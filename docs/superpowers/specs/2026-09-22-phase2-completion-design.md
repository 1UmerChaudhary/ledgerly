# Phase 2 completion — design

Status: revised 2026-09-22 after two independent cross-model design reviews (Opus, Fable) found
severe, converging issues in the first draft — see "What changed after review" at the end.
Encryption and Google sign-in are now substantially redesigned; token refresh gained a
concurrency fix. Awaiting user re-approval of this revision before implementation.

## Context

Phase 1 (desktop) and the bulk of Phase 2 (backend + sync + Android touch support) are complete
and live. Three items were explicitly deferred from Phase 2's original scope and are being closed
out now: passphrase encryption with a printed recovery code, Google sign-in, and silent
401-triggered token refresh (currently a stale access token just logs the user out). Also folded
into this same round: PNG export wiring, cosmetic keyboard-hint cleanup on touch screens, and five
Minor items parked during the Android effort's final review.

Two items are explicitly **out of scope** for this round, per user decision: Bluetooth thermal
printing's real-hardware verification and the Windows USB-printer smoke test — both need physical
hardware not available here and stay as documented, accepted gaps.

## Goals

- Close out every remaining Phase 2 item except the two hardware-blocked ones.
- No data-loss risk from the encryption work — this is the one piece in this round where a design
  mistake is not just a bug but a way to permanently lock the user out of their own ledger. Both
  reviewers independently found the first draft's Section 1 didn't just risk this — it was
  literally unbuildable as written (see below). This revision is written to survive a third,
  equally adversarial read.
- No new migration needed for Google sign-in — `google_sub` already exists on `users`
  (`migrations/versions/f537e6a2a3d5_firms_users_firm_members_devices.py:60`, with a unique
  constraint), from the original schema design. This work is endpoint + app-side only.

## 1. Passphrase encryption + printed recovery code

**Design: envelope encryption with two independent wraps of one master key.** This is a revision
of the first draft, which made the recovery code *equal to* the raw database key — both reviewers
independently flagged that this makes the recovery code permanently unrotatable (a compromised
recovery code can never be invalidated without re-encrypting the whole database) and, separately,
that the wrapped-key storage location made the whole scheme physically unable to boot. Both are
fixed below.

- At encryption setup, generate one random 256-bit key (`masterKey`) — this is the *actual*
  SQLCipher key, passed to SQLCipher in its raw-hex-key form (`PRAGMA key = "x'<64 hex chars>'"`),
  never as a passphrase string. This bypasses SQLCipher's own built-in passphrase-to-key
  derivation entirely — that built-in path has no way to support two independent unlock methods,
  which is the whole property this design needs. `masterKey` is never shown to the user and never
  stored in plaintext on disk.
- **Two independent wrapped copies of `masterKey` are stored, not one:**
  - `wrappedKeyByPassphrase` — the user's chosen passphrase, run through Argon2id (via
    `package:cryptography`; PBKDF2-HMAC-SHA256 at ≥600,000 iterations is an acceptable fallback if
    Argon2id turns out awkward to wire up, but Argon2id is preferred as the current standard for
    passphrase KDFs), derives a wrapping key. `masterKey` is encrypted with it (AES-GCM, fresh
    random 96-bit nonce).
  - `wrappedKeyByRecoveryCode` — a **separate**, independently-generated 256-bit random secret
    (the actual printed recovery code, encoded as Crockford base32 — see below) is used directly
    as a second wrapping key. `masterKey` is encrypted with it the same way (AES-GCM, its own
    fresh nonce).
  - Both wraps, their KDF parameters (algorithm, iteration/memory/parallelism cost, salt), and a
    short format-version tag live together in one small JSON envelope.
  - This buys real properties the first draft's design didn't have: the recovery code can be
    **rotated independently** (re-wrap `masterKey` under a new random recovery secret, print a new
    sheet, the old sheet is now inert — needed if a recovery sheet is ever lost, photographed, or
    shown to someone during a support call), and the raw database key itself never appears in
    printable form at all. Changing the passphrase re-wraps only `wrappedKeyByPassphrase`;
    `wrappedKeyByRecoveryCode` — and therefore the printed recovery code — is untouched, so the
    user-facing fact from the first draft still holds: **your recovery code stays valid even if you
    change your passphrase.**
  - Both PBKDF2/Argon2id derivation and AES-GCM wrap/unwrap come from `package:cryptography` (v2.9,
    confirmed actively maintained) — the one new dependency this feature needs.
- **Where the envelope actually lives — this is the fix for the first draft's fatal flaw.** The
  first draft put it in the `app_settings` table, reasoning that it was "device-local, not synced
  to the server." Both reviewers independently caught the real problem: `app_settings`
  (`packages/ledgerly_data/lib/src/db/schema.drift:227`) is a table *inside the same SQLite file*
  that SQLCipher encrypts. Reading the wrapped key to unlock the file requires the file to already
  be open, which requires the wrapped key — a circular dependency that makes the "normal unlock"
  path in the first draft physically impossible to execute, not just risky. (`app_settings` also
  has zero existing call sites anywhere in the codebase today, which is almost certainly why it
  read as a safe, unused home.)

  **Fix:** the envelope is a plaintext sidecar file next to the database, e.g.
  `firms/<firmId>.key.json` (alongside `firms/<firmId>.db`, using the same `AppPaths` the database
  file itself already resolves through). It is never encrypted (it doesn't need to be — its
  contents are useless without the passphrase or recovery code, and it must be readable *before*
  the database can be opened). Being a plain file, not a SharedPreferences/`GlobalPrefs` entry,
  also means it can be included in the backup set (see below) — necessary for restoring a backup
  onto a different device, where nothing else would carry the envelope.
- **Atomic, safe envelope writes.** Every write (initial creation, passphrase change, recovery-code
  rotation) writes to a temp file, verifies it round-trips (decrypt the newly-written wrap back to
  the known `masterKey` and confirm it matches) before touching the real path, then renames over
  the original. The *old* envelope file is kept as `<name>.key.json.bak` until the new one has
  round-tripped successfully — a crash mid-write must never leave the user with a envelope that
  matches neither their old nor new passphrase.
- **The printed recovery code**: the recovery secret (not `masterKey`) encoded as **Crockford
  base32** (not plain base32) — Crockford's alphabet folds visually ambiguous characters (`O→0`,
  `I`/`L→1`) and defines an optional check-symbol scheme, so a single mistyped character from a
  handwritten or printed sheet is detectable as "that's not a valid code" rather than silently
  producing a different, equally-plausible-looking wrong key. Format it grouped in 4-character
  blocks (e.g. `XM4K-9QRT-...`) with the check symbol appended. It's generated once, shown once,
  and — this is new in this revision — **the setup wizard requires the user to type the code back
  in** before encryption is actually switched on (not just a "I've saved it" checkbox — a checkbox
  confirms intent, typing it back confirms the printed sheet is legible and actually has the right
  code on it). The printed sheet itself also carries the firm's name and the date generated (the
  app is explicitly multi-firm; two firms' recovery sheets must not be visually interchangeable),
  and states plainly, in the wizard before the user commits: **"If you forget your passphrase and
  lose this recovery code, this firm's ledger cannot be recovered by anyone, including you or us."**
  This uses the existing print pipeline (`packages/ledgerly_data/lib/src/printing/`) with a new
  template — not the slip/ledger ones.
- **Unlock at app launch**: try the passphrase first (derive the passphrase wrapping key, decrypt
  `wrappedKeyByPassphrase`, get `masterKey`, open SQLCipher with it). "Fail closed" must be a real
  read, not just a successful `PRAGMA key` — SQLCipher accepts a wrong raw key silently and only
  fails on the first actual page read, so verification means running e.g. `PRAGMA
  cipher_integrity_check` or a real `SELECT` immediately after keying and treating any failure as
  "wrong passphrase," not a crash. If the passphrase is forgotten, an "I lost my passphrase" path
  lets the user type the recovery code instead — decoded, used to decrypt
  `wrappedKeyByRecoveryCode`, yielding the same `masterKey` via the second independent path. After
  a successful recovery-code unlock, the wizard **requires setting a new passphrase immediately**
  (the old one is presumed compromised — whoever needed the recovery path may also know or have
  guessed at the old passphrase) and separately **offers, but does not require, rotating the
  recovery code too** (the recovery code itself wasn't necessarily exposed by this event — only
  the passphrase was forgotten, not leaked — so forcing rotation here isn't automatic, but the
  option should be visible).
- **Turning encryption on for an existing (plaintext) database — entirely new in this revision.**
  The first draft never addressed this at all, despite it being the actual user-facing event every
  existing Phase 1 installation will go through. The only correct sequence for an existing
  SQLCipher-capable SQLite file:
  1. Generate `masterKey`, the passphrase, and the recovery secret; build the envelope in memory
     (don't write it yet).
  2. `ATTACH DATABASE '<new-file>.db' AS enc KEY "x'<masterKey hex>'"` against the live plaintext
     connection, then `SELECT sqlcipher_export('enc')` — SQLCipher's own sanctioned
     plaintext-to-encrypted export path (this is **not** the same as `VACUUM INTO`, and the
     implementation plan must verify this empirically against the actual `sqlcipher_flutter_libs`
     build rather than assume it — see Testing).
  3. Open the new encrypted file read-only with `masterKey`, and verify it round-trips: run
     `PRAGMA cipher_integrity_check`, and compare row counts per table against the live plaintext
     database. Only once this passes does the app write the envelope file (atomically, as above),
     close the live connection, and swap the encrypted file into place as the firm's real database
     file.
  4. The plaintext original is retained (renamed, not deleted) until the swapped-in encrypted file
     has been successfully reopened and read from at least once after the swap — then securely
     removed.
  5. **Existing plaintext backups are not silently left behind pretending to be safe.** At the end
     of this flow, the user is shown how many plaintext backups exist in `localBackupDir` and any
     configured `userBackupDir`, and offered a one-tap "delete these now" action (default:
     offered, not automatic — deleting someone's only backups without an explicit tap is its own
     risk). This is a UI moment, not a silent background sweep.
  - This is per-firm (each firm has its own database file, its own envelope, its own independent
    encryption state) — a device with multiple firms may have some encrypted and some not.
  - A **disable encryption** path is out of scope for this round (not requested, adds real surface
    area) but the sidecar-envelope design doesn't foreclose it — reversing step 2-4 with a plain
    `sqlcipher_export()` back to an unencrypted target is the same shape. Note this in the code as
    a natural follow-up, don't build it now.
- **Changing the passphrase later** (Settings): decrypt `masterKey` via the *old* passphrase wrap,
  re-derive and re-wrap under the *new* passphrase, atomically replace `wrappedKeyByPassphrase`
  only (as described above). `wrappedKeyByRecoveryCode` is untouched.
- **Key rotation** (new in this revision, addressing the "compromised recovery code" case the
  first draft's design couldn't actually handle): Settings gains a **"Generate a new recovery
  code"** action, independent of changing the passphrase — generates a new random recovery secret,
  re-wraps `masterKey` under it, atomically replaces `wrappedKeyByRecoveryCode`, and walks the user
  through printing the new sheet exactly like initial setup. The old recovery code becomes
  permanently unable to unlock this database the moment this completes.
- **Backups become key-aware — this is the fix for the first draft's second fatal claim.** The
  first draft asserted "no change needed to `BackupService` itself." Both reviewers checked the
  actual code and found this false: `BackupService._verify` and `BackupService.validateBackup`
  (`packages/ledgerly_data/lib/src/backup_service.dart`) both open their probe connections with a
  plain, unkeyed `sqlite3.open` and run `PRAGMA quick_check`/`SELECT count(*)` — against an
  encrypted file, both throw immediately. As written, **enabling encryption would silently break
  every future automatic backup** (`backupNow()`'s `_verify` step would start throwing on every
  run) **and reject every encrypted file at restore-validation** ("that is not a valid database
  file"), for the one class of database where backups matter most.

  **Fix:** `BackupService` takes the current firm's `masterKey` (or `null` for an unencrypted
  firm) at construction, and its probe connections key themselves before running any check —
  `PRAGMA key = "x'...'"` immediately after opening, before `quick_check`. The backup artifact for
  an encrypted firm is redefined as the `.db` file **and** its `.key.json` envelope sidecar
  together (both copied into `localBackupDir`/`userBackupDir`, both included in the pre-restore
  safety copy) — without the sidecar, a `.db`-only backup restored onto a different device has no
  way to unwrap `masterKey` at all except the printed recovery code, which the implementation plan
  should treat as the intended fallback for that exact case, not a bug to work around.
- **Cross-key restore.** Restoring a backup whose envelope doesn't match the currently-open
  firm's live key (e.g. restoring an older backup taken before a recovery-code rotation, or a
  backup from a different device) is handled the same way as first-launch unlock: the restore flow
  prompts for that backup's passphrase or recovery code before anything else touches the restored
  file, using the sidecar that traveled with the backup artifact.

## 2. Google sign-in

**Scope for this round: Android only.** The first draft put the "Sign in with Google" button in
Settings unconditionally. Both reviewers independently caught that `google_sign_in` 7.x has no
Windows or Linux implementation at all — and this app's primary platform is Windows desktop. A
real desktop OAuth flow (loopback-redirect through a system browser, a third, Desktop-type OAuth
client) is a genuinely separate implementation, not a config tweak, and is **not** built in this
round — it's called out explicitly as follow-up work, not silently dropped. The button in Settings
is shown only when `Platform.isAndroid`.

**Backend**: new `POST /auth/google` in `backend/app/routers/auth.py`, mirroring the existing
`/auth/register` + `/auth/login` split but unified into one endpoint (a Google sign-in click
doesn't know ahead of time whether this is a first-time or returning user — the endpoint decides):

- Request body: `{id_token: str, firm: FirmInfo, device: DeviceInfo}` — same `FirmInfo`/`DeviceInfo`
  shapes `/auth/register` already uses.
- Verify `id_token` server-side using `google.oauth2.id_token.verify_oauth2_token` from the
  `google-auth` package (already a dependency in `backend/pyproject.toml`, unused until now), with
  `audience` checked against an **allow-list** of this app's client IDs (starts with one — the web
  client ID — but written as a list from day one, since a future desktop client ID is expected to
  join it), and `issuer` checked against Google's documented pair (`accounts.google.com` /
  `https://accounts.google.com`). Extract `sub`, `email`, and **`email_verified`** from the
  verified payload.
- **`email_verified` must be `true` before the email is trusted for anything** — this is a fix for
  a real account-takeover gap both reviewers found in the first draft. If it's `false` or absent,
  treat this the same as "no email match" below (never auto-link on an unverified email).
- If a user with that `google_sub` already exists: this is a login. Issue tokens for their
  existing firm, exactly like `/auth/login` does, ignoring the `firm`/`device` info the app sent.
- If no user has that `google_sub`, but a user with that (verified) **email** already exists,
  registered originally via password: **do not silently link.** The first draft's "standard
  convergence behavior" reasoning doesn't hold here, because `/auth/register` performs no email
  verification of its own — an attacker could pre-register a victim's email with a password before
  the victim ever signs up, and a silent auto-link would hand the attacker's firm to the victim's
  Google identity. Instead, respond with a distinct status telling the app "an account with this
  email already exists — log in with its password, then link Google from Settings" (a `409` with a
  machine-readable reason, e.g. `{"detail": "email_exists_unlinked"}`), and provide a **separate**,
  already-authenticated `POST /auth/google/link` endpoint (bearer-token-protected, like the sync
  endpoints) that the app calls from Settings once the user is logged in normally — this both
  proves the user controls the account (they had to log in first) and completes the same
  `UPDATE users SET google_sub = :sub WHERE id = :authenticated_user_id` the first draft proposed,
  just gated behind proof of account ownership instead of email-string equality.
- If neither matches: first-time registration, structured identically to `/auth/register`'s
  transaction (insert firm, user with `google_sub` set and `password_hash` left `NULL`,
  firm_members owner row, device), then issue tokens.
- Reuses `_issue_tokens`/`_store_refresh_token` unchanged — no new token logic.
- **Known pre-existing gaps this endpoint inherits from `/auth/login`, noted but not fixed in this
  round** (both reviewers flagged these; they predate this work and fixing them is a real product
  decision — which firm does an ambiguous multi-firm user log into? — not a mechanical fix): a
  user who belongs to more than one firm crashes `/auth/login`'s query (`.one_or_none()` on a join
  that can return multiple rows); logging in as an *existing* Google user from a *new* device never
  inserts a `devices` row for that device. Flagged in code comments at the call sites so they're a
  visible, deliberate deferral rather than a silent gap.

**App**: `google_sign_in: ^7.2.0`. API facts, verified against the package's actual current source
(not its README prose, which is written Android/iOS-agnostic and glosses over a real platform
difference the first draft got wrong):
- On Android specifically, **`clientId` is not passed** — confirmed against
  `google_sign_in_android`'s own README: the Android client is resolved automatically from the
  app's package name and signing SHA-1 once registered in the Cloud Console (or via
  `google-services.json`), and only `serverClientId` (the web client ID) needs to be supplied in
  Dart. Call is `GoogleSignIn.instance.initialize(serverClientId: <web client ID>)`, then
  `.authenticate()` for the explicit user-initiated flow. Wire `attemptLightweightAuthentication()`
  too, for returning users who shouldn't be re-prompted every launch.
- The ID token to send the backend is `account.authentication.idToken` —
  `GoogleSignInAccount.authentication` returns a `GoogleSignInAuthentication` with exactly one
  field, `idToken`; the package's own doc comment is explicit this is the only safe thing to send a
  backend.
- **Setup dependency, flagged for the user**: an OAuth client configured in Google Cloud project
  `ledgerly-1umerchaudhary` (already running Cloud Run) — an Android client ID (keyed to package
  name `pk.ledgerly.ledgerly` and the signing certificate's SHA-1) and a Web client ID (used as
  `serverClientId` in the app *and* as the audience the backend verifies against). Creating the
  OAuth consent screen and these client IDs has manual steps in the Cloud Console that can't be
  fully scripted — the implementation plan flags exactly where to stop and walk the user through
  it.

## 3. Silent 401 token refresh

Fix in `app/lib/features/settings/cloud_sync_providers.dart`'s `SyncRunner.syncNow()`. Today, a
`BackendAuthException` (401) from either `pushPending()` or `pullAll()` immediately logs the user
out (`cloud_sync_providers.dart:137-142`) — the code comment at `sync_service.dart:14-15` already
documents this as a known gap.

Fix: on `BackendAuthException`, first try `client.refresh(session.refreshToken)` (the endpoint and
client method both already exist and work — `BackendClient.refresh`, `POST /auth/refresh`). If
that succeeds, **persist the new token pair before doing anything else** (mirroring what
`cloud_sync_providers.dart:54/75` already do after register/login) — this ordering is load-bearing,
not incidental: if the app is killed between a successful refresh and persisting it, the next
launch would retry with the now-dead old token. Only after persisting, retry the *same* sync
attempt once with the new access token. Only if the refresh call **itself** throws
`BackendAuthException` does the existing logout path fire.

**Concurrency guard, added in this revision.** `POST /auth/refresh` *rotates* the refresh token
(`auth.py`'s `_store_refresh_token` does an `ON CONFLICT ... DO UPDATE`) — the old refresh token
stops working the instant a new one is issued. One reviewer traced through what happens if two
`syncNow()` calls are in flight at once (e.g. the periodic timer and a manual "Sync now" tap both
land while the access token has just expired): both see a 401, both call `refresh()` with the
*same* stored (soon-to-be-stale) refresh token; the first call rotates it successfully, and the
second call's request now uses an already-dead refresh token, throws `BackendAuthException`, and
triggers the exact wrongful logout this fix exists to prevent. `SyncRunner` needs a single-flight
guard around the refresh-and-retry path (e.g. an in-flight `Future` the second caller awaits
instead of independently retrying) so only one refresh ever happens per expiry, not one per
concurrent caller.

`pushPending()`'s outbox-driven design is already idempotent under a retry (it only clears entries
the server actually accepted) — this is worth a one-line comment where the retry happens, so it
reads as a verified property rather than an unexamined assumption next time someone touches this
code.

## 4. Smaller items, folded into the same implementation plan

- **PNG export wiring**: `exportSlipPng` (in `print_actions.dart`) has no call site — add an
  "Export PNG" action alongside the existing "Export PDF" one in the ledger detail action row
  (`ledger_detail_screen.dart`, from the Android effort's final fix wave), same pattern.
- **Keyboard-hint cleanup**: five places still show desktop-only text like `"Ctrl+N adds one"` /
  `"Ctrl+Enter save · Esc back"` at compact/touch width, where they're meaningless — gate each
  behind the existing `compact` flag already threaded through these files, same pattern used
  throughout the Android effort.
- **Five parked Minor items** from the Android final review (all documented with exact file:line
  in that effort's ledger — the implementation plan restates each precisely): the 600–695dp
  back-affordance gap on the pushed ledger detail screen, the touch Edit button's cancel landing on
  the dashboard instead of the ledger it came from, a narrow duplicate-print risk in `printSlip` if
  `disconnect()` itself throws after a successful write, `print_actions.dart`'s exception handler
  not catching bare `Error` types, and one stale test comment.

## Testing

- **Encryption — the highest test bar in this project, deliberately.** Round-trip: encrypt → lock
  → unlock with passphrase → unlock with recovery code (independently of the passphrase path,
  since it's now a genuinely separate wrap) → change passphrase → unlock with the *new* passphrase
  → recovery code still works unchanged → rotate the recovery code → old recovery code now fails,
  new one works → passphrase still works throughout. A wrong passphrase and a wrong recovery code
  both fail closed via a real read (`PRAGMA cipher_integrity_check` or equivalent), never a silent
  partial success. A simulated torn write to the envelope file (kill the process between temp-write
  and rename) leaves the *previous* envelope intact and openable. The plaintext-to-encrypted
  migration is tested end to end: row counts match before/after, the plaintext original survives
  until the swap is verified, and a failure partway through (e.g. `sqlcipher_export` erroring) never
  deletes or corrupts the live plaintext database.
  - **Verify empirically, don't assume**, before writing the migration code: whether
    `sqlcipher_export()` is genuinely necessary versus whether this build's `VACUUM INTO` already
    produces a correctly-encrypted target (behavior here is version-sensitive and must be confirmed
    against the actual `sqlcipher_flutter_libs`/`sqlite3` versions this project pins, not assumed
    from documentation) — and separately, whether `dart test` in `packages/ledgerly_data` (a pure-Dart
    package, no Flutter) can actually exercise the SQLCipher build at all, given every existing test
    in that package uses `NativeDatabase.memory()`. Both are stated here as things to check first,
    not as settled facts.
  - `BackupService`'s keyed probes are tested against both an encrypted and an unencrypted firm; a
    backup of an encrypted database is confirmed to fail an *unkeyed* open (proving it's genuinely
    ciphertext on disk, not accidentally plaintext).
- **Google sign-in**: `verify_oauth2_token` is the one call mocked (a legitimate last-resort case —
  sandboxing real Google OAuth isn't practical); everything else runs against a real Postgres
  testcontainer, matching this backend's existing `/auth/register`/`/auth/login` conventions. Cases:
  new user, existing-`google_sub` login, existing-email-unverified (must not link), existing-email-
  verified-but-not-yet-linked (must return the `409`, not auto-link), and the separate authenticated
  `/auth/google/link` endpoint actually linking when called correctly.
- **Token refresh**: forcing `BackendAuthException` on the first sync attempt with a fake
  `refresh()` that succeeds, asserting the retry happens and succeeds, persisted-before-retried
  ordering; the refresh-also-fails-so-logout path unchanged; and the new concurrency case — two
  simultaneous `syncNow()` calls against an expired token result in exactly one refresh call and
  neither one wrongfully logs out.

## What changed after review

Two independent design reviews (dispatched on different model configurations, per the user's
explicit request for a second opinion before implementation) both read the first draft
independently and both — without seeing each other's findings — identified the same two
blocking defects in Section 1 (wrapped-key storage location made unlock impossible; "no change
needed to `BackupService`" was factually wrong and would have silently broken backups the moment
encryption shipped), plus overlapping concerns in Section 2 (the Google account-linking logic had
a real takeover gap; Windows platform support was never addressed despite being the primary
platform). One review additionally proposed the two-independent-wraps recovery-code design this
revision adopted, which is a genuine improvement over the first draft's "recovery code equals the
raw key" approach, not just a fix for a bug. This revision incorporates every confirmed finding
from both reviews; nothing here was accepted uncritically — each claim was checked against the
actual codebase (cited by file:line above) before being folded in.
