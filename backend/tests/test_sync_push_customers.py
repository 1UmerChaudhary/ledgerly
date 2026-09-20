import time
import uuid

from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from tests.test_sync_push import _auth_headers, _registered_session

DEVICE = str(uuid.uuid4())


def _customer_row(
    *,
    row_id: str | None = None,
    name: str,
    phone: str | None,
    updated_at: int,
    created_by_user_id: str,
    device_id: str = DEVICE,
) -> dict:
    return {
        "table": "customers",
        "id": row_id or str(uuid.uuid4()),
        "data": {
            "name": name,
            "name_normalized": name.lower(),
            "phone": phone,
            "phone_normalized": phone,
            "notes": None,
            "created_by_user_id": created_by_user_id,
            "merged_into_id": None,
            "needs_review": False,
            "created_at": updated_at,
            "updated_at": updated_at,
            "updated_by_device_id": device_id,
            "deleted_at": None,
        },
    }


async def _push(client: AsyncClient, session: dict, *rows: dict) -> dict:
    response = await client.post(
        "/sync/push",
        headers=_auth_headers(session),
        json={
            "device_id": DEVICE,
            "schema_version": 1,
            "device_time": int(time.time() * 1000),
            "rows": list(rows),
        },
    )
    assert response.status_code == 200, response.text
    return response.json()


async def test_push_inserts_a_new_customer_with_no_phone_conflict(client: AsyncClient) -> None:
    session = await _registered_session(client)
    now = int(time.time() * 1000)
    row = _customer_row(
        name="Rashid Traders",
        phone="923001234567",
        updated_at=now,
        created_by_user_id=session["user"]["id"],
    )

    result = await _push(client, session, row)

    assert result["accepted"] == [{"id": row["id"], "updated_at": now}]
    assert result["rewrites"] == []


async def test_push_flags_both_customers_for_review_when_phones_match_but_names_dont(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    session = await _registered_session(client)
    now = int(time.time() * 1000)
    first = _customer_row(
        name="Rashid Traders",
        phone="923001234567",
        updated_at=now,
        created_by_user_id=session["user"]["id"],
    )
    await _push(client, session, first)

    second = _customer_row(
        name="Ahmed Brothers",
        phone="923001234567",
        updated_at=now + 1000,
        created_by_user_id=session["user"]["id"],
    )
    result = await _push(client, session, second)

    assert result["accepted"] == [{"id": second["id"], "updated_at": now + 1000}]
    assert result["rewrites"] == []
    needs_review = (
        await db_session.execute(
            text("SELECT id, needs_review FROM customers WHERE firm_id = :firm_id"),
            {"firm_id": session["firm"]["id"]},
        )
    ).all()
    assert {row.id: row.needs_review for row in needs_review} == {
        uuid.UUID(first["id"]): True,
        uuid.UUID(second["id"]): True,
    }


async def test_push_auto_merges_when_phone_and_name_both_match(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    session = await _registered_session(client)
    now = int(time.time() * 1000)
    first = _customer_row(
        name="Rashid Traders",
        phone="923001234567",
        updated_at=now,
        created_by_user_id=session["user"]["id"],
    )
    await _push(client, session, first)

    duplicate = _customer_row(
        name="Rashid Traders",
        phone="923001234567",
        updated_at=now + 1000,
        created_by_user_id=session["user"]["id"],
    )
    result = await _push(client, session, duplicate)

    assert result["accepted"] == [{"id": duplicate["id"], "updated_at": now + 1000}]
    assert result["rewrites"] == [{"old_id": duplicate["id"], "new_id": first["id"]}]
    exists = (
        await db_session.execute(
            text("SELECT count(*) FROM customers WHERE id = :id"), {"id": duplicate["id"]}
        )
    ).scalar_one()
    assert exists == 0  # the duplicate row was never actually created


async def test_push_updates_an_existing_customer_with_a_newer_write(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    session = await _registered_session(client)
    row_id = str(uuid.uuid4())
    now = int(time.time() * 1000)
    created = _customer_row(
        row_id=row_id,
        name="Rashid Traders",
        phone="923001234567",
        updated_at=now,
        created_by_user_id=session["user"]["id"],
    )
    await _push(client, session, created)

    edited = _customer_row(
        row_id=row_id,
        name="Rashid Traders Pvt Ltd",
        phone="923001234567",
        updated_at=now + 1000,
        created_by_user_id=session["user"]["id"],
    )
    result = await _push(client, session, edited)

    assert result["accepted"] == [{"id": row_id, "updated_at": now + 1000}]
    current_name = (
        await db_session.execute(text("SELECT name FROM customers WHERE id = :id"), {"id": row_id})
    ).scalar_one()
    assert current_name == "Rashid Traders Pvt Ltd"
