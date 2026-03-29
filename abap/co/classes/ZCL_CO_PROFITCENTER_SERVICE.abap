*&---------------------------------------------------------------------*
*& Class: ZCL_CO_PROFITCENTER_SERVICE
*& Description: 수익센터 서비스 (Profit Center Accounting - EC-PCA)
*& 담당업무: 수익센터 마스터 CRUD, 수익/원가 집계, 손익분석
*& Transaction: SE24
*&---------------------------------------------------------------------*

CLASS zcl_co_profitcenter_service DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_profit_center,
        kokrs          TYPE kokrs,
        prctr          TYPE prctr,
        datbi          TYPE datum,
        datab          TYPE datum,
        ktext          TYPE c LENGTH 20,
        ltext          TYPE c LENGTH 40,
        verak          TYPE uname,
        bukrs          TYPE bukrs,
        pc_type        TYPE c LENGTH 4,
        stat_ind       TYPE c LENGTH 1,
        revenue_plan   TYPE p LENGTH 15 DECIMALS 2,
        revenue_actual TYPE p LENGTH 15 DECIMALS 2,
        cost_plan      TYPE p LENGTH 15 DECIMALS 2,
        cost_actual    TYPE p LENGTH 15 DECIMALS 2,
        profit_plan    TYPE p LENGTH 15 DECIMALS 2,
        profit_actual  TYPE p LENGTH 15 DECIMALS 2,
        created_by     TYPE uname,
      END OF ty_profit_center,
      ty_profit_centers TYPE STANDARD TABLE OF ty_profit_center WITH KEY prctr,

      " 수익센터 손익 보고서
      BEGIN OF ty_pca_pl_report,
        prctr          TYPE prctr,
        ktext          TYPE c LENGTH 20,
        pc_type        TYPE c LENGTH 4,
        revenue        TYPE p LENGTH 15 DECIMALS 2,
        direct_cost    TYPE p LENGTH 15 DECIMALS 2,
        indirect_cost  TYPE p LENGTH 15 DECIMALS 2,
        total_cost     TYPE p LENGTH 15 DECIMALS 2,
        gross_profit   TYPE p LENGTH 15 DECIMALS 2,
        profit_margin  TYPE p LENGTH 5 DECIMALS 2,
      END OF ty_pca_pl_report,
      ty_pca_pl_reports TYPE STANDARD TABLE OF ty_pca_pl_report WITH KEY prctr,

      " 월별 수익 추이
      BEGIN OF ty_pca_monthly,
        prctr         TYPE prctr,
        monat         TYPE monat,
        revenue       TYPE p LENGTH 15 DECIMALS 2,
        cost          TYPE p LENGTH 15 DECIMALS 2,
        profit        TYPE p LENGTH 15 DECIMALS 2,
      END OF ty_pca_monthly,
      ty_pca_monthlies TYPE STANDARD TABLE OF ty_pca_monthly WITH KEY prctr monat.

    METHODS:
      find_all
        IMPORTING iv_kokrs             TYPE kokrs
        RETURNING VALUE(rt_pcs)        TYPE ty_profit_centers,

      find_by_id
        IMPORTING iv_kokrs             TYPE kokrs
                  iv_prctr             TYPE prctr
        RETURNING VALUE(rs_pc)         TYPE ty_profit_center
        RAISING   cx_abap_not_found,

      create_profit_center
        IMPORTING is_pc                TYPE ty_profit_center
        RETURNING VALUE(rs_pc)         TYPE ty_profit_center
        RAISING   cx_sy_dyn_call_error,

      update_profit_center
        IMPORTING iv_kokrs             TYPE kokrs
                  iv_prctr             TYPE prctr
                  is_pc                TYPE ty_profit_center
        RETURNING VALUE(rs_pc)         TYPE ty_profit_center
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      "! 수익센터 손익계산서 (S_ALR_87009712)
      get_pl_report
        IMPORTING iv_kokrs              TYPE kokrs
                  iv_gjahr              TYPE gjahr
                  iv_monat_from         TYPE monat
                  iv_monat_to           TYPE monat
        RETURNING VALUE(rt_report)      TYPE ty_pca_pl_reports,

      "! 월별 수익 추이
      get_monthly_trend
        IMPORTING iv_kokrs              TYPE kokrs
                  iv_prctr              TYPE prctr
                  iv_gjahr              TYPE gjahr
        RETURNING VALUE(rt_monthly)     TYPE ty_pca_monthlies,

      "! 수익센터 실적 갱신 (AR/AP 전기 시 호출)
      refresh_actual
        IMPORTING iv_kokrs TYPE kokrs
                  iv_prctr TYPE prctr
                  iv_gjahr TYPE gjahr.

ENDCLASS.


CLASS zcl_co_profitcenter_service IMPLEMENTATION.

  METHOD find_all.
    SELECT kokrs prctr datbi datab ktext ltext verak bukrs pc_type stat_ind
           revenue_plan revenue_actual cost_plan cost_actual profit_plan profit_actual created_by
      FROM zco_profit_center
      WHERE kokrs = @iv_kokrs AND stat_ind = 'A'
      INTO CORRESPONDING FIELDS OF TABLE @rt_pcs
      ORDER BY prctr.
  ENDMETHOD.

  METHOD find_by_id.
    SELECT SINGLE kokrs prctr datbi datab ktext ltext verak bukrs pc_type stat_ind
                  revenue_plan revenue_actual cost_plan cost_actual profit_plan profit_actual created_by
      FROM zco_profit_center
      WHERE kokrs = @iv_kokrs AND prctr = @iv_prctr
      INTO CORRESPONDING FIELDS OF @rs_pc.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.
  ENDMETHOD.

  METHOD create_profit_center.
    DATA ls_db TYPE zco_profit_center.
    SELECT COUNT(*) FROM zco_profit_center
      WHERE kokrs = @is_pc-kokrs AND prctr = @is_pc-prctr
      INTO @DATA(lv_cnt).
    IF lv_cnt > 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    rs_pc = is_pc.
    rs_pc-stat_ind = 'A'.
    MOVE-CORRESPONDING rs_pc TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-created_by = sy-uname.
    GET TIME STAMP FIELD ls_db-created_at.
    INSERT zco_profit_center FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD update_profit_center.
    find_by_id( iv_kokrs = iv_kokrs iv_prctr = iv_prctr ).
    rs_pc = is_pc.
    UPDATE zco_profit_center
      SET ktext        = @rs_pc-ktext,
          ltext        = @rs_pc-ltext,
          verak        = @rs_pc-verak,
          revenue_plan = @rs_pc-revenue_plan,
          cost_plan    = @rs_pc-cost_plan,
          profit_plan  = @rs_pc-profit_plan,
          changed_by   = @sy-uname
      WHERE kokrs = @iv_kokrs AND prctr = @iv_prctr AND mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD get_pl_report.
    " 수익 집계 (AR 청구서에서)
    SELECT ar~prctr pc~ktext pc~pc_type
           SUM( ai~net_amount ) AS revenue
      FROM zfi_ar_item AS ai
      INNER JOIN zfi_ar_invoice AS ar ON ar~ar_invno = ai~ar_invno AND ar~bukrs = ai~bukrs
      LEFT JOIN zco_profit_center AS pc ON pc~prctr = ar~prctr AND pc~kokrs = @iv_kokrs
      WHERE ar~gjahr = @iv_gjahr
        AND ar~budat+4(2) >= @iv_monat_from AND ar~budat+4(2) <= @iv_monat_to
        AND ar~prctr IS NOT INITIAL
      GROUP BY ar~prctr pc~ktext pc~pc_type
      INTO TABLE @DATA(lt_revenue)
      ORDER BY ar~prctr.

    " 원가 집계 (CO 실적 라인에서)
    SELECT al~prctr
           SUM( CASE ce~cel_group WHEN 'REVN' THEN 0 ELSE al~wkgbtr END ) AS total_cost
           SUM( CASE ce~cel_group
                  WHEN 'LABR' THEN al~wkgbtr WHEN 'MATL' THEN al~wkgbtr
                  WHEN 'SUBK' THEN al~wkgbtr WHEN 'EQUP' THEN al~wkgbtr
                  ELSE 0 END ) AS direct_cost
           SUM( CASE ce~cel_group WHEN 'OVER' THEN al~wkgbtr WHEN 'IDRT' THEN al~wkgbtr
                  ELSE 0 END ) AS indirect_cost
      FROM zco_actual_line AS al
      LEFT JOIN zco_cost_element AS ce ON ce~kokrs = al~kokrs AND ce~kstar = al~kstar
      WHERE al~kokrs = @iv_kokrs AND al~gjahr = @iv_gjahr
        AND al~monat >= @iv_monat_from AND al~monat <= @iv_monat_to
        AND al~prctr IS NOT INITIAL AND al~wrttp = '04'
      GROUP BY al~prctr
      INTO TABLE @DATA(lt_cost)
      ORDER BY al~prctr.

    LOOP AT lt_revenue INTO DATA(ls_rev).
      DATA(ls_rpt) = VALUE ty_pca_pl_report(
        prctr   = ls_rev-prctr
        ktext   = ls_rev-ktext
        pc_type = ls_rev-pc_type
        revenue = ls_rev-revenue ).

      READ TABLE lt_cost INTO DATA(ls_cost) WITH KEY prctr = ls_rev-prctr.
      IF sy-subrc = 0.
        ls_rpt-direct_cost   = ls_cost-direct_cost.
        ls_rpt-indirect_cost = ls_cost-indirect_cost.
        ls_rpt-total_cost    = ls_cost-total_cost.
      ENDIF.

      ls_rpt-gross_profit = ls_rpt-revenue - ls_rpt-total_cost.
      IF ls_rpt-revenue <> 0.
        ls_rpt-profit_margin = ( ls_rpt-gross_profit / ls_rpt-revenue ) * 100.
      ENDIF.
      APPEND ls_rpt TO rt_report.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_monthly_trend.
    DO 12 TIMES.
      DATA lv_monat TYPE monat.
      lv_monat = sy-index.

      " 월별 수익 (AR)
      DATA lv_rev TYPE p LENGTH 15 DECIMALS 2.
      SELECT SUM( ai~net_amount ) FROM zfi_ar_item AS ai
        INNER JOIN zfi_ar_invoice AS ar ON ar~ar_invno = ai~ar_invno AND ar~bukrs = ai~bukrs
        WHERE ar~prctr = @iv_prctr AND ar~gjahr = @iv_gjahr
          AND ar~budat+4(2) = @lv_monat
        INTO @lv_rev.

      " 월별 원가 (CO)
      DATA lv_cost TYPE p LENGTH 15 DECIMALS 2.
      SELECT SUM( wkgbtr ) FROM zco_actual_line
        WHERE kokrs = @iv_kokrs AND prctr = @iv_prctr AND gjahr = @iv_gjahr
          AND monat = @lv_monat AND wrttp = '04'
        INTO @lv_cost.

      APPEND VALUE ty_pca_monthly(
        prctr  = iv_prctr monat = lv_monat
        revenue = lv_rev cost = lv_cost
        profit  = lv_rev - lv_cost ) TO rt_monthly.
    ENDDO.
  ENDMETHOD.

  METHOD refresh_actual.
    " 수익 재집계
    DATA lv_rev TYPE p LENGTH 15 DECIMALS 2.
    SELECT SUM( ai~net_amount ) FROM zfi_ar_item AS ai
      INNER JOIN zfi_ar_invoice AS ar ON ar~ar_invno = ai~ar_invno AND ar~bukrs = ai~bukrs
      WHERE ar~prctr = @iv_prctr AND ar~gjahr = @iv_gjahr
      INTO @lv_rev.

    " 원가 재집계
    DATA lv_cost TYPE p LENGTH 15 DECIMALS 2.
    SELECT SUM( wkgbtr ) FROM zco_actual_line
      WHERE kokrs = @iv_kokrs AND prctr = @iv_prctr AND gjahr = @iv_gjahr AND wrttp = '04'
      INTO @lv_cost.

    UPDATE zco_profit_center
      SET revenue_actual = @lv_rev,
          cost_actual    = @lv_cost,
          profit_actual  = @lv_rev - @lv_cost
      WHERE kokrs = @iv_kokrs AND prctr = @iv_prctr AND mandt = @sy-mandt.
  ENDMETHOD.

ENDCLASS.
