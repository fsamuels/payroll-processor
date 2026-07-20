# Roadmap and milestones

**Current milestone: M3** (Stage 3 — called subprogram). M0–M2 are done.

| # | Milestone | Depends on | Exit criteria | Status |
|---|-----------|-----------|----------------|--------|
| M0 | Repo + toolchain setup | — | `cobc -xj` compiles a hello-world; committed to `main` | ✅ done |
| M1 | Stage 1 complete | M0 | payroll-v1 compiles, runs against sample data, output verified by hand | ✅ done |
| M2 | Stage 2 complete | M1 | copybook extracted, both programs compile and match Stage 1 output | ✅ done |
| M3 | Stage 3 complete | M2 | subprogram CALL works, net pay matches manual calculation | ⏳ next |
| M4 | Stage 4 (stretch) | M3 | indexed file + table lookup working, decide go/no-go before starting | not started |
| M5 | Documentation pass | M1–M4 | README covers each stage, what it demonstrates, how to run it | ongoing (kept current after each stage; see [current-status.md](current-status.md)) |

Stage details live in [architecture.md](architecture.md).

## Short-term goals (M3)

- Design the `CALL ... USING` parameter list between the main program and
  `tax-calc.cob` (gross pay in; net pay and/or tax withheld out).
- Write `tax-calc.cob` with a `LINKAGE SECTION` matching that contract.
- Decide fictional tax-bracket logic (simple, hand-verifiable — consistent
  with the project's non-goal of real tax accuracy).
- Wire the call into `payroll-v1.cob` (or a new Stage 3 driver program —
  TBD when Stage 3 work starts), verify net pay by hand.
- Document the calling convention in README/STAGE-NOTES, same pattern used
  for Stages 1–2.

## Medium-term goals (M4, stretch)

- After M3 lands: explicit go/no-go decision on Stage 4, since it's
  marked optional/stretch in the architecture plan.
- If go: convert `data/employees.dat` to `ORGANIZATION IS INDEXED` keyed
  by employee ID, add an `OCCURS`-based tax-bracket table, replace
  hardcoded tax IF/ELSE with `SEARCH`/`SEARCH ALL`.
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
- No CI compile-check on push/PR.

## Nice-to-have enhancements

- A CI workflow that runs `cobc -Wall` over all `.cob` sources on every
  PR, catching a broken compile before merge (currently done manually).
- A single `Makefile` or script wrapping the per-stage `cobc` invocations
  in the README, once there are enough stages that retyping full compile
  commands becomes tedious.
