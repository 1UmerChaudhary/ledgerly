import time
from typing import Any

from fastapi import APIRouter, Depends
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


class PushResponse(BaseModel):
    accepted: list[Accepted]
    rejected: list[Rejected]
    server_time: int


async def _reserve_sequence_block(db: AsyncSession, firm_id: str, count: int) -> int:
    """Reserves `count` sync_changes sequence numbers in one row-locked
    update, so concurrent pushes from two devices of the same firm can never
    interleave their sequence numbers (docs/design-spec.md Section 4, step 3).
    Returns the first number in the reserved block; unused numbers (from
    rows that end up rejected or are a no-op ack) are simply gaps, which is
    fine for a monotonic cursor.
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
    return new_next_seq - count


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


async def _push_item_row(
    db: AsyncSession, *, firm_id: str, row: PushRow, server_time: int, next_seq: int
) -> tuple[Accepted | Rejected, int]:
    """Returns the outcome and the next unused sequence number (advanced by
    one only when something actually changed, per _reserve_sequence_block).

    Raises IntegrityError for the caller to turn into a rejection — it must
    not be caught here: catching it inside the caller's savepoint block
    would fight the savepoint's own rollback-on-exception when that
    savepoint is still open.
    """
    updated_at = row.data.get("updated_at")
    if not isinstance(updated_at, int):
        return Rejected(id=row.id, reason="invalid"), next_seq
    if updated_at > server_time + CLOCK_SKEW_TOLERANCE_MS:
        return Rejected(id=row.id, reason="clock_skew"), next_seq

    existing = (
        await db.execute(
            text(
                "SELECT updated_at, updated_by_device_id FROM items "
                "WHERE firm_id = :firm_id AND id = :id"
            ),
            {"firm_id": firm_id, "id": row.id},
        )
    ).one_or_none()

    if existing is None:
        await db.execute(
            text(
                "INSERT INTO items (id, firm_id, " + ", ".join(ITEM_COLUMNS) + ") "
                "VALUES (:id, :firm_id, " + ", ".join(f":{c}" for c in ITEM_COLUMNS) + ")"
            ),
            {"id": row.id, "firm_id": firm_id, **row.data},
        )
    else:
        incoming_key = (updated_at, str(row.data.get("updated_by_device_id")))
        existing_key = (existing.updated_at, str(existing.updated_by_device_id))
        if incoming_key <= existing_key:
            # older or identical: the write already happened (or lost to a
            # race) — ack it so the device's outbox stops retrying, but the
            # row itself is untouched. The device learns the real current
            # state on its next pull.
            return Accepted(id=row.id, updated_at=updated_at), next_seq
        await db.execute(
            text(
                "UPDATE items SET "
                + ", ".join(f"{c} = :{c}" for c in ITEM_COLUMNS if c != "created_by_user_id")
                + " WHERE firm_id = :firm_id AND id = :id"
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
    return Accepted(id=row.id, updated_at=updated_at), next_seq + 1


@router.post("/push", response_model=PushResponse)
async def push(
    body: PushRequest,
    firm_id: str = Depends(get_current_firm_id),  # noqa: B008 -- FastAPI Depends()
    db: AsyncSession = Depends(get_db),  # noqa: B008 -- FastAPI Depends()
) -> PushResponse:
    server_time = int(time.time() * 1000)
    accepted: list[Accepted] = []
    rejected: list[Rejected] = []
    next_seq = await _reserve_sequence_block(db, firm_id, len(body.rows))

    for row in body.rows:
        try:
            async with db.begin_nested():
                if row.table != "items":
                    outcome: Accepted | Rejected = Rejected(id=row.id, reason="unsupported_table")
                else:
                    outcome, next_seq = await _push_item_row(
                        db, firm_id=firm_id, row=row, server_time=server_time, next_seq=next_seq
                    )
        except IntegrityError:
            outcome = Rejected(id=row.id, reason="invalid")
        (accepted if isinstance(outcome, Accepted) else rejected).append(outcome)

    await db.commit()
    return PushResponse(accepted=accepted, rejected=rejected, server_time=server_time)
