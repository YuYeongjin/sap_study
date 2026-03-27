*&---------------------------------------------------------------------*
*& Class: ZCL_PROJECT_SERVICE
*& Description: 건설 프로젝트 서비스 클래스 (ProjectService.java 동일 기능)
*& SE24 에서 Global Class 로 생성
*&---------------------------------------------------------------------*

CLASS zcl_project_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      "! 프로젝트 단일 레코드 타입
      BEGIN OF ty_project,
        project_id      TYPE n LENGTH 10,
        project_code    TYPE c LENGTH 20,
        project_name    TYPE c LENGTH 200,
        location        TYPE c LENGTH 200,
        client          TYPE c LENGTH 100,
        project_type    TYPE c LENGTH 20,
        status          TYPE c LENGTH 20,
        contract_amt    TYPE p LENGTH 15 DECIMALS 2,
        budget          TYPE p LENGTH 15 DECIMALS 2,
        exec_budget     TYPE p LENGTH 15 DECIMALS 2,
        actual_cost     TYPE p LENGTH 15 DECIMALS 2,
        waers           TYPE waers,
        start_date      TYPE datum,
        plan_end_date   TYPE datum,
        actual_end_date TYPE datum,
        progress_rate   TYPE p LENGTH 5 DECIMALS 2,
        site_manager    TYPE c LENGTH 50,
      END OF ty_project,
      "! 프로젝트 목록 타입
      ty_projects TYPE STANDARD TABLE OF ty_project WITH KEY project_id,

      "! 대시보드 통계 타입
      BEGIN OF ty_dashboard_stats,
        total_projects    TYPE i,
        planning_count    TYPE i,
        in_progress_count TYPE i,
        completed_count   TYPE i,
        contracted_count  TYPE i,
        total_contract_amt TYPE p LENGTH 15 DECIMALS 2,
      END OF ty_dashboard_stats.

    "! 전체 프로젝트 조회
    METHODS find_all
      RETURNING VALUE(rt_projects) TYPE ty_projects
      RAISING   cx_sy_dyn_call_error.

    "! ID로 프로젝트 조회
    METHODS find_by_id
      IMPORTING iv_project_id   TYPE n
      RETURNING VALUE(rs_project) TYPE ty_project
      RAISING   cx_sy_dyn_call_error
                cx_abap_not_found.

    "! 상태별 프로젝트 조회
    METHODS find_by_status
      IMPORTING iv_status       TYPE c
      RETURNING VALUE(rt_projects) TYPE ty_projects.

    "! 키워드 검색 (프로젝트명, 코드, 위치, 발주처)
    METHODS search
      IMPORTING iv_keyword      TYPE c
      RETURNING VALUE(rt_projects) TYPE ty_projects.

    "! 프로젝트 생성
    METHODS create_project
      IMPORTING is_project      TYPE ty_project
      RETURNING VALUE(rs_project) TYPE ty_project
      RAISING   cx_sy_dyn_call_error.

    "! 프로젝트 수정
    METHODS update_project
      IMPORTING iv_project_id   TYPE n
                is_project      TYPE ty_project
      RETURNING VALUE(rs_project) TYPE ty_project
      RAISING   cx_sy_dyn_call_error
                cx_abap_not_found.

    "! 프로젝트 삭제
    METHODS delete_project
      IMPORTING iv_project_id TYPE n
      RAISING   cx_sy_dyn_call_error
                cx_abap_not_found.

    "! 대시보드 통계 조회
    METHODS get_dashboard_stats
      RETURNING VALUE(rs_stats) TYPE ty_dashboard_stats.

  PRIVATE SECTION.
    "! 다음 프로젝트 ID 채번
    METHODS get_next_id
      RETURNING VALUE(rv_id) TYPE n.

    "! 실적원가 갱신
    METHODS update_actual_cost
      IMPORTING iv_project_id TYPE n.

ENDCLASS.


CLASS zcl_project_service IMPLEMENTATION.

  METHOD find_all.
    SELECT project_id project_code project_name location client
           project_type status contract_amt budget exec_budget
           actual_cost waers start_date plan_end_date actual_end_date
           progress_rate site_manager
      FROM zconstruction_proj
      INTO CORRESPONDING FIELDS OF TABLE @rt_projects
      ORDER BY project_id.
  ENDMETHOD.


  METHOD find_by_id.
    SELECT SINGLE project_id project_code project_name location client
                  project_type status contract_amt budget exec_budget
                  actual_cost waers start_date plan_end_date actual_end_date
                  progress_rate site_manager
      FROM zconstruction_proj
      WHERE project_id = @iv_project_id
      INTO CORRESPONDING FIELDS OF @rs_project.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.
  ENDMETHOD.


  METHOD find_by_status.
    SELECT project_id project_code project_name location client
           project_type status contract_amt budget exec_budget
           actual_cost waers start_date plan_end_date actual_end_date
           progress_rate site_manager
      FROM zconstruction_proj
      WHERE status = @iv_status
      INTO CORRESPONDING FIELDS OF TABLE @rt_projects
      ORDER BY project_id.
  ENDMETHOD.


  METHOD search.
    DATA lv_pattern TYPE c LENGTH 202.
    lv_pattern = '%' && iv_keyword && '%'.

    SELECT project_id project_code project_name location client
           project_type status contract_amt budget exec_budget
           actual_cost waers start_date plan_end_date actual_end_date
           progress_rate site_manager
      FROM zconstruction_proj
      WHERE project_name LIKE @lv_pattern
         OR project_code LIKE @lv_pattern
         OR location     LIKE @lv_pattern
         OR client       LIKE @lv_pattern
      INTO CORRESPONDING FIELDS OF TABLE @rt_projects
      ORDER BY project_id.
  ENDMETHOD.


  METHOD create_project.
    DATA ls_db TYPE zconstruction_proj.

    rs_project = is_project.
    rs_project-project_id = get_next_id( ).

    MOVE-CORRESPONDING rs_project TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-created_by = sy-uname.
    GET TIME STAMP FIELD ls_db-created_at.

    INSERT zconstruction_proj FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.


  METHOD update_project.
    DATA ls_db TYPE zconstruction_proj.

    " 존재 확인
    find_by_id( iv_project_id ).

    rs_project = is_project.
    rs_project-project_id = iv_project_id.

    MOVE-CORRESPONDING rs_project TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-changed_by = sy-uname.
    GET TIME STAMP FIELD ls_db-changed_at.

    UPDATE zconstruction_proj FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.


  METHOD delete_project.
    " 존재 확인
    find_by_id( iv_project_id ).

    DELETE FROM zconstruction_proj
      WHERE project_id = @iv_project_id
        AND mandt       = @sy-mandt.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.


  METHOD get_dashboard_stats.
    " 전체 카운트
    SELECT COUNT(*) FROM zconstruction_proj INTO @rs_stats-total_projects.

    " 상태별 카운트
    SELECT COUNT(*) FROM zconstruction_proj
      WHERE status = 'PLANNING'    INTO @rs_stats-planning_count.
    SELECT COUNT(*) FROM zconstruction_proj
      WHERE status = 'IN_PROGRESS' INTO @rs_stats-in_progress_count.
    SELECT COUNT(*) FROM zconstruction_proj
      WHERE status = 'COMPLETED'   INTO @rs_stats-completed_count.
    SELECT COUNT(*) FROM zconstruction_proj
      WHERE status = 'CONTRACTED'  INTO @rs_stats-contracted_count.

    " 총 계약금액
    SELECT SUM( contract_amt ) FROM zconstruction_proj
      INTO @rs_stats-total_contract_amt.
  ENDMETHOD.


  METHOD get_next_id.
    DATA lv_max TYPE n LENGTH 10.

    SELECT MAX( project_id ) FROM zconstruction_proj INTO @lv_max.
    IF sy-subrc = 0 AND lv_max IS NOT INITIAL.
      rv_id = lv_max + 1.
    ELSE.
      rv_id = 1.
    ENDIF.
  ENDMETHOD.


  METHOD update_actual_cost.
    DATA lv_total TYPE p LENGTH 15 DECIMALS 2.

    SELECT SUM( amount ) FROM zconstruction_cost
      WHERE project_id = @iv_project_id
      INTO @lv_total.

    UPDATE zconstruction_proj
      SET actual_cost = @lv_total
      WHERE project_id = @iv_project_id
        AND mandt       = @sy-mandt.
  ENDMETHOD.

ENDCLASS.
