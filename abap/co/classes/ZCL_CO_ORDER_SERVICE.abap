*&---------------------------------------------------------------------*
*& Class: ZCL_CO_ORDER_SERVICE
*& Description: 내부오더 서비스 (Internal Order - CO-OPA)
*& 담당업무: 오더 마스터 CRUD, 예산관리, 실적조회, 오더 정산
*& Transaction: SE24
*&---------------------------------------------------------------------*

CLASS zcl_co_order_service DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_order,
        kokrs         TYPE kokrs,
        aufnr         TYPE aufnr,
        auart         TYPE auart,
        ktext         TYPE c LENGTH 20,
        ltext         TYPE c LENGTH 40,
        bukrs         TYPE bukrs,
        kostl         TYPE kostl,
        prctr         TYPE prctr,
        proj_id       TYPE n LENGTH 10,
        idat1         TYPE datum,
        idat2         TYPE datum,
        order_status  TYPE c LENGTH 2,
        budget_amount TYPE p LENGTH 15 DECIMALS 2,
        actual_cost   TYPE p LENGTH 15 DECIMALS 2,
        commit_cost   TYPE p LENGTH 15 DECIMALS 2,
        plan_cost     TYPE p LENGTH 15 DECIMALS 2,
        variance      TYPE p LENGTH 15 DECIMALS 2,
        settle_rule   TYPE c LENGTH 1,
        settle_rcvr   TYPE c LENGTH 10,
        rcvr_type     TYPE c LENGTH 3,
        created_by    TYPE uname,
      END OF ty_order,
      ty_orders TYPE STANDARD TABLE OF ty_order WITH KEY aufnr,

      " 예산 조회 결과
      BEGIN OF ty_budget_status,
        aufnr         TYPE aufnr,
        ktext         TYPE c LENGTH 20,
        total_budget  TYPE p LENGTH 15 DECIMALS 2,
        actual_cost   TYPE p LENGTH 15 DECIMALS 2,
        commit_cost   TYPE p LENGTH 15 DECIMALS 2,
        avail_budget  TYPE p LENGTH 15 DECIMALS 2,
        used_pct      TYPE p LENGTH 5 DECIMALS 2,
        overrun       TYPE abap_bool,
      END OF ty_budget_status,
      ty_budget_statuses TYPE STANDARD TABLE OF ty_budget_status WITH KEY aufnr,

      " 오더별 원가요소 집계
      BEGIN OF ty_order_cost,
        aufnr        TYPE aufnr,
        ktext        TYPE c LENGTH 20,
        kstar        TYPE kstar,
        cel_name     TYPE c LENGTH 20,
        cel_group    TYPE c LENGTH 4,
        plan_cost    TYPE p LENGTH 15 DECIMALS 2,
        actual_cost  TYPE p LENGTH 15 DECIMALS 2,
        variance     TYPE p LENGTH 15 DECIMALS 2,
      END OF ty_order_cost,
      ty_order_costs TYPE STANDARD TABLE OF ty_order_cost WITH KEY aufnr kstar,

      " 정산 결과
      BEGIN OF ty_settlement_result,
        aufnr         TYPE aufnr,
        settle_belnr  TYPE belnr_d,
        settled_amt   TYPE p LENGTH 15 DECIMALS 2,
        settle_date   TYPE datum,
        rcvr_type     TYPE c LENGTH 3,
        settle_rcvr   TYPE c LENGTH 10,
      END OF ty_settlement_result.

    METHODS:
      " ================================================================
      " 내부오더 마스터 CRUD
      " ================================================================
      find_all
        IMPORTING iv_kokrs          TYPE kokrs
                  iv_auart          TYPE auart OPTIONAL
                  iv_proj_id        TYPE n OPTIONAL
        RETURNING VALUE(rt_orders)  TYPE ty_orders,

      find_by_id
        IMPORTING iv_kokrs          TYPE kokrs
                  iv_aufnr          TYPE aufnr
        RETURNING VALUE(rs_order)   TYPE ty_order
        RAISING   cx_abap_not_found,

      find_by_project
        IMPORTING iv_kokrs          TYPE kokrs
                  iv_proj_id        TYPE n
        RETURNING VALUE(rt_orders)  TYPE ty_orders,

      find_overbudget
        IMPORTING iv_kokrs          TYPE kokrs
        RETURNING VALUE(rt_orders)  TYPE ty_orders,

      create_order
        IMPORTING is_order          TYPE ty_order
        RETURNING VALUE(rs_order)   TYPE ty_order
        RAISING   cx_sy_dyn_call_error,

      update_order
        IMPORTING iv_kokrs          TYPE kokrs
                  iv_aufnr          TYPE aufnr
                  is_order          TYPE ty_order
        RETURNING VALUE(rs_order)   TYPE ty_order
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      "! 오더 릴리즈 (CR → RE)
      release_order
        IMPORTING iv_kokrs TYPE kokrs
                  iv_aufnr TYPE aufnr
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      "! 오더 잠금 (RE → LK)
      lock_order
        IMPORTING iv_kokrs TYPE kokrs
                  iv_aufnr TYPE aufnr
        RAISING   cx_abap_not_found,

      " ================================================================
      " 예산 관리 (KO22)
      " ================================================================
      "! 예산 등록/변경
      save_budget
        IMPORTING iv_kokrs        TYPE kokrs
                  iv_aufnr        TYPE aufnr
                  iv_gjahr        TYPE gjahr
                  iv_budget_type  TYPE c
                  iv_amount       TYPE p
        RAISING   cx_sy_dyn_call_error,

      "! 예산 조회 (가용예산, 초과 여부)
      get_budget_status
        IMPORTING iv_kokrs             TYPE kokrs
                  iv_aufnr             TYPE aufnr
                  iv_gjahr             TYPE gjahr
        RETURNING VALUE(rs_budget)     TYPE ty_budget_status
        RAISING   cx_abap_not_found,

      "! 전체 오더 예산 현황
      get_all_budget_status
        IMPORTING iv_kokrs             TYPE kokrs
                  iv_gjahr             TYPE gjahr
        RETURNING VALUE(rt_budgets)    TYPE ty_budget_statuses,

      " ================================================================
      " 원가 분석
      " ================================================================
      "! 오더별 원가요소 집계
      get_order_cost_detail
        IMPORTING iv_kokrs             TYPE kokrs
                  iv_aufnr             TYPE aufnr
                  iv_gjahr             TYPE gjahr
        RETURNING VALUE(rt_costs)      TYPE ty_order_costs,

      "! 실적 라인아이템 조회
      get_actual_line_items
        IMPORTING iv_kokrs             TYPE kokrs
                  iv_aufnr             TYPE aufnr
                  iv_gjahr             TYPE gjahr
        RETURNING VALUE(rt_items)      TYPE STANDARD TABLE,

      " ================================================================
      " 오더 정산 (KO88)
      " ================================================================
      "! 오더 정산 실행 (코스트센터 또는 GL계정으로)
      settle_order
        IMPORTING iv_kokrs             TYPE kokrs
                  iv_aufnr             TYPE aufnr
                  iv_settle_date       TYPE datum
        RETURNING VALUE(rs_result)     TYPE ty_settlement_result
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      "! 오더 결산 완료 (RE → CL)
      close_order
        IMPORTING iv_kokrs TYPE kokrs
                  iv_aufnr TYPE aufnr
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error.

  PRIVATE SECTION.
    METHODS:
      get_next_aufnr
        IMPORTING iv_kokrs         TYPE kokrs
                  iv_auart         TYPE auart
        RETURNING VALUE(rv_aufnr)  TYPE aufnr,

      update_order_actual
        IMPORTING iv_kokrs  TYPE kokrs
                  iv_aufnr  TYPE aufnr.

ENDCLASS.


CLASS zcl_co_order_service IMPLEMENTATION.

  METHOD find_all.
    IF iv_auart IS NOT INITIAL AND iv_proj_id IS NOT INITIAL.
      SELECT kokrs aufnr auart ktext ltext bukrs kostl prctr proj_id idat1 idat2
             order_status budget_amount actual_cost commit_cost plan_cost variance
             settle_rule settle_rcvr rcvr_type created_by
        FROM zco_internal_order
        WHERE kokrs = @iv_kokrs AND auart = @iv_auart AND proj_id = @iv_proj_id
        INTO CORRESPONDING FIELDS OF TABLE @rt_orders
        ORDER BY aufnr.
    ELSEIF iv_auart IS NOT INITIAL.
      SELECT kokrs aufnr auart ktext ltext bukrs kostl prctr proj_id idat1 idat2
             order_status budget_amount actual_cost commit_cost plan_cost variance
             settle_rule settle_rcvr rcvr_type created_by
        FROM zco_internal_order
        WHERE kokrs = @iv_kokrs AND auart = @iv_auart
        INTO CORRESPONDING FIELDS OF TABLE @rt_orders
        ORDER BY aufnr.
    ELSE.
      SELECT kokrs aufnr auart ktext ltext bukrs kostl prctr proj_id idat1 idat2
             order_status budget_amount actual_cost commit_cost plan_cost variance
             settle_rule settle_rcvr rcvr_type created_by
        FROM zco_internal_order
        WHERE kokrs = @iv_kokrs
        INTO CORRESPONDING FIELDS OF TABLE @rt_orders
        ORDER BY aufnr.
    ENDIF.
  ENDMETHOD.

  METHOD find_by_id.
    SELECT SINGLE kokrs aufnr auart ktext ltext bukrs kostl prctr proj_id idat1 idat2
                  order_status budget_amount actual_cost commit_cost plan_cost variance
                  settle_rule settle_rcvr rcvr_type created_by
      FROM zco_internal_order
      WHERE kokrs = @iv_kokrs AND aufnr = @iv_aufnr
      INTO CORRESPONDING FIELDS OF @rs_order.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.
  ENDMETHOD.

  METHOD find_by_project.
    SELECT kokrs aufnr auart ktext ltext bukrs kostl prctr proj_id idat1 idat2
           order_status budget_amount actual_cost commit_cost plan_cost variance
           settle_rule settle_rcvr rcvr_type created_by
      FROM zco_internal_order
      WHERE kokrs = @iv_kokrs AND proj_id = @iv_proj_id
      INTO CORRESPONDING FIELDS OF TABLE @rt_orders
      ORDER BY aufnr.
  ENDMETHOD.

  METHOD find_overbudget.
    SELECT kokrs aufnr auart ktext ltext bukrs kostl prctr proj_id idat1 idat2
           order_status budget_amount actual_cost commit_cost plan_cost variance
           settle_rule settle_rcvr rcvr_type created_by
      FROM zco_internal_order
      WHERE kokrs = @iv_kokrs AND order_status = 'RE'
        AND actual_cost > budget_amount AND budget_amount > 0
      INTO CORRESPONDING FIELDS OF TABLE @rt_orders
      ORDER BY aufnr.
  ENDMETHOD.

  METHOD create_order.
    DATA ls_db TYPE zco_internal_order.
    rs_order = is_order.
    rs_order-aufnr       = get_next_aufnr( iv_kokrs = is_order-kokrs iv_auart = is_order-auart ).
    rs_order-order_status = 'CR'.
    rs_order-actual_cost  = 0.
    rs_order-commit_cost  = 0.
    MOVE-CORRESPONDING rs_order TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-erdat      = sy-datum.
    ls_db-created_by = sy-uname.
    GET TIME STAMP FIELD ls_db-created_at.
    INSERT zco_internal_order FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD update_order.
    find_by_id( iv_kokrs = iv_kokrs iv_aufnr = iv_aufnr ).
    rs_order = is_order.
    UPDATE zco_internal_order
      SET ktext     = @rs_order-ktext,
          ltext     = @rs_order-ltext,
          kostl     = @rs_order-kostl,
          prctr     = @rs_order-prctr,
          idat1     = @rs_order-idat1,
          idat2     = @rs_order-idat2,
          plan_cost = @rs_order-plan_cost,
          changed_by = @sy-uname,
          aedat      = @sy-datum
      WHERE kokrs = @iv_kokrs AND aufnr = @iv_aufnr AND mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD release_order.
    DATA(ls_order) = find_by_id( iv_kokrs = iv_kokrs iv_aufnr = iv_aufnr ).
    IF ls_order-order_status <> 'CR'.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    UPDATE zco_internal_order
      SET order_status = 'RE', changed_by = @sy-uname
      WHERE kokrs = @iv_kokrs AND aufnr = @iv_aufnr AND mandt = @sy-mandt.
  ENDMETHOD.

  METHOD lock_order.
    find_by_id( iv_kokrs = iv_kokrs iv_aufnr = iv_aufnr ).
    UPDATE zco_internal_order
      SET order_status = 'LK', changed_by = @sy-uname
      WHERE kokrs = @iv_kokrs AND aufnr = @iv_aufnr AND mandt = @sy-mandt.
  ENDMETHOD.

  METHOD save_budget.
    " 기존 예산 조회
    SELECT SINGLE * FROM zco_budget
      WHERE kokrs = @iv_kokrs AND aufnr = @iv_aufnr AND gjahr = @iv_gjahr
        AND budget_type = @iv_budget_type
      INTO @DATA(ls_exist).

    IF sy-subrc = 0.
      " 수정
      DATA lv_new_suppl TYPE p LENGTH 15 DECIMALS 2.
      DATA lv_new_orig  TYPE p LENGTH 15 DECIMALS 2.
      IF iv_budget_type = 'OR'.
        lv_new_orig = iv_amount.
        UPDATE zco_budget
          SET orig_budget   = @lv_new_orig,
              total_budget  = @lv_new_orig + @ls_exist-suppl_budget,
              avail_budget  = @lv_new_orig + @ls_exist-suppl_budget
                              - @ls_exist-actual_cost - @ls_exist-commit_cost
          WHERE kokrs = @iv_kokrs AND aufnr = @iv_aufnr AND gjahr = @iv_gjahr
            AND budget_type = @iv_budget_type AND mandt = @sy-mandt.
      ELSE.
        lv_new_suppl = iv_amount.
        UPDATE zco_budget
          SET suppl_budget  = @lv_new_suppl,
              total_budget  = @ls_exist-orig_budget + @lv_new_suppl,
              avail_budget  = @ls_exist-orig_budget + @lv_new_suppl
                              - @ls_exist-actual_cost - @ls_exist-commit_cost
          WHERE kokrs = @iv_kokrs AND aufnr = @iv_aufnr AND gjahr = @iv_gjahr
            AND budget_type = @iv_budget_type AND mandt = @sy-mandt.
      ENDIF.
    ELSE.
      " 신규
      DATA ls_db TYPE zco_budget.
      ls_db-mandt         = sy-mandt.
      ls_db-kokrs         = iv_kokrs.
      ls_db-gjahr         = iv_gjahr.
      ls_db-aufnr         = iv_aufnr.
      ls_db-budget_type   = iv_budget_type.
      ls_db-budget_status = 'AP'.
      ls_db-waers         = 'KRW'.
      ls_db-created_by    = sy-uname.
      GET TIME STAMP FIELD ls_db-created_at.
      IF iv_budget_type = 'OR'.
        ls_db-orig_budget  = iv_amount.
        ls_db-total_budget = iv_amount.
        ls_db-avail_budget = iv_amount.
      ELSE.
        ls_db-suppl_budget = iv_amount.
        ls_db-total_budget = iv_amount.
        ls_db-avail_budget = iv_amount.
      ENDIF.
      INSERT zco_budget FROM ls_db.
    ENDIF.

    " 오더 마스터 예산 갱신
    SELECT SUM( total_budget ) FROM zco_budget
      WHERE kokrs = @iv_kokrs AND aufnr = @iv_aufnr AND gjahr = @iv_gjahr
      INTO @DATA(lv_total_budget).
    UPDATE zco_internal_order
      SET budget_amount = @lv_total_budget
      WHERE kokrs = @iv_kokrs AND aufnr = @iv_aufnr AND mandt = @sy-mandt.
  ENDMETHOD.

  METHOD get_budget_status.
    DATA(ls_order) = find_by_id( iv_kokrs = iv_kokrs iv_aufnr = iv_aufnr ).

    SELECT SINGLE SUM( total_budget ) AS total_budget
                  SUM( actual_cost )  AS actual_cost
                  SUM( commit_cost )  AS commit_cost
                  SUM( avail_budget ) AS avail_budget
      FROM zco_budget
      WHERE kokrs = @iv_kokrs AND aufnr = @iv_aufnr AND gjahr = @iv_gjahr
      INTO @DATA(ls_bgt).

    rs_budget-aufnr        = iv_aufnr.
    rs_budget-ktext        = ls_order-ktext.
    rs_budget-total_budget = ls_bgt-total_budget.
    rs_budget-actual_cost  = ls_order-actual_cost.
    rs_budget-commit_cost  = ls_order-commit_cost.
    rs_budget-avail_budget = ls_bgt-total_budget - ls_order-actual_cost - ls_order-commit_cost.
    IF rs_budget-total_budget > 0.
      rs_budget-used_pct = ( rs_budget-actual_cost / rs_budget-total_budget ) * 100.
    ENDIF.
    rs_budget-overrun = COND #( WHEN rs_budget-avail_budget < 0 THEN abap_true ELSE abap_false ).
  ENDMETHOD.

  METHOD get_all_budget_status.
    SELECT ord~aufnr ord~ktext
           bgt~total_budget
           ord~actual_cost ord~commit_cost
      FROM zco_internal_order AS ord
      LEFT JOIN zco_budget AS bgt
        ON bgt~kokrs = ord~kokrs AND bgt~aufnr = ord~aufnr AND bgt~gjahr = @iv_gjahr
      WHERE ord~kokrs = @iv_kokrs AND ord~order_status = 'RE'
      INTO TABLE @DATA(lt_raw)
      ORDER BY ord~aufnr.

    LOOP AT lt_raw INTO DATA(ls_raw).
      DATA(ls_bgt) = VALUE ty_budget_status(
        aufnr        = ls_raw-aufnr
        ktext        = ls_raw-ktext
        total_budget = ls_raw-total_budget
        actual_cost  = ls_raw-actual_cost
        commit_cost  = ls_raw-commit_cost ).
      ls_bgt-avail_budget = ls_bgt-total_budget - ls_bgt-actual_cost - ls_bgt-commit_cost.
      IF ls_bgt-total_budget > 0.
        ls_bgt-used_pct = ( ls_bgt-actual_cost / ls_bgt-total_budget ) * 100.
      ENDIF.
      ls_bgt-overrun = COND #( WHEN ls_bgt-avail_budget < 0 THEN abap_true ELSE abap_false ).
      APPEND ls_bgt TO rt_budgets.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_order_cost_detail.
    SELECT al~aufnr ce~ktext AS ktext al~kstar ce~ktext AS cel_name ce~cel_group
           SUM( al~wkgbtr ) AS actual_cost
      FROM zco_actual_line AS al
      LEFT JOIN zco_internal_order AS ord ON ord~kokrs = al~kokrs AND ord~aufnr = al~aufnr
      LEFT JOIN zco_cost_element AS ce ON ce~kokrs = al~kokrs AND ce~kstar = al~kstar
      WHERE al~kokrs = @iv_kokrs AND al~aufnr = @iv_aufnr AND al~gjahr = @iv_gjahr
        AND al~wrttp = '04'
      GROUP BY al~aufnr ce~ktext al~kstar ce~ktext ce~cel_group
      INTO CORRESPONDING FIELDS OF TABLE @rt_costs
      ORDER BY al~kstar.

    " 계획원가 병합
    SELECT pl~kstar SUM( pl~plan_amount ) AS plan_cost
      FROM zco_plan_line AS pl
      WHERE pl~kokrs = @iv_kokrs AND pl~aufnr = @iv_aufnr AND pl~gjahr = @iv_gjahr
        AND pl~version = '000'
      GROUP BY pl~kstar INTO TABLE @DATA(lt_plan).

    LOOP AT rt_costs ASSIGNING FIELD-SYMBOL(<c>).
      READ TABLE lt_plan INTO DATA(ls_p) WITH KEY kstar = <c>-kstar.
      IF sy-subrc = 0. <c>-plan_cost = ls_p-plan_cost. ENDIF.
      <c>-variance = <c>-plan_cost - <c>-actual_cost.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_actual_line_items.
    SELECT al~aufnr al~kstar ce~ktext AS cel_name al~belnr al~budat al~monat
           al~wkgbtr al~sgtxt al~lifnr al~usnam
      FROM zco_actual_line AS al
      LEFT JOIN zco_cost_element AS ce ON ce~kokrs = al~kokrs AND ce~kstar = al~kstar
      WHERE al~kokrs = @iv_kokrs AND al~aufnr = @iv_aufnr AND al~gjahr = @iv_gjahr
        AND al~wrttp = '04'
      INTO TABLE @rt_items
      ORDER BY al~budat DESCENDING.
  ENDMETHOD.

  METHOD settle_order.
    DATA(ls_order) = find_by_id( iv_kokrs = iv_kokrs iv_aufnr = iv_aufnr ).

    IF ls_order-order_status <> 'RE'.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.

    " 미정산 원가 계산
    DATA lv_unsettled TYPE p LENGTH 15 DECIMALS 2.
    lv_unsettled = ls_order-actual_cost.

    IF lv_unsettled = 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.

    " 정산 FI 전표 생성: 차) 정산수신자 / 대) 내부오더
    DATA ls_gl_svc TYPE REF TO zcl_fi_gl_service.
    CREATE OBJECT ls_gl_svc.

    DATA ls_header TYPE zcl_fi_gl_service=>ty_journal_header.
    ls_header-bukrs = ls_order-bukrs.
    ls_header-blart = 'SA'.
    ls_header-bldat = iv_settle_date.
    ls_header-budat = iv_settle_date.
    ls_header-waers = 'KRW'.
    ls_header-bktxt = |오더정산:{ iv_aufnr }|.

    " 정산수신자 유형에 따라 계정 결정
    DATA lv_rcvr_saknr TYPE saknr.
    CASE ls_order-rcvr_type.
      WHEN 'CTR'. lv_rcvr_saknr = '505000'.  " 경비 (코스트센터 정산)
      WHEN 'GL'.  lv_rcvr_saknr = ls_order-settle_rcvr.
      WHEN OTHERS. lv_rcvr_saknr = '505000'.
    ENDCASE.

    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '001' saknr = lv_rcvr_saknr shkzg = 'S'
      dmbtr = lv_unsettled wrbtr = lv_unsettled
      kostl = ls_order-kostl sgtxt = ls_header-bktxt ) TO ls_header-items.
    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '002' saknr = '505000' shkzg = 'H'
      dmbtr = lv_unsettled wrbtr = lv_unsettled
      aufnr = iv_aufnr sgtxt = ls_header-bktxt ) TO ls_header-items.

    DATA(ls_posted) = ls_gl_svc->post_journal( ls_header ).

    rs_result-aufnr        = iv_aufnr.
    rs_result-settle_belnr = ls_posted-belnr.
    rs_result-settled_amt  = lv_unsettled.
    rs_result-settle_date  = iv_settle_date.
    rs_result-rcvr_type    = ls_order-rcvr_type.
    rs_result-settle_rcvr  = ls_order-settle_rcvr.
  ENDMETHOD.

  METHOD close_order.
    DATA(ls_order) = find_by_id( iv_kokrs = iv_kokrs iv_aufnr = iv_aufnr ).
    IF ls_order-order_status <> 'RE'.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    IF ls_order-actual_cost > 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.  " 미정산 원가 있음
    ENDIF.
    UPDATE zco_internal_order
      SET order_status = 'CL', changed_by = @sy-uname
      WHERE kokrs = @iv_kokrs AND aufnr = @iv_aufnr AND mandt = @sy-mandt.
  ENDMETHOD.

  METHOD get_next_aufnr.
    DATA lv_prefix TYPE c LENGTH 3.
    CASE iv_auart.
      WHEN 'ZCO1'. lv_prefix = '100'.
      WHEN 'ZCO2'. lv_prefix = '200'.
      WHEN 'ZCO3'. lv_prefix = '300'.
      WHEN 'ZCO4'. lv_prefix = '400'.
      WHEN 'ZCO5'. lv_prefix = '500'.
      WHEN OTHERS. lv_prefix = '900'.
    ENDCASE.
    DATA lv_from TYPE aufnr.
    DATA lv_to   TYPE aufnr.
    lv_from = |{ lv_prefix }000000000|.
    lv_to   = |{ lv_prefix }999999999|.
    SELECT MAX( aufnr ) FROM zco_internal_order
      WHERE kokrs = @iv_kokrs AND aufnr >= @lv_from AND aufnr <= @lv_to
      INTO @DATA(lv_max).
    rv_aufnr = COND #( WHEN lv_max IS NOT INITIAL THEN lv_max + 1
                       ELSE lv_from + 1 ).
  ENDMETHOD.

  METHOD update_order_actual.
    DATA lv_actual TYPE p LENGTH 15 DECIMALS 2.
    SELECT SUM( wkgbtr ) FROM zco_actual_line
      WHERE kokrs = @iv_kokrs AND aufnr = @iv_aufnr AND wrttp = '04'
      INTO @lv_actual.
    UPDATE zco_internal_order
      SET actual_cost = @lv_actual,
          variance    = budget_amount - @lv_actual
      WHERE kokrs = @iv_kokrs AND aufnr = @iv_aufnr AND mandt = @sy-mandt.
  ENDMETHOD.

ENDCLASS.
