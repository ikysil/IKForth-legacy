\
\  required.f
\
\  Copyright (C) 1999-2016 Illya Kysil
\

CR .( Loading REQUIRED definitions )

REPORT-NEW-NAME @
REPORT-NEW-NAME OFF

S" Stack changed on INCLUDE" EXCEPTION CONSTANT EXC-STACK-CHANGED

WORDLIST CONSTANT INCLUDED-WORDLIST

VARIABLE REPORT-INCLUDED
REPORT-INCLUDED OFF

VARIABLE TRACK-INCLUDED
TRACK-INCLUDED ON

: ?REPORT-INCLUDED (S c-addr count -- c-addr count )
  REPORT-INCLUDED @ IF CR ." Including " 2DUP TYPE SPACE THEN
;

: INCLUDED, (S c-addr count -- )
  TRACK-INCLUDED @ 
  IF
    2>R
    GET-CURRENT GET-ORDER
    INCLUDED-WORDLIST SET-CURRENT
    0 2R> &USUAL HEADER,
    DROP
    SET-ORDER SET-CURRENT
  ELSE
    2DROP
  THEN
;

:NONAME (S c-addr count -- )
  ?REPORT-INCLUDED
  2DUP S">Z" >R
  [ACTION-OF] INCLUDED CATCH
  R> OVER 0= IF DUP ZCOUNT INCLUDED, THEN FREE THROW THROW
; IS INCLUDED

: REQUIRED? (S c-addr count -- c-addr count flag )
  2DUP INCLUDED-WORDLIST SEARCH-WORDLIST DUP IF NIP THEN INVERT ;

: REQUIRED (S x*i c-addr count -- y*j )
  REQUIRED?
  IF
    SP@ [ 2 CELLS ] LITERAL + \ take account of INCLUDED arguments
    >R
    INCLUDED
    SP@ R> - 0<>
    IF EXC-STACK-CHANGED THROW THEN
  ELSE
    2DROP
  THEN
;

: (REQUIRES) (S x*i c-addr count -- y*j )
  ['] REQUIRED CATCH
  ?DUP IF
         -ROT 2DROP \ remove arguments on exception
         DUP EXC-STACK-CHANGED = IF
                                   ." Stack changed on REQUIRED" DROP
                                 ELSE THROW THEN
       THEN
;

:NONAME BL WORD COUNT (REQUIRES) ;
:NONAME BL WORD COUNT POSTPONE SLITERAL POSTPONE (REQUIRES) ;
INT/COMP: REQUIRES  (S x*i "name" -- y*j )

:NONAME PARSE" (REQUIRES) ;
:NONAME PARSE" POSTPONE SLITERAL POSTPONE (REQUIRES) ;
INT/COMP: REQUIRES" (S x*i "name" -- y*j )

: REQUIRE \ S: <name> <path> --
  \ Check if name is available using FIND, and include path if not
  BL WORD FIND NIP
  IF
    POSTPONE \
  ELSE
    BL WORD COUNT (REQUIRES)
  THEN
;

REPORT-NEW-NAME !
