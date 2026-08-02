# Stage notes

What each stage demonstrates and gotchas hit along the way. Updated as each
stage lands.

## M0 — Repo + toolchain setup

- GnuCOBOL 3.2.0 installed via `brew install gnucobol` (pulls berkeley-db,
  gmp, json-c as dependencies). Installed cleanly on Apple Silicon.
- `src/hello.cob` is a minimal fixed-format program: sequence numbers in
  cols 1–6, `*` in col 7 for comments, division headers in Area A (col 8),
  statements in Area B (col 12+).
- `cobc -xj src/hello.cob` compiles and runs in one step. It leaves the
  compiled executable (`hello`, no extension) in the working directory —
  covered by `.gitignore`.
- Compiled with zero warnings; no format or dialect flags needed for
  fixed-format source, since fixed is GnuCOBOL's default.

## Stage 1 — Single flat-file program

- `src/payroll-v1.cob` reads `data/employees.dat` (4 hand-written records,
  fixed-width, 34 bytes each: `EMP-ID PIC 9(4)`, `EMP-NAME PIC X(20)`,
  `EMP-HOURS PIC 9(3)V99`, `EMP-RATE PIC 9(3)V99`) and writes
  `data/payroll-report.out` — a title, column headers, one detail line per
  employee, a totals line, and an employee-count line.
- Gross pay is `COMPUTE WS-GROSS-PAY = EMP-HOURS * EMP-RATE`, accumulated
  into a running total with `ADD`. Output checked by manual arithmetic:
  1,000.00 + 1,159.00 + 832.50 + 880.00 = 3,871.50, matching the
  `TOTAL GROSS PAY` line.
- Edited-picture width has to fit the largest value that can land in it,
  not just the largest value in the current test data. `PIC ZZ9.99` tops
  out at 999.99, so the per-employee gross field needed `PIC Z,ZZ9.99`
  headroom, and the running total (which sums across all employees) needed
  `PIC ZZ,ZZ9.99`. Undersizing either would silently truncate/misformat
  rather than error at compile time.
- `LINE SEQUENTIAL` output trims trailing spaces on `WRITE` in GnuCOBOL
  3.2 — the ragged-right report lines (header vs. detail vs. totals, all
  different lengths) come out clean in the `.out` file with no manual
  trimming needed.
- `V` in a PICTURE clause is an implied decimal point — it reserves no
  byte in the data file. 40.00 hours is stored as the 5 digits `04000`,
  not `040.00`. Zero-padding has to line up exactly with the implied
  decimal position or every field after it in the record shifts.
- Compile: `cobc -x -o payroll-v1 src/payroll-v1.cob` — zero warnings with
  `-Wall`. Run as `./payroll-v1` from the repo root, since `ASSIGN TO
  "data/employees.dat"` and `"data/payroll-report.out"` are relative paths.

## Stage 2 — Extract a copybook

- `copybooks/employee-record.cpy` holds just the `01 EMPLOYEE-RECORD`
  entry (05-level fields, no `FD`) — the `FD EMPLOYEE-FILE.` line stays in
  each program, since the file-name it's tied to is program-specific even
  when, as here, both programs happen to use the same one.
- `COPY` is pure textual substitution at compile time, applied before the
  compiler does anything else with the source — so the `.cpy` file has to
  follow the same fixed-format column rules (sequence numbers, indicator
  area, Area A/B) as the `.cob` file it's inserted into.
- Compiling either program now needs `-I copybooks` so `cobc` can resolve
  `COPY EMPLOYEE-RECORD.` to `copybooks/employee-record.cpy`. Omitting the
  flag fails at compile time with a clear "copybook not found" error, not
  a silent problem.
- After extracting the copybook, recompiled `payroll-v1.cob` and diffed
  `data/payroll-report.out` against the pre-extraction output — byte
  identical, confirming the refactor changed nothing observable.
- `payroll-report.cob` COPYs the same layout to build a paginated summary
  report. `WRITE ... AFTER ADVANCING PAGE` is COBOL's page-break
  mechanism — confirmed with a throwaway test program that it inserts a
  literal form-feed control character (hex `0C`, `\f`) into the output
  immediately before that WRITE's line, visible with `od -c`. The first
  page's header intentionally skips `ADVANCING PAGE` (plain `WRITE`)
  since a leading form-feed before any content would be a stray control
  character with nothing to page past.
- `WS-LINES-PER-PAGE` is set to 2 (a real report might use 40-60) purely
  so the existing 4-employee sample data exercises an actual page break
  without needing bigger test data — keeps output hand-verifiable per
  this project's convention of small test data (see M1 notes above).
  With 2 employees/page, `data/payroll-summary.out` comes out as two
  pages (1001/1002, then 1003/1004) with grand totals appended after the
  last page, matching Stage 1's total-gross of 3,871.50.
- Compile: `cobc -x -I copybooks -o payroll-report src/payroll-report.cob`
  — zero warnings with `-Wall`. Run as `./payroll-report` from the repo
  root (relative `ASSIGN` paths).

## Stage 3 — Called subprogram

- `src/tax-calc.cob` is a subprogram: no `FILE SECTION`, no files of its
  own, just a `LINKAGE SECTION` (`LS-GROSS-PAY` in; `LS-TAX-AMOUNT`,
  `LS-NET-PAY` out) and ends each invocation with `GOBACK` instead of
  `STOP RUN` — `STOP RUN` would end the whole caller's process, not just
  return from the one `CALL`.
- `src/payroll-net.cob` is a new, independent Stage 3 driver program
  (rather than a change to `payroll-v1.cob`) — same one-artifact-per-stage
  approach Stage 2 used, and it means Stage 1/2's byte-diff-verified
  output stays untouched. It `COPY`s the same `employee-record.cpy`
  layout, computes gross pay identically to `payroll-v1.cob`, then
  `CALL "TAX-CALC" USING WS-GROSS-PAY WS-TAX-AMOUNT WS-NET-PAY` once per
  employee.
- COBOL `CALL` links parameters **positionally**, by matching storage
  layout, not by name — `WS-GROSS-PAY`/`WS-TAX-AMOUNT`/`WS-NET-PAY` in
  `payroll-net.cob` must appear in the same order and have the same
  `PICTURE` (`9(5)V99`, all three) as `LS-GROSS-PAY`/`LS-TAX-AMOUNT`/
  `LS-NET-PAY` in `tax-calc.cob`'s `PROCEDURE DIVISION USING`. Nothing
  checks this by name at compile time; a mismatched order or PICTURE
  would silently misinterpret the bytes on the other side.
- Three fictional, hand-verifiable tax brackets, implemented as hardcoded
  `IF`/`ELSE` (not a table): gross `<= 850.00` → 10%, `<= 1050.00` → 15%,
  otherwise → 20%. Thresholds were chosen so all three brackets are
  actually exercised by the existing 4-employee sample data (rather than,
  say, a boundary that happens to leave one bracket untested):
  - 1003 CAROL CHEN: gross `832.50` → 10% → tax `83.25`, net `749.25`
  - 1004 DAVID DIAZ: gross `880.00` → 15% → tax `132.00`, net `748.00`
  - 1001 ALICE ANDERSON: gross `1,000.00` → 15% → tax `150.00`, net `850.00`
  - 1002 BOB BAKER: gross `1,159.00` → 20% → tax `231.80`, net `927.20`
  - Totals: tax withheld `597.05`, net pay `3,274.45` — checked against
    Stage 1's total gross of `3,871.50` (`3,871.50 - 597.05 = 3,274.45`).
- `COMPUTE ... ROUNDED` is used for the tax amount (e.g. `832.50 * 0.10 =
  83.250` rounds to `83.25`) — without `ROUNDED`, COBOL truncates instead
  of rounding, which would only differ here at the third decimal place
  but is worth being deliberate about for any bracket/rate combination
  that lands exactly on a rounding boundary.
- This hardcoded `IF`/`ELSE` is deliberately the "before" picture for
  Stage 4, which plans to replace it with an `OCCURS` table and
  `SEARCH`/`SEARCH ALL` (see roadmap.md) — not a shortcut to clean up
  later, but the intended point of comparison between the two idioms.
- **Two programs compiled together, not a dynamically-loaded module.**
  The README originally anticipated `cobc -m src/tax-calc.cob` (a
  separately compiled `.so` module, dynamically loaded at runtime by
  name). In practice, giving both source files to `cobc -x` in one
  invocation (`cobc -x -I copybooks -o payroll-net src/payroll-net.cob
  src/tax-calc.cob`) statically links the `CALL` target into a single
  executable — simpler, and it avoids any runtime module-search-path
  configuration (`COB_LIBRARY_PATH` and friends) entirely. No separate
  `tax-calc` binary or `.so` file is produced.
- **Copybook `COPY` resolution turned out to be case-sensitive** on the
  Linux GnuCOBOL install used to verify this stage compiles: `COPY
  EMPLOYEE-RECORD.` failed to resolve to `employee-record.cpy` with `-I
  copybooks` until a same-case `EMPLOYEE-RECORD.cpy` existed alongside it.
  This project's stated platform is macOS, whose default filesystem is
  case-insensitive, so `payroll-v1.cob`/`payroll-report.cob` have never
  hit this — it only surfaced here because Stage 3 verification happened
  on Linux. No repository change was made for it (see architecture.md's
  Known architectural debt); noted in case a Linux CI job is ever added.
- Compile: `cobc -x -I copybooks -o payroll-net src/payroll-net.cob
  src/tax-calc.cob` — zero warnings with `-Wall`. Run as `./payroll-net`
  from the repo root (relative `ASSIGN` paths, same as Stages 1–2).

## Stage 4 — Indexed file + table lookup (stretch)

_(not started)_
