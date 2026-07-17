000100 IDENTIFICATION DIVISION.
000200 PROGRAM-ID. HELLO.
000300*
000400* M0 toolchain check: verifies GnuCOBOL compiles and runs a
000500* fixed-format program. Compile and run with: cobc -xj src/hello.cob
000600*
000700 PROCEDURE DIVISION.
000800     DISPLAY "Hello from GnuCOBOL - payroll-processor M0".
000900     STOP RUN.
