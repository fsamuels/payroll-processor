# Roadmap and milestones

**Current milestone: M5** (documentation pass — ongoing, see status below).
M0–M4 are done; M4's go/no-go was decided "go" and Stage 4 has landed.

| # | Milestone | Depends on | Exit criteria | Status |
|---|-----------|-----------|----------------|--------|
| M0 | Repo + toolchain setup | — | `cobc -xj` compiles a hello-world; committed to `main` | ✅ done |
| M1 | Stage 1 complete | M0 | payroll-v1 compiles, runs against sample data, output verified by hand | ✅ done |
| M2 | Stage 2 complete | M1 | copybook extracted, both programs compile and match Stage 1 output | ✅ done |
| M3 | Stage 3 complete | M2 | subprogram CALL works, net pay matches manual calculation | ✅ done |
| M4 | Stage 4 (stretch) | M3 | indexed file + table lookup working, decide go/no-go before starting | ✅ done |
| M5 | Documentation pass | M1–M4 | README covers each stage, what it demonstrates, how to run it | ongoing (kept current after each stage; see [current-status.md](current-status.md)) |

Stage details live in [architecture.md](architecture.md).

## Recently completed (M4)

- Decided "go" on Stage 4 (see M3's note below) and implemented both
  parts of the stretch scope in one pass.
- Added `src/build-employee-index.cob`, a one-time conversion utility that
  reads `data/employees.dat` and writes `data/employees-indexed.dat`
  (`ORGANIZATION IS INDEXED`, keyed by `EMP-ID`) — a generated binary
  artifact, `.gitignore`d rather than checked in (see
  [architecture.md](architecture.md#design-decisions)).
- Added `src/payroll-indexed.cob`, a new Stage 4 driver demonstrating both
  a random `READ ... KEY IS` lookup and a `START` + sequential `READ NEXT`
  pass over the same indexed file, `CALL`ing the same `tax-calc.cob`
  subprogram Stage 3 uses.
- Replaced `tax-calc.cob`'s hardcoded `IF`/`ELSE` tax brackets with an
  `OCCURS` table walked by `SEARCH` — same thresholds/rates, verified
  byte-identical output against Stage 3's `payroll-net-report.out` before
  and after. Caught and fixed a bug during that verification (`TB-IDX` not
  reset between employees — see
  [STAGE-NOTES.md](STAGE-NOTES.md#stage-4--indexed-file--table-lookup)).

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

## Long-term goals

- Keep all four project docs (README, architecture, roadmap,
  current-status) current after every stage lands, not just at a single
  M5 documentation pass — the milestone table above already reflects this
  by marking M5 "ongoing."
- All four stages from the original architecture plan are now done. No
  further stretch stages are currently planned; consider the project
  feature-complete as scoped unless a new idiom to demonstrate comes up.

## Technical debt items

- No automated test suite (see architecture.md's Known architectural
  debt) — acceptable at current scale, revisit if test data ever grows
  beyond hand-verifiable size.
- `data/employees-indexed.dat` (Stage 4's indexed master) is generated
  locally, not checked in — anyone cloning the repo must run
  `./build-employee-index` once before `payroll-indexed` will find its
  input file. Documented in README's build/run instructions; a `make`
  target (see nice-to-haves below) could fold this into one step.
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
