requires" lib/~ik/locals-test.4th"

: TEST-DUMP
  CR
  ['] DUMP >HEAD
  DUP 64 DUMP
  0 DUMP/LINE !
  DUP 64 DUMP
  32 DUMP/LINE !
  DUP 64 DUMP
  DROP
;

TEST-DUMP
