import uuid

import jwt
from httpx import AsyncClient

from app.config import settings

DEVICE_ID = "22222222-2222-4222-8222-222222222222"


async def _register(client: AsyncClient, email: str = "rashid@example.com") -> dict:
    response = await client.post(
        "/auth/register",
        json={
            "name": "Rashid",
            "email": email,
            "password": "correct-password",
            "device_id": DEVICE_ID,
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


async def test_register_creates_a_user_and_returns_tokens(client: AsyncClient) -> None:
    body = await _register(client)

    assert body["user"]["email"] == "rashid@example.com"
    assert body["token_type"] == "bearer"
    payload = jwt.decode(body["access_token"], settings.jwt_secret, algorithms=["HS256"])
    assert payload["sub"] == body["user"]["id"]


async def test_register_rejects_a_password_over_the_bcrypt_byte_limit(
    client: AsyncClient,
) -> None:
    # bcrypt hard-fails past 72 bytes; this must be a clean validation error,
    # not a 500 from inside the hashing call.
    response = await client.post(
        "/auth/register",
        json={
            "name": "Rashid",
            "email": "long-password@example.com",
            "password": "x" * 73,
            "device_id": DEVICE_ID,
        },
    )

    assert response.status_code == 422


async def test_register_rejects_a_password_shorter_than_8_characters(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/auth/register",
        json={
            "name": "Rashid",
            "email": "short-password@example.com",
            "password": "short1",
            "device_id": DEVICE_ID,
        },
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
        json={
            "name": "Someone else",
            "email": "duplicate@example.com",
            "password": "another-password",
            "device_id": str(uuid.uuid4()),
        },
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
