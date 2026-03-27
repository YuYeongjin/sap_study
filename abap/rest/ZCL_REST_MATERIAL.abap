*&---------------------------------------------------------------------*
*& Class: ZCL_REST_MATERIAL
*& Description: 자재 REST 핸들러 (MaterialController.java 동일 기능)
*& ICF 서비스 경로: /sap/bc/zconstruction/materials
*&
*& 지원 URL 패턴:
*&   GET  ?lowstock=X  → find_low_stock()
*&   GET  ?id=X        → find_by_id(X)
*&   GET  ?category=X  → find_by_category(X)
*&   GET  ?keyword=X   → search(X)
*&   GET  (없음)       → find_all()
*&   POST              → create_material()
*&   PUT  ?id=X        → update_material(X)
*&   DELETE ?id=X      → delete_material(X)
*&---------------------------------------------------------------------*

CLASS zcl_rest_material DEFINITION
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
    DATA mo_service TYPE REF TO zcl_material_service.
    METHODS constructor.
    METHODS set_json_response IMPORTING iv_json TYPE string iv_status TYPE i DEFAULT 200.
    METHODS set_error_response IMPORTING iv_msg TYPE string iv_status TYPE i DEFAULT 500.

ENDCLASS.


CLASS zcl_rest_material IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    CREATE OBJECT mo_service.
  ENDMETHOD.


  METHOD if_rest_resource~get.
    DATA lv_id       TYPE string.
    DATA lv_category TYPE string.
    DATA lv_keyword  TYPE string.
    DATA lv_lowstock TYPE string.

    lv_id       = mo_request->get_form_field( 'id' ).
    lv_category = mo_request->get_form_field( 'category' ).
    lv_keyword  = mo_request->get_form_field( 'keyword' ).
    lv_lowstock = mo_request->get_form_field( 'lowstock' ).

    TRY.
        IF lv_lowstock IS NOT INITIAL.
          DATA(lt_low) = mo_service->find_low_stock( ).
          set_json_response( /ui2/cl_json=>serialize( data = lt_low compress = abap_true ) ).

        ELSEIF lv_id IS NOT INITIAL.
          DATA(ls_mat) = mo_service->find_by_id( CONV n( lv_id ) ).
          set_json_response( /ui2/cl_json=>serialize( data = ls_mat compress = abap_true ) ).

        ELSEIF lv_category IS NOT INITIAL.
          DATA(lt_cat) = mo_service->find_by_category( lv_category ).
          set_json_response( /ui2/cl_json=>serialize( data = lt_cat compress = abap_true ) ).

        ELSEIF lv_keyword IS NOT INITIAL.
          DATA(lt_srch) = mo_service->search( lv_keyword ).
          set_json_response( /ui2/cl_json=>serialize( data = lt_srch compress = abap_true ) ).

        ELSE.
          DATA(lt_all) = mo_service->find_all( ).
          set_json_response( /ui2/cl_json=>serialize( data = lt_all compress = abap_true ) ).
        ENDIF.

      CATCH cx_abap_not_found.
        set_error_response( iv_msg = 'Material not found' iv_status = 404 ).
      CATCH cx_sy_dyn_call_error INTO DATA(lx_err).
        set_error_response( lx_err->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD if_rest_resource~post.
    DATA ls_mat TYPE zcl_material_service=>ty_material.
    /ui2/cl_json=>deserialize( EXPORTING json = mo_request->get_string_data( )
                               CHANGING  data = ls_mat ).
    TRY.
        DATA(ls_created) = mo_service->create_material( ls_mat ).
        set_json_response(
          iv_json   = /ui2/cl_json=>serialize( data = ls_created compress = abap_true )
          iv_status = 201 ).
      CATCH cx_sy_dyn_call_error INTO DATA(lx_err).
        set_error_response( lx_err->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD if_rest_resource~put.
    DATA ls_mat TYPE zcl_material_service=>ty_material.
    DATA lv_id  TYPE string.
    lv_id = mo_request->get_form_field( 'id' ).
    /ui2/cl_json=>deserialize( EXPORTING json = mo_request->get_string_data( )
                               CHANGING  data = ls_mat ).
    TRY.
        DATA(ls_updated) = mo_service->update_material(
          iv_material_id = CONV n( lv_id )
          is_material    = ls_mat ).
        set_json_response( /ui2/cl_json=>serialize( data = ls_updated compress = abap_true ) ).
      CATCH cx_abap_not_found.
        set_error_response( iv_msg = 'Material not found' iv_status = 404 ).
      CATCH cx_sy_dyn_call_error INTO DATA(lx_err).
        set_error_response( lx_err->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD if_rest_resource~delete.
    TRY.
        mo_service->delete_material( CONV n( mo_request->get_form_field( 'id' ) ) ).
        mo_response->set_status( cl_rest_status_code=>gc_success_no_content ).
      CATCH cx_abap_not_found.
        set_error_response( iv_msg = 'Material not found' iv_status = 404 ).
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
