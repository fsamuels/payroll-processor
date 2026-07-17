# Stage notes

What each stage demonstrates and gotchas hit along the way. Updated as each
stage lands.

## M0 — Repo + toolchain setup

- GnuCOBOL 3.2.0 installed via `brew install gnucobol` (pulls berkeley-db,
  gmp, json-c as dependencies). Installed cleanly on Apple Silicon.
- `src/hello.cob` is a minimal fixed-format program: sequence numbers in
  cols 1–6, `*` in col 7 for comments, division headers in Area A (col 8),
  statements in Area B (col 12+).
- `cobc -xj src/hello.cob` compiles and runs in one step. It leaves the
  compiled executable (`hello`, no extension) in the working directory —
  covered by `.gitignore`.
- Compiled with zero warnings; no format or dialect flags needed for
  fixed-format source, since fixed is GnuCOBOL's default.

## Stage 1 — Single flat-file program

_(not started)_

## Stage 2 — Extract a copybook

_(not started)_

## Stage 3 — Called subprogram

_(not started)_

## Stage 4 — Indexed file + table lookup (stretch)

_(not started)_
