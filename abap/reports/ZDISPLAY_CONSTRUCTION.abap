*&---------------------------------------------------------------------*
*& Program: ZDISPLAY_CONSTRUCTION
*& Description: 건설관리 시스템 조회 프로그램 (ALV 리포트)
*&              - 프로젝트 현황 조회 (Dashboard)
*&              - 자재 재고 현황 (저재고 하이라이트)
*&              - 장비 현황
*&              - 원가 요약
*& SE38 에서 실행
*&---------------------------------------------------------------------*

REPORT zdisplay_construction.

* 선택화면
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS:
  p_mode TYPE c LENGTH 1 DEFAULT '1' OBLIGATORY.
"  1 = 프로젝트 현황
"  2 = 자재 재고
"  3 = 장비 현황
"  4 = 원가 요약
SELECTION-SCREEN COMMENT /1(60) TEXT-002.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-003.
PARAMETERS:
  p_proj TYPE n LENGTH 10.   " 프로젝트 ID (선택)
SELECT-OPTIONS:
  s_status FOR zconstruction_proj-status,
  s_type   FOR zconstruction_proj-project_type.
SELECTION-SCREEN END OF BLOCK b2.

* ALV 타입 정의
TYPES:
  BEGIN OF ty_project_alv,
    project_id    TYPE n LENGTH 10,
    project_code  TYPE c LENGTH 20,
    project_name  TYPE c LENGTH 200,
    location      TYPE c LENGTH 50,
    client        TYPE c LENGTH 50,
    project_type  TYPE c LENGTH 20,
    status        TYPE c LENGTH 20,
    contract_amt  TYPE p LENGTH 15 DECIMALS 2,
    actual_cost   TYPE p LENGTH 15 DECIMALS 2,
    progress_rate TYPE p LENGTH 5 DECIMALS 1,
    site_manager  TYPE c LENGTH 20,
    budget_rate   TYPE p LENGTH 5 DECIMALS 1,   " 집행률
  END OF ty_project_alv,
  ty_projects_alv TYPE STANDARD TABLE OF ty_project_alv WITH EMPTY KEY,

  BEGIN OF ty_material_alv,
    material_code  TYPE c LENGTH 20,
    material_name  TYPE c LENGTH 100,
    category       TYPE c LENGTH 20,
    unit           TYPE t006-msehi,
    standard_price TYPE p LENGTH 15 DECIMALS 2,
    stock_qty      TYPE p LENGTH 13 DECIMALS 3,
    safety_stock   TYPE p LENGTH 13 DECIMALS 3,
    is_low_stock   TYPE c LENGTH 1,            " X = 재고부족
    primary_vendor TYPE c LENGTH 50,
  END OF ty_material_alv,
  ty_materials_alv TYPE STANDARD TABLE OF ty_material_alv WITH EMPTY KEY,

  BEGIN OF ty_equipment_alv,
    equipment_code  TYPE c LENGTH 20,
    equipment_name  TYPE c LENGTH 100,
    equipment_type  TYPE c LENGTH 20,
    model           TYPE c LENGTH 50,
    status          TYPE c LENGTH 20,
    current_project TYPE c LENGTH 30,
    is_rented       TYPE c LENGTH 1,
    total_op_hours  TYPE p LENGTH 10 DECIMALS 1,
    next_maint_date TYPE datum,
  END OF ty_equipment_alv,
  ty_equipments_alv TYPE STANDARD TABLE OF ty_equipment_alv WITH EMPTY KEY,

  BEGIN OF ty_cost_alv,
    project_name  TYPE c LENGTH 100,
    cost_type     TYPE c LENGTH 20,
    total_amount  TYPE p LENGTH 15 DECIMALS 2,
    entry_count   TYPE i,
  END OF ty_cost_alv,
  ty_costs_alv TYPE STANDARD TABLE OF ty_cost_alv WITH EMPTY KEY.

* 전역 변수
DATA:
  go_alv      TYPE REF TO cl_salv_table,
  go_columns  TYPE REF TO cl_salv_columns_table,
  go_column   TYPE REF TO cl_salv_column_table,
  go_display  TYPE REF TO cl_salv_display_settings,
  go_sorts    TYPE REF TO cl_salv_sorts,
  go_aggrs    TYPE REF TO cl_salv_aggregations,
  go_funcs    TYPE REF TO cl_salv_functions.


START-OF-SELECTION.
  CASE p_mode.
    WHEN '1'. PERFORM display_projects.
    WHEN '2'. PERFORM display_materials.
    WHEN '3'. PERFORM display_equipment.
    WHEN '4'. PERFORM display_cost_summary.
    WHEN OTHERS.
      MESSAGE '모드를 1~4 중에서 선택하세요.' TYPE 'E'.
  ENDCASE.

*&---------------------------------------------------------------------*
*& Form display_projects - 프로젝트 현황 ALV
*&---------------------------------------------------------------------*
FORM display_projects.
  DATA lt_alv TYPE ty_projects_alv.
  DATA ls_alv TYPE ty_project_alv.

  SELECT project_id project_code project_name location client
         project_type status contract_amt actual_cost progress_rate site_manager
    FROM zconstruction_proj
    WHERE status IN @s_status
      AND project_type IN @s_type
      AND ( @p_proj = 0 OR project_id = @p_proj )
    INTO TABLE @DATA(lt_raw)
    ORDER BY project_id.

  LOOP AT lt_raw INTO DATA(ls_raw).
    CLEAR ls_alv.
    MOVE-CORRESPONDING ls_raw TO ls_alv.
    ls_alv-location = ls_raw-location(50).
    ls_alv-client   = ls_raw-client(50).
    ls_alv-site_manager = ls_raw-site_manager(20).
    IF ls_raw-contract_amt > 0.
      ls_alv-budget_rate = ls_raw-actual_cost * 100 / ls_raw-contract_amt.
    ENDIF.
    APPEND ls_alv TO lt_alv.
  ENDLOOP.

  " 집계: 전체 계약금액, 실적원가 합계 출력
  DATA lv_total_contract TYPE p LENGTH 15 DECIMALS 2.
  DATA lv_total_actual   TYPE p LENGTH 15 DECIMALS 2.
  LOOP AT lt_alv INTO ls_alv.
    lv_total_contract = lv_total_contract + ls_alv-contract_amt.
    lv_total_actual   = lv_total_actual   + ls_alv-actual_cost.
  ENDLOOP.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv
        CHANGING  t_table      = lt_alv ).

      " 컬럼 레이블 설정
      go_columns = go_alv->get_columns( ).
      go_columns->set_optimize( abap_true ).

      DATA(lo_col) = CAST cl_salv_column_table(
        go_columns->get_column( 'PROJECT_ID' ) ).
      lo_col->set_short_text( '프로ID' ).
      lo_col->set_medium_text( '프로젝트ID' ).

      lo_col = CAST cl_salv_column_table( go_columns->get_column( 'PROJECT_CODE' ) ).
      lo_col->set_short_text( '프로코드' ).

      lo_col = CAST cl_salv_column_table( go_columns->get_column( 'PROJECT_NAME' ) ).
      lo_col->set_short_text( '프로젝트명' ).
      lo_col->set_long_text( '프로젝트명' ).

      lo_col = CAST cl_salv_column_table( go_columns->get_column( 'STATUS' ) ).
      lo_col->set_short_text( '상태' ).

      lo_col = CAST cl_salv_column_table( go_columns->get_column( 'CONTRACT_AMT' ) ).
      lo_col->set_short_text( '계약금액' ).
      lo_col->set_currency( 'KRW' ).

      lo_col = CAST cl_salv_column_table( go_columns->get_column( 'ACTUAL_COST' ) ).
      lo_col->set_short_text( '실적원가' ).
      lo_col->set_currency( 'KRW' ).

      lo_col = CAST cl_salv_column_table( go_columns->get_column( 'PROGRESS_RATE' ) ).
      lo_col->set_short_text( '진행률(%)' ).

      lo_col = CAST cl_salv_column_table( go_columns->get_column( 'BUDGET_RATE' ) ).
      lo_col->set_short_text( '집행률(%)' ).

      " 기능 설정
      go_funcs = go_alv->get_functions( ).
      go_funcs->set_all( abap_true ).

      go_display = go_alv->get_display_settings( ).
      go_display->set_list_header( '건설 프로젝트 현황' ).
      go_display->set_striped_pattern( abap_true ).

      " 정렬
      go_sorts = go_alv->get_sorts( ).
      go_sorts->add_sort( columnname = 'STATUS' ).

      go_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_err).
      MESSAGE lx_err->get_text( ) TYPE 'E'.
  ENDTRY.

  " 통계 출력
  SKIP.
  WRITE: / '=== 통계 ==='.
  WRITE: / '총 계약금액:',
           lv_total_contract CURRENCY 'KRW',
           '원'.
  WRITE: / '총 실적원가:',
           lv_total_actual CURRENCY 'KRW',
           '원'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form display_materials - 자재 재고 현황 ALV
*&---------------------------------------------------------------------*
FORM display_materials.
  DATA lt_alv TYPE ty_materials_alv.

  SELECT material_code material_name category unit standard_price
         stock_qty safety_stock primary_vendor
    FROM zconstruction_matl
    ORDER BY category material_code
    INTO TABLE @DATA(lt_raw).

  LOOP AT lt_raw INTO DATA(ls_raw).
    DATA ls_alv TYPE ty_material_alv.
    MOVE-CORRESPONDING ls_raw TO ls_alv.
    ls_alv-primary_vendor = ls_raw-primary_vendor(50).
    " 안전재고 미달 체크
    IF ls_raw-stock_qty < ls_raw-safety_stock.
      ls_alv-is_low_stock = abap_true.
    ENDIF.
    APPEND ls_alv TO lt_alv.
  ENDLOOP.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv
        CHANGING  t_table      = lt_alv ).

      go_columns = go_alv->get_columns( ).
      go_columns->set_optimize( abap_true ).

      DATA(lo_col) = CAST cl_salv_column_table(
        go_columns->get_column( 'IS_LOW_STOCK' ) ).
      lo_col->set_short_text( '재고부족' ).
      lo_col->set_cell_type( if_salv_c_cell_type=>checkbox ).

      go_display = go_alv->get_display_settings( ).
      go_display->set_list_header( '자재 재고 현황' ).
      go_display->set_striped_pattern( abap_true ).

      go_funcs = go_alv->get_functions( ).
      go_funcs->set_all( abap_true ).

      go_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_err).
      MESSAGE lx_err->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form display_equipment - 장비 현황 ALV
*&---------------------------------------------------------------------*
FORM display_equipment.
  DATA lt_alv TYPE ty_equipments_alv.

  SELECT e~equipment_code e~equipment_name e~equipment_type e~model
         e~status e~is_rented e~total_op_hours e~next_maint_date
         p~project_name
    FROM zconstruction_equip AS e
    LEFT JOIN zconstruction_proj AS p ON e~current_project = p~project_id
                                     AND e~mandt = p~mandt
    ORDER BY e~equipment_type e~equipment_code
    INTO TABLE @DATA(lt_raw).

  LOOP AT lt_raw INTO DATA(ls_raw).
    DATA ls_alv TYPE ty_equipment_alv.
    ls_alv-equipment_code  = ls_raw-equipment_code.
    ls_alv-equipment_name  = ls_raw-equipment_name(100).
    ls_alv-equipment_type  = ls_raw-equipment_type.
    ls_alv-model           = ls_raw-model(50).
    ls_alv-status          = ls_raw-status.
    ls_alv-current_project = COND #(
      WHEN ls_raw-project_name IS NOT INITIAL
      THEN ls_raw-project_name(30)
      ELSE '-' ).
    ls_alv-is_rented       = ls_raw-is_rented.
    ls_alv-total_op_hours  = ls_raw-total_op_hours.
    ls_alv-next_maint_date = ls_raw-next_maint_date.
    APPEND ls_alv TO lt_alv.
  ENDLOOP.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv
        CHANGING  t_table      = lt_alv ).

      go_columns = go_alv->get_columns( ).
      go_columns->set_optimize( abap_true ).

      go_display = go_alv->get_display_settings( ).
      go_display->set_list_header( '장비 현황' ).
      go_display->set_striped_pattern( abap_true ).

      go_funcs = go_alv->get_functions( ).
      go_funcs->set_all( abap_true ).

      go_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_err).
      MESSAGE lx_err->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form display_cost_summary - 원가 요약 ALV (프로젝트 × 원가유형)
*&---------------------------------------------------------------------*
FORM display_cost_summary.
  DATA lt_alv TYPE ty_costs_alv.

  SELECT p~project_name c~cost_type
         SUM( c~amount ) AS total_amount
         COUNT(*) AS entry_count
    FROM zconstruction_cost AS c
    INNER JOIN zconstruction_proj AS p ON c~project_id = p~project_id
                                       AND c~mandt = p~mandt
    WHERE ( @p_proj = 0 OR c~project_id = @p_proj )
    GROUP BY p~project_name c~cost_type
    ORDER BY p~project_name c~cost_type
    INTO CORRESPONDING FIELDS OF TABLE @lt_alv.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv
        CHANGING  t_table      = lt_alv ).

      go_columns = go_alv->get_columns( ).
      go_columns->set_optimize( abap_true ).

      DATA(lo_col) = CAST cl_salv_column_table(
        go_columns->get_column( 'TOTAL_AMOUNT' ) ).
      lo_col->set_short_text( '합계금액' ).
      lo_col->set_currency( 'KRW' ).

      " 합계 집계
      go_aggrs = go_alv->get_aggregations( ).
      go_aggrs->add_aggregation( columnname = 'TOTAL_AMOUNT'
                                 aggregation = if_salv_c_aggregation=>total ).

      go_display = go_alv->get_display_settings( ).
      go_display->set_list_header( '프로젝트 원가 요약 (유형별)' ).
      go_display->set_striped_pattern( abap_true ).

      go_funcs = go_alv->get_functions( ).
      go_funcs->set_all( abap_true ).

      go_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_err).
      MESSAGE lx_err->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.
