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
| `src/tax-calc.cob` | Stage 3 subprogram: gross pay in, tax withheld and net pay out via `CALL ... USING` / `LINKAGE SECTION`. Three fictional tax brackets. No `FILE SECTION` of its own — its only I/O is the parameter list. Stage 4 replaced the original hardcoded `IF`/`ELSE` bracket logic with an `OCCURS` table walked by `SEARCH`, same brackets, byte-identical output — see below. |
| `src/payroll-net.cob` | Stage 3 driver. Reads `data/employees.dat`, computes gross pay same as `payroll-v1.cob`, `CALL`s `tax-calc.cob` per employee, writes `data/payroll-net-report.out` (gross/tax/net detail lines plus grand totals). Independent executable, compiled together with `tax-calc.cob` into one binary (`cobc -x ... payroll-net.cob tax-calc.cob`). |
| `data/employees.dat` | Sample/test employee master file — fixed-width, currently 4 hand-written records. `LINE SEQUENTIAL`; unchanged since Stage 1, still read by Stages 1–3. |
| `src/build-employee-index.cob` | Stage 4 one-time conversion utility. Reads `data/employees.dat` and writes `data/employees-indexed.dat`, an `ORGANIZATION IS INDEXED` file keyed by `EMP-ID`. Generated binary artifact, not checked in (`.gitignore`d) — rerun whenever `data/employees.dat` changes. |
| `src/payroll-indexed.cob` | Stage 4 driver. Reads `data/employees-indexed.dat` (`ACCESS MODE IS DYNAMIC`): a random `READ ... KEY IS` lookup for one employee, then a `START` + sequential `READ NEXT` pass over all records. `CALL`s the same `tax-calc.cob` subprogram as Stage 3, writes `data/payroll-indexed-report.out`. Independent executable, compiled together with `tax-calc.cob`. |

## Data flow

```
data/employees.dat  (fixed-width sequential file)
        │
        ├─▶ payroll-v1.cob      ──▶ data/payroll-report.out      (Stage 1: flat report)
        │
        ├─▶ payroll-report.cob ──▶ data/payroll-summary.out     (Stage 2: paginated report)
        │
        ├─▶ payroll-net.cob    ──▶ data/payroll-net-report.out  (Stage 3: gross/tax/net report)
        │        ▲                       │
        │        │                       └─▶ CALL "TAX-CALC" (in-process,
        │        │                            same executable — see below)
        │        └── COPY EMPLOYEE-RECORD.  (copybooks/employee-record.cpy,
        │             also COPYd into payroll-v1.cob and payroll-report.cob)
        │
        └─▶ build-employee-index.cob ──▶ data/employees-indexed.dat (indexed master)
                                                  │
                                                  └─▶ payroll-indexed.cob ──▶ data/payroll-indexed-report.out
                                                           │                  (Stage 4: gross/tax/net report,
                                                           └─▶ CALL "TAX-CALC"  keyed random + sequential read)
```

All programs open their input file read-only, loop record-by-record with a
priming read + `PERFORM UNTIL` end-of-file (Stage 4 additionally does one
keyed random read before that loop), and open their own `REPORT-FILE`
write-only/output. There is no shared runtime state between them — the only
thing shared at compile time is the copybook text (and, for Stages 3–4, the
`tax-calc.cob` source file linked into each driver's executable).

`payroll-net.cob` `CALL`s `tax-calc.cob` once per employee, passing gross
pay in and receiving tax withheld and net pay back via `LINKAGE SECTION`
parameters (`WS-GROSS-PAY`/`WS-TAX-AMOUNT`/`WS-NET-PAY` in the caller,
matching `LS-GROSS-PAY`/`LS-TAX-AMOUNT`/`LS-NET-PAY` in the subprogram).
Both programs are compiled together in one `cobc -x` invocation
(`src/payroll-net.cob src/tax-calc.cob`), which statically links the CALL
target into a single executable — no dynamically-loaded `.so` module and
no separate `tax-calc` binary.

`payroll-indexed.cob` (Stage 4) `CALL`s the same `tax-calc.cob`, compiled
together the same way (`src/payroll-indexed.cob src/tax-calc.cob`). Only
`payroll-indexed.cob`'s input file organization differs from `payroll-net`'s
— indexed instead of sequential; the subprogram contract is unchanged.
`src/build-employee-index.cob` is a separate, standalone utility (its own
`cobc -x` invocation, no `CALL`) that reads `data/employees.dat` and writes
`data/employees-indexed.dat` — it has to run once, ahead of
`payroll-indexed`, to produce the indexed file `payroll-indexed` reads.

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
  Stages 1–3 — plain text, one record per line, easy to inspect with
  ordinary text tools. Stage 4 deliberately switches the master file to
  `INDEXED` to demonstrate the contrast; report output stays `LINE
  SEQUENTIAL` even in Stage 4, since the report is still meant to be
  read top-to-bottom, not looked up by key.
- **Indexed master file is generated, not checked in.** Unlike
  `data/employees.dat` (plain fixed-width text, hand-written and
  committed), `data/employees-indexed.dat` is a binary Berkeley DB btree
  file produced by `build-employee-index.cob` from that same source data.
  It's `.gitignore`d like a compiled executable and rebuilt locally rather
  than tracked — its exact on-disk format is GnuCOBOL-version- and
  platform-specific in a way plain text isn't.
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
- **Fictional tax logic is a stated non-goal**, not a gap to close — the
  three brackets in `tax-calc.cob` (10%/15%/20%, thresholds chosen to
  exercise all three against the existing 4-employee sample data) do not
  need real-world accuracy.
- **`COPY` copybook-name resolution is case-sensitive on Linux, matching
  the exact case of the `COPY` operand.** This project targets macOS
  (case-insensitive filesystem by default), where `COPY EMPLOYEE-RECORD.`
  resolving to `employee-record.cpy` has never been an issue. Discovered
  while verifying Stage 3 compiles on a Linux GnuCOBOL install — noted
  here since it would surface as a build failure if a Linux CI job (see
  roadmap's nice-to-haves) were ever added without accounting for it.

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

### Stage 3 — Called subprogram ✅ done

Tax calculation lives in its own COBOL subprogram, `tax-calc.cob`. A new
driver program, `payroll-net.cob`, CALLs it once per employee, passing
gross pay in and receiving tax withheld and net pay out via a parameter
list — a new, independent program rather than a modification of
`payroll-v1.cob`, consistent with this project's one-artifact-per-stage
approach (see Design decisions below).

Demonstrates:

- CALL ... USING
- LINKAGE SECTION in the subprogram
- Separation of business logic into distinct compilation units
- PROCEDURE DIVISION USING in the called program
- GOBACK (subprogram return) vs. STOP RUN (program termination)

**Deliverable**: `tax-calc.cob` (subprogram), `payroll-net.cob` (driver),
documented calling convention (see
[data-flow](#data-flow) above and STAGE-NOTES.md).

### Stage 4 — Indexed file + table lookup ✅ done

`build-employee-index.cob` converts the employee master file to indexed
(`ORGANIZATION IS INDEXED`, keyed by `EMP-ID`), writing
`data/employees-indexed.dat` from `data/employees.dat`. `tax-calc.cob`'s
hardcoded `IF`/`ELSE` tax brackets were replaced with an `OCCURS` table
(`TAX-BRACKET-TABLE`, 3 rows) walked by `SEARCH` — same thresholds and
rates as Stage 3, so `payroll-net`'s output is byte-identical before and
after. `payroll-indexed.cob`, a new driver, reads the indexed file with
`ACCESS MODE IS DYNAMIC`: one random `READ ... KEY IS` lookup (a specific
employee, by ID, without scanning from the top), then a `START` +
sequential `READ NEXT` pass that visits every record in key order to build
the same style of gross/tax/net report Stage 3 produces.

Demonstrates:

- Indexed file organization (vs. sequential)
- OCCURS clause for table definitions
- SEARCH (linear scan over an ordered-by-position table; SEARCH ALL was
  considered but doesn't fit — see STAGE-NOTES.md for why)
- START / random access READ by key, and READ NEXT for sequential access
  on the same file
- Migrating a subprogram's internal logic (IF/ELSE → table) without
  changing its external contract or output

**Deliverable**: `build-employee-index.cob` (conversion utility),
`payroll-indexed.cob` (driver), updated `tax-calc.cob` (table lookup),
migration notes (see [STAGE-NOTES.md](STAGE-NOTES.md#stage-4--indexed-file--table-lookup)).

### Format decision

Fixed-format COBOL uses column-position rules (Area A/B, sequence numbers
in cols 1–6, indicator in col 7). GnuCOBOL also supports free format
(`-free` flag) — this project uses **fixed format** throughout for
authenticity and portfolio value.
