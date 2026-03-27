*&---------------------------------------------------------------------*
*& Class: ZCL_COST_SERVICE
*& Description: 원가 서비스 클래스 (CostEntryService.java 동일 기능)
*&---------------------------------------------------------------------*

CLASS zcl_cost_service DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_cost_entry,
        cost_id      TYPE n LENGTH 10,
        entry_number TYPE c LENGTH 20,
        project_id   TYPE n LENGTH 10,
        cost_type    TYPE c LENGTH 20,
        cost_account TYPE c LENGTH 20,
        entry_date   TYPE datum,
        amount       TYPE p LENGTH 15 DECIMALS 2,
        quantity     TYPE p LENGTH 13 DECIMALS 3,
        unit         TYPE t006-msehi,
        unit_price   TYPE p LENGTH 15 DECIMALS 2,
        description  TYPE c LENGTH 500,
        document_no  TYPE c LENGTH 20,
        waers        TYPE waers,
        created_by   TYPE uname,
      END OF ty_cost_entry,
      ty_cost_entries TYPE STANDARD TABLE OF ty_cost_entry WITH KEY cost_id,

      BEGIN OF ty_cost_summary,
        project_id   TYPE n LENGTH 10,
        cost_type    TYPE c LENGTH 20,
        total_amount TYPE p LENGTH 15 DECIMALS 2,
        entry_count  TYPE i,
      END OF ty_cost_summary,
      ty_cost_summaries TYPE STANDARD TABLE OF ty_cost_summary WITH KEY project_id cost_type.

    METHODS find_all
      RETURNING VALUE(rt_entries) TYPE ty_cost_entries.

    METHODS find_by_id
      IMPORTING iv_cost_id     TYPE n
      RETURNING VALUE(rs_entry) TYPE ty_cost_entry
      RAISING   cx_abap_not_found.

    METHODS find_by_project
      IMPORTING iv_project_id   TYPE n
      RETURNING VALUE(rt_entries) TYPE ty_cost_entries.

    METHODS get_cost_summary_by_project
      IMPORTING iv_project_id    TYPE n
      RETURNING VALUE(rt_summary) TYPE ty_cost_summaries.

    METHODS get_all_cost_summary
      RETURNING VALUE(rt_summary) TYPE ty_cost_summaries.

    METHODS create_cost_entry
      IMPORTING is_entry       TYPE ty_cost_entry
      RETURNING VALUE(rs_entry) TYPE ty_cost_entry
      RAISING   cx_sy_dyn_call_error.

    "! 원가전표 수정 (금액 자동 재계산 포함)
    METHODS update_cost_entry
      IMPORTING iv_cost_id     TYPE n
                is_entry       TYPE ty_cost_entry
      RETURNING VALUE(rs_entry) TYPE ty_cost_entry
      RAISING   cx_sy_dyn_call_error
                cx_abap_not_found.

    METHODS delete_cost_entry
      IMPORTING iv_cost_id TYPE n
      RAISING   cx_sy_dyn_call_error
                cx_abap_not_found.

  PRIVATE SECTION.
    METHODS get_next_id  RETURNING VALUE(rv_id) TYPE n.
    METHODS update_project_actual_cost IMPORTING iv_project_id TYPE n.

ENDCLASS.


CLASS zcl_cost_service IMPLEMENTATION.

  METHOD find_all.
    SELECT cost_id entry_number project_id cost_type cost_account
           entry_date amount quantity unit unit_price description
           document_no waers created_by
      FROM zconstruction_cost
      INTO CORRESPONDING FIELDS OF TABLE @rt_entries
      ORDER BY entry_date DESCENDING.
  ENDMETHOD.

  METHOD find_by_id.
    SELECT SINGLE cost_id entry_number project_id cost_type cost_account
                  entry_date amount quantity unit unit_price description
                  document_no waers created_by
      FROM zconstruction_cost
      WHERE cost_id = @iv_cost_id
      INTO CORRESPONDING FIELDS OF @rs_entry.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.
  ENDMETHOD.

  METHOD find_by_project.
    SELECT cost_id entry_number project_id cost_type cost_account
           entry_date amount quantity unit unit_price description
           document_no waers created_by
      FROM zconstruction_cost
      WHERE project_id = @iv_project_id
      INTO CORRESPONDING FIELDS OF TABLE @rt_entries
      ORDER BY entry_date DESCENDING.
  ENDMETHOD.

  METHOD get_cost_summary_by_project.
    SELECT project_id cost_type
           SUM( amount ) AS total_amount
           COUNT(*) AS entry_count
      FROM zconstruction_cost
      WHERE project_id = @iv_project_id
      GROUP BY project_id cost_type
      INTO CORRESPONDING FIELDS OF TABLE @rt_summary
      ORDER BY cost_type.
  ENDMETHOD.

  METHOD get_all_cost_summary.
    SELECT project_id cost_type
           SUM( amount ) AS total_amount
           COUNT(*) AS entry_count
      FROM zconstruction_cost
      GROUP BY project_id cost_type
      INTO CORRESPONDING FIELDS OF TABLE @rt_summary
      ORDER BY project_id cost_type.
  ENDMETHOD.

  METHOD create_cost_entry.
    DATA ls_db TYPE zconstruction_cost.
    rs_entry = is_entry.
    rs_entry-cost_id = get_next_id( ).
    IF rs_entry-quantity > 0 AND rs_entry-unit_price > 0.
      rs_entry-amount = rs_entry-quantity * rs_entry-unit_price.
    ENDIF.
    MOVE-CORRESPONDING rs_entry TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-created_by = sy-uname.
    GET TIME STAMP FIELD ls_db-created_at.
    INSERT zconstruction_cost FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    update_project_actual_cost( rs_entry-project_id ).
  ENDMETHOD.

  METHOD update_cost_entry.
    DATA ls_db TYPE zconstruction_cost.

    " 존재 확인
    DATA(ls_old) = find_by_id( iv_cost_id ).

    rs_entry = is_entry.
    rs_entry-cost_id = iv_cost_id.

    " 금액 재계산
    IF rs_entry-quantity > 0 AND rs_entry-unit_price > 0.
      rs_entry-amount = rs_entry-quantity * rs_entry-unit_price.
    ENDIF.

    MOVE-CORRESPONDING rs_entry TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-created_by = ls_old-created_by.  " 최초 입력자 유지

    UPDATE zconstruction_cost FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.

    update_project_actual_cost( rs_entry-project_id ).
  ENDMETHOD.

  METHOD delete_cost_entry.
    DATA(ls_entry) = find_by_id( iv_cost_id ).
    DELETE FROM zconstruction_cost
      WHERE cost_id = @iv_cost_id AND mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    update_project_actual_cost( ls_entry-project_id ).
  ENDMETHOD.

  METHOD update_project_actual_cost.
    DATA lv_total TYPE p LENGTH 15 DECIMALS 2.
    SELECT SUM( amount ) FROM zconstruction_cost
      WHERE project_id = @iv_project_id INTO @lv_total.
    UPDATE zconstruction_proj SET actual_cost = @lv_total
      WHERE project_id = @iv_project_id AND mandt = @sy-mandt.
  ENDMETHOD.

  METHOD get_next_id.
    DATA lv_max TYPE n LENGTH 10.
    SELECT MAX( cost_id ) FROM zconstruction_cost INTO @lv_max.
    rv_id = COND #( WHEN lv_max IS NOT INITIAL THEN lv_max + 1 ELSE 1 ).
  ENDMETHOD.

ENDCLASS.
