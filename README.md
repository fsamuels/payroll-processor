# COBOL Payroll Processor

An exploratory portfolio project to gain hands-on exposure to COBOL using
[GnuCOBOL](https://gnucobol.sourceforge.io/) on macOS. The goal is a working,
multi-stage codebase that demonstrates core COBOL idioms: fixed-format
divisions, PICTURE clauses, file I/O, copybooks, subprogram linkage, and
table processing.

Secondary goal: exercise an agentic development workflow (spec → docs →
implementation).

## Domain

A small fictional company's payroll system. Weekly or biweekly pay period,
simplified/fictional tax brackets. **Not** production-grade payroll — tax
logic does not match real tax law.

## Non-goals

- Production-grade payroll accuracy
- Full COBOL-85/2002/2014 feature coverage
- Performance optimization
- Mainframe deployment (JCL, VSAM) — GnuCOBOL/local only

## Toolchain

| Tool | Choice |
|------|--------|
| Compiler | GnuCOBOL (`brew install gnucobol`) |
| Platform | macOS (Apple Silicon), local compile + run |
| Editor | VS Code (no COBOL-specific IDE required) |
| Version control | Git — feature branches + PR + squash merge |

## Setup

```bash
brew install gnucobol
cobc --version   # confirm install
```

## Building and running

Compile a program to an executable:

```bash
cobc -x -o payroll-v1 src/payroll-v1.cob
./payroll-v1
```

Compile with copybook resolution (copybooks live in `copybooks/`):

```bash
cobc -x -I copybooks -o payroll-v1 src/payroll-v1.cob
```

Compile a subprogram (module, not a standalone executable):

```bash
cobc -m src/tax-calc.cob
```

Compile and run in one step:

```bash
cobc -xj src/hello.cob
```

## Stage 1: payroll-v1

`src/payroll-v1.cob` reads a fixed-width employee file and writes a
formatted payroll report: one line per employee (ID, name, hours, rate,
gross pay), a total-gross line, and an employee-count line. Gross pay is
hours × rate; no overtime or tax logic yet (see later stages).

Build and run from the repo root, so the relative `ASSIGN` paths resolve:

```bash
cobc -x -o payroll-v1 src/payroll-v1.cob
./payroll-v1
```

Input: `data/employees.dat`. Output: `data/payroll-report.out`.

The program's four divisions:

- **IDENTIFICATION DIVISION** — just names the program (`PROGRAM-ID.
  PAYROLL-V1`).
- **ENVIRONMENT DIVISION** — `SELECT ... ASSIGN TO` maps the logical files
  `EMPLOYEE-FILE` and `REPORT-FILE` to their paths on disk.
- **DATA DIVISION** — `FILE SECTION` defines the record layouts (`FD` +
  `01`-level with `PICTURE` clauses for each field, e.g. `EMP-HOURS PIC
  9(3)V99`); `WORKING-STORAGE SECTION` holds accumulators (running gross
  total, employee count), the end-of-file flag, and the edited-picture
  report lines used for output formatting.
- **PROCEDURE DIVISION** — open both files, loop read → compute gross →
  accumulate → write detail line until end of file, then write the totals
  and close. Uses `COMPUTE` and `ADD` for the arithmetic.

## Repo structure

```
/src         COBOL programs (.cob)
/copybooks   Shared record layouts (.cpy)
/data        Sample input files
/docs        Architecture, roadmap, and per-stage notes
```

## Project docs

- [Architecture — staged build plan](docs/architecture.md)
- [Roadmap and milestones](docs/roadmap.md)
- [Stage notes](docs/STAGE-NOTES.md) — what each stage demonstrates, gotchas hit

## Conventions

- Fixed-format COBOL (column rules: sequence numbers in cols 1–6, indicator
  in col 7, Area A/B) — chosen over free format for authenticity.
- Test data stays small and hand-verifiable (3–5 employees) so output can be
  checked by manual arithmetic.
- Each stage is its own PR; the PR description notes which COBOL features
  the stage demonstrates.
