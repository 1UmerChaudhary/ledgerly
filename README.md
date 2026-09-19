# Ledgerly

Offline-first ledger for small trading and processing firms. Desktop first (Windows), Android next,
cloud sync later. Design spec: [docs/design-spec.md](docs/design-spec.md). Clickable screen mockups:
[docs/mockups/phase1-screens.html](docs/mockups/phase1-screens.html). Windows + thermal printer
release checklist: [docs/windows-smoke-test.md](docs/windows-smoke-test.md).

## Layout

| Folder | What |
|---|---|
| `packages/ledgerly_core/` | Pure Dart: money and weight types, balance and rate math, clocks, name/phone normalisation, repository interfaces. No Flutter, no database. |
| `app/` | The Flutter app: screens, controllers, SQLite (drift), backups, printing, sync engine. |
| `backend/` | Phase 2 FastAPI sync API. |
| `docs/` | Spec, mockups, decisions. |

## Rules of the house

- Money is stored in paisa and weight in grams, always integers.
- Balances are never stored. They are computed from transactions.
- The UI never touches SQL. The domain never imports Flutter.
