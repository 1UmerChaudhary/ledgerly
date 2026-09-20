import time
import uuid

from httpx import AsyncClient

from tests.test_auth import _register_body
from tests.test_sync_push import _auth_headers, _item_row, _registered_session

OTHER_DEVICE = str(uuid.uuid4())


async def _push(client: AsyncClient, session: dict, *rows: dict, device_id: str = "d1") -> dict:
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


async def test_pull_requires_authentication(client: AsyncClient) -> None:
    response = await client.get("/sync/pull", params={"since": 0})

    assert response.status_code == 401


async def test_pull_requires_membership_in_the_firm_named_by_x_firm_id(
    client: AsyncClient,
) -> None:
    session = await _registered_session(client)
    headers = {
        "Authorization": f"Bearer {session['access_token']}",
        "X-Firm-Id": str(uuid.uuid4()),
    }

    response = await client.get("/sync/pull", headers=headers, params={"since": 0})

    assert response.status_code == 403


async def test_pull_returns_a_row_pushed_since_the_cursor(client: AsyncClient) -> None:
    session = await _registered_session(client)
    now = int(time.time() * 1000)
    row = _item_row(
        updated_at=now, device_id=OTHER_DEVICE, created_by_user_id=session["user"]["id"]
    )
    await _push(client, session, row)

    response = await client.get("/sync/pull", headers=_auth_headers(session), params={"since": 0})

    assert response.status_code == 200, response.text
    body = response.json()
    assert len(body["rows"]) == 1
    pulled = body["rows"][0]
    assert pulled["table"] == "items"
    assert pulled["id"] == row["id"]
    assert pulled["data"]["name"] == "Oil"
    assert body["has_more"] is False
    assert body["next_cursor"] >= 1


async def test_pull_excludes_rows_at_or_before_the_given_cursor(client: AsyncClient) -> None:
    session = await _registered_session(client)
    now = int(time.time() * 1000)
    first = _item_row(
        updated_at=now, device_id=OTHER_DEVICE, created_by_user_id=session["user"]["id"]
    )
    push_result = await _push(client, session, first)
    cursor_after_first = (
        await client.get("/sync/pull", headers=_auth_headers(session), params={"since": 0})
    ).json()["next_cursor"]

    second = _item_row(
        updated_at=now + 1,
        device_id=OTHER_DEVICE,
        created_by_user_id=session["user"]["id"],
        name="Ghee",
    )
    await _push(client, session, second)

    response = await client.get(
        "/sync/pull",
        headers=_auth_headers(session),
        params={"since": cursor_after_first},
    )

    body = response.json()
    assert [r["id"] for r in body["rows"]] == [second["id"]]
    assert push_result["accepted"][0]["id"] == first["id"]


async def test_pull_paginates_with_has_more_and_a_usable_next_cursor(
    client: AsyncClient,
) -> None:
    session = await _registered_session(client)
    now = int(time.time() * 1000)
    rows = [
        _item_row(
            updated_at=now + i,
            device_id=OTHER_DEVICE,
            created_by_user_id=session["user"]["id"],
            name=f"Item{i}",
        )
        for i in range(3)
    ]
    await _push(client, session, *rows)

    first_page = await client.get(
        "/sync/pull", headers=_auth_headers(session), params={"since": 0, "limit": 2}
    )
    body = first_page.json()
    assert len(body["rows"]) == 2
    assert body["has_more"] is True

    second_page = await client.get(
        "/sync/pull",
        headers=_auth_headers(session),
        params={"since": body["next_cursor"], "limit": 2},
    )
    second_body = second_page.json()
    assert len(second_body["rows"]) == 1
    assert second_body["has_more"] is False

    all_ids = {r["id"] for r in body["rows"]} | {r["id"] for r in second_body["rows"]}
    assert all_ids == {row["id"] for row in rows}


async def test_pull_deduplicates_a_row_changed_twice_since_the_cursor(
    client: AsyncClient,
) -> None:
    session = await _registered_session(client)
    row_id = str(uuid.uuid4())
    now = int(time.time() * 1000)
    created = _item_row(
        row_id=row_id,
        updated_at=now,
        device_id=OTHER_DEVICE,
        created_by_user_id=session["user"]["id"],
        name="Oil",
    )
    updated = _item_row(
        row_id=row_id,
        updated_at=now + 1000,
        device_id=OTHER_DEVICE,
        created_by_user_id=session["user"]["id"],
        name="Refined Oil",
    )
    await _push(client, session, created)
    await _push(client, session, updated)

    response = await client.get("/sync/pull", headers=_auth_headers(session), params={"since": 0})

    body = response.json()
    assert len(body["rows"]) == 1
    assert body["rows"][0]["data"]["name"] == "Refined Oil"


async def test_pull_only_returns_the_callers_own_firm(client: AsyncClient) -> None:
    session_a = await _registered_session(client)
    other_body = _register_body(email="other@example.com")
    other_body["device"]["id"] = str(uuid.uuid4())
    session_b = (await client.post("/auth/register", json=other_body)).json()
    now = int(time.time() * 1000)
    row_a = _item_row(
        updated_at=now, device_id=OTHER_DEVICE, created_by_user_id=session_a["user"]["id"]
    )
    row_b = _item_row(
        updated_at=now, device_id=OTHER_DEVICE, created_by_user_id=session_b["user"]["id"]
    )
    await _push(client, session_a, row_a)
    await _push(client, session_b, row_b)

    response = await client.get("/sync/pull", headers=_auth_headers(session_a), params={"since": 0})

    assert [r["id"] for r in response.json()["rows"]] == [row_a["id"]]
