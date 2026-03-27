*&---------------------------------------------------------------------*
*& Class: ZCL_PO_SERVICE
*& Description: 구매발주 서비스 클래스 (PurchaseOrderService.java 동일 기능)
*&---------------------------------------------------------------------*

CLASS zcl_po_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      "! 발주 아이템 타입
      BEGIN OF ty_po_item,
        po_id         TYPE n LENGTH 10,
        item_no       TYPE n LENGTH 3,
        material_id   TYPE n LENGTH 10,
        item_desc     TYPE c LENGTH 200,
        quantity      TYPE p LENGTH 13 DECIMALS 3,
        unit          TYPE t006-msehi,
        unit_price    TYPE p LENGTH 15 DECIMALS 2,
        supply_amount TYPE p LENGTH 15 DECIMALS 2,
        vat_amount    TYPE p LENGTH 15 DECIMALS 2,
        total_amount  TYPE p LENGTH 15 DECIMALS 2,
        received_qty  TYPE p LENGTH 13 DECIMALS 3,
        waers         TYPE waers,
      END OF ty_po_item,
      ty_po_items TYPE STANDARD TABLE OF ty_po_item WITH KEY po_id item_no,

      "! 발주 헤더 타입
      BEGIN OF ty_po,
        po_id         TYPE n LENGTH 10,
        po_number     TYPE c LENGTH 20,
        project_id    TYPE n LENGTH 10,
        vendor_name   TYPE c LENGTH 100,
        vendor_code   TYPE c LENGTH 20,
        status        TYPE c LENGTH 20,
        order_date    TYPE datum,
        delivery_date TYPE datum,
        delivery_addr TYPE c LENGTH 200,
        total_amount  TYPE p LENGTH 15 DECIMALS 2,
        waers         TYPE waers,
        purchaser     TYPE c LENGTH 50,
        remarks       TYPE c LENGTH 500,
        items         TYPE ty_po_items,    "< 아이템 포함
      END OF ty_po,
      ty_pos TYPE STANDARD TABLE OF ty_po WITH KEY po_id.

    METHODS find_all
      RETURNING VALUE(rt_pos) TYPE ty_pos.

    METHODS find_by_id
      IMPORTING iv_po_id    TYPE n
      RETURNING VALUE(rs_po) TYPE ty_po
      RAISING   cx_abap_not_found.

    METHODS find_by_project
      IMPORTING iv_project_id TYPE n
      RETURNING VALUE(rt_pos)  TYPE ty_pos.

    METHODS find_by_status
      IMPORTING iv_status    TYPE c
      RETURNING VALUE(rt_pos) TYPE ty_pos.

    METHODS create_po
      IMPORTING is_po       TYPE ty_po
      RETURNING VALUE(rs_po) TYPE ty_po
      RAISING   cx_sy_dyn_call_error.

    "! 발주 상태 변경
    METHODS update_status
      IMPORTING iv_po_id   TYPE n
                iv_status  TYPE c
      RAISING   cx_sy_dyn_call_error
                cx_abap_not_found.

    METHODS delete_po
      IMPORTING iv_po_id TYPE n
      RAISING   cx_sy_dyn_call_error
                cx_abap_not_found.

  PRIVATE SECTION.
    METHODS get_next_po_id
      RETURNING VALUE(rv_id) TYPE n.

    "! 아이템의 금액 자동계산 후 헤더 합계 갱신
    METHODS calc_amounts
      CHANGING cs_po TYPE ty_po.

    "! 아이템 목록 조회
    METHODS load_items
      IMPORTING iv_po_id        TYPE n
      RETURNING VALUE(rt_items) TYPE ty_po_items.

ENDCLASS.


CLASS zcl_po_service IMPLEMENTATION.

  METHOD find_all.
    DATA lt_headers TYPE STANDARD TABLE OF zconstruction_po.

    SELECT * FROM zconstruction_po
      INTO TABLE @lt_headers
      ORDER BY po_id.

    LOOP AT lt_headers INTO DATA(ls_hdr).
      DATA(ls_po) = VALUE ty_po(
        po_id         = ls_hdr-po_id
        po_number     = ls_hdr-po_number
        project_id    = ls_hdr-project_id
        vendor_name   = ls_hdr-vendor_name
        vendor_code   = ls_hdr-vendor_code
        status        = ls_hdr-status
        order_date    = ls_hdr-order_date
        delivery_date = ls_hdr-delivery_date
        delivery_addr = ls_hdr-delivery_addr
        total_amount  = ls_hdr-total_amount
        waers         = ls_hdr-waers
        purchaser     = ls_hdr-purchaser
        remarks       = ls_hdr-remarks
        items         = load_items( ls_hdr-po_id )
      ).
      APPEND ls_po TO rt_pos.
    ENDLOOP.
  ENDMETHOD.


  METHOD find_by_id.
    DATA ls_hdr TYPE zconstruction_po.

    SELECT SINGLE * FROM zconstruction_po
      WHERE po_id = @iv_po_id
      INTO @ls_hdr.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.

    rs_po = VALUE ty_po(
      po_id         = ls_hdr-po_id
      po_number     = ls_hdr-po_number
      project_id    = ls_hdr-project_id
      vendor_name   = ls_hdr-vendor_name
      vendor_code   = ls_hdr-vendor_code
      status        = ls_hdr-status
      order_date    = ls_hdr-order_date
      delivery_date = ls_hdr-delivery_date
      delivery_addr = ls_hdr-delivery_addr
      total_amount  = ls_hdr-total_amount
      waers         = ls_hdr-waers
      purchaser     = ls_hdr-purchaser
      remarks       = ls_hdr-remarks
      items         = load_items( ls_hdr-po_id )
    ).
  ENDMETHOD.


  METHOD find_by_project.
    SELECT po_id FROM zconstruction_po
      WHERE project_id = @iv_project_id
      INTO TABLE @DATA(lt_ids).

    LOOP AT lt_ids INTO DATA(ls_id).
      TRY.
          APPEND find_by_id( ls_id-po_id ) TO rt_pos.
        CATCH cx_abap_not_found. "#EC NO_HANDLER
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD find_by_status.
    SELECT po_id FROM zconstruction_po
      WHERE status = @iv_status
      INTO TABLE @DATA(lt_ids).

    LOOP AT lt_ids INTO DATA(ls_id).
      TRY.
          APPEND find_by_id( ls_id-po_id ) TO rt_pos.
        CATCH cx_abap_not_found. "#EC NO_HANDLER
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD create_po.
    DATA ls_db_hdr  TYPE zconstruction_po.
    DATA ls_db_item TYPE zconstruction_poi.

    rs_po = is_po.
    rs_po-po_id = get_next_po_id( ).

    "! 금액 자동계산
    calc_amounts( CHANGING cs_po = rs_po ).

    "! 헤더 INSERT
    MOVE-CORRESPONDING rs_po TO ls_db_hdr.
    ls_db_hdr-mandt      = sy-mandt.
    ls_db_hdr-created_by = sy-uname.
    GET TIME STAMP FIELD ls_db_hdr-created_at.
    INSERT zconstruction_po FROM ls_db_hdr.

    "! 아이템 INSERT
    DATA lv_item_no TYPE n LENGTH 3 VALUE '001'.
    LOOP AT rs_po-items INTO DATA(ls_item).
      ls_db_item-mandt    = sy-mandt.
      ls_db_item-po_id    = rs_po-po_id.
      ls_db_item-item_no  = lv_item_no.
      MOVE-CORRESPONDING ls_item TO ls_db_item.
      ls_db_item-po_id   = rs_po-po_id.
      ls_db_item-item_no = lv_item_no.
      INSERT zconstruction_poi FROM ls_db_item.
      lv_item_no = lv_item_no + 1.
    ENDLOOP.
  ENDMETHOD.


  METHOD update_status.
    find_by_id( iv_po_id ).

    UPDATE zconstruction_po
      SET status = @iv_status
      WHERE po_id = @iv_po_id
        AND mandt   = @sy-mandt.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.


  METHOD delete_po.
    find_by_id( iv_po_id ).

    DELETE FROM zconstruction_poi WHERE po_id = @iv_po_id AND mandt = @sy-mandt.
    DELETE FROM zconstruction_po  WHERE po_id = @iv_po_id AND mandt = @sy-mandt.
  ENDMETHOD.


  METHOD load_items.
    SELECT po_id item_no material_id item_desc quantity unit unit_price
           supply_amount vat_amount total_amount received_qty waers
      FROM zconstruction_poi
      WHERE po_id = @iv_po_id
      INTO CORRESPONDING FIELDS OF TABLE @rt_items
      ORDER BY item_no.
  ENDMETHOD.


  METHOD calc_amounts.
    DATA lv_total TYPE p LENGTH 15 DECIMALS 2.

    LOOP AT cs_po-items ASSIGNING FIELD-SYMBOL(<item>).
      <item>-supply_amount = <item>-quantity * <item>-unit_price.
      <item>-vat_amount    = <item>-supply_amount * '0.1'.
      <item>-total_amount  = <item>-supply_amount + <item>-vat_amount.
      lv_total = lv_total + <item>-total_amount.
    ENDLOOP.

    cs_po-total_amount = lv_total.
  ENDMETHOD.


  METHOD get_next_po_id.
    DATA lv_max TYPE n LENGTH 10.
    SELECT MAX( po_id ) FROM zconstruction_po INTO @lv_max.
    rv_id = COND #( WHEN lv_max IS NOT INITIAL THEN lv_max + 1 ELSE 1 ).
  ENDMETHOD.

ENDCLASS.
