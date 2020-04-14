\
\  linux.4th
\
\  Unlicense since 1999 by Illya Kysil
\
\  Linux specific definitions
\

REQUIRES" sysdict/dynlib.4th"
REQUIRES" sysdict/x86-linux/linconst.4th"

CR .( Probing for Linux host )

S" libc.so.6" (LoadLibrary) [IF]

<ENV

: PLATFORM S" Linux" ;

ENV>

REQUIRES" sysdict/x86-linux/lindynlib.4th"
\ FIXME - remove - #52 REQUIRES" sysdict/x86-linux/lincon.4th"
REQUIRES" sysdict/x86-linux/libc.4th"
REQUIRES" sysdict/x86-linux/libreadline.4th"
REQUIRES" sysdict/x86-linux/linfile.4th"
REQUIRES" sysdict/term/linconsole.4th"

:NONAME
   S" ANSITERM-INIT"
; IS TERMINIT-DEFAULT

[THEN]
