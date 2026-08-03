# Roadmap and milestones

**Current milestone: M4** (Stage 4, stretch — go/no-go not yet decided).
M0–M3 are done.

| # | Milestone | Depends on | Exit criteria | Status |
|---|-----------|-----------|----------------|--------|
| M0 | Repo + toolchain setup | — | `cobc -xj` compiles a hello-world; committed to `main` | ✅ done |
| M1 | Stage 1 complete | M0 | payroll-v1 compiles, runs against sample data, output verified by hand | ✅ done |
| M2 | Stage 2 complete | M1 | copybook extracted, both programs compile and match Stage 1 output | ✅ done |
| M3 | Stage 3 complete | M2 | subprogram CALL works, net pay matches manual calculation | ✅ done |
| M4 | Stage 4 (stretch) | M3 | indexed file + table lookup working, decide go/no-go before starting | ⏳ next (go/no-go pending) |
| M5 | Documentation pass | M1–M4 | README covers each stage, what it demonstrates, how to run it | ongoing (kept current after each stage; see [current-status.md](current-status.md)) |

Stage details live in [architecture.md](architecture.md).

## Recently completed (M3)

- Designed the `CALL ... USING` parameter list between a new Stage 3 driver
  program and `tax-calc.cob`: gross pay in, tax withheld and net pay out,
  all `PIC 9(5)V99`, linked positionally (see
  [architecture.md](architecture.md#stage-3--called-subprogram--done)).
- Wrote `src/tax-calc.cob` with a `LINKAGE SECTION` matching that contract;
  three fictional, hand-verifiable tax brackets (10%/15%/20%), deliberately
  hardcoded `IF`/`ELSE` rather than a table — Stage 4 plans to replace this
  exact logic with `SEARCH`/`SEARCH ALL` over an `OCCURS` table, so the
  "before" picture needed to stay simple.
- Added `src/payroll-net.cob` as a new, independent Stage 3 driver program
  (rather than modifying `payroll-v1.cob`) — consistent with the project's
  one-artifact-per-stage approach and keeps Stage 1/2's byte-diff-verified
  output untouched.
- Verified net pay by hand for all 4 employees; documented the calling
  convention and a copybook case-sensitivity gotcha in README/STAGE-NOTES.

## Medium-term goals (M4, stretch)

- M3 has landed — explicit go/no-go decision on Stage 4 is the immediate
  next step, since it's marked optional/stretch in the architecture plan.
- If go: convert `data/employees.dat` to `ORGANIZATION IS INDEXED` keyed
  by employee ID, add an `OCCURS`-based tax-bracket table, replace
  `tax-calc.cob`'s hardcoded `IF`/`ELSE` tax brackets with
  `SEARCH`/`SEARCH ALL`.
- Migration notes explaining sequential-vs-indexed tradeoffs.

## Long-term goals

- Keep all four project docs (README, architecture, roadmap,
  current-status) current after every stage lands, not just at a single
  M5 documentation pass — the milestone table above already reflects this
  by marking M5 "ongoing."
- Once Stage 4's go/no-go is decided, consider whether the project is
  "done" as scoped, or whether further stretch stages (e.g. more COBOL
  idioms) are worth adding — no such stages are currently planned.

## Technical debt items

- No automated test suite (see architecture.md's Known architectural
  debt) — acceptable at current scale, revisit if test data ever grows
  beyond hand-verifiable size.
- No CI compile-check on push/PR. If one is ever added, note that GitHub
  Actions runners are Linux (case-sensitive filesystem) — see the `COPY`
  case-sensitivity gotcha in README/STAGE-NOTES, which this macOS-only
  project hasn't needed to work around so far.

## Nice-to-have enhancements

- A CI workflow that runs `cobc -Wall` over all `.cob` sources on every
  PR, catching a broken compile before merge (currently done manually).
- A single `Makefile` or script wrapping the per-stage `cobc` invocations
  in the README, once there are enough stages that retyping full compile
  commands becomes tedious.
