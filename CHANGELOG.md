# Changelog

## v0.2.0 — 2026-09-23

Phase 2 completion: local database encryption, Google sign-in, and reliability fixes for cloud
sync, on top of the Phase 1 (Windows desktop) and Android support already shipped in v0.1.0.

### Encryption

- Passphrase-protect a firm's local database (SQLCipher). Setup wizard generates a random master
  key, wraps it two independent ways — once under the user's passphrase, once under a printed/
  written recovery code (Argon2id KDF + AES-GCM) — so either secret unlocks the firm and neither
  depends on the other. The envelope (both wrapped copies) lives in a plaintext `<firmId>.key.json`
  sidecar next to the database file, never inside it.
- Existing (plaintext) firms can migrate to encrypted in place, via SQLCipher's `sqlcipher_export`,
  with a crash-safe swap sequence and the original plaintext kept as a safety copy until the
  encrypted copy is independently re-verified.
- Backups of an encrypted firm now carry the key envelope alongside the database, and can be
  restored on a different device using that backup's own passphrase or recovery code (not the
  current session's key).
- Passphrase changes and recovery-code rotation genuinely revoke the old secret (the previous
  envelope is deleted once the new one is confirmed durable), matching the "the old one stops
  working" guarantee stated in the UI.
- Known gap (tracked, not yet fixed): the key-file swap during a cross-device restore isn't
  atomic the way the database swap is — a crash at exactly the wrong moment during that specific
  step could corrupt the newly-installed key file. The original backup is untouched either way,
  so nothing is destroyed, but this should be hardened before recommending cross-device restore
  for anything critical. See `packages/ledgerly_data/lib/src/backup_service.dart`, the envelope
  install step inside `restoreFrom`.
- Known gap: canceling the encryption setup wizard while the recovery code is on screen loses
  that code silently (the passphrase still works; a new recovery code can be generated afterward
  from Settings). A guard or warning banner would close this.
- Known gap: restoring a backup via its recovery code doesn't force a new passphrase the way a
  normal recovery-code unlock does. Self-healing (the recovery code still works normally on the
  next unlock), so low urgency.

### Google sign-in (Android only)

- `POST /auth/google` + `POST /auth/google/link` on the backend. An email match to an existing
  password account never auto-links (that would be an account-takeover vector, since
  `/auth/register` has no email verification) — it returns `409 email_exists_unlinked`, and
  linking only happens through the explicit, authenticated `/auth/google/link` call.
- App-side sign-in and account-linking UI, gated to Android — the `google_sign_in` package has no
  Windows/Linux implementation.

### Sync reliability

- `SyncRunner` now retries once on a 401 (expired access token) via `/auth/refresh` before
  logging the user out, with a single-flight guard so concurrent sync calls don't each try to
  refresh independently — `/auth/refresh` rotates the refresh token on every call, so a naive
  retry-per-caller implementation would cause spurious logouts.

### Smaller items

PNG export wired up on the ledger detail screen; keyboard hints hidden on phone-width screens;
five smaller items parked from the Android-support round closed out.

## v0.1.0 — 2026-09-19

Phase 1 (Windows desktop, full offline functionality) and Phase 3 (Android/touch support)
complete: entry screens, ledger with edit history, printing (80mm slip + A4 ledger PDFs), local
backup/restore, settings, and a responsive touch UI for phone-width screens. Tagged and released
with a Windows installer (Inno Setup) and an Android APK.
