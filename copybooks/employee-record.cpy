000100* employee-record.cpy
000200*
000300* Shared record layout for the employee master file
000400* (data/employees.dat): one flat, fixed-width record per
000500* employee, no delimiters between fields - the PICTURE widths
000600* below ARE the file format on disk.
000700*
      * WHAT'S A COPYBOOK? A .cpy file holds a chunk of COBOL source
      * - here, just an 01-level record description - that gets
      * pulled in verbatim wherever a COPY statement names it,
      * before the compiler does anything else with the source. It's
      * plain text substitution, not a separate compilation unit or
      * a runtime call. The payoff: define a record layout once,
      * COPY it into every program that reads this file
      * (payroll-v1.cob and payroll-report.cob both do), and a
      * future field change only has to happen in this one place -
      * both programs recompile against the same layout automatically
      * instead of two hand-typed copies drifting apart over time.
      *
      * Because COPY inserts this text into a fixed-format program,
      * this file follows the same fixed-format column rules as any
      * .cob source: columns 1-6 are the sequence-number area, column
      * 7 is the indicator area ('*' = comment line), columns 8-11
      * are "Area A" (the 01-level line below), columns 12+ are
      * "Area B" (the 05-level fields). See src/payroll-v1.cob for
      * the full orientation if this is unfamiliar.
      *
      * Compiling any program that COPYs this file needs `-I
      * copybooks` on the cobc command line, so the compiler knows
      * where to look for employee-record.cpy - see README.md.
000800 01 EMPLOYEE-RECORD.
      *     PIC 9    one numeric digit (0-9), unsigned
      *     PIC X    one alphanumeric character, any byte
      *     PIC V    an IMPLIED decimal point - lines up where the
      *              decimal belongs but takes up zero bytes on disk.
      *              EMP-HOURS PIC 9(3)V99 is 5 bytes wide, and
      *              40.00 hours is stored as the literal digits
      *              "04000", not "040.00". Get the zero-padding
      *              wrong and every field after it in the record
      *              shifts out of alignment.
000900     05 EMP-ID              PIC 9(4).
001000     05 EMP-NAME            PIC X(20).
001100     05 EMP-HOURS           PIC 9(3)V99.
001200     05 EMP-RATE            PIC 9(3)V99.
