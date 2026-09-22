import uuid
from unittest.mock import patch

from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

DEVICE_ID = "22222222-2222-4222-8222-222222222222"


def _register_body(email: str = "rashid@example.com", **overrides: object) -> dict:
    body: dict = {
        "name": "Rashid",
        "email": email,
        "password": "correct-password",
        "firm": {
            "id": str(uuid.uuid4()),
            "name": "Al-Madina Oil Mills",
            "contact_number": "0300-1234567",
        },
        "device": {
            "id": DEVICE_ID,
            "name": "Rashid's Laptop",
            "platform": "windows",
            "short_code": "A3F9",
        },
    }
    body.update(overrides)
    return body


async def _register(client: AsyncClient, email: str = "rashid@example.com") -> dict:
    # A fresh device id per registration: devices.id is the primary key, so two
    # registrations sharing the module-level DEVICE_ID collide on the device
    # row and surface as the users-email 409 instead.
    body = _register_body(email)
    body["device"] = {**body["device"], "id": str(uuid.uuid4())}
    response = await client.post("/auth/register", json=body)
    assert response.status_code == 201, response.text
    return response.json()


def _google_body(sub: str, email: str = "new@example.com", **overrides: object) -> dict:
    body: dict = {
        "id_token": "fake",
        "firm": {
            "id": str(uuid.uuid4()),
            "name": "Test Mill",
            "contact_number": "0300-1234567",
        },
        "device": {
            "id": str(uuid.uuid4()),
            "name": "Phone",
            "platform": "android",
            "short_code": "AB12",
        },
    }
    body.update(overrides)
    return body


def _fake_verified_payload(sub: str, email: str, email_verified: bool = True) -> dict:
    return {"sub": sub, "email": email, "email_verified": email_verified, "name": "Google User"}


async def test_google_sign_in_creates_a_new_user_and_firm(client: AsyncClient) -> None:
    with patch(
        "app.routers.auth.verify_google_id_token",
        return_value=_fake_verified_payload("g-sub-1", "new@example.com"),
    ):
        response = await client.post("/auth/google", json=_google_body("g-sub-1"))

    assert response.status_code == 201, response.text
    body = response.json()
    assert body["user"]["email"] == "new@example.com"
    assert body["token_type"] == "bearer"


async def test_google_sign_in_logs_in_an_existing_google_user(client: AsyncClient) -> None:
    payload = _fake_verified_payload("g-sub-2", "returning@example.com")
    request_body = _google_body("g-sub-2", "returning@example.com")
    with patch("app.routers.auth.verify_google_id_token", return_value=payload):
        first = await client.post("/auth/google", json=request_body)
        assert first.status_code == 201, first.text
        firm_id = first.json()["firm"]["id"]

        # Sign in again with the SAME google sub but a DIFFERENT client-supplied
        # firm/device (a second phone, or a reinstalled app) -- must log into
        # the same existing firm, never create a second one.
        second = await client.post(
            "/auth/google",
            json=_google_body("g-sub-2", "returning@example.com"),
        )

    assert second.status_code == 201, second.text
    assert second.json()["firm"]["id"] == firm_id
    assert second.json()["user"]["email"] == "returning@example.com"


async def test_google_sign_in_does_not_auto_link_an_existing_password_account(
    client: AsyncClient,
) -> None:
    registered = await _register(client, email="passwordonly@example.com")

    with patch(
        "app.routers.auth.verify_google_id_token",
        return_value=_fake_verified_payload("g-sub-3", "passwordonly@example.com"),
    ):
        response = await client.post(
            "/auth/google", json=_google_body("g-sub-3", "passwordonly@example.com")
        )

    assert response.status_code == 409
    assert response.json()["detail"] == "email_exists_unlinked"

    # The password account must not have been silently linked -- logging in
    # with the ORIGINAL password must still work and return the same user.
    login = await client.post(
        "/auth/login",
        json={
            "email": "passwordonly@example.com",
            "password": "correct-password",
            "device_id": DEVICE_ID,
        },
    )
    assert login.status_code == 200
    assert login.json()["user"]["id"] == registered["user"]["id"]


async def test_google_sign_in_rejects_an_unverified_email_even_on_a_match(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    registered = await _register(client, email="unverified@example.com")

    payload = _fake_verified_payload("g-sub-4", "unverified@example.com", email_verified=False)
    with patch("app.routers.auth.verify_google_id_token", return_value=payload):
        response = await client.post(
            "/auth/google", json=_google_body("g-sub-4", "unverified@example.com")
        )

    # An unverified email is never trusted as a match, so this never reaches
    # the email_exists_unlinked check -- it falls through to the same
    # first-time-registration path as a brand-new address. But `users.email`
    # is UNIQUE across the whole table (no partial index on deleted_at),
    # regardless of verification status: one email can only ever belong to
    # one live user. So creating a second, "shadow" account for an email
    # that's already taken always collides with that constraint, the same
    # way any other duplicate-email attempt does -- there's no special-case
    # account-takeover-prevention logic to write here, the schema already
    # makes this impossible.
    assert response.status_code == 409
    assert response.json()["detail"] == "That account already exists."

    # The original account this collided with must be completely
    # unaffected: still logs in with its password, and was never linked to
    # the Google identity that collided with it.
    login = await client.post(
        "/auth/login",
        json={
            "email": "unverified@example.com",
            "password": "correct-password",
            "device_id": DEVICE_ID,
        },
    )
    assert login.status_code == 200
    assert login.json()["user"]["id"] == registered["user"]["id"]

    row = (
        await db_session.execute(
            text("SELECT google_sub FROM users WHERE id = :id"),
            {"id": registered["user"]["id"]},
        )
    ).one()
    assert row.google_sub is None


async def test_google_link_requires_an_authenticated_session(client: AsyncClient) -> None:
    response = await client.post("/auth/google/link", json={"id_token": "fake"})
    assert response.status_code == 401


async def test_google_link_sets_google_sub_on_the_authenticated_users_account(
    client: AsyncClient,
) -> None:
    registered = await _register(client, email="linkme@example.com")
    access_token = registered["access_token"]

    with patch(
        "app.routers.auth.verify_google_id_token",
        return_value=_fake_verified_payload("g-sub-5", "linkme@example.com"),
    ):
        link_response = await client.post(
            "/auth/google/link",
            json={"id_token": "fake"},
            headers={"Authorization": f"Bearer {access_token}"},
        )
    assert link_response.status_code == 204

    # A subsequent Google sign-in with that sub must now log into the SAME
    # account this token belonged to, not create a new one.
    with patch(
        "app.routers.auth.verify_google_id_token",
        return_value=_fake_verified_payload("g-sub-5", "linkme@example.com"),
    ):
        signed_in = await client.post(
            "/auth/google", json=_google_body("g-sub-5", "linkme@example.com")
        )
    assert signed_in.status_code == 201
    assert signed_in.json()["user"]["id"] == registered["user"]["id"]


async def test_google_link_returns_409_when_that_google_account_is_already_linked(
    client: AsyncClient,
) -> None:
    # users_google_sub_unique is table-wide, so linking a Google identity that
    # already belongs to someone else is an everyday collision -- a second
    # person on a shared machine, or a mistyped account in the picker -- not
    # an exotic one. Every other collision path in this router answers 409;
    # this one has to as well, or it answers 500 with a traceback.
    first = await _register(client, email="first@example.com")
    with patch(
        "app.routers.auth.verify_google_id_token",
        return_value=_fake_verified_payload("g-sub-shared", "first@example.com"),
    ):
        taken = await client.post(
            "/auth/google/link",
            json={"id_token": "fake"},
            headers={"Authorization": f"Bearer {first['access_token']}"},
        )
    assert taken.status_code == 204

    second = await _register(client, email="second@example.com")
    with patch(
        "app.routers.auth.verify_google_id_token",
        return_value=_fake_verified_payload("g-sub-shared", "second@example.com"),
    ):
        response = await client.post(
            "/auth/google/link",
            json={"id_token": "fake"},
            headers={"Authorization": f"Bearer {second['access_token']}"},
        )

    assert response.status_code == 409, response.text
    assert "already" in response.json()["detail"].lower()


async def test_a_failed_google_link_leaves_both_accounts_exactly_as_they_were(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    first = await _register(client, email="keeper@example.com")
    with patch(
        "app.routers.auth.verify_google_id_token",
        return_value=_fake_verified_payload("g-sub-keeper", "keeper@example.com"),
    ):
        await client.post(
            "/auth/google/link",
            json={"id_token": "fake"},
            headers={"Authorization": f"Bearer {first['access_token']}"},
        )
    second = await _register(client, email="loser@example.com")
    with patch(
        "app.routers.auth.verify_google_id_token",
        return_value=_fake_verified_payload("g-sub-keeper", "loser@example.com"),
    ):
        await client.post(
            "/auth/google/link",
            json={"id_token": "fake"},
            headers={"Authorization": f"Bearer {second['access_token']}"},
        )

    rows = (
        await db_session.execute(
            text("SELECT email, google_sub FROM users ORDER BY email"),
        )
    ).all()
    linked = {row.email: row.google_sub for row in rows}
    assert linked["keeper@example.com"] == "g-sub-keeper"
    assert linked["loser@example.com"] is None
