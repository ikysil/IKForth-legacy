\
\  float.4th
\
\  Copyright (C) 2017 Illya Kysil
\

CR .( Loading FLOAT definitions )

REPORT-NEW-NAME @
REPORT-NEW-NAME OFF

REQUIRES" sysdict/x86/486asm.4th"

ONLY FORTH DEFINITIONS

VOCABULARY FLOAT-PRIVATE

ALSO FLOAT-PRIVATE DEFINITIONS

\ private definitions go here

DECIMAL

6 CONSTANT /FPSTACK
3 CELLS CONSTANT B/FLOAT
63 CONSTANT D>F-EXPONENT

<ENV
             TRUE  CONSTANT FLOATING
             TRUE  CONSTANT FLOATING-EXT
         /FPSTACK  CONSTANT FLOATING-STACK
ENV>

\ floating point representation
\ +0   most  significant cell
\ +1   least significant cell
\ unsigned mantissa is stored as double value, aligned to the most significant bit
\ +2   exponent and flags cell

HEX
00000000 CONSTANT FPV-POSITIVE
80000000 CONSTANT FPV-NEGATIVE
80000000 CONSTANT FPV-SIGN
00008000 CONSTANT FPV-EXP-SIGN
00007FFF CONSTANT FPV-EXP-MAX
0000FFFF CONSTANT FPV-EXP-MASK
80000000 CONSTANT FPV-MSBIT
DECIMAL

2 CELLS CONSTANT FPV-EXP-OFFS

USER FPSTACK
/FPSTACK B/FLOAT * USER-ALLOC
USER FP0                    \ initial floats stack pointer
USER FP  1 CELLS USER-ALLOC \ floats stack pointer

: FP@ (S -- addr ) \ addr is floats stack pointer
   FP @
;

: FP! (S addr -- ) \ addr is floats stack pointer
   FP !
;

:NONAME
   FP0 FP!
;
DUP STARTUP-CHAIN CHAIN.ADD EXECUTE

DEFER (F IMMEDIATE ' ( IS (F

: FDEPTH (S -- +n ) \ 12.6.1.1497 FDEPTH
   (G +n is the number of values contained on the floating-point stack. )
   (G If the system has an environmental restriction of keeping )
   (G the floating-point numbers on the data stack, +n is the current number )
   (G of possible floating-point values contained on the data stack. )
   FP0 FP@ - B/FLOAT /
;

: ?FPSTACK-OVERFLOW (S +n -- )
   (G Ensure that floats stack may accommodate +n values, throw exception otherwise )
   FDEPTH + /FPSTACK > IF  EXC-FLOAT-STACK-OVERFLOW THROW  THEN
;

: ?FPSTACK-UNDERFLOW (S +n -- )
   (G Ensure that floats stack has at least +n values, throw exception otherwise )
   FDEPTH > IF  EXC-FLOAT-STACK-UNDERFLOW THROW  THEN
;

: 'FPX (S -- addr )
   (G Return address of the top item on floating-point stack)
   FP@
;

: 'FPX-M (S -- addr )
   (G Return address of the mantissa cell of the top item on floating-point stack)
   'FPX
;

: 'FPX-E (S -- addr )
   (G Return address of the exponent cell of the top item on floating-point stack)
   'FPX FPV-EXP-OFFS +
;

: 'FPY (S -- addr )
   (G Return address of the second item on floating-point stack)
   FP@ [ B/FLOAT ] LITERAL +
;

: 'FPY-M (S -- addr )
   (G Return address of the mantissa cell of the second item on floating-point stack)
   'FPY
;

: 'FPY-E (S -- addr )
   (G Return address of the exponent cell of the second item on floating-point stack)
   'FPY FPV-EXP-OFFS +
;

: 'FPZ (S -- addr )
   (G Return address of the third item on floating-point stack)
   FP@ [ 2 B/FLOAT * ] LITERAL +
;

: 'FPZ-M (S -- addr )
   (G Return address of the mantissa cell of the third item on floating-point stack)
   'FPZ
;

: 'FPZ-E (S -- addr )
   (G Return address of the exponent cell of the third item on floating-point stack)
   'FPZ FPV-EXP-OFFS +
;

: FPFLAGS>EXP (S n1 -- n2 )
   (G Extract exponent value from n with sign expansion)
   FPV-EXP-MASK AND
   DUP FPV-EXP-SIGN AND
   IF  FPV-EXP-MASK INVERT OR  THEN
;

: FP> (S -- d n) (F r -- )
   (G Move float value from floating-point stack to data stack)
   1 ?FPSTACK-UNDERFLOW
   'FPX-M 2@
   'FPX-E @
   FP@ B/FLOAT + FP!
;

: >FP (S d n -- ) (F -- r )
   (G Move float value from data stack to floating-point stack)
   1 ?FPSTACK-OVERFLOW
   FP@ B/FLOAT - FP!
   'FPX-E !
   'FPX-M 2!
;

: FPX0= (S -- flag ) (F r -- r)
   (G flag is true if and only if r is equal to zero.)
   'FPX-M 2@ OR 0=
;

: FPY0= (S -- flag ) (F r1 r2 -- r1 r2)
   (G flag is true if and only if r1 is equal to zero.)
   'FPY-M 2@ OR 0=
;

: FPX-NORMALIZE (F r -- r' )
   (G Normalize representation of r on the top of the stack)
   FPX0= IF  EXIT  THEN
   'FPX-E @ FPFLAGS>EXP >R
   'FPX-M 2@
   BEGIN
      DUP FPV-MSBIT AND 0=
   WHILE
      D2*
      R> 1- >R
   REPEAT
   'FPX-M 2!
   R> FPV-EXP-MASK AND 'FPX-E @ FPV-EXP-MASK INVERT AND OR 'FPX-E !
;

: FPX-DENORMALIZE (S +n -- ) (F r -- r')
   (G De-normalize representation of r on the top of the stack by n bits)
   FPX0=  IF  DROP EXIT  THEN
   DUP 0= IF  DROP EXIT  THEN
   'FPX-E @ FPFLAGS>EXP >R >R
   'FPX-M 2@
   BEGIN
      R@ 0<>
   WHILE
      D2/ FPV-MSBIT INVERT AND
      R> 1- R> 1+ >R >R
   REPEAT
   'FPX-M 2!
   R> DROP R> FPV-EXP-MASK AND 'FPX-E @ FPV-EXP-MASK INVERT AND OR 'FPX-E !
;

: T+ (S nlo nmi nhi mlo mmi mhi -- tlo tmi thi)
   (G Add triple-cell numbers.)
   >R ROT  >R        \ S: nlo nmi mlo mmi   R: mhi nhi
   >R SWAP >R        \ S: nlo mlo           R: mhi nhi mmi nmi
   0 SWAP OVER       \ S: nlo 0 mlo 0       R: mhi nhi mmi nmi
   D+ 0              \ S: tlo tmi1 0        R: mhi nhi mmi nmi
   R> 0 D+           \ S: tlo tmi2 thi1     R: mhi nhi mmi
   R> 0 D+           \ S: tlo tmi thi2      R: mhi nhi
   R> R> + +         \ S: tlo tmi thi       R:
;

: T2/ (S nlo nmi nhi -- nlo' nmi' nhi')
   (G Divide triple-cell value by 2 - shift right with sign extension)
   >R DUP >R
   D2/ DROP
   R> R>
   D2/
;

: F.DUMP
   (G Dump the content of the floating-point stack)
   FP@ DUP FP0 SWAP - CELL+ DUMP
;

: ?FPV-NEGATIVE (S n -- flag)
   \G flag is true if the sign flag in exponent cell n is set
   FPV-SIGN AND FPV-NEGATIVE =
;

ONLY FORTH DEFINITIONS ALSO FLOAT-PRIVATE

\ public definitions go here
\ private definitions are available for use

SYNONYM (F (F

SYNONYM FDEPTH FDEPTH

: FLOATS (S n1 -- n2 ) \ 12.6.1.1556 FLOATS
   (G n2 is the size in address units of n1 floating-point numbers.)
   B/FLOAT *
;

: FDROP (F r -- ) \ 12.6.1.1500 FDROP
   (G Remove r from the floating-point stack.)
   1 ?FPSTACK-UNDERFLOW
   FP@ B/FLOAT + FP!
;

: FDUP (F r -- r r ) \ 12.6.1.1510 FDUP
   (G Duplicate r.)
   1 ?FPSTACK-UNDERFLOW
   'FPX-M 2@
   'FPX-E @
   >FP
;

: FSWAP (F r1 r2 -- r2 r1 ) \ 12.6.1.1620 FSWAP
   (G Exchange the top two floating-point stack items.)
   2 ?FPSTACK-UNDERFLOW
   'FPX-M 2@
   'FPX-E @
   'FPY-M 2@
   'FPY-E @
   'FPX-E !
   'FPX-M 2!
   'FPY-E !
   'FPY-M 2!
;

: FOVER (F r1 r2 -- r1 r2 r1 ) \ 12.6.1.1600 FOVER
   (G Place a copy of r1 on top of the floating-point stack.)
   2 ?FPSTACK-UNDERFLOW
   1 ?FPSTACK-OVERFLOW
   'FPY-M 2@
   'FPY-E @
   >FP
;

: FROT (F r1 r2 r3 -- r2 r3 r1 ) \ 12.6.1.1610 FROT
   (G Rotate the top three floating-point stack entries.)
   FP> FSWAP >FP FSWAP
;

: D>F (S d -- ) (F -- r ) \ 12.6.1.1130 D>F
   (G r is the floating-point equivalent of d. )
   (G An ambiguous condition exists if d cannot be precisely represented as a floating-point value.)
   2DUP D0< IF  DABS FPV-NEGATIVE  ELSE  FPV-POSITIVE  THEN
   D>F-EXPONENT +
   >FP FPX-NORMALIZE
;

: FNEGATE (F r1 -- r2 ) \ 12.6.1.1567 FNEGATE
   (G r2 is the negation of r1.)
   1 ?FPSTACK-UNDERFLOW
   'FPX-E @
   FPV-SIGN XOR
   'FPX-E !
;

: F0< (S -- flag ) (F r -- ) \ 12.6.1.1440 F0<
   (G flag is true if and only if r is less than zero.)
   1 ?FPSTACK-UNDERFLOW
   FP> ?FPV-NEGATIVE
   >R OR 0<> R> AND
;

: F0= (S -- flag ) (F r -- ) \ 12.6.1.1450 F0=
   (G flag is true if and only if r is equal to zero.)
   FPX0= FDROP
;

: FNIP (F r1 r2 -- r2)
   (G Drop the first item below the top of stack.)
   2 ?FPSTACK-UNDERFLOW
   FP> FDROP >FP
;

: F+PREPARE (F r1 r2 -- r1' r2' )
   (G Prepare operands for add/subtract operation)
   (G - move operand with lesser exponent to the TOS)
   (G - denormalize TOS)
   'FPY-E @ FPFLAGS>EXP
   'FPX-E @ FPFLAGS>EXP
   < IF  FSWAP  THEN
   'FPY-E @ FPFLAGS>EXP
   'FPX-E @ FPFLAGS>EXP
   - FPX-DENORMALIZE
;

: FPV-M>D (S mlo mhi sign -- mlo mhi sign)
   (G Adjust the value of mantissa - negate if flag is true)
   DUP IF  >R DNEGATE R>  THEN
;

: F+ (F r1 r2 -- r3 ) \ 12.6.1.1420 F+
   (G Add r1 to r2 giving the sum r3.)
   2 ?FPSTACK-UNDERFLOW
   FPX0= IF  FDROP EXIT  THEN
   FPY0= IF  FNIP  EXIT  THEN
   F+PREPARE
   'FPY-M 2@ 'FPY-E @ ?FPV-NEGATIVE FPV-M>D
   'FPX-M 2@ 'FPX-E @ ?FPV-NEGATIVE FPV-M>D
   \DEBUG S" F+-B1: " CR TYPE CR H.S CR
   T+ T2/
   \DEBUG S" F+-B2: " CR TYPE CR H.S CR
   FDROP
   0<> FPV-SIGN AND FPV-M>D
   'FPX-E @ FPFLAGS>EXP 1+ FPV-EXP-MASK AND OR 'FPX-E !
   'FPX-M 2!
   FPX-NORMALIZE
;

: F- (F r1 r2 -- r3 ) \ 12.6.1.1425 F-
   (G Subtract r2 from r1, giving r3.)
   FNEGATE F+
;

USER F*-YL*XH  2 CELLS USER-ALLOC
USER F*-YH*XL  2 CELLS USER-ALLOC
USER F*-YH*XH  2 CELLS USER-ALLOC

: F* (F r1 r2 -- r3 ) \ 12.6.1.1410 F*
   (G Multiply r1 by r2 giving r3.)
   2 ?FPSTACK-UNDERFLOW
   FPX0= IF  FNIP  EXIT  THEN
   FPY0= IF  FDROP EXIT  THEN
   'FPY-M 2@ 'FPX-M 2@  \ S: yl yh xl xh
   ROT SWAP OVER        \ S: yl xl yh xh yh
   UM* F*-YH*XH 2!
   UM* F*-YH*XL 2!
   'FPX-M 2@            \ S: yl xl xh
   ROT SWAP OVER        \ S: xl yl xh yl
   UM* F*-YL*XH 2!
   UM* 0
   0 F*-YL*XH 2@ T+
   0 F*-YH*XL 2@ T+
   ROT DROP 0
   0 F*-YH*XH 2@ T+
   'FPY-M 2! DROP
   'FPY-E @ DUP FPV-SIGN AND SWAP FPV-EXP-MASK AND
   'FPX-E @ DUP FPV-SIGN AND SWAP FPV-EXP-MASK AND
   ROT + 1+ FPV-EXP-MASK AND
   >R XOR R> OR 'FPY-E !
   FDROP
   FPX-NORMALIZE
;

USER F/-Q    2 CELLS USER-ALLOC
USER F/-QBIT 2 CELLS USER-ALLOC
USER F/-YM   2 CELLS USER-ALLOC
USER F/-XM   2 CELLS USER-ALLOC

: F/ (F r1 r2 -- r3 ) \ 12.6.1.1430 F/
   (G Divide r1 by r2, giving the quotient r3. )
   (G An ambiguous condition exists if r2 is zero, )
   (G or the quotient lies outside of the range of a floating-point number.)
   2 ?FPSTACK-UNDERFLOW
   FPX0= IF  EXC-FLOAT-DIVISION-BY-ZERO THROW  THEN
   FPY0= IF  FDROP EXIT  THEN
   \DEBUG CR S" F/-A: " TYPE CR F.DUMP CR
   0. F/-Q 2!
   0 FPV-MSBIT F/-QBIT 2!
   'FPY-M 2@ F/-YM 2!
   'FPX-M 2@ F/-XM 2!
   BEGIN
      F/-QBIT 2@ OR 0<>
      F/-YM 2@ OR 0<>
      AND
   WHILE
      F/-YM 2@ 0
      F/-XM 2@ 0
      \DEBUG CR S" F/-B1: " TYPE CR H.S CR
      TNEGATE
      \DEBUG CR S" F/-B2: " TYPE CR H.S CR
      T+ 0<
      \DEBUG CR S" F/-B3: " TYPE CR H.S CR
      IF
         2DROP
      ELSE
         F/-YM 2!
         F/-Q 2@ F/-QBIT 2@ ROT OR >R OR R> F/-Q 2!
      THEN
      F/-XM   2@ 0 T2/ DROP F/-XM   2!
      F/-QBIT 2@ 0 T2/ DROP F/-QBIT 2!
   REPEAT
   F/-Q 2@ 'FPY-M 2!
   'FPY-E @ DUP FPV-SIGN AND SWAP FPV-EXP-MASK AND
   'FPX-E @ DUP FPV-SIGN AND SWAP FPV-EXP-MASK AND
   ROT SWAP - FPV-EXP-MASK AND
   >R XOR R> OR 'FPY-E !
   FDROP
   \DEBUG CR S" F/-C: " TYPE CR F.DUMP CR
   FPX-NORMALIZE
   \DEBUG CR S" F/-D: " TYPE CR F.DUMP CR
;

: F< (S -- flag ) (F r1 r2 -- ) \ 2.6.1.1460 F<
   (G flag is true if and only if r1 is less than r2.)
   F- F0<
;

: FMIN (F r1 r2 -- r3 ) \ 12.6.1.1565 FMIN
   (G r3 is the lesser of r1 and r2.)
   2 ?FPSTACK-UNDERFLOW
   2 ?FPSTACK-OVERFLOW
   FOVER FOVER F< IF  FDROP  ELSE  FNIP  THEN
;

: FMAX (F r1 r2 -- r3 ) \ 12.6.1.1562 FMAX
   (G r3 is the greater of r1 and r2.)
   2 ?FPSTACK-UNDERFLOW
   2 ?FPSTACK-OVERFLOW
   FOVER FOVER F< IF  FNIP  ELSE  FDROP  THEN
;

: F>D ( -- d ) (F r -- ) \ 12.6.1.1470 F>D
   (G d is the double-cell signed-integer equivalent of the integer portion of r.)
   (G The fractional portion of r is discarded.)
   (G An ambiguous condition exists if the integer portion of r cannot be represented as a double-cell signed integer.)
   (G Note: Rounding the floating-point value prior to calling F>D is advised, because F>D rounds towards zero.)
   1 ?FPSTACK-UNDERFLOW
   \DEBUG CR S" F>D-A: " TYPE CR F.DUMP CR
   D>F-EXPONENT 'FPX-E @ FPFLAGS>EXP -
   DUP 0< IF  EXC-OUT-OF-RANGE THROW  THEN
   \DEBUG CR S" F>D-B: " TYPE CR H.S CR
   FPX-DENORMALIZE
   \DEBUG CR S" F>D-C: " TYPE CR F.DUMP CR
   'FPX-M 2@
   \DEBUG CR S" F>D-D: " TYPE CR H.S CR
   'FPX-E @ ?FPV-NEGATIVE FPV-M>D DROP
   FDROP
   \DEBUG CR S" F>D-E: " TYPE CR H.S CR
;

: F! (S f-addr -- ) (F r -- ) \ 12.6.1.1400 F!
   \G Store r at f-addr.
   1 ?FPSTACK-UNDERFLOW
   FP@ SWAP 1 FLOATS MOVE
   FDROP
;

: F@ (S f-addr -- ) (F -- r ) \ 12.6.1.1472 F@
   \G r is the value stored at f-addr.
   1 ?FPSTACK-OVERFLOW
   0. D>F
   FP@ 1 FLOATS MOVE
;

: FVARIABLE ( "<spaces>name" -- ) \ 12.6.1.1630 FVARIABLE
   \G Skip leading space delimiters. Parse name delimited by a space.
   \G Create a definition for name with the execution semantics defined below.
   \G Reserve 1 FLOATS address units of data space at a float-aligned address.
   \G
   \G name is referred to as an "f-variable".
   \G
   \G name Execution: (S -- f-addr )
   \G f-addr is the address of the data space reserved by FVARIABLE when it created name.
   \G A program is responsible for initializing the contents of the reserved space.
   CREATE  HERE 1 FLOATS DUP ALLOT ERASE
   DOES>
;

: FCONSTANT ( "<spaces>name" -- ) (F r -- ) \ 2.6.1.1492 FCONSTANT
   \G Skip leading space delimiters. Parse name delimited by a space.
   \G Create a definition for name with the execution semantics defined below.
   \G
   \G name is referred to as an "f-constant".
   \G
   \G name Execution: (S -- ) (F -- r )
   \G Place r on the floating-point stack.
   1 ?FPSTACK-UNDERFLOW
   CREATE  HERE 1 FLOATS ALLOT F!
   DOES>   1 ?FPSTACK-OVERFLOW F@
;

CODE FLIT
   PUSH        ESI
   ADD         ESI , # B/FLOAT
   NEXT
END-CODE COMPILE-ONLY

: FLITERAL \ 12.6.1.1552 FLITERAL
   \G Interpretation: Interpretation semantics for this word are undefined.
   \G Compilation: ( F: r -- )
   \G Append the run-time semantics given below to the current definition.
   \G
   \G Run-time: ( F: -- r )
   \G Place r on the floating-point stack.
   1 ?FPSTACK-UNDERFLOW
   POSTPONE FLIT
   HERE
   1 FLOATS ALLOT
   F!
   POSTPONE F@
; IMMEDIATE/COMPILE-ONLY

: FABS (F r1 -- r2 ) \ 12.6.2.1474 FABS
   \G r2 is the absolute value of r1.
   1 ?FPSTACK-UNDERFLOW
   'FPX-E @ FPV-SIGN INVERT AND 'FPX-E !
;

: F~ (S -- flag ) (F r1 r2 r3 -- ) \ 12.6.2.1640 F~
   \G If r3 is positive, flag is true if the absolute value of (r1 minus r2) is less than r3.
   \G
   \G If r3 is zero, flag is true if the implementation-dependent encoding of r1 and r2 are exactly
   \G identical (positive and negative zero are unequal if they have distinct encodings).
   \G
   \G If r3 is negative, flag is true if the absolute value of (r1 minus r2) is less than
   \G the absolute value of r3 times the sum of the absolute values of r1 and r2.
   3 ?FPSTACK-UNDERFLOW
   \DEBUG CR S" F~-A1: " TYPE CR F.DUMP CR
   FPX0= IF
      FDROP
      'FPX 'FPY 1 FLOATS TUCK COMPARE 0=
      FDROP FDROP
      EXIT
   THEN
   'FPX-E @ ?FPV-NEGATIVE IF
      FABS FP>          \ F: r1 r2                                S: abs(r3)
      FDUP FABS FP>     \ F: r1 r2                                S: abs(r3) abs(r2)
      FOVER FABS FP>    \ F: r1 r2                                S: abs(r3) abs(r2) abs(r1)
      \DEBUG CR S" F~-B1: " TYPE CR F.DUMP CR H.S CR
      F- FABS           \ F: abs(r1-r2)                           S: abs(r3) abs(r2) abs(r1)
      \DEBUG CR S" F~-B2: " TYPE CR F.DUMP CR H.S CR
      >FP >FP F+        \ F: abs(r1-r2) abs(r1)+abs(r2)           S: abs(r3)
      \DEBUG CR S" F~-B3: " TYPE CR F.DUMP CR H.S CR
      >FP F*            \ F: abs(r1-r2) (abs(r1)+abs(r2))*abs(r3)
      \DEBUG CR S" F~-B4: " TYPE CR F.DUMP CR H.S CR
      F-
      \DEBUG CR S" F~-B5: " TYPE CR F.DUMP CR H.S CR
      F0<
      \DEBUG CR S" F~-B6: " TYPE CR H.S CR
   ELSE
      FP> F- FABS >FP F<
   THEN
;

 0. D>F FCONSTANT FZERO
 1. D>F FCONSTANT FONE
10. D>F FCONSTANT FTEN

USER >FLOAT-M-SIGN 1 CELLS USER-ALLOC

: >FLOAT-PARSE-EXPONENT (S c-addr u -- exp-sign udexp c-addr' u')
   \G Parse exponent.
   \G udexp - usigned exponent value
   \G exp-sign - sign of the exponent (1/0/-1), 0 if exponent value is absent
   DUP 1 < IF  2>R 0 0. 2R> EXIT  THEN
   OVER C@ CASE
      'D' OF  1 /STRING  ENDOF
      'd' OF  1 /STRING  ENDOF
      'E' OF  1 /STRING  ENDOF
      'e' OF  1 /STRING  ENDOF
   ENDCASE
   DUP 0> IF
      OVER C@ CASE
         '+' OF  1 /STRING  1  ENDOF
         '-' OF  1 /STRING -1  ENDOF
         >R 1 R>
      ENDCASE
   ELSE
      0
   THEN
   -ROT
   \ S: exp-sign c-addr" u"
   \DEBUG S" >FLOAT-PARSE-EXPONENT-A: " CR TYPE CR H.S CR
   0. 2SWAP
   \ S: exp-sign 0 0 c-addr" u"
   \DEBUG S" >FLOAT-PARSE-EXPONENT-B: " CR TYPE CR H.S CR
   DUP 0> IF  >NUMBER  THEN
   \ S: exp-sign udexp c-addr' u'
   \DEBUG S" >FLOAT-PARSE-EXPONENT-C: " CR TYPE CR H.S CR
;

: >FLOAT-FIX-EXPONENT (S +exp-corr exp-sign udexp -- ) (F r -- r')
   \G Restore scale using unsigned exponent value udexp,
   \G exponent sign exp-sign (1/0/-1), and correction +exp-corr.
   \G exp-corr is the number of the positions after decimal dot.
   \DEBUG S" >FLOAT-FIX-EXPONENT-A: " CR TYPE CR H.S CR F.DUMP CR
   2DUP FPV-EXP-MAX S>D DU< INVERT IF  EXC-FLOAT-OUT-OF-RANGE THROW  THEN
   D>S
   \ S: +exp-corr exp-sign uexp
   \DEBUG S" >FLOAT-FIX-EXPONENT-B: " CR TYPE CR H.S CR F.DUMP CR
   * SWAP -
   DUP 0= IF  DROP EXIT  THEN
   DUP 0< IF  ['] F/  ELSE  ['] F*  THEN SWAP
   ABS
   FTEN FSWAP
   \ S: op-xt abs(exp)      F: 10. ud
   \DEBUG S" >FLOAT-FIX-EXPONENT-C: " CR TYPE CR H.S CR F.DUMP CR
   BEGIN
      DUP 0>
   WHILE
      FOVER
      OVER CATCH THROW
      \DEBUG S" >FLOAT-FIX-EXPONENT-D: " CR TYPE CR H.S CR F.DUMP CR
      1-
   REPEAT
   \ S: op-xt 0             F: 10. (fra+int)*10**exp
   2DROP
   FNIP
;

: ?DECIMAL (S -- flag )
   \G flag is true only if current BASE is DECIMAL
   BASE @ D# 10 =
;

: >FLOAT (S c-addr u -- true | false ) (F -- r | ~ ) \ 12.6.1.0558 >FLOAT
   \G An attempt is made to convert the string specified by c-addr and u
   \G to internal floating-point representation. If the string represents
   \G a valid floating-point number in the syntax below, its value r and true are returned.
   \G If the string does not represent a valid floating-point number only false is returned.
   \G
   \G A string of blanks should be treated as a special case representing zero.
   \G
   \G The syntax of a convertible string
   \G :=	<significand>[<exponent>]
   \G <significand> := [<sign>]{<digits>[.<digits0>] | .<digits> }
   \G <exponent> := <marker><digits0>
   \G <marker> := {<e-form> | <sign-form>}
   \G <e-form> := <e-char>[<sign-form>]
   \G <sign-form> :=	{ + | - }
   \G <e-char> := { D | d | E | e }
   SKIP-BLANK
   DUP 0= IF  2DROP FZERO TRUE EXIT  THEN
   ?DECIMAL INVERT IF  EXC-INVALID-FLOAT-BASE THROW  THEN
   OVER C@ CASE
      '+' OF   0 >FLOAT-M-SIGN ! 1 /STRING  ENDOF
      '-' OF  -1 >FLOAT-M-SIGN ! 1 /STRING  ENDOF
      0 >FLOAT-M-SIGN !
   ENDCASE
   DUP 0= IF  2DROP FALSE EXIT  THEN
   0. 2OVER >NUMBER  \ S: c-addr1 u1 udint c-addr2 u2
   2ROT 2OVER D= IF  2DROP 2DROP FALSE EXIT  THEN
   \DEBUG S" >FLOAT-A: " CR TYPE CR H.S CR
   DUP 0= IF  2DROP D>F TRUE EXIT  THEN
   OVER C@ '.' = IF
      1 /STRING
      2SWAP 2OVER >NUMBER
      \ S: c-addr2 u2 ud c-addr3 u3
      2ROT NIP OVER -
      \ S: ud c-addr3 u3 +exp-corr
   ELSE
      0
   THEN
   \ S: ud c-addr3 u3 +exp-corr
   \DEBUG S" >FLOAT-B: " CR TYPE CR H.S CR
   >R 2SWAP D>F R>
   -ROT
   \ S: +exp-corr c-addr3 u3                   F: ud
   >FLOAT-PARSE-EXPONENT
   \ S: +exp-corr exp-sign udexp c-addr4 u4    F: ud
   \DEBUG S" >FLOAT-C: " CR TYPE CR H.S CR
   DUP 0<> IF  6 NDROP FDROP FALSE EXIT  THEN
   2DROP
   \ S: +exp-corr exp-sign udexp               F: ud
   \DEBUG S" >FLOAT-D: " CR TYPE CR H.S CR
   >FLOAT-FIX-EXPONENT
   \ S:                                        F: ud'
   >FLOAT-M-SIGN @ 0< IF  FNEGATE  THEN
   TRUE
   \DEBUG S" >FLOAT-I: " CR TYPE CR H.S CR F.DUMP CR
;

:NONAME (S c-addr u -- )
   ?DECIMAL IF
      2DUP
      >FLOAT IF
         STATE @ IF  POSTPONE FLITERAL  THEN
         2DROP EXIT
      THEN
   THEN

   DEFERRED INTERPRET-WORD-NOT-FOUND
; IS INTERPRET-WORD-NOT-FOUND

ONLY FORTH DEFINITIONS

REPORT-NEW-NAME !

\EOF

-1. d>f
1. d>f
F+
CR F.DUMP
FDROP

123. d>f
12. d>f
F+
CR F.DUMP
FDROP

123. d>f
12. d>f
F-
CR F.DUMP
FDROP

44443333222211110000. d>f
44443333222211110001. d>f
F-
CR F.DUMP
FDROP

HEX FEDCBA987654321. DECIMAL d>f
HEX 123456789ABCDEF. DECIMAL d>f
F-
CR F.DUMP
FDROP

HEX 123456789ABCDEF. DECIMAL d>f
HEX FEDCBA987654321. DECIMAL d>f
F-
CR F.DUMP
FDROP

-1. d>f
1. d>f
CR F.DUMP
F*
CR F.DUMP
FDROP

-255. d>f
256. d>f
CR F.DUMP
F*
CR F.DUMP
FDROP

-255. d>f
1000. d>f
CR F.DUMP
F*
CR F.DUMP
-255000. D>F
F- F0= CR .

-2. d>f
2. d>f
CR F.DUMP
F/
CR F.DUMP
-1. D>F
F-
CR F.DUMP
F0= CR .

1. D>F
CR F.DUMP
F>D
CR .S
1. D=
CR .

1. D>F
10. D>F
F/
CR F.DUMP
F>D
CR .S
0. D=
CR .

-1. D>F
CR F.DUMP
F>D
CR .S
-1. D=
CR .

bye
