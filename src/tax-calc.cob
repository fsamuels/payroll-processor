000100 IDENTIFICATION DIVISION.
000200 PROGRAM-ID. TAX-CALC.
000300*
000400* M3 Stage 3: tax-withholding subprogram, CALLed from
000500* payroll-net.cob (see src/payroll-net.cob). Takes one
000600* employee's gross pay in, returns the withheld tax amount and
000700* net pay out - three fictional, hand-verifiable brackets, no
000800* attempt at real tax-law accuracy (see README's Non-goals).
000900*
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
001800     PERFORM 100-CALC-TAX.
001900     COMPUTE LS-NET-PAY = LS-GROSS-PAY - LS-TAX-AMOUNT.
      * GOBACK, not STOP RUN - see the subprogram note above. STOP RUN
      * here would end the whole caller's process instead of just
      * returning from this one CALL.
002000     GOBACK.
002100*
      * Three fictional, hardcoded brackets - deliberately simple
      * IF/ELSE, not a table. Stage 4 (stretch, see roadmap.md) plans
      * to replace this exact logic with an OCCURS table and
      * SEARCH/SEARCH ALL, so this hardcoded form is the "before"
      * picture for that comparison, not an oversight.
002200 100-CALC-TAX.
002300     IF LS-GROSS-PAY <= 850.00
002400         COMPUTE LS-TAX-AMOUNT ROUNDED = LS-GROSS-PAY * 0.10
002500     ELSE
002600         IF LS-GROSS-PAY <= 1050.00
002700             COMPUTE LS-TAX-AMOUNT ROUNDED = LS-GROSS-PAY * 0.15
002800         ELSE
002900             COMPUTE LS-TAX-AMOUNT ROUNDED = LS-GROSS-PAY * 0.20
003000         END-IF
003100     END-IF.
