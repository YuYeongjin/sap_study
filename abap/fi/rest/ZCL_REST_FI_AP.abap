*&---------------------------------------------------------------------*
*& Class: ZCL_REST_FI_AP
*& Description: AP REST 핸들러 (매입채무 - Accounts Payable)
*& Transaction: SICF → /sap/bc/zfi/ap/
*&
*& API Endpoints:
*&   벤더:
*&     GET    /sap/bc/zfi/ap/vendors               → 벤더 목록
*&     GET    /sap/bc/zfi/ap/vendors?id=1000        → 벤더 단건
*&     GET    /sap/bc/zfi/ap/vendors?type=SUBK      → 유형별 조회
*&     GET    /sap/bc/zfi/ap/vendors?search=삼성     → 검색
*&     POST   /sap/bc/zfi/ap/vendors               → 벤더 생성
*&     PUT    /sap/bc/zfi/ap/vendors?id=1000        → 벤더 수정
*&     DELETE /sap/bc/zfi/ap/vendors?id=1000        → 벤더 블록
*&   매입전표:
*&     GET    /sap/bc/zfi/ap/invoices               → 매입전표 목록
*&     GET    /sap/bc/zfi/ap/invoices?id=2026000001 → 단건 조회
*&     GET    /sap/bc/zfi/ap/invoices?overdue=X     → 연체 조회
*&     POST   /sap/bc/zfi/ap/invoices               → 매입전표 생성
*&     PUT    /sap/bc/zfi/ap/invoices?id=2026000001 → 수정
*&     DELETE /sap/bc/zfi/ap/invoices?id=2026000001 → 삭제
*&   지급/분석:
*&     POST   /sap/bc/zfi/ap/payment                → 지급 처리
*&     GET    /sap/bc/zfi/ap/aging                  → AP 연령분석
*&---------------------------------------------------------------------*

CLASS zcl_rest_fi_ap DEFINITION
  PUBLIC INHERITING FROM cl_rest_resource
  FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS:
      if_rest_resource~get  REDEFINITION,
      if_rest_resource~post REDEFINITION,
      if_rest_resource~put  REDEFINITION,
      if_rest_resource~delete REDEFINITION.

  PRIVATE SECTION.
    DATA:
      mo_ap_svc TYPE REF TO zcl_fi_ap_service,
      mv_bukrs  TYPE bukrs VALUE 'Z001'.

    METHODS:
      get_param
        IMPORTING iv_name          TYPE string
        RETURNING VALUE(rv_value)  TYPE string,

      send_json
        IMPORTING iv_data TYPE REF TO data
                  iv_code TYPE i DEFAULT 200,

      send_error
        IMPORTING iv_code    TYPE i
                  iv_message TYPE string.

ENDCLASS.


CLASS zcl_rest_fi_ap IMPLEMENTATION.

  METHOD if_rest_resource~get.
    CREATE OBJECT mo_ap_svc.
    DATA(lv_path) = mo_request->get_header_field( '~path_info' ).

    " 벤더 관련
    IF lv_path CS '/vendors'.
      DATA(lv_id)     = get_param( 'id' ).
      DATA(lv_type)   = get_param( 'type' ).
      DATA(lv_search) = get_param( 'search' ).

      IF lv_id IS NOT INITIAL.
        TRY.
            DATA(ls_vendor) = mo_ap_svc->find_vendor_by_id(
              iv_lifnr = CONV #( lv_id ) iv_bukrs = mv_bukrs ).
            DATA lr_v TYPE REF TO data. GET REFERENCE OF ls_vendor INTO lr_v.
            send_json( lr_v ).
          CATCH cx_abap_not_found.
            send_error( iv_code = 404 iv_message = '벤더를 찾을 수 없습니다' ).
        ENDTRY.
      ELSEIF lv_type IS NOT INITIAL.
        DATA(lt_by_type) = mo_ap_svc->find_vendors_by_type(
          iv_bukrs = mv_bukrs iv_vend_type = CONV #( lv_type ) ).
        DATA lr_vt TYPE REF TO data. GET REFERENCE OF lt_by_type INTO lr_vt.
        send_json( lr_vt ).
      ELSEIF lv_search IS NOT INITIAL.
        DATA(lt_search) = mo_ap_svc->search_vendors(
          iv_bukrs = mv_bukrs iv_keyword = CONV #( lv_search ) ).
        DATA lr_vs TYPE REF TO data. GET REFERENCE OF lt_search INTO lr_vs.
        send_json( lr_vs ).
      ELSE.
        DATA(lt_vendors) = mo_ap_svc->find_all_vendors( mv_bukrs ).
        DATA lr_va TYPE REF TO data. GET REFERENCE OF lt_vendors INTO lr_va.
        send_json( lr_va ).
      ENDIF.

    " 매입전표 관련
    ELSEIF lv_path CS '/invoices'.
      DATA(lv_inv_id)  = get_param( 'id' ).
      DATA(lv_overdue) = get_param( 'overdue' ).
      DATA(lv_vendor)  = get_param( 'vendor' ).
      DATA(lv_gjahr)   = get_param( 'gjahr' ).
      DATA(lv_status)  = get_param( 'status' ).

      IF lv_inv_id IS NOT INITIAL.
        DATA(lv_year) = COND gjahr(
          WHEN lv_gjahr IS NOT INITIAL THEN CONV #( lv_gjahr )
          ELSE CONV #( sy-datum(4) ) ).
        TRY.
            DATA(ls_inv) = mo_ap_svc->find_ap_invoice_by_id(
              iv_bukrs = mv_bukrs iv_ap_invno = CONV #( lv_inv_id )
              iv_gjahr = lv_year ).
            DATA lr_inv TYPE REF TO data. GET REFERENCE OF ls_inv INTO lr_inv.
            send_json( lr_inv ).
          CATCH cx_abap_not_found.
            send_error( iv_code = 404 iv_message = '매입전표를 찾을 수 없습니다' ).
        ENDTRY.
      ELSEIF lv_overdue IS NOT INITIAL.
        DATA(lt_overdue) = mo_ap_svc->find_overdue_invoices( mv_bukrs ).
        DATA lr_od TYPE REF TO data. GET REFERENCE OF lt_overdue INTO lr_od.
        send_json( lr_od ).
      ELSE.
        DATA lv_yr TYPE gjahr.
        lv_yr = COND #( WHEN lv_gjahr IS NOT INITIAL THEN CONV #( lv_gjahr )
                        ELSE CONV #( sy-datum(4) ) ).
        DATA(lt_invoices) = mo_ap_svc->find_ap_invoices(
          iv_bukrs     = mv_bukrs
          iv_gjahr     = lv_yr
          iv_lifnr     = CONV #( lv_vendor )
          iv_pay_status = CONV #( lv_status ) ).
        DATA lr_ia TYPE REF TO data. GET REFERENCE OF lt_invoices INTO lr_ia.
        send_json( lr_ia ).
      ENDIF.

    " AP 연령분석
    ELSEIF lv_path CS '/aging'.
      DATA(lt_aging) = mo_ap_svc->get_ap_aging(
        iv_bukrs    = mv_bukrs
        iv_key_date = sy-datum ).
      DATA lr_ag TYPE REF TO data. GET REFERENCE OF lt_aging INTO lr_ag.
      send_json( lr_ag ).

    ELSE.
      send_error( iv_code = 400 iv_message = '잘못된 경로입니다' ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rest_resource~post.
    CREATE OBJECT mo_ap_svc.
    DATA(lv_path) = mo_request->get_header_field( '~path_info' ).
    DATA(lv_body) = mo_request->get_entity( )->get_string_data( ).

    " 벤더 생성
    IF lv_path CS '/vendors'.
      DATA ls_vendor TYPE zcl_fi_ap_service=>ty_vendor.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_vendor ).
      TRY.
          DATA(ls_new_v) = mo_ap_svc->create_vendor( ls_vendor ).
          DATA lr_nv TYPE REF TO data. GET REFERENCE OF ls_new_v INTO lr_nv.
          send_json( iv_data = lr_nv iv_code = 201 ).
        CATCH cx_sy_dyn_call_error.
          send_error( iv_code = 400 iv_message = '벤더 생성 실패 (중복 또는 오류)' ).
      ENDTRY.

    " 매입전표 생성
    ELSEIF lv_path CS '/invoices'.
      DATA ls_invoice TYPE zcl_fi_ap_service=>ty_ap_invoice.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_invoice ).
      ls_invoice-bukrs = mv_bukrs.
      TRY.
          DATA(ls_new_i) = mo_ap_svc->create_ap_invoice( ls_invoice ).
          DATA lr_ni TYPE REF TO data. GET REFERENCE OF ls_new_i INTO lr_ni.
          send_json( iv_data = lr_ni iv_code = 201 ).
        CATCH cx_sy_dyn_call_error.
          send_error( iv_code = 400 iv_message = '매입전표 생성 실패' ).
      ENDTRY.

    " 지급처리
    ELSEIF lv_path CS '/payment'.
      DATA ls_pay TYPE zcl_fi_ap_service=>ty_payment_request.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_pay ).
      ls_pay-bukrs = mv_bukrs.
      TRY.
          DATA(lv_belnr) = mo_ap_svc->process_payment( ls_pay ).
          DATA ls_result TYPE string.
          ls_result = |{ "pay_belnr": "{ lv_belnr }", "status": "OK" }|.
          mo_response->set_status( cl_rest_status_code=>gc_success_ok ).
          mo_response->create_entity( )->set_string_data( ls_result ).
        CATCH cx_abap_not_found.
          send_error( iv_code = 404 iv_message = '매입전표를 찾을 수 없습니다' ).
        CATCH cx_sy_dyn_call_error.
          send_error( iv_code = 400 iv_message = '지급처리 실패' ).
      ENDTRY.

    ELSE.
      send_error( iv_code = 400 iv_message = '잘못된 경로입니다' ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rest_resource~put.
    CREATE OBJECT mo_ap_svc.
    DATA(lv_path) = mo_request->get_header_field( '~path_info' ).
    DATA(lv_body) = mo_request->get_entity( )->get_string_data( ).
    DATA(lv_id)   = get_param( 'id' ).

    IF lv_path CS '/vendors' AND lv_id IS NOT INITIAL.
      DATA ls_vendor TYPE zcl_fi_ap_service=>ty_vendor.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_vendor ).
      TRY.
          DATA(ls_upd_v) = mo_ap_svc->update_vendor(
            iv_lifnr = CONV #( lv_id ) iv_bukrs = mv_bukrs is_vendor = ls_vendor ).
          DATA lr_uv TYPE REF TO data. GET REFERENCE OF ls_upd_v INTO lr_uv.
          send_json( lr_uv ).
        CATCH cx_abap_not_found.
          send_error( iv_code = 404 iv_message = '벤더를 찾을 수 없습니다' ).
        CATCH cx_sy_dyn_call_error.
          send_error( iv_code = 400 iv_message = '벤더 수정 실패' ).
      ENDTRY.

    ELSEIF lv_path CS '/invoices' AND lv_id IS NOT INITIAL.
      DATA ls_invoice TYPE zcl_fi_ap_service=>ty_ap_invoice.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_invoice ).
      DATA(lv_gjahr) = CONV gjahr( sy-datum(4) ).
      TRY.
          DATA(ls_upd_i) = mo_ap_svc->update_ap_invoice(
            iv_ap_invno = CONV #( lv_id ) iv_gjahr = lv_gjahr is_invoice = ls_invoice ).
          DATA lr_ui TYPE REF TO data. GET REFERENCE OF ls_upd_i INTO lr_ui.
          send_json( lr_ui ).
        CATCH cx_abap_not_found.
          send_error( iv_code = 404 iv_message = '매입전표를 찾을 수 없습니다' ).
        CATCH cx_sy_dyn_call_error.
          send_error( iv_code = 400 iv_message = '매입전표 수정 실패 (이미 지급됨)' ).
      ENDTRY.
    ELSE.
      send_error( iv_code = 400 iv_message = '잘못된 요청입니다' ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rest_resource~delete.
    CREATE OBJECT mo_ap_svc.
    DATA(lv_path) = mo_request->get_header_field( '~path_info' ).
    DATA(lv_id)   = get_param( 'id' ).

    IF lv_path CS '/vendors' AND lv_id IS NOT INITIAL.
      TRY.
          mo_ap_svc->block_vendor( iv_lifnr = CONV #( lv_id ) iv_bukrs = mv_bukrs ).
          mo_response->set_status( cl_rest_status_code=>gc_success_no_content ).
        CATCH cx_abap_not_found.
          send_error( iv_code = 404 iv_message = '벤더를 찾을 수 없습니다' ).
      ENDTRY.

    ELSEIF lv_path CS '/invoices' AND lv_id IS NOT INITIAL.
      TRY.
          mo_ap_svc->delete_ap_invoice(
            iv_bukrs = mv_bukrs iv_ap_invno = CONV #( lv_id )
            iv_gjahr = CONV #( sy-datum(4) ) ).
          mo_response->set_status( cl_rest_status_code=>gc_success_no_content ).
        CATCH cx_abap_not_found.
          send_error( iv_code = 404 iv_message = '매입전표를 찾을 수 없습니다' ).
        CATCH cx_sy_dyn_call_error.
          send_error( iv_code = 400 iv_message = '삭제 실패 (이미 지급된 전표)' ).
      ENDTRY.
    ELSE.
      send_error( iv_code = 400 iv_message = '잘못된 요청입니다' ).
    ENDIF.
  ENDMETHOD.

  METHOD get_param.
    DATA(lo_req) = mo_request->get_uri( ).
    rv_value = lo_req->get_query_parameter( CONV #( iv_name ) ).
  ENDMETHOD.

  METHOD send_json.
    DATA lv_json TYPE string.
    /ui2/cl_json=>serialize( EXPORTING data = iv_data->* RECEIVING r_json = lv_json ).
    mo_response->set_status( iv_code ).
    mo_response->create_entity( )->set_string_data( lv_json ).
    mo_response->set_header_field( name = 'Content-Type' value = 'application/json; charset=utf-8' ).
  ENDMETHOD.

  METHOD send_error.
    DATA lv_json TYPE string.
    lv_json = |{ "error": "{ iv_message }", "code": { iv_code } }|.
    mo_response->set_status( iv_code ).
    mo_response->create_entity( )->set_string_data( lv_json ).
    mo_response->set_header_field( name = 'Content-Type' value = 'application/json; charset=utf-8' ).
  ENDMETHOD.

ENDCLASS.
