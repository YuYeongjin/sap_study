*&---------------------------------------------------------------------*
*& Class: ZCL_REST_COST
*& Description: 원가 REST 핸들러 (CostEntryController.java 동일 기능)
*& ICF 서비스 경로: /sap/bc/zconstruction/cost-entries
*&
*& 지원 URL 패턴:
*&   GET    ?id=X               → find_by_id(X)
*&   GET    ?project_id=X       → find_by_project(X)
*&   GET    ?project_id=X&summary=X → get_cost_summary_by_project(X)
*&   GET    ?all_summary=X      → get_all_cost_summary()
*&   GET    (없음)              → find_all()
*&   POST                       → create_cost_entry()
*&   DELETE ?id=X               → delete_cost_entry(X)
*&---------------------------------------------------------------------*

CLASS zcl_rest_cost DEFINITION
  PUBLIC
  INHERITING FROM cl_rest_resource
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS if_rest_resource~get    REDEFINITION.
    METHODS if_rest_resource~post   REDEFINITION.
    METHODS if_rest_resource~delete REDEFINITION.

  PRIVATE SECTION.
    DATA mo_service TYPE REF TO zcl_cost_service.
    METHODS constructor.
    METHODS set_json_response IMPORTING iv_json TYPE string iv_status TYPE i DEFAULT 200.
    METHODS set_error_response IMPORTING iv_msg TYPE string iv_status TYPE i DEFAULT 500.

ENDCLASS.


CLASS zcl_rest_cost IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    CREATE OBJECT mo_service.
  ENDMETHOD.


  METHOD if_rest_resource~get.
    DATA lv_id          TYPE string.
    DATA lv_project_id  TYPE string.
    DATA lv_summary     TYPE string.
    DATA lv_all_summary TYPE string.

    lv_id          = mo_request->get_form_field( 'id' ).
    lv_project_id  = mo_request->get_form_field( 'project_id' ).
    lv_summary     = mo_request->get_form_field( 'summary' ).
    lv_all_summary = mo_request->get_form_field( 'all_summary' ).

    TRY.
        IF lv_all_summary IS NOT INITIAL.
          DATA(lt_all_sum) = mo_service->get_all_cost_summary( ).
          set_json_response( /ui2/cl_json=>serialize( data = lt_all_sum compress = abap_true ) ).

        ELSEIF lv_project_id IS NOT INITIAL AND lv_summary IS NOT INITIAL.
          DATA(lt_proj_sum) = mo_service->get_cost_summary_by_project( CONV n( lv_project_id ) ).
          set_json_response( /ui2/cl_json=>serialize( data = lt_proj_sum compress = abap_true ) ).

        ELSEIF lv_project_id IS NOT INITIAL.
          DATA(lt_proj) = mo_service->find_by_project( CONV n( lv_project_id ) ).
          set_json_response( /ui2/cl_json=>serialize( data = lt_proj compress = abap_true ) ).

        ELSEIF lv_id IS NOT INITIAL.
          DATA(ls_cost) = mo_service->find_by_id( CONV n( lv_id ) ).
          set_json_response( /ui2/cl_json=>serialize( data = ls_cost compress = abap_true ) ).

        ELSE.
          DATA(lt_all) = mo_service->find_all( ).
          set_json_response( /ui2/cl_json=>serialize( data = lt_all compress = abap_true ) ).
        ENDIF.

      CATCH cx_abap_not_found.
        set_error_response( iv_msg = 'Cost entry not found' iv_status = 404 ).
      CATCH cx_sy_dyn_call_error INTO DATA(lx_err).
        set_error_response( lx_err->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD if_rest_resource~post.
    DATA ls_entry TYPE zcl_cost_service=>ty_cost_entry.
    /ui2/cl_json=>deserialize( EXPORTING json = mo_request->get_string_data( )
                               CHANGING  data = ls_entry ).
    TRY.
        DATA(ls_created) = mo_service->create_cost_entry( ls_entry ).
        set_json_response(
          iv_json   = /ui2/cl_json=>serialize( data = ls_created compress = abap_true )
          iv_status = 201 ).
      CATCH cx_sy_dyn_call_error INTO DATA(lx_err).
        set_error_response( lx_err->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD if_rest_resource~delete.
    TRY.
        mo_service->delete_cost_entry( CONV n( mo_request->get_form_field( 'id' ) ) ).
        mo_response->set_status( cl_rest_status_code=>gc_success_no_content ).
      CATCH cx_abap_not_found.
        set_error_response( iv_msg = 'Cost entry not found' iv_status = 404 ).
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
