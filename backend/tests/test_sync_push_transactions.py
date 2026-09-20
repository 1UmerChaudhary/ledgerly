import time
import uuid

from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from tests.test_sync_push import _auth_headers, _registered_session

DEVICE_A = str(uuid.uuid4())
DEVICE_B = str(uuid.uuid4())


async def _seed_item(client: AsyncClient, session: dict, name: str = "Oil") -> str:
    now = int(time.time() * 1000)
    item_id = str(uuid.uuid4())
    row = {
        "table": "items",
        "id": item_id,
        "data": {
            "name": name,
            "name_normalized": name.lower(),
            "default_bag_weight_g": None,
            "default_rate_base_weight_g": None,
            "default_uom": "kg",
            "track_stock": False,
            "created_by_user_id": session["user"]["id"],
            "created_at": now,
            "updated_at": now,
            "updated_by_device_id": DEVICE_A,
            "deleted_at": None,
        },
    }
    await _push(client, session, row)
    return item_id


async def _push(client: AsyncClient, session: dict, *rows: dict, device_id: str = DEVICE_A) -> dict:
    response = await client.post(
        "/sync/push",
        headers=_auth_headers(session),
        json={
            "device_id": device_id,
            "schema_version": 1,
            "device_time": int(time.time() * 1000),
            "rows": list(rows),
        },
    )
    assert response.status_code == 200, response.text
    return response.json()


def _sale_row(
    *,
    row_id: str | None,
    item_id: str,
    updated_at: int,
    device_id: str,
    user_id: str,
    final_amount: int = 1000,
    version: int = 1,
) -> dict:
    line_id = str(uuid.uuid4())
    return {
        "table": "transactions",
        "id": row_id or str(uuid.uuid4()),
        "data": {
            "customer_id": None,
            "device_short_code": "A3F9",
            "display_seq": 1,
            "type": "sale",
            "entry_date": "2026-09-20",
            "description": None,
            "version": version,
            "calculated_total": final_amount,
            "overridden_total": None,
            "overridden_total_basis": None,
            "final_amount": final_amount,
            "created_by_user_id": user_id,
            "updated_by_user_id": user_id,
            "created_at": updated_at,
            "updated_at": updated_at,
            "updated_by_device_id": device_id,
            "deleted_at": None,
            "lines": [
                {
                    "id": line_id,
                    "line_no": 0,
                    "item_id": item_id,
                    "uom": "kg",
                    "sale_mode": "by_weight",
                    "bag_count": None,
                    "bag_weight_g": None,
                    "total_weight_g": 1000,
                    "quantity": None,
                    "rate_paisa": final_amount,
                    "rate_base_weight_g": 1000,
                    "overridden_total": None,
                }
            ],
        },
    }


async def test_push_inserts_a_new_sale_with_its_line(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    session = await _registered_session(client)
    item_id = await _seed_item(client, session)
    now = int(time.time() * 1000)
    row = _sale_row(
        row_id=None,
        item_id=item_id,
        updated_at=now,
        device_id=DEVICE_A,
        user_id=session["user"]["id"],
    )

    result = await _push(client, session, row)

    assert result["accepted"] == [{"id": row["id"], "updated_at": now}]
    line_count = (
        await db_session.execute(
            text("SELECT count(*) FROM transaction_lines WHERE transaction_id = :id"),
            {"id": row["id"]},
        )
    ).scalar_one()
    assert line_count == 1


async def test_push_newer_write_replaces_lines_and_archives_the_loser(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    session = await _registered_session(client)
    item_id = await _seed_item(client, session)
    row_id = str(uuid.uuid4())
    t1 = int(time.time() * 1000)
    original = _sale_row(
        row_id=row_id,
        item_id=item_id,
        updated_at=t1,
        device_id=DEVICE_A,
        user_id=session["user"]["id"],
        final_amount=1000,
    )
    await _push(client, session, original)

    t2 = t1 + 1000
    edited = _sale_row(
        row_id=row_id,
        item_id=item_id,
        updated_at=t2,
        device_id=DEVICE_B,
        user_id=session["user"]["id"],
        final_amount=2000,
        version=2,
    )
    result = await _push(client, session, edited)

    assert result["accepted"] == [{"id": row_id, "updated_at": t2}]
    final_amount = (
        await db_session.execute(
            text("SELECT final_amount FROM transactions WHERE id = :id"), {"id": row_id}
        )
    ).scalar_one()
    assert final_amount == 2000
    line_amounts = (
        (
            await db_session.execute(
                text("SELECT rate_paisa FROM transaction_lines WHERE transaction_id = :id"),
                {"id": row_id},
            )
        )
        .scalars()
        .all()
    )
    assert line_amounts == [2000]  # old line replaced, not appended
    history = (
        await db_session.execute(
            text(
                "SELECT reason, version, snapshot FROM transaction_history "
                "WHERE transaction_id = :id"
            ),
            {"id": row_id},
        )
    ).one()
    assert history.reason == "sync_overwrite"
    assert history.version == 1  # the losing (original) version
    assert history.snapshot["header"]["final_amount"] == 1000


async def test_push_older_write_is_acked_but_not_applied_and_is_archived(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    session = await _registered_session(client)
    item_id = await _seed_item(client, session)
    row_id = str(uuid.uuid4())
    t1 = int(time.time() * 1000)

    newer = _sale_row(
        row_id=row_id,
        item_id=item_id,
        updated_at=t1 + 1000,
        device_id=DEVICE_B,
        user_id=session["user"]["id"],
        final_amount=2000,
        version=2,
    )
    await _push(client, session, newer)

    stale = _sale_row(
        row_id=row_id,
        item_id=item_id,
        updated_at=t1,
        device_id=DEVICE_A,
        user_id=session["user"]["id"],
        final_amount=1000,
        version=1,
    )
    result = await _push(client, session, stale)

    assert result["accepted"] == [{"id": row_id, "updated_at": t1}]
    final_amount = (
        await db_session.execute(
            text("SELECT final_amount FROM transactions WHERE id = :id"), {"id": row_id}
        )
    ).scalar_one()
    assert final_amount == 2000  # untouched
    history = (
        await db_session.execute(
            text(
                "SELECT reason, version, snapshot FROM transaction_history "
                "WHERE transaction_id = :id"
            ),
            {"id": row_id},
        )
    ).one()
    assert history.reason == "sync_overwrite"
    assert history.version == 1  # the losing (incoming, stale) version
    assert history.snapshot["header"]["final_amount"] == 1000


async def test_push_resending_the_identical_row_does_not_duplicate_history(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    session = await _registered_session(client)
    item_id = await _seed_item(client, session)
    row_id = str(uuid.uuid4())
    now = int(time.time() * 1000)
    row = _sale_row(
        row_id=row_id,
        item_id=item_id,
        updated_at=now,
        device_id=DEVICE_A,
        user_id=session["user"]["id"],
    )
    await _push(client, session, row)

    result = await _push(client, session, row)

    assert result["accepted"] == [{"id": row_id, "updated_at": now}]
    history_count = (
        await db_session.execute(
            text("SELECT count(*) FROM transaction_history WHERE transaction_id = :id"),
            {"id": row_id},
        )
    ).scalar_one()
    assert history_count == 0
