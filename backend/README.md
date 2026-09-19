# backend

Phase 2. FastAPI + Postgres sync API for Ledgerly (see `docs/design-spec.md`, Section 4).

## Status

Built so far, all TDD'd against a real Postgres testcontainer (no mocked database):

- `GET /healthz`
- `POST /auth/register` — takes the firm and device this account's owner already created on
  their first device (ids are made on the device, never by the server — see
  `docs/design-spec.md` Section 2), plus their name/email/password. Creates the user (server
  assigns the id), the firm, the owner's `firm_members` row, and the device row, all in one
  transaction. bcrypt password hashing, JWT access token (15 min), rotating per-device refresh
  token.
- `POST /auth/login`, `POST /auth/refresh` — same tokens, for a user (and firm) that already
  exists.
- Schema: `firms`, `users`, `firm_members`, `devices`, `refresh_tokens` (Alembic migrations under
  `migrations/versions/`, hand-written — no autogenerate, same discipline as the SQLite side).

Not built yet: `/auth/google`, `/sync/time`, `/sync/push`, `/sync/pull`; Row Level Security
(deferred until there's a real non-superuser app role to enforce it against — see the first
migration's docstring); deployment to Cloud Run.

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
