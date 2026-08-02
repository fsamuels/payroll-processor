000100 IDENTIFICATION DIVISION.
000200 PROGRAM-ID. PAYROLL-NET.
000300*
000400* M3 Stage 3: net-pay report. Reads the same
000500* data/employees.dat file Stage 1/2 read (via the shared
000600* copybook, see copybooks/employee-record.cpy), computes gross
000700* pay exactly as payroll-v1.cob does, then CALLs the TAX-CALC
000800* subprogram (src/tax-calc.cob) to get tax withheld and net pay
000900* for each employee. Writes data/payroll-net-report.out: one
001000* line per employee (gross, tax, net) plus grand totals.
001100*
      * This program assumes the fixed-format orientation and
      * PICTURE-clause vocabulary already covered in
      * src/payroll-v1.cob's comments, and the COPY mechanism covered
      * in src/payroll-report.cob's - read those first if unfamiliar.
      * Comments here focus on what's new in Stage 3: CALL ... USING
      * a subprogram. See src/tax-calc.cob for the LINKAGE SECTION
      * side of this same contract.
001200 ENVIRONMENT DIVISION.
001300 INPUT-OUTPUT SECTION.
001400 FILE-CONTROL.
001500     SELECT EMPLOYEE-FILE ASSIGN TO "data/employees.dat"
001600         ORGANIZATION IS LINE SEQUENTIAL.
001700     SELECT REPORT-FILE   ASSIGN TO "data/payroll-net-report.out"
001800         ORGANIZATION IS LINE SEQUENTIAL.
001900*
002000 DATA DIVISION.
002100 FILE SECTION.
      * Same COPY EMPLOYEE-RECORD as payroll-v1.cob and
      * payroll-report.cob - all three programs stay guaranteed in
      * sync on the input file layout. Compiling this file needs
      * `-I copybooks` on the cobc command line.
002200 FD EMPLOYEE-FILE.
002300     COPY EMPLOYEE-RECORD.
002400*
      * REPORT-FILE's record is a flat PIC X(74) buffer - wider than
      * Stage 1/2's PIC X(54) because this report adds TAX and NET
      * columns; see WS-DETAIL-LINE below for the exact 74-byte
      * layout every WRITE ... FROM line in this program fills.
002500 FD REPORT-FILE.
002600 01 REPORT-LINE             PIC X(74).
002700*
002800 WORKING-STORAGE SECTION.
002900 01 WS-EOF-FLAG             PIC X VALUE "N".
003000     88 END-OF-FILE         VALUE "Y".
003100*
      * WS-GROSS-PAY, WS-TAX-AMOUNT and WS-NET-PAY are the actual
      * arguments passed on the CALL below - their PICTURE clauses
      * must match LS-GROSS-PAY/LS-TAX-AMOUNT/LS-NET-PAY in
      * tax-calc.cob exactly, since COBOL CALL links parameters
      * positionally by matching storage layout, not by name.
003200 01 WS-GROSS-PAY            PIC 9(5)V99.
003300 01 WS-TAX-AMOUNT           PIC 9(5)V99.
003400 01 WS-NET-PAY              PIC 9(5)V99.
003500*
003600 01 WS-TOTAL-GROSS          PIC 9(7)V99 VALUE ZERO.
003700 01 WS-TOTAL-TAX            PIC 9(7)V99 VALUE ZERO.
003800 01 WS-TOTAL-NET            PIC 9(7)V99 VALUE ZERO.
003900 01 WS-EMP-COUNT            PIC 9(3)    VALUE ZERO.
004000*
004100* Report headings.
004200 01 WS-TITLE-LINE           PIC X(35)
004300     VALUE "PAYROLL REPORT - STAGE 3 (NET PAY)".
004400 01 WS-UNDER-LINE           PIC X(35)
004500     VALUE "===================================".
      * Column widths below (2/4/2/20/2/6/2/6/2/8/2/8/2/8 = 74) match
      * WS-DETAIL-LINE field-for-field, same alternating FILLER/named
      * -field pattern as payroll-v1.cob's WS-COL-HEADER.
004600 01 WS-COL-HEADER.
004700     05 FILLER              PIC X(2)  VALUE SPACES.
004800     05 FILLER              PIC X(4)  VALUE "  ID".
004900     05 FILLER              PIC X(2)  VALUE SPACES.
005000     05 FILLER              PIC X(20) VALUE "NAME".
005100     05 FILLER              PIC X(2)  VALUE SPACES.
005200     05 FILLER              PIC X(6)  VALUE " HOURS".
005300     05 FILLER              PIC X(2)  VALUE SPACES.
005400     05 FILLER              PIC X(6)  VALUE "  RATE".
005500     05 FILLER              PIC X(2)  VALUE SPACES.
005600     05 FILLER              PIC X(8)  VALUE "   GROSS".
005700     05 FILLER              PIC X(2)  VALUE SPACES.
005800     05 FILLER              PIC X(8)  VALUE "     TAX".
005900     05 FILLER              PIC X(2)  VALUE SPACES.
006000     05 FILLER              PIC X(8)  VALUE "     NET".
006100*
      * Detail line - same ID/NAME/HOURS/RATE fields and edited
      * PICTUREs as payroll-v1.cob's WS-DETAIL-LINE, plus TAX and NET
      * columns fed by the subprogram CALL in 200-PROCESS-EMPLOYEE.
006200 01 WS-DETAIL-LINE.
006300     05 FILLER              PIC X(2)  VALUE SPACES.
006400     05 WS-D-ID             PIC 9(4).
006500     05 FILLER              PIC X(2)  VALUE SPACES.
006600     05 WS-D-NAME           PIC X(20).
006700     05 FILLER              PIC X(2)  VALUE SPACES.
006800     05 WS-D-HOURS          PIC ZZ9.99.
006900     05 FILLER              PIC X(2)  VALUE SPACES.
007000     05 WS-D-RATE           PIC ZZ9.99.
007100     05 FILLER              PIC X(2)  VALUE SPACES.
007200     05 WS-D-GROSS          PIC Z,ZZ9.99.
007300     05 FILLER              PIC X(2)  VALUE SPACES.
007400     05 WS-D-TAX            PIC Z,ZZ9.99.
007500     05 FILLER              PIC X(2)  VALUE SPACES.
007600     05 WS-D-NET            PIC Z,ZZ9.99.
007700*
      * One total line per accumulator, plus the employee count -
      * same FILLER-label / edited-total pattern as payroll-v1.cob's
      * WS-TOTAL-OUT-LINE, just one line per figure instead of one.
007800 01 WS-TOTAL-GROSS-LINE.
007900     05 FILLER              PIC X(2)  VALUE SPACES.
008000     05 FILLER              PIC X(19) VALUE "TOTAL GROSS PAY:".
008100     05 FILLER              PIC X(2)  VALUE SPACES.
008200     05 WS-T-GROSS          PIC ZZ,ZZ9.99.
008300*
008400 01 WS-TOTAL-TAX-LINE.
008500     05 FILLER              PIC X(2)  VALUE SPACES.
008600     05 FILLER              PIC X(19) VALUE "TOTAL TAX WITHHELD:".
008700     05 FILLER              PIC X(2)  VALUE SPACES.
008800     05 WS-T-TAX            PIC ZZ,ZZ9.99.
008900*
009000 01 WS-TOTAL-NET-LINE.
009100     05 FILLER              PIC X(2)  VALUE SPACES.
009200     05 FILLER              PIC X(19) VALUE "TOTAL NET PAY:".
009300     05 FILLER              PIC X(2)  VALUE SPACES.
009400     05 WS-T-NET            PIC ZZ,ZZ9.99.
009500*
009600 01 WS-COUNT-OUT-LINE.
009700     05 FILLER              PIC X(2)  VALUE SPACES.
009800     05 FILLER              PIC X(19) VALUE "EMPLOYEE COUNT:".
009900     05 FILLER              PIC X(2)  VALUE SPACES.
010000     05 WS-T-COUNT          PIC ZZ9.
010100*
010200 PROCEDURE DIVISION.
010300 000-MAIN.
010400     OPEN INPUT  EMPLOYEE-FILE.
010500     OPEN OUTPUT REPORT-FILE.
010600     PERFORM 100-WRITE-HEADERS.
010700     READ EMPLOYEE-FILE
010800         AT END SET END-OF-FILE TO TRUE
010900     END-READ.
011000     PERFORM 200-PROCESS-EMPLOYEE UNTIL END-OF-FILE.
011100     PERFORM 300-WRITE-TOTALS.
011200     CLOSE EMPLOYEE-FILE.
011300     CLOSE REPORT-FILE.
011400     STOP RUN.
011500*
011600 100-WRITE-HEADERS.
011700     WRITE REPORT-LINE FROM WS-TITLE-LINE.
011800     WRITE REPORT-LINE FROM WS-UNDER-LINE.
011900     WRITE REPORT-LINE FROM WS-COL-HEADER.
012000*
012100 200-PROCESS-EMPLOYEE.
012200     COMPUTE WS-GROSS-PAY = EMP-HOURS * EMP-RATE.
      * CALL ... USING hands control (and these three
      * WORKING-STORAGE items, by reference) to TAX-CALC's
      * PROCEDURE DIVISION USING - see src/tax-calc.cob. WS-GROSS-PAY
      * is read there; WS-TAX-AMOUNT and WS-NET-PAY come back filled
      * in once TAX-CALC reaches GOBACK, same as any other
      * subroutine-style call/return.
012300     CALL "TAX-CALC" USING WS-GROSS-PAY
012400                           WS-TAX-AMOUNT
012500                           WS-NET-PAY.
012600     ADD WS-GROSS-PAY  TO WS-TOTAL-GROSS.
012700     ADD WS-TAX-AMOUNT TO WS-TOTAL-TAX.
012800     ADD WS-NET-PAY    TO WS-TOTAL-NET.
012900     ADD 1 TO WS-EMP-COUNT.
013000     MOVE EMP-ID       TO WS-D-ID.
013100     MOVE EMP-NAME     TO WS-D-NAME.
013200     MOVE EMP-HOURS    TO WS-D-HOURS.
013300     MOVE EMP-RATE     TO WS-D-RATE.
013400     MOVE WS-GROSS-PAY TO WS-D-GROSS.
013500     MOVE WS-TAX-AMOUNT TO WS-D-TAX.
013600     MOVE WS-NET-PAY   TO WS-D-NET.
013700     WRITE REPORT-LINE FROM WS-DETAIL-LINE.
013800     READ EMPLOYEE-FILE
013900         AT END SET END-OF-FILE TO TRUE
014000     END-READ.
014100*
014200 300-WRITE-TOTALS.
014300     MOVE WS-UNDER-LINE   TO REPORT-LINE.
014400     WRITE REPORT-LINE.
014500     MOVE WS-TOTAL-GROSS  TO WS-T-GROSS.
014600     WRITE REPORT-LINE FROM WS-TOTAL-GROSS-LINE.
014700     MOVE WS-TOTAL-TAX    TO WS-T-TAX.
014800     WRITE REPORT-LINE FROM WS-TOTAL-TAX-LINE.
014900     MOVE WS-TOTAL-NET    TO WS-T-NET.
015000     WRITE REPORT-LINE FROM WS-TOTAL-NET-LINE.
015100     MOVE WS-EMP-COUNT    TO WS-T-COUNT.
015200     WRITE REPORT-LINE FROM WS-COUNT-OUT-LINE.
