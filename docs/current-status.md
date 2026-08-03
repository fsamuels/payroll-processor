# Current status

## Project state

M0–M3 are complete and merged. The codebase has three independently
compiling COBOL programs, a shared copybook, and one called subprogram.
Indexed-file work (Stage 4) has not started.

## Features completed ✅

- **M0 — Toolchain setup.** GnuCOBOL 3.2.0 via Homebrew, verified with
  `src/hello.cob` (`cobc -xj`, zero warnings).
- **M1 — Stage 1 (`src/payroll-v1.cob`).** Reads `data/employees.dat`
  (4 fixed-width records), computes gross pay (`hours × rate`), writes
  `data/payroll-report.out` — title, column headers, one detail line per
  employee, total-gross line, employee-count line. Verified by hand:
  total gross `3,871.50`.
- **M2 — Stage 2 (`copybooks/employee-record.cpy` +
  `src/payroll-report.cob`).** Employee record layout extracted to a
  copybook, `COPY`d into both `payroll-v1.cob` and the new
  `payroll-report.cob`. The new program produces a paginated summary
  report in `data/payroll-summary.out`: repeating page/column headers, 2
  detail lines per page, a page break (`WRITE ... AFTER ADVANCING PAGE`,
  confirmed to emit a real form-feed byte) whenever a page fills, grand
  totals at the end. `payroll-v1.cob`'s output was byte-diffed against
  its pre-copybook version to confirm the refactor was behavior-preserving.
- **M3 — Stage 3 (`src/tax-calc.cob` + `src/payroll-net.cob`).** Tax
  withholding moved into its own subprogram, `tax-calc.cob`, with a
  `LINKAGE SECTION` taking gross pay in and returning tax withheld and net
  pay. A new driver program, `payroll-net.cob`, reads the same
  `data/employees.dat` (via the shared copybook), computes gross pay the
  same way Stage 1 does, `CALL`s `tax-calc.cob` per employee, and writes
  `data/payroll-net-report.out` — gross/tax/net detail lines plus three
  grand-total lines and the employee count. Three fictional, hardcoded
  `IF`/`ELSE` tax brackets (10%/15%/20%, thresholds `850.00`/`1050.00`)
  were chosen so all three are exercised against the existing 4-employee
  sample data. Verified by hand: total tax withheld `597.05`, total net
  pay `3,274.45` (`3,871.50 - 597.05`).

All three standalone programs compile with `cobc -x -Wall -I copybooks` at
zero warnings (`payroll-net` additionally needs `src/tax-calc.cob` given
to `cobc` in the same invocation, so the `CALL` resolves — see README).

## Features in progress

None currently in flight.

## Known issues

None outstanding — all three programs compile clean and their output has
been manually verified against hand-computed expected values.

## Recent major changes

- Added `src/tax-calc.cob`, a Stage 3 subprogram computing tax withheld
  and net pay from gross pay via `CALL ... USING` / `LINKAGE SECTION`,
  with three hardcoded fictional tax brackets.
- Added `src/payroll-net.cob`, a new independent Stage 3 driver program
  that `CALL`s `tax-calc.cob` and writes `data/payroll-net-report.out`.
- Added `data/payroll-net-report.out` as the checked-in sample output for
  the new program.
- Discovered and documented (README, architecture.md) a `COPY`
  copybook-resolution case-sensitivity gotcha on Linux filesystems, found
  while verifying Stage 3 compiles outside this project's usual macOS
  environment — no code change needed, since the project targets macOS.

## Open technical concerns

- No automated tests or CI — see
  [architecture.md#known-architectural-debt](architecture.md#known-architectural-debt).
  Acceptable while test data stays small enough to hand-verify.
- Stage 4's go/no-go decision (indexed file + `OCCURS`/`SEARCH` table,
  replacing `tax-calc.cob`'s hardcoded `IF`/`ELSE` brackets) hasn't been
  made yet.

## Recommended next actions

1. Decide go/no-go on Stage 4 (Stage 4 is explicitly optional/stretch —
   see roadmap.md).
2. If go: design the indexed-file migration and `OCCURS` tax-bracket
   table, then implement and hand-verify against the same sample data.
3. Keep this file and `docs/roadmap.md` updated as M4 progresses, per the
   project's per-stage documentation convention.
