*&---------------------------------------------------------------------*
*& Class: ZCL_EQUIPMENT_SERVICE
*& Description: 장비 서비스 클래스 (EquipmentService.java 동일 기능)
*&---------------------------------------------------------------------*

CLASS zcl_equipment_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_equipment,
        equipment_id    TYPE n LENGTH 10,
        equipment_code  TYPE c LENGTH 20,
        equipment_name  TYPE c LENGTH 200,
        equipment_type  TYPE c LENGTH 20,
        model           TYPE c LENGTH 100,
        manufacturer    TYPE c LENGTH 100,
        registration_no TYPE c LENGTH 20,
        status          TYPE c LENGTH 20,
        current_project TYPE n LENGTH 10,
        acquisition_date TYPE datum,
        acquisition_cost TYPE p LENGTH 15 DECIMALS 2,
        is_rented       TYPE abap_bool,
        rental_cost_day TYPE p LENGTH 15 DECIMALS 2,
        next_maint_date TYPE datum,
        total_op_hours  TYPE p LENGTH 10 DECIMALS 1,
        waers           TYPE waers,
      END OF ty_equipment,
      ty_equipments TYPE STANDARD TABLE OF ty_equipment WITH KEY equipment_id.

    METHODS find_all
      RETURNING VALUE(rt_equipments) TYPE ty_equipments.

    METHODS find_by_id
      IMPORTING iv_equipment_id    TYPE n
      RETURNING VALUE(rs_equipment) TYPE ty_equipment
      RAISING   cx_abap_not_found.

    METHODS find_by_status
      IMPORTING iv_status           TYPE c
      RETURNING VALUE(rt_equipments) TYPE ty_equipments.

    "! 특정 프로젝트에 배정된 장비 조회
    METHODS find_by_project
      IMPORTING iv_project_id       TYPE n
      RETURNING VALUE(rt_equipments) TYPE ty_equipments.

    METHODS create_equipment
      IMPORTING is_equipment        TYPE ty_equipment
      RETURNING VALUE(rs_equipment)  TYPE ty_equipment
      RAISING   cx_sy_dyn_call_error.

    METHODS update_equipment
      IMPORTING iv_equipment_id    TYPE n
                is_equipment       TYPE ty_equipment
      RETURNING VALUE(rs_equipment) TYPE ty_equipment
      RAISING   cx_sy_dyn_call_error
                cx_abap_not_found.

    "! 장비를 프로젝트에 배정 (상태 → IN_USE)
    METHODS assign_to_project
      IMPORTING iv_equipment_id TYPE n
                iv_project_id   TYPE n
      RAISING   cx_sy_dyn_call_error
                cx_abap_not_found.

    METHODS delete_equipment
      IMPORTING iv_equipment_id TYPE n
      RAISING   cx_sy_dyn_call_error
                cx_abap_not_found.

  PRIVATE SECTION.
    METHODS get_next_id
      RETURNING VALUE(rv_id) TYPE n.

ENDCLASS.


CLASS zcl_equipment_service IMPLEMENTATION.

  METHOD find_all.
    SELECT equipment_id equipment_code equipment_name equipment_type
           model manufacturer registration_no status current_project
           acquisition_date acquisition_cost is_rented rental_cost_day
           next_maint_date total_op_hours waers
      FROM zconstruction_equip
      INTO CORRESPONDING FIELDS OF TABLE @rt_equipments
      ORDER BY equipment_id.
  ENDMETHOD.


  METHOD find_by_id.
    SELECT SINGLE equipment_id equipment_code equipment_name equipment_type
                  model manufacturer registration_no status current_project
                  acquisition_date acquisition_cost is_rented rental_cost_day
                  next_maint_date total_op_hours waers
      FROM zconstruction_equip
      WHERE equipment_id = @iv_equipment_id
      INTO CORRESPONDING FIELDS OF @rs_equipment.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.
  ENDMETHOD.


  METHOD find_by_status.
    SELECT equipment_id equipment_code equipment_name equipment_type
           model manufacturer registration_no status current_project
           acquisition_date acquisition_cost is_rented rental_cost_day
           next_maint_date total_op_hours waers
      FROM zconstruction_equip
      WHERE status = @iv_status
      INTO CORRESPONDING FIELDS OF TABLE @rt_equipments
      ORDER BY equipment_id.
  ENDMETHOD.


  METHOD find_by_project.
    SELECT equipment_id equipment_code equipment_name equipment_type
           model manufacturer registration_no status current_project
           acquisition_date acquisition_cost is_rented rental_cost_day
           next_maint_date total_op_hours waers
      FROM zconstruction_equip
      WHERE current_project = @iv_project_id
      INTO CORRESPONDING FIELDS OF TABLE @rt_equipments
      ORDER BY equipment_id.
  ENDMETHOD.


  METHOD create_equipment.
    DATA ls_db TYPE zconstruction_equip.

    rs_equipment = is_equipment.
    rs_equipment-equipment_id = get_next_id( ).

    MOVE-CORRESPONDING rs_equipment TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-created_by = sy-uname.
    GET TIME STAMP FIELD ls_db-created_at.

    INSERT zconstruction_equip FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.


  METHOD update_equipment.
    DATA ls_db TYPE zconstruction_equip.

    find_by_id( iv_equipment_id ).

    rs_equipment = is_equipment.
    rs_equipment-equipment_id = iv_equipment_id.

    MOVE-CORRESPONDING rs_equipment TO ls_db.
    ls_db-mandt = sy-mandt.

    UPDATE zconstruction_equip FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.


  METHOD assign_to_project.
    "! 장비 상태를 IN_USE로 변경하고 프로젝트 할당
    find_by_id( iv_equipment_id ).

    UPDATE zconstruction_equip
      SET status          = 'IN_USE',
          current_project = @iv_project_id
      WHERE equipment_id = @iv_equipment_id
        AND mandt          = @sy-mandt.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.


  METHOD delete_equipment.
    find_by_id( iv_equipment_id ).

    DELETE FROM zconstruction_equip
      WHERE equipment_id = @iv_equipment_id
        AND mandt          = @sy-mandt.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.


  METHOD get_next_id.
    DATA lv_max TYPE n LENGTH 10.
    SELECT MAX( equipment_id ) FROM zconstruction_equip INTO @lv_max.
    rv_id = COND #( WHEN lv_max IS NOT INITIAL THEN lv_max + 1 ELSE 1 ).
  ENDMETHOD.

ENDCLASS.
