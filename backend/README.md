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
- `GET /sync/time` — the server's clock, so a device can seed its offset before it has ever
  logged in.
- `POST /sync/push` — bearer token + `X-Firm-Id` header required (checked against
  `firm_members`). Handles the `items` table end to end: unseen row → insert; seen row with a
  newer `(updated_at, updated_by_device_id)` → update; older or identical → acked but not
  applied (the device learns the real state on its next pull); a timestamp more than 5 minutes
  in the future → rejected as `clock_skew`; any other table name → rejected as
  `unsupported_table`, not silently accepted half-built. Sequence numbers for `sync_changes` are
  reserved in one row-locked `UPDATE firms SET next_seq = ...`, so two devices pushing at once
  can't interleave.
- Schema: `firms`, `users`, `firm_members`, `devices`, `refresh_tokens`, `items`, `sync_changes`
  (Alembic migrations under `migrations/versions/`, hand-written — no autogenerate, same
  discipline as the SQLite side).

Not built yet: `/auth/google`, `/sync/pull`, and push support for every table besides `items`
(customers, transactions — the bill-as-unit case, customer dedup/merge, tombstone un-delete —
per `docs/design-spec.md` Section 4 step 3). Row Level Security is deferred until there's a real
non-superuser app role to enforce it against (see the first migration's docstring). Deployment
to Cloud Run hasn't started.

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
