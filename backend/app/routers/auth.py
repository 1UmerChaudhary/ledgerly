import time

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, Field, field_validator
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.security import (
    create_access_token,
    hash_password,
    hash_refresh_token,
    new_refresh_token,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])

# A refresh token outlives the access token by a lot on purpose: it is what
# lets a device stay signed in between app launches without re-typing a
# password, same as any mobile app's "remember me".
REFRESH_TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30


def _password_within_bcrypt_byte_limit(password: str) -> str:
    # bcrypt hard-rejects anything over 72 bytes; catching that as a 500 from
    # inside the hashing call would be a crash on ordinary user input.
    if len(password.encode()) > 72:
        raise ValueError("Password must be at most 72 bytes.")
    return password


class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str = Field(min_length=8)
    device_id: str

    @field_validator("password")
    @classmethod
    def _password_limit(cls, v: str) -> str:
        return _password_within_bcrypt_byte_limit(v)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    device_id: str

    @field_validator("password")
    @classmethod
    def _password_limit(cls, v: str) -> str:
        return _password_within_bcrypt_byte_limit(v)


class RefreshRequest(BaseModel):
    refresh_token: str


class UserOut(BaseModel):
    id: str
    name: str
    email: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserOut


class RefreshResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


async def _issue_tokens(
    db: AsyncSession, *, user_id: str, name: str, email: str, device_id: str
) -> TokenResponse:
    refresh_token, token_hash = new_refresh_token()
    await _store_refresh_token(db, user_id=user_id, device_id=device_id, token_hash=token_hash)
    await db.commit()
    return TokenResponse(
        access_token=create_access_token(user_id),
        refresh_token=refresh_token,
        user=UserOut(id=user_id, name=name, email=email),
    )


async def _store_refresh_token(
    db: AsyncSession, *, user_id: str, device_id: str, token_hash: str
) -> None:
    now = int(time.time())
    await db.execute(
        text(
            """
            INSERT INTO refresh_tokens (user_id, device_id, token_hash, created_at, expires_at)
            VALUES (:user_id, :device_id, :token_hash, :now, :expires_at)
            ON CONFLICT (user_id, device_id) DO UPDATE SET
                token_hash = excluded.token_hash,
                created_at = excluded.created_at,
                expires_at = excluded.expires_at
            """
        ),
        {
            "user_id": user_id,
            "device_id": device_id,
            "token_hash": token_hash,
            "now": now,
            "expires_at": now + REFRESH_TOKEN_TTL_SECONDS,
        },
    )


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(
    body: RegisterRequest,
    db: AsyncSession = Depends(get_db),  # noqa: B008 -- FastAPI Depends()
) -> TokenResponse:
    now = int(time.time())
    try:
        row = (
            await db.execute(
                text(
                    """
                    INSERT INTO users (name, email, password_hash, created_at, updated_at,
                                        updated_by_device_id)
                    VALUES (:name, :email, :password_hash, :now, :now, :device_id)
                    RETURNING id
                    """
                ),
                {
                    "name": body.name,
                    "email": body.email,
                    "password_hash": hash_password(body.password),
                    "now": now,
                    "device_id": body.device_id,
                },
            )
        ).one()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status_code=409, detail="An account with that email already exists."
        ) from e

    return await _issue_tokens(
        db, user_id=str(row.id), name=body.name, email=body.email, device_id=body.device_id
    )


@router.post("/login", response_model=TokenResponse)
async def login(
    body: LoginRequest,
    db: AsyncSession = Depends(get_db),  # noqa: B008 -- FastAPI Depends()
) -> TokenResponse:
    row = (
        await db.execute(
            text(
                "SELECT id, name, email, password_hash FROM users "
                "WHERE email = :email AND deleted_at IS NULL"
            ),
            {"email": body.email},
        )
    ).one_or_none()
    if (
        row is None
        or row.password_hash is None
        or not verify_password(body.password, row.password_hash)
    ):
        raise HTTPException(status_code=401, detail="Invalid email or password.")

    return await _issue_tokens(
        db, user_id=str(row.id), name=row.name, email=row.email, device_id=body.device_id
    )


@router.post("/refresh", response_model=RefreshResponse)
async def refresh(
    body: RefreshRequest,
    db: AsyncSession = Depends(get_db),  # noqa: B008 -- FastAPI Depends()
) -> RefreshResponse:
    now = int(time.time())
    row = (
        await db.execute(
            text(
                "SELECT user_id, device_id FROM refresh_tokens "
                "WHERE token_hash = :token_hash AND expires_at > :now"
            ),
            {"token_hash": hash_refresh_token(body.refresh_token), "now": now},
        )
    ).one_or_none()
    if row is None:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token.")

    new_token, new_hash = new_refresh_token()
    await _store_refresh_token(
        db, user_id=str(row.user_id), device_id=str(row.device_id), token_hash=new_hash
    )
    await db.commit()
    return RefreshResponse(
        access_token=create_access_token(str(row.user_id)), refresh_token=new_token
    )
