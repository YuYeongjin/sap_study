*&---------------------------------------------------------------------*
*& Class: ZCL_CO_COSTCENTER_SERVICE
*& Description: 코스트센터 서비스 (Cost Center Accounting - CO-CCA)
*& 담당업무: 코스트센터 마스터, 계획/실적 조회, 배분, 차이분석
*& Transaction: SE24
*&---------------------------------------------------------------------*

CLASS zcl_co_costcenter_service DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_cost_center,
        kokrs      TYPE kokrs,
        kostl      TYPE kostl,
        datbi      TYPE datum,
        datab      TYPE datum,
        ktext      TYPE c LENGTH 20,
        ltext      TYPE c LENGTH 40,
        kosar      TYPE kosar,
        verak      TYPE uname,
        abtei      TYPE c LENGTH 12,
        bukrs      TYPE bukrs,
        prctr      TYPE prctr,
        waers      TYPE waers,
        stat_ind   TYPE c LENGTH 1,
        func_area  TYPE fkber,
        created_by TYPE uname,
      END OF ty_cost_center,
      ty_cost_centers TYPE STANDARD TABLE OF ty_cost_center WITH KEY kostl,

      " 코스트센터 실적/계획 비교
      BEGIN OF ty_cc_variance,
        kostl       TYPE kostl,
        ktext       TYPE c LENGTH 20,
        kstar       TYPE kstar,
        cel_name    TYPE c LENGTH 20,
        plan_amount TYPE p LENGTH 15 DECIMALS 2,
        actual_amt  TYPE p LENGTH 15 DECIMALS 2,
        variance    TYPE p LENGTH 15 DECIMALS 2,
        var_pct     TYPE p LENGTH 5 DECIMALS 2,
      END OF ty_cc_variance,
      ty_cc_variances TYPE STANDARD TABLE OF ty_cc_variance WITH KEY kostl kstar,

      " 월별 원가 추이
      BEGIN OF ty_cc_monthly,
        kostl       TYPE kostl,
        monat       TYPE monat,
        kstar       TYPE kstar,
        plan_amount TYPE p LENGTH 15 DECIMALS 2,
        actual_amt  TYPE p LENGTH 15 DECIMALS 2,
      END OF ty_cc_monthly,
      ty_cc_monthlies TYPE STANDARD TABLE OF ty_cc_monthly WITH KEY kostl monat kstar,

      " 원가요소별 집계
      BEGIN OF ty_cc_by_element,
        kstar       TYPE kstar,
        cel_name    TYPE c LENGTH 20,
        cel_group   TYPE c LENGTH 4,
        plan_amount TYPE p LENGTH 15 DECIMALS 2,
        actual_amt  TYPE p LENGTH 15 DECIMALS 2,
        variance    TYPE p LENGTH 15 DECIMALS 2,
      END OF ty_cc_by_element,
      ty_cc_by_elements TYPE STANDARD TABLE OF ty_cc_by_element WITH KEY kstar.

    METHODS:
      " ================================================================
      " 코스트센터 마스터 CRUD
      " ================================================================
      find_all
        IMPORTING iv_kokrs            TYPE kokrs
                  iv_bukrs            TYPE bukrs OPTIONAL
        RETURNING VALUE(rt_cc)        TYPE ty_cost_centers,

      find_by_id
        IMPORTING iv_kokrs            TYPE kokrs
                  iv_kostl            TYPE kostl
        RETURNING VALUE(rs_cc)        TYPE ty_cost_center
        RAISING   cx_abap_not_found,

      find_by_type
        IMPORTING iv_kokrs            TYPE kokrs
                  iv_kosar            TYPE kosar
        RETURNING VALUE(rt_cc)        TYPE ty_cost_centers,

      find_by_profit_center
        IMPORTING iv_kokrs            TYPE kokrs
                  iv_prctr            TYPE prctr
        RETURNING VALUE(rt_cc)        TYPE ty_cost_centers,

      create_cost_center
        IMPORTING is_cc               TYPE ty_cost_center
        RETURNING VALUE(rs_cc)        TYPE ty_cost_center
        RAISING   cx_sy_dyn_call_error,

      update_cost_center
        IMPORTING iv_kokrs            TYPE kokrs
                  iv_kostl            TYPE kostl
                  is_cc               TYPE ty_cost_center
        RETURNING VALUE(rs_cc)        TYPE ty_cost_center
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      deactivate_cost_center
        IMPORTING iv_kokrs TYPE kokrs
                  iv_kostl TYPE kostl
        RAISING   cx_abap_not_found,

      " ================================================================
      " 계획 입력 (KP06 기능)
      " ================================================================
      "! 월별 원가 계획 입력/수정
      save_plan
        IMPORTING iv_kokrs      TYPE kokrs
                  iv_kostl      TYPE kostl
                  iv_kstar      TYPE kstar
                  iv_gjahr      TYPE gjahr
                  iv_version    TYPE c
                  it_monthly    TYPE ty_cc_monthlies
        RAISING   cx_sy_dyn_call_error,

      "! 연간 계획 균등 배분 입력
      save_annual_plan
        IMPORTING iv_kokrs      TYPE kokrs
                  iv_kostl      TYPE kostl
                  iv_kstar      TYPE kstar
                  iv_gjahr      TYPE gjahr
                  iv_version    TYPE c
                  iv_annual_amt TYPE p
        RAISING   cx_sy_dyn_call_error,

      " ================================================================
      " 실적/차이 분석 (KSB1, S_ALR_87013611)
      " ================================================================
      "! 코스트센터별 계획/실적 차이분석
      get_variance_report
        IMPORTING iv_kokrs            TYPE kokrs
                  iv_kostl            TYPE kostl
                  iv_gjahr            TYPE gjahr
                  iv_monat_from       TYPE monat
                  iv_monat_to         TYPE monat
                  iv_version          TYPE c
        RETURNING VALUE(rt_variance)  TYPE ty_cc_variances,

      "! 월별 원가 추이 조회
      get_monthly_trend
        IMPORTING iv_kokrs             TYPE kokrs
                  iv_kostl             TYPE kostl
                  iv_gjahr             TYPE gjahr
                  iv_version           TYPE c
        RETURNING VALUE(rt_monthly)    TYPE ty_cc_monthlies,

      "! 원가요소별 집계 (코스트센터 내)
      get_by_cost_element
        IMPORTING iv_kokrs              TYPE kokrs
                  iv_kostl              TYPE kostl
                  iv_gjahr              TYPE gjahr
                  iv_monat_from         TYPE monat
                  iv_monat_to           TYPE monat
        RETURNING VALUE(rt_elements)    TYPE ty_cc_by_elements,

      "! 실제 원가 라인항목 조회 (KSB1)
      get_actual_line_items
        IMPORTING iv_kokrs           TYPE kokrs
                  iv_kostl           TYPE kostl
                  iv_gjahr           TYPE gjahr
                  iv_monat_from      TYPE monat
                  iv_monat_to        TYPE monat
        RETURNING VALUE(rt_items)    TYPE STANDARD TABLE,

      "! 부서별/현장별 원가 집계
      get_summary_by_dept
        IMPORTING iv_kokrs          TYPE kokrs
                  iv_gjahr          TYPE gjahr
                  iv_monat_from     TYPE monat
                  iv_monat_to       TYPE monat
        RETURNING VALUE(rt_summary) TYPE STANDARD TABLE.

  PRIVATE SECTION.
    METHODS:
      validate_no_postings
        IMPORTING iv_kokrs           TYPE kokrs
                  iv_kostl           TYPE kostl
        RETURNING VALUE(rv_can_del)  TYPE abap_bool.

ENDCLASS.


CLASS zcl_co_costcenter_service IMPLEMENTATION.

  METHOD find_all.
    IF iv_bukrs IS NOT INITIAL.
      SELECT kokrs kostl datbi datab ktext ltext kosar verak abtei bukrs prctr waers stat_ind func_area created_by
        FROM zco_cost_center
        WHERE kokrs = @iv_kokrs AND bukrs = @iv_bukrs AND stat_ind <> 'D'
        INTO CORRESPONDING FIELDS OF TABLE @rt_cc
        ORDER BY kostl.
    ELSE.
      SELECT kokrs kostl datbi datab ktext ltext kosar verak abtei bukrs prctr waers stat_ind func_area created_by
        FROM zco_cost_center
        WHERE kokrs = @iv_kokrs AND stat_ind <> 'D'
        INTO CORRESPONDING FIELDS OF TABLE @rt_cc
        ORDER BY kostl.
    ENDIF.
  ENDMETHOD.

  METHOD find_by_id.
    SELECT SINGLE kokrs kostl datbi datab ktext ltext kosar verak abtei bukrs prctr waers stat_ind func_area created_by
      FROM zco_cost_center
      WHERE kokrs = @iv_kokrs AND kostl = @iv_kostl
      INTO CORRESPONDING FIELDS OF @rs_cc.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.
  ENDMETHOD.

  METHOD find_by_type.
    SELECT kokrs kostl datbi datab ktext ltext kosar verak abtei bukrs prctr waers stat_ind func_area created_by
      FROM zco_cost_center
      WHERE kokrs = @iv_kokrs AND kosar = @iv_kosar AND stat_ind <> 'D'
      INTO CORRESPONDING FIELDS OF TABLE @rt_cc
      ORDER BY kostl.
  ENDMETHOD.

  METHOD find_by_profit_center.
    SELECT kokrs kostl datbi datab ktext ltext kosar verak abtei bukrs prctr waers stat_ind func_area created_by
      FROM zco_cost_center
      WHERE kokrs = @iv_kokrs AND prctr = @iv_prctr AND stat_ind <> 'D'
      INTO CORRESPONDING FIELDS OF TABLE @rt_cc
      ORDER BY kostl.
  ENDMETHOD.

  METHOD create_cost_center.
    DATA ls_db TYPE zco_cost_center.
    SELECT COUNT(*) FROM zco_cost_center
      WHERE kokrs = @is_cc-kokrs AND kostl = @is_cc-kostl
      INTO @DATA(lv_cnt).
    IF lv_cnt > 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
    rs_cc = is_cc.
    rs_cc-stat_ind = 'A'.
    MOVE-CORRESPONDING rs_cc TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-created_by = sy-uname.
    GET TIME STAMP FIELD ls_db-created_at.
    INSERT zco_cost_center FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD update_cost_center.
    find_by_id( iv_kokrs = iv_kokrs iv_kostl = iv_kostl ).
    rs_cc = is_cc.
    UPDATE zco_cost_center
      SET ktext     = @rs_cc-ktext,
          ltext     = @rs_cc-ltext,
          verak     = @rs_cc-verak,
          prctr     = @rs_cc-prctr,
          func_area = @rs_cc-func_area,
          changed_by = @sy-uname
      WHERE kokrs = @iv_kokrs AND kostl = @iv_kostl AND mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD deactivate_cost_center.
    find_by_id( iv_kokrs = iv_kokrs iv_kostl = iv_kostl ).
    " 실적이 있는 경우 비활성화만 허용 (물리삭제 불가)
    UPDATE zco_cost_center
      SET stat_ind   = 'I',
          changed_by = @sy-uname
      WHERE kokrs = @iv_kokrs AND kostl = @iv_kostl AND mandt = @sy-mandt.
  ENDMETHOD.

  METHOD save_plan.
    LOOP AT it_monthly INTO DATA(ls_plan).
      " 기존 계획 조회
      SELECT COUNT(*) FROM zco_plan_line
        WHERE kokrs = @iv_kokrs AND gjahr = @iv_gjahr AND version = @iv_version
          AND kostl = @iv_kostl AND kstar = @iv_kstar AND monat = @ls_plan-monat
        INTO @DATA(lv_cnt).

      IF lv_cnt > 0.
        " 수정
        UPDATE zco_plan_line
          SET plan_amount = @ls_plan-plan_amount
          WHERE kokrs = @iv_kokrs AND gjahr = @iv_gjahr AND version = @iv_version
            AND kostl = @iv_kostl AND kstar = @iv_kstar AND monat = @ls_plan-monat
            AND mandt = @sy-mandt.
      ELSE.
        " 신규
        DATA ls_db TYPE zco_plan_line.
        ls_db-mandt       = sy-mandt.
        ls_db-kokrs       = iv_kokrs.
        ls_db-gjahr       = iv_gjahr.
        ls_db-version     = iv_version.
        ls_db-kostl       = iv_kostl.
        ls_db-kstar       = iv_kstar.
        ls_db-monat       = ls_plan-monat.
        ls_db-plan_amount = ls_plan-plan_amount.
        ls_db-plan_status = 'A'.
        ls_db-twaer       = 'KRW'.
        ls_db-created_by  = sy-uname.
        GET TIME STAMP FIELD ls_db-created_at.
        INSERT zco_plan_line FROM ls_db.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD save_annual_plan.
    " 연간 계획을 12등분하여 월별 저장
    DATA lv_monthly TYPE p LENGTH 15 DECIMALS 2.
    DATA lv_last    TYPE p LENGTH 15 DECIMALS 2.
    lv_monthly = TRUNC( iv_annual_amt / 12 ).
    lv_last    = iv_annual_amt - ( lv_monthly * 11 ).  " 12월 잔액 처리

    DATA lt_monthly TYPE ty_cc_monthlies.
    DO 12 TIMES.
      APPEND VALUE ty_cc_monthly(
        kostl       = iv_kostl
        monat       = sy-index
        kstar       = iv_kstar
        plan_amount = COND #( WHEN sy-index = 12 THEN lv_last ELSE lv_monthly )
      ) TO lt_monthly.
    ENDDO.

    save_plan(
      iv_kokrs   = iv_kokrs
      iv_kostl   = iv_kostl
      iv_kstar   = iv_kstar
      iv_gjahr   = iv_gjahr
      iv_version = iv_version
      it_monthly = lt_monthly ).
  ENDMETHOD.

  METHOD get_variance_report.
    " 실적 집계
    SELECT al~kostl al~kstar
           SUM( al~wkgbtr ) AS actual_amt
      FROM zco_actual_line AS al
      WHERE al~kokrs = @iv_kokrs AND al~gjahr = @iv_gjahr
        AND al~monat >= @iv_monat_from AND al~monat <= @iv_monat_to
        AND al~kostl = @iv_kostl AND al~wrttp = '04'
      GROUP BY al~kostl al~kstar
      INTO TABLE @DATA(lt_actual).

    " 계획 집계
    SELECT pl~kostl pl~kstar
           SUM( pl~plan_amount ) AS plan_amount
      FROM zco_plan_line AS pl
      WHERE pl~kokrs = @iv_kokrs AND pl~gjahr = @iv_gjahr
        AND pl~monat >= @iv_monat_from AND pl~monat <= @iv_monat_to
        AND pl~kostl = @iv_kostl AND pl~version = @iv_version
      GROUP BY pl~kostl pl~kstar
      INTO TABLE @DATA(lt_plan).

    " 차이 계산
    LOOP AT lt_plan INTO DATA(ls_plan).
      DATA(ls_var) = VALUE ty_cc_variance(
        kostl       = ls_plan-kostl
        kstar       = ls_plan-kstar
        plan_amount = ls_plan-plan_amount ).

      SELECT SINGLE ktext FROM zco_cost_center
        WHERE kokrs = @iv_kokrs AND kostl = @ls_var-kostl INTO @ls_var-ktext.
      SELECT SINGLE ktext FROM zco_cost_element
        WHERE kokrs = @iv_kokrs AND kstar = @ls_var-kstar INTO @ls_var-cel_name.

      READ TABLE lt_actual INTO DATA(ls_act) WITH KEY kostl = ls_plan-kostl kstar = ls_plan-kstar.
      IF sy-subrc = 0.
        ls_var-actual_amt = ls_act-actual_amt.
      ENDIF.

      ls_var-variance = ls_var-plan_amount - ls_var-actual_amt.
      IF ls_var-plan_amount <> 0.
        ls_var-var_pct = ( ls_var-variance / ls_var-plan_amount ) * 100.
      ENDIF.
      APPEND ls_var TO rt_variance.
    ENDLOOP.

    " 계획에 없지만 실적 있는 항목 추가
    LOOP AT lt_actual INTO DATA(ls_actonly).
      READ TABLE rt_variance WITH KEY kostl = ls_actonly-kostl kstar = ls_actonly-kstar TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        APPEND VALUE ty_cc_variance(
          kostl      = ls_actonly-kostl
          kstar      = ls_actonly-kstar
          actual_amt = ls_actonly-actual_amt
          variance   = -1 * ls_actonly-actual_amt ) TO rt_variance.
      ENDIF.
    ENDLOOP.
    SORT rt_variance BY kostl kstar.
  ENDMETHOD.

  METHOD get_monthly_trend.
    " 월별 계획
    SELECT kostl kstar monat plan_amount
      FROM zco_plan_line
      WHERE kokrs = @iv_kokrs AND gjahr = @iv_gjahr AND version = @iv_version
        AND kostl = @iv_kostl
      INTO CORRESPONDING FIELDS OF TABLE @rt_monthly
      ORDER BY kstar monat.

    " 월별 실적 병합
    SELECT al~kostl al~kstar al~monat SUM( al~wkgbtr ) AS actual_amt
      FROM zco_actual_line AS al
      WHERE al~kokrs = @iv_kokrs AND al~gjahr = @iv_gjahr AND al~kostl = @iv_kostl
        AND al~wrttp = '04'
      GROUP BY al~kostl al~kstar al~monat
      INTO TABLE @DATA(lt_actual)
      ORDER BY al~kstar al~monat.

    LOOP AT lt_actual INTO DATA(ls_act).
      READ TABLE rt_monthly ASSIGNING FIELD-SYMBOL(<mo>)
        WITH KEY kostl = ls_act-kostl kstar = ls_act-kstar monat = ls_act-monat.
      IF sy-subrc = 0.
        <mo>-actual_amt = ls_act-actual_amt.
      ELSE.
        APPEND VALUE ty_cc_monthly(
          kostl      = ls_act-kostl kstar = ls_act-kstar
          monat      = ls_act-monat actual_amt = ls_act-actual_amt ) TO rt_monthly.
      ENDIF.
    ENDLOOP.
    SORT rt_monthly BY kstar monat.
  ENDMETHOD.

  METHOD get_by_cost_element.
    SELECT al~kstar ce~ktext AS cel_name ce~cel_group
           SUM( al~wkgbtr ) AS actual_amt
      FROM zco_actual_line AS al
      LEFT JOIN zco_cost_element AS ce
        ON ce~kokrs = al~kokrs AND ce~kstar = al~kstar
      WHERE al~kokrs = @iv_kokrs AND al~kostl = @iv_kostl AND al~gjahr = @iv_gjahr
        AND al~monat >= @iv_monat_from AND al~monat <= @iv_monat_to
        AND al~wrttp = '04'
      GROUP BY al~kstar ce~ktext ce~cel_group
      INTO CORRESPONDING FIELDS OF TABLE @rt_elements
      ORDER BY al~kstar.

    " 계획 병합
    SELECT pl~kstar SUM( pl~plan_amount ) AS plan_amount
      FROM zco_plan_line AS pl
      WHERE pl~kokrs = @iv_kokrs AND pl~kostl = @iv_kostl AND pl~gjahr = @iv_gjahr
        AND pl~monat >= @iv_monat_from AND pl~monat <= @iv_monat_to
        AND pl~version = '000'
      GROUP BY pl~kstar
      INTO TABLE @DATA(lt_plan).

    LOOP AT rt_elements ASSIGNING FIELD-SYMBOL(<el>).
      READ TABLE lt_plan INTO DATA(ls_p) WITH KEY kstar = <el>-kstar.
      IF sy-subrc = 0.
        <el>-plan_amount = ls_p-plan_amount.
      ENDIF.
      <el>-variance = <el>-plan_amount - <el>-actual_amt.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_actual_line_items.
    SELECT al~kostl al~kstar al~belnr al~budat al~monat al~wkgbtr al~sgtxt al~lifnr al~usnam
           ce~ktext AS cel_name
      FROM zco_actual_line AS al
      LEFT JOIN zco_cost_element AS ce ON ce~kokrs = al~kokrs AND ce~kstar = al~kstar
      WHERE al~kokrs = @iv_kokrs AND al~kostl = @iv_kostl AND al~gjahr = @iv_gjahr
        AND al~monat >= @iv_monat_from AND al~monat <= @iv_monat_to
        AND al~wrttp = '04'
      INTO TABLE @rt_items
      ORDER BY al~budat DESCENDING.
  ENDMETHOD.

  METHOD get_summary_by_dept.
    SELECT cc~abtei cc~kostl cc~ktext
           SUM( al~wkgbtr ) AS actual_amt
      FROM zco_actual_line AS al
      INNER JOIN zco_cost_center AS cc ON cc~kokrs = al~kokrs AND cc~kostl = al~kostl
      WHERE al~kokrs = @iv_kokrs AND al~gjahr = @iv_gjahr
        AND al~monat >= @iv_monat_from AND al~monat <= @iv_monat_to
        AND al~wrttp = '04'
      GROUP BY cc~abtei cc~kostl cc~ktext
      INTO TABLE @rt_summary
      ORDER BY cc~abtei cc~kostl.
  ENDMETHOD.

  METHOD validate_no_postings.
    SELECT COUNT(*) FROM zco_actual_line
      WHERE kokrs = @iv_kokrs AND kostl = @iv_kostl
      INTO @DATA(lv_cnt).
    rv_can_del = COND #( WHEN lv_cnt = 0 THEN abap_true ELSE abap_false ).
  ENDMETHOD.

ENDCLASS.
