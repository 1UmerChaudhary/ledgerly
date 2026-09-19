import os
import subprocess
import sys
from collections.abc import AsyncIterator, Iterator
from pathlib import Path

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from testcontainers.community.postgres import PostgresContainer

from app.db import get_db
from app.main import app

BACKEND_DIR = Path(__file__).resolve().parent.parent


@pytest.fixture(scope="session")
def postgres_url() -> Iterator[str]:
    """One real Postgres for the whole test session, migrated once.

    A throwaway container beats mocking the database entirely: it is the
    generated columns, CHECK constraints and RLS policies that need proving,
    not our own SQL string-building.
    """
    with PostgresContainer("postgres:16-alpine", driver="asyncpg") as pg:
        url = pg.get_connection_url()
        subprocess.run(
            [sys.executable, "-m", "alembic", "upgrade", "head"],
            cwd=BACKEND_DIR,
            env={**os.environ, "LEDGERLY_DATABASE_URL": url},
            check=True,
        )
        yield url


@pytest_asyncio.fixture
async def db_session(postgres_url: str) -> AsyncIterator[AsyncSession]:
    """A session on its own connection, rolled back after each test so tests
    never see one another's rows despite sharing the one migrated database.

    join_transaction_mode="create_savepoint" is what makes this safe even
    when the code under test calls session.commit() itself (every endpoint
    does): commit only releases a savepoint, it can never end the outer
    transaction this fixture rolls back at teardown.
    """
    engine = create_async_engine(postgres_url)
    try:
        async with engine.connect() as conn:
            trans = await conn.begin()
            session = AsyncSession(
                bind=conn, join_transaction_mode="create_savepoint", expire_on_commit=False
            )
            try:
                yield session
            finally:
                await session.close()
                await trans.rollback()
    finally:
        await engine.dispose()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncIterator[AsyncClient]:
    """The real FastAPI app, wired to the same per-test transaction as
    db_session so a test can set up rows directly then hit the HTTP layer.

    An async httpx client over ASGITransport, not Starlette's sync
    TestClient: TestClient drives the app from a separate thread with its
    own event loop, and asyncpg connections can't cross event loops — this
    keeps the whole request on the one loop pytest-asyncio already gave
    this test, the same loop db_session's connection was opened on.
    """

    async def override_get_db() -> AsyncIterator[AsyncSession]:
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            yield c
    finally:
        del app.dependency_overrides[get_db]
