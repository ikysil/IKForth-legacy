\
\  win32.4th
\
\  Unlicense since 1999 by Illya Kysil
\
\  Win32 specific definitions
\

REQUIRES" sysdict/dynlib.4th"

CR .( Probing for Win32 host )

S" kernel32.dll" (LoadLibrary) [IF]

<ENV

: PLATFORM S" Win32" ;

ENV>

REQUIRES" sysdict/x86-windows/kernel32.4th"
REQUIRES" sysdict/x86-windows/wincon.4th"
REQUIRES" sysdict/x86-windows/winerr.4th"
REQUIRES" sysdict/x86-windows/winexception.4th"
REQUIRES" sysdict/term/winconsole.4th"
REQUIRES" sysdict/x86-windows/winfile.4th"
REQUIRES" sysdict/x86-windows/winmisc.4th"

:NONAME
   S" WINCONSOLE-INIT"
; IS TERMINIT-DEFAULT

[THEN]
