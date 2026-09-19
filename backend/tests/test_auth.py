import uuid

import jwt
from httpx import AsyncClient

from app.config import settings

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
    response = await client.post("/auth/register", json=_register_body(email))
    assert response.status_code == 201, response.text
    return response.json()


async def test_register_creates_a_user_and_returns_tokens(client: AsyncClient) -> None:
    body = await _register(client)

    assert body["user"]["email"] == "rashid@example.com"
    assert body["token_type"] == "bearer"
    payload = jwt.decode(body["access_token"], settings.jwt_secret, algorithms=["HS256"])
    assert payload["sub"] == body["user"]["id"]


async def test_register_creates_the_firm_with_the_client_supplied_id(
    client: AsyncClient,
) -> None:
    firm_id = str(uuid.uuid4())
    body = _register_body()
    body["firm"]["id"] = firm_id

    response = await client.post("/auth/register", json=body)

    assert response.status_code == 201, response.text
    result = response.json()
    assert result["firm"]["id"] == firm_id
    assert result["firm"]["name"] == "Al-Madina Oil Mills"


async def test_login_returns_the_users_firm(client: AsyncClient) -> None:
    registered = await _register(client)

    response = await client.post(
        "/auth/login",
        json={
            "email": "rashid@example.com",
            "password": "correct-password",
            "device_id": DEVICE_ID,
        },
    )

    assert response.status_code == 200
    assert response.json()["firm"]["id"] == registered["firm"]["id"]


async def test_register_rejects_a_password_over_the_bcrypt_byte_limit(
    client: AsyncClient,
) -> None:
    # bcrypt hard-fails past 72 bytes; this must be a clean validation error,
    # not a 500 from inside the hashing call.
    response = await client.post(
        "/auth/register",
        json=_register_body(email="long-password@example.com", password="x" * 73),
    )

    assert response.status_code == 422


async def test_register_rejects_a_password_shorter_than_8_characters(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/auth/register",
        json=_register_body(email="short-password@example.com", password="short1"),
    )

    assert response.status_code == 422


async def test_login_rejects_a_password_over_the_bcrypt_byte_limit_without_crashing(
    client: AsyncClient,
) -> None:
    await _register(client)

    response = await client.post(
        "/auth/login",
        json={"email": "rashid@example.com", "password": "x" * 73, "device_id": DEVICE_ID},
    )

    assert response.status_code == 422


async def test_register_rejects_a_duplicate_email(client: AsyncClient) -> None:
    await _register(client, email="duplicate@example.com")

    response = await client.post(
        "/auth/register",
        json=_register_body(email="duplicate@example.com", name="Someone else"),
    )

    assert response.status_code == 409


async def test_login_returns_tokens_for_the_correct_password(client: AsyncClient) -> None:
    await _register(client)

    response = await client.post(
        "/auth/login",
        json={
            "email": "rashid@example.com",
            "password": "correct-password",
            "device_id": DEVICE_ID,
        },
    )

    assert response.status_code == 200
    assert response.json()["user"]["email"] == "rashid@example.com"


async def test_login_rejects_the_wrong_password(client: AsyncClient) -> None:
    await _register(client)

    response = await client.post(
        "/auth/login",
        json={
            "email": "rashid@example.com",
            "password": "wrong-password",
            "device_id": DEVICE_ID,
        },
    )

    assert response.status_code == 401


async def test_login_rejects_an_unknown_email(client: AsyncClient) -> None:
    response = await client.post(
        "/auth/login",
        json={"email": "nobody@example.com", "password": "anything", "device_id": DEVICE_ID},
    )

    assert response.status_code == 401


async def test_refresh_issues_a_new_access_token(client: AsyncClient) -> None:
    tokens = await _register(client)

    response = await client.post("/auth/refresh", json={"refresh_token": tokens["refresh_token"]})

    assert response.status_code == 200
    new_access = response.json()["access_token"]
    payload = jwt.decode(new_access, settings.jwt_secret, algorithms=["HS256"])
    assert payload["sub"] == tokens["user"]["id"]


async def test_refresh_rotates_the_token_so_the_old_one_cannot_be_reused(
    client: AsyncClient,
) -> None:
    tokens = await _register(client)
    first_refresh = (
        await client.post("/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    ).json()

    reuse = await client.post("/auth/refresh", json={"refresh_token": tokens["refresh_token"]})

    assert reuse.status_code == 401
    # the rotated token still works, proving rotation issued a real replacement
    second_refresh = await client.post(
        "/auth/refresh", json={"refresh_token": first_refresh["refresh_token"]}
    )
    assert second_refresh.status_code == 200


async def test_refresh_rejects_an_unknown_token(client: AsyncClient) -> None:
    response = await client.post("/auth/refresh", json={"refresh_token": "not-a-real-token"})

    assert response.status_code == 401
