# backend

Phase 2. FastAPI + Postgres sync API for Ledgerly (see `docs/design-spec.md`, Section 4).

## Status

Built so far, all TDD'd against a real Postgres testcontainer (no mocked database):

- `GET /healthz`
- `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh` — email+password auth, bcrypt
  password hashing, JWT access tokens (15 min), rotating per-device refresh tokens.
- Schema: `firms`, `users`, `firm_members`, `devices`, `refresh_tokens` (Alembic migrations under
  `migrations/versions/`, hand-written — no autogenerate, same discipline as the SQLite side).

Not built yet: `/auth/google`, `/sync/time`, `/sync/push`, `/sync/pull`; Row Level Security
(deferred until there's a real non-superuser app role to enforce it against — see the first
migration's docstring); firm creation/association for a registered user; deployment to Cloud Run.

## Working on it locally

```
cd backend
python3.11 -m venv .venv
.venv/bin/pip install -e ".[dev]"
.venv/bin/pytest                 # spins up Postgres in Docker automatically
.venv/bin/ruff check . && .venv/bin/ruff format .
```

No `.env` needed for tests — the Postgres testcontainer fixture points every test at its own
throwaway database. Running the API by hand needs a real Postgres reachable at
`LEDGERLY_DATABASE_URL` (see `app/config.py`) and `alembic upgrade head` run against it first.
