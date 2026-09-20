import time
import uuid

from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from tests.test_auth import _register_body

# updated_by_device_id is a real uuid column; these stand for "some other
# device" in the newer/older-write tests without claiming to be the
# session's own registered device.
DEVICE_A = str(uuid.uuid4())
DEVICE_B = str(uuid.uuid4())


async def _registered_session(client: AsyncClient) -> dict:
    response = await client.post("/auth/register", json=_register_body())
    assert response.status_code == 201, response.text
    return response.json()


def _auth_headers(session: dict) -> dict:
    return {
        "Authorization": f"Bearer {session['access_token']}",
        "X-Firm-Id": session["firm"]["id"],
    }


def _item_row(
    *,
    row_id: str | None = None,
    updated_at: int,
    device_id: str,
    created_by_user_id: str,
    name: str = "Oil",
) -> dict:
    return {
        "table": "items",
        "id": row_id or str(uuid.uuid4()),
        "data": {
            "name": name,
            "name_normalized": name.lower(),
            "default_bag_weight_g": None,
            "default_rate_base_weight_g": None,
            "default_uom": "kg",
            "track_stock": False,
            "created_by_user_id": created_by_user_id,
            "created_at": updated_at,
            "updated_at": updated_at,
            "updated_by_device_id": device_id,
            "deleted_at": None,
        },
    }


async def test_push_requires_authentication(client: AsyncClient) -> None:
    response = await client.post(
        "/sync/push",
        json={"device_id": "d", "schema_version": 1, "device_time": 0, "rows": []},
    )

    assert response.status_code == 401


async def test_push_requires_membership_in_the_firm_named_by_x_firm_id(
    client: AsyncClient,
) -> None:
    session = await _registered_session(client)
    headers = {
        "Authorization": f"Bearer {session['access_token']}",
        "X-Firm-Id": str(uuid.uuid4()),  # a firm this user does not belong to
    }

    response = await client.post(
        "/sync/push",
        headers=headers,
        json={"device_id": "d", "schema_version": 1, "device_time": 0, "rows": []},
    )

    assert response.status_code == 403


async def test_push_inserts_a_new_item_and_accepts_it(client: AsyncClient) -> None:
    session = await _registered_session(client)
    now = int(time.time() * 1000)
    row = _item_row(updated_at=now, device_id=DEVICE_A, created_by_user_id=session["user"]["id"])

    response = await client.post(
        "/sync/push",
        headers=_auth_headers(session),
        json={"device_id": "d1", "schema_version": 1, "device_time": now, "rows": [row]},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["accepted"] == [{"id": row["id"], "updated_at": now}]
    assert body["rejected"] == []


async def test_push_rejects_a_row_from_an_unsupported_table(client: AsyncClient) -> None:
    session = await _registered_session(client)
    now = int(time.time() * 1000)

    response = await client.post(
        "/sync/push",
        headers=_auth_headers(session),
        json={
            "device_id": "d1",
            "schema_version": 1,
            "device_time": now,
            "rows": [{"table": "transactions", "id": str(uuid.uuid4()), "data": {}}],
        },
    )

    assert response.status_code == 200
    assert response.json()["rejected"][0]["reason"] == "unsupported_table"


async def test_push_rejects_a_timestamp_more_than_5_minutes_in_the_future(
    client: AsyncClient,
) -> None:
    session = await _registered_session(client)
    now = int(time.time() * 1000)
    far_future = now + 6 * 60 * 1000
    row = _item_row(
        updated_at=far_future,
        device_id=DEVICE_A,
        created_by_user_id=session["user"]["id"],
    )

    response = await client.post(
        "/sync/push",
        headers=_auth_headers(session),
        json={"device_id": "d1", "schema_version": 1, "device_time": now, "rows": [row]},
    )

    assert response.status_code == 200
    assert response.json()["rejected"] == [{"id": row["id"], "reason": "clock_skew"}]


async def test_push_is_idempotent_for_a_resend_of_the_same_row(client: AsyncClient) -> None:
    session = await _registered_session(client)
    now = int(time.time() * 1000)
    row = _item_row(updated_at=now, device_id=DEVICE_A, created_by_user_id=session["user"]["id"])

    first = await client.post(
        "/sync/push",
        headers=_auth_headers(session),
        json={"device_id": DEVICE_A, "schema_version": 1, "device_time": now, "rows": [row]},
    )
    second = await client.post(
        "/sync/push",
        headers=_auth_headers(session),
        json={"device_id": DEVICE_A, "schema_version": 1, "device_time": now, "rows": [row]},
    )

    assert first.status_code == second.status_code == 200
    assert second.json()["accepted"] == [{"id": row["id"], "updated_at": now}]


async def test_push_lets_a_newer_write_overwrite_an_older_one(client: AsyncClient) -> None:
    session = await _registered_session(client)
    row_id = str(uuid.uuid4())
    t1 = int(time.time() * 1000)

    older = _item_row(
        row_id=row_id,
        updated_at=t1,
        device_id=DEVICE_A,
        created_by_user_id=session["user"]["id"],
        name="Oil",
    )
    await client.post(
        "/sync/push",
        headers=_auth_headers(session),
        json={"device_id": DEVICE_A, "schema_version": 1, "device_time": t1, "rows": [older]},
    )

    t2 = t1 + 1000
    newer = _item_row(
        row_id=row_id,
        updated_at=t2,
        device_id=DEVICE_B,
        created_by_user_id=session["user"]["id"],
        name="Refined Oil",
    )
    response = await client.post(
        "/sync/push",
        headers=_auth_headers(session),
        json={"device_id": DEVICE_B, "schema_version": 1, "device_time": t2, "rows": [newer]},
    )

    assert response.json()["accepted"] == [{"id": row_id, "updated_at": t2}]


async def test_push_acks_but_ignores_an_older_write_that_arrives_after_a_newer_one(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    session = await _registered_session(client)
    row_id = str(uuid.uuid4())
    t1 = int(time.time() * 1000)

    newer = _item_row(
        row_id=row_id,
        updated_at=t1 + 1000,
        device_id=DEVICE_B,
        created_by_user_id=session["user"]["id"],
        name="Newest",
    )
    await client.post(
        "/sync/push",
        headers=_auth_headers(session),
        json={
            "device_id": DEVICE_B,
            "schema_version": 1,
            "device_time": t1 + 1000,
            "rows": [newer],
        },
    )

    stale = _item_row(
        row_id=row_id,
        updated_at=t1,
        device_id=DEVICE_A,
        created_by_user_id=session["user"]["id"],
        name="Stale",
    )
    response = await client.post(
        "/sync/push",
        headers=_auth_headers(session),
        json={"device_id": DEVICE_A, "schema_version": 1, "device_time": t1, "rows": [stale]},
    )

    # acked (the device's outbox can stop retrying it) but the write itself
    # did not happen
    assert response.json()["accepted"] == [{"id": row_id, "updated_at": t1}]
    current_name = (
        await db_session.execute(text("SELECT name FROM items WHERE id = :id"), {"id": row_id})
    ).scalar_one()
    assert current_name == "Newest"
