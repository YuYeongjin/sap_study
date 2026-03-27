*&---------------------------------------------------------------------*
*& Class: ZCL_REST_PO
*& Description: 구매발주 REST 핸들러 (PurchaseOrderController.java 동일 기능)
*& ICF 서비스 경로: /sap/bc/zconstruction/purchase-orders
*&
*& 지원 URL 패턴:
*&   GET    ?id=X         → find_by_id(X)
*&   GET    ?project_id=X → find_by_project(X)
*&   GET    ?status=X     → find_by_status(X)
*&   GET    (없음)        → find_all()
*&   POST                 → create_po()
*&   PUT    ?id=X&status=Y → update_status(X, Y)
*&   PUT    ?id=X (body)  → update_po(X)
*&   DELETE ?id=X         → delete_po(X)
*&---------------------------------------------------------------------*

CLASS zcl_rest_po DEFINITION
  PUBLIC
  INHERITING FROM cl_rest_resource
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS if_rest_resource~get    REDEFINITION.
    METHODS if_rest_resource~post   REDEFINITION.
    METHODS if_rest_resource~put    REDEFINITION.
    METHODS if_rest_resource~delete REDEFINITION.

  PRIVATE SECTION.
    DATA mo_service TYPE REF TO zcl_po_service.
    METHODS constructor.
    METHODS set_json_response IMPORTING iv_json TYPE string iv_status TYPE i DEFAULT 200.
    METHODS set_error_response IMPORTING iv_msg TYPE string iv_status TYPE i DEFAULT 500.

ENDCLASS.


CLASS zcl_rest_po IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    CREATE OBJECT mo_service.
  ENDMETHOD.


  METHOD if_rest_resource~get.
    DATA lv_id         TYPE string.
    DATA lv_project_id TYPE string.
    DATA lv_status     TYPE string.

    lv_id         = mo_request->get_form_field( 'id' ).
    lv_project_id = mo_request->get_form_field( 'project_id' ).
    lv_status     = mo_request->get_form_field( 'status' ).

    TRY.
        IF lv_id IS NOT INITIAL.
          DATA(ls_po) = mo_service->find_by_id( CONV n( lv_id ) ).
          set_json_response( /ui2/cl_json=>serialize( data = ls_po compress = abap_true ) ).

        ELSEIF lv_project_id IS NOT INITIAL.
          DATA(lt_proj) = mo_service->find_by_project( CONV n( lv_project_id ) ).
          set_json_response( /ui2/cl_json=>serialize( data = lt_proj compress = abap_true ) ).

        ELSEIF lv_status IS NOT INITIAL.
          DATA(lt_stat) = mo_service->find_by_status( lv_status ).
          set_json_response( /ui2/cl_json=>serialize( data = lt_stat compress = abap_true ) ).

        ELSE.
          DATA(lt_all) = mo_service->find_all( ).
          set_json_response( /ui2/cl_json=>serialize( data = lt_all compress = abap_true ) ).
        ENDIF.

      CATCH cx_abap_not_found.
        set_error_response( iv_msg = 'Purchase order not found' iv_status = 404 ).
      CATCH cx_sy_dyn_call_error INTO DATA(lx_err).
        set_error_response( lx_err->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD if_rest_resource~post.
    DATA ls_po TYPE zcl_po_service=>ty_po.
    /ui2/cl_json=>deserialize( EXPORTING json = mo_request->get_string_data( )
                               CHANGING  data = ls_po ).
    TRY.
        DATA(ls_created) = mo_service->create_po( ls_po ).
        set_json_response(
          iv_json   = /ui2/cl_json=>serialize( data = ls_created compress = abap_true )
          iv_status = 201 ).
      CATCH cx_sy_dyn_call_error INTO DATA(lx_err).
        set_error_response( lx_err->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD if_rest_resource~put.
    DATA lv_id     TYPE string.
    DATA lv_status TYPE string.

    lv_id     = mo_request->get_form_field( 'id' ).
    lv_status = mo_request->get_form_field( 'status' ).

    TRY.
        IF lv_status IS NOT INITIAL.
          " 상태만 변경
          mo_service->update_status(
            iv_po_id  = CONV n( lv_id )
            iv_status = lv_status ).
          set_json_response( '{"message":"Status updated successfully"}' ).
        ELSE.
          " 전체 수정
          DATA ls_po TYPE zcl_po_service=>ty_po.
          /ui2/cl_json=>deserialize( EXPORTING json = mo_request->get_string_data( )
                                     CHANGING  data = ls_po ).
          DATA(ls_updated) = mo_service->update_po(
            iv_po_id = CONV n( lv_id )
            is_po    = ls_po ).
          set_json_response( /ui2/cl_json=>serialize( data = ls_updated compress = abap_true ) ).
        ENDIF.
      CATCH cx_abap_not_found.
        set_error_response( iv_msg = 'Purchase order not found' iv_status = 404 ).
      CATCH cx_sy_dyn_call_error INTO DATA(lx_err).
        set_error_response( lx_err->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD if_rest_resource~delete.
    TRY.
        mo_service->delete_po( CONV n( mo_request->get_form_field( 'id' ) ) ).
        mo_response->set_status( cl_rest_status_code=>gc_success_no_content ).
      CATCH cx_abap_not_found.
        set_error_response( iv_msg = 'Purchase order not found' iv_status = 404 ).
      CATCH cx_sy_dyn_call_error INTO DATA(lx_err).
        set_error_response( lx_err->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD set_json_response.
    mo_response->set_header_field(
      iv_name  = if_http_header_fields=>content_type
      iv_value = 'application/json; charset=utf-8' ).
    mo_response->set_status( iv_status ).
    mo_response->set_string_data( iv_json ).
  ENDMETHOD.


  METHOD set_error_response.
    set_json_response(
      iv_json   = |{"error":"| && iv_msg && |"}|
      iv_status = iv_status ).
  ENDMETHOD.

ENDCLASS.
