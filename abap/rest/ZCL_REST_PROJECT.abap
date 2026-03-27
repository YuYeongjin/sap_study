*&---------------------------------------------------------------------*
*& Class: ZCL_REST_PROJECT
*& Description: 프로젝트 REST 핸들러 (ProjectController.java 동일 기능)
*& ICF 서비스 경로: /sap/bc/zconstruction/projects
*& CL_REST_RESOURCE 상속으로 GET/POST/PUT/DELETE 구현
*&---------------------------------------------------------------------*
*
* SICF 설정 방법:
*   트랜잭션: SICF
*   서비스 경로: /default_host/sap/bc/zconstruction/projects
*   Handler 클래스: ZCL_REST_PROJECT
*
* 지원 URL 패턴:
*   GET    /sap/bc/zconstruction/projects          → find_all()
*   GET    /sap/bc/zconstruction/projects?id=1     → find_by_id(1)
*   GET    /sap/bc/zconstruction/projects?status=X → find_by_status(X)
*   GET    /sap/bc/zconstruction/projects?keyword=X → search(X)
*   GET    /sap/bc/zconstruction/projects?stats=X  → get_dashboard_stats()
*   POST   /sap/bc/zconstruction/projects          → create_project()
*   PUT    /sap/bc/zconstruction/projects?id=1     → update_project(1)
*   DELETE /sap/bc/zconstruction/projects?id=1     → delete_project(1)
*&---------------------------------------------------------------------*

CLASS zcl_rest_project DEFINITION
  PUBLIC
  INHERITING FROM cl_rest_resource
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS if_rest_resource~get  REDEFINITION.
    METHODS if_rest_resource~post REDEFINITION.
    METHODS if_rest_resource~put  REDEFINITION.
    METHODS if_rest_resource~delete REDEFINITION.

  PRIVATE SECTION.
    DATA mo_service TYPE REF TO zcl_project_service.

    METHODS constructor.
    METHODS set_json_response
      IMPORTING iv_json   TYPE string
                iv_status TYPE i DEFAULT 200.
    METHODS set_error_response
      IMPORTING iv_msg    TYPE string
                iv_status TYPE i DEFAULT 500.
    METHODS to_json_project
      IMPORTING is_project      TYPE zcl_project_service=>ty_project
      RETURNING VALUE(rv_json)  TYPE string.
    METHODS to_json_projects
      IMPORTING it_projects     TYPE zcl_project_service=>ty_projects
      RETURNING VALUE(rv_json)  TYPE string.

ENDCLASS.


CLASS zcl_rest_project IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    CREATE OBJECT mo_service.
  ENDMETHOD.


  METHOD if_rest_resource~get.
    DATA lv_id      TYPE string.
    DATA lv_status  TYPE string.
    DATA lv_keyword TYPE string.
    DATA lv_stats   TYPE string.

    " 쿼리 파라미터 추출
    lv_id      = mo_request->get_form_field( 'id' ).
    lv_status  = mo_request->get_form_field( 'status' ).
    lv_keyword = mo_request->get_form_field( 'keyword' ).
    lv_stats   = mo_request->get_form_field( 'stats' ).

    TRY.
        IF lv_stats IS NOT INITIAL.
          " 대시보드 통계
          DATA(ls_stats) = mo_service->get_dashboard_stats( ).
          DATA(lv_json) = |{"totalProjects":| && ls_stats-total_projects
                       && |,"planningCount":| && ls_stats-planning_count
                       && |,"inProgressCount":| && ls_stats-in_progress_count
                       && |,"completedCount":| && ls_stats-completed_count
                       && |,"contractedCount":| && ls_stats-contracted_count
                       && |,"totalContractAmt":| && ls_stats-total_contract_amt
                       && |}|.
          set_json_response( lv_json ).

        ELSEIF lv_id IS NOT INITIAL.
          " ID로 단건 조회
          DATA(ls_proj) = mo_service->find_by_id( CONV n( lv_id ) ).
          set_json_response( to_json_project( ls_proj ) ).

        ELSEIF lv_status IS NOT INITIAL.
          " 상태별 조회
          DATA(lt_by_status) = mo_service->find_by_status( lv_status ).
          set_json_response( to_json_projects( lt_by_status ) ).

        ELSEIF lv_keyword IS NOT INITIAL.
          " 키워드 검색
          DATA(lt_searched) = mo_service->search( lv_keyword ).
          set_json_response( to_json_projects( lt_searched ) ).

        ELSE.
          " 전체 조회
          DATA(lt_all) = mo_service->find_all( ).
          set_json_response( to_json_projects( lt_all ) ).
        ENDIF.

      CATCH cx_abap_not_found.
        set_error_response( iv_msg = 'Project not found' iv_status = 404 ).
      CATCH cx_sy_dyn_call_error INTO DATA(lx_err).
        set_error_response( lx_err->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD if_rest_resource~post.
    DATA lv_body TYPE string.
    DATA ls_proj TYPE zcl_project_service=>ty_project.

    lv_body = mo_request->get_string_data( ).

    " JSON → 구조체 변환 (/ui2/cl_json 활용)
    /ui2/cl_json=>deserialize(
      EXPORTING json = lv_body
      CHANGING  data = ls_proj ).

    TRY.
        DATA(ls_created) = mo_service->create_project( ls_proj ).
        set_json_response(
          iv_json   = to_json_project( ls_created )
          iv_status = 201 ).
      CATCH cx_sy_dyn_call_error INTO DATA(lx_err).
        set_error_response( lx_err->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD if_rest_resource~put.
    DATA lv_id   TYPE string.
    DATA lv_body TYPE string.
    DATA ls_proj TYPE zcl_project_service=>ty_project.

    lv_id  = mo_request->get_form_field( 'id' ).
    lv_body = mo_request->get_string_data( ).

    /ui2/cl_json=>deserialize(
      EXPORTING json = lv_body
      CHANGING  data = ls_proj ).

    TRY.
        DATA(ls_updated) = mo_service->update_project(
          iv_project_id = CONV n( lv_id )
          is_project    = ls_proj ).
        set_json_response( to_json_project( ls_updated ) ).
      CATCH cx_abap_not_found.
        set_error_response( iv_msg = 'Project not found' iv_status = 404 ).
      CATCH cx_sy_dyn_call_error INTO DATA(lx_err).
        set_error_response( lx_err->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD if_rest_resource~delete.
    DATA lv_id TYPE string.
    lv_id = mo_request->get_form_field( 'id' ).

    TRY.
        mo_service->delete_project( CONV n( lv_id ) ).
        mo_response->set_status( cl_rest_status_code=>gc_success_no_content ).
      CATCH cx_abap_not_found.
        set_error_response( iv_msg = 'Project not found' iv_status = 404 ).
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
    DATA lv_json TYPE string.
    lv_json = |{"error":"| && iv_msg && |"}|.
    set_json_response( iv_json = lv_json iv_status = iv_status ).
  ENDMETHOD.


  METHOD to_json_project.
    rv_json = /ui2/cl_json=>serialize(
      data             = is_project
      pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
      compress         = abap_true ).
  ENDMETHOD.


  METHOD to_json_projects.
    rv_json = /ui2/cl_json=>serialize(
      data             = it_projects
      pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
      compress         = abap_true ).
  ENDMETHOD.

ENDCLASS.
