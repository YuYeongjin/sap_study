*&---------------------------------------------------------------------*
*& Report: ZFI_AP_AR_REPORT
*& Description: AP/AR 통합 조회 리포트 (연령분석 + 미결항목)
*& Transaction: SE38 → ZFI_AP_AR_REPORT
*& 기능: AP 연령분석, AR 연령분석, 미결 AP/AR 목록, 지급/수금 현황
*&---------------------------------------------------------------------*
REPORT zfi_ap_ar_report.

" ================================================================
" 선택화면
" ================================================================
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS:
    p_bukrs TYPE bukrs DEFAULT 'Z001' OBLIGATORY,
    p_gjahr TYPE gjahr DEFAULT '2026',
    p_kdate TYPE datum DEFAULT sy-datum.           " 기준일 (연령분석)
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS:
    p_mode TYPE c LENGTH 1 DEFAULT '1'.            " 조회 모드
    " 1: AP 연령분석
    " 2: AR 연령분석
    " 3: 미결 AP 목록 (만기일 기준)
    " 4: 미결 AR 목록 (만기일 기준)
    " 5: AP/AR 잔액 대사
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
  PARAMETERS:
    p_lifnr TYPE lifnr OPTIONAL,                   " 벤더 (AP)
    p_kunnr TYPE kunnr OPTIONAL.                   " 고객 (AR)
SELECTION-SCREEN END OF BLOCK b3.

" ================================================================
" 타입 정의
" ================================================================
TYPES:
  " AP 연령분석 ALV
  BEGIN OF ty_ap_aging_alv,
    lifnr       TYPE lifnr,
    vend_name   TYPE name1,
    total_open  TYPE p LENGTH 15 DECIMALS 2,
    not_due     TYPE p LENGTH 15 DECIMALS 2,
    od_30       TYPE p LENGTH 15 DECIMALS 2,
    od_60       TYPE p LENGTH 15 DECIMALS 2,
    od_90       TYPE p LENGTH 15 DECIMALS 2,
    od_90p      TYPE p LENGTH 15 DECIMALS 2,
    risk_flag   TYPE c LENGTH 1,                   " H:고위험, M:중위험
  END OF ty_ap_aging_alv,

  " AR 연령분석 ALV
  BEGIN OF ty_ar_aging_alv,
    kunnr       TYPE kunnr,
    cust_name   TYPE name1,
    total_open  TYPE p LENGTH 15 DECIMALS 2,
    not_due     TYPE p LENGTH 15 DECIMALS 2,
    od_30       TYPE p LENGTH 15 DECIMALS 2,
    od_60       TYPE p LENGTH 15 DECIMALS 2,
    od_90       TYPE p LENGTH 15 DECIMALS 2,
    od_90p      TYPE p LENGTH 15 DECIMALS 2,
    bad_debt_risk TYPE c LENGTH 1,
  END OF ty_ar_aging_alv,

  " 미결 AP 목록
  BEGIN OF ty_open_ap,
    ap_invno    TYPE c LENGTH 10,
    lifnr       TYPE lifnr,
    vend_name   TYPE name1,
    bldat       TYPE bldat,
    due_date    TYPE datum,
    overdue_days TYPE i,
    gross_amt   TYPE p LENGTH 15 DECIMALS 2,
    paid_amt    TYPE p LENGTH 15 DECIMALS 2,
    open_amt    TYPE p LENGTH 15 DECIMALS 2,
    pay_status  TYPE c LENGTH 1,
    ap_type     TYPE c LENGTH 4,
    traffic_light TYPE c LENGTH 1,
  END OF ty_open_ap,

  " 미결 AR 목록
  BEGIN OF ty_open_ar,
    ar_invno    TYPE c LENGTH 10,
    kunnr       TYPE kunnr,
    cust_name   TYPE name1,
    bldat       TYPE bldat,
    due_date    TYPE datum,
    overdue_days TYPE i,
    gross_amt   TYPE p LENGTH 15 DECIMALS 2,
    rcvd_amt    TYPE p LENGTH 15 DECIMALS 2,
    open_amt    TYPE p LENGTH 15 DECIMALS 2,
    rcv_status  TYPE c LENGTH 1,
    contract_no TYPE c LENGTH 20,
    traffic_light TYPE c LENGTH 1,
  END OF ty_open_ar.

" ================================================================
" 전역 데이터
" ================================================================
DATA:
  go_alv     TYPE REF TO cl_salv_table,
  go_columns TYPE REF TO cl_salv_columns_table,
  go_display TYPE REF TO cl_salv_display_settings,
  go_aggr    TYPE REF TO cl_salv_aggregations,
  go_sorts   TYPE REF TO cl_salv_sorts.

" ================================================================
" START-OF-SELECTION
" ================================================================
START-OF-SELECTION.
  CASE p_mode.
    WHEN '1'. PERFORM show_ap_aging.
    WHEN '2'. PERFORM show_ar_aging.
    WHEN '3'. PERFORM show_open_ap.
    WHEN '4'. PERFORM show_open_ar.
    WHEN '5'. PERFORM show_balance_reconciliation.
    WHEN OTHERS.
      MESSAGE '조회 모드를 선택하세요 (1~5)' TYPE 'E'.
  ENDCASE.

" ================================================================
" FORM: AP 연령분석
" ================================================================
FORM show_ap_aging.
  DATA lt_alv TYPE STANDARD TABLE OF ty_ap_aging_alv.
  DATA ls_alv TYPE ty_ap_aging_alv.

  SELECT ap~lifnr v~name1
         SUM( ap~gross_amount - ap~paid_amount ) AS total_open
    FROM zfi_ap_invoice AS ap
    LEFT JOIN zfi_vendor AS v ON v~lifnr = ap~lifnr AND v~bukrs = ap~bukrs
    WHERE ap~bukrs = @p_bukrs AND ap~pay_status IN (' ', 'P')
      AND ( @p_lifnr IS INITIAL OR ap~lifnr = @p_lifnr )
    GROUP BY ap~lifnr v~name1
    INTO TABLE @DATA(lt_base)
    ORDER BY ap~lifnr.

  LOOP AT lt_base INTO DATA(ls_b).
    CLEAR ls_alv.
    ls_alv-lifnr     = ls_b-lifnr.
    ls_alv-vend_name = ls_b-name1.
    ls_alv-total_open = ls_b-total_open.

    SELECT SUM( gross_amount - paid_amount ) FROM zfi_ap_invoice
      WHERE bukrs = @p_bukrs AND lifnr = @ls_b-lifnr
        AND pay_status IN (' ', 'P') AND due_date >= @p_kdate
      INTO @ls_alv-not_due.
    SELECT SUM( gross_amount - paid_amount ) FROM zfi_ap_invoice
      WHERE bukrs = @p_bukrs AND lifnr = @ls_b-lifnr
        AND pay_status IN (' ', 'P')
        AND due_date >= p_kdate - 30 AND due_date < @p_kdate
      INTO @ls_alv-od_30.
    SELECT SUM( gross_amount - paid_amount ) FROM zfi_ap_invoice
      WHERE bukrs = @p_bukrs AND lifnr = @ls_b-lifnr
        AND pay_status IN (' ', 'P')
        AND due_date >= p_kdate - 60 AND due_date < p_kdate - 30
      INTO @ls_alv-od_60.
    SELECT SUM( gross_amount - paid_amount ) FROM zfi_ap_invoice
      WHERE bukrs = @p_bukrs AND lifnr = @ls_b-lifnr
        AND pay_status IN (' ', 'P')
        AND due_date >= p_kdate - 90 AND due_date < p_kdate - 60
      INTO @ls_alv-od_90.
    SELECT SUM( gross_amount - paid_amount ) FROM zfi_ap_invoice
      WHERE bukrs = @p_bukrs AND lifnr = @ls_b-lifnr
        AND pay_status IN (' ', 'P') AND due_date < p_kdate - 90
      INTO @ls_alv-od_90p.

    " 위험 등급
    ls_alv-risk_flag = COND #(
      WHEN ls_alv-od_90p > 0 THEN 'H'
      WHEN ls_alv-od_60 > 0  THEN 'M'
      ELSE ' ' ).

    APPEND ls_alv TO lt_alv.
  ENDLOOP.

  " ALV 출력
  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv
        CHANGING  t_table      = lt_alv ).
      go_display = go_alv->get_display_settings( ).
      go_display->set_striped_pattern( abap_true ).
      go_display->set_list_header( 'AP 연령분석 (Accounts Payable Aging)' ).

      go_columns = go_alv->get_columns( ).
      go_columns->set_optimize( abap_true ).
      " 컬럼 헤더 설정
      DATA(lo_col) = go_columns->get_column( 'LIFNR' ).
      lo_col->set_long_text( '벤더번호' ).
      lo_col = go_columns->get_column( 'VEND_NAME' ).
      lo_col->set_long_text( '벤더명' ).
      lo_col = go_columns->get_column( 'TOTAL_OPEN' ).
      lo_col->set_long_text( '미결잔액 합계' ).
      lo_col = go_columns->get_column( 'NOT_DUE' ).
      lo_col->set_long_text( '미도래' ).
      lo_col = go_columns->get_column( 'OD_30' ).
      lo_col->set_long_text( '1~30일 연체' ).
      lo_col = go_columns->get_column( 'OD_60' ).
      lo_col->set_long_text( '31~60일 연체' ).
      lo_col = go_columns->get_column( 'OD_90' ).
      lo_col->set_long_text( '61~90일 연체' ).
      lo_col = go_columns->get_column( 'OD_90P' ).
      lo_col->set_long_text( '90일 초과' ).

      " 합계행
      go_aggr = go_alv->get_aggregations( ).
      go_aggr->add_aggregation( columnname = 'TOTAL_OPEN' aggregation = if_salv_c_aggregation=>total ).
      go_aggr->add_aggregation( columnname = 'NOT_DUE'   aggregation = if_salv_c_aggregation=>total ).
      go_aggr->add_aggregation( columnname = 'OD_30'     aggregation = if_salv_c_aggregation=>total ).
      go_aggr->add_aggregation( columnname = 'OD_60'     aggregation = if_salv_c_aggregation=>total ).
      go_aggr->add_aggregation( columnname = 'OD_90'     aggregation = if_salv_c_aggregation=>total ).
      go_aggr->add_aggregation( columnname = 'OD_90P'    aggregation = if_salv_c_aggregation=>total ).

      go_alv->display( ).
    CATCH cx_salv_msg INTO DATA(lx).
      MESSAGE lx->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.

" ================================================================
" FORM: AR 연령분석
" ================================================================
FORM show_ar_aging.
  DATA lt_alv TYPE STANDARD TABLE OF ty_ar_aging_alv.

  SELECT ar~kunnr c~name1
         SUM( ar~gross_amount - ar~rcvd_amount ) AS total_open
    FROM zfi_ar_invoice AS ar
    LEFT JOIN zfi_customer AS c ON c~kunnr = ar~kunnr AND c~bukrs = ar~bukrs
    WHERE ar~bukrs = @p_bukrs AND ar~rcv_status IN (' ', 'P')
      AND ( @p_kunnr IS INITIAL OR ar~kunnr = @p_kunnr )
    GROUP BY ar~kunnr c~name1
    INTO TABLE @DATA(lt_base).

  LOOP AT lt_base INTO DATA(ls_b).
    DATA ls_alv TYPE ty_ar_aging_alv.
    ls_alv-kunnr = ls_b-kunnr.
    ls_alv-cust_name = ls_b-name1.
    ls_alv-total_open = ls_b-total_open.

    SELECT SUM( gross_amount - rcvd_amount ) FROM zfi_ar_invoice
      WHERE bukrs = @p_bukrs AND kunnr = @ls_b-kunnr
        AND rcv_status IN (' ', 'P') AND due_date >= @p_kdate
      INTO @ls_alv-not_due.
    SELECT SUM( gross_amount - rcvd_amount ) FROM zfi_ar_invoice
      WHERE bukrs = @p_bukrs AND kunnr = @ls_b-kunnr
        AND rcv_status IN (' ', 'P')
        AND due_date >= p_kdate - 30 AND due_date < @p_kdate
      INTO @ls_alv-od_30.
    SELECT SUM( gross_amount - rcvd_amount ) FROM zfi_ar_invoice
      WHERE bukrs = @p_bukrs AND kunnr = @ls_b-kunnr
        AND rcv_status IN (' ', 'P')
        AND due_date >= p_kdate - 60 AND due_date < p_kdate - 30
      INTO @ls_alv-od_60.
    SELECT SUM( gross_amount - rcvd_amount ) FROM zfi_ar_invoice
      WHERE bukrs = @p_bukrs AND kunnr = @ls_b-kunnr
        AND rcv_status IN (' ', 'P')
        AND due_date >= p_kdate - 90 AND due_date < p_kdate - 60
      INTO @ls_alv-od_90.
    SELECT SUM( gross_amount - rcvd_amount ) FROM zfi_ar_invoice
      WHERE bukrs = @p_bukrs AND kunnr = @ls_b-kunnr
        AND rcv_status IN (' ', 'P') AND due_date < p_kdate - 90
      INTO @ls_alv-od_90p.

    ls_alv-bad_debt_risk = COND #(
      WHEN ls_alv-od_90p > 0 THEN 'H'
      WHEN ls_alv-od_60 > 0  THEN 'M'
      ELSE ' ' ).
    APPEND ls_alv TO lt_alv.
  ENDLOOP.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv CHANGING t_table = lt_alv ).
      go_display = go_alv->get_display_settings( ).
      go_display->set_striped_pattern( abap_true ).
      go_display->set_list_header( 'AR 연령분석 (Accounts Receivable Aging)' ).
      go_columns = go_alv->get_columns( ).
      go_columns->set_optimize( abap_true ).
      go_aggr = go_alv->get_aggregations( ).
      go_aggr->add_aggregation( columnname = 'TOTAL_OPEN' aggregation = if_salv_c_aggregation=>total ).
      go_aggr->add_aggregation( columnname = 'OD_90P'     aggregation = if_salv_c_aggregation=>total ).
      go_alv->display( ).
    CATCH cx_salv_msg INTO DATA(lx).
      MESSAGE lx->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.

" ================================================================
" FORM: 미결 AP 목록
" ================================================================
FORM show_open_ap.
  DATA lt_alv TYPE STANDARD TABLE OF ty_open_ap.

  SELECT ap~ap_invno ap~lifnr v~name1 ap~bldat ap~due_date
         ap~gross_amount ap~paid_amount ap~pay_status ap~ap_type
    FROM zfi_ap_invoice AS ap
    LEFT JOIN zfi_vendor AS v ON v~lifnr = ap~lifnr AND v~bukrs = ap~bukrs
    WHERE ap~bukrs = @p_bukrs AND ap~pay_status IN (' ', 'P')
      AND ( @p_lifnr IS INITIAL OR ap~lifnr = @p_lifnr )
    INTO TABLE @DATA(lt_raw)
    ORDER BY ap~due_date.

  LOOP AT lt_raw INTO DATA(ls_r).
    DATA ls_alv TYPE ty_open_ap.
    ls_alv-ap_invno    = ls_r-ap_invno.
    ls_alv-lifnr       = ls_r-lifnr.
    ls_alv-vend_name   = ls_r-name1.
    ls_alv-bldat       = ls_r-bldat.
    ls_alv-due_date    = ls_r-due_date.
    ls_alv-gross_amt   = ls_r-gross_amount.
    ls_alv-paid_amt    = ls_r-paid_amount.
    ls_alv-open_amt    = ls_r-gross_amount - ls_r-paid_amount.
    ls_alv-pay_status  = ls_r-pay_status.
    ls_alv-ap_type     = ls_r-ap_type.
    ls_alv-overdue_days = COND #( WHEN ls_r-due_date < p_kdate
                                  THEN p_kdate - ls_r-due_date ELSE 0 ).
    ls_alv-traffic_light = COND #(
      WHEN ls_alv-overdue_days > 90 THEN '1'   " 빨강
      WHEN ls_alv-overdue_days > 30 THEN '2'   " 노랑
      ELSE '3' ).                               " 초록
    APPEND ls_alv TO lt_alv.
  ENDLOOP.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv CHANGING t_table = lt_alv ).
      go_display = go_alv->get_display_settings( ).
      go_display->set_list_header( |미결 AP 목록 (기준일: { p_kdate })| ).
      go_display->set_striped_pattern( abap_true ).
      go_columns = go_alv->get_columns( ).
      go_columns->set_optimize( abap_true ).
      go_aggr = go_alv->get_aggregations( ).
      go_aggr->add_aggregation( columnname = 'OPEN_AMT' aggregation = if_salv_c_aggregation=>total ).
      go_sorts = go_alv->get_sorts( ).
      go_sorts->add_sort( columnname = 'OVERDUE_DAYS' sortorder = if_salv_c_sort_order=>descending ).
      go_alv->display( ).
    CATCH cx_salv_msg INTO DATA(lx).
      MESSAGE lx->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.

" ================================================================
" FORM: 미결 AR 목록
" ================================================================
FORM show_open_ar.
  DATA lt_alv TYPE STANDARD TABLE OF ty_open_ar.

  SELECT ar~ar_invno ar~kunnr c~name1 ar~bldat ar~due_date
         ar~gross_amount ar~rcvd_amount ar~rcv_status ar~contract_no
    FROM zfi_ar_invoice AS ar
    LEFT JOIN zfi_customer AS c ON c~kunnr = ar~kunnr AND c~bukrs = ar~bukrs
    WHERE ar~bukrs = @p_bukrs AND ar~rcv_status IN (' ', 'P')
      AND ( @p_kunnr IS INITIAL OR ar~kunnr = @p_kunnr )
    INTO TABLE @DATA(lt_raw)
    ORDER BY ar~due_date.

  LOOP AT lt_raw INTO DATA(ls_r).
    DATA ls_alv TYPE ty_open_ar.
    ls_alv-ar_invno    = ls_r-ar_invno.
    ls_alv-kunnr       = ls_r-kunnr.
    ls_alv-cust_name   = ls_r-name1.
    ls_alv-bldat       = ls_r-bldat.
    ls_alv-due_date    = ls_r-due_date.
    ls_alv-gross_amt   = ls_r-gross_amount.
    ls_alv-rcvd_amt    = ls_r-rcvd_amount.
    ls_alv-open_amt    = ls_r-gross_amount - ls_r-rcvd_amount.
    ls_alv-rcv_status  = ls_r-rcv_status.
    ls_alv-contract_no = ls_r-contract_no.
    ls_alv-overdue_days = COND #( WHEN ls_r-due_date < p_kdate
                                  THEN p_kdate - ls_r-due_date ELSE 0 ).
    ls_alv-traffic_light = COND #(
      WHEN ls_alv-overdue_days > 90 THEN '1'
      WHEN ls_alv-overdue_days > 30 THEN '2'
      ELSE '3' ).
    APPEND ls_alv TO lt_alv.
  ENDLOOP.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv CHANGING t_table = lt_alv ).
      go_display = go_alv->get_display_settings( ).
      go_display->set_list_header( |미결 AR 목록 (기준일: { p_kdate })| ).
      go_display->set_striped_pattern( abap_true ).
      go_columns = go_alv->get_columns( ).
      go_columns->set_optimize( abap_true ).
      go_aggr = go_alv->get_aggregations( ).
      go_aggr->add_aggregation( columnname = 'OPEN_AMT' aggregation = if_salv_c_aggregation=>total ).
      go_alv->display( ).
    CATCH cx_salv_msg INTO DATA(lx).
      MESSAGE lx->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.

" ================================================================
" FORM: AP/AR 잔액 대사
" ================================================================
FORM show_balance_reconciliation.
  DATA lv_ap_balance TYPE p LENGTH 15 DECIMALS 2.
  DATA lv_ar_balance TYPE p LENGTH 15 DECIMALS 2.

  " AP 잔액
  SELECT SUM( gross_amount - paid_amount ) FROM zfi_ap_invoice
    WHERE bukrs = @p_bukrs AND pay_status IN (' ', 'P')
    INTO @lv_ap_balance.

  " AR 잔액
  SELECT SUM( gross_amount - rcvd_amount ) FROM zfi_ar_invoice
    WHERE bukrs = @p_bukrs AND rcv_status IN (' ', 'P')
    INTO @lv_ar_balance.

  " 리포트 출력
  WRITE: / '=' TIMES 60.
  WRITE: / '  AP/AR 잔액 대사 리포트'.
  WRITE: / '  회사코드:', p_bukrs, '  기준일:', p_kdate.
  WRITE: / '=' TIMES 60.
  WRITE: / '  미결 매입채무 (AP) 잔액:', lv_ap_balance CURRENCY 'KRW'.
  WRITE: / '  미결 매출채권 (AR) 잔액:', lv_ar_balance CURRENCY 'KRW'.
  WRITE: / '-' TIMES 60.
  WRITE: / '  순 운전자본 (AR - AP):', lv_ar_balance - lv_ap_balance CURRENCY 'KRW'.
  WRITE: / '=' TIMES 60.
ENDFORM.
