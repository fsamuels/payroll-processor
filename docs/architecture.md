# Architecture: staged build

Each stage is a complete, independently runnable artifact. Do not proceed to
the next stage until the current stage compiles and produces correct output
against test data. Each stage is its own PR.

## Stage 1 — Single flat-file program

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

## Stage 2 — Extract a copybook

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

## Stage 3 — Called subprogram

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

## Stage 4 (optional/stretch) — Indexed file + table lookup

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

## Format decision

Fixed-format COBOL uses column-position rules (Area A/B, sequence numbers
in cols 1–6, indicator in col 7). GnuCOBOL also supports free format
(`-free` flag) — this project uses **fixed format** throughout for
authenticity and portfolio value.
