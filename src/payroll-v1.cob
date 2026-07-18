000100 IDENTIFICATION DIVISION.
000200 PROGRAM-ID. PAYROLL-V1.
000300*
000400* M1 Stage 1: single flat-file payroll program.
000500* Reads a sequential fixed-width employee file, computes gross
000600* pay (gross = hours * rate; no overtime/tax in Stage 1), and
000700* writes a formatted report with one line per employee plus a
000800* total-gross line and an employee-count line.
000900*
      * NEW TO COBOL? A quick orientation on the source format used
      * throughout this file (this is "fixed-format" COBOL, the
      * traditional punch-card-derived layout GnuCOBOL defaults to):
      *   columns 1-6   sequence number area (historical; ignored by
      *                 the compiler, just a convention here)
      *   column 7      indicator area - '*' marks the whole line as
      *                 a comment, like these lines
      *   columns 8-11  "Area A" - DIVISION/SECTION headers, 01-level
      *                 (and 88-level) data items, paragraph names
      *   columns 12+   "Area B" - everything else: clauses,
      *                 statements, lower-level (03/05/...) data items
      *
      * A COBOL program is built from four DIVISIONs, always in this
      * order: IDENTIFICATION, ENVIRONMENT, DATA, PROCEDURE. Think of
      * them as answering: what is this program, what does it touch
      * on the outside world, what data does it hold, and what does
      * it do.
001000 ENVIRONMENT DIVISION.
      * ENVIRONMENT DIVISION connects the program to the outside
      * world - here, that means the two files it reads/writes.
      * INPUT-OUTPUT SECTION / FILE-CONTROL is where every file used
      * in the program gets a SELECT clause, once each.
001100 INPUT-OUTPUT SECTION.
001200 FILE-CONTROL.
      * SELECT gives the file a logical, in-program name
      * (EMPLOYEE-FILE) and ASSIGN TO maps it to a real path on disk.
      * ORGANIZATION IS LINE SEQUENTIAL means: this is a plain text
      * file, one record per line, delimited by newlines - as
      * opposed to RECORD SEQUENTIAL (fixed-length binary records,
      * no delimiters) or INDEXED (keyed access, needs a key field).
      * LINE SEQUENTIAL is the easiest to inspect by eye or with
      * ordinary text tools, which is why Stage 1 uses it for both
      * input and output.
001300     SELECT EMPLOYEE-FILE ASSIGN TO "data/employees.dat"
001400         ORGANIZATION IS LINE SEQUENTIAL.
001500     SELECT REPORT-FILE   ASSIGN TO "data/payroll-report.out"
001600         ORGANIZATION IS LINE SEQUENTIAL.
001700*
001800 DATA DIVISION.
      * DATA DIVISION declares every piece of storage the program
      * uses. It has (at least) two SECTIONs here:
      *   FILE SECTION       - the shape of records as they exist in
      *                        each file (one FD per SELECTed file)
      *   WORKING-STORAGE     - variables that live only in memory:
      *   SECTION              accumulators, flags, and the
      *                        formatted lines built for output
001900 FILE SECTION.
      * FD = File Description. It's followed by a single 01-level
      * record that lays out that file's record, byte by byte via
      * PICTURE ("PIC") clauses. This record layout IS the file
      * format on disk for a fixed-width file like this one - there
      * are no delimiters between EMP-ID, EMP-NAME, etc.; the
      * compiler knows where one field ends and the next begins
      * purely from the PIC widths below.
002000 FD EMPLOYEE-FILE.
002100 01 EMPLOYEE-RECORD.
      *     PIC 9    one numeric digit (0-9), unsigned
      *     PIC X    one alphanumeric character, any byte
      *     PIC V    an IMPLIED decimal point - lines up where the
      *              decimal belongs but takes up zero bytes on disk.
      *              EMP-HOURS PIC 9(3)V99 is 5 bytes wide, and
      *              40.00 hours is stored as the literal digits
      *              "04000", not "040.00". Get the zero-padding
      *              wrong and every field after it in the record
      *              shifts out of alignment.
002200     05 EMP-ID              PIC 9(4).
002300     05 EMP-NAME            PIC X(20).
002400     05 EMP-HOURS           PIC 9(3)V99.
002500     05 EMP-RATE            PIC 9(3)V99.
002600*
      * REPORT-FILE's record is declared as one flat, unstructured
      * PIC X(54) buffer, unlike EMPLOYEE-RECORD above. That's
      * because the report has several differently-shaped lines
      * (title, headers, per-employee detail, totals) - rather than
      * modeling each shape here in the FILE SECTION, this program
      * builds each formatted line as a WORKING-STORAGE record (see
      * below) and then WRITEs it FROM there into this generic
      * buffer. WRITE ... FROM does a MOVE-then-WRITE in one step.
002700 FD REPORT-FILE.
002800 01 REPORT-LINE             PIC X(54).
002900*
003000 WORKING-STORAGE SECTION.
      * WS-EOF-FLAG is a plain 1-byte flag, "N" until end-of-file.
      * The 88-level below it is a CONDITION NAME, not a data item -
      * it reserves no storage of its own. It's just a readable name
      * for "WS-EOF-FLAG equals a particular value". Declaring
      * 88 END-OF-FILE VALUE "Y" means the code can write
      * SET END-OF-FILE TO TRUE (sets WS-EOF-FLAG to "Y") and test
      * END-OF-FILE in an IF or PERFORM UNTIL, instead of spelling
      * out WS-EOF-FLAG = "Y" everywhere. This is the standard COBOL
      * idiom for loop-termination flags.
003100 01 WS-EOF-FLAG             PIC X VALUE "N".
003200     88 END-OF-FILE         VALUE "Y".
003300*
      * Working numeric accumulators. WS-GROSS-PAY holds one
      * employee's computed pay; WS-TOTAL-GROSS accumulates across
      * every employee, so it needs more headroom (7 integer digits
      * vs. 5) even though a single employee's gross never gets that
      * large. VALUE ZERO gives each an explicit starting value -
      * WORKING-STORAGE items are NOT automatically zeroed/blanked
      * by the runtime unless you say so.
003400 01 WS-GROSS-PAY            PIC 9(5)V99.
003500 01 WS-TOTAL-GROSS          PIC 9(7)V99 VALUE ZERO.
003600 01 WS-EMP-COUNT            PIC 9(3)    VALUE ZERO.
003700*
003800* Report headings.
      * These are the literal, unchanging lines written once at the
      * top of the report. WS-TITLE-LINE and WS-UNDER-LINE are
      * simple elementary items; WS-COL-HEADER below is a GROUP item
      * built entirely out of FILLER fields.
003900 01 WS-TITLE-LINE           PIC X(24)
004000     VALUE "PAYROLL REPORT - STAGE 1".
004100 01 WS-UNDER-LINE           PIC X(24)
004200     VALUE "========================".
      * FILLER is COBOL's name for "this field has no name because
      * nothing ever refers to it by name" - here it's used purely
      * as fixed spacing/label text between the columns that DO get
      * named and filled in per-employee (see WS-DETAIL-LINE below).
      * Grouping several 05-level FILLERs under one 01-level record
      * (WS-COL-HEADER) lets the whole thing be written in one
      * WRITE ... FROM statement even though no single field spans
      * the whole line.
004300 01 WS-COL-HEADER.
004400     05 FILLER              PIC X(2)  VALUE SPACES.
004500     05 FILLER              PIC X(4)  VALUE "  ID".
004600     05 FILLER              PIC X(2)  VALUE SPACES.
004700     05 FILLER              PIC X(20) VALUE "NAME".
004800     05 FILLER              PIC X(2)  VALUE SPACES.
004900     05 FILLER              PIC X(6)  VALUE " HOURS".
005000     05 FILLER              PIC X(2)  VALUE SPACES.
005100     05 FILLER              PIC X(6)  VALUE "  RATE".
005200     05 FILLER              PIC X(2)  VALUE SPACES.
005300     05 FILLER              PIC X(8)  VALUE "   GROSS".
005400*
005500* Detail line with edited (display) PICTUREs.
      * This is the per-employee output line: FILLER spacers
      * alternate with named fields that get MOVEd to fresh values
      * for every employee in 200-PROCESS-EMPLOYEE below.
      *
      * WS-D-HOURS, WS-D-RATE and WS-D-GROSS use EDITED PICTUREs -
      * different from the plain 9/X/V PICTUREs in EMPLOYEE-RECORD.
      * These exist purely for human-readable DISPLAY, never for
      * storage or arithmetic:
      *   Z   zero-suppression - a leading zero digit prints as a
      *       space instead, so 040.00 displays as " 40.00" rather
      *       than "040.00"
      *   ,   a literal comma is INSERTED at that position when the
      *       value is large enough to reach it (editing characters
      *       like this take up a real byte of output, unlike V)
      * MOVEing a numeric item (like WS-GROSS-PAY, PIC 9(5)V99) into
      * an edited item (like WS-D-GROSS, PIC Z,ZZ9.99) is what
      * triggers this formatting - the compiler does the conversion
      * automatically based on the receiving field's PICTURE.
006000 01 WS-DETAIL-LINE.
006100     05 FILLER              PIC X(2)  VALUE SPACES.
006200     05 WS-D-ID             PIC 9(4).
006300     05 FILLER              PIC X(2)  VALUE SPACES.
006400     05 WS-D-NAME           PIC X(20).
006500     05 FILLER              PIC X(2)  VALUE SPACES.
006600     05 WS-D-HOURS          PIC ZZ9.99.
006700     05 FILLER              PIC X(2)  VALUE SPACES.
006800     05 WS-D-RATE           PIC ZZ9.99.
006900     05 FILLER              PIC X(2)  VALUE SPACES.
007000     05 WS-D-GROSS          PIC Z,ZZ9.99.
007100*
      * An edited PICTURE has to be sized for the LARGEST value that
      * could ever land in it, not just what's in today's test data.
      * WS-D-GROSS needed the extra comma position (PIC Z,ZZ9.99,
      * good up to 9,999.99) even though no single Stage-1 employee's
      * gross reaches four digits, because nothing stops a future
      * record from getting there. Undersizing an edited PICTURE
      * doesn't fail at compile time - it silently truncates or
      * misformats at run time, which is much harder to catch.
007200 01 WS-TOTAL-OUT-LINE.
007300     05 FILLER              PIC X(2)  VALUE SPACES.
007400     05 FILLER              PIC X(16) VALUE "TOTAL GROSS PAY:".
007500     05 FILLER              PIC X(2)  VALUE SPACES.
007600     05 WS-T-GROSS          PIC ZZ,ZZ9.99.
007700*
007800 01 WS-COUNT-OUT-LINE.
007900     05 FILLER              PIC X(2)  VALUE SPACES.
008000     05 FILLER              PIC X(16) VALUE "EMPLOYEE COUNT:".
008100     05 FILLER              PIC X(2)  VALUE SPACES.
008200     05 WS-T-COUNT          PIC ZZ9.
008300*
008400 PROCEDURE DIVISION.
      * PROCEDURE DIVISION is the executable logic, organized into
      * named PARAGRAPHs (000-MAIN, 100-WRITE-HEADERS, ...). The
      * numeric prefixes are just a naming convention to show
      * execution order/grouping at a glance - COBOL doesn't require
      * or enforce it. PERFORM <paragraph-name> calls a paragraph
      * like a subroutine and returns when it falls through to the
      * next paragraph's header; there's no explicit "end" statement
      * needed for a simple PERFORM like this.
008500 000-MAIN.
      * 000-MAIN is the entry point: every COBOL program starts
      * executing at the first statement in PROCEDURE DIVISION.
      * Files must be OPENed before use and CLOSEd when done. OPEN
      * INPUT means "we will only READ this file"; OPEN OUTPUT means
      * "we will only WRITE this file, and it will be (re)created".
008600     OPEN INPUT  EMPLOYEE-FILE.
008700     OPEN OUTPUT REPORT-FILE.
008800     PERFORM 100-WRITE-HEADERS.
      * This is a PRIMING READ - a classic COBOL idiom. We READ once
      * here, before the loop even starts, so that if the file is
      * empty, END-OF-FILE is already TRUE and PERFORM UNTIL never
      * executes its body at all. AT END is only evaluated if the
      * READ finds no more records - it's not a separate check, it's
      * part of the READ statement itself.
008900     READ EMPLOYEE-FILE
009000         AT END SET END-OF-FILE TO TRUE
009100     END-READ.
      * PERFORM UNTIL is COBOL's pre-test loop (condition checked
      * before each iteration, same as a while-loop). It tests the
      * 88-level condition name declared earlier - this is why the
      * priming READ above and the READ at the bottom of
      * 200-PROCESS-EMPLOYEE both matter: each one is what makes
      * END-OF-FILE possibly become true for the NEXT check here.
009200     PERFORM 200-PROCESS-EMPLOYEE UNTIL END-OF-FILE.
009300     PERFORM 300-WRITE-TOTALS.
009400     CLOSE EMPLOYEE-FILE.
009500     CLOSE REPORT-FILE.
      * STOP RUN ends the program immediately. It's only ever used
      * in the main paragraph (or wherever execution should
      * terminate), never inside a paragraph meant to be PERFORMed
      * and returned from.
009600     STOP RUN.
009700*
009800 100-WRITE-HEADERS.
      * WRITE <file-record> FROM <working-storage-item> moves the
      * working-storage item into the file's record area (here,
      * REPORT-LINE) and writes it in one statement - equivalent to
      * MOVE WS-TITLE-LINE TO REPORT-LINE followed by
      * WRITE REPORT-LINE, just shorter.
009900     WRITE REPORT-LINE FROM WS-TITLE-LINE.
010000     WRITE REPORT-LINE FROM WS-UNDER-LINE.
010100     WRITE REPORT-LINE FROM WS-COL-HEADER.
010200*
010300 200-PROCESS-EMPLOYEE.
      * COMPUTE evaluates an arithmetic expression and stores the
      * result - here, ordinary multiplication. (ADD/SUBTRACT/
      * MULTIPLY/DIVIDE also exist as standalone verbs for simple
      * cases, but COMPUTE reads more like a normal assignment
      * statement and is preferred once more than one operator is
      * involved.)
010400     COMPUTE WS-GROSS-PAY = EMP-HOURS * EMP-RATE.
      * Running-total accumulator pattern: ADD the new value INTO
      * the total on every iteration, rather than recomputing the
      * total from scratch. Same idea for the employee counter,
      * incrementing by the literal 1 each pass through the loop.
010500     ADD WS-GROSS-PAY TO WS-TOTAL-GROSS.
010600     ADD 1 TO WS-EMP-COUNT.
      * Field-by-field MOVEs from the input record (EMPLOYEE-RECORD,
      * plain PICTUREs) into the output detail line (WS-DETAIL-LINE,
      * edited PICTUREs). Each MOVE here is where the zero-suppress/
      * comma-insert formatting described above actually happens.
010700     MOVE EMP-ID    TO WS-D-ID.
010800     MOVE EMP-NAME  TO WS-D-NAME.
010900     MOVE EMP-HOURS TO WS-D-HOURS.
011000     MOVE EMP-RATE  TO WS-D-RATE.
011100     MOVE WS-GROSS-PAY TO WS-D-GROSS.
011200     WRITE REPORT-LINE FROM WS-DETAIL-LINE.
      * This READ at the bottom of the loop body is what advances to
      * the next record for the PERFORM UNTIL's next condition check
      * (see the priming-read note in 000-MAIN above) - it plays the
      * same role a for-loop's increment step would in other
      * languages, just expressed as "go get the next record".
011300     READ EMPLOYEE-FILE
011400         AT END SET END-OF-FILE TO TRUE
011500     END-READ.
011600*
011700 300-WRITE-TOTALS.
      * MOVE ... TO REPORT-LINE followed by a plain WRITE REPORT-LINE
      * (no FROM) is the same two steps WRITE ... FROM does for you
      * automatically elsewhere in this program - spelled out here
      * because the separator is just the existing WS-UNDER-LINE
      * value reused verbatim, with nothing else to combine it with.
011800     MOVE WS-UNDER-LINE   TO REPORT-LINE.
011900     WRITE REPORT-LINE.
      * Totals are only formatted into their edited output fields
      * (WS-T-GROSS, WS-T-COUNT) once, here at the end, rather than
      * on every loop iteration - there's no point re-editing a
      * running total that isn't being displayed until the loop is
      * already done.
012000     MOVE WS-TOTAL-GROSS  TO WS-T-GROSS.
012100     WRITE REPORT-LINE FROM WS-TOTAL-OUT-LINE.
012200     MOVE WS-EMP-COUNT    TO WS-T-COUNT.
012300     WRITE REPORT-LINE FROM WS-COUNT-OUT-LINE.
