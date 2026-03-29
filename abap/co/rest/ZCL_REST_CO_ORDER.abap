*&---------------------------------------------------------------------*
*& Class: ZCL_REST_CO_ORDER
*& Description: 내부오더 REST 핸들러 (CO-OPA)
*& Transaction: SICF → /sap/bc/zco/orders/
*&
*& API Endpoints:
*&     GET    /sap/bc/zco/orders               → 오더 목록
*&     GET    /sap/bc/zco/orders?id=100000001  → 단건
*&     GET    /sap/bc/zco/orders?proj=1        → 프로젝트별
*&     GET    /sap/bc/zco/orders?overbudget=X  → 예산초과 오더
*&     GET    /sap/bc/zco/orders?budget=100000001 → 예산 현황
*&     GET    /sap/bc/zco/orders?cost=100000001   → 원가 상세
*&     POST   /sap/bc/zco/orders               → 오더 생성
*&     POST   /sap/bc/zco/orders/release       → 오더 릴리즈
*&     POST   /sap/bc/zco/orders/settle        → 오더 정산
*&     PUT    /sap/bc/zco/orders?id=100000001  → 오더 수정
*&     POST   /sap/bc/zco/budgets              → 예산 등록
*&---------------------------------------------------------------------*

CLASS zcl_rest_co_order DEFINITION
  PUBLIC INHERITING FROM cl_rest_resource
  FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS:
      if_rest_resource~get    REDEFINITION,
      if_rest_resource~post   REDEFINITION,
      if_rest_resource~put    REDEFINITION.

  PRIVATE SECTION.
    DATA:
      mo_ord_svc TYPE REF TO zcl_co_order_service,
      mv_kokrs   TYPE kokrs VALUE 'Z001'.

    METHODS:
      get_param
        IMPORTING iv_name         TYPE string
        RETURNING VALUE(rv_value) TYPE string,
      send_json
        IMPORTING iv_data TYPE REF TO data
                  iv_code TYPE i DEFAULT 200,
      send_error
        IMPORTING iv_code    TYPE i
                  iv_message TYPE string.

ENDCLASS.


CLASS zcl_rest_co_order IMPLEMENTATION.

  METHOD if_rest_resource~get.
    CREATE OBJECT mo_ord_svc.
    DATA(lv_path)       = mo_request->get_header_field( '~path_info' ).
    DATA(lv_id)         = get_param( 'id' ).
    DATA(lv_proj)       = get_param( 'proj' ).
    DATA(lv_overbudget) = get_param( 'overbudget' ).
    DATA(lv_budget)     = get_param( 'budget' ).
    DATA(lv_cost)       = get_param( 'cost' ).
    DATA(lv_gjahr)      = get_param( 'gjahr' ).

    DATA lv_yr TYPE gjahr.
    lv_yr = COND #( WHEN lv_gjahr IS NOT INITIAL THEN CONV #( lv_gjahr )
                    ELSE CONV #( sy-datum(4) ) ).

    IF lv_id IS NOT INITIAL.
      TRY.
          DATA(ls_ord) = mo_ord_svc->find_by_id( iv_kokrs = mv_kokrs iv_aufnr = CONV #( lv_id ) ).
          DATA lr_o TYPE REF TO data. GET REFERENCE OF ls_ord INTO lr_o.
          send_json( lr_o ).
        CATCH cx_abap_not_found.
          send_error( 404 '내부오더를 찾을 수 없습니다' ).
      ENDTRY.

    ELSEIF lv_budget IS NOT INITIAL.
      TRY.
          DATA(ls_bgt) = mo_ord_svc->get_budget_status(
            iv_kokrs = mv_kokrs iv_aufnr = CONV #( lv_budget ) iv_gjahr = lv_yr ).
          DATA lr_b TYPE REF TO data. GET REFERENCE OF ls_bgt INTO lr_b.
          send_json( lr_b ).
        CATCH cx_abap_not_found.
          send_error( 404 '오더를 찾을 수 없습니다' ).
      ENDTRY.

    ELSEIF lv_cost IS NOT INITIAL.
      DATA(lt_cost) = mo_ord_svc->get_order_cost_detail(
        iv_kokrs = mv_kokrs iv_aufnr = CONV #( lv_cost ) iv_gjahr = lv_yr ).
      DATA lr_c TYPE REF TO data. GET REFERENCE OF lt_cost INTO lr_c.
      send_json( lr_c ).

    ELSEIF lv_proj IS NOT INITIAL.
      DATA(lt_proj) = mo_ord_svc->find_by_project(
        iv_kokrs = mv_kokrs iv_proj_id = CONV #( lv_proj ) ).
      DATA lr_p TYPE REF TO data. GET REFERENCE OF lt_proj INTO lr_p.
      send_json( lr_p ).

    ELSEIF lv_overbudget IS NOT INITIAL.
      DATA(lt_over) = mo_ord_svc->find_overbudget( mv_kokrs ).
      DATA lr_ov TYPE REF TO data. GET REFERENCE OF lt_over INTO lr_ov.
      send_json( lr_ov ).

    ELSEIF lv_path CS '/budgets'.
      DATA(lt_budgets) = mo_ord_svc->get_all_budget_status( iv_kokrs = mv_kokrs iv_gjahr = lv_yr ).
      DATA lr_bg TYPE REF TO data. GET REFERENCE OF lt_budgets INTO lr_bg.
      send_json( lr_bg ).

    ELSE.
      DATA(lt_all) = mo_ord_svc->find_all( iv_kokrs = mv_kokrs ).
      DATA lr_a TYPE REF TO data. GET REFERENCE OF lt_all INTO lr_a.
      send_json( lr_a ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rest_resource~post.
    CREATE OBJECT mo_ord_svc.
    DATA(lv_path) = mo_request->get_header_field( '~path_info' ).
    DATA(lv_body) = mo_request->get_entity( )->get_string_data( ).

    IF lv_path CS '/release'.
      DATA ls_rel_req TYPE string.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_rel_req ).
      DATA lv_aufnr_rel TYPE aufnr.
      " aufnr 파싱 (간이)
      TRY.
          mo_ord_svc->release_order( iv_kokrs = mv_kokrs iv_aufnr = lv_aufnr_rel ).
          mo_response->set_status( 200 ).
          mo_response->create_entity( )->set_string_data( '{"status":"릴리즈 완료"}' ).
        CATCH cx_abap_not_found.
          send_error( 404 '오더를 찾을 수 없습니다' ).
        CATCH cx_sy_dyn_call_error.
          send_error( 400 '릴리즈 실패 (CR 상태만 가능)' ).
      ENDTRY.

    ELSEIF lv_path CS '/settle'.
      DATA ls_settle TYPE zcl_co_order_service=>ty_order.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_settle ).
      TRY.
          DATA(ls_result) = mo_ord_svc->settle_order(
            iv_kokrs      = mv_kokrs
            iv_aufnr      = ls_settle-aufnr
            iv_settle_date = sy-datum ).
          DATA lr_sr TYPE REF TO data. GET REFERENCE OF ls_result INTO lr_sr.
          send_json( lr_sr ).
        CATCH cx_abap_not_found.
          send_error( 404 '오더를 찾을 수 없습니다' ).
        CATCH cx_sy_dyn_call_error.
          send_error( 400 '정산 실패' ).
      ENDTRY.

    ELSEIF lv_path CS '/budgets'.
      " 예산 등록 요청 처리
      DATA BEGIN OF ls_bgt_req.
        DATA aufnr        TYPE aufnr.
        DATA gjahr        TYPE gjahr.
        DATA budget_type  TYPE c LENGTH 2.
        DATA amount       TYPE p LENGTH 15 DECIMALS 2.
      DATA END OF ls_bgt_req.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_bgt_req ).
      IF ls_bgt_req-gjahr IS INITIAL.
        ls_bgt_req-gjahr = CONV #( sy-datum(4) ).
      ENDIF.
      TRY.
          mo_ord_svc->save_budget(
            iv_kokrs       = mv_kokrs
            iv_aufnr       = ls_bgt_req-aufnr
            iv_gjahr       = ls_bgt_req-gjahr
            iv_budget_type = ls_bgt_req-budget_type
            iv_amount      = ls_bgt_req-amount ).
          mo_response->set_status( 200 ).
          mo_response->create_entity( )->set_string_data( '{"status":"예산 등록 완료"}' ).
        CATCH cx_sy_dyn_call_error.
          send_error( 400 '예산 등록 실패' ).
      ENDTRY.

    ELSE.
      " 오더 생성
      DATA ls_order TYPE zcl_co_order_service=>ty_order.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_order ).
      ls_order-kokrs = mv_kokrs.
      TRY.
          DATA(ls_new) = mo_ord_svc->create_order( ls_order ).
          DATA lr_nw TYPE REF TO data. GET REFERENCE OF ls_new INTO lr_nw.
          send_json( iv_data = lr_nw iv_code = 201 ).
        CATCH cx_sy_dyn_call_error.
          send_error( 400 '오더 생성 실패' ).
      ENDTRY.
    ENDIF.
  ENDMETHOD.

  METHOD if_rest_resource~put.
    CREATE OBJECT mo_ord_svc.
    DATA(lv_body) = mo_request->get_entity( )->get_string_data( ).
    DATA(lv_id)   = get_param( 'id' ).

    IF lv_id IS NOT INITIAL.
      DATA ls_order TYPE zcl_co_order_service=>ty_order.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_order ).
      TRY.
          DATA(ls_upd) = mo_ord_svc->update_order(
            iv_kokrs = mv_kokrs iv_aufnr = CONV #( lv_id ) is_order = ls_order ).
          DATA lr_u TYPE REF TO data. GET REFERENCE OF ls_upd INTO lr_u.
          send_json( lr_u ).
        CATCH cx_abap_not_found.
          send_error( 404 '오더를 찾을 수 없습니다' ).
        CATCH cx_sy_dyn_call_error.
          send_error( 400 '오더 수정 실패' ).
      ENDTRY.
    ELSE.
      send_error( 400 'ID가 필요합니다' ).
    ENDIF.
  ENDMETHOD.

  METHOD get_param.
    rv_value = mo_request->get_uri( )->get_query_parameter( CONV #( iv_name ) ).
  ENDMETHOD.

  METHOD send_json.
    DATA lv_json TYPE string.
    /ui2/cl_json=>serialize( EXPORTING data = iv_data->* RECEIVING r_json = lv_json ).
    mo_response->set_status( iv_code ).
    mo_response->create_entity( )->set_string_data( lv_json ).
    mo_response->set_header_field( name = 'Content-Type' value = 'application/json; charset=utf-8' ).
  ENDMETHOD.

  METHOD send_error.
    mo_response->set_status( iv_code ).
    mo_response->create_entity( )->set_string_data(
      |{ "error": "{ iv_message }", "code": { iv_code } }| ).
    mo_response->set_header_field( name = 'Content-Type' value = 'application/json; charset=utf-8' ).
  ENDMETHOD.

ENDCLASS.
