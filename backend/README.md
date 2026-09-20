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
  reserved in one row-locked `UPDATE firms SET next_seq = ...` (1-based — see the function's
  docstring for why 0-based broke `since=0`), so two devices pushing at once can't interleave.
  Each row's write happens inside its own SAVEPOINT so one bad row can't poison the batch.
- `GET /sync/pull?since=&limit=` — same auth. `limit` bounds the raw `sync_changes` rows read,
  not the distinct rows returned (a row that changed many times still costs one output row, but
  can still fill most of a page by itself); `next_cursor` is always the highest raw sequence
  number actually read, so a page can never skip an entry that landed between two deduplicated
  rows. Both `items` and `customers` are wired up.
- Customers get one extra push rule items don't need: an unseen row whose phone matches an
  existing *live* customer in the firm is still accepted, not rejected — same name too →
  auto-merged (the incoming row is never created; a `rewrite` in the push response tells the
  device to use the existing id instead), different name → both rows kept and flagged
  `needs_review` for a person to sort out later. The server's `customers` table deliberately has
  no hard uniqueness constraint on phone (unlike the device's SQLite copy, which blocks a
  duplicate at creation time) — the whole point of `needs_review` is letting two rows share a
  phone until it's resolved; a hard constraint would make that impossible.
- `transactions` (a bill) push/pull as a unit with its lines — never diffed line by line, always
  replaced wholesale, same as the device does on pull. Unseen → insert header + lines. Seen with
  a newer write → the *losing* (current) version is archived to `transaction_history` first
  (reason `sync_overwrite`), then the header is updated and its lines replaced. Seen with an
  older write → the incoming (losing) version is archived instead and the live row is left
  alone — acked so the pushing device's outbox clears it, but nothing changes until its next
  pull. A history row's id is deterministic (`uuid5` of the transaction id + the losing write's
  own `(updated_at, device)`), so the same conflict discovered twice collides into one row
  instead of duplicating. Real Postgres limitation caught while building the schema, not by
  inspection: unlike SQLite, Postgres refuses to let one generated column reference another —
  `transaction_lines.final_amount` had to duplicate `calculated_total`'s expression inline rather
  than reference the column.
- Schema: `firms`, `users`, `firm_members`, `devices`, `refresh_tokens`, `items`, `customers`,
  `transactions`, `transaction_lines`, `transaction_history`, `sync_changes` (Alembic migrations
  under `migrations/versions/`, hand-written — no autogenerate, same discipline as the SQLite
  side).

Not built yet: `/auth/google`; `transaction_history` isn't itself pushed/pulled yet, so a
conflict's loser is visible on the server but not synced to every device; a bill referencing a
tombstoned or merged customer isn't handled (docs/design-spec.md Section 4 step 3); customer/item
names aren't enriched into a history snapshot for display. Row Level Security is deferred until
there's a real non-superuser app role to enforce it against (see the first migration's
docstring).

## Deploying

Cost-driven choice for now: [Render](https://render.com) for the API (free web service, no card)
and [Neon](https://neon.tech) for Postgres (free tier, scales to zero, no card) — Cloud Run +
Cloud SQL is the originally-planned pair and stays the plan once there's a working payment
method for the personal GCP project; nothing about the code differs either way, since both are
"a FastAPI app behind an ASGI server, talking to a Postgres connection string."

1. Create a Neon project, copy its connection string, and run migrations against it directly —
   from any machine with this repo, once (not from Render — see `render.yaml`'s comment on why
   migrations are deliberately not part of the deploy step):
   ```
   LEDGERLY_DATABASE_URL="<neon connection string>" .venv/bin/python -m alembic upgrade head
   ```
2. On Render: "New +" → "Blueprint" → connect the `1UmerChaudhary/ledgerly` repo. Render reads
   `render.yaml` at the repo root and creates the service, asking only for
   `LEDGERLY_DATABASE_URL` (paste the same Neon connection string) — `LEDGERLY_JWT_SECRET` is
   generated automatically.
3. Once deployed, `https://<service>.onrender.com/healthz` should return `{"status": "ok"}`. The
   free plan spins the service down after 15 minutes of no traffic; the first request after that
   takes a few seconds to wake it back up — the app's Sync now button will just look slow that
   one time, not broken.

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
