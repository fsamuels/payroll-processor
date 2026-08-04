000100 IDENTIFICATION DIVISION.
000200 PROGRAM-ID. BUILD-EMPLOYEE-INDEX.
000300*
000400* M4 Stage 4: one-time conversion utility. Reads the existing
000500* LINE SEQUENTIAL master file (data/employees.dat, unchanged
000600* since Stage 1) and writes an equivalent ORGANIZATION IS
000700* INDEXED file, data/employees-indexed.dat, keyed by EMP-ID.
000800* Run this once (or whenever data/employees.dat changes) before
000900* running src/payroll-indexed.cob - see README for the exact
001000* command.
001100*
      * This program needs the same EMPLOYEE-RECORD layout twice: once
      * for the LINE SEQUENTIAL source (read) and once for the
      * INDEXED destination (write), because a program can't attach
      * two FDs to the same data-name set. COPY ... REPLACING renames
      * every field in the second copy so both FDs coexist without a
      * naming collision, while still pulling the field widths from
      * the one shared copybook instead of retyping them.
001200 ENVIRONMENT DIVISION.
001300 INPUT-OUTPUT SECTION.
001400 FILE-CONTROL.
001500     SELECT EMPLOYEE-FILE ASSIGN TO "data/employees.dat"
001600         ORGANIZATION IS LINE SEQUENTIAL.
      * RECORD KEY IS names the field that makes this file INDEXED
      * instead of sequential - GnuCOBOL builds an on-disk key index
      * over IDX-EMP-ID so later programs can jump straight to a
      * record by key instead of reading from the top every time (see
      * src/payroll-indexed.cob's random-access lookup).
001700     SELECT EMPLOYEE-INDEXED-FILE
001750         ASSIGN TO "data/employees-indexed.dat"
001800         ORGANIZATION IS INDEXED
001900         ACCESS MODE IS SEQUENTIAL
002000         RECORD KEY IS IDX-EMP-ID.
002100*
002200 DATA DIVISION.
002300 FILE SECTION.
002400 FD EMPLOYEE-FILE.
002500     COPY EMPLOYEE-RECORD.
002600*
002700 FD EMPLOYEE-INDEXED-FILE.
002800     COPY EMPLOYEE-RECORD
002900         REPLACING EMPLOYEE-RECORD BY EMPLOYEE-INDEXED-RECORD
003000                   EMP-ID          BY IDX-EMP-ID
003100                   EMP-NAME        BY IDX-EMP-NAME
003200                   EMP-HOURS       BY IDX-EMP-HOURS
003300                   EMP-RATE        BY IDX-EMP-RATE.
003400*
003500 WORKING-STORAGE SECTION.
003600 01 WS-EOF-FLAG             PIC X VALUE "N".
003700     88 END-OF-FILE         VALUE "Y".
003800 01 WS-REC-COUNT            PIC 9(3) VALUE ZERO.
003900*
004000 PROCEDURE DIVISION.
004100 000-MAIN.
004200     OPEN INPUT  EMPLOYEE-FILE.
004300     OPEN OUTPUT EMPLOYEE-INDEXED-FILE.
004400     READ EMPLOYEE-FILE
004500         AT END SET END-OF-FILE TO TRUE
004600     END-READ.
004700     PERFORM 100-COPY-RECORD UNTIL END-OF-FILE.
004800     CLOSE EMPLOYEE-FILE.
004900     CLOSE EMPLOYEE-INDEXED-FILE.
005000     DISPLAY "Indexed file built: " WS-REC-COUNT " records.".
005100     STOP RUN.
005200*
005300 100-COPY-RECORD.
005400     MOVE EMP-ID       TO IDX-EMP-ID.
005500     MOVE EMP-NAME     TO IDX-EMP-NAME.
005600     MOVE EMP-HOURS    TO IDX-EMP-HOURS.
005700     MOVE EMP-RATE     TO IDX-EMP-RATE.
      * WRITE (not REWRITE) - EMPLOYEE-INDEXED-FILE was OPENed OUTPUT,
      * so every record is a new one; the on-disk key index is built
      * incrementally as each WRITE lands, keyed by IDX-EMP-ID.
005800     WRITE EMPLOYEE-INDEXED-RECORD.
005900     ADD 1 TO WS-REC-COUNT.
006000     READ EMPLOYEE-FILE
006100         AT END SET END-OF-FILE TO TRUE
006200     END-READ.
