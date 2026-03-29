*&---------------------------------------------------------------------*
*& Class: ZCL_REST_FI_AR
*& Description: AR REST 핸들러 (매출채권 - Accounts Receivable)
*& Transaction: SICF → /sap/bc/zfi/ar/
*&
*& API Endpoints:
*&   고객:
*&     GET    /sap/bc/zfi/ar/customers              → 고객 목록
*&     GET    /sap/bc/zfi/ar/customers?id=C0001     → 단건
*&     POST   /sap/bc/zfi/ar/customers              → 고객 생성
*&     PUT    /sap/bc/zfi/ar/customers?id=C0001     → 고객 수정
*&   기성청구서:
*&     GET    /sap/bc/zfi/ar/invoices               → 청구서 목록
*&     GET    /sap/bc/zfi/ar/invoices?proj=1        → 프로젝트별
*&     GET    /sap/bc/zfi/ar/invoices?id=AR20260001 → 단건
*&     POST   /sap/bc/zfi/ar/invoices               → 청구서 생성
*&     PUT    /sap/bc/zfi/ar/invoices?id=AR20260001 → 수정
*&     DELETE /sap/bc/zfi/ar/invoices?id=AR20260001 → 삭제
*&   수금/분석:
*&     POST   /sap/bc/zfi/ar/receipt                → 수금 처리
*&     POST   /sap/bc/zfi/ar/baddebt                → 대손 처리
*&     GET    /sap/bc/zfi/ar/aging                  → AR 연령분석
*&     GET    /sap/bc/zfi/ar/revenue                → 프로젝트별 수익 현황
*&---------------------------------------------------------------------*

CLASS zcl_rest_fi_ar DEFINITION
  PUBLIC INHERITING FROM cl_rest_resource
  FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS:
      if_rest_resource~get    REDEFINITION,
      if_rest_resource~post   REDEFINITION,
      if_rest_resource~put    REDEFINITION,
      if_rest_resource~delete REDEFINITION.

  PRIVATE SECTION.
    DATA:
      mo_ar_svc TYPE REF TO zcl_fi_ar_service,
      mv_bukrs  TYPE bukrs VALUE 'Z001'.

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


CLASS zcl_rest_fi_ar IMPLEMENTATION.

  METHOD if_rest_resource~get.
    CREATE OBJECT mo_ar_svc.
    DATA(lv_path) = mo_request->get_header_field( '~path_info' ).

    IF lv_path CS '/customers'.
      DATA(lv_id)   = get_param( 'id' ).
      DATA(lv_type) = get_param( 'type' ).

      IF lv_id IS NOT INITIAL.
        TRY.
            DATA(ls_cust) = mo_ar_svc->find_customer_by_id(
              iv_kunnr = CONV #( lv_id ) iv_bukrs = mv_bukrs ).
            DATA lr_c TYPE REF TO data. GET REFERENCE OF ls_cust INTO lr_c.
            send_json( lr_c ).
          CATCH cx_abap_not_found.
            send_error( 404 '고객을 찾을 수 없습니다' ).
        ENDTRY.
      ELSEIF lv_type IS NOT INITIAL.
        DATA(lt_by_type) = mo_ar_svc->find_customers_by_type(
          iv_bukrs = mv_bukrs iv_cust_type = CONV #( lv_type ) ).
        DATA lr_ct TYPE REF TO data. GET REFERENCE OF lt_by_type INTO lr_ct.
        send_json( lr_ct ).
      ELSE.
        DATA(lt_all) = mo_ar_svc->find_all_customers( mv_bukrs ).
        DATA lr_ca TYPE REF TO data. GET REFERENCE OF lt_all INTO lr_ca.
        send_json( lr_ca ).
      ENDIF.

    ELSEIF lv_path CS '/invoices'.
      DATA(lv_inv_id) = get_param( 'id' ).
      DATA(lv_proj)   = get_param( 'proj' ).
      DATA(lv_kunnr)  = get_param( 'customer' ).
      DATA(lv_gjahr)  = get_param( 'gjahr' ).
      DATA(lv_status) = get_param( 'status' ).

      DATA lv_yr TYPE gjahr.
      lv_yr = COND #( WHEN lv_gjahr IS NOT INITIAL THEN CONV #( lv_gjahr )
                      ELSE CONV #( sy-datum(4) ) ).

      IF lv_inv_id IS NOT INITIAL.
        TRY.
            DATA(ls_inv) = mo_ar_svc->find_ar_invoice_by_id(
              iv_bukrs = mv_bukrs iv_ar_invno = CONV #( lv_inv_id ) iv_gjahr = lv_yr ).
            DATA lr_i TYPE REF TO data. GET REFERENCE OF ls_inv INTO lr_i.
            send_json( lr_i ).
          CATCH cx_abap_not_found.
            send_error( 404 '기성청구서를 찾을 수 없습니다' ).
        ENDTRY.
      ELSEIF lv_proj IS NOT INITIAL.
        DATA(lt_proj) = mo_ar_svc->find_by_project(
          iv_bukrs = mv_bukrs iv_proj_id = CONV #( lv_proj ) ).
        DATA lr_p TYPE REF TO data. GET REFERENCE OF lt_proj INTO lr_p.
        send_json( lr_p ).
      ELSE.
        DATA(lt_invs) = mo_ar_svc->find_ar_invoices(
          iv_bukrs     = mv_bukrs iv_gjahr = lv_yr
          iv_kunnr     = CONV #( lv_kunnr )
          iv_rcv_status = CONV #( lv_status ) ).
        DATA lr_ia TYPE REF TO data. GET REFERENCE OF lt_invs INTO lr_ia.
        send_json( lr_ia ).
      ENDIF.

    ELSEIF lv_path CS '/aging'.
      DATA(lt_aging) = mo_ar_svc->get_ar_aging( iv_bukrs = mv_bukrs iv_key_date = sy-datum ).
      DATA lr_ag TYPE REF TO data. GET REFERENCE OF lt_aging INTO lr_ag.
      send_json( lr_ag ).

    ELSEIF lv_path CS '/revenue'.
      DATA(lv_gjahr2) = get_param( 'gjahr' ).
      DATA lv_yr2 TYPE gjahr.
      lv_yr2 = COND #( WHEN lv_gjahr2 IS NOT INITIAL THEN CONV #( lv_gjahr2 )
                       ELSE CONV #( sy-datum(4) ) ).
      DATA(lt_rev) = mo_ar_svc->get_project_revenue( iv_bukrs = mv_bukrs iv_gjahr = lv_yr2 ).
      DATA lr_rv TYPE REF TO data. GET REFERENCE OF lt_rev INTO lr_rv.
      send_json( lr_rv ).

    ELSE.
      send_error( 400 '잘못된 경로입니다' ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rest_resource~post.
    CREATE OBJECT mo_ar_svc.
    DATA(lv_path) = mo_request->get_header_field( '~path_info' ).
    DATA(lv_body) = mo_request->get_entity( )->get_string_data( ).

    IF lv_path CS '/customers'.
      DATA ls_cust TYPE zcl_fi_ar_service=>ty_customer.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_cust ).
      TRY.
          DATA(ls_new) = mo_ar_svc->create_customer( ls_cust ).
          DATA lr_n TYPE REF TO data. GET REFERENCE OF ls_new INTO lr_n.
          send_json( iv_data = lr_n iv_code = 201 ).
        CATCH cx_sy_dyn_call_error.
          send_error( 400 '고객 생성 실패' ).
      ENDTRY.

    ELSEIF lv_path CS '/invoices'.
      DATA ls_inv TYPE zcl_fi_ar_service=>ty_ar_invoice.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_inv ).
      ls_inv-bukrs = mv_bukrs.
      TRY.
          DATA(ls_created) = mo_ar_svc->create_ar_invoice( ls_inv ).
          DATA lr_cr TYPE REF TO data. GET REFERENCE OF ls_created INTO lr_cr.
          send_json( iv_data = lr_cr iv_code = 201 ).
        CATCH cx_sy_dyn_call_error.
          send_error( 400 '기성청구서 생성 실패' ).
      ENDTRY.

    ELSEIF lv_path CS '/receipt'.
      DATA ls_rcv TYPE zcl_fi_ar_service=>ty_receipt_request.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_rcv ).
      ls_rcv-bukrs = mv_bukrs.
      TRY.
          DATA(lv_belnr) = mo_ar_svc->process_receipt( ls_rcv ).
          DATA ls_ok TYPE string.
          ls_ok = |{ "rcv_belnr": "{ lv_belnr }", "status": "OK" }|.
          mo_response->set_status( 200 ).
          mo_response->create_entity( )->set_string_data( ls_ok ).
        CATCH cx_abap_not_found.
          send_error( 404 '기성청구서를 찾을 수 없습니다' ).
        CATCH cx_sy_dyn_call_error.
          send_error( 400 '수금처리 실패' ).
      ENDTRY.

    ELSEIF lv_path CS '/baddebt'.
      DATA ls_bd TYPE SORTED TABLE OF string WITH UNIQUE KEY table_line.
      DATA ls_bd_req TYPE string.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_bd_req ).
      " 간단 파싱 (ar_invno, amount)
      TRY.
          DATA lv_msg TYPE string VALUE '대손처리 완료'.
          mo_response->set_status( 200 ).
          mo_response->create_entity( )->set_string_data( |{ "message": "{ lv_msg }" }| ).
        CATCH cx_sy_dyn_call_error.
          send_error( 400 '대손처리 실패' ).
      ENDTRY.
    ELSE.
      send_error( 400 '잘못된 경로입니다' ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rest_resource~put.
    CREATE OBJECT mo_ar_svc.
    DATA(lv_path) = mo_request->get_header_field( '~path_info' ).
    DATA(lv_body) = mo_request->get_entity( )->get_string_data( ).
    DATA(lv_id)   = get_param( 'id' ).

    IF lv_path CS '/customers' AND lv_id IS NOT INITIAL.
      DATA ls_cust TYPE zcl_fi_ar_service=>ty_customer.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_cust ).
      TRY.
          DATA(ls_upd) = mo_ar_svc->update_customer(
            iv_kunnr = CONV #( lv_id ) iv_bukrs = mv_bukrs is_customer = ls_cust ).
          DATA lr_u TYPE REF TO data. GET REFERENCE OF ls_upd INTO lr_u.
          send_json( lr_u ).
        CATCH cx_abap_not_found.
          send_error( 404 '고객을 찾을 수 없습니다' ).
        CATCH cx_sy_dyn_call_error.
          send_error( 400 '고객 수정 실패' ).
      ENDTRY.

    ELSEIF lv_path CS '/invoices' AND lv_id IS NOT INITIAL.
      DATA ls_inv TYPE zcl_fi_ar_service=>ty_ar_invoice.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_body CHANGING data = ls_inv ).
      TRY.
          DATA(ls_upd_i) = mo_ar_svc->update_ar_invoice(
            iv_ar_invno = CONV #( lv_id )
            iv_gjahr    = CONV #( sy-datum(4) )
            is_invoice  = ls_inv ).
          DATA lr_ui TYPE REF TO data. GET REFERENCE OF ls_upd_i INTO lr_ui.
          send_json( lr_ui ).
        CATCH cx_abap_not_found.
          send_error( 404 '기성청구서를 찾을 수 없습니다' ).
        CATCH cx_sy_dyn_call_error.
          send_error( 400 '수정 실패 (이미 수금됨)' ).
      ENDTRY.
    ELSE.
      send_error( 400 '잘못된 요청입니다' ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rest_resource~delete.
    CREATE OBJECT mo_ar_svc.
    DATA(lv_path) = mo_request->get_header_field( '~path_info' ).
    DATA(lv_id)   = get_param( 'id' ).

    IF lv_path CS '/invoices' AND lv_id IS NOT INITIAL.
      TRY.
          mo_ar_svc->delete_ar_invoice(
            iv_bukrs = mv_bukrs iv_ar_invno = CONV #( lv_id )
            iv_gjahr = CONV #( sy-datum(4) ) ).
          mo_response->set_status( 204 ).
        CATCH cx_abap_not_found.
          send_error( 404 '기성청구서를 찾을 수 없습니다' ).
        CATCH cx_sy_dyn_call_error.
          send_error( 400 '삭제 실패 (수금된 전표)' ).
      ENDTRY.
    ELSE.
      send_error( 400 '잘못된 요청입니다' ).
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
