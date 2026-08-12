000100 IDENTIFICATION DIVISION.
000200 PROGRAM-ID. TAX-CALC.
000300*
000400* M3 Stage 3: tax-withholding subprogram, CALLed from
000500* payroll-net.cob (see src/payroll-net.cob). Takes one
000600* employee's gross pay in, returns the withheld tax amount and
000700* net pay out - three fictional, hand-verifiable brackets, no
000800* attempt at real tax-law accuracy (see README's Non-goals).
000850* M4 Stage 4: the brackets themselves are unchanged (same
000860* thresholds, same rates - net pay for the existing sample data
000870* is byte-identical to M3), but the lookup logic is now an
000880* OCCURS table walked with SEARCH instead of hardcoded
000890* IF/ELSE - see the WORKING-STORAGE and 100-CALC-TAX comments
000900* below.
000910*
      * A SUBPROGRAM is an independently-compiled COBOL program that
      * another program reaches with CALL instead of running on its
      * own via STOP RUN. It has no FILE SECTION and no files of its
      * own here - its only inputs/outputs are the parameters passed
      * on the CALL. Where a standalone program's PROCEDURE DIVISION
      * ends execution with STOP RUN, a subprogram ends each
      * invocation with GOBACK - "return control to whoever CALLed
      * me", leaving the caller free to CALL it again for the next
      * employee.
001000 DATA DIVISION.
001050 WORKING-STORAGE SECTION.
      * M4 Stage 4: the three brackets from M3's IF/ELSE, now data
      * instead of code. TB-THRESHOLD is each bracket's UPPER bound
      * (the last row's 99999.99 is a sentinel meaning "or higher" -
      * PIC 9(5)V99's max value, so every possible LS-GROSS-PAY
      * matches it). TB-RATE is that bracket's flat tax rate. OCCURS
      * repeats the 05-level group 3 times as an in-memory table,
      * indexed by TB-IDX (declared right on the OCCURS clause) -
      * TB-THRESHOLD(1) and TB-RATE(1) are the first row, and so on.
      * Populated by 050-INIT-TAX-TABLE below rather than per-entry
      * VALUE clauses (OCCURS entries can't carry distinct VALUEs
      * portably).
001060 01 TAX-BRACKET-TABLE.
001070     05 TAX-BRACKET OCCURS 3 TIMES INDEXED BY TB-IDX.
001080         10 TB-THRESHOLD    PIC 9(5)V99.
001090         10 TB-RATE         PIC V99.
      * LINKAGE SECTION declares the parameter list a subprogram
      * expects - no VALUE clauses and no storage of its own; each
      * LS- item is just a named window onto whatever data item the
      * CALLing program passed in the matching position of its
      * CALL ... USING list. The order and PICTURE of each item here
      * must match the caller's CALL statement exactly - COBOL links
      * parameters positionally, not by name.
001100 LINKAGE SECTION.
      * LS-GROSS-PAY is input-only (the caller fills it in before the
      * CALL); LS-TAX-AMOUNT and LS-NET-PAY are output-only (this
      * subprogram fills them in before GOBACK). LINKAGE SECTION
      * doesn't distinguish direction in the declaration itself - it's
      * the PROCEDURE DIVISION logic below that decides which items
      * get read vs. written.
001200 01 LS-GROSS-PAY            PIC 9(5)V99.
001300 01 LS-TAX-AMOUNT           PIC 9(5)V99.
001400 01 LS-NET-PAY              PIC 9(5)V99.
001500*
      * PROCEDURE DIVISION USING repeats the same three items in the
      * same order as the LINKAGE SECTION above - that's what wires
      * this subprogram's logic to the caller's actual arguments.
001600 PROCEDURE DIVISION USING LS-GROSS-PAY LS-TAX-AMOUNT LS-NET-PAY.
001700 000-MAIN.
      * M4: table has to be (re)populated before SEARCH can walk it -
      * cheap enough to redo on every CALL that a "populate once"
      * flag would only add complexity, not save meaningful work.
001750     PERFORM 050-INIT-TAX-TABLE.
001800     PERFORM 100-CALC-TAX.
001900     COMPUTE LS-NET-PAY = LS-GROSS-PAY - LS-TAX-AMOUNT.
      * GOBACK, not STOP RUN - see the subprogram note above. STOP RUN
      * here would end the whole caller's process instead of just
      * returning from this one CALL.
002000     GOBACK.
002050*
      * Same three brackets as M3 (10%/15%/20%, thresholds
      * 850.00/1050.00), just expressed as table rows instead of
      * IF/ELSE literals. Row 3's 99999.99 threshold is the "or
      * higher" sentinel described above.
002060 050-INIT-TAX-TABLE.
002070     MOVE 850.00   TO TB-THRESHOLD(1).
002080     MOVE 0.10     TO TB-RATE(1).
002090     MOVE 1050.00  TO TB-THRESHOLD(2).
002100     MOVE 0.15     TO TB-RATE(2).
002110     MOVE 99999.99 TO TB-THRESHOLD(3).
002120     MOVE 0.20     TO TB-RATE(3).
002130*
002200 100-CALC-TAX.
      * SET ... TO 1 resets TB-IDX to the table's first row before
      * each SEARCH. Without it, TB-IDX would keep whatever value the
      * previous employee's SEARCH left it at - TAX-BRACKET-TABLE is
      * WORKING-STORAGE, so it (and its index) persists across CALLs
      * within one run - and later employees would start scanning
      * mid-table, skipping rows they should have matched.
002210     SET TB-IDX TO 1.
      * SEARCH (not SEARCH ALL): SEARCH ALL needs the table in an
      * order it can binary-search by testing equality against a
      * search key, but this lookup's test is a "first row whose
      * threshold is >= gross pay" range comparison, not an equality
      * match - SEARCH's sequential scan is the right tool, same as
      * the IF/ELSE it replaces would have short-circuited on the
      * first true condition. TB-IDX advances from 1 until the WHEN
      * condition is true; AT END is unreachable here since row 3's
      * sentinel matches any possible LS-GROSS-PAY, but COBOL
      * requires the clause regardless of whether it can execute.
002300     SEARCH TAX-BRACKET
002400         AT END
002500             DISPLAY "TAX-CALC: no bracket matched gross pay "
002600                 LS-GROSS-PAY
002700         WHEN LS-GROSS-PAY <= TB-THRESHOLD(TB-IDX)
002800             COMPUTE LS-TAX-AMOUNT ROUNDED =
002900                 LS-GROSS-PAY * TB-RATE(TB-IDX)
003000     END-SEARCH.
