000100 IDENTIFICATION DIVISION.
000200 PROGRAM-ID. PAYROLL-INDEXED.
000300*
000400* M4 Stage 4: reads the INDEXED master file built by
000500* src/build-employee-index.cob (data/employees-indexed.dat)
000600* instead of the LINE SEQUENTIAL data/employees.dat Stages 1-3
000700* read. Demonstrates two access modes on the same file: a
000800* random READ by key (050-RANDOM-LOOKUP-DEMO, looking up one
000900* specific employee without scanning from the top) and a
001000* START + sequential READ NEXT pass (200-PROCESS-EMPLOYEE,
001100* same shape as Stage 3's report loop) that visits every
001200* record in key order to build the report. CALLs the same
001300* TAX-CALC subprogram as Stage 3 - see src/tax-calc.cob for its
001400* M4 change (OCCURS table + SEARCH replacing hardcoded
001500* IF/ELSE). Writes data/payroll-indexed-report.out.
001600*
      * This program assumes the fixed-format orientation, PICTURE
      * vocabulary, COPY mechanism, and CALL ... USING pattern already
      * covered in src/payroll-v1.cob, src/payroll-report.cob, and
      * src/payroll-net.cob's comments - read those first if
      * unfamiliar. Comments here focus on what's new in Stage 4:
      * ORGANIZATION IS INDEXED, RECORD KEY, START, and random vs.
      * sequential READ.
001700 ENVIRONMENT DIVISION.
001800 INPUT-OUTPUT SECTION.
001900 FILE-CONTROL.
      * ACCESS MODE IS DYNAMIC lets one program mix both READ styles
      * on the same file: a keyed random READ (050-RANDOM-LOOKUP-DEMO)
      * and START + sequential READ NEXT (000-MAIN's report loop).
      * ACCESS MODE IS RANDOM would allow only the former, SEQUENTIAL
      * only the latter.
002000     SELECT EMPLOYEE-INDEXED-FILE
002050         ASSIGN TO "data/employees-indexed.dat"
002100         ORGANIZATION IS INDEXED
002200         ACCESS MODE IS DYNAMIC
002300         RECORD KEY IS EMP-ID.
002400     SELECT REPORT-FILE
002450         ASSIGN TO "data/payroll-indexed-report.out"
002500         ORGANIZATION IS LINE SEQUENTIAL.
002600*
002700 DATA DIVISION.
002800 FILE SECTION.
      * Same COPY EMPLOYEE-RECORD as Stages 1-3 - EMP-ID here doubles
      * as both an ordinary field and, per RECORD KEY IS EMP-ID above,
      * this file's key: moving a value into EMP-ID and then doing a
      * keyed READ or START looks that value up in the on-disk index.
002900 FD EMPLOYEE-INDEXED-FILE.
003000     COPY EMPLOYEE-RECORD.
003100*
003200 FD REPORT-FILE.
003300 01 REPORT-LINE             PIC X(74).
003400*
003500 WORKING-STORAGE SECTION.
003600 01 WS-EOF-FLAG             PIC X VALUE "N".
003700     88 END-OF-FILE         VALUE "Y".
004000 01 WS-GROSS-PAY            PIC 9(5)V99.
004100 01 WS-TAX-AMOUNT           PIC 9(5)V99.
004200 01 WS-NET-PAY              PIC 9(5)V99.
004300*
004400 01 WS-TOTAL-GROSS          PIC 9(7)V99 VALUE ZERO.
004500 01 WS-TOTAL-TAX            PIC 9(7)V99 VALUE ZERO.
004600 01 WS-TOTAL-NET            PIC 9(7)V99 VALUE ZERO.
004700 01 WS-EMP-COUNT            PIC 9(3)    VALUE ZERO.
004800*
      * The employee ID looked up by 050-RANDOM-LOOKUP-DEMO before the
      * sequential pass starts - fixed here rather than taken from
      * input, since this project has no interactive ACCEPT precedent
      * (see src/payroll-v1.cob's Non-goals).
004900 01 WS-LOOKUP-ID             PIC 9(4) VALUE 1003.
005000*
005100* Report headings.
005200 01 WS-TITLE-LINE           PIC X(38)
005300     VALUE "PAYROLL REPORT - STAGE 4 (INDEXED)".
005400 01 WS-UNDER-LINE           PIC X(38)
005500     VALUE "======================================".
005600 01 WS-COL-HEADER.
005700     05 FILLER              PIC X(2)  VALUE SPACES.
005800     05 FILLER              PIC X(4)  VALUE "  ID".
005900     05 FILLER              PIC X(2)  VALUE SPACES.
006000     05 FILLER              PIC X(20) VALUE "NAME".
006100     05 FILLER              PIC X(2)  VALUE SPACES.
006200     05 FILLER              PIC X(6)  VALUE " HOURS".
006300     05 FILLER              PIC X(2)  VALUE SPACES.
006400     05 FILLER              PIC X(6)  VALUE "  RATE".
006500     05 FILLER              PIC X(2)  VALUE SPACES.
006600     05 FILLER              PIC X(8)  VALUE "   GROSS".
006700     05 FILLER              PIC X(2)  VALUE SPACES.
006800     05 FILLER              PIC X(8)  VALUE "     TAX".
006900     05 FILLER              PIC X(2)  VALUE SPACES.
007000     05 FILLER              PIC X(8)  VALUE "     NET".
007100*
007200 01 WS-DETAIL-LINE.
007300     05 FILLER              PIC X(2)  VALUE SPACES.
007400     05 WS-D-ID             PIC 9(4).
007500     05 FILLER              PIC X(2)  VALUE SPACES.
007600     05 WS-D-NAME           PIC X(20).
007700     05 FILLER              PIC X(2)  VALUE SPACES.
007800     05 WS-D-HOURS          PIC ZZ9.99.
007900     05 FILLER              PIC X(2)  VALUE SPACES.
008000     05 WS-D-RATE           PIC ZZ9.99.
008100     05 FILLER              PIC X(2)  VALUE SPACES.
008200     05 WS-D-GROSS          PIC Z,ZZ9.99.
008300     05 FILLER              PIC X(2)  VALUE SPACES.
008400     05 WS-D-TAX            PIC Z,ZZ9.99.
008500     05 FILLER              PIC X(2)  VALUE SPACES.
008600     05 WS-D-NET            PIC Z,ZZ9.99.
008700*
008800 01 WS-TOTAL-GROSS-LINE.
008900     05 FILLER              PIC X(2)  VALUE SPACES.
009000     05 FILLER              PIC X(19) VALUE "TOTAL GROSS PAY:".
009100     05 FILLER              PIC X(2)  VALUE SPACES.
009200     05 WS-T-GROSS          PIC ZZ,ZZ9.99.
009300*
009400 01 WS-TOTAL-TAX-LINE.
009500     05 FILLER              PIC X(2)  VALUE SPACES.
009600     05 FILLER              PIC X(19) VALUE "TOTAL TAX WITHHELD:".
009700     05 FILLER              PIC X(2)  VALUE SPACES.
009800     05 WS-T-TAX            PIC ZZ,ZZ9.99.
009900*
010000 01 WS-TOTAL-NET-LINE.
010100     05 FILLER              PIC X(2)  VALUE SPACES.
010200     05 FILLER              PIC X(19) VALUE "TOTAL NET PAY:".
010300     05 FILLER              PIC X(2)  VALUE SPACES.
010400     05 WS-T-NET            PIC ZZ,ZZ9.99.
010500*
010600 01 WS-COUNT-OUT-LINE.
010700     05 FILLER              PIC X(2)  VALUE SPACES.
010800     05 FILLER              PIC X(19) VALUE "EMPLOYEE COUNT:".
010900     05 FILLER              PIC X(2)  VALUE SPACES.
011000     05 WS-T-COUNT          PIC ZZ9.
011100*
      * Lookup-result line - written to the report so the random-
      * access demo's outcome is visible somewhere other than DISPLAY
      * (which goes to the terminal, not the report file).
011200 01 WS-LOOKUP-LINE.
011300     05 FILLER              PIC X(2)  VALUE SPACES.
011400     05 FILLER              PIC X(24)
011500         VALUE "RANDOM LOOKUP (ID 1003):".
011600     05 FILLER              PIC X(2)  VALUE SPACES.
011700     05 WS-L-NAME           PIC X(20).
011800     05 FILLER              PIC X(2)  VALUE SPACES.
011900     05 WS-L-GROSS          PIC Z,ZZ9.99.
012000*
012100 PROCEDURE DIVISION.
012200 000-MAIN.
012300     OPEN I-O    EMPLOYEE-INDEXED-FILE.
012400     OPEN OUTPUT REPORT-FILE.
012500     PERFORM 050-RANDOM-LOOKUP-DEMO.
012600     PERFORM 100-WRITE-HEADERS.
      * MOVE ZEROS then START ... NOT LESS THAN positions the file
      * just before its first record in key order, regardless of
      * where the random lookup above left the file's cursor - the
      * sequential pass below always starts from EMP-ID's lowest
      * possible value (ZEROS, since EMP-ID is numeric), not wherever
      * 050-RANDOM-LOOKUP-DEMO's keyed READ happened to land.
012700     MOVE ZEROS TO EMP-ID.
012800     START EMPLOYEE-INDEXED-FILE KEY IS NOT LESS THAN EMP-ID
012900         INVALID KEY SET END-OF-FILE TO TRUE
013000     END-START.
013100     IF NOT END-OF-FILE
013200         PERFORM 210-READ-NEXT
013300     END-IF.
013400     PERFORM 200-PROCESS-EMPLOYEE UNTIL END-OF-FILE.
013500     PERFORM 300-WRITE-TOTALS.
013600     CLOSE EMPLOYEE-INDEXED-FILE.
013700     CLOSE REPORT-FILE.
013800     STOP RUN.
013900*
      * Random access: move the key value straight into EMP-ID and
      * READ ... KEY IS jumps directly to that record via the on-disk
      * index - no scanning past 1001/1002 to reach 1003. INVALID KEY
      * fires instead of AT END when the key isn't found, since this
      * is a keyed lookup rather than a sequential traversal.
014000 050-RANDOM-LOOKUP-DEMO.
014100     MOVE WS-LOOKUP-ID TO EMP-ID.
014200     READ EMPLOYEE-INDEXED-FILE KEY IS EMP-ID
014300         INVALID KEY
014400             DISPLAY "Employee " WS-LOOKUP-ID " not found."
014500             MOVE "(not found)"     TO WS-L-NAME
014600             MOVE ZERO              TO WS-L-GROSS
014700         NOT INVALID KEY
014800             DISPLAY "Random lookup: " EMP-NAME
014900             MOVE EMP-NAME           TO WS-L-NAME
015000             COMPUTE WS-L-GROSS = EMP-HOURS * EMP-RATE
015100     END-READ.
015200*
015300 100-WRITE-HEADERS.
015400     WRITE REPORT-LINE FROM WS-TITLE-LINE.
015500     WRITE REPORT-LINE FROM WS-UNDER-LINE.
015600     WRITE REPORT-LINE FROM WS-LOOKUP-LINE.
015700     WRITE REPORT-LINE FROM WS-UNDER-LINE.
015800     WRITE REPORT-LINE FROM WS-COL-HEADER.
015900*
016000 200-PROCESS-EMPLOYEE.
016100     COMPUTE WS-GROSS-PAY = EMP-HOURS * EMP-RATE.
016200     CALL "TAX-CALC" USING WS-GROSS-PAY
016300                           WS-TAX-AMOUNT
016400                           WS-NET-PAY.
016500     ADD WS-GROSS-PAY  TO WS-TOTAL-GROSS.
016600     ADD WS-TAX-AMOUNT TO WS-TOTAL-TAX.
016700     ADD WS-NET-PAY    TO WS-TOTAL-NET.
016800     ADD 1 TO WS-EMP-COUNT.
016900     MOVE EMP-ID       TO WS-D-ID.
017000     MOVE EMP-NAME     TO WS-D-NAME.
017100     MOVE EMP-HOURS    TO WS-D-HOURS.
017200     MOVE EMP-RATE     TO WS-D-RATE.
017300     MOVE WS-GROSS-PAY TO WS-D-GROSS.
017400     MOVE WS-TAX-AMOUNT TO WS-D-TAX.
017500     MOVE WS-NET-PAY   TO WS-D-NET.
017600     WRITE REPORT-LINE FROM WS-DETAIL-LINE.
017700     PERFORM 210-READ-NEXT.
017800*
      * READ ... NEXT RECORD walks the file in ascending key order
      * from wherever the last START or READ NEXT left off - the
      * DYNAMIC access mode counterpart to Stage 1-3's plain
      * sequential READ on a LINE SEQUENTIAL file.
017900 210-READ-NEXT.
018000     READ EMPLOYEE-INDEXED-FILE NEXT RECORD
018100         AT END SET END-OF-FILE TO TRUE
018200     END-READ.
018300*
018400 300-WRITE-TOTALS.
018500     MOVE WS-UNDER-LINE   TO REPORT-LINE.
018600     WRITE REPORT-LINE.
018700     MOVE WS-TOTAL-GROSS  TO WS-T-GROSS.
018800     WRITE REPORT-LINE FROM WS-TOTAL-GROSS-LINE.
018900     MOVE WS-TOTAL-TAX    TO WS-T-TAX.
019000     WRITE REPORT-LINE FROM WS-TOTAL-TAX-LINE.
019100     MOVE WS-TOTAL-NET    TO WS-T-NET.
019200     WRITE REPORT-LINE FROM WS-TOTAL-NET-LINE.
019300     MOVE WS-EMP-COUNT    TO WS-T-COUNT.
019400     WRITE REPORT-LINE FROM WS-COUNT-OUT-LINE.
