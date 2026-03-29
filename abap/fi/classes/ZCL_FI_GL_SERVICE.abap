*&---------------------------------------------------------------------*
*& Class: ZCL_FI_GL_SERVICE
*& Description: 총계정원장 서비스 (General Ledger Service)
*& 담당업무: GL 계정 마스터 관리, 회계전표 전기/역전, 계정잔액 조회
*& Transaction: SE24
*&---------------------------------------------------------------------*

CLASS zcl_fi_gl_service DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.

    " ================================================================
    " 타입 정의
    " ================================================================
    TYPES:
      " GL 계정 마스터
      BEGIN OF ty_gl_account,
        bukrs      TYPE bukrs,
        saknr      TYPE saknr,
        ktoks      TYPE ktoks,
        xbilk      TYPE xbilk,
        txt20      TYPE c LENGTH 20,
        txt50      TYPE c LENGTH 50,
        waers      TYPE waers,
        xopvw      TYPE c LENGTH 1,
        gvtyp      TYPE gvtyp,
        stat_ind   TYPE c LENGTH 1,
        created_by TYPE uname,
      END OF ty_gl_account,
      ty_gl_accounts TYPE STANDARD TABLE OF ty_gl_account WITH KEY saknr,

      " 회계전표 (헤더+아이템 통합)
      BEGIN OF ty_journal_item,
        buzei    TYPE buzei,
        saknr    TYPE saknr,
        shkzg    TYPE shkzg,
        dmbtr    TYPE dmbtr,
        wrbtr    TYPE wrbtr,
        kostl    TYPE kostl,
        aufnr    TYPE aufnr,
        prctr    TYPE prctr,
        mwskz    TYPE mwskz,
        sgtxt    TYPE sgtxt,
        lifnr    TYPE lifnr,
        kunnr    TYPE kunnr,
      END OF ty_journal_item,
      ty_journal_items TYPE STANDARD TABLE OF ty_journal_item WITH KEY buzei,

      BEGIN OF ty_journal_header,
        bukrs  TYPE bukrs,
        belnr  TYPE belnr_d,
        gjahr  TYPE gjahr,
        blart  TYPE blart,
        bldat  TYPE bldat,
        budat  TYPE budat,
        monat  TYPE monat,
        waers  TYPE waers,
        bktxt  TYPE bktxt,
        xblnr  TYPE xblnr,
        bstat  TYPE bstat,
        usnam  TYPE usnam,
        items  TYPE ty_journal_items,
      END OF ty_journal_header,
      ty_journals TYPE STANDARD TABLE OF ty_journal_header WITH KEY belnr gjahr,

      " 계정 잔액
      BEGIN OF ty_account_balance,
        saknr      TYPE saknr,
        txt20      TYPE c LENGTH 20,
        gjahr      TYPE gjahr,
        monat      TYPE monat,
        debit_amt  TYPE p LENGTH 15 DECIMALS 2,
        credit_amt TYPE p LENGTH 15 DECIMALS 2,
        balance    TYPE p LENGTH 15 DECIMALS 2,
      END OF ty_account_balance,
      ty_balances TYPE STANDARD TABLE OF ty_account_balance WITH KEY saknr gjahr monat,

      " 시산표
      BEGIN OF ty_trial_balance,
        saknr      TYPE saknr,
        txt50      TYPE c LENGTH 50,
        ktoks      TYPE ktoks,
        xbilk      TYPE xbilk,
        open_bal   TYPE p LENGTH 15 DECIMALS 2,
        debit_ytd  TYPE p LENGTH 15 DECIMALS 2,
        credit_ytd TYPE p LENGTH 15 DECIMALS 2,
        close_bal  TYPE p LENGTH 15 DECIMALS 2,
      END OF ty_trial_balance,
      ty_trial_balances TYPE STANDARD TABLE OF ty_trial_balance WITH KEY saknr.

    " ================================================================
    " GL 계정 마스터 CRUD
    " ================================================================
    METHODS:
      "! 전체 GL 계정 조회
      find_all_accounts
        IMPORTING iv_bukrs           TYPE bukrs
        RETURNING VALUE(rt_accounts) TYPE ty_gl_accounts,

      "! GL 계정 단건 조회
      find_account_by_id
        IMPORTING iv_bukrs           TYPE bukrs
                  iv_saknr           TYPE saknr
        RETURNING VALUE(rs_account)  TYPE ty_gl_account
        RAISING   cx_abap_not_found,

      "! 계정그룹별 조회
      find_accounts_by_group
        IMPORTING iv_bukrs           TYPE bukrs
                  iv_ktoks           TYPE ktoks
        RETURNING VALUE(rt_accounts) TYPE ty_gl_accounts,

      "! GL 계정 생성
      create_account
        IMPORTING is_account         TYPE ty_gl_account
        RETURNING VALUE(rs_account)  TYPE ty_gl_account
        RAISING   cx_sy_dyn_call_error,

      "! GL 계정 수정
      update_account
        IMPORTING iv_bukrs           TYPE bukrs
                  iv_saknr           TYPE saknr
                  is_account         TYPE ty_gl_account
        RETURNING VALUE(rs_account)  TYPE ty_gl_account
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      "! GL 계정 비활성화 (물리삭제 불가, 상태만 변경)
      deactivate_account
        IMPORTING iv_bukrs TYPE bukrs
                  iv_saknr TYPE saknr
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      " ================================================================
      " 회계전표 CRUD
      " ================================================================
      "! 전표 목록 조회 (회계연도+기간 범위)
      find_journals
        IMPORTING iv_bukrs           TYPE bukrs
                  iv_gjahr           TYPE gjahr
                  iv_monat_from      TYPE monat
                  iv_monat_to        TYPE monat
                  iv_blart           TYPE blart OPTIONAL
        RETURNING VALUE(rt_journals) TYPE ty_journals,

      "! 전표 단건 조회 (라인항목 포함)
      find_journal_by_id
        IMPORTING iv_bukrs           TYPE bukrs
                  iv_belnr           TYPE belnr_d
                  iv_gjahr           TYPE gjahr
        RETURNING VALUE(rs_journal)  TYPE ty_journal_header
        RAISING   cx_abap_not_found,

      "! 계정별 라인항목 조회 (FBL3N 기능)
      find_items_by_account
        IMPORTING iv_bukrs           TYPE bukrs
                  iv_saknr           TYPE saknr
                  iv_budat_from      TYPE budat
                  iv_budat_to        TYPE budat
        RETURNING VALUE(rt_items)    TYPE ty_journal_items,

      "! 회계전표 전기 (복식부기 밸런스 검증 포함)
      post_journal
        IMPORTING is_header          TYPE ty_journal_header
        RETURNING VALUE(rs_journal)  TYPE ty_journal_header
        RAISING   cx_sy_dyn_call_error,

      "! 회계전표 역전 (Reversal)
      reverse_journal
        IMPORTING iv_bukrs           TYPE bukrs
                  iv_belnr           TYPE belnr_d
                  iv_gjahr           TYPE gjahr
                  iv_stgrd           TYPE stgrd
                  iv_rev_date        TYPE budat
        RETURNING VALUE(rv_new_belnr) TYPE belnr_d
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      " ================================================================
      " 잔액/보고서 조회
      " ================================================================
      "! 계정별 기간별 잔액 조회
      get_account_balances
        IMPORTING iv_bukrs           TYPE bukrs
                  iv_gjahr           TYPE gjahr
                  iv_monat_from      TYPE monat
                  iv_monat_to        TYPE monat
        RETURNING VALUE(rt_balances) TYPE ty_balances,

      "! 시산표 조회 (Trial Balance)
      get_trial_balance
        IMPORTING iv_bukrs              TYPE bukrs
                  iv_gjahr              TYPE gjahr
                  iv_monat              TYPE monat
        RETURNING VALUE(rt_trial_bal)   TYPE ty_trial_balances.

  PRIVATE SECTION.
    METHODS:
      get_next_belnr
        IMPORTING iv_bukrs          TYPE bukrs
                  iv_blart          TYPE blart
                  iv_gjahr          TYPE gjahr
        RETURNING VALUE(rv_belnr)   TYPE belnr_d,

      validate_balance
        IMPORTING it_items          TYPE ty_journal_items
        RETURNING VALUE(rv_valid)   TYPE abap_bool,

      update_co_actual
        IMPORTING is_header         TYPE ty_journal_header.

ENDCLASS.


CLASS zcl_fi_gl_service IMPLEMENTATION.

  " ================================================================
  " GL 계정 마스터 CRUD
  " ================================================================

  METHOD find_all_accounts.
    SELECT bukrs saknr ktoks xbilk txt20 txt50 waers xopvw gvtyp stat_ind created_by
      FROM zfi_gl_account
      WHERE bukrs = @iv_bukrs
        AND stat_ind <> 'I'
      INTO CORRESPONDING FIELDS OF TABLE @rt_accounts
      ORDER BY saknr.
  ENDMETHOD.

  METHOD find_account_by_id.
    SELECT SINGLE bukrs saknr ktoks xbilk txt20 txt50 waers xopvw gvtyp stat_ind created_by
      FROM zfi_gl_account
      WHERE bukrs = @iv_bukrs AND saknr = @iv_saknr
      INTO CORRESPONDING FIELDS OF @rs_account.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.
  ENDMETHOD.

  METHOD find_accounts_by_group.
    SELECT bukrs saknr ktoks xbilk txt20 txt50 waers xopvw gvtyp stat_ind created_by
      FROM zfi_gl_account
      WHERE bukrs = @iv_bukrs AND ktoks = @iv_ktoks
      INTO CORRESPONDING FIELDS OF TABLE @rt_accounts
      ORDER BY saknr.
  ENDMETHOD.

  METHOD create_account.
    DATA ls_db TYPE zfi_gl_account.
    " 중복 계정 체크
    SELECT COUNT(*) FROM zfi_gl_account
      WHERE bukrs = @is_account-bukrs AND saknr = @is_account-saknr
      INTO @DATA(lv_cnt).
    IF lv_cnt > 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    rs_account = is_account.
    rs_account-stat_ind = 'A'.
    MOVE-CORRESPONDING rs_account TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-created_by = sy-uname.
    GET TIME STAMP FIELD ls_db-created_at.
    INSERT zfi_gl_account FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD update_account.
    " 존재 확인
    find_account_by_id( iv_bukrs = iv_bukrs iv_saknr = iv_saknr ).
    rs_account = is_account.
    rs_account-bukrs = iv_bukrs.
    rs_account-saknr = iv_saknr.
    UPDATE zfi_gl_account
      SET txt20      = @rs_account-txt20,
          txt50      = @rs_account-txt50,
          ktoks      = @rs_account-ktoks,
          xbilk      = @rs_account-xbilk,
          waers      = @rs_account-waers,
          gvtyp      = @rs_account-gvtyp,
          changed_by = @sy-uname
      WHERE bukrs = @iv_bukrs AND saknr = @iv_saknr AND mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD deactivate_account.
    find_account_by_id( iv_bukrs = iv_bukrs iv_saknr = iv_saknr ).
    UPDATE zfi_gl_account
      SET stat_ind   = 'I',
          changed_by = @sy-uname
      WHERE bukrs = @iv_bukrs AND saknr = @iv_saknr AND mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  " ================================================================
  " 회계전표 CRUD
  " ================================================================

  METHOD find_journals.
    " 헤더 조회
    DATA lt_headers TYPE STANDARD TABLE OF zfi_journal_entry.
    DATA lv_blart TYPE blart.
    lv_blart = iv_blart.

    IF lv_blart IS INITIAL.
      SELECT bukrs belnr gjahr blart bldat budat monat waers bktxt xblnr bstat usnam
        FROM zfi_journal_entry
        WHERE bukrs = @iv_bukrs AND gjahr = @iv_gjahr
          AND monat >= @iv_monat_from AND monat <= @iv_monat_to
        INTO CORRESPONDING FIELDS OF TABLE @lt_headers
        ORDER BY budat DESCENDING belnr DESCENDING.
    ELSE.
      SELECT bukrs belnr gjahr blart bldat budat monat waers bktxt xblnr bstat usnam
        FROM zfi_journal_entry
        WHERE bukrs = @iv_bukrs AND gjahr = @iv_gjahr
          AND monat >= @iv_monat_from AND monat <= @iv_monat_to
          AND blart = @lv_blart
        INTO CORRESPONDING FIELDS OF TABLE @lt_headers
        ORDER BY budat DESCENDING belnr DESCENDING.
    ENDIF.

    LOOP AT lt_headers INTO DATA(ls_hdr).
      DATA(ls_journal) = VALUE ty_journal_header(
        bukrs = ls_hdr-bukrs belnr = ls_hdr-belnr gjahr = ls_hdr-gjahr
        blart = ls_hdr-blart bldat = ls_hdr-bldat budat = ls_hdr-budat
        monat = ls_hdr-monat waers = ls_hdr-waers bktxt = ls_hdr-bktxt
        xblnr = ls_hdr-xblnr bstat = ls_hdr-bstat usnam = ls_hdr-usnam ).
      APPEND ls_journal TO rt_journals.
    ENDLOOP.
  ENDMETHOD.

  METHOD find_journal_by_id.
    " 헤더 조회
    SELECT SINGLE bukrs belnr gjahr blart bldat budat monat waers bktxt xblnr bstat usnam
      FROM zfi_journal_entry
      WHERE bukrs = @iv_bukrs AND belnr = @iv_belnr AND gjahr = @iv_gjahr
      INTO CORRESPONDING FIELDS OF @rs_journal.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.
    " 라인항목 조회
    SELECT buzei saknr shkzg dmbtr wrbtr kostl aufnr prctr mwskz sgtxt lifnr kunnr
      FROM zfi_journal_item
      WHERE bukrs = @iv_bukrs AND belnr = @iv_belnr AND gjahr = @iv_gjahr
      INTO CORRESPONDING FIELDS OF TABLE @rs_journal-items
      ORDER BY buzei.
  ENDMETHOD.

  METHOD find_items_by_account.
    SELECT buzei saknr shkzg dmbtr wrbtr kostl aufnr prctr mwskz sgtxt lifnr kunnr
      FROM zfi_journal_item AS i
      INNER JOIN zfi_journal_entry AS h
        ON h~mandt = i~mandt AND h~bukrs = i~bukrs
           AND h~belnr = i~belnr AND h~gjahr = i~gjahr
      WHERE i~bukrs = @iv_bukrs AND i~saknr = @iv_saknr
        AND h~budat >= @iv_budat_from AND h~budat <= @iv_budat_to
      INTO CORRESPONDING FIELDS OF TABLE @rt_items
      ORDER BY h~budat DESCENDING.
  ENDMETHOD.

  METHOD post_journal.
    " 1. 밸런스 검증 (차변합계 = 대변합계)
    IF validate_balance( is_header-items ) = abap_false.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.

    " 2. 전표번호 채번
    rs_journal = is_header.
    rs_journal-belnr = get_next_belnr(
      iv_bukrs = is_header-bukrs
      iv_blart = is_header-blart
      iv_gjahr = is_header-gjahr ).
    rs_journal-usnam = sy-uname.

    " 3. 회계기간 산출 (전기일에서 월 추출)
    rs_journal-monat = rs_journal-budat+4(2).

    " 4. 헤더 INSERT
    DATA ls_hdr TYPE zfi_journal_entry.
    MOVE-CORRESPONDING rs_journal TO ls_hdr.
    ls_hdr-mandt = sy-mandt.
    ls_hdr-cpudt = sy-datum.
    ls_hdr-cputm = sy-uzeit.
    ls_hdr-tcode = sy-tcode.
    INSERT zfi_journal_entry FROM ls_hdr.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.

    " 5. 라인항목 INSERT
    DATA ls_item TYPE zfi_journal_item.
    LOOP AT rs_journal-items ASSIGNING FIELD-SYMBOL(<item>).
      MOVE-CORRESPONDING <item> TO ls_item.
      ls_item-mandt = sy-mandt.
      ls_item-bukrs = rs_journal-bukrs.
      ls_item-belnr = rs_journal-belnr.
      ls_item-gjahr = rs_journal-gjahr.
      " 세액 자동계산 (세금코드 V1=10% 부가세)
      IF ls_item-mwskz = 'V1'.
        ls_item-wmwst = ls_item-wrbtr * '0.1'.
        ls_item-mwsts = ls_item-dmbtr * '0.1'.
      ENDIF.
      INSERT zfi_journal_item FROM ls_item.
    ENDLOOP.

    " 6. CO 실적 데이터 생성 (코스트센터/내부오더 있는 항목)
    update_co_actual( rs_journal ).
  ENDMETHOD.

  METHOD reverse_journal.
    " 1. 원 전표 조회
    DATA(ls_orig) = find_journal_by_id(
      iv_bukrs = iv_bukrs iv_belnr = iv_belnr iv_gjahr = iv_gjahr ).

    " 2. 이미 역전된 전표 체크
    IF ls_orig-bstat = 'S'.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.

    " 3. 역전 전표 생성 (차/대변 반전)
    DATA ls_rev TYPE ty_journal_header.
    ls_rev = ls_orig.
    ls_rev-bldat = iv_rev_date.
    ls_rev-budat = iv_rev_date.
    ls_rev-monat = iv_rev_date+4(2).
    ls_rev-xblnr = iv_belnr.
    ls_rev-bktxt = |역전:{ iv_belnr }|.
    CLEAR ls_rev-belnr.

    " 차/대변 반전
    LOOP AT ls_rev-items ASSIGNING FIELD-SYMBOL(<item>).
      IF <item>-shkzg = 'S'.
        <item>-shkzg = 'H'.
      ELSE.
        <item>-shkzg = 'S'.
      ENDIF.
    ENDLOOP.

    " 4. 역전 전표 전기
    DATA(ls_posted) = post_journal( ls_rev ).
    rv_new_belnr = ls_posted-belnr.

    " 5. 원 전표에 역전 표시
    UPDATE zfi_journal_entry
      SET bstat = 'S',
          stblg = @rv_new_belnr,
          stjah = @iv_gjahr,
          stgrd = @iv_stgrd
      WHERE bukrs = @iv_bukrs AND belnr = @iv_belnr AND gjahr = @iv_gjahr
        AND mandt = @sy-mandt.
  ENDMETHOD.

  " ================================================================
  " 잔액/보고서 조회
  " ================================================================

  METHOD get_account_balances.
    SELECT i~saknr
           SUM( CASE i~shkzg WHEN 'S' THEN i~dmbtr ELSE 0 END ) AS debit_amt
           SUM( CASE i~shkzg WHEN 'H' THEN i~dmbtr ELSE 0 END ) AS credit_amt
           h~gjahr h~monat
      FROM zfi_journal_item AS i
      INNER JOIN zfi_journal_entry AS h
        ON h~mandt = i~mandt AND h~bukrs = i~bukrs
           AND h~belnr = i~belnr AND h~gjahr = i~gjahr
      WHERE i~bukrs = @iv_bukrs AND h~gjahr = @iv_gjahr
        AND h~monat >= @iv_monat_from AND h~monat <= @iv_monat_to
      GROUP BY i~saknr h~gjahr h~monat
      INTO CORRESPONDING FIELDS OF TABLE @rt_balances
      ORDER BY i~saknr h~monat.

    LOOP AT rt_balances ASSIGNING FIELD-SYMBOL(<bal>).
      <bal>-balance = <bal>-debit_amt - <bal>-credit_amt.
      " GL 계정명 추가
      SELECT SINGLE txt20 FROM zfi_gl_account
        WHERE bukrs = @iv_bukrs AND saknr = @<bal>-saknr
        INTO @<bal>-txt20.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_trial_balance.
    DATA lt_items TYPE STANDARD TABLE OF zfi_journal_item.

    " 전기이월 잔액 (전년도 누적)
    SELECT i~saknr
           SUM( CASE i~shkzg WHEN 'S' THEN i~dmbtr ELSE -1 * i~dmbtr END ) AS open_bal
      FROM zfi_journal_item AS i
      INNER JOIN zfi_journal_entry AS h
        ON h~mandt = i~mandt AND h~bukrs = i~bukrs
           AND h~belnr = i~belnr AND h~gjahr = i~gjahr
      WHERE i~bukrs = @iv_bukrs AND h~gjahr < @iv_gjahr
      GROUP BY i~saknr
      INTO TABLE @DATA(lt_prev).

    " 당기 차변/대변
    SELECT i~saknr
           SUM( CASE i~shkzg WHEN 'S' THEN i~dmbtr ELSE 0 END ) AS debit_ytd
           SUM( CASE i~shkzg WHEN 'H' THEN i~dmbtr ELSE 0 END ) AS credit_ytd
      FROM zfi_journal_item AS i
      INNER JOIN zfi_journal_entry AS h
        ON h~mandt = i~mandt AND h~bukrs = i~bukrs
           AND h~belnr = i~belnr AND h~gjahr = i~gjahr
      WHERE i~bukrs = @iv_bukrs AND h~gjahr = @iv_gjahr AND h~monat <= @iv_monat
      GROUP BY i~saknr
      INTO TABLE @DATA(lt_curr).

    " 계정 마스터 JOIN 및 시산표 구성
    SELECT saknr txt50 ktoks xbilk FROM zfi_gl_account
      WHERE bukrs = @iv_bukrs AND stat_ind = 'A'
      INTO TABLE @DATA(lt_acct)
      ORDER BY saknr.

    LOOP AT lt_acct INTO DATA(ls_acct).
      DATA(ls_tb) = VALUE ty_trial_balance(
        saknr = ls_acct-saknr txt50 = ls_acct-txt50
        ktoks = ls_acct-ktoks xbilk = ls_acct-xbilk ).

      READ TABLE lt_prev INTO DATA(ls_prev) WITH KEY saknr = ls_acct-saknr.
      IF sy-subrc = 0.
        ls_tb-open_bal = ls_prev-open_bal.
      ENDIF.

      READ TABLE lt_curr INTO DATA(ls_curr) WITH KEY saknr = ls_acct-saknr.
      IF sy-subrc = 0.
        ls_tb-debit_ytd  = ls_curr-debit_ytd.
        ls_tb-credit_ytd = ls_curr-credit_ytd.
      ENDIF.

      ls_tb-close_bal = ls_tb-open_bal + ls_tb-debit_ytd - ls_tb-credit_ytd.

      " 잔액 있는 계정만 추가
      IF ls_tb-debit_ytd <> 0 OR ls_tb-credit_ytd <> 0 OR ls_tb-open_bal <> 0.
        APPEND ls_tb TO rt_trial_balances.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  " ================================================================
  " Private 메서드
  " ================================================================

  METHOD get_next_belnr.
    " 전표유형별 번호범위 관리
    DATA lv_range_from TYPE belnr_d.
    DATA lv_range_to   TYPE belnr_d.
    CASE iv_blart.
      WHEN 'SA'. lv_range_from = '1000000000'. lv_range_to = '1999999999'.
      WHEN 'KR'. lv_range_from = '5100000000'. lv_range_to = '5199999999'.
      WHEN 'DR'. lv_range_from = '1800000000'. lv_range_to = '1899999999'.
      WHEN 'ZP'. lv_range_from = '1500000000'. lv_range_to = '1599999999'.
      WHEN 'ZE'. lv_range_from = '1400000000'. lv_range_to = '1499999999'.
      WHEN 'AB'. lv_range_from = '9900000000'. lv_range_to = '9999999999'.
      WHEN OTHERS. lv_range_from = '2000000000'. lv_range_to = '2999999999'.
    ENDCASE.

    SELECT MAX( belnr ) FROM zfi_journal_entry
      WHERE bukrs = @iv_bukrs AND gjahr = @iv_gjahr
        AND belnr >= @lv_range_from AND belnr <= @lv_range_to
      INTO @DATA(lv_max).

    rv_belnr = COND #( WHEN lv_max IS NOT INITIAL THEN lv_max + 1
                       ELSE lv_range_from ).
  ENDMETHOD.

  METHOD validate_balance.
    DATA lv_debit  TYPE p LENGTH 15 DECIMALS 2.
    DATA lv_credit TYPE p LENGTH 15 DECIMALS 2.
    LOOP AT it_items INTO DATA(ls_item).
      IF ls_item-shkzg = 'S'.
        lv_debit = lv_debit + ls_item-dmbtr.
      ELSE.
        lv_credit = lv_credit + ls_item-dmbtr.
      ENDIF.
    ENDLOOP.
    rv_valid = COND #( WHEN lv_debit = lv_credit THEN abap_true ELSE abap_false ).
  ENDMETHOD.

  METHOD update_co_actual.
    " FI 전기 시 CO 실적 라인아이템 자동 생성
    DATA ls_co TYPE zco_actual_line.
    DATA lv_docno TYPE c LENGTH 10.

    " CO 전표번호 채번
    SELECT MAX( co_docno ) FROM zco_actual_line
      WHERE kokrs = 'Z001' AND gjahr = @is_header-gjahr
      INTO @lv_docno.
    lv_docno = COND #( WHEN lv_docno IS NOT INITIAL THEN lv_docno + 1 ELSE '1000000001' ).

    DATA lv_itemno TYPE n LENGTH 3 VALUE 1.
    LOOP AT is_header-items INTO DATA(ls_item).
      IF ls_item-kostl IS NOT INITIAL OR ls_item-aufnr IS NOT INITIAL.
        ls_co-mandt     = sy-mandt.
        ls_co-kokrs     = 'Z001'.
        ls_co-gjahr     = is_header-gjahr.
        ls_co-co_docno  = lv_docno.
        ls_co-co_itemno = lv_itemno.
        ls_co-kostl     = ls_item-kostl.
        ls_co-aufnr     = ls_item-aufnr.
        ls_co-prctr     = ls_item-prctr.
        ls_co-kstar     = ls_item-saknr.
        ls_co-belnr     = is_header-belnr.
        ls_co-bukrs     = is_header-bukrs.
        ls_co-bldat     = is_header-bldat.
        ls_co-budat     = is_header-budat.
        ls_co-monat     = is_header-monat.
        ls_co-wkgbtr    = COND #( WHEN ls_item-shkzg = 'S' THEN ls_item-dmbtr
                                  ELSE -1 * ls_item-dmbtr ).
        ls_co-twaer     = is_header-waers.
        ls_co-wrttp     = '04'.
        ls_co-lifnr     = ls_item-lifnr.
        ls_co-sgtxt     = ls_item-sgtxt.
        ls_co-usnam     = sy-uname.
        INSERT zco_actual_line FROM ls_co.
        lv_itemno = lv_itemno + 1.

        " 내부오더 실적원가 갱신
        IF ls_item-aufnr IS NOT INITIAL.
          UPDATE zco_internal_order
            SET actual_cost = actual_cost + @ls_co-wkgbtr
            WHERE kokrs = 'Z001' AND aufnr = @ls_item-aufnr AND mandt = @sy-mandt.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
