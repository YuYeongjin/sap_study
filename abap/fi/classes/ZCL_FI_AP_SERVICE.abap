*&---------------------------------------------------------------------*
*& Class: ZCL_FI_AP_SERVICE
*& Description: 매입채무 서비스 (Accounts Payable Service)
*& 담당업무: 벤더 마스터 관리, 매입전표 처리, 지급처리, 연령분석
*& Transaction: SE24
*&---------------------------------------------------------------------*

CLASS zcl_fi_ap_service DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      " 벤더 마스터
      BEGIN OF ty_vendor,
        lifnr      TYPE lifnr,
        bukrs      TYPE bukrs,
        name1      TYPE name1,
        stcd1      TYPE stcd1,
        akont      TYPE saknr,
        zterm      TYPE dzterm,
        vend_type  TYPE c LENGTH 4,
        sperr      TYPE c LENGTH 1,
        telf1      TYPE telf1,
        smtp_addr  TYPE ad_smtpadr,
        bankn      TYPE bankn,
        waers      TYPE waers,
        created_by TYPE uname,
      END OF ty_vendor,
      ty_vendors TYPE STANDARD TABLE OF ty_vendor WITH KEY lifnr,

      " 매입전표 (헤더+아이템)
      BEGIN OF ty_ap_item,
        ap_itemno    TYPE n LENGTH 3,
        saknr        TYPE saknr,
        kostl        TYPE kostl,
        aufnr        TYPE aufnr,
        prctr        TYPE prctr,
        item_text    TYPE c LENGTH 50,
        net_amount   TYPE p LENGTH 15 DECIMALS 2,
        tax_code     TYPE mwskz,
        tax_amount   TYPE p LENGTH 15 DECIMALS 2,
        gross_amount TYPE p LENGTH 15 DECIMALS 2,
        matnr        TYPE matnr,
        menge        TYPE menge_d,
        meins        TYPE meins,
        netpr        TYPE p LENGTH 15 DECIMALS 2,
      END OF ty_ap_item,
      ty_ap_items TYPE STANDARD TABLE OF ty_ap_item WITH KEY ap_itemno,

      BEGIN OF ty_ap_invoice,
        bukrs        TYPE bukrs,
        ap_invno     TYPE c LENGTH 10,
        gjahr        TYPE gjahr,
        lifnr        TYPE lifnr,
        vend_name    TYPE name1,
        belnr        TYPE belnr_d,
        bldat        TYPE bldat,
        budat        TYPE budat,
        xblnr        TYPE xblnr,
        bktxt        TYPE bktxt,
        waers        TYPE waers,
        gross_amount TYPE p LENGTH 15 DECIMALS 2,
        net_amount   TYPE p LENGTH 15 DECIMALS 2,
        tax_amount   TYPE p LENGTH 15 DECIMALS 2,
        zterm        TYPE dzterm,
        due_date     TYPE datum,
        pay_status   TYPE c LENGTH 1,
        paid_amount  TYPE p LENGTH 15 DECIMALS 2,
        paid_date    TYPE datum,
        ebeln        TYPE ebeln,
        ap_type      TYPE c LENGTH 4,
        items        TYPE ty_ap_items,
        created_by   TYPE uname,
      END OF ty_ap_invoice,
      ty_ap_invoices TYPE STANDARD TABLE OF ty_ap_invoice WITH KEY ap_invno,

      " AP 연령분석
      BEGIN OF ty_ap_aging,
        lifnr        TYPE lifnr,
        vend_name    TYPE name1,
        total_open   TYPE p LENGTH 15 DECIMALS 2,
        not_due      TYPE p LENGTH 15 DECIMALS 2,
        overdue_30   TYPE p LENGTH 15 DECIMALS 2,
        overdue_60   TYPE p LENGTH 15 DECIMALS 2,
        overdue_90   TYPE p LENGTH 15 DECIMALS 2,
        overdue_90p  TYPE p LENGTH 15 DECIMALS 2,
      END OF ty_ap_aging,
      ty_ap_agings TYPE STANDARD TABLE OF ty_ap_aging WITH KEY lifnr,

      " 지급 처리 요청
      BEGIN OF ty_payment_request,
        bukrs        TYPE bukrs,
        ap_invno     TYPE c LENGTH 10,
        gjahr        TYPE gjahr,
        pay_amount   TYPE p LENGTH 15 DECIMALS 2,
        pay_date     TYPE datum,
        zlsch        TYPE dzlsch,
        bank_account TYPE bankn,
        memo         TYPE c LENGTH 50,
      END OF ty_payment_request.

    " ================================================================
    " 벤더 마스터 CRUD
    " ================================================================
    METHODS:
      find_all_vendors
        IMPORTING iv_bukrs          TYPE bukrs
        RETURNING VALUE(rt_vendors) TYPE ty_vendors,

      find_vendor_by_id
        IMPORTING iv_lifnr          TYPE lifnr
                  iv_bukrs          TYPE bukrs
        RETURNING VALUE(rs_vendor)  TYPE ty_vendor
        RAISING   cx_abap_not_found,

      find_vendors_by_type
        IMPORTING iv_bukrs          TYPE bukrs
                  iv_vend_type      TYPE c
        RETURNING VALUE(rt_vendors) TYPE ty_vendors,

      search_vendors
        IMPORTING iv_bukrs          TYPE bukrs
                  iv_keyword        TYPE c
        RETURNING VALUE(rt_vendors) TYPE ty_vendors,

      create_vendor
        IMPORTING is_vendor         TYPE ty_vendor
        RETURNING VALUE(rs_vendor)  TYPE ty_vendor
        RAISING   cx_sy_dyn_call_error,

      update_vendor
        IMPORTING iv_lifnr          TYPE lifnr
                  iv_bukrs          TYPE bukrs
                  is_vendor         TYPE ty_vendor
        RETURNING VALUE(rs_vendor)  TYPE ty_vendor
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      block_vendor
        IMPORTING iv_lifnr TYPE lifnr
                  iv_bukrs TYPE bukrs
        RAISING   cx_abap_not_found,

      " ================================================================
      " 매입전표 CRUD
      " ================================================================
      find_ap_invoices
        IMPORTING iv_bukrs             TYPE bukrs
                  iv_gjahr             TYPE gjahr
                  iv_lifnr             TYPE lifnr OPTIONAL
                  iv_pay_status        TYPE c OPTIONAL
        RETURNING VALUE(rt_invoices)   TYPE ty_ap_invoices,

      find_ap_invoice_by_id
        IMPORTING iv_bukrs             TYPE bukrs
                  iv_ap_invno          TYPE c
                  iv_gjahr             TYPE gjahr
        RETURNING VALUE(rs_invoice)    TYPE ty_ap_invoice
        RAISING   cx_abap_not_found,

      find_overdue_invoices
        IMPORTING iv_bukrs             TYPE bukrs
        RETURNING VALUE(rt_invoices)   TYPE ty_ap_invoices,

      "! 매입전표 생성 + FI 전표 자동 전기
      create_ap_invoice
        IMPORTING is_invoice           TYPE ty_ap_invoice
        RETURNING VALUE(rs_invoice)    TYPE ty_ap_invoice
        RAISING   cx_sy_dyn_call_error,

      "! 매입전표 수정 (미지급 상태만 가능)
      update_ap_invoice
        IMPORTING iv_ap_invno          TYPE c
                  iv_gjahr             TYPE gjahr
                  is_invoice           TYPE ty_ap_invoice
        RETURNING VALUE(rs_invoice)    TYPE ty_ap_invoice
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      "! 매입전표 삭제 (미지급 상태만 가능)
      delete_ap_invoice
        IMPORTING iv_bukrs   TYPE bukrs
                  iv_ap_invno TYPE c
                  iv_gjahr   TYPE gjahr
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      "! 지급 처리 (FI 지급전표 생성)
      process_payment
        IMPORTING is_pay_req           TYPE ty_payment_request
        RETURNING VALUE(rv_pay_belnr)  TYPE belnr_d
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      "! AP 연령분석 (기준일 기준 미결항목)
      get_ap_aging
        IMPORTING iv_bukrs           TYPE bukrs
                  iv_key_date        TYPE datum
        RETURNING VALUE(rt_aging)    TYPE ty_ap_agings,

      "! 벤더별 매입채무 잔액
      get_vendor_balance
        IMPORTING iv_bukrs          TYPE bukrs
                  iv_lifnr          TYPE lifnr
        RETURNING VALUE(rv_balance) TYPE p.

  PRIVATE SECTION.
    METHODS:
      get_next_ap_invno
        IMPORTING iv_bukrs          TYPE bukrs
                  iv_gjahr          TYPE gjahr
        RETURNING VALUE(rv_invno)   TYPE c LENGTH 10,

      post_fi_ap_document
        IMPORTING is_invoice TYPE ty_ap_invoice
        RETURNING VALUE(rv_belnr) TYPE belnr_d
        RAISING   cx_sy_dyn_call_error,

      calc_due_date
        IMPORTING iv_zfbdt        TYPE datum
                  iv_zterm        TYPE dzterm
        RETURNING VALUE(rv_date)  TYPE datum.

ENDCLASS.


CLASS zcl_fi_ap_service IMPLEMENTATION.

  " ================================================================
  " 벤더 마스터 CRUD
  " ================================================================

  METHOD find_all_vendors.
    SELECT lifnr bukrs name1 stcd1 akont zterm vend_type sperr telf1 smtp_addr bankn waers created_by
      FROM zfi_vendor
      WHERE bukrs = @iv_bukrs AND loevm <> 'X'
      INTO CORRESPONDING FIELDS OF TABLE @rt_vendors
      ORDER BY lifnr.
  ENDMETHOD.

  METHOD find_vendor_by_id.
    SELECT SINGLE lifnr bukrs name1 stcd1 akont zterm vend_type sperr telf1 smtp_addr bankn waers created_by
      FROM zfi_vendor
      WHERE lifnr = @iv_lifnr AND bukrs = @iv_bukrs
      INTO CORRESPONDING FIELDS OF @rs_vendor.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.
  ENDMETHOD.

  METHOD find_vendors_by_type.
    SELECT lifnr bukrs name1 stcd1 akont zterm vend_type sperr telf1 smtp_addr bankn waers created_by
      FROM zfi_vendor
      WHERE bukrs = @iv_bukrs AND vend_type = @iv_vend_type AND loevm <> 'X'
      INTO CORRESPONDING FIELDS OF TABLE @rt_vendors
      ORDER BY name1.
  ENDMETHOD.

  METHOD search_vendors.
    DATA lv_pattern TYPE c LENGTH 37.
    lv_pattern = |%{ iv_keyword }%|.
    SELECT lifnr bukrs name1 stcd1 akont zterm vend_type sperr telf1 smtp_addr bankn waers created_by
      FROM zfi_vendor
      WHERE bukrs = @iv_bukrs AND loevm <> 'X'
        AND ( name1 LIKE @lv_pattern OR lifnr LIKE @lv_pattern OR stcd1 LIKE @lv_pattern )
      INTO CORRESPONDING FIELDS OF TABLE @rt_vendors
      ORDER BY name1.
  ENDMETHOD.

  METHOD create_vendor.
    DATA ls_db TYPE zfi_vendor.
    " 중복 체크
    SELECT COUNT(*) FROM zfi_vendor
      WHERE lifnr = @is_vendor-lifnr AND bukrs = @is_vendor-bukrs
      INTO @DATA(lv_cnt).
    IF lv_cnt > 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    rs_vendor = is_vendor.
    MOVE-CORRESPONDING rs_vendor TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-created_by = sy-uname.
    GET TIME STAMP FIELD ls_db-created_at.
    INSERT zfi_vendor FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD update_vendor.
    find_vendor_by_id( iv_lifnr = iv_lifnr iv_bukrs = iv_bukrs ).
    rs_vendor = is_vendor.
    UPDATE zfi_vendor
      SET name1      = @rs_vendor-name1,
          telf1      = @rs_vendor-telf1,
          smtp_addr  = @rs_vendor-smtp_addr,
          zterm      = @rs_vendor-zterm,
          vend_type  = @rs_vendor-vend_type,
          bankn      = @rs_vendor-bankn,
          changed_by = @sy-uname
      WHERE lifnr = @iv_lifnr AND bukrs = @iv_bukrs AND mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD block_vendor.
    find_vendor_by_id( iv_lifnr = iv_lifnr iv_bukrs = iv_bukrs ).
    UPDATE zfi_vendor
      SET sperr      = 'X',
          changed_by = @sy-uname
      WHERE lifnr = @iv_lifnr AND bukrs = @iv_bukrs AND mandt = @sy-mandt.
  ENDMETHOD.

  " ================================================================
  " 매입전표 CRUD
  " ================================================================

  METHOD find_ap_invoices.
    IF iv_lifnr IS NOT INITIAL AND iv_pay_status IS NOT INITIAL.
      SELECT ap~bukrs ap~ap_invno ap~gjahr ap~lifnr v~name1 ap~belnr ap~bldat ap~budat
             ap~xblnr ap~bktxt ap~waers ap~gross_amount ap~net_amount ap~tax_amount
             ap~zterm ap~due_date ap~pay_status ap~paid_amount ap~paid_date ap~ebeln
             ap~ap_type ap~created_by
        FROM zfi_ap_invoice AS ap
        LEFT JOIN zfi_vendor AS v ON v~lifnr = ap~lifnr AND v~bukrs = ap~bukrs
        WHERE ap~bukrs = @iv_bukrs AND ap~gjahr = @iv_gjahr
          AND ap~lifnr = @iv_lifnr AND ap~pay_status = @iv_pay_status
        INTO CORRESPONDING FIELDS OF TABLE @rt_invoices
        ORDER BY ap~budat DESCENDING.
    ELSEIF iv_lifnr IS NOT INITIAL.
      SELECT ap~bukrs ap~ap_invno ap~gjahr ap~lifnr v~name1 ap~belnr ap~bldat ap~budat
             ap~xblnr ap~bktxt ap~waers ap~gross_amount ap~net_amount ap~tax_amount
             ap~zterm ap~due_date ap~pay_status ap~paid_amount ap~paid_date ap~ebeln
             ap~ap_type ap~created_by
        FROM zfi_ap_invoice AS ap
        LEFT JOIN zfi_vendor AS v ON v~lifnr = ap~lifnr AND v~bukrs = ap~bukrs
        WHERE ap~bukrs = @iv_bukrs AND ap~gjahr = @iv_gjahr AND ap~lifnr = @iv_lifnr
        INTO CORRESPONDING FIELDS OF TABLE @rt_invoices
        ORDER BY ap~budat DESCENDING.
    ELSE.
      SELECT ap~bukrs ap~ap_invno ap~gjahr ap~lifnr v~name1 ap~belnr ap~bldat ap~budat
             ap~xblnr ap~bktxt ap~waers ap~gross_amount ap~net_amount ap~tax_amount
             ap~zterm ap~due_date ap~pay_status ap~paid_amount ap~paid_date ap~ebeln
             ap~ap_type ap~created_by
        FROM zfi_ap_invoice AS ap
        LEFT JOIN zfi_vendor AS v ON v~lifnr = ap~lifnr AND v~bukrs = ap~bukrs
        WHERE ap~bukrs = @iv_bukrs AND ap~gjahr = @iv_gjahr
        INTO CORRESPONDING FIELDS OF TABLE @rt_invoices
        ORDER BY ap~budat DESCENDING.
    ENDIF.
  ENDMETHOD.

  METHOD find_ap_invoice_by_id.
    SELECT SINGLE ap~bukrs ap~ap_invno ap~gjahr ap~lifnr v~name1 ap~belnr ap~bldat ap~budat
                  ap~xblnr ap~bktxt ap~waers ap~gross_amount ap~net_amount ap~tax_amount
                  ap~zterm ap~due_date ap~pay_status ap~paid_amount ap~paid_date ap~ebeln
                  ap~ap_type ap~created_by
      FROM zfi_ap_invoice AS ap
      LEFT JOIN zfi_vendor AS v ON v~lifnr = ap~lifnr AND v~bukrs = ap~bukrs
      WHERE ap~bukrs = @iv_bukrs AND ap~ap_invno = @iv_ap_invno AND ap~gjahr = @iv_gjahr
      INTO CORRESPONDING FIELDS OF @rs_invoice.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.
    " 아이템 조회
    SELECT ap_itemno saknr kostl aufnr prctr item_text net_amount tax_code
           tax_amount gross_amount matnr menge meins netpr
      FROM zfi_ap_item
      WHERE bukrs = @iv_bukrs AND ap_invno = @iv_ap_invno AND gjahr = @iv_gjahr
      INTO CORRESPONDING FIELDS OF TABLE @rs_invoice-items
      ORDER BY ap_itemno.
  ENDMETHOD.

  METHOD find_overdue_invoices.
    SELECT ap~bukrs ap~ap_invno ap~gjahr ap~lifnr v~name1 ap~belnr ap~bldat ap~budat
           ap~xblnr ap~bktxt ap~waers ap~gross_amount ap~net_amount ap~tax_amount
           ap~zterm ap~due_date ap~pay_status ap~paid_amount ap~paid_date ap~ebeln
           ap~ap_type ap~created_by
      FROM zfi_ap_invoice AS ap
      LEFT JOIN zfi_vendor AS v ON v~lifnr = ap~lifnr AND v~bukrs = ap~bukrs
      WHERE ap~bukrs = @iv_bukrs
        AND ap~pay_status IN (' ', 'P')
        AND ap~due_date < @sy-datum
      INTO CORRESPONDING FIELDS OF TABLE @rt_invoices
      ORDER BY ap~due_date.
  ENDMETHOD.

  METHOD create_ap_invoice.
    DATA ls_db TYPE zfi_ap_invoice.
    rs_invoice = is_invoice.
    rs_invoice-ap_invno = get_next_ap_invno(
      iv_bukrs = is_invoice-bukrs iv_gjahr = is_invoice-gjahr ).
    rs_invoice-pay_status = ' '.
    " 만기일 계산
    rs_invoice-due_date = calc_due_date(
      iv_zfbdt = is_invoice-budat iv_zterm = is_invoice-zterm ).
    " FI 전표 전기
    rs_invoice-belnr = post_fi_ap_document( rs_invoice ).
    MOVE-CORRESPONDING rs_invoice TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-created_by = sy-uname.
    GET TIME STAMP FIELD ls_db-created_at.
    INSERT zfi_ap_invoice FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    " 아이템 INSERT
    DATA ls_item TYPE zfi_ap_item.
    LOOP AT rs_invoice-items INTO DATA(ls_src).
      MOVE-CORRESPONDING ls_src TO ls_item.
      ls_item-mandt    = sy-mandt.
      ls_item-bukrs    = rs_invoice-bukrs.
      ls_item-ap_invno = rs_invoice-ap_invno.
      ls_item-gjahr    = rs_invoice-gjahr.
      INSERT zfi_ap_item FROM ls_item.
    ENDLOOP.
  ENDMETHOD.

  METHOD update_ap_invoice.
    DATA(ls_old) = find_ap_invoice_by_id(
      iv_bukrs = is_invoice-bukrs iv_ap_invno = iv_ap_invno iv_gjahr = iv_gjahr ).
    " 미지급 상태만 수정 가능
    IF ls_old-pay_status <> ' '.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    rs_invoice = is_invoice.
    rs_invoice-ap_invno = iv_ap_invno.
    UPDATE zfi_ap_invoice
      SET gross_amount = @rs_invoice-gross_amount,
          net_amount   = @rs_invoice-net_amount,
          tax_amount   = @rs_invoice-tax_amount,
          bktxt        = @rs_invoice-bktxt,
          zterm        = @rs_invoice-zterm,
          due_date     = @rs_invoice-due_date
      WHERE bukrs = @rs_invoice-bukrs AND ap_invno = @iv_ap_invno
        AND gjahr = @iv_gjahr AND mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD delete_ap_invoice.
    DATA(ls_inv) = find_ap_invoice_by_id(
      iv_bukrs = iv_bukrs iv_ap_invno = iv_ap_invno iv_gjahr = iv_gjahr ).
    IF ls_inv-pay_status <> ' '.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    DELETE FROM zfi_ap_item
      WHERE bukrs = @iv_bukrs AND ap_invno = @iv_ap_invno AND gjahr = @iv_gjahr
        AND mandt = @sy-mandt.
    DELETE FROM zfi_ap_invoice
      WHERE bukrs = @iv_bukrs AND ap_invno = @iv_ap_invno AND gjahr = @iv_gjahr
        AND mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD process_payment.
    DATA(ls_inv) = find_ap_invoice_by_id(
      iv_bukrs  = is_pay_req-bukrs
      iv_ap_invno = is_pay_req-ap_invno
      iv_gjahr  = is_pay_req-gjahr ).

    " 지급가능 상태 체크
    IF ls_inv-pay_status = 'F'.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.

    " 지급전표 생성 (FI: 차) 매입채무 / 대) 보통예금)
    DATA ls_gl_svc TYPE REF TO zcl_fi_gl_service.
    CREATE OBJECT ls_gl_svc.

    DATA ls_header TYPE zcl_fi_gl_service=>ty_journal_header.
    ls_header-bukrs = is_pay_req-bukrs.
    ls_header-blart = 'ZP'.
    ls_header-bldat = is_pay_req-pay_date.
    ls_header-budat = is_pay_req-pay_date.
    ls_header-waers = 'KRW'.
    ls_header-bktxt = |지급:{ is_pay_req-ap_invno }|.

    " 차변: 매입채무(201000)
    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '001' saknr = '201000' shkzg = 'S'
      dmbtr = is_pay_req-pay_amount wrbtr = is_pay_req-pay_amount
      lifnr = ls_inv-lifnr sgtxt = ls_header-bktxt ) TO ls_header-items.

    " 대변: 보통예금(101100)
    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '002' saknr = '101100' shkzg = 'H'
      dmbtr = is_pay_req-pay_amount wrbtr = is_pay_req-pay_amount
      sgtxt = ls_header-bktxt ) TO ls_header-items.

    DATA(ls_posted) = ls_gl_svc->post_journal( ls_header ).
    rv_pay_belnr = ls_posted-belnr.

    " 지급상태 갱신
    DATA lv_new_paid TYPE p LENGTH 15 DECIMALS 2.
    lv_new_paid = ls_inv-paid_amount + is_pay_req-pay_amount.
    DATA lv_new_status TYPE c LENGTH 1.
    lv_new_status = COND #(
      WHEN lv_new_paid >= ls_inv-gross_amount THEN 'F'
      ELSE 'P' ).

    UPDATE zfi_ap_invoice
      SET pay_status  = @lv_new_status,
          paid_amount = @lv_new_paid,
          paid_date   = @is_pay_req-pay_date,
          pay_belnr   = @rv_pay_belnr
      WHERE bukrs = @is_pay_req-bukrs AND ap_invno = @is_pay_req-ap_invno
        AND gjahr = @is_pay_req-gjahr AND mandt = @sy-mandt.
  ENDMETHOD.

  METHOD get_ap_aging.
    SELECT ap~lifnr v~name1
           SUM( ap~gross_amount - ap~paid_amount ) AS total_open
      FROM zfi_ap_invoice AS ap
      LEFT JOIN zfi_vendor AS v ON v~lifnr = ap~lifnr AND v~bukrs = ap~bukrs
      WHERE ap~bukrs = @iv_bukrs AND ap~pay_status IN (' ', 'P')
      GROUP BY ap~lifnr v~name1
      INTO CORRESPONDING FIELDS OF TABLE @rt_aging.

    LOOP AT rt_aging ASSIGNING FIELD-SYMBOL(<aging>).
      " 미도래
      SELECT SUM( gross_amount - paid_amount ) FROM zfi_ap_invoice
        WHERE bukrs = @iv_bukrs AND lifnr = @<aging>-lifnr
          AND pay_status IN (' ', 'P') AND due_date >= @iv_key_date
        INTO @<aging>-not_due.
      " 1~30일 연체
      SELECT SUM( gross_amount - paid_amount ) FROM zfi_ap_invoice
        WHERE bukrs = @iv_bukrs AND lifnr = @<aging>-lifnr
          AND pay_status IN (' ', 'P')
          AND due_date >= @iv_key_date - 30 AND due_date < @iv_key_date
        INTO @<aging>-overdue_30.
      " 31~60일 연체
      SELECT SUM( gross_amount - paid_amount ) FROM zfi_ap_invoice
        WHERE bukrs = @iv_bukrs AND lifnr = @<aging>-lifnr
          AND pay_status IN (' ', 'P')
          AND due_date >= @iv_key_date - 60 AND due_date < @iv_key_date - 30
        INTO @<aging>-overdue_60.
      " 61~90일 연체
      SELECT SUM( gross_amount - paid_amount ) FROM zfi_ap_invoice
        WHERE bukrs = @iv_bukrs AND lifnr = @<aging>-lifnr
          AND pay_status IN (' ', 'P')
          AND due_date >= @iv_key_date - 90 AND due_date < @iv_key_date - 60
        INTO @<aging>-overdue_90.
      " 90일 초과 연체
      SELECT SUM( gross_amount - paid_amount ) FROM zfi_ap_invoice
        WHERE bukrs = @iv_bukrs AND lifnr = @<aging>-lifnr
          AND pay_status IN (' ', 'P')
          AND due_date < @iv_key_date - 90
        INTO @<aging>-overdue_90p.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_vendor_balance.
    SELECT SUM( gross_amount - paid_amount ) FROM zfi_ap_invoice
      WHERE bukrs = @iv_bukrs AND lifnr = @iv_lifnr AND pay_status IN (' ', 'P')
      INTO @rv_balance.
  ENDMETHOD.

  " ================================================================
  " Private 메서드
  " ================================================================

  METHOD get_next_ap_invno.
    DATA lv_max TYPE c LENGTH 10.
    SELECT MAX( ap_invno ) FROM zfi_ap_invoice
      WHERE bukrs = @iv_bukrs AND gjahr = @iv_gjahr
      INTO @lv_max.
    rv_invno = COND #(
      WHEN lv_max IS NOT INITIAL THEN lv_max + 1
      ELSE |{ iv_gjahr }0000001| ).
  ENDMETHOD.

  METHOD post_fi_ap_document.
    " 매입전표 전기: 차) 비용계정 / 대) 매입채무(201000)
    DATA ls_gl_svc TYPE REF TO zcl_fi_gl_service.
    CREATE OBJECT ls_gl_svc.

    DATA ls_header TYPE zcl_fi_gl_service=>ty_journal_header.
    ls_header-bukrs = is_invoice-bukrs.
    ls_header-blart = 'KR'.
    ls_header-bldat = is_invoice-bldat.
    ls_header-budat = is_invoice-budat.
    ls_header-waers = is_invoice-waers.
    ls_header-xblnr = is_invoice-xblnr.
    ls_header-bktxt = is_invoice-bktxt.

    DATA lv_itemno TYPE buzei VALUE 1.
    " 비용 차변 항목 (아이템별)
    LOOP AT is_invoice-items INTO DATA(ls_item).
      APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
        buzei = lv_itemno
        saknr = ls_item-saknr
        shkzg = 'S'
        dmbtr = ls_item-gross_amount
        wrbtr = ls_item-gross_amount
        kostl = ls_item-kostl
        aufnr = ls_item-aufnr
        prctr = ls_item-prctr
        mwskz = ls_item-tax_code
        sgtxt = ls_item-item_text
        lifnr = is_invoice-lifnr ) TO ls_header-items.
      lv_itemno = lv_itemno + 1.
    ENDLOOP.

    " 매입채무 대변 (통합)
    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = lv_itemno
      saknr = '201000'
      shkzg = 'H'
      dmbtr = is_invoice-gross_amount
      wrbtr = is_invoice-gross_amount
      lifnr = is_invoice-lifnr
      sgtxt = is_invoice-bktxt ) TO ls_header-items.

    DATA(ls_posted) = ls_gl_svc->post_journal( ls_header ).
    rv_belnr = ls_posted-belnr.
  ENDMETHOD.

  METHOD calc_due_date.
    " 간단한 지급조건별 만기일 계산
    DATA lv_days TYPE i.
    CASE iv_zterm.
      WHEN 'NT30'. lv_days = 30.
      WHEN 'NT60'. lv_days = 60.
      WHEN 'NT90'. lv_days = 90.
      WHEN 'IMM'.  lv_days = 0.
      WHEN OTHERS. lv_days = 30.
    ENDCASE.
    rv_date = iv_zfbdt + lv_days.
  ENDMETHOD.

ENDCLASS.
