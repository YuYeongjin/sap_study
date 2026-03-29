*&---------------------------------------------------------------------*
*& Report: ZCO_VARIANCE_REPORT
*& Description: CO 계획/실적 차이분석 리포트 (통합)
*& Transaction: SE38 → ZCO_VARIANCE_REPORT
*& 기능: 코스트센터 차이분석, 내부오더 예산현황, 수익센터 손익, 전체 요약
*&---------------------------------------------------------------------*
REPORT zco_variance_report.

" ================================================================
" 선택화면
" ================================================================
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS:
    p_kokrs  TYPE kokrs DEFAULT 'Z001' OBLIGATORY,
    p_bukrs  TYPE bukrs DEFAULT 'Z001',
    p_gjahr  TYPE gjahr DEFAULT '2026' OBLIGATORY.
  SELECT-OPTIONS:
    s_monat FOR sy-datum+4(2) DEFAULT '01' TO '12',
    s_kostl FOR kostl OPTIONAL,
    s_aufnr FOR aufnr OPTIONAL.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS:
    p_mode TYPE c LENGTH 1 DEFAULT '1'.
    " 1: 코스트센터 계획/실적 차이분석
    " 2: 내부오더 예산 현황 (신호등)
    " 3: 수익센터 손익 분석
    " 4: 원가요소별 집계 (전사)
    " 5: 프로젝트별 원가 현황
SELECTION-SCREEN END OF BLOCK b2.

" ================================================================
" 타입 정의
" ================================================================
TYPES:
  BEGIN OF ty_cc_var_alv,
    kostl       TYPE kostl,
    ktext       TYPE c LENGTH 20,
    kosar       TYPE kosar,
    kstar       TYPE kstar,
    cel_name    TYPE c LENGTH 20,
    cel_group   TYPE c LENGTH 4,
    plan_amount TYPE p LENGTH 15 DECIMALS 2,
    actual_amt  TYPE p LENGTH 15 DECIMALS 2,
    variance    TYPE p LENGTH 15 DECIMALS 2,
    var_pct     TYPE p LENGTH 5 DECIMALS 2,
    traffic_light TYPE c LENGTH 1,
  END OF ty_cc_var_alv,

  BEGIN OF ty_order_bgt_alv,
    aufnr         TYPE aufnr,
    ktext         TYPE c LENGTH 20,
    auart         TYPE auart,
    order_status  TYPE c LENGTH 2,
    total_budget  TYPE p LENGTH 15 DECIMALS 2,
    actual_cost   TYPE p LENGTH 15 DECIMALS 2,
    commit_cost   TYPE p LENGTH 15 DECIMALS 2,
    avail_budget  TYPE p LENGTH 15 DECIMALS 2,
    used_pct      TYPE p LENGTH 5 DECIMALS 2,
    traffic_light TYPE c LENGTH 1,
  END OF ty_order_bgt_alv,

  BEGIN OF ty_pca_pl_alv,
    prctr         TYPE prctr,
    ktext         TYPE c LENGTH 20,
    pc_type       TYPE c LENGTH 4,
    revenue       TYPE p LENGTH 15 DECIMALS 2,
    direct_cost   TYPE p LENGTH 15 DECIMALS 2,
    indirect_cost TYPE p LENGTH 15 DECIMALS 2,
    total_cost    TYPE p LENGTH 15 DECIMALS 2,
    gross_profit  TYPE p LENGTH 15 DECIMALS 2,
    profit_margin TYPE p LENGTH 5 DECIMALS 2,
    traffic_light TYPE c LENGTH 1,
  END OF ty_pca_pl_alv,

  BEGIN OF ty_proj_cost_alv,
    proj_id     TYPE n LENGTH 10,
    proj_name   TYPE c LENGTH 100,
    budget      TYPE p LENGTH 15 DECIMALS 2,
    actual_cost TYPE p LENGTH 15 DECIMALS 2,
    variance    TYPE p LENGTH 15 DECIMALS 2,
    used_pct    TYPE p LENGTH 5 DECIMALS 2,
    order_cnt   TYPE i,
    traffic_light TYPE c LENGTH 1,
  END OF ty_proj_cost_alv.

" ================================================================
" 전역 변수
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
    WHEN '1'. PERFORM show_cc_variance.
    WHEN '2'. PERFORM show_order_budget.
    WHEN '3'. PERFORM show_pca_pl.
    WHEN '4'. PERFORM show_cost_element_summary.
    WHEN '5'. PERFORM show_project_cost.
    WHEN OTHERS.
      MESSAGE '조회 모드를 선택하세요 (1~5)' TYPE 'E'.
  ENDCASE.

" ================================================================
" FORM: 코스트센터 계획/실적 차이분석
" ================================================================
FORM show_cc_variance.
  DATA lt_alv TYPE STANDARD TABLE OF ty_cc_var_alv.

  " 실적
  SELECT al~kostl cc~ktext cc~kosar al~kstar ce~ktext AS cel_name ce~cel_group
         SUM( al~wkgbtr ) AS actual_amt
    FROM zco_actual_line AS al
    LEFT JOIN zco_cost_center AS cc ON cc~kokrs = al~kokrs AND cc~kostl = al~kostl
    LEFT JOIN zco_cost_element AS ce ON ce~kokrs = al~kokrs AND ce~kstar = al~kstar
    WHERE al~kokrs = @p_kokrs AND al~gjahr = @p_gjahr
      AND al~monat IN @s_monat AND al~wrttp = '04'
      AND ( al~kostl IN @s_kostl OR @s_kostl IS INITIAL )
    GROUP BY al~kostl cc~ktext cc~kosar al~kstar ce~ktext ce~cel_group
    INTO TABLE @DATA(lt_actual)
    ORDER BY al~kostl al~kstar.

  " 계획
  SELECT pl~kostl pl~kstar SUM( pl~plan_amount ) AS plan_amount
    FROM zco_plan_line AS pl
    WHERE pl~kokrs = @p_kokrs AND pl~gjahr = @p_gjahr
      AND pl~monat IN @s_monat AND pl~version = '000'
      AND ( pl~kostl IN @s_kostl OR @s_kostl IS INITIAL )
    GROUP BY pl~kostl pl~kstar
    INTO TABLE @DATA(lt_plan).

  LOOP AT lt_actual INTO DATA(ls_act).
    DATA ls_alv TYPE ty_cc_var_alv.
    ls_alv-kostl     = ls_act-kostl.
    ls_alv-ktext     = ls_act-ktext.
    ls_alv-kosar     = ls_act-kosar.
    ls_alv-kstar     = ls_act-kstar.
    ls_alv-cel_name  = ls_act-cel_name.
    ls_alv-cel_group = ls_act-cel_group.
    ls_alv-actual_amt = ls_act-actual_amt.

    READ TABLE lt_plan INTO DATA(ls_p) WITH KEY kostl = ls_act-kostl kstar = ls_act-kstar.
    IF sy-subrc = 0.
      ls_alv-plan_amount = ls_p-plan_amount.
    ENDIF.

    ls_alv-variance = ls_alv-plan_amount - ls_alv-actual_amt.
    IF ls_alv-plan_amount <> 0.
      ls_alv-var_pct = ( ls_alv-variance / ls_alv-plan_amount ) * 100.
    ENDIF.
    ls_alv-traffic_light = COND #(
      WHEN ls_alv-var_pct < -10 THEN '1'   " 빨강: 10% 초과
      WHEN ls_alv-var_pct < 0   THEN '2'   " 노랑: 초과지출
      ELSE '3' ).                           " 초록: 계획 이하
    APPEND ls_alv TO lt_alv.
  ENDLOOP.

  PERFORM display_alv USING lt_alv 'CL_SALV_TABLE'
    |코스트센터 계획/실적 차이분석 { p_gjahr }년 ({ s_monat-low }~{ s_monat-high }월)|.
ENDFORM.

" ================================================================
" FORM: 내부오더 예산 현황
" ================================================================
FORM show_order_budget.
  DATA lt_alv TYPE STANDARD TABLE OF ty_order_bgt_alv.

  SELECT ord~aufnr ord~ktext ord~auart ord~order_status
         bgt~total_budget ord~actual_cost ord~commit_cost
    FROM zco_internal_order AS ord
    LEFT JOIN zco_budget AS bgt
      ON bgt~kokrs = ord~kokrs AND bgt~aufnr = ord~aufnr AND bgt~gjahr = @p_gjahr
    WHERE ord~kokrs = @p_kokrs AND ord~order_status IN ('RE', 'CR')
      AND ( ord~aufnr IN @s_aufnr OR @s_aufnr IS INITIAL )
    INTO TABLE @DATA(lt_raw)
    ORDER BY ord~aufnr.

  LOOP AT lt_raw INTO DATA(ls_r).
    DATA ls_alv TYPE ty_order_bgt_alv.
    ls_alv-aufnr        = ls_r-aufnr.
    ls_alv-ktext        = ls_r-ktext.
    ls_alv-auart        = ls_r-auart.
    ls_alv-order_status = ls_r-order_status.
    ls_alv-total_budget = ls_r-total_budget.
    ls_alv-actual_cost  = ls_r-actual_cost.
    ls_alv-commit_cost  = ls_r-commit_cost.
    ls_alv-avail_budget = ls_r-total_budget - ls_r-actual_cost - ls_r-commit_cost.
    IF ls_r-total_budget > 0.
      ls_alv-used_pct = ( ls_r-actual_cost / ls_r-total_budget ) * 100.
    ENDIF.
    ls_alv-traffic_light = COND #(
      WHEN ls_alv-avail_budget < 0        THEN '1'   " 빨강: 예산 초과
      WHEN ls_alv-used_pct > 90           THEN '2'   " 노랑: 90% 이상 사용
      ELSE '3' ).                                     " 초록
    APPEND ls_alv TO lt_alv.
  ENDLOOP.

  " 예산 초과 건수 카운트
  DATA lv_overrun TYPE i.
  LOOP AT lt_alv INTO DATA(ls_a) WHERE traffic_light = '1'.
    lv_overrun = lv_overrun + 1.
  ENDLOOP.
  IF lv_overrun > 0.
    MESSAGE |예산 초과 오더 { lv_overrun }건이 있습니다!| TYPE 'W'.
  ENDIF.

  PERFORM display_alv USING lt_alv 'CL_SALV_TABLE'
    |내부오더 예산 현황 { p_gjahr }년|.
ENDFORM.

" ================================================================
" FORM: 수익센터 손익 분석
" ================================================================
FORM show_pca_pl.
  DATA lt_alv TYPE STANDARD TABLE OF ty_pca_pl_alv.

  " 수익센터 기본정보
  SELECT prctr ktext pc_type
    FROM zco_profit_center
    WHERE kokrs = @p_kokrs AND stat_ind = 'A'
    INTO TABLE @DATA(lt_pc).

  LOOP AT lt_pc INTO DATA(ls_pc).
    DATA ls_alv TYPE ty_pca_pl_alv.
    ls_alv-prctr   = ls_pc-prctr.
    ls_alv-ktext   = ls_pc-ktext.
    ls_alv-pc_type = ls_pc-pc_type.

    " 수익 집계
    SELECT SUM( ai~net_amount ) FROM zfi_ar_item AS ai
      INNER JOIN zfi_ar_invoice AS ar ON ar~ar_invno = ai~ar_invno AND ar~bukrs = ai~bukrs
      WHERE ar~prctr = @ls_pc-prctr AND ar~gjahr = @p_gjahr
        AND ar~budat+4(2) IN @s_monat
      INTO @ls_alv-revenue.

    " 원가 집계
    SELECT SUM( CASE ce~cel_group
                  WHEN 'LABR' THEN al~wkgbtr WHEN 'MATL' THEN al~wkgbtr
                  WHEN 'SUBK' THEN al~wkgbtr WHEN 'EQUP' THEN al~wkgbtr
                  ELSE 0 END ) AS direct_cost
           SUM( CASE ce~cel_group
                  WHEN 'OVER' THEN al~wkgbtr WHEN 'IDRT' THEN al~wkgbtr
                  ELSE 0 END ) AS indirect_cost
      FROM zco_actual_line AS al
      LEFT JOIN zco_cost_element AS ce ON ce~kokrs = al~kokrs AND ce~kstar = al~kstar
      WHERE al~kokrs = @p_kokrs AND al~prctr = @ls_pc-prctr AND al~gjahr = @p_gjahr
        AND al~monat IN @s_monat AND al~wrttp = '04'
      INTO ( @ls_alv-direct_cost, @ls_alv-indirect_cost ).

    ls_alv-total_cost   = ls_alv-direct_cost + ls_alv-indirect_cost.
    ls_alv-gross_profit = ls_alv-revenue - ls_alv-total_cost.
    IF ls_alv-revenue > 0.
      ls_alv-profit_margin = ( ls_alv-gross_profit / ls_alv-revenue ) * 100.
    ENDIF.
    ls_alv-traffic_light = COND #(
      WHEN ls_alv-profit_margin < 0  THEN '1'   " 빨강: 손실
      WHEN ls_alv-profit_margin < 5  THEN '2'   " 노랑: 5% 미만
      ELSE '3' ).                               " 초록: 정상

    IF ls_alv-revenue > 0 OR ls_alv-total_cost > 0.
      APPEND ls_alv TO lt_alv.
    ENDIF.
  ENDLOOP.

  PERFORM display_alv USING lt_alv 'CL_SALV_TABLE'
    |수익센터 손익 분석 { p_gjahr }년 ({ s_monat-low }~{ s_monat-high }월)|.
ENDFORM.

" ================================================================
" FORM: 원가요소별 집계 (전사)
" ================================================================
FORM show_cost_element_summary.
  SELECT al~kstar ce~ktext ce~cel_group
         SUM( al~wkgbtr ) AS actual_amt
    FROM zco_actual_line AS al
    LEFT JOIN zco_cost_element AS ce ON ce~kokrs = al~kokrs AND ce~kstar = al~kstar
    WHERE al~kokrs = @p_kokrs AND al~gjahr = @p_gjahr
      AND al~monat IN @s_monat AND al~wrttp = '04'
    GROUP BY al~kstar ce~ktext ce~cel_group
    INTO TABLE @DATA(lt_result)
    ORDER BY ce~cel_group al~kstar.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv CHANGING t_table = lt_result ).
      go_display = go_alv->get_display_settings( ).
      go_display->set_list_header( |원가요소별 집계 { p_gjahr }년| ).
      go_display->set_striped_pattern( abap_true ).
      go_columns = go_alv->get_columns( ).
      go_columns->set_optimize( abap_true ).
      go_aggr = go_alv->get_aggregations( ).
      go_aggr->add_aggregation( columnname = 'ACTUAL_AMT' aggregation = if_salv_c_aggregation=>total ).
      go_alv->display( ).
    CATCH cx_salv_msg INTO DATA(lx).
      MESSAGE lx->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.

" ================================================================
" FORM: 프로젝트별 원가 현황
" ================================================================
FORM show_project_cost.
  DATA lt_alv TYPE STANDARD TABLE OF ty_proj_cost_alv.

  SELECT ord~proj_id proj~project_name
         SUM( bgt~total_budget ) AS budget
         SUM( ord~actual_cost )  AS actual_cost
         COUNT(*) AS order_cnt
    FROM zco_internal_order AS ord
    LEFT JOIN zconstruction_proj AS proj ON proj~project_id = ord~proj_id
    LEFT JOIN zco_budget AS bgt
      ON bgt~kokrs = ord~kokrs AND bgt~aufnr = ord~aufnr AND bgt~gjahr = @p_gjahr
    WHERE ord~kokrs = @p_kokrs AND ord~proj_id IS NOT INITIAL
      AND ( ord~aufnr IN @s_aufnr OR @s_aufnr IS INITIAL )
    GROUP BY ord~proj_id proj~project_name
    INTO TABLE @DATA(lt_raw)
    ORDER BY ord~proj_id.

  LOOP AT lt_raw INTO DATA(ls_r).
    DATA ls_alv TYPE ty_proj_cost_alv.
    ls_alv-proj_id    = ls_r-proj_id.
    ls_alv-proj_name  = ls_r-project_name.
    ls_alv-budget     = ls_r-budget.
    ls_alv-actual_cost = ls_r-actual_cost.
    ls_alv-variance   = ls_r-budget - ls_r-actual_cost.
    ls_alv-order_cnt  = ls_r-order_cnt.
    IF ls_r-budget > 0.
      ls_alv-used_pct = ( ls_r-actual_cost / ls_r-budget ) * 100.
    ENDIF.
    ls_alv-traffic_light = COND #(
      WHEN ls_alv-variance < 0     THEN '1'
      WHEN ls_alv-used_pct > 90    THEN '2'
      ELSE '3' ).
    APPEND ls_alv TO lt_alv.
  ENDLOOP.

  PERFORM display_alv USING lt_alv 'CL_SALV_TABLE'
    |프로젝트별 원가 현황 { p_gjahr }년|.
ENDFORM.

" ================================================================
" FORM: ALV 공통 출력
" ================================================================
FORM display_alv USING pt_table TYPE ANY TABLE pv_dummy TYPE string pv_title TYPE string.
  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv CHANGING t_table = pt_table ).
      go_display = go_alv->get_display_settings( ).
      go_display->set_striped_pattern( abap_true ).
      go_display->set_list_header( pv_title ).
      go_columns = go_alv->get_columns( ).
      go_columns->set_optimize( abap_true ).
      go_alv->display( ).
    CATCH cx_salv_msg INTO DATA(lx).
      MESSAGE lx->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.
