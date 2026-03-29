*&---------------------------------------------------------------------*
*& Class: ZCL_FI_AR_SERVICE
*& Description: 매출채권 서비스 (Accounts Receivable Service)
*& 담당업무: 고객 마스터 관리, 기성청구서 처리, 수금처리, AR 연령분석
*& Transaction: SE24
*&---------------------------------------------------------------------*

CLASS zcl_fi_ar_service DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      " 고객 마스터
      BEGIN OF ty_customer,
        kunnr        TYPE kunnr,
        bukrs        TYPE bukrs,
        name1        TYPE name1,
        stcd1        TYPE stcd1,
        akont        TYPE saknr,
        zterm        TYPE dzterm,
        cust_type    TYPE c LENGTH 4,
        credit_limit TYPE p LENGTH 15 DECIMALS 2,
        credit_used  TYPE p LENGTH 15 DECIMALS 2,
        sperr        TYPE c LENGTH 1,
        telf1        TYPE telf1,
        smtp_addr    TYPE ad_smtpadr,
        created_by   TYPE uname,
      END OF ty_customer,
      ty_customers TYPE STANDARD TABLE OF ty_customer WITH KEY kunnr,

      " 매출전표 아이템
      BEGIN OF ty_ar_item,
        ar_itemno    TYPE n LENGTH 3,
        saknr        TYPE saknr,
        item_text    TYPE c LENGTH 50,
        net_amount   TYPE p LENGTH 15 DECIMALS 2,
        tax_code     TYPE mwskz,
        tax_amount   TYPE p LENGTH 15 DECIMALS 2,
        gross_amount TYPE p LENGTH 15 DECIMALS 2,
        prctr        TYPE prctr,
        work_desc    TYPE c LENGTH 100,
      END OF ty_ar_item,
      ty_ar_items TYPE STANDARD TABLE OF ty_ar_item WITH KEY ar_itemno,

      " 매출전표 헤더
      BEGIN OF ty_ar_invoice,
        bukrs         TYPE bukrs,
        ar_invno      TYPE c LENGTH 10,
        gjahr         TYPE gjahr,
        kunnr         TYPE kunnr,
        cust_name     TYPE name1,
        belnr         TYPE belnr_d,
        bldat         TYPE bldat,
        budat         TYPE budat,
        xblnr         TYPE xblnr,
        bktxt         TYPE bktxt,
        waers         TYPE waers,
        gross_amount  TYPE p LENGTH 15 DECIMALS 2,
        net_amount    TYPE p LENGTH 15 DECIMALS 2,
        tax_amount    TYPE p LENGTH 15 DECIMALS 2,
        zterm         TYPE dzterm,
        due_date      TYPE datum,
        rcv_status    TYPE c LENGTH 1,
        rcvd_amount   TYPE p LENGTH 15 DECIMALS 2,
        rcvd_date     TYPE datum,
        proj_id       TYPE n LENGTH 10,
        contract_no   TYPE c LENGTH 20,
        bill_type     TYPE c LENGTH 4,
        progress_rate TYPE p LENGTH 5 DECIMALS 2,
        items         TYPE ty_ar_items,
        created_by    TYPE uname,
      END OF ty_ar_invoice,
      ty_ar_invoices TYPE STANDARD TABLE OF ty_ar_invoice WITH KEY ar_invno,

      " AR 연령분석
      BEGIN OF ty_ar_aging,
        kunnr        TYPE kunnr,
        cust_name    TYPE name1,
        total_open   TYPE p LENGTH 15 DECIMALS 2,
        not_due      TYPE p LENGTH 15 DECIMALS 2,
        overdue_30   TYPE p LENGTH 15 DECIMALS 2,
        overdue_60   TYPE p LENGTH 15 DECIMALS 2,
        overdue_90   TYPE p LENGTH 15 DECIMALS 2,
        overdue_90p  TYPE p LENGTH 15 DECIMALS 2,
      END OF ty_ar_aging,
      ty_ar_agings TYPE STANDARD TABLE OF ty_ar_aging WITH KEY kunnr,

      " 수금 처리
      BEGIN OF ty_receipt_request,
        bukrs        TYPE bukrs,
        ar_invno     TYPE c LENGTH 10,
        gjahr        TYPE gjahr,
        rcv_amount   TYPE p LENGTH 15 DECIMALS 2,
        rcv_date     TYPE datum,
        rcv_method   TYPE c LENGTH 1,
        bank_ref     TYPE c LENGTH 20,
        memo         TYPE c LENGTH 50,
      END OF ty_receipt_request,

      " 프로젝트별 수익 현황
      BEGIN OF ty_proj_revenue,
        proj_id       TYPE n LENGTH 10,
        contract_no   TYPE c LENGTH 20,
        total_billed  TYPE p LENGTH 15 DECIMALS 2,
        total_rcvd    TYPE p LENGTH 15 DECIMALS 2,
        outstanding   TYPE p LENGTH 15 DECIMALS 2,
        invoice_cnt   TYPE i,
      END OF ty_proj_revenue,
      ty_proj_revenues TYPE STANDARD TABLE OF ty_proj_revenue WITH KEY proj_id.

    METHODS:
      " ================================================================
      " 고객 마스터 CRUD
      " ================================================================
      find_all_customers
        IMPORTING iv_bukrs            TYPE bukrs
        RETURNING VALUE(rt_customers) TYPE ty_customers,

      find_customer_by_id
        IMPORTING iv_kunnr            TYPE kunnr
                  iv_bukrs            TYPE bukrs
        RETURNING VALUE(rs_customer)  TYPE ty_customer
        RAISING   cx_abap_not_found,

      find_customers_by_type
        IMPORTING iv_bukrs            TYPE bukrs
                  iv_cust_type        TYPE c
        RETURNING VALUE(rt_customers) TYPE ty_customers,

      create_customer
        IMPORTING is_customer         TYPE ty_customer
        RETURNING VALUE(rs_customer)  TYPE ty_customer
        RAISING   cx_sy_dyn_call_error,

      update_customer
        IMPORTING iv_kunnr            TYPE kunnr
                  iv_bukrs            TYPE bukrs
                  is_customer         TYPE ty_customer
        RETURNING VALUE(rs_customer)  TYPE ty_customer
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      update_credit_used
        IMPORTING iv_kunnr TYPE kunnr
                  iv_bukrs TYPE bukrs,

      " ================================================================
      " 매출전표 (기성청구) CRUD
      " ================================================================
      find_ar_invoices
        IMPORTING iv_bukrs             TYPE bukrs
                  iv_gjahr             TYPE gjahr
                  iv_kunnr             TYPE kunnr OPTIONAL
                  iv_rcv_status        TYPE c OPTIONAL
        RETURNING VALUE(rt_invoices)   TYPE ty_ar_invoices,

      find_ar_invoice_by_id
        IMPORTING iv_bukrs             TYPE bukrs
                  iv_ar_invno          TYPE c
                  iv_gjahr             TYPE gjahr
        RETURNING VALUE(rs_invoice)    TYPE ty_ar_invoice
        RAISING   cx_abap_not_found,

      find_by_project
        IMPORTING iv_bukrs             TYPE bukrs
                  iv_proj_id           TYPE n
        RETURNING VALUE(rt_invoices)   TYPE ty_ar_invoices,

      "! 기성청구서 생성 + FI 전표 자동 전기
      create_ar_invoice
        IMPORTING is_invoice           TYPE ty_ar_invoice
        RETURNING VALUE(rs_invoice)    TYPE ty_ar_invoice
        RAISING   cx_sy_dyn_call_error,

      update_ar_invoice
        IMPORTING iv_ar_invno          TYPE c
                  iv_gjahr             TYPE gjahr
                  is_invoice           TYPE ty_ar_invoice
        RETURNING VALUE(rs_invoice)    TYPE ty_ar_invoice
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      delete_ar_invoice
        IMPORTING iv_bukrs   TYPE bukrs
                  iv_ar_invno TYPE c
                  iv_gjahr   TYPE gjahr
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      "! 수금 처리 (FI 수금전표 생성)
      process_receipt
        IMPORTING is_rcv_req            TYPE ty_receipt_request
        RETURNING VALUE(rv_rcv_belnr)   TYPE belnr_d
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      "! 대손 처리 (Bad Debt Write-off)
      write_off_bad_debt
        IMPORTING iv_bukrs    TYPE bukrs
                  iv_ar_invno TYPE c
                  iv_gjahr    TYPE gjahr
                  iv_amount   TYPE p
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      " ================================================================
      " 분석/보고서
      " ================================================================
      get_ar_aging
        IMPORTING iv_bukrs           TYPE bukrs
                  iv_key_date        TYPE datum
        RETURNING VALUE(rt_aging)    TYPE ty_ar_agings,

      get_project_revenue
        IMPORTING iv_bukrs              TYPE bukrs
                  iv_gjahr              TYPE gjahr
        RETURNING VALUE(rt_revenues)    TYPE ty_proj_revenues,

      get_customer_balance
        IMPORTING iv_bukrs          TYPE bukrs
                  iv_kunnr          TYPE kunnr
        RETURNING VALUE(rv_balance) TYPE p.

  PRIVATE SECTION.
    METHODS:
      get_next_ar_invno
        IMPORTING iv_bukrs         TYPE bukrs
                  iv_gjahr         TYPE gjahr
        RETURNING VALUE(rv_invno)  TYPE c LENGTH 10,

      post_fi_ar_document
        IMPORTING is_invoice TYPE ty_ar_invoice
        RETURNING VALUE(rv_belnr) TYPE belnr_d
        RAISING   cx_sy_dyn_call_error,

      calc_due_date
        IMPORTING iv_zfbdt       TYPE datum
                  iv_zterm       TYPE dzterm
        RETURNING VALUE(rv_date) TYPE datum.

ENDCLASS.


CLASS zcl_fi_ar_service IMPLEMENTATION.

  METHOD find_all_customers.
    SELECT kunnr bukrs name1 stcd1 akont zterm cust_type credit_limit credit_used sperr telf1 smtp_addr created_by
      FROM zfi_customer
      WHERE bukrs = @iv_bukrs AND loevm <> 'X'
      INTO CORRESPONDING FIELDS OF TABLE @rt_customers
      ORDER BY kunnr.
  ENDMETHOD.

  METHOD find_customer_by_id.
    SELECT SINGLE kunnr bukrs name1 stcd1 akont zterm cust_type credit_limit credit_used sperr telf1 smtp_addr created_by
      FROM zfi_customer
      WHERE kunnr = @iv_kunnr AND bukrs = @iv_bukrs
      INTO CORRESPONDING FIELDS OF @rs_customer.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.
  ENDMETHOD.

  METHOD find_customers_by_type.
    SELECT kunnr bukrs name1 stcd1 akont zterm cust_type credit_limit credit_used sperr telf1 smtp_addr created_by
      FROM zfi_customer
      WHERE bukrs = @iv_bukrs AND cust_type = @iv_cust_type AND loevm <> 'X'
      INTO CORRESPONDING FIELDS OF TABLE @rt_customers
      ORDER BY name1.
  ENDMETHOD.

  METHOD create_customer.
    DATA ls_db TYPE zfi_customer.
    SELECT COUNT(*) FROM zfi_customer
      WHERE kunnr = @is_customer-kunnr AND bukrs = @is_customer-bukrs
      INTO @DATA(lv_cnt).
    IF lv_cnt > 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    rs_customer = is_customer.
    MOVE-CORRESPONDING rs_customer TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-created_by = sy-uname.
    GET TIME STAMP FIELD ls_db-created_at.
    INSERT zfi_customer FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD update_customer.
    find_customer_by_id( iv_kunnr = iv_kunnr iv_bukrs = iv_bukrs ).
    rs_customer = is_customer.
    UPDATE zfi_customer
      SET name1        = @rs_customer-name1,
          telf1        = @rs_customer-telf1,
          smtp_addr    = @rs_customer-smtp_addr,
          zterm        = @rs_customer-zterm,
          cust_type    = @rs_customer-cust_type,
          credit_limit = @rs_customer-credit_limit,
          changed_by   = @sy-uname
      WHERE kunnr = @iv_kunnr AND bukrs = @iv_bukrs AND mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD update_credit_used.
    DATA lv_used TYPE p LENGTH 15 DECIMALS 2.
    SELECT SUM( gross_amount - rcvd_amount ) FROM zfi_ar_invoice
      WHERE bukrs = @iv_bukrs AND kunnr = @iv_kunnr AND rcv_status IN (' ', 'P')
      INTO @lv_used.
    UPDATE zfi_customer SET credit_used = @lv_used
      WHERE kunnr = @iv_kunnr AND bukrs = @iv_bukrs AND mandt = @sy-mandt.
  ENDMETHOD.

  METHOD find_ar_invoices.
    IF iv_kunnr IS NOT INITIAL AND iv_rcv_status IS NOT INITIAL.
      SELECT ar~bukrs ar~ar_invno ar~gjahr ar~kunnr c~name1 ar~belnr ar~bldat ar~budat
             ar~xblnr ar~bktxt ar~waers ar~gross_amount ar~net_amount ar~tax_amount
             ar~zterm ar~due_date ar~rcv_status ar~rcvd_amount ar~rcvd_date
             ar~proj_id ar~contract_no ar~bill_type ar~progress_rate ar~created_by
        FROM zfi_ar_invoice AS ar
        LEFT JOIN zfi_customer AS c ON c~kunnr = ar~kunnr AND c~bukrs = ar~bukrs
        WHERE ar~bukrs = @iv_bukrs AND ar~gjahr = @iv_gjahr
          AND ar~kunnr = @iv_kunnr AND ar~rcv_status = @iv_rcv_status
        INTO CORRESPONDING FIELDS OF TABLE @rt_invoices
        ORDER BY ar~budat DESCENDING.
    ELSE.
      SELECT ar~bukrs ar~ar_invno ar~gjahr ar~kunnr c~name1 ar~belnr ar~bldat ar~budat
             ar~xblnr ar~bktxt ar~waers ar~gross_amount ar~net_amount ar~tax_amount
             ar~zterm ar~due_date ar~rcv_status ar~rcvd_amount ar~rcvd_date
             ar~proj_id ar~contract_no ar~bill_type ar~progress_rate ar~created_by
        FROM zfi_ar_invoice AS ar
        LEFT JOIN zfi_customer AS c ON c~kunnr = ar~kunnr AND c~bukrs = ar~bukrs
        WHERE ar~bukrs = @iv_bukrs AND ar~gjahr = @iv_gjahr
        INTO CORRESPONDING FIELDS OF TABLE @rt_invoices
        ORDER BY ar~budat DESCENDING.
    ENDIF.
  ENDMETHOD.

  METHOD find_ar_invoice_by_id.
    SELECT SINGLE ar~bukrs ar~ar_invno ar~gjahr ar~kunnr c~name1 ar~belnr ar~bldat ar~budat
                  ar~xblnr ar~bktxt ar~waers ar~gross_amount ar~net_amount ar~tax_amount
                  ar~zterm ar~due_date ar~rcv_status ar~rcvd_amount ar~rcvd_date
                  ar~proj_id ar~contract_no ar~bill_type ar~progress_rate ar~created_by
      FROM zfi_ar_invoice AS ar
      LEFT JOIN zfi_customer AS c ON c~kunnr = ar~kunnr AND c~bukrs = ar~bukrs
      WHERE ar~bukrs = @iv_bukrs AND ar~ar_invno = @iv_ar_invno AND ar~gjahr = @iv_gjahr
      INTO CORRESPONDING FIELDS OF @rs_invoice.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.
    SELECT ar_itemno saknr item_text net_amount tax_code tax_amount gross_amount prctr work_desc
      FROM zfi_ar_item
      WHERE bukrs = @iv_bukrs AND ar_invno = @iv_ar_invno AND gjahr = @iv_gjahr
      INTO CORRESPONDING FIELDS OF TABLE @rs_invoice-items
      ORDER BY ar_itemno.
  ENDMETHOD.

  METHOD find_by_project.
    SELECT ar~bukrs ar~ar_invno ar~gjahr ar~kunnr c~name1 ar~belnr ar~bldat ar~budat
           ar~xblnr ar~bktxt ar~waers ar~gross_amount ar~net_amount ar~tax_amount
           ar~zterm ar~due_date ar~rcv_status ar~rcvd_amount ar~rcvd_date
           ar~proj_id ar~contract_no ar~bill_type ar~progress_rate ar~created_by
      FROM zfi_ar_invoice AS ar
      LEFT JOIN zfi_customer AS c ON c~kunnr = ar~kunnr AND c~bukrs = ar~bukrs
      WHERE ar~bukrs = @iv_bukrs AND ar~proj_id = @iv_proj_id
      INTO CORRESPONDING FIELDS OF TABLE @rt_invoices
      ORDER BY ar~budat DESCENDING.
  ENDMETHOD.

  METHOD create_ar_invoice.
    DATA ls_db TYPE zfi_ar_invoice.
    rs_invoice = is_invoice.
    rs_invoice-ar_invno = get_next_ar_invno(
      iv_bukrs = is_invoice-bukrs iv_gjahr = is_invoice-gjahr ).
    rs_invoice-rcv_status = ' '.
    rs_invoice-due_date = calc_due_date(
      iv_zfbdt = is_invoice-budat iv_zterm = is_invoice-zterm ).
    " FI 전표 전기
    rs_invoice-belnr = post_fi_ar_document( rs_invoice ).
    MOVE-CORRESPONDING rs_invoice TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-created_by = sy-uname.
    GET TIME STAMP FIELD ls_db-created_at.
    INSERT zfi_ar_invoice FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    " 아이템 INSERT
    LOOP AT rs_invoice-items INTO DATA(ls_item).
      DATA ls_db_item TYPE zfi_ar_item.
      MOVE-CORRESPONDING ls_item TO ls_db_item.
      ls_db_item-mandt    = sy-mandt.
      ls_db_item-bukrs    = rs_invoice-bukrs.
      ls_db_item-ar_invno = rs_invoice-ar_invno.
      ls_db_item-gjahr    = rs_invoice-gjahr.
      INSERT zfi_ar_item FROM ls_db_item.
    ENDLOOP.
    " 신용한도 사용액 갱신
    update_credit_used( iv_kunnr = rs_invoice-kunnr iv_bukrs = rs_invoice-bukrs ).
  ENDMETHOD.

  METHOD update_ar_invoice.
    DATA(ls_old) = find_ar_invoice_by_id(
      iv_bukrs = is_invoice-bukrs iv_ar_invno = iv_ar_invno iv_gjahr = iv_gjahr ).
    IF ls_old-rcv_status = 'F'.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    rs_invoice = is_invoice.
    rs_invoice-ar_invno = iv_ar_invno.
    UPDATE zfi_ar_invoice
      SET gross_amount  = @rs_invoice-gross_amount,
          net_amount    = @rs_invoice-net_amount,
          tax_amount    = @rs_invoice-tax_amount,
          progress_rate = @rs_invoice-progress_rate,
          bktxt         = @rs_invoice-bktxt
      WHERE bukrs = @rs_invoice-bukrs AND ar_invno = @iv_ar_invno
        AND gjahr = @iv_gjahr AND mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD delete_ar_invoice.
    DATA(ls_inv) = find_ar_invoice_by_id(
      iv_bukrs = iv_bukrs iv_ar_invno = iv_ar_invno iv_gjahr = iv_gjahr ).
    IF ls_inv-rcv_status <> ' '.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    DELETE FROM zfi_ar_item
      WHERE bukrs = @iv_bukrs AND ar_invno = @iv_ar_invno AND gjahr = @iv_gjahr
        AND mandt = @sy-mandt.
    DELETE FROM zfi_ar_invoice
      WHERE bukrs = @iv_bukrs AND ar_invno = @iv_ar_invno AND gjahr = @iv_gjahr
        AND mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD process_receipt.
    DATA(ls_inv) = find_ar_invoice_by_id(
      iv_bukrs    = is_rcv_req-bukrs
      iv_ar_invno = is_rcv_req-ar_invno
      iv_gjahr    = is_rcv_req-gjahr ).

    IF ls_inv-rcv_status = 'F'.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.

    " 수금전표 생성: 차) 보통예금 / 대) 매출채권
    DATA ls_gl_svc TYPE REF TO zcl_fi_gl_service.
    CREATE OBJECT ls_gl_svc.

    DATA ls_header TYPE zcl_fi_gl_service=>ty_journal_header.
    ls_header-bukrs = is_rcv_req-bukrs.
    ls_header-blart = 'ZE'.
    ls_header-bldat = is_rcv_req-rcv_date.
    ls_header-budat = is_rcv_req-rcv_date.
    ls_header-waers = 'KRW'.
    ls_header-bktxt = |수금:{ is_rcv_req-ar_invno }|.

    " 차변: 보통예금(101100)
    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '001' saknr = '101100' shkzg = 'S'
      dmbtr = is_rcv_req-rcv_amount wrbtr = is_rcv_req-rcv_amount
      sgtxt = ls_header-bktxt ) TO ls_header-items.

    " 대변: 매출채권(102000)
    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '002' saknr = '102000' shkzg = 'H'
      dmbtr = is_rcv_req-rcv_amount wrbtr = is_rcv_req-rcv_amount
      kunnr = ls_inv-kunnr sgtxt = ls_header-bktxt ) TO ls_header-items.

    DATA(ls_posted) = ls_gl_svc->post_journal( ls_header ).
    rv_rcv_belnr = ls_posted-belnr.

    " 수금 상태 갱신
    DATA lv_new_rcvd TYPE p LENGTH 15 DECIMALS 2.
    lv_new_rcvd = ls_inv-rcvd_amount + is_rcv_req-rcv_amount.
    DATA lv_new_status TYPE c LENGTH 1.
    lv_new_status = COND #(
      WHEN lv_new_rcvd >= ls_inv-gross_amount THEN 'F' ELSE 'P' ).

    UPDATE zfi_ar_invoice
      SET rcv_status  = @lv_new_status,
          rcvd_amount = @lv_new_rcvd,
          rcvd_date   = @is_rcv_req-rcv_date,
          rcv_belnr   = @rv_rcv_belnr
      WHERE bukrs = @is_rcv_req-bukrs AND ar_invno = @is_rcv_req-ar_invno
        AND gjahr = @is_rcv_req-gjahr AND mandt = @sy-mandt.

    " 신용한도 사용액 갱신
    update_credit_used( iv_kunnr = ls_inv-kunnr iv_bukrs = is_rcv_req-bukrs ).
  ENDMETHOD.

  METHOD write_off_bad_debt.
    DATA(ls_inv) = find_ar_invoice_by_id(
      iv_bukrs = iv_bukrs iv_ar_invno = iv_ar_invno iv_gjahr = iv_gjahr ).

    " 대손처리: 차) 대손상각비(505900) / 대) 매출채권(102000)
    DATA ls_gl_svc TYPE REF TO zcl_fi_gl_service.
    CREATE OBJECT ls_gl_svc.

    DATA ls_header TYPE zcl_fi_gl_service=>ty_journal_header.
    ls_header-bukrs = iv_bukrs.
    ls_header-blart = 'SA'.
    ls_header-bldat = sy-datum.
    ls_header-budat = sy-datum.
    ls_header-waers = 'KRW'.
    ls_header-bktxt = |대손:{ iv_ar_invno }|.

    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '001' saknr = '505900' shkzg = 'S'
      dmbtr = iv_amount wrbtr = iv_amount sgtxt = ls_header-bktxt ) TO ls_header-items.
    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '002' saknr = '102000' shkzg = 'H'
      dmbtr = iv_amount wrbtr = iv_amount
      kunnr = ls_inv-kunnr sgtxt = ls_header-bktxt ) TO ls_header-items.

    ls_gl_svc->post_journal( ls_header ).

    UPDATE zfi_ar_invoice
      SET rcv_status = 'D'
      WHERE bukrs = @iv_bukrs AND ar_invno = @iv_ar_invno
        AND gjahr = @iv_gjahr AND mandt = @sy-mandt.
  ENDMETHOD.

  METHOD get_ar_aging.
    SELECT ar~kunnr c~name1
           SUM( ar~gross_amount - ar~rcvd_amount ) AS total_open
      FROM zfi_ar_invoice AS ar
      LEFT JOIN zfi_customer AS c ON c~kunnr = ar~kunnr AND c~bukrs = ar~bukrs
      WHERE ar~bukrs = @iv_bukrs AND ar~rcv_status IN (' ', 'P')
      GROUP BY ar~kunnr c~name1
      INTO CORRESPONDING FIELDS OF TABLE @rt_aging.

    LOOP AT rt_aging ASSIGNING FIELD-SYMBOL(<aging>).
      SELECT SUM( gross_amount - rcvd_amount ) FROM zfi_ar_invoice
        WHERE bukrs = @iv_bukrs AND kunnr = @<aging>-kunnr
          AND rcv_status IN (' ', 'P') AND due_date >= @iv_key_date
        INTO @<aging>-not_due.
      SELECT SUM( gross_amount - rcvd_amount ) FROM zfi_ar_invoice
        WHERE bukrs = @iv_bukrs AND kunnr = @<aging>-kunnr
          AND rcv_status IN (' ', 'P')
          AND due_date >= @iv_key_date - 30 AND due_date < @iv_key_date
        INTO @<aging>-overdue_30.
      SELECT SUM( gross_amount - rcvd_amount ) FROM zfi_ar_invoice
        WHERE bukrs = @iv_bukrs AND kunnr = @<aging>-kunnr
          AND rcv_status IN (' ', 'P')
          AND due_date >= @iv_key_date - 60 AND due_date < @iv_key_date - 30
        INTO @<aging>-overdue_60.
      SELECT SUM( gross_amount - rcvd_amount ) FROM zfi_ar_invoice
        WHERE bukrs = @iv_bukrs AND kunnr = @<aging>-kunnr
          AND rcv_status IN (' ', 'P')
          AND due_date >= @iv_key_date - 90 AND due_date < @iv_key_date - 60
        INTO @<aging>-overdue_90.
      SELECT SUM( gross_amount - rcvd_amount ) FROM zfi_ar_invoice
        WHERE bukrs = @iv_bukrs AND kunnr = @<aging>-kunnr
          AND rcv_status IN (' ', 'P') AND due_date < @iv_key_date - 90
        INTO @<aging>-overdue_90p.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_project_revenue.
    SELECT proj_id contract_no
           SUM( gross_amount ) AS total_billed
           SUM( rcvd_amount )  AS total_rcvd
           COUNT(*) AS invoice_cnt
      FROM zfi_ar_invoice
      WHERE bukrs = @iv_bukrs AND gjahr = @iv_gjahr
      GROUP BY proj_id contract_no
      INTO CORRESPONDING FIELDS OF TABLE @rt_revenues.
    LOOP AT rt_revenues ASSIGNING FIELD-SYMBOL(<rev>).
      <rev>-outstanding = <rev>-total_billed - <rev>-total_rcvd.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_customer_balance.
    SELECT SUM( gross_amount - rcvd_amount ) FROM zfi_ar_invoice
      WHERE bukrs = @iv_bukrs AND kunnr = @iv_kunnr AND rcv_status IN (' ', 'P')
      INTO @rv_balance.
  ENDMETHOD.

  METHOD get_next_ar_invno.
    DATA lv_max TYPE c LENGTH 10.
    SELECT MAX( ar_invno ) FROM zfi_ar_invoice
      WHERE bukrs = @iv_bukrs AND gjahr = @iv_gjahr
      INTO @lv_max.
    rv_invno = COND #(
      WHEN lv_max IS NOT INITIAL THEN lv_max + 1
      ELSE |AR{ iv_gjahr }0001| ).
  ENDMETHOD.

  METHOD post_fi_ar_document.
    " 매출전표 전기: 차) 매출채권(102000) / 대) 건설공사수익(401000) + 부가세예수금(202500)
    DATA ls_gl_svc TYPE REF TO zcl_fi_gl_service.
    CREATE OBJECT ls_gl_svc.

    DATA ls_header TYPE zcl_fi_gl_service=>ty_journal_header.
    ls_header-bukrs = is_invoice-bukrs.
    ls_header-blart = 'DR'.
    ls_header-bldat = is_invoice-bldat.
    ls_header-budat = is_invoice-budat.
    ls_header-waers = is_invoice-waers.
    ls_header-xblnr = is_invoice-contract_no.
    ls_header-bktxt = is_invoice-bktxt.

    " 차변: 매출채권
    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '001' saknr = '102000' shkzg = 'S'
      dmbtr = is_invoice-gross_amount wrbtr = is_invoice-gross_amount
      kunnr = is_invoice-kunnr sgtxt = |기성청구:{ is_invoice-contract_no }| ) TO ls_header-items.

    " 대변: 건설공사수익
    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '002' saknr = '401000' shkzg = 'H'
      dmbtr = is_invoice-net_amount wrbtr = is_invoice-net_amount
      kunnr = is_invoice-kunnr sgtxt = ls_header-bktxt ) TO ls_header-items.

    " 대변: 부가세예수금 (세액이 있는 경우)
    IF is_invoice-tax_amount > 0.
      APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
        buzei = '003' saknr = '202500' shkzg = 'H'
        dmbtr = is_invoice-tax_amount wrbtr = is_invoice-tax_amount
        sgtxt = |부가세:{ is_invoice-ar_invno }| ) TO ls_header-items.
    ENDIF.

    DATA(ls_posted) = ls_gl_svc->post_journal( ls_header ).
    rv_belnr = ls_posted-belnr.
  ENDMETHOD.

  METHOD calc_due_date.
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
