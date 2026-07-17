# Project Spec: COBOL Payroll Processor

## Purpose

Exploratory portfolio project to gain hands-on exposure to COBOL. Not intended
to produce deep language mastery — intended to produce a working,
multi-stage codebase that demonstrates core COBOL idioms: fixed-format
divisions, PICTURE clauses, file I/O, copybooks, subprogram linkage, and
table processing.

Secondary goal: exercise agentic development workflow (spec → docs →
implementation) as practice for EM candidacy, consistent with existing
project patterns (Chore Corral, Durak Tracker).

## Non-goals

- Production-grade payroll accuracy (tax logic can be simplified/fictional)
- Full COBOL-85/2002/2014 feature coverage
- Performance optimization
- Mainframe deployment (JCL, VSAM) — GnuCOBOL/local only

## Toolchain

- **Compiler**: GnuCOBOL, installed via `brew install gnucobol` (formula
  renamed from `gnu-cobol` — use `gnucobol`)
- **Platform**: macOS (M1 Pro), local compilation and execution
- **Editor**: VS Code (or preferred), no COBOL-specific IDE required
- **Version control**: Git, feature branches + PR + squash merge (existing
  convention)

## Domain

A small company's payroll system. Fictional employee data. Weekly or
biweekly pay period. Simplified tax brackets (does not need to match real
tax law).

## Architecture: staged build

Each stage is a complete, independently runnable artifact. Do not proceed to
the next stage until the current stage compiles and produces correct output
against test data. Each stage should be its own PR.

### Stage 1 — Single flat-file program

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

### Stage 2 — Extract a copybook

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

### Stage 3 — Called subprogram

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

### Stage 4 (optional/stretch) — Indexed file + table lookup

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

## Milestones

| # | Milestone | Depends on | Exit criteria |
|---|-----------|-----------|----------------|
| M0 | Repo + toolchain setup | — | `cobc -xj` compiles a hello-world; committed to `main` |
| M1 | Stage 1 complete | M0 | payroll-v1 compiles, runs against sample data, output verified by hand |
| M2 | Stage 2 complete | M1 | copybook extracted, both programs compile and match Stage 1 output |
| M3 | Stage 3 complete | M2 | subprogram CALL works, net pay matches manual calculation |
| M4 | Stage 4 (stretch) | M3 | indexed file + table lookup working, decide go/no-go before starting |
| M5 | Documentation pass | M1–M4 | README covers each stage, what it demonstrates, how to run it |

## Repo structure (proposed)

```
/src
  payroll-v1.cob
  payroll-report.cob
  tax-calc.cob
/copybooks
  employee-record.cpy
/data
  employees-sample.dat
/docs
  README.md
  STAGE-NOTES.md   (what each stage demonstrates, gotchas hit)
.gitignore          (compiled binaries: *.o, executables with no extension or matching cobc output)
```

## Setup instructions (for the implementing agent)

```bash
brew install gnucobol
cobc --version   # confirm install
```

Compile a program (executable):
```bash
cobc -x -o payroll-v1 payroll-v1.cob
./payroll-v1
```

Compile with COPY resolution (copybooks in a separate dir):
```bash
cobc -x -I copybooks -o payroll-v1 src/payroll-v1.cob
```

Compile a subprogram (module, not standalone executable):
```bash
cobc -m tax-calc.cob
```

## Notes for downstream agent

- Fixed-format COBOL uses column-position rules (Area A/B, sequence
  numbers in cols 1–6, indicator in col 7). GnuCOBOL also supports free
  format (`-free` flag) — decide once and stay consistent; fixed-format is
  more "authentic" for portfolio purposes and worth doing at least once.
- Keep test data small and hand-verifiable (3–5 employees) so output can be
  checked by manual arithmetic rather than trusted blindly.
- Each stage's PR description should note what COBOL feature it
  demonstrates — this doubles as portfolio material per existing practice.
