
\ TRACE-STACK
\ TRACE-WORD


BEGIN-CONST
INCLUDE" build/winconst-extract/winconst.f"
END-CONST
CONSTDICT-HASH WINCONST

WINCONST SEARCH-CONSTDICT-HASH: WINCONST:

\ TRACE-STACK
\ TRACE-WORD

CR winconst 64 dump

s" ABE_BOTTOM"
winconst SEARCH-CONSTDICT-HASH CR H.8 SPACE H.8

s" APPMODEL_ERROR_NO_APPLICATION"
winconst SEARCH-CONSTDICT-HASH CR H.8 SPACE H.8

s" ABE_BOTTOM1"
winconst SEARCH-CONSTDICT-HASH CR H.8

s" ALG_SID_DSS_PKCS2"
winconst SEARCH-CONSTDICT-HASH CR H.8

s" ABE_BOTTO"
winconst SEARCH-CONSTDICT-HASH CR H.8

s" ALG_SID_DSS_PKC"
winconst SEARCH-CONSTDICT-HASH CR H.8

s" ABE_BOTTOM"
linconst SEARCH-CONSTDICT-HASH CR H.8

s" ALG_SID_DSS_PKCS"
linconst SEARCH-CONSTDICT-HASH CR H.8

s" ABE_BOTTOM1"
linconst SEARCH-CONSTDICT-HASH CR H.8

s" ALG_SID_DSS_PKCS2"
linconst SEARCH-CONSTDICT-HASH CR H.8

winconst cdh{: ABS_AUTOHIDE :} CR H.8
winconst cdh{: ABS_ALWAYSONTOP :} CR H.8
winconst cdh{: ABS_AUTOHIDE ABS_ALWAYSONTOP :} CR H.8

: test winconst cdh{: ABS_AUTOHIDE ABS_ALWAYSONTOP :} CR H.8 ;
test

CR H.S
