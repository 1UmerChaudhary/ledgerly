# Phase 2 completion — design

Status: approved by user 2026-09-22 (key decisions confirmed via direct questions during
brainstorming — envelope-encryption approach for passphrase/recovery-code, proceed with Google
Sign-In now with manual GCP console steps walked through when reached).

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
  mistake is not just a bug but a way to permanently lock the user out of their own ledger.
- No new migration needed for Google sign-in — `google_sub` already exists on `users`
  (`migrations/versions/f537e6a2a3d5_firms_users_firm_members_devices.py:60`, with a unique
  constraint), from the original schema design. This work is endpoint + app-side only.

## 1. Passphrase encryption + printed recovery code

**Design: envelope encryption**, the standard, safe pattern for "a passphrase you can forget but a
recovery code you can't lose forever":

- At encryption setup, generate one random 256-bit key (`masterKey`) — this is the *actual*
  SQLCipher key that encrypts the database file, passed to SQLCipher in its raw-hex-key form
  (`PRAGMA key = "x'<64 hex chars>'"`), never as a passphrase string. This deliberately bypasses
  SQLCipher's own built-in passphrase-to-key derivation entirely — that built-in path has no way
  to also unlock via a separate recovery code, which is the whole property this design needs.
  `masterKey` is never shown to the user and never stored in plaintext on disk.
- The user's chosen passphrase, run through PBKDF2, derives a *wrapping key*. `masterKey` is
  encrypted with the wrapping key (AES-GCM) and the result (`wrappedKeyByPassphrase`, plus the KDF
  salt) is stored in a new row in the existing local-only `app_settings` table (confirmed present
  in `packages/ledgerly_data/lib/src/db/schema.drift` — a device-local key/value table, not synced
  to the server). Both the PBKDF2 derivation and the AES-GCM wrap/unwrap come from
  `package:cryptography`, a well-maintained pure-Dart implementation — the **one** new dependency
  this whole feature needs (SQLCipher itself is not asked to do any of this derivation).
- The **printed recovery code** is `masterKey` itself, encoded as a human-typeable string (base32,
  grouped in 4-character blocks, e.g. `XM4K-9QRT-...`, matching how license keys or 2FA backup
  codes are conventionally formatted — no wrapping, no KDF, direct decode back to the 32 raw
  bytes). It's generated once, shown once, and the user is walked through printing/saving it
  before encryption is actually turned on — mirroring the existing print pipeline (`buildSlipPdf`
  et al. in `packages/ledgerly_data/lib/src/printing/`), a new template, not the slip/ledger ones.
- **Unlock at app launch**: try the passphrase first (derive wrapping key, decrypt
  `wrappedKeyByPassphrase`, get `masterKey`, open the SQLCipher file with it). If the passphrase is
  forgotten, an "I lost my passphrase" path lets the user type the recovery code directly — this
  decodes straight to `masterKey`, bypassing the passphrase entirely, and (critically) prompts the
  user to **set a new passphrase immediately** after a successful recovery-code unlock, since the
  old one is now effectively compromised (whoever had it typed it into this flow).
- **Changing the passphrase later** (Settings): decrypt `masterKey` with the *old* passphrase,
  re-wrap with a new KDF-derived key from the *new* passphrase, overwrite
  `wrappedKeyByPassphrase`. The recovery code (being `masterKey` directly, not
  passphrase-derived) **never changes** when the passphrase changes — this is a deliberate,
  user-facing fact to state clearly in the UI ("your recovery code stays valid even if you change
  your passphrase").
- **No UI in phase 1** is superseded here: this phase ships the toggle in Settings ("Enable
  encryption"), the setup wizard (choose passphrase → see & confirm the printed recovery code →
  confirm you've saved it), the unlock screen shown before the dashboard on every launch of an
  encrypted firm's database, and the "forgot passphrase" recovery-code path.
- **Backups**: `BackupService`'s existing `VACUUM INTO` (phase 1) copies the file as-is — an
  encrypted database backs up encrypted, restores encrypted, and needs the same
  passphrase/recovery-code to open after a restore. No change needed to `BackupService` itself,
  but the restore flow's "keep device identity" step needs to also prompt for
  passphrase/recovery-code if the restored file is encrypted, before the app can read anything
  from it (including the device-identity check itself) — this is a real sequencing wrinkle the
  implementation plan needs to get right: detect "is this file encrypted" *before* attempting the
  identity check, not after.

## 2. Google sign-in

**Backend**: new `POST /auth/google` in `backend/app/routers/auth.py`, mirroring the existing
`/auth/register` + `/auth/login` split but unified into one endpoint (a Google sign-in click
doesn't know ahead of time whether this is a first-time or returning user — the endpoint decides):

- Request body: `{id_token: str, firm: FirmInfo, device: DeviceInfo}` — same `FirmInfo`/`DeviceInfo`
  shapes `/auth/register` already uses (the app's first-launch wizard already creates these
  locally before any network call, exactly like the password path).
- Verify `id_token` server-side using `google.oauth2.id_token.verify_oauth2_token` from the
  `google-auth` package (already a dependency in `backend/pyproject.toml` — confirmed present,
  unused until now), with `audience` set to the **web** OAuth client ID (not the Android one — see
  below). Extract `sub` (Google's stable user ID) and `email` from the verified payload.
- If a user with that `google_sub` already exists: this is a login. Issue tokens for their
  existing firm, exactly like `/auth/login` does, ignoring the `firm`/`device` info the app sent
  (the existing firm is authoritative).
- If no user has that `google_sub`, but a user with that **email** already exists (registered via
  password originally): link the accounts — `UPDATE users SET google_sub = :sub WHERE email =
  :email`, then log in as that user. This is the standard "sign in with Google using the same
  email you registered with" convergence behavior most apps have.
- If neither matches: this is a first-time registration, structured identically to
  `/auth/register`'s transaction (insert firm, insert user with `google_sub` set and
  `password_hash` left `NULL`, insert firm_members owner row, insert device), then issue tokens.
- Reuses `_issue_tokens`/`_store_refresh_token` unchanged — no new token logic.

**App**: `google_sign_in: ^7.2.0` (a real API rewrite from older versions — confirmed against the
package's actual current source, not just its README prose). Key facts, verified against source
rather than assumed:
- `GoogleSignIn.instance.initialize(clientId: <iOS/Android client ID>, serverClientId: <web client
  ID>)`, then `.authenticate()` for an explicit user-initiated sign-in (the flow this app needs —
  not the silent `attemptLightweightAuthentication()` used for "was already signed in" checks,
  though that's worth wiring too for returning users so they're not re-prompted every launch).
- The ID token to send to the backend is `account.authentication.idToken` —
  `GoogleSignInAccount.authentication` returns a `GoogleSignInAuthentication` with exactly one
  field, `idToken`. The package's own doc comment is explicit that this is the *only* safe thing
  to send a backend (never the raw `id`/`email` fields directly — those aren't server-verifiable).
- **Setup dependency, flagged for the user**: this needs an OAuth client configured in Google
  Cloud project `ledgerly-1umerchaudhary` (the same project already running Cloud Run) — an
  Android client ID (keyed to the app's package name `pk.ledgerly.ledgerly` and its signing
  certificate's SHA-1) and a Web client ID (used as `serverClientId` in the app *and* as the
  `audience` the backend verifies against). Creating the OAuth consent screen and these two client
  IDs has manual steps in the Google Cloud Console that can't be fully scripted — the
  implementation plan flags exactly where to stop and walk the user through it.
- Settings gains a "Sign in with Google" button next to the existing email/password fields in the
  Cloud sync section, calling this new flow instead of `register`/`login`.

## 3. Silent 401 token refresh

Small, self-contained fix in `app/lib/features/settings/cloud_sync_providers.dart`'s
`SyncRunner.syncNow()`. Today, a `BackendAuthException` (401) from either `pushPending()` or
`pullAll()` immediately logs the user out (`cloud_sync_providers.dart:137-142`) — the code comment
at `sync_service.dart:14-15` already documents this as a known gap ("the caller... is responsible
for refreshing it before calling this; there's no in-flight 401-retry here yet").

Fix: on `BackendAuthException`, first try `client.refresh(session.refreshToken)` (the endpoint and
client method both already exist and work —`BackendClient.refresh`, `POST /auth/refresh`). If that
succeeds, save the new token pair (mirroring what `cloud_sync_providers.dart:54/75` already do
after register/login) and retry the *same* sync attempt once with the new access token. Only if
the refresh call **itself** throws `BackendAuthException` (the refresh token is also expired/
invalid — the genuinely-stale-session case) does the existing logout path fire.

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

- Encryption: this is the one place in this whole project where "can't lose the user's data" is
  the literal design goal, so the test bar is correspondingly higher — round-trip tests (encrypt →
  lock → unlock with passphrase → unlock with recovery code → change passphrase → unlock with
  *new* passphrase → recovery code still works), and a test that a *wrong* passphrase and a *wrong*
  recovery code both fail closed (no partial/silent data exposure).
- Google sign-in: the `verify_oauth2_token` call is the one piece that can't be TDD'd against a
  real Google server in CI — mock only that one call (a legitimate use of the "last resort" tier,
  since sandboxing a real Google OAuth flow isn't practical), real Postgres testcontainer for
  everything else (the three-way new/linked/existing-user branch, matching this backend's existing
  `/auth/register`/`/auth/login` test conventions).
- Token refresh: widget test forcing a `BackendAuthException` on the first sync attempt, a fake
  `refresh()` that succeeds, and asserting the retry actually happens and succeeds — plus the
  refresh-also-fails-so-logout path, unchanged from today.
