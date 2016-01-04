\
\  environment.f
\
\  Copyright (C) 1999-2004 Illya Kysil
\
\  ENVIRONMENT? queries support
\

CR .( Loading ENVIRONMENT definitions )

REPORT-NEW-NAME @
REPORT-NEW-NAME OFF

WORDLIST CONSTANT ENVIRONMENT-WORDLIST

ENVIRONMENT-WORDLIST (VOCABULARY) ENVIRONMENT

USER ENV-CURRENT 1 CELLS USER-ALLOC

: <ENV
  GET-CURRENT ENV-CURRENT ! ENVIRONMENT-WORDLIST SET-CURRENT
;

: ENV>
  ENV-CURRENT @ SET-CURRENT
;

<ENV DECIMAL

              255  CONSTANT /COUNTED-STRING
         HLD-SIZE  CONSTANT /HOLD
         PAD-SIZE  CONSTANT /PAD
                8  CONSTANT ADDRESS-UNITS-BITS
     -10 7 / -2 =  CONSTANT FLOORED
             TRUE  CONSTANT CORE
             TRUE  CONSTANT CORE-EXT
             TRUE  CONSTANT DOUBLE
             TRUE  CONSTANT DOUBLE-EXT
             TRUE  CONSTANT EXCEPTION
             TRUE  CONSTANT EXCEPTION-EXT
             TRUE  CONSTANT FACILITY
             TRUE  CONSTANT FACILITY-EXT
             TRUE  CONSTANT FILE
             TRUE  CONSTANT FILE-EXT
             TRUE  CONSTANT SEARCH-ORDER
             TRUE  CONSTANT SEARCH-ORDER-EXT
             TRUE  CONSTANT STRING
             TRUE  CONSTANT STRING-EXT
             TRUE  CONSTANT TOOLS
             TRUE  CONSTANT TOOLS-EXT
             TRUE  CONSTANT MEMORY-ALLOC
             TRUE  CONSTANT MEMORY-ALLOC-EXT
             TRUE  CONSTANT ZCHAR
             TRUE  CONSTANT ZCHAR-EXT
HEX

              FF   CONSTANT MAX-CHAR
        7FFFFFFF   CONSTANT MAX-N
        FFFFFFFF   CONSTANT MAX-U
7FFFFFFFFFFFFFFF. 2CONSTANT MAX-D
FFFFFFFFFFFFFFFF. 2CONSTANT MAX-UD

DECIMAL
          RS-SIZE  CONSTANT RETURN-STACK-CELLS
          DS-SIZE  CONSTANT STACK-CELLS

             4096  CONSTANT WORDLISTS

ENV>

: ENVIRONMENT?
  ENVIRONMENT-WORDLIST SEARCH-WORDLIST
  IF EXECUTE TRUE ELSE FALSE THEN
;

: [DEFINED] (S "name" -- flag )
  ['] ' CATCH ?DUP
  IF
    DUP EXC-UNDEFINED = IF DROP FALSE ELSE THROW THEN
  ELSE
    DROP TRUE
  THEN
; IMMEDIATE

: [UNDEFINED] (S "name" -- flag )
  ['] ' CATCH ?DUP
  IF
    DUP EXC-UNDEFINED = IF DROP TRUE ELSE THROW THEN
  ELSE
    DROP FALSE
  THEN
; IMMEDIATE

: [VOID] (S -- FALSE )
  FALSE
; IMMEDIATE

REPORT-NEW-NAME !
