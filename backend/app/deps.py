from uuid import UUID

from fastapi import Depends, Header, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import PyJWTError, decode
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.db import get_db

_bearer = HTTPBearer()


async def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),  # noqa: B008 -- FastAPI Depends()
) -> str:
    try:
        payload = decode(credentials.credentials, settings.jwt_secret, algorithms=["HS256"])
    except PyJWTError as e:
        raise HTTPException(status_code=401, detail="Invalid or expired access token.") from e
    return payload["sub"]


async def get_current_firm_id(
    # Typed as a real UUID (not str) so a malformed header is a clean 422
    # from FastAPI's own validation, not a raw asyncpg type error.
    x_firm_id: UUID = Header(alias="X-Firm-Id"),  # noqa: B008 -- FastAPI Header()
    user_id: str = Depends(get_current_user_id),  # noqa: B008 -- FastAPI Depends()
    db: AsyncSession = Depends(get_db),  # noqa: B008 -- FastAPI Depends()
) -> str:
    """Every firm-scoped endpoint depends on this, never just on the user:
    a valid token proves who you are, not which firm's data you may touch.
    """
    row = (
        await db.execute(
            text(
                "SELECT 1 FROM firm_members "
                "WHERE firm_id = :firm_id AND user_id = :user_id AND deleted_at IS NULL"
            ),
            {"firm_id": x_firm_id, "user_id": user_id},
        )
    ).one_or_none()
    if row is None:
        raise HTTPException(status_code=403, detail="Not a member of this firm.")
    return str(x_firm_id)
