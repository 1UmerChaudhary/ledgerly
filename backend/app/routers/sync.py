import json
import time
import uuid as uuid_module
from typing import Any

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.deps import get_current_firm_id

router = APIRouter(prefix="/sync", tags=["sync"])

CLOCK_SKEW_TOLERANCE_MS = 5 * 60 * 1000

# name -> the columns a row for that table carries, beyond id/firm_id. Only
# "items" is wired up so far (docs/design-spec.md Section 4); every other
# table name is rejected rather than silently accepted half-built.
ITEM_COLUMNS = (
    "name",
    "name_normalized",
    "default_bag_weight_g",
    "default_rate_base_weight_g",
    "default_uom",
    "track_stock",
    "created_by_user_id",
    "created_at",
    "updated_at",
    "updated_by_device_id",
    "deleted_at",
)

CUSTOMER_COLUMNS = (
    "name",
    "name_normalized",
    "phone",
    "phone_normalized",
    "notes",
    "created_by_user_id",
    "merged_into_id",
    "needs_review",
    "created_at",
    "updated_at",
    "updated_by_device_id",
    "deleted_at",
)

# A bill's header columns (its lines live in TRANSACTION_LINE_COLUMNS,
# always sent and replaced together — see docs/design-spec.md Section 2,
# "lines travel inside their bill; pull = DELETE all + INSERT the ids
# carried in the payload"). signed_amount is generated, never written.
TRANSACTION_COLUMNS = (
    "customer_id",
    "device_short_code",
    "display_seq",
    "type",
    "entry_date",
    "description",
    "version",
    "calculated_total",
    "overridden_total",
    "overridden_total_basis",
    "final_amount",
    "created_by_user_id",
    "updated_by_user_id",
    "created_at",
    "updated_at",
    "updated_by_device_id",
    "deleted_at",
)

# A line's own columns, excluding id/firm_id/transaction_id (supplied
# separately) and calculated_total/final_amount (generated).
TRANSACTION_LINE_COLUMNS = (
    "id",
    "line_no",
    "item_id",
    "uom",
    "sale_mode",
    "bag_count",
    "bag_weight_g",
    "total_weight_g",
    "quantity",
    "rate_paisa",
    "rate_base_weight_g",
    "overridden_total",
)

# Fixed namespace for transaction_history's deterministic id: uuid5 of
# (transaction_id, loser's updated_at, loser's device), so the same losing
# version discovered by more than one push collides into a single row
# instead of duplicating (docs/design-spec.md Section 2). The exact value
# doesn't matter, only that it never changes.
HISTORY_NAMESPACE = uuid_module.UUID("6f6e1c4a-6b8a-4b1a-9c1a-2f6b7a8c9d0e")


class TimeResponse(BaseModel):
    server_time: int


@router.get("/time", response_model=TimeResponse)
async def get_time() -> TimeResponse:
    """The server's own clock, in the same HLC-millisecond units as every
    stamped column. Public and DB-free on purpose: a device seeds its clock
    offset from this before it has ever logged in (see docs/design-spec.md
    Section 4, step 0).
    """
    return TimeResponse(server_time=int(time.time() * 1000))


class PushRow(BaseModel):
    table: str
    id: str
    data: dict[str, Any]


class PushRequest(BaseModel):
    device_id: str
    schema_version: int
    device_time: int
    rows: list[PushRow]


class Accepted(BaseModel):
    id: str
    updated_at: int


class Rejected(BaseModel):
    id: str
    reason: str


class Rewrite(BaseModel):
    old_id: str
    new_id: str


class PushResponse(BaseModel):
    accepted: list[Accepted]
    rejected: list[Rejected]
    rewrites: list[Rewrite]
    server_time: int


async def _reserve_sequence_block(db: AsyncSession, firm_id: str, count: int) -> int:
    """Reserves `count` sync_changes sequence numbers in one row-locked
    update, so concurrent pushes from two devices of the same firm can never
    interleave their sequence numbers (docs/design-spec.md Section 4, step 3).
    Returns the first number in the reserved block; unused numbers (from
    rows that end up rejected or are a no-op ack) are simply gaps, which is
    fine for a monotonic cursor.

    Sequence numbers are 1-based: firms.next_seq starts at 0, and pull's
    cursor convention is "server_seq > since", so a 0-based first sequence
    number would make the very first change ever pushed indistinguishable
    from "nothing to pull yet" when since=0.
    """
    if count == 0:
        return 0
    new_next_seq = (
        await db.execute(
            text(
                "UPDATE firms SET next_seq = next_seq + :n WHERE id = :firm_id RETURNING next_seq"
            ),
            {"n": count, "firm_id": firm_id},
        )
    ).scalar_one()
    return new_next_seq - count + 1


async def _record_sync_change(
    db: AsyncSession, *, firm_id: str, seq: int, table_name: str, row_id: str, changed_at: int
) -> None:
    await db.execute(
        text(
            "INSERT INTO sync_changes (firm_id, server_seq, table_name, row_id, changed_at) "
            "VALUES (:firm_id, :seq, :table_name, :row_id, :changed_at)"
        ),
        {
            "firm_id": firm_id,
            "seq": seq,
            "table_name": table_name,
            "row_id": row_id,
            "changed_at": changed_at,
        },
    )


async def _newer_write_or_ack(
    db: AsyncSession,
    *,
    table_name: str,
    columns: tuple[str, ...],
    firm_id: str,
    row: PushRow,
    server_time: int,
    next_seq: int,
    updated_at: int,
) -> tuple[Accepted, int]:
    """The generic "seen row" case shared by every table: newer write wins
    and is applied + logged; older or identical is acked but left alone —
    the device learns the real current state on its next pull.
    """
    existing = (
        await db.execute(
            text(
                f"SELECT updated_at, updated_by_device_id FROM {table_name} "
                "WHERE firm_id = :firm_id AND id = :id"
            ),
            {"firm_id": firm_id, "id": row.id},
        )
    ).one()
    incoming_key = (updated_at, str(row.data.get("updated_by_device_id")))
    existing_key = (existing.updated_at, str(existing.updated_by_device_id))
    if incoming_key <= existing_key:
        return Accepted(id=row.id, updated_at=updated_at), next_seq

    await db.execute(
        text(
            f"UPDATE {table_name} SET "
            + ", ".join(f"{c} = :{c}" for c in columns if c != "created_by_user_id")
            + " WHERE firm_id = :firm_id AND id = :id"
        ),
        {"id": row.id, "firm_id": firm_id, **row.data},
    )
    await _record_sync_change(
        db,
        firm_id=firm_id,
        seq=next_seq,
        table_name=table_name,
        row_id=row.id,
        changed_at=server_time,
    )
    return Accepted(id=row.id, updated_at=updated_at), next_seq + 1


async def _push_item_row(
    db: AsyncSession, *, firm_id: str, row: PushRow, server_time: int, next_seq: int
) -> tuple[Accepted | Rejected, int, list[Rewrite]]:
    """Returns the outcome, the next unused sequence number (advanced by one
    only when something actually changed, per _reserve_sequence_block), and
    any rewrites (always empty for items — only customers can merge).

    Raises IntegrityError for the caller to turn into a rejection — it must
    not be caught here: catching it inside the caller's savepoint block
    would fight the savepoint's own rollback-on-exception when that
    savepoint is still open.
    """
    updated_at = row.data.get("updated_at")
    if not isinstance(updated_at, int):
        return Rejected(id=row.id, reason="invalid"), next_seq, []
    if updated_at > server_time + CLOCK_SKEW_TOLERANCE_MS:
        return Rejected(id=row.id, reason="clock_skew"), next_seq, []

    exists = (
        await db.execute(
            text("SELECT 1 FROM items WHERE firm_id = :firm_id AND id = :id"),
            {"firm_id": firm_id, "id": row.id},
        )
    ).one_or_none()

    if exists is None:
        await db.execute(
            text(
                "INSERT INTO items (id, firm_id, " + ", ".join(ITEM_COLUMNS) + ") "
                "VALUES (:id, :firm_id, " + ", ".join(f":{c}" for c in ITEM_COLUMNS) + ")"
            ),
            {"id": row.id, "firm_id": firm_id, **row.data},
        )
        await _record_sync_change(
            db,
            firm_id=firm_id,
            seq=next_seq,
            table_name="items",
            row_id=row.id,
            changed_at=server_time,
        )
        return Accepted(id=row.id, updated_at=updated_at), next_seq + 1, []

    outcome, next_seq = await _newer_write_or_ack(
        db,
        table_name="items",
        columns=ITEM_COLUMNS,
        firm_id=firm_id,
        row=row,
        server_time=server_time,
        next_seq=next_seq,
        updated_at=updated_at,
    )
    return outcome, next_seq, []


async def _push_customer_row(
    db: AsyncSession, *, firm_id: str, row: PushRow, server_time: int, next_seq: int
) -> tuple[Accepted | Rejected, int, list[Rewrite]]:
    """Unseen customers get one extra check items don't need: a phone that
    already belongs to another live customer in the firm. Same name too →
    auto-merge (the incoming row is never created; a Rewrite tells the
    device to use the existing id instead). Different name → both rows are
    kept, flagged needs_review, for a person to sort out later
    (docs/design-spec.md Section 4 step 3).
    """
    updated_at = row.data.get("updated_at")
    if not isinstance(updated_at, int):
        return Rejected(id=row.id, reason="invalid"), next_seq, []
    if updated_at > server_time + CLOCK_SKEW_TOLERANCE_MS:
        return Rejected(id=row.id, reason="clock_skew"), next_seq, []

    exists = (
        await db.execute(
            text("SELECT 1 FROM customers WHERE firm_id = :firm_id AND id = :id"),
            {"firm_id": firm_id, "id": row.id},
        )
    ).one_or_none()

    if exists is not None:
        outcome, next_seq = await _newer_write_or_ack(
            db,
            table_name="customers",
            columns=CUSTOMER_COLUMNS,
            firm_id=firm_id,
            row=row,
            server_time=server_time,
            next_seq=next_seq,
            updated_at=updated_at,
        )
        return outcome, next_seq, []

    phone_normalized = row.data.get("phone_normalized")
    match = None
    if phone_normalized:
        match = (
            await db.execute(
                text(
                    "SELECT id, name_normalized FROM customers "
                    "WHERE firm_id = :firm_id AND phone_normalized = :phone "
                    "AND deleted_at IS NULL AND merged_into_id IS NULL"
                ),
                {"firm_id": firm_id, "phone": phone_normalized},
            )
        ).one_or_none()

    if match is not None and match.name_normalized == row.data.get("name_normalized"):
        return (
            Accepted(id=row.id, updated_at=updated_at),
            next_seq,
            [Rewrite(old_id=row.id, new_id=str(match.id))],
        )

    insert_data = dict(row.data)
    if match is not None:
        insert_data["needs_review"] = True
    await db.execute(
        text(
            "INSERT INTO customers (id, firm_id, " + ", ".join(CUSTOMER_COLUMNS) + ") "
            "VALUES (:id, :firm_id, " + ", ".join(f":{c}" for c in CUSTOMER_COLUMNS) + ")"
        ),
        {"id": row.id, "firm_id": firm_id, **insert_data},
    )
    await _record_sync_change(
        db,
        firm_id=firm_id,
        seq=next_seq,
        table_name="customers",
        row_id=row.id,
        changed_at=server_time,
    )
    next_seq += 1

    if match is not None:
        await db.execute(
            text("UPDATE customers SET needs_review = true WHERE id = :id"),
            {"id": match.id},
        )
        await _record_sync_change(
            db,
            firm_id=firm_id,
            seq=next_seq,
            table_name="customers",
            row_id=str(match.id),
            changed_at=server_time,
        )
        next_seq += 1

    return Accepted(id=row.id, updated_at=updated_at), next_seq, []


def _history_id(transaction_id: str, loser_updated_at: int, loser_device_id: str) -> str:
    name = f"{transaction_id}:{loser_updated_at}:{loser_device_id}"
    return str(uuid_module.uuid5(HISTORY_NAMESPACE, name))


async def _insert_lines(
    db: AsyncSession, *, firm_id: str, transaction_id: str, lines: list[dict[str, Any]]
) -> None:
    for line in lines:
        await db.execute(
            text(
                "INSERT INTO transaction_lines (firm_id, transaction_id, "
                + ", ".join(TRANSACTION_LINE_COLUMNS)
                + ") VALUES (:firm_id, :transaction_id, "
                + ", ".join(f":{c}" for c in TRANSACTION_LINE_COLUMNS)
                + ")"
            ),
            {"firm_id": firm_id, "transaction_id": transaction_id, **line},
        )


async def _replace_lines(
    db: AsyncSession, *, firm_id: str, transaction_id: str, lines: list[dict[str, Any]]
) -> None:
    await db.execute(
        text("DELETE FROM transaction_lines WHERE firm_id = :firm_id AND transaction_id = :id"),
        {"firm_id": firm_id, "id": transaction_id},
    )
    await _insert_lines(db, firm_id=firm_id, transaction_id=transaction_id, lines=lines)


async def _current_snapshot(db: AsyncSession, *, firm_id: str, transaction_id: str) -> dict:
    """{header, lines} as they stand in the database right now — used to
    archive the LOSING side of a conflict just before it's overwritten.
    """
    header = (
        (
            await db.execute(
                text(
                    f"SELECT id, {', '.join(TRANSACTION_COLUMNS)} FROM transactions "
                    "WHERE firm_id = :firm_id AND id = :id"
                ),
                {"firm_id": firm_id, "id": transaction_id},
            )
        )
        .mappings()
        .one()
    )
    lines = (
        (
            await db.execute(
                text(
                    f"SELECT {', '.join(TRANSACTION_LINE_COLUMNS)} FROM transaction_lines "
                    "WHERE firm_id = :firm_id AND transaction_id = :id ORDER BY line_no"
                ),
                {"firm_id": firm_id, "id": transaction_id},
            )
        )
        .mappings()
        .all()
    )
    return {"schema_version": 1, "header": dict(header), "lines": [dict(line) for line in lines]}


async def _record_history(
    db: AsyncSession,
    *,
    firm_id: str,
    transaction_id: str,
    version: int,
    snapshot: dict,
    changed_at: int,
    changed_by_user_id: str,
    changed_by_device_id: str,
    history_id: str,
) -> None:
    # ON CONFLICT DO NOTHING: the deterministic id means a repeat discovery
    # of the same losing version (e.g. the same stale row pushed twice)
    # collides into the one row instead of duplicating it.
    await db.execute(
        text(
            """
            INSERT INTO transaction_history
                (id, firm_id, transaction_id, version, snapshot, reason, changed_at,
                 changed_by_user_id, changed_by_device_id)
            VALUES
                (:id, :firm_id, :transaction_id, :version, CAST(:snapshot AS jsonb),
                 'sync_overwrite', :changed_at, :changed_by_user_id, :changed_by_device_id)
            ON CONFLICT (id) DO NOTHING
            """
        ),
        {
            "id": history_id,
            "firm_id": firm_id,
            "transaction_id": transaction_id,
            "version": version,
            "snapshot": json.dumps(snapshot, default=str),
            "changed_at": changed_at,
            "changed_by_user_id": changed_by_user_id,
            "changed_by_device_id": changed_by_device_id,
        },
    )


async def _push_transaction_row(
    db: AsyncSession, *, firm_id: str, row: PushRow, server_time: int, next_seq: int
) -> tuple[Accepted | Rejected, int, list[Rewrite]]:
    """A bill is header + lines together, always replaced wholesale — never
    diffed line by line (docs/design-spec.md Section 2). Unlike items and
    customers, a losing write here is never silently dropped: it's archived
    to transaction_history first, on whichever side loses (see
    `_history_id`'s docstring on the module-level constant for why the
    archived id is deterministic rather than a fresh uuid each time).

    Not yet built: transaction_history isn't itself pushed/pulled (so a
    conflict's loser is visible to this device but not synced to others
    yet), and there's no handling for a bill referencing a tombstoned or
    merged customer (docs/design-spec.md Section 4 step 3).
    """
    updated_at = row.data.get("updated_at")
    lines = row.data.get("lines")
    if not isinstance(updated_at, int) or not isinstance(lines, list):
        return Rejected(id=row.id, reason="invalid"), next_seq, []
    if updated_at > server_time + CLOCK_SKEW_TOLERANCE_MS:
        return Rejected(id=row.id, reason="clock_skew"), next_seq, []

    header_data = {k: v for k, v in row.data.items() if k != "lines"}

    existing = (
        await db.execute(
            text(
                "SELECT updated_at, updated_by_device_id, version FROM transactions "
                "WHERE firm_id = :firm_id AND id = :id"
            ),
            {"firm_id": firm_id, "id": row.id},
        )
    ).one_or_none()

    if existing is None:
        await db.execute(
            text(
                "INSERT INTO transactions (id, firm_id, "
                + ", ".join(TRANSACTION_COLUMNS)
                + ") VALUES (:id, :firm_id, "
                + ", ".join(f":{c}" for c in TRANSACTION_COLUMNS)
                + ")"
            ),
            {"id": row.id, "firm_id": firm_id, **header_data},
        )
        await _insert_lines(db, firm_id=firm_id, transaction_id=row.id, lines=lines)
        await _record_sync_change(
            db,
            firm_id=firm_id,
            seq=next_seq,
            table_name="transactions",
            row_id=row.id,
            changed_at=server_time,
        )
        return Accepted(id=row.id, updated_at=updated_at), next_seq + 1, []

    incoming_key = (updated_at, str(header_data.get("updated_by_device_id")))
    existing_key = (existing.updated_at, str(existing.updated_by_device_id))

    if incoming_key > existing_key:
        loser_snapshot = await _current_snapshot(db, firm_id=firm_id, transaction_id=row.id)
        await _record_history(
            db,
            firm_id=firm_id,
            transaction_id=row.id,
            version=existing.version,
            snapshot=loser_snapshot,
            changed_at=server_time,
            changed_by_user_id=str(header_data.get("updated_by_user_id")),
            changed_by_device_id=str(existing.updated_by_device_id),
            history_id=_history_id(row.id, existing.updated_at, str(existing.updated_by_device_id)),
        )
        await db.execute(
            text(
                "UPDATE transactions SET "
                + ", ".join(f"{c} = :{c}" for c in TRANSACTION_COLUMNS if c != "created_by_user_id")
                + " WHERE firm_id = :firm_id AND id = :id"
            ),
            {"id": row.id, "firm_id": firm_id, **header_data},
        )
        await _replace_lines(db, firm_id=firm_id, transaction_id=row.id, lines=lines)
        await _record_sync_change(
            db,
            firm_id=firm_id,
            seq=next_seq,
            table_name="transactions",
            row_id=row.id,
            changed_at=server_time,
        )
        return Accepted(id=row.id, updated_at=updated_at), next_seq + 1, []

    if incoming_key < existing_key:
        loser_snapshot = {"schema_version": 1, "header": header_data, "lines": lines}
        loser_device_id = str(header_data.get("updated_by_device_id"))
        await _record_history(
            db,
            firm_id=firm_id,
            transaction_id=row.id,
            version=header_data.get("version"),
            snapshot=loser_snapshot,
            changed_at=server_time,
            changed_by_user_id=str(header_data.get("updated_by_user_id")),
            changed_by_device_id=loser_device_id,
            history_id=_history_id(row.id, updated_at, loser_device_id),
        )
        return Accepted(id=row.id, updated_at=updated_at), next_seq, []

    return Accepted(id=row.id, updated_at=updated_at), next_seq, []


@router.post("/push", response_model=PushResponse)
async def push(
    body: PushRequest,
    firm_id: str = Depends(get_current_firm_id),  # noqa: B008 -- FastAPI Depends()
    db: AsyncSession = Depends(get_db),  # noqa: B008 -- FastAPI Depends()
) -> PushResponse:
    server_time = int(time.time() * 1000)
    accepted: list[Accepted] = []
    rejected: list[Rejected] = []
    rewrites: list[Rewrite] = []
    # A customer row can consume two sequence numbers (itself + the existing
    # phone match it flags needs_review on), so the reserved block is sized
    # for that worst case; any unused numbers are harmless gaps.
    next_seq = await _reserve_sequence_block(db, firm_id, len(body.rows) * 2)

    for row in body.rows:
        row_rewrites: list[Rewrite] = []
        try:
            async with db.begin_nested():
                if row.table == "items":
                    outcome, next_seq, row_rewrites = await _push_item_row(
                        db, firm_id=firm_id, row=row, server_time=server_time, next_seq=next_seq
                    )
                elif row.table == "customers":
                    outcome, next_seq, row_rewrites = await _push_customer_row(
                        db, firm_id=firm_id, row=row, server_time=server_time, next_seq=next_seq
                    )
                elif row.table == "transactions":
                    outcome, next_seq, row_rewrites = await _push_transaction_row(
                        db, firm_id=firm_id, row=row, server_time=server_time, next_seq=next_seq
                    )
                else:
                    outcome = Rejected(id=row.id, reason="unsupported_table")
        except IntegrityError:
            outcome = Rejected(id=row.id, reason="invalid")
        (accepted if isinstance(outcome, Accepted) else rejected).append(outcome)
        rewrites.extend(row_rewrites)

    await db.commit()
    return PushResponse(
        accepted=accepted, rejected=rejected, rewrites=rewrites, server_time=server_time
    )


class PullRow(BaseModel):
    table: str
    id: str
    data: dict[str, Any]


class PullResponse(BaseModel):
    rows: list[PullRow]
    next_cursor: int
    has_more: bool


# table_name -> the SELECT list for its "current row" lookup on pull. Same
# restriction as push: only items is wired up so far.
TABLE_COLUMNS = {
    "items": ITEM_COLUMNS,
    "customers": CUSTOMER_COLUMNS,
    "transactions": TRANSACTION_COLUMNS,
}


@router.get("/pull", response_model=PullResponse)
async def pull(
    since: int = Query(ge=0),
    limit: int = Query(default=500, ge=1, le=1000),
    firm_id: str = Depends(get_current_firm_id),  # noqa: B008 -- FastAPI Depends()
    db: AsyncSession = Depends(get_db),  # noqa: B008 -- FastAPI Depends()
) -> PullResponse:
    """`limit` bounds the raw sync_changes rows read, not the distinct rows
    returned (docs/design-spec.md Section 4, step 5) — a chatty row that
    changed many times still only costs one output row, but it can still
    fill most of a page by itself. next_cursor is always the highest raw
    seq actually read, so a page can never skip over an entry that landed
    between two deduplicated rows.
    """
    raw = (
        await db.execute(
            text(
                "SELECT table_name, row_id, server_seq FROM sync_changes "
                "WHERE firm_id = :firm_id AND server_seq > :since "
                "ORDER BY server_seq ASC LIMIT :limit"
            ),
            {"firm_id": firm_id, "since": since, "limit": limit},
        )
    ).all()

    if not raw:
        return PullResponse(rows=[], next_cursor=since, has_more=False)

    seen: dict[tuple[str, str], None] = {}
    for entry in raw:
        seen.setdefault((entry.table_name, str(entry.row_id)), None)

    rows: list[PullRow] = []
    for table_name, row_id in seen:
        columns = TABLE_COLUMNS[table_name]
        current = (
            (
                await db.execute(
                    text(
                        f"SELECT {', '.join(columns)} FROM {table_name} "
                        "WHERE firm_id = :firm_id AND id = :id"
                    ),
                    {"firm_id": firm_id, "id": row_id},
                )
            )
            .mappings()
            .one()
        )
        data = dict(current)
        if table_name == "transactions":
            lines = (
                (
                    await db.execute(
                        text(
                            f"SELECT {', '.join(TRANSACTION_LINE_COLUMNS)} FROM transaction_lines "
                            "WHERE firm_id = :firm_id AND transaction_id = :id ORDER BY line_no"
                        ),
                        {"firm_id": firm_id, "id": row_id},
                    )
                )
                .mappings()
                .all()
            )
            data["lines"] = [dict(line) for line in lines]
        rows.append(PullRow(table=table_name, id=row_id, data=data))

    return PullResponse(
        rows=rows,
        next_cursor=raw[-1].server_seq,
        has_more=len(raw) == limit,
    )
