*&---------------------------------------------------------------------*
*& Class: ZCL_MATERIAL_SERVICE
*& Description: 자재 서비스 클래스 (MaterialService.java 동일 기능)
*&---------------------------------------------------------------------*

CLASS zcl_material_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_material,
        material_id    TYPE n LENGTH 10,
        material_code  TYPE c LENGTH 20,
        material_name  TYPE c LENGTH 200,
        category       TYPE c LENGTH 20,
        specification  TYPE c LENGTH 300,
        unit           TYPE t006-msehi,
        standard_price TYPE p LENGTH 15 DECIMALS 2,
        stock_qty      TYPE p LENGTH 13 DECIMALS 3,
        safety_stock   TYPE p LENGTH 13 DECIMALS 3,
        primary_vendor TYPE c LENGTH 100,
        lead_time_days TYPE i,
        waers          TYPE waers,
      END OF ty_material,
      ty_materials TYPE STANDARD TABLE OF ty_material WITH KEY material_id.

    METHODS find_all
      RETURNING VALUE(rt_materials) TYPE ty_materials.

    METHODS find_by_id
      IMPORTING iv_material_id    TYPE n
      RETURNING VALUE(rs_material) TYPE ty_material
      RAISING   cx_abap_not_found.

    METHODS find_by_category
      IMPORTING iv_category        TYPE c
      RETURNING VALUE(rt_materials) TYPE ty_materials.

    METHODS search
      IMPORTING iv_keyword         TYPE c
      RETURNING VALUE(rt_materials) TYPE ty_materials.

    "! 안전재고 미달 자재 조회 (재고 < 안전재고)
    METHODS find_low_stock
      RETURNING VALUE(rt_materials) TYPE ty_materials.

    METHODS create_material
      IMPORTING is_material        TYPE ty_material
      RETURNING VALUE(rs_material)  TYPE ty_material
      RAISING   cx_sy_dyn_call_error.

    METHODS update_material
      IMPORTING iv_material_id    TYPE n
                is_material       TYPE ty_material
      RETURNING VALUE(rs_material) TYPE ty_material
      RAISING   cx_sy_dyn_call_error
                cx_abap_not_found.

    METHODS delete_material
      IMPORTING iv_material_id TYPE n
      RAISING   cx_sy_dyn_call_error
                cx_abap_not_found.

  PRIVATE SECTION.
    METHODS get_next_id
      RETURNING VALUE(rv_id) TYPE n.

ENDCLASS.


CLASS zcl_material_service IMPLEMENTATION.

  METHOD find_all.
    SELECT material_id material_code material_name category
           specification unit standard_price stock_qty safety_stock
           primary_vendor lead_time_days waers
      FROM zconstruction_matl
      INTO CORRESPONDING FIELDS OF TABLE @rt_materials
      ORDER BY material_id.
  ENDMETHOD.


  METHOD find_by_id.
    SELECT SINGLE material_id material_code material_name category
                  specification unit standard_price stock_qty safety_stock
                  primary_vendor lead_time_days waers
      FROM zconstruction_matl
      WHERE material_id = @iv_material_id
      INTO CORRESPONDING FIELDS OF @rs_material.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.
  ENDMETHOD.


  METHOD find_by_category.
    SELECT material_id material_code material_name category
           specification unit standard_price stock_qty safety_stock
           primary_vendor lead_time_days waers
      FROM zconstruction_matl
      WHERE category = @iv_category
      INTO CORRESPONDING FIELDS OF TABLE @rt_materials
      ORDER BY material_id.
  ENDMETHOD.


  METHOD search.
    DATA lv_pattern TYPE c LENGTH 202.
    lv_pattern = '%' && iv_keyword && '%'.

    SELECT material_id material_code material_name category
           specification unit standard_price stock_qty safety_stock
           primary_vendor lead_time_days waers
      FROM zconstruction_matl
      WHERE material_name LIKE @lv_pattern
         OR material_code LIKE @lv_pattern
         OR specification  LIKE @lv_pattern
      INTO CORRESPONDING FIELDS OF TABLE @rt_materials
      ORDER BY material_id.
  ENDMETHOD.


  METHOD find_low_stock.
    "! 재고수량이 안전재고 미만인 자재 조회
    SELECT material_id material_code material_name category
           specification unit standard_price stock_qty safety_stock
           primary_vendor lead_time_days waers
      FROM zconstruction_matl
      WHERE stock_qty < safety_stock
      INTO CORRESPONDING FIELDS OF TABLE @rt_materials
      ORDER BY material_id.
  ENDMETHOD.


  METHOD create_material.
    DATA ls_db TYPE zconstruction_matl.

    rs_material = is_material.
    rs_material-material_id = get_next_id( ).

    MOVE-CORRESPONDING rs_material TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-created_by = sy-uname.
    GET TIME STAMP FIELD ls_db-created_at.

    INSERT zconstruction_matl FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.


  METHOD update_material.
    DATA ls_db TYPE zconstruction_matl.

    find_by_id( iv_material_id ).

    rs_material = is_material.
    rs_material-material_id = iv_material_id.

    MOVE-CORRESPONDING rs_material TO ls_db.
    ls_db-mandt = sy-mandt.

    UPDATE zconstruction_matl FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.


  METHOD delete_material.
    find_by_id( iv_material_id ).

    DELETE FROM zconstruction_matl
      WHERE material_id = @iv_material_id
        AND mandt         = @sy-mandt.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.


  METHOD get_next_id.
    DATA lv_max TYPE n LENGTH 10.
    SELECT MAX( material_id ) FROM zconstruction_matl INTO @lv_max.
    rv_id = COND #( WHEN lv_max IS NOT INITIAL THEN lv_max + 1 ELSE 1 ).
  ENDMETHOD.

ENDCLASS.
