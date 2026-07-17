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
