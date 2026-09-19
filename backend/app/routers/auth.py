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

# New firms created through registration start with these; a firm that
# already exists locally with different settings gets reconciled by
# /sync/push later, same as everything else about it.
DEFAULT_NUMBER_GROUPING = "pakistani"


def _password_within_bcrypt_byte_limit(password: str) -> str:
    # bcrypt hard-rejects anything over 72 bytes; catching that as a 500 from
    # inside the hashing call would be a crash on ordinary user input.
    if len(password.encode()) > 72:
        raise ValueError("Password must be at most 72 bytes.")
    return password


class FirmInfo(BaseModel):
    """The firm this device already created locally on first launch (phase 1).

    Ids are made on the device, never by the server (see docs/design-spec.md
    Section 2) — registering just tells the server about it for the first
    time, it doesn't invent a new one.
    """

    id: str
    name: str
    contact_number: str


class DeviceInfo(BaseModel):
    id: str
    name: str
    platform: str
    short_code: str


class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str = Field(min_length=8)
    firm: FirmInfo
    device: DeviceInfo

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


class FirmOut(BaseModel):
    id: str
    name: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserOut
    firm: FirmOut


class RefreshResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


async def _issue_tokens(
    db: AsyncSession, *, user_id: str, name: str, email: str, device_id: str, firm: FirmOut
) -> TokenResponse:
    refresh_token, token_hash = new_refresh_token()
    await _store_refresh_token(db, user_id=user_id, device_id=device_id, token_hash=token_hash)
    await db.commit()
    return TokenResponse(
        access_token=create_access_token(user_id),
        refresh_token=refresh_token,
        user=UserOut(id=user_id, name=name, email=email),
        firm=firm,
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
        await db.execute(
            text(
                """
                INSERT INTO firms (id, name, contact_number, number_grouping, created_at,
                                    updated_at, updated_by_device_id)
                VALUES (:id, :name, :contact_number, :number_grouping, :now, :now, :device_id)
                """
            ),
            {
                "id": body.firm.id,
                "name": body.firm.name,
                "contact_number": body.firm.contact_number,
                "number_grouping": DEFAULT_NUMBER_GROUPING,
                "now": now,
                "device_id": body.device.id,
            },
        )
        user_row = (
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
                    "device_id": body.device.id,
                },
            )
        ).one()
        user_id = str(user_row.id)
        await db.execute(
            text(
                """
                INSERT INTO firm_members (firm_id, user_id, role, created_at, updated_at,
                                           updated_by_device_id)
                VALUES (:firm_id, :user_id, 'owner', :now, :now, :device_id)
                """
            ),
            {
                "firm_id": body.firm.id,
                "user_id": user_id,
                "now": now,
                "device_id": body.device.id,
            },
        )
        await db.execute(
            text(
                """
                INSERT INTO devices (id, firm_id, name, platform, short_code, created_at,
                                      updated_at, updated_by_device_id)
                VALUES (:id, :firm_id, :name, :platform, :short_code, :now, :now, :id)
                """
            ),
            {
                "id": body.device.id,
                "firm_id": body.firm.id,
                "name": body.device.name,
                "platform": body.device.platform,
                "short_code": body.device.short_code,
                "now": now,
            },
        )
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status_code=409, detail="An account with that email already exists."
        ) from e

    return await _issue_tokens(
        db,
        user_id=user_id,
        name=body.name,
        email=body.email,
        device_id=body.device.id,
        firm=FirmOut(id=body.firm.id, name=body.firm.name),
    )


@router.post("/login", response_model=TokenResponse)
async def login(
    body: LoginRequest,
    db: AsyncSession = Depends(get_db),  # noqa: B008 -- FastAPI Depends()
) -> TokenResponse:
    row = (
        await db.execute(
            text(
                """
                SELECT u.id, u.name, u.email, u.password_hash, f.id AS firm_id,
                       f.name AS firm_name
                FROM users u
                JOIN firm_members fm ON fm.user_id = u.id AND fm.deleted_at IS NULL
                JOIN firms f ON f.id = fm.firm_id
                WHERE u.email = :email AND u.deleted_at IS NULL
                """
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
        db,
        user_id=str(row.id),
        name=row.name,
        email=row.email,
        device_id=body.device_id,
        firm=FirmOut(id=str(row.firm_id), name=row.firm_name),
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
