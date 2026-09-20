# Android support (Phase 3) — design

Status: approved by user 2026-09-20, pending spec review before implementation plan.

## Context

Phase 1 (desktop) and phase 2 (backend + sync) are complete. The design spec's Phase 3 line item
("phone stacks in phase 3") was never detailed. This spec fills that in: what Android actually
needs to be, how the existing keyboard-first desktop UI adapts to touch, and how thermal-printing
works without a USB port.

## Goals

- **Full parity, not a companion app.** Android runs the same local-first app as desktop — its
  own drift/SQLite copy, every screen, every feature. Sync to a hosted backend is added the same
  way it already works on desktop: point `LEDGERLY_BACKEND_URL` at a deployed instance (already
  live on Cloud Run as of this session) once a device wants to sync. Android does not depend on
  sync to be useful, exactly like desktop.
- Reuse every existing domain/data/controller layer unchanged. This is presentation-layer work
  only — `packages/ledgerly_core`, `packages/ledgerly_data`, Riverpod controllers, and
  `app/lib/sync/*` need zero changes.

## Non-goals

- No new business logic, no schema changes, no new sync behaviour.
- No attempt to preserve keyboard shortcuts as the *primary* interaction model on phone — they
  stay wired in (see below) but touch is the primary path being designed here.

## Architecture: breakpoint-based, not platform-based

The app already branches on nothing platform-specific for layout — it assumes desktop width
everywhere. Rather than adding `if (Platform.isAndroid)` branches, layout adapts to available
width using a single breakpoint at **600dp** — Material 3's defined compact/medium cutoff:

- **Below 600dp** ("compact"): bottom navigation bar + a FAB for the most common action
  (new sale), replacing the letter-keyed `_Rail`. The `_KeyBar` (keyboard hint strip) is omitted —
  there's nothing to hint at without a keyboard.
- **At or above 600dp** ("expanded"): today's two-pane rail layout, unchanged. This
  covers desktop *and* a large Android tablet or a phone in landscape with room to spare — the
  same widget tree adapts by width everywhere, not by OS.
- `CallbackShortcuts` (Ctrl+N, Ctrl+I, etc. in `AppShell`) stay wired in unconditionally at every
  width. Free bonus for a tablet with a Bluetooth keyboard attached; costs nothing to keep for
  phone-only use where no keyboard exists to trigger them.

## Screens: two need real redesign, the rest are mechanical

Dashboard, customers/items lists, cash entry, and settings need only "stack instead of
side-by-side" adjustments at compact width — no new interaction model. Two screens are genuinely
different:

### Bill form

Today: a keyboard grid (Tab between cells, Enter to pick/advance, hotkeys 1–5 for standard base
weights, Space toggles sale mode, Ctrl+Minus removes a line). At compact width this becomes a
scrollable list of line **cards**:

- Tapping the item field opens a full-screen search (replaces type-and-autocomplete-with-Enter).
- Sale mode becomes a tappable segmented toggle.
- The base-weight hotkeys (30/34/37.324/40/56 g) become tappable chips.
- A swipe or trailing delete icon removes a line; a bottom "+ Add line" button adds one.
- Numeric fields get the appropriate on-screen keyboard (decimal for weights/rates).

Same underlying line/total logic (`RateCalculator`, the generated `calculated_total`/
`final_amount` columns) — only the input widgets change. No change to `transactions` /
`transaction_lines` handling.

### Ledger

Today: list and detail+history panel are always visible side by side. At compact width these
become two stacked routes: tapping a row in the list pushes a full-screen detail route (back
returns to the list) via `go_router` — a standard push, not a new data concept. The history diff
view becomes its own pushed screen rather than a persistent side panel.

## Printing

Desktop's print pipeline sends a **PDF** to the OS printer via the `printing` package. Generic
cheap ESC/POS Bluetooth thermal printers do not speak PDF — they take raw byte commands over
Bluetooth SPP (text formatting codes, cut command, etc.). This is not "make PDF printing also
work on Android" — it's a second, parallel rendering path sharing the same input data:

- **Shared data, two renderers.** `SlipModel` (already the input to the existing PDF template)
  becomes the single source of truth for a slip's content. Desktop/export keeps rendering it to
  PDF, unchanged. A new `EscPosRenderer` renders the same `SlipModel` to raw ESC/POS bytes for the
  Bluetooth path. Pricing/formatting logic is never duplicated — only the output encoding differs.
- **New seam**, parallel to the existing `PrintingService`: a `ThermalPrinterService`
  (connect/print/disconnect over Bluetooth SPP). Settings gains a Bluetooth-printer picker
  (scan/pair) on Android, alongside the existing named-printer picker used on desktop.
- **Downloads-folder export.** Android's `exportPdf`/`exportPng` write directly to the public
  Downloads directory instead of using `file_selector`'s save dialog, which has no real equivalent
  on Android.

## Error handling

- Bluetooth connect failure (printer off, out of range, not paired): surfaced the same way a
  missing desktop printer already degrades — falls back to "ask" (Android's share/export sheet)
  rather than a silent failure, matching the existing app-wide convention of degrading to "ask"
  when nothing is configured.
- Compact-width navigation (list → pushed detail route) needs no new error handling — it's a
  normal `go_router` push/pop, same failure modes (none) as any existing route transition.

## Testing

- **ESC/POS byte generation** from a `SlipModel` is pure logic — golden-byte-sequence tests, no
  hardware needed, same spirit as the existing PDF golden-raster test.
- **Bluetooth transport** gets faked in tests exactly like `PrintingService` already is (real
  Bluetooth I/O is untestable in CI). Only manual testing against real hardware — deferred until
  the user has a Bluetooth thermal printer to test against — exercises the real transport. This
  is a known, accepted gap: the code is built and unit-tested now, hardware-verified later.
- **New `androidOnly` (or `phoneOnly`) widget-test variant**, alongside the existing
  `windowsOnly` variant: forces Android platform + a phone-sized `tester.view.physicalSize`.
  Reuses every existing fixture/controller/harness unchanged (`pump_app.dart` et al.) — only the
  interaction assertions differ (tap sequences instead of key events).
- Existing desktop/`windowsOnly` tests are untouched; this is additive.

## Open items carried forward (not blocking this spec)

- Real hardware verification of the Bluetooth thermal path (deferred per user decision this
  session — building now, testing once a printer is bought).
- Android app signing / Play Store listing is out of scope for this phase (matches phase 1's
  "Windows unsigned for now" precedent — no cost/process reason to sign before there's a paying
  user).
