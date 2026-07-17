# Roadmap and milestones

| # | Milestone | Depends on | Exit criteria |
|---|-----------|-----------|----------------|
| M0 | Repo + toolchain setup | — | `cobc -xj` compiles a hello-world; committed to `main` |
| M1 | Stage 1 complete | M0 | payroll-v1 compiles, runs against sample data, output verified by hand |
| M2 | Stage 2 complete | M1 | copybook extracted, both programs compile and match Stage 1 output |
| M3 | Stage 3 complete | M2 | subprogram CALL works, net pay matches manual calculation |
| M4 | Stage 4 (stretch) | M3 | indexed file + table lookup working, decide go/no-go before starting |
| M5 | Documentation pass | M1–M4 | README covers each stage, what it demonstrates, how to run it |

Stage details live in [architecture.md](architecture.md).
