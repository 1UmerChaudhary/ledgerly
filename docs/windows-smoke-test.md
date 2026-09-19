# Windows + thermal printer smoke test

Everything in phase 1 has automated coverage (77 core + 57 data + 40 app tests, plus a CI run of
the installer itself on `windows-latest`) except the one thing no CI runner has: a real USB
thermal printer. This is the one remaining phase-1 check, and it needs your own Windows machine.

## Get the installer

1. Tag a release (from `~/Desktop/ledgerly`, on `main`, once you're ready):
   ```
   git tag v0.1.0
   git push origin v0.1.0
   ```
   This triggers the "Windows installer" workflow. When it finishes, download
   `Ledgerly-Setup-0.1.0.exe` from the run's Artifacts (or from the GitHub Release, if you add a
   release step later).
2. Copy it to the Windows machine and run it. `PrivilegesRequired=lowest`, so it installs to your
   user profile — no admin prompt. Windows SmartScreen will likely warn because the installer is
   unsigned (a phase-1 decision, not a bug) — "More info → Run anyway".

## Checklist

Work through this in order; each step depends on data from the one before it.

- [ ] **First launch** — wizard asks for firm name, contact, address, backup folder. Fill it in,
      finish, and land on the dashboard (empty).
- [ ] **Opening balances** — open the opening-balances grid, paste or type a few customers with
      signed balances (try one with a comma in the amount, e.g. `6,20,000`, to exercise the CSV
      parser). Save. Dashboard now shows them split into Receivables/Giveables.
- [ ] **Items** — add at least one item.
- [ ] **A two-line sale at the 37.324 base weight** — Ctrl+N, pick a customer, add two lines, use
      the `3` hotkey on the base-weight cell for 37.324 kg on at least one line. Watch the live
      total. Ctrl+Enter to save; confirm the Saved state shows the new balance.
- [ ] **Cash in** — Ctrl+I against the same customer.
- [ ] **A backdated purchase** — Ctrl+Shift+N, type a date before today.
- [ ] **Edit a bill** — F2/Ctrl+E on the sale. Override the total, save, then come back and change
      a line instead — confirm the "total overridden, lines changed" flag appears.
- [ ] **Ledger** — open the customer's ledger. Running balance should match the dashboard. The
      edited bill shows its "edited" badge; open its history panel, confirm the diff view shows
      the field that changed, and restore an earlier version.
- [ ] **Print a slip** — Ctrl+P on a saved bill. First time, this should prompt for a printer
      (no default saved yet); pick your thermal printer. Confirm it prints on 80mm paper, legible,
      with the firm header, correct previous/new balance, and a timestamp.
- [ ] **Set a default printer** — Settings → Printer → Choose printer… → pick the thermal printer.
      Print another slip; it should go straight to the printer with no dialog this time.
- [ ] **Print a ranged ledger** — Ctrl+Shift+P on the ledger, pick "This month". Confirm it prints
      on A4 (or your default printer, if that's what's configured) with the correct opening
      balance for the range and a page number.
- [ ] **Backup** — Ctrl+B, or Settings → Backup now. Confirm the "Backed up" timestamp updates and
      a `.db` file appears in the backup folder you set at first launch.
- [ ] **Uninstall, reinstall** — uninstall Ledgerly (Windows Settings → Apps), reinstall from the
      same `.exe`. It should land back on the first-launch wizard (a fresh profile).
- [ ] **Restore** — at the wizard, or from Settings → Restore from backup…, pick the `.db` file
      from the backup step. Confirm you're back to the exact state before uninstalling — same
      customers, same balances, same bill numbering (the next bill continues from where it left
      off, it does not restart at 1).

If every box is checked, phase 1 is done. Anything that doesn't match is a real bug — note the
exact step and what you saw, not just "printing didn't work."
