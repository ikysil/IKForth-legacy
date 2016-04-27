                $COLON      'BOOTSTRAP-INTERPRET',$BOOTSTRAP_INTERPRET,VEF_HIDDEN
                CW          $INIT_USER
                CFETCH      $SF
                CFETCH      $HASH_SF
                CWLIT       $INCLUDED
                CW          $CATCH, $DUP, $EXIT_CODE, $STORE, $QDUP
                CQBR        BSI_NO_EXCEPTIONS
                $CR
                $CR
                $WRITE      'Exception caught while INCLUDing ['
                CFETCH      $SF
                CFETCH      $HASH_SF
                CW          $TYPE
                $WRITE      ']'
                $CR
                $WRITE      'Exception: H# '
                CW          $HOUT8
                $CR
                CW          $2DROP
                $WRITE      'HERE:      H# '
                CW          $HERE, $HOUT8
                $CR
                $WRITE      'Latest word searched: '
                CW          $POCKET, $COUNT, $TYPE
                $CR
                $WRITE      'Latest vocabulary entry: '
                CW          $LATEST_HEAD_FETCH, $H_TO_HASH_NAME, $DUP, $ZERONOEQ
                _IF         BSI_ERROR_HAS_NAME
                CW          $TYPE
                _ELSE       BSI_ERROR_HAS_NAME
                CW          $2DROP
                $WRITE      '(nonamed)'
                _THEN       BSI_ERROR_HAS_NAME
                $CR
                $WRITE      'Error in: '
                CW          $REPORT_SOURCE
                $CR
                $CR
BSI_NO_EXCEPTIONS:
                CW      $PBYE
