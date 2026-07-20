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

## Key features

- **Stage 1 — `payroll-v1.cob`**: single flat-file program. Reads a
  fixed-width employee file, computes gross pay (hours × rate), writes a
  formatted report with per-employee detail, a total, and a count.
- **Stage 2 — `payroll-report.cob`**: a second, independent program that
  shares the Stage 1 record layout via a copybook (`copybooks/`) and
  produces a paginated summary report (repeating headers, page breaks via
  `WRITE ... AFTER ADVANCING PAGE`, grand totals).
- **Stage 3 (planned)** — tax calculation split into a called subprogram
  (`CALL ... USING`, `LINKAGE SECTION`).
- **Stage 4 (stretch, planned)** — indexed employee file + `OCCURS`/`SEARCH`
  tax-bracket table lookup.

See [docs/roadmap.md](docs/roadmap.md) for milestone status and
[docs/architecture.md](docs/architecture.md) for what each stage
demonstrates.

## Technology stack

| Layer | Choice |
|-------|--------|
| Language | COBOL (fixed-format, GnuCOBOL dialect) |
| Compiler | [GnuCOBOL](https://gnucobol.sourceforge.io/) 3.2.0 (`brew install gnucobol`) |
| Platform | macOS (Apple Silicon), local compile + run — no server/cloud component |
| Editor | VS Code (no COBOL-specific IDE required) |
| Version control | Git — feature branches + PR + squash merge |

## Local development setup

```bash
brew install gnucobol
cobc --version   # confirm install; this project was built against 3.2.0
```

No other dependencies, package manager, or config files are required.

## Build/run instructions

Always compile and run from the **repo root** — every program's
`SELECT ... ASSIGN TO` uses a relative path (`data/...`) that only
resolves correctly from there.

Programs that `COPY` a copybook (anything under `copybooks/`) need
`-I copybooks` so `cobc` can resolve the copybook name:

```bash
# Stage 1
cobc -x -I copybooks -o payroll-v1     src/payroll-v1.cob
./payroll-v1

# Stage 2
cobc -x -I copybooks -o payroll-report src/payroll-report.cob
./payroll-report
```

Other `cobc` invocations used in this project:

```bash
# Compile and run in one step (used for the M0 toolchain check)
cobc -xj src/hello.cob

# Compile a subprogram module (not a standalone executable) — for
# Stage 3's tax-calc.cob once it exists; not yet implemented
cobc -m src/tax-calc.cob
```

Compiled executables have no file extension and are `.gitignore`d
(`payroll-v1`, `payroll-report`, `tax-calc`, `hello`) — they're build
artifacts, not checked in.

## Testing instructions

There is no automated test suite; correctness is verified manually, by
design (see [docs/architecture.md](docs/architecture.md#design-decisions)):

1. **Hand arithmetic.** Test data (`data/employees.dat`) stays small
   (currently 4 employees) so the expected gross pay, running totals, and
   employee count can be checked by hand against the program's output.
   Current known-good total: `1,000.00 + 1,159.00 + 832.50 + 880.00 =
   3,871.50`.
2. **Byte-diff after refactors.** When a change is meant to be
   behavior-preserving (e.g. Stage 2 extracting the copybook out of
   `payroll-v1.cob`), the `.out` file is diffed byte-for-byte against the
   pre-change output to confirm nothing observable changed.
3. **Compiler warnings as a signal.** Every program compiles with `-Wall`
   and is expected to produce zero warnings.

Sample outputs are checked into `data/` (`payroll-report.out`,
`payroll-summary.out`) as the current known-good baseline.

## Important configuration

- No environment variables, secrets, or config files — the only inputs are
  the `.cob`/`.cpy` source and the sample data under `data/`.
- Fixed-format COBOL source is column-sensitive: sequence numbers in
  columns 1–6, indicator (`*` for comment) in column 7, Area A in columns
  8–11, Area B in columns 12+. Getting a statement into the wrong column
  is a compile error, not a warning.
- File `ASSIGN` paths are relative to the current working directory, not
  the source file — always run compiled executables from the repo root.

## Repository structure

```
/src         COBOL programs (.cob)
/copybooks   Shared record layouts (.cpy)
/data        Sample input files and checked-in sample output
/docs        Architecture, roadmap, current status, and per-stage notes
```

## Project docs

- [Architecture — staged build plan](docs/architecture.md)
- [Roadmap and milestones](docs/roadmap.md)
- [Current status](docs/current-status.md) — what's done, in progress, and next
- [Stage notes](docs/STAGE-NOTES.md) — what each stage demonstrates, gotchas hit

## Conventions

- Fixed-format COBOL (column rules: sequence numbers in cols 1–6, indicator
  in col 7, Area A/B) — chosen over free format for authenticity.
- Test data stays small and hand-verifiable (3–5 employees) so output can be
  checked by manual arithmetic.
- Each stage is its own PR; the PR description notes which COBOL features
  the stage demonstrates.
