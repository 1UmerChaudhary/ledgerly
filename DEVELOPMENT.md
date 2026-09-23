# Development notes

Toolchain setup and hard-won gotchas for working on this repo. Project decisions and architecture
live in [docs/design-spec.md](docs/design-spec.md); this file is implementation-detail facts.

## Toolchain

- **Flutter**: installed manually at `~/development/flutter` (not Homebrew — the cask needs
  `sudo xcodebuild -license accept`, which needs a password prompt this environment couldn't give).
  Add `~/development/flutter/bin` to `PATH` if `flutter`/`dart` aren't found.
- **Windows builds**: can't be done on macOS/Linux — Flutter's Windows desktop target only compiles
  on Windows. `.github/workflows/windows-installer.yml` builds one on `windows-latest` on every
  `v*` tag push (or manually via `workflow_dispatch`), bundles the VC++ runtime, builds an Inno
  Setup installer, and smoke-tests that a silent install actually places `ledgerly.exe`. Building
  a Java-dependent Android release locally needs `JAVA_HOME` set explicitly — Flutter doesn't find
  a JDK on its own here; a Homebrew `openjdk@17` install works
  (`/opt/homebrew/Cellar/openjdk@17/*/libexec/openjdk.jdk/Contents/Home`).
- **Backend**: isolated venv at `backend/.venv` (Python 3.11), deliberately separate from any other
  project's venv/poetry/uv setup. `pip install -e ".[dev]"`.
- **GitHub**: repo is `github.com/1UmerChaudhary/ledgerly` (personal account, public). `git push`
  works from a plain shell regardless of which `gh` account is active, because the repo has a
  repo-local `credential.helper` that resolves to the `1UmerChaudhary` token — but `gh` subcommands
  (`gh release`, `gh repo edit`, etc.) use whichever account is currently *active*, which needs an
  explicit `gh auth switch --hostname github.com --user 1UmerChaudhary` first, and switching back
  afterward if other work depends on a different account being active by default.

## Backend gotchas

- **passlib's bcrypt backend is broken against current bcrypt** (`AttributeError: module 'bcrypt'
  has no attribute '__about__'` — a long-unresolved upstream incompatibility). Call the `bcrypt`
  package directly (`bcrypt.hashpw`/`bcrypt.checkpw`), don't reach for passlib. bcrypt also
  hard-raises on any password over 72 bytes — validated at the request-schema level (a pydantic
  `field_validator`) on both register and login, or it's an unhandled 500 on ordinary long input.
- **Starlette's sync `TestClient` runs the app in a separate thread with its own event loop** —
  mixing it with an async SQLAlchemy fixture throws `RuntimeError: ... attached to a different
  loop`. Use `httpx.AsyncClient(transport=ASGITransport(app=app))` with `async def test_...`
  instead, so everything runs on the one loop pytest-asyncio already gave the test.
- **Tests share one Postgres testcontainer + one `alembic upgrade head` for the whole session**,
  isolated per test via `AsyncSession(bind=conn, join_transaction_mode="create_savepoint")` inside
  an outer transaction the fixture rolls back at teardown. Endpoints calling `db.commit()`
  (every write endpoint does, correctly) only release a SAVEPOINT under this mode — without
  `join_transaction_mode`, the app's own commit would end the outer transaction early and break
  test isolation.
- Testcontainers occasionally leaks orphaned `postgres:17-alpine`/`redis:7-alpine` containers if a
  test run gets killed rather than exiting cleanly (interrupted session, `Ctrl+C` mid-suite, etc.).
  Harmless but accumulates — `docker ps -a` and remove anything with a random Docker-generated name
  that isn't part of an active dev stack.

## App/data gotchas

- **Real file I/O inside a `flutter test` widget test hangs forever** in a sandboxed dev
  environment. Any test doing real file I/O (envelope files, database files, backups) with no
  actual Flutter/widget dependency should be a plain `dart test` file instead. Tests that
  genuinely need Flutter (e.g. anything importing `path_provider` transitively, or real widgets)
  have to stay as `flutter test` and just avoid real file I/O — use in-memory fakes there instead.
- **A closure passed to `NativeDatabase.createInBackground`'s `setup:` (or anything else crossing
  an `Isolate.spawn` boundary) must not capture Riverpod's `ref` or any other non-sendable
  object.** An unsendable capture throws at isolate-spawn time — before the database opens —
  invisible to static analysis and to any test that never sets a key. Build the closure in a
  top-level function that captures only plain, sendable values (a `String`, a `Uint8List`, etc).
- **A wrong SQLCipher key is accepted by `PRAGMA key` itself** (it's silently a no-op on an
  unrecognized key) **and only fails on the first real read** (`SELECT`, `PRAGMA quick_check`,
  etc). Any "is this the right key" check needs to force a genuine read, not just an open.

## Release process

1. Bump `app/pubspec.yaml`'s `version:` field.
2. `git tag vX.Y.Z && git push origin vX.Y.Z` — this alone triggers the Windows installer build
   in CI (`windows-installer.yml`).
3. Build the Android release locally: `cd app && flutter build apk --release` (needs `JAVA_HOME`
   set, see above). Output: `app/build/app/outputs/flutter-apk/app-release.apk`.
4. `gh release create vX.Y.Z <apk-path>#<label> --title ... --notes ...` (switch `gh` to the
   `1UmerChaudhary` account first), then `gh run download <windows-installer-run-id> -n
   ledgerly-windows-installer` and `gh release upload vX.Y.Z <installer-path>` to attach both
   platform builds to the same release.
