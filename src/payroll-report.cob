000100 IDENTIFICATION DIVISION.
000200 PROGRAM-ID. PAYROLL-REPORT.
000300*
000400* M2 Stage 2: report generator sharing the employee record
000500* layout with payroll-v1.cob via a copybook (see
000600* copybooks/employee-record.cpy). Reads the same
000700* data/employees.dat file Stage 1 reads and produces a
000800* paginated summary report: a repeating page header, a capped
000900* number of detail lines per page, a page break (WRITE ...
001000* AFTER ADVANCING PAGE) whenever a page fills up, and grand
001100* totals at the very end.
001200*
      * This program assumes the fixed-format orientation and the
      * PICTURE-clause vocabulary (PIC 9/X/V, edited Z and comma,
      * the 88-level condition-name idiom, WRITE ... FROM, and the
      * priming-read PERFORM UNTIL loop) already covered in
      * src/payroll-v1.cob's comments - read that file first if any
      * of that is unfamiliar. Comments here focus on what's new in
      * Stage 2: COPY and paginated report output.
001300 ENVIRONMENT DIVISION.
001400 INPUT-OUTPUT SECTION.
001500 FILE-CONTROL.
001600     SELECT EMPLOYEE-FILE ASSIGN TO "data/employees.dat"
001700         ORGANIZATION IS LINE SEQUENTIAL.
001800     SELECT REPORT-FILE   ASSIGN TO "data/payroll-summary.out"
001900         ORGANIZATION IS LINE SEQUENTIAL.
002000*
002100 DATA DIVISION.
002200 FILE SECTION.
      * Same input file, same record shape, as payroll-v1.cob - but
      * instead of spelling out the 05-level fields again, COPY
      * pulls in the exact text of copybooks/employee-record.cpy at
      * compile time. This is the actual reason copybooks exist in
      * real COBOL shops: two independently-compiled programs
      * (payroll-v1.cob and this one) stay guaranteed in sync on the
      * file layout, because they both COPY the same source instead
      * of maintaining two hand-typed copies that could quietly
      * drift apart. Compiling this file needs `-I copybooks` on the
      * cobc command line so it can find employee-record.cpy.
002300 FD EMPLOYEE-FILE.
002400     COPY EMPLOYEE-RECORD.
002500*
      * REPORT-FILE's record, like Stage 1's, is one flat PIC X(54)
      * buffer - every formatted line (page header, column header,
      * detail, totals) is built in WORKING-STORAGE and WRITEn FROM
      * there; see payroll-v1.cob for why.
002600 FD REPORT-FILE.
002700 01 REPORT-LINE             PIC X(54).
002800*
002900 WORKING-STORAGE SECTION.
003000 01 WS-EOF-FLAG             PIC X VALUE "N".
003100     88 END-OF-FILE         VALUE "Y".
003200*
003300 01 WS-GROSS-PAY            PIC 9(5)V99.
003400 01 WS-TOTAL-GROSS          PIC 9(7)V99 VALUE ZERO.
003500 01 WS-EMP-COUNT            PIC 9(3)    VALUE ZERO.
003600*
      * Pagination bookkeeping - all new in Stage 2.
      *   WS-LINES-PER-PAGE  caps how many detail lines print before
      *                      starting a new page. It's set to 2 here
      *                      (a real report might use 40-60) purely
      *                      so the 4-employee sample data actually
      *                      exercises a page break without needing
      *                      a bigger test file - this project keeps
      *                      test data small and hand-verifiable
      *                      (see STAGE-NOTES.md).
      *   WS-LINE-COUNT      how many detail lines have printed on
      *                      the CURRENT page; resets to zero every
      *                      time a new page starts.
      *   WS-PAGE-NUM        the running page number shown in the
      *                      header, incremented after each header
      *                      is written.
      *   WS-FIRST-PAGE-FLAG distinguishes page 1 (already at the
      *   / FIRST-PAGE       top of a brand-new file, no page break
      *                      needed) from every later page (needs
      *                      WRITE ... AFTER ADVANCING PAGE) - see
      *                      100-WRITE-HEADERS below.
003700 01 WS-LINES-PER-PAGE       PIC 9(2) VALUE 2.
003800 01 WS-LINE-COUNT           PIC 9(2) VALUE ZERO.
003900 01 WS-PAGE-NUM             PIC 9(2) VALUE 1.
004000 01 WS-FIRST-PAGE-FLAG      PIC X    VALUE "Y".
004100     88 FIRST-PAGE          VALUE "Y".
004200     88 NOT-FIRST-PAGE      VALUE "N".
004300*
004400* Report headings - printed once per page (unlike Stage 1,
004500* where the whole report has a single title/header block).
      * WS-PAGE-HEADER combines literal FILLER text with WS-H-PAGE,
      * an edited numeric field, on one line - "PAYROLL SUMMARY
      * REPORT - STAGE 2 PAGE  1", then "... PAGE  2", etc. Moving
      * WS-PAGE-NUM into WS-H-PAGE right before each WRITE is what
      * puts the current page number into that line.
004600 01 WS-PAGE-HEADER.
004700     05 FILLER              PIC X(33)
004800         VALUE "PAYROLL SUMMARY REPORT - STAGE 2 ".
004900     05 FILLER              PIC X(5)  VALUE "PAGE ".
005000     05 WS-H-PAGE           PIC Z9.
005100 01 WS-UNDER-LINE           PIC X(24)
005200     VALUE "========================".
005300 01 WS-COL-HEADER.
005400     05 FILLER              PIC X(2)  VALUE SPACES.
005500     05 FILLER              PIC X(4)  VALUE "  ID".
005600     05 FILLER              PIC X(2)  VALUE SPACES.
005700     05 FILLER              PIC X(20) VALUE "NAME".
005800     05 FILLER              PIC X(2)  VALUE SPACES.
005900     05 FILLER              PIC X(6)  VALUE " HOURS".
006000     05 FILLER              PIC X(2)  VALUE SPACES.
006100     05 FILLER              PIC X(6)  VALUE "  RATE".
006200     05 FILLER              PIC X(2)  VALUE SPACES.
006300     05 FILLER              PIC X(8)  VALUE "   GROSS".
006400*
006500* Detail line - same shape as Stage 1's WS-DETAIL-LINE; see
006600* payroll-v1.cob for what the Z and comma editing characters do.
006700 01 WS-DETAIL-LINE.
006800     05 FILLER              PIC X(2)  VALUE SPACES.
006900     05 WS-D-ID             PIC 9(4).
007000     05 FILLER              PIC X(2)  VALUE SPACES.
007100     05 WS-D-NAME           PIC X(20).
007200     05 FILLER              PIC X(2)  VALUE SPACES.
007300     05 WS-D-HOURS          PIC ZZ9.99.
007400     05 FILLER              PIC X(2)  VALUE SPACES.
007500     05 WS-D-RATE           PIC ZZ9.99.
007600     05 FILLER              PIC X(2)  VALUE SPACES.
007700     05 WS-D-GROSS          PIC Z,ZZ9.99.
007800*
007900 01 WS-TOTAL-OUT-LINE.
008000     05 FILLER              PIC X(2)  VALUE SPACES.
008100     05 FILLER              PIC X(16) VALUE "TOTAL GROSS PAY:".
008200     05 FILLER              PIC X(2)  VALUE SPACES.
008300     05 WS-T-GROSS          PIC ZZ,ZZ9.99.
008400*
008500 01 WS-COUNT-OUT-LINE.
008600     05 FILLER              PIC X(2)  VALUE SPACES.
008700     05 FILLER              PIC X(16) VALUE "EMPLOYEE COUNT:".
008800     05 FILLER              PIC X(2)  VALUE SPACES.
008900     05 WS-T-COUNT          PIC ZZ9.
009000*
009100 PROCEDURE DIVISION.
009200 000-MAIN.
009300     OPEN INPUT  EMPLOYEE-FILE.
009400     OPEN OUTPUT REPORT-FILE.
009500     PERFORM 100-WRITE-HEADERS.
009600     READ EMPLOYEE-FILE
009700         AT END SET END-OF-FILE TO TRUE
009800     END-READ.
009900     PERFORM 200-PROCESS-EMPLOYEE UNTIL END-OF-FILE.
010000     PERFORM 300-WRITE-TOTALS.
010100     CLOSE EMPLOYEE-FILE.
010200     CLOSE REPORT-FILE.
010300     STOP RUN.
010400*
      * 100-WRITE-HEADERS runs once at the very start of the report
      * AND again every time 200-PROCESS-EMPLOYEE below decides the
      * current page is full - that's the entire page-break
      * mechanism in this program. COBOL has no separate "start a
      * new page" verb beyond WRITE ... AFTER ADVANCING PAGE.
010500 100-WRITE-HEADERS.
010600     MOVE WS-PAGE-NUM TO WS-H-PAGE.
      * AFTER ADVANCING PAGE inserts a form-feed control character
      * (hex 0C) into the output immediately before this line -
      * that's the actual mechanism paginated printed/spooled COBOL
      * reports have always used to eject to a new sheet. Open
      * data/payroll-summary.out in a hex viewer (or `od -c`) and
      * the \f shows up right before page 2's header line. Page 1
      * skips ADVANCING PAGE (plain WRITE) because it's already at
      * the top of a brand-new file - a leading form-feed before any
      * content would just be a stray control character with
      * nothing to page past.
010700     IF FIRST-PAGE
010800         WRITE REPORT-LINE FROM WS-PAGE-HEADER
010900         SET NOT-FIRST-PAGE TO TRUE
011000     ELSE
011100         WRITE REPORT-LINE FROM WS-PAGE-HEADER
011200             AFTER ADVANCING PAGE
011300     END-IF.
011400     WRITE REPORT-LINE FROM WS-UNDER-LINE.
011500     WRITE REPORT-LINE FROM WS-COL-HEADER.
011600     MOVE ZERO TO WS-LINE-COUNT.
011700     ADD 1 TO WS-PAGE-NUM.
011800*
011900 200-PROCESS-EMPLOYEE.
012000     COMPUTE WS-GROSS-PAY = EMP-HOURS * EMP-RATE.
012100     ADD WS-GROSS-PAY TO WS-TOTAL-GROSS.
012200     ADD 1 TO WS-EMP-COUNT.
012300     MOVE EMP-ID    TO WS-D-ID.
012400     MOVE EMP-NAME  TO WS-D-NAME.
012500     MOVE EMP-HOURS TO WS-D-HOURS.
012600     MOVE EMP-RATE  TO WS-D-RATE.
012700     MOVE WS-GROSS-PAY TO WS-D-GROSS.
012800     WRITE REPORT-LINE FROM WS-DETAIL-LINE.
012900     ADD 1 TO WS-LINE-COUNT.
013000     READ EMPLOYEE-FILE
013100         AT END SET END-OF-FILE TO TRUE
013200     END-READ.
      * The page-full check happens after the read-ahead and is
      * guarded by NOT END-OF-FILE, so the report never starts a
      * fresh page just to put nothing but totals on it - the last
      * page always carries at least one detail line before
      * 300-WRITE-TOTALS appends the grand totals below it.
013300     IF (WS-LINE-COUNT >= WS-LINES-PER-PAGE) AND (NOT END-OF-FILE)
013400         PERFORM 100-WRITE-HEADERS
013500     END-IF.
013600*
013700 300-WRITE-TOTALS.
      * Grand totals across ALL employees/pages, written once at the
      * end of the report (not per page) - same MOVE-then-WRITE
      * pattern as payroll-v1.cob's 300-WRITE-TOTALS.
013800     MOVE WS-UNDER-LINE   TO REPORT-LINE.
013900     WRITE REPORT-LINE.
014000     MOVE WS-TOTAL-GROSS  TO WS-T-GROSS.
014100     WRITE REPORT-LINE FROM WS-TOTAL-OUT-LINE.
014200     MOVE WS-EMP-COUNT    TO WS-T-COUNT.
014300     WRITE REPORT-LINE FROM WS-COUNT-OUT-LINE.
