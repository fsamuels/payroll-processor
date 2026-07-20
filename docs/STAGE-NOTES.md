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

_(not started)_

## Stage 4 — Indexed file + table lookup (stretch)

_(not started)_
