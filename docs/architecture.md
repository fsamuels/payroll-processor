# Architecture

## Overview

This is a local, single-user COBOL codebase built in stages with
GnuCOBOL — there is no server, service, or deployed component. Each stage
is a complete, independently runnable artifact (one or more `.cob`
programs, compiled to a standalone executable). Do not proceed to the
next stage until the current stage compiles and produces correct output
against test data. Each stage is its own PR.

## Components and responsibilities

| Component | Responsibility |
|---|---|
| `src/hello.cob` | M0 toolchain check — minimal fixed-format program, no business logic. |
| `src/payroll-v1.cob` | Stage 1. Reads `data/employees.dat`, computes gross pay, writes `data/payroll-report.out` (single-block report: headers, one line per employee, totals). |
| `src/payroll-report.cob` | Stage 2. Reads the same `data/employees.dat`, writes `data/payroll-summary.out` — a paginated summary report (repeating page headers, capped detail lines per page, page breaks, grand totals). Independent executable from `payroll-v1`; shares only the record layout. |
| `copybooks/employee-record.cpy` | Shared `01 EMPLOYEE-RECORD` layout (`EMP-ID`, `EMP-NAME`, `EMP-HOURS`, `EMP-RATE`). `COPY`d into both `payroll-v1.cob` and `payroll-report.cob` so the two programs cannot drift apart on the file format. |
| `src/tax-calc.cob` *(Stage 3, not yet implemented)* | Planned subprogram: gross pay in, net pay / tax withheld out via `CALL ... USING`. |
| `data/employees.dat` | Sample/test employee master file — fixed-width, currently 4 hand-written records. |

## Data flow

```
data/employees.dat  (fixed-width sequential file)
        │
        ├─▶ payroll-v1.cob      ──▶ data/payroll-report.out    (Stage 1: flat report)
        │
        └─▶ payroll-report.cob ──▶ data/payroll-summary.out   (Stage 2: paginated report)
                 ▲
                 └── COPY EMPLOYEE-RECORD.  (copybooks/employee-record.cpy,
                      also COPYd into payroll-v1.cob)
```

Both programs open `EMPLOYEE-FILE` read-only, loop record-by-record with a
priming read + `PERFORM UNTIL` end-of-file, and open their own
`REPORT-FILE` write-only/output. There is no shared runtime state between
the two programs — the only thing shared is the compile-time copybook
text.

Planned (Stage 3): `payroll-v1.cob` (or a successor) will `CALL` into
`tax-calc.cob`, passing gross pay in and receiving net pay / tax withheld
back via `LINKAGE SECTION` parameters, still within a single process.

## External integrations

None. No network calls, databases, or third-party services. All I/O is
local flat files under `data/`.

## Deployment architecture

None — this is a local development/portfolio project. Programs are
compiled with `cobc` and run directly from the repo root; there is no
packaging, containerization, CI/CD, or target runtime beyond "GnuCOBOL
installed locally via Homebrew." See the roadmap for whether a CI
compile-check gets added.

## Design decisions

- **Fixed-format COBOL throughout.** GnuCOBOL also supports free format
  (`-free`), but this project uses fixed format (column-position rules —
  Area A/B, sequence numbers in cols 1–6, indicator in col 7) for
  authenticity and portfolio value.
- **`LINE SEQUENTIAL` file organization** for both input and output in
  Stages 1–2 — plain text, one record per line, easy to inspect with
  ordinary text tools. Stage 4 deliberately switches the master file to
  `INDEXED` to demonstrate the contrast.
- **Copybook holds only the `01`-level record, not the `FD`.** The `FD
  EMPLOYEE-FILE.` line stays in each program (the file-name it's attached
  to is program-specific even when, as here, it happens to be the same
  name in both programs); only the field layout is shared.
- **Small, hand-verifiable test data** (currently 4 employees) rather than
  a larger synthetic dataset, so every program's output can be checked by
  manual arithmetic instead of relying on a test framework. This is a
  deliberate tradeoff against realism/scale — see Known architectural
  debt.
- **Each stage is a separate, independently compiling artifact and a
  separate PR**, rather than one evolving program — the point of the
  project is to demonstrate the *progression* of COBOL idioms (flat file
  → copybook → subprogram → indexed file), not just the end state.

## Technical constraints

- GnuCOBOL only (no mainframe COBOL dialect extensions assumed beyond what
  GnuCOBOL 3.2.0 supports).
- macOS / Apple Silicon local compilation only — no JCL, no VSAM, no
  mainframe deployment target (explicit non-goal).
- Fixed-format source is column-sensitive; both `.cob` and `.cpy` files
  must follow the same column rules, since `COPY` is textual substitution
  applied before the compiler does anything else with the source.
- Executables must be run from the repo root — every `SELECT ... ASSIGN
  TO` path is relative.

## Known architectural debt

- **No automated tests.** Verification is manual (hand arithmetic +
  byte-diffing checked-in sample output). Acceptable at current scale;
  would not scale past the "small hand-verifiable dataset" design choice
  above.
- **No CI.** Nothing currently runs `cobc` on push/PR to catch a broken
  compile automatically.
- **Stage 3 and Stage 4 are unstarted** — `payroll-v1.cob` still computes
  gross pay only, with no tax/net-pay logic. Stage 4 (indexed file +
  table lookup) is explicitly optional/stretch; go/no-go decision
  deferred until Stage 3 lands (see roadmap).
- **Fictional tax logic is a stated non-goal**, not a gap to close — do
  not treat the eventual Stage 3 tax brackets as needing real-world
  accuracy.

## Stage-by-stage plan

### Stage 1 — Single flat-file program ✅ done

One COBOL program. Reads a sequential file of employee records (hours
worked, hourly rate), computes gross pay, writes a sequential output file
(or report) with gross pay per employee.

Demonstrates:

- Four-division structure (IDENTIFICATION, ENVIRONMENT, DATA, PROCEDURE)
- PICTURE clauses for numeric and alphanumeric fields
- FD (File Description) and record layout
- SELECT/ASSIGN for file handling
- OPEN/READ/WRITE/CLOSE with AT END handling
- Basic arithmetic (COMPUTE, ADD)

**Deliverable**: `payroll-v1.cob`, sample input file, sample output,
README section explaining the divisions.

### Stage 2 — Extract a copybook ✅ done

Pull the employee record layout (FD/01-level structure) into a `.cpy` file.
COPY it into the Stage 1 program and into a new second program — a report
generator that reads the same file layout and produces a formatted summary
report (totals, headers, page breaks).

Demonstrates:

- Copybook pattern for shared data definitions
- COPY statement
- Multiple programs sharing one record layout (the actual reason copybooks
  exist in COBOL shops)

**Deliverable**: `employee-record.cpy`, updated `payroll-v1.cob`,
`payroll-report.cob`.

### Stage 3 — Called subprogram (not started)

Move tax calculation out of the main program into its own COBOL subprogram.
Main program CALLs it, passing gross pay in and receiving net pay
(and/or tax withheld) out via a parameter list.

Demonstrates:

- CALL ... USING
- LINKAGE SECTION in the subprogram
- Separation of business logic into distinct compilation units
- PROCEDURE DIVISION USING in the called program

**Deliverable**: `tax-calc.cob` (subprogram), updated main program,
documented calling convention.

### Stage 4 (optional/stretch) — Indexed file + table lookup (not started)

Convert the employee master file to indexed
(`ORGANIZATION IS INDEXED`, keyed by employee ID). Add a tax-bracket table
defined with OCCURS, populated at program start, looked up via SEARCH
(or SEARCH ALL) instead of hardcoded IF/ELSE tax logic.

Demonstrates:

- Indexed file organization (vs. sequential)
- OCCURS clause for table definitions
- SEARCH / SEARCH ALL
- START/random access READ by key

**Deliverable**: converted master file, updated tax-calc logic using table
lookup, migration notes (why indexed vs. sequential).

### Format decision

Fixed-format COBOL uses column-position rules (Area A/B, sequence numbers
in cols 1–6, indicator in col 7). GnuCOBOL also supports free format
(`-free` flag) — this project uses **fixed format** throughout for
authenticity and portfolio value.
