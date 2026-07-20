# Current status

## Project state

M0–M2 are complete and merged/in-review on branch `m1-stage1-payroll-v1`.
The codebase has two independently compiling COBOL programs plus a shared
copybook. No subprogram (`CALL`) or indexed-file work has started yet.

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

Both programs compile with `cobc -x -Wall -I copybooks` at zero warnings.

## Features in progress

None currently in flight.

## Known issues

None outstanding — both programs compile clean and their output has been
manually verified against hand-computed expected values.

## Recent major changes

- Extracted the employee record layout into `copybooks/employee-record.cpy`
  and updated `payroll-v1.cob` to `COPY` it instead of declaring the
  05-level fields inline.
- Added `src/payroll-report.cob`, a new Stage 2 program demonstrating
  copybook reuse and paginated report output.
- Added `data/payroll-summary.out` as the checked-in sample output for the
  new program.

## Open technical concerns

- No automated tests or CI — see
  [architecture.md#known-architectural-debt](architecture.md#known-architectural-debt).
  Acceptable while test data stays small enough to hand-verify.
- Stage 3's calling convention (exact `LINKAGE SECTION` parameter list
  between the main program and `tax-calc.cob`) isn't designed yet.

## Recommended next actions

1. Start M3 (Stage 3): design the `CALL ... USING` contract for
   `tax-calc.cob`, then implement and hand-verify net pay.
2. Keep this file and `docs/roadmap.md` updated as M3 progresses, per the
   project's per-stage documentation convention.
