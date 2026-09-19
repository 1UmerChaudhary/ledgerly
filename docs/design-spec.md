# Ledgerly — offline-first ledger for trading/processing firms

Design spec + Phase 1 implementation plan. Produced in an interactive learning session and revised
after two rounds of independent review (sync/data; product/UI/ops). Every choice carries its reason.

## Context

Build a sellable, general-purpose ledger product for small trading and processing firms (first
customer: an oil mill; product must stay generic). Desktop first (Windows, developed on macOS),
Android second, cloud sync later on the user's own GCP project. Offline-first, single currency,
keyboard-only operation, non-technical users. Convertible to online/multi-user later with no data
loss. The user is learning system design along the way.

## Decisions

| Topic | Decision | Why |
|---|---|---|
| Stack | Flutter (Dart), Riverpod, drift (SQLite) | One codebase for Windows/Android/iOS/macOS; strong offline SQLite |
| Backend (phase 2) | FastAPI + Postgres (Cloud SQL) on Cloud Run, Alembic | User's comfort zone; sync API is small |
| Platform order | Windows → Android → iOS/macOS | Sell sooner |
| Mobile role | Full data entry | So conflict handling is real |
| Sync model | Newer-wins on **bills as the unit**; losers always written to history (deterministic id); balances are never stored, so nothing to sync or repair | User chose simplicity; guardrails close the money-loss hole |
| Balances | **Computed, never stored.** Running balance via SQL window function; dashboard via `customer_balances` view. No `balance_before/after`, no `balance_cached`, no `replay()`. Benchmark test (200k txns; balance aggregate and raw ledger query < 200 ms, 20k materialised ledger entries < 1.5 s, budgets sized for CI runners) guards the assumption | One source of truth; removes the whole cache-maintenance and cache-sync problem; derived data is free to add later |
| Clock | Hybrid logical clock per device seeded from DB on every start + learned server offset; server **rejects** (never clamps) skewed stamps; strict `(hlc, device_id)` order | Client clocks never sole authority |
| Bills | Multi-item: header + lines, one `version`; lines replaced wholesale on pull; stable line ids across edits | Mill sells oil + oilcake in one bill; diff needs line identity |
| Walk-in sales | `customer_id` nullable; Cash Sales view; never in a ledger | Counter sales exist |
| Inventory / production | Phase 5. Prerequisite now: `items` + `item_id` on lines | Identity is expensive to retrofit; derived stock is free later |
| Money / weight | Integers: paisa, grams. Whole rupees shown by default; Pakistani grouping 12,34,567 (per-firm setting); "Rs" not ₨ | Floats drift; users read lakh/crore; fonts |
| Balance | One signed int per customer: + receivable, − giveable | Four spec rules collapse to one formula |
| Paper | 80 mm thermal (USB, Windows driver) for slips; A4 ledgers; PDF + 300-DPI PNG | User's printers |
| Language | English; ARB localization; directional layout; prints stay English | Urdu later without rewrite |
| Login (phase 2) | Email + password and Google sign-in; token names the user, `X-Firm-Id` header checked against memberships | User's choice; multi-firm |
| Monetisation | Desktop free; sellable unit = cloud sync/backup; licensing server-side | No offline DRM |
| Windows signing | Unsigned for now | Zero cost until paying firms |
| Encryption | Ship SQLCipher-capable driver, **no UI in phase 1**; phase 2 adds passphrase + printed recovery code; encryption detected from file header | Key-only-in-keychain makes backups unrestorable after PC death |
| After save | Read-only "Saved" state: Ctrl+P print, Ctrl+N next bill, Esc ledger | Clerk throughput |
| Multi-firm | One DB file per firm from day one; firm picker UI deferred | Layout is free now, UI is not |
| Repo | `~/Desktop/ledgerly`, new repo on user's personal GitHub | Not inside Laam-Python |

## Phases

1. Core + desktop app, local-only, sync-ready schema, backups, printing  ← this plan implements
2. Cloud backend + sync (user's GCP project), passphrase encryption
3. Android layouts
4. Multi-user login, roles, merge-customers, firm picker
5. Inventory + production runs

---

## Section 1 — Architecture

Arrows only point downward. UI never imports DB; domain never imports Flutter or drift.

```
UI (screens/widgets) → Application (Riverpod controllers) → Domain (pure Dart: BalanceEngine,
RateCalculator, Hlc, normalizeName, Money/Weight value types + formatters/parsers, entities)
→ Data (repository interfaces + drift impl, BackupService) → Sync (outbox, push/pull, HTTP)
                    ⇅ HTTPS JSON        Cloud: FastAPI → Cloud SQL Postgres
```

```
ledgerly/                       (Dart pub workspace)
  packages/ledgerly_core/       pure Dart. Zero Flutter/drift imports, compiler-enforced.
  app/                          Flutter app: UI, controllers, drift DB, backups, printing, sync.
  backend/                      FastAPI (phase 2; folder + README only in phase 1).
  docs/                         this spec, diagrams, ADRs.
  .github/workflows/            analyze+test (ubuntu); Windows installer build (windows-latest).
```

Riverpod ≈ FastAPI `Depends()`: `ref.watch(x)` ≈ `Depends(x)`; `overrideWithValue` ≈
`dependency_overrides`. Repository interfaces live in core; `app` providers pick the implementation.

Files: `%LOCALAPPDATA%/Ledgerly/firms/<firm_id>.db` (WAL, opened in a background isolate);
`%LOCALAPPDATA%/Ledgerly/backups/`; global prefs (device id, last firm, printer, backup folder).

## Section 2 — Schema

Same tables on device (SQLite, one file per firm) and server (Postgres). Revised after independent
schema reviews by three models (Opus, Sonnet, Haiku); their consensus findings are folded in below.

**Global rules**
- Money in paisa, weight in grams: SQLite `INTEGER` (64-bit), Postgres `bigint` (never `integer`:
  Rs 21.4M overflows int32; `rate × weight` intermediates overflow far sooner).
- Ids: uuid v4 made on the device. SQLite `TEXT CHECK(id = lower(id) AND length(id) = 36)`;
  Postgres `uuid`. Key model: `id` is the PRIMARY KEY (globally unique), `firm_id NOT NULL`, plus
  `UNIQUE(firm_id, id)` so every child FK is composite `(firm_id, parent_id)` → a child can never be
  re-parented across firms. Postgres RLS policy on every table: `firm_id = current_setting('app.firm_id')`.
- Dates: `entry_date` stored as ISO `YYYY-MM-DD` text in SQLite (`CHECK(entry_date GLOB
  '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')`), `date` in Postgres; it is the device's local
  calendar day, serialised as a plain date string in sync. `dd/MM/yyyy` exists only in the UI.
- Timestamps (`created_at`, `updated_at`, `changed_at`, `printed_at`): HLC milliseconds, integer.
- Every syncable table: `id, firm_id, created_at, updated_at, updated_by_device_id, deleted_at?`
  (the "sync cols"). All columns NOT NULL unless marked `?`.
- Enumerations are text with `CHECK(col IN (...))`, no `ELSE` anywhere that maps them. Extending an
  enum in SQLite means a drift table rebuild (`alterTable`); accepted, since a backup precedes every
  migration and tables are small. Postgres uses CHECK, not native enums (values can be added/removed).
- Derived-data rule, stated precisely: **balances are never stored**. Per-line arithmetic is a
  STORED generated column (the database computes it, so device and server cannot disagree). Bill
  header totals are stored and guarded by an integrity test (see Section 3).

```
firms             id, name, contact_number, address?, logo_blob?, number_grouping (pk|western),
                  show_paisa bool, default_country_code ("92"), sync cols
                  server-only: next_seq bigint=0, min_valid_cursor bigint=0
users             id, name, sync cols  (global identity table, NO firm_id; phase 2 adds email UNIQUE,
                  password_hash?, google_sub?; RLS: visible only via shared firm_members)
firm_members      id, firm_id, user_id, role CHECK(owner|manager|clerk), sync cols
                  UNIQUE(firm_id, user_id) WHERE deleted_at IS NULL
devices           id, firm_id, name, platform, short_code (4 base32 chars from device uuid),
                  sync cols   UNIQUE(firm_id, short_code)
items             id, firm_id, name, name_normalized, default_bag_weight_g?,
                  default_rate_base_weight_g?, default_uom CHECK(kg|unit)='kg', track_stock bool=false,
                  created_by_user_id, sync cols
customers         id, firm_id, name, name_normalized, phone?, phone_normalized?, notes?,
                  created_by_user_id, merged_into_id? (FK customers), needs_review bool=false, sync cols
                  UNIQUE(firm_id, phone_normalized) WHERE deleted_at IS NULL AND merged_into_id IS NULL
                  (merge also sets loser.deleted_at, so "live" has one meaning everywhere)
transactions      id, firm_id, customer_id? (null = walk-in),
                  device_short_code, display_seq int   (display_no is RENDERED as "A3F9-1043";
                  UNIQUE(firm_id, device_short_code, display_seq); allocator = max(display_seq)+1
                  for this device; format is changeable later because it is not stored),
                  type CHECK(sale|purchase|cash_in|cash_out|opening_balance|adjustment),
                  entry_date, description?, version int=1,
                  calculated_total, overridden_total?, overridden_total_basis?, final_amount,
                  signed_amount  GENERATED ALWAYS AS (
                      CASE type WHEN 'sale' THEN final_amount
                                WHEN 'cash_out' THEN final_amount
                                WHEN 'opening_balance' THEN final_amount
                                WHEN 'adjustment' THEN final_amount        -- already signed
                                WHEN 'purchase' THEN -final_amount
                                WHEN 'cash_in' THEN -final_amount END) STORED,
                  CHECK(type = 'adjustment' AND final_amount <> 0 OR type <> 'adjustment' AND final_amount > 0),
                  created_by_user_id, updated_by_user_id, sync cols
transaction_lines id (stable across edits), firm_id, transaction_id, line_no, item_id,
                  uom CHECK(kg|unit)='kg', sale_mode CHECK(by_bags|by_weight|by_count),
                  bag_count?, bag_weight_g?, total_weight_g?, quantity?, rate_paisa,
                  rate_base_weight_g? (null when uom='unit'), overridden_total?,
                  calculated_total GENERATED ALWAYS AS (
                      CASE uom WHEN 'kg' THEN (rate_paisa * total_weight_g + rate_base_weight_g / 2)
                                                 / rate_base_weight_g          -- integer half-up
                               WHEN 'unit' THEN rate_paisa * quantity END) STORED,
                  final_amount GENERATED ALWAYS AS (COALESCE(overridden_total, calculated_total)) STORED
                  CHECK((sale_mode = 'by_bags') = (bag_count IS NOT NULL AND bag_weight_g IS NOT NULL))
                  CHECK((uom = 'kg') = (total_weight_g IS NOT NULL AND rate_base_weight_g > 0))
                  CHECK(rate_paisa > 0)
                  UNIQUE(firm_id, transaction_id, line_no)
                  FK (firm_id, transaction_id) → transactions(firm_id, id) ON DELETE CASCADE
                  — no own updated_at/deleted_at: lines travel inside their bill; pull = DELETE all +
                  INSERT the ids carried in the payload. `total_weight_g` is written by the app as
                  bag_count × bag_weight_g in by_bags mode (kept as a plain column so by_weight works).
                  uom/quantity/by_count exist now so phase 5 can sell tins/drums without a migration.
transaction_history id = uuid5(transaction_id + loser.updated_at + loser.device_id) — all writers of
                  the same loser collide into one row (INSERT OR IGNORE; first writer's `reason`
                  stands, snapshots are identical by construction); firm_id, transaction_id, version,
                  snapshot JSON {schema_version, header, lines (ids, overrides, item_id), customer_name,
                  item_names}, reason CHECK(edit|delete|sync_overwrite|restore), changed_at,
                  changed_by_user_id, changed_by_device_id — append-only. Snapshot upcasters in core
                  (v1→v2…) so old snapshots always parse.
print_log         id, firm_id, transaction_id?, customer_id?, kind CHECK(slip|ledger|export_pdf|export_png),
                  printed_at, device_id, printed_balance_after?, range_from?, range_to? — insert-only
sync_outbox       table_name, row_id, queued_updated_at, attempts=0, failed_reason?  PK(table,row_id)
                  (lives inside the per-firm DB file, so firm scope is implicit; only
                  table_name='transactions' is ever enqueued for a bill, never a line)
sync_orphans      table_name, row_id, payload JSON, missing_parent_table, missing_parent_id, received_at
sync_state        device_id, last_pull_cursor, clock_offset_ms, hlc_last, last_sync_at, paused_reason?
app_settings      key, value

VIEW customer_balances AS
  SELECT firm_id, customer_id, SUM(signed_amount) AS balance
  FROM transactions WHERE deleted_at IS NULL AND customer_id IS NOT NULL
  GROUP BY firm_id, customer_id;            -- Postgres: WITH (security_invoker = true) so RLS applies
```

**Indexes** (all lead with `firm_id`; partial where the query filters `deleted_at IS NULL`):
- `transactions(firm_id, customer_id, signed_amount) WHERE deleted_at IS NULL` — covering index for
  `customer_balances`; the aggregate never touches the table.
- `transactions(firm_id, customer_id, entry_date, created_at, id) WHERE deleted_at IS NULL` — ledger
  window query and ranged opening balance, no sort step.
- `transactions(firm_id, entry_date) WHERE customer_id IS NULL` — Cash Sales view.
- `customers(firm_id, name_normalized)`; `customers(firm_id, phone_normalized)` partial unique (above).
- `transaction_lines(firm_id, transaction_id, line_no)` unique; `transaction_lines(firm_id, item_id)`
  (phase 5 stock).
- `transaction_history(firm_id, transaction_id, changed_at)`; `print_log(firm_id, transaction_id)`.
- Server: `sync_changes PRIMARY KEY (firm_id, server_seq)`, index `(firm_id, table_name, row_id)`.

SQLite: `PRAGMA foreign_keys = ON` on every connection (drift `beforeOpen`); sync-apply transactions
use `PRAGMA defer_foreign_keys = ON` and park true orphans in `sync_orphans`.

**Server-only**: `sync_changes(firm_id, server_seq, table_name, row_id uuid, changed_at)` append-only,
one row per **bill** change (never per line). No per-table `server_seq` column (pull walks
`sync_changes` and joins current rows; a per-row seq would be write-only). Sequence allocation:
`UPDATE firms SET next_seq = next_seq + :n WHERE id = :firm RETURNING next_seq` inside the push
transaction — the row lock serialises pushes per firm (fine at 2–5 devices) and guarantees seq order
== commit order without an advisory lock a stray connection could hold.

**Postgres RLS**: every firm-scoped table gets `USING (firm_id = current_setting('app.firm_id')::uuid)`;
the API sets `app.firm_id` from the validated `X-Firm-Id` header per request. `users` is readable
only through a policy joining `firm_members` on a shared firm.

Fuzzy search: `normalizeName` in core (lowercase, strip non-alphanumerics, collapse transliteration
variants) + Damerau-Levenshtein scored matcher over in-memory customers, also matches phone.

Duplicate customers — phone is the key, name is the fallback:
- `normalizePhone` in core (digits only, default country code from firm setting; "0300-1234567",
  "03001234567", "+92 300 1234567" → "923001234567"). Index `customers(firm_id, phone_normalized)`
  among live rows.
- Local create with an existing phone_normalized is **blocked**: "This number belongs to X. Open
  it?" (Enter opens X). No phone → fuzzy-name warning only (phones can be shared, names are fuzzy,
  so neither check is fully automatic).
- Cross-device (phase 2): server detects phone collision on push, keeps both, sets `needs_review`
  on both. Dashboard "Possible duplicates" card: phone matches first, then close names; Enter =
  side-by-side, Ctrl+Enter = merge (repoint bills, set loser.merged_into_id, history row; server
  redirects future bills for the loser). Server auto-merges only when phone_normalized AND
  name_normalized both match.

## Section 3 — Balance math

`new = old + signed_amount`. The sign lives in exactly one place: the `signed_amount` generated
column's CASE (Section 2). sale, cash_out, opening_balance → +final; purchase, cash_in → −final;
adjustment stores a signed `final_amount` and passes through. `BalanceEngine` in core mirrors that
CASE for previews and is tested against the database's own answer so the two can never drift.
`receivable = max(b,0)`, `giveable = max(−b,0)`.

Rate: the database computes `line.calculated_total = (rate_paisa × total_weight_g +
rate_base_weight_g / 2) / rate_base_weight_g` in integer arithmetic (that expression IS round-half-up;
SQLite's `round()` and Dart's `round()` are not guaranteed identical, so neither is used). By-bags:
the app writes `total_weight_g = bag_count × bag_weight_g`. Unit items: `rate_paisa × quantity`.
`line.final_amount = COALESCE(overridden_total, calculated_total)` (generated).
Header: `bill.calculated_total = Σ lines.final_amount` and `bill.final_amount = overridden_total ??
calculated_total` are stored by `recomputeBillTotals` on every save and every pull; an integrity
test (and a SQLite trigger in debug builds) asserts header = Σ lines for every bill. Cash/opening/
adjustment: no lines, amount typed into `calculated_total`. Changing any input on a line clears
that line's override. Bill-level override is kept; flag "total overridden, lines changed" =
`overridden_total != null && overridden_total_basis != calculated_total`.

Money/Weight value types in core with `format()` (grouping, paisa toggle) and `parse()`
("1,25,000", "37.324 kg" → 37324 g, decimal limits).

Balances are computed on read, never stored:

```sql
-- ledger (whole customer, never paged; same query feeds the printed ledger)
SELECT t.*, SUM(signed_amount) OVER (ORDER BY entry_date, created_at, id) AS running
FROM transactions t
WHERE firm_id = ? AND customer_id = ? AND deleted_at IS NULL
ORDER BY entry_date, created_at, id;
-- opening balance for a ranged ledger:
SELECT COALESCE(SUM(signed_amount), 0) FROM transactions
WHERE firm_id = ? AND customer_id = ? AND deleted_at IS NULL AND entry_date < :range_from;
-- dashboard:
SELECT c.*, b.balance FROM customer_balances b JOIN customers c ON c.id = b.customer_id
WHERE b.firm_id = ? AND c.deleted_at IS NULL ORDER BY b.balance DESC;
```
Ordering key `(entry_date, created_at, id)` is deterministic on every device (`entry_date` is ISO
text so lexical order == chronological order). Bill-form preview ("owes X → after this bill owes Y")
= current balance + `BalanceEngine.sign(type) × final_amount`.

Edit = one SQLite transaction: history snapshot (reason edit, current state) → apply → version+1,
updated_at = Hlc.next() → recomputeBillTotals → enqueue outbox (bill, history). No balance repair
step exists because nothing derived is stored.
Delete = same with `deleted_at`, reason delete. Restore version k = history(reason restore, current)
→ apply snapshot k as version N+1 (lines by id; deleted items un-deleted). Diff view pairs
`history[k]` with `history[k+1]` or live for the last.

HLC: `next() = max(now_ms + clock_offset_ms, hlc_last + 1)`. On every startup and after restore:
`hlc_last = max(hlc_last, max(updated_at) over all synced tables)`. On pull: `hlc_last =
max(hlc_last, max incoming)`. `display_seq` allocator = `max(display_seq) + 1` for this device's
short_code (integer, so 10 > 9). Restore from a history snapshot resolves `customer_id` through
`merged_into_id` first, so it never resurrects a merged-away customer.

## Section 4 — Sync flow (phase 2; schema ready in phase 1)

Unit = **bill** (header + all lines, one JSON document, one version). Other tables row-by-row.
Dependency order: firms, devices, users/firm_members, items, customers, bills, history, print_log.
Triggers: network regained, every 5 min online, 5 s after save (debounced), manual. Single-flight.

```
0 first sync: GET /sync/time → clock_offset; if hlc_last > server_time + 5 min, seed hlc_last =
  server_time and re-stamp outbox rows preserving relative order. First login: server returns
  user_id; one txn rewrites local Owner user id in users/firm_members/*_by_user_id; then bulk-enqueue.
1 POST /sync/push {device_id, schema_version, device_time, rows grouped in dependency order}
2 server: token → user; X-Firm-Id checked against firm_members; payload firm_id must match; schema
  too old → 426
3 server, one txn: `UPDATE firms SET next_seq = next_seq + :n ... RETURNING` (row lock serialises
  the firm's pushes), SAVEPOINT per row, keyed (firm_id,id), `app.firm_id` set for RLS:
     unseen → insert, sync_changes row (seq from the reserved block)
     seen & incoming (updated_at,device_id) > existing → history(existing,sync_overwrite,
        changed_by = existing.device) + update + sync_changes row
     seen & incoming older → history(incoming, sync_overwrite) (deterministic id) + ack, no update
     identical → ack
     updated_at > server_time + 5 min → rejected{clock_skew}; parent missing (not in DB nor accepted
        in this payload) → rejected{missing_parent}; invalid → rejected{reason}
     bill for tombstoned customer → un-tombstone customer (new updated_at, needs_review=true,
        history) or, if merged_into_id set, rewrite customer_id and return rewrite in ack
     new customer whose phone_normalized already exists in firm → accept, set needs_review on both;
        if name_normalized also matches → auto-merge into the older one (rewrite returned in ack)
  → {accepted:[(id,updated_at)], rejected:[(id,reason)], rewrites:[…], server_time}
4 device, one txn: clear outbox rows whose queued_updated_at matches; apply rewrites; clock_skew →
  fix offset/hlc, re-stamp, retry once; other rejects → attempts++, failed_reason shown in Sync screen
5 GET /sync/pull?since=cursor&limit=500 (limit counts sync_changes rows; a bill is one row) →
  sync_changes JOIN current rows; dedupe per page by (table,row_id) at first seq
6 device, one txn per page (`PRAGMA defer_foreign_keys = ON`): same comparison; loser → history
  (INSERT OR IGNORE); bills: DELETE all lines + INSERT the ids in the payload; missing parent →
  sync_orphans (cursor still advances); parent arrives → drain orphans;
  cursor = next; hlc_last = max(...). Devices never resurrect on pull.
7 loop while has_more; 8 recomputeBillTotals for pulled bills; 9 UI "last synced …"
  (balances need no repair step: they are computed on read)
```

Phase 2 open decision (recorded, not blocking): **field-level merge** for bills as the upgrade over
bill-level newer-wins. Each bill would carry a `field_stamps` JSON map (field → HLC); merge keeps the
newer value per field, recomputes totals from merged lines, delete-line beats edit-line, and only
same-field collisions produce a history loser. Borrowed from Google Docs' "edits to different places
never fight" (Operational Transformation), simplified for field records. Decide at phase 2 design.

Backend: `POST /auth/login`, `/auth/google`, `/auth/refresh`, `GET /sync/time`, `POST /sync/push`,
`GET /sync/pull`, `GET /healthz`. JWT 15 min + per-device refresh token. Cloud Run min 0; Cloud SQL
smallest tier (~$10–15/mo, never sleeps); Secret Manager; Alembic as Cloud Run Job before traffic
switch; JSON logs; uptime check; automated backups + PITR; Postgres RLS by firm_id.

## Section 5 — UI and keyboard model

Screens (desktop two-pane; phone stacks in phase 3):

- **First launch**: firm name, contact, address?, backup folder, or Restore from backup. Creates
  firm, Owner user, this device (short_code from uuid), DB file.
- **Dashboard** (default route; shell + skeleton drawn first frame, DB opens async): search box
  focused; Receivables / Giveables tables sorted desc with totals; today's walk-in cash; last backup;
  "Possible duplicates" card when any customer has needs_review (phase 2+); quick actions. Arrows
  move, Enter opens ledger.
- **Customer ledger**: left table (date, bill no, type, description, debit, credit, running
  balance, edited badge, printed count); right panel: lines, totals, history timeline with
  field-by-field diff (changed fields highlighted), Restore this version; "show deleted" toggle.
  F2/Ctrl+E edit, Ctrl+P slip, Ctrl+Shift+P ledger.
- **Bill form**: header (customer autocomplete, typed date, description) → lines grid → totals
  (calculated, override, final, current → new balance). After Ctrl+Enter: read-only Saved state with
  bill no + new balance; Ctrl+P print, Ctrl+N next bill (same customer prefilled), Esc ledger.
  Editing a bill with print_log rows shows "printed N×" and offers reprint after save.
- **Cash entry form**: type (cash in/out, opening, adjustment), customer, date, amount, note.
  Ctrl+Enter saves.
- **Opening balances grid** (name, phone, signed balance; fuzzy-dup warning) + CSV import.
- **Customers / Items** lists with inline edit; **Cash Sales** view.
- **Settings**: firm details, display (paisa, grouping), printer (by name + URL, fallback prompt,
  silent print), backup (folder, now, restore), language.

Keyboard rules (written down, tested):
- Enter table: autocomplete open → pick highlighted only; closed → next cell; last cell → new line;
  never saves. `enter` and `numpadEnter` both handled. Grid uses `Focus.onKeyEvent`, not app-level
  Shortcuts. Trailing blank line dropped on save.
- Autocomplete: Enter picks; last row "Create 'X'" (or Ctrl+Enter) creates, showing similar names.
  Customer create form: phone with an existing phone_normalized is blocked with "belongs to X, open
  it?"; firm default country code setting feeds normalizePhone.
- Date field: typed dd/MM/yyyy, `T` today, Up/Down ±1 day, PgUp/PgDn ±1 month. Same in range dialog.
- Line ops: Ctrl+Minus remove line; Space toggles sale_mode (by_weight skips bag cells, nulls them);
  base-weight cell typed number with hotkeys 1–5 for 30/34/37.324/40/56.
- Item pick fills bag weight / base weight only if cell untouched.
- Esc: close overlay → confirm if dirty → pop dialog → back.
- Validation: final > 0 for sale/purchase/cash; adjustment non-zero; ≥1 line; bags/weight/rate > 0.
- Global: Ctrl+N sale, Ctrl+Shift+N purchase, Ctrl+I cash in, Ctrl+O cash out, Ctrl+F search,
  Ctrl+P print, Ctrl+B backup, Ctrl+, settings. Explicit `FocusTraversalGroup` order.
- Startup: Windows runner background colour; migrations show progress only if > 500 ms; never
  heavy work on startup (dashboard reads the customer_balances view lazily).

## Section 6 — Printing and export

`pdf` + `printing`. M6 begins with a 1-day silent-print spike on the real USB thermal printer.

- **Slip (80 mm roll, ~72 mm printable)**: lay out once to measure, build page of that height.
  Firm header, bill no, date, customer or "Cash Sale", lines, total, previous balance, new balance
  "as of <time>", edited badge, printed-at, device code. Fonts bundled: Noto Sans + Noto Nastaliq
  Urdu (customer names). Silent print to saved printer (name + URL).
- **Ledger (A4)**: range dialog (All / This month / Custom, typed dates); opening balance as of
  start (SUM before range_from), rows with running balance, closing balance, page x/y, printed-at.
  Ledger columns (screen and print): Date, No, Type, Debit, Credit, Balance. Debit = sale/cash_out/
  opening(+), Credit = purchase/cash_in. Left nav with shortcut letters kept on desktop.
- Export: PDF; PNG 300 DPI rasterised one page at a time. Every print/export writes `print_log`.
- Prints stay English.

## Section 7 — Data safety

- SQLCipher-capable driver shipped (`sqlcipher_flutter_libs`), empty key; no encryption UI in phase 1.
  Encryption state detected from file header, not a prefs flag.
- **BackupService** (M2): `VACUUM INTO` `backups/<firm>-<ts>.db.tmp` on the DB isolate → verify
  (open read-only, `quick_check`, compare transaction count) → rename → copy to user folder →
  prune to 30. Runs on launch if last > 24 h, before every migration, on Ctrl+B. Covers every firm
  DB file. Failures surface on dashboard.
- **Restore**: write pending-restore marker + pre-restore backup → relaunch → swap file → if global
  prefs' device id exists in the restored DB keep identity, else new device → seed hlc_last → reset
  `sync_state` cursor.

## Section 8 — Testing

- **core**: sign table + four spec cases + crossings; rounding at all bases; override precedence and
  clearing; HLC monotonic + startup seeding; normalize/fuzzy; display_no resume; Money/Weight
  format+parse round-trips.
- **app data** (real SQLite file): repositories; running-balance and customer_balances queries incl.
  backdated insert/delete/edit and walk-in exclusion; opening balance for a date range;
  generated-column arithmetic vs `RateCalculator` (same answer on 1,000 random inputs incl. the
  37.324 base); CHECK constraints reject bad rows (type typo, zero sale, by_bags without bag
  weight, uppercase uuid, dd/MM/yyyy date); header = Σ lines integrity sweep; EXPLAIN QUERY PLAN
  asserts the two partial indexes are used; edit/delete/restore atomicity
  (inject throwing step, assert rollback); outbox enqueue and ack-vs-newer-edit race; backup
  verify/prune; migration tests with committed `drift_dev make-migrations` schema exports + CI step
  failing on missing export; **benchmark**: 200k transactions across 2k customers, ledger query and
  customer_balances each < 50 ms (fails CI if the compute-on-read assumption breaks).
- **widget** (`debugDefaultTargetPlatformOverride = windows`, events with platform windows): bill
  form Enter table, Tab order, Ctrl+Minus, Ctrl+Enter, autocomplete create row, date field keys,
  Esc layers, first-launch wizard, dashboard navigation.
- **printing**: assert on `SlipModel`/`LedgerModel` view-models; one golden raster per template.
- **phase 2**: pytest + Postgres testcontainer; two-device convergence property test.
- **CI**: `flutter analyze` + tests on ubuntu; Windows installer (Inno Setup, bundles VC++ runtime).

---

## Phase 1 implementation plan (milestones; each ends runnable + tested)

M0 **Clickable HTML mockups** of the seven screens (dashboard, first launch, bill form + saved state,
   ledger with history panel, cash entry, slip, settings) published as an artifact for the user's
   reaction before any Flutter code; then repo + workspace: pub workspace, `packages/ledgerly_core`,
   `app` (windows+macos+android), lint, CI analyze+test, **Windows VM build + installer workflow
   skeleton**, README, spec + wireframes in `docs/`.
M1 Core: Money/Weight value types + formatters/parsers, entities, BalanceEngine, RateCalculator,
   Hlc, normalizeName + fuzzy matcher, displayNo allocator, repository interfaces. Tests.
M2 Data: drift schema v1 + `customer_balances` view, migrations scaffold + schema export + migration
   test, repositories incl. running-balance query, edit/delete/restore with history + outbox in one
   txn, **BackupService** (local folder, verify, prune, pre-migration hook), benchmark test. Tests.
M3 Shell: Riverpod wiring, routing, theme, ARB localization, first-launch wizard (incl. Restore),
   dashboard with tables + fuzzy search, no-white-screen startup, Ctrl+B.
M4 Entry: customers + items screens; bill form with full keyboard model and Saved state; cash entry
   form; opening-balances grid + CSV import; Cash Sales view. Widget tests.
M5 Ledger: two-pane ledger, history diff panel, restore, show-deleted toggle.
M6 Printing: printer spike on real hardware → slip + ledger templates, range dialog, silent print,
   PDF/PNG export, print_log.
M7 Settings complete: firm details, display, printer, backup folder picker + Restore UI.
M8 Windows release: installer polish, smoke test on Windows VM with thermal printer, tag v0.1.

Verification (end of phase 1): fresh Windows install → wizard → opening balances via grid → items →
sale with two lines at 37.324 base → cash in → backdated purchase → edit a bill (override, then
change a line, see flag) → ledger running balances correct, edited badge, diff view, restore version
→ print slip + ranged ledger (opening balance correct) → Ctrl+B → uninstall → reinstall → Restore →
identical data and bill numbering continues; all tests green in CI.
