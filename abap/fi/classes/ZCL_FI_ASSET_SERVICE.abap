*&---------------------------------------------------------------------*
*& Class: ZCL_FI_ASSET_SERVICE
*& Description: 자산회계 서비스 (Asset Accounting Service - FI-AA)
*& 담당업무: 자산 마스터 관리, 취득/제각, 감가상각 계산/전기
*& Transaction: SE24
*&---------------------------------------------------------------------*

CLASS zcl_fi_asset_service DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_asset,
        bukrs          TYPE bukrs,
        anln1          TYPE anln1,
        anln2          TYPE anln2,
        asset_class    TYPE c LENGTH 8,
        txt50          TYPE c LENGTH 50,
        txt20          TYPE c LENGTH 20,
        kostl          TYPE kostl,
        aufnr          TYPE aufnr,
        prctr          TYPE prctr,
        invdate        TYPE datum,
        deact_date     TYPE datum,
        vendor         TYPE lifnr,
        orig_cost      TYPE p LENGTH 15 DECIMALS 2,
        curr_book_val  TYPE p LENGTH 15 DECIMALS 2,
        accum_depr     TYPE p LENGTH 15 DECIMALS 2,
        depr_key       TYPE c LENGTH 4,
        useful_life    TYPE n LENGTH 3,
        curr_year_depr TYPE p LENGTH 15 DECIMALS 2,
        waers          TYPE waers,
        asset_status   TYPE c LENGTH 1,
        location       TYPE c LENGTH 30,
        proj_id        TYPE n LENGTH 10,
        created_by     TYPE uname,
      END OF ty_asset,
      ty_assets TYPE STANDARD TABLE OF ty_asset WITH KEY anln1 anln2,

      BEGIN OF ty_asset_depr,
        bukrs        TYPE bukrs,
        anln1        TYPE anln1,
        anln2        TYPE anln2,
        gjahr        TYPE gjahr,
        afabe        TYPE n LENGTH 2,
        depr_period  TYPE n LENGTH 2,
        depr_amount  TYPE p LENGTH 15 DECIMALS 2,
        accum_depr   TYPE p LENGTH 15 DECIMALS 2,
        book_value   TYPE p LENGTH 15 DECIMALS 2,
        depr_status  TYPE c LENGTH 1,
        posted_belnr TYPE belnr_d,
        post_date    TYPE datum,
      END OF ty_asset_depr,
      ty_asset_deprs TYPE STANDARD TABLE OF ty_asset_depr WITH KEY gjahr afabe depr_period,

      " 감가상각 시뮬레이션 결과
      BEGIN OF ty_depr_simulation,
        gjahr       TYPE gjahr,
        period      TYPE n LENGTH 2,
        depr_amount TYPE p LENGTH 15 DECIMALS 2,
        accum_depr  TYPE p LENGTH 15 DECIMALS 2,
        book_value  TYPE p LENGTH 15 DECIMALS 2,
      END OF ty_depr_simulation,
      ty_depr_simulations TYPE STANDARD TABLE OF ty_depr_simulation WITH KEY gjahr period.

    METHODS:
      " ================================================================
      " 자산 마스터 CRUD
      " ================================================================
      find_all_assets
        IMPORTING iv_bukrs         TYPE bukrs
                  iv_asset_class   TYPE c OPTIONAL
        RETURNING VALUE(rt_assets) TYPE ty_assets,

      find_asset_by_id
        IMPORTING iv_bukrs         TYPE bukrs
                  iv_anln1         TYPE anln1
                  iv_anln2         TYPE anln2
        RETURNING VALUE(rs_asset)  TYPE ty_asset
        RAISING   cx_abap_not_found,

      find_assets_by_project
        IMPORTING iv_bukrs         TYPE bukrs
                  iv_proj_id       TYPE n
        RETURNING VALUE(rt_assets) TYPE ty_assets,

      "! 자산 취득 등록
      acquire_asset
        IMPORTING is_asset         TYPE ty_asset
        RETURNING VALUE(rs_asset)  TYPE ty_asset
        RAISING   cx_sy_dyn_call_error,

      update_asset
        IMPORTING iv_bukrs         TYPE bukrs
                  iv_anln1         TYPE anln1
                  iv_anln2         TYPE anln2
                  is_asset         TYPE ty_asset
        RETURNING VALUE(rs_asset)  TYPE ty_asset
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      "! 자산 이관 (다른 코스트센터/프로젝트로)
      transfer_asset
        IMPORTING iv_bukrs     TYPE bukrs
                  iv_anln1     TYPE anln1
                  iv_anln2     TYPE anln2
                  iv_new_kostl TYPE kostl
                  iv_new_prctr TYPE prctr
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      "! 자산 제각 (Retirement)
      retire_asset
        IMPORTING iv_bukrs       TYPE bukrs
                  iv_anln1       TYPE anln1
                  iv_anln2       TYPE anln2
                  iv_retire_date TYPE datum
                  iv_retire_val  TYPE p
        RAISING   cx_abap_not_found
                  cx_sy_dyn_call_error,

      " ================================================================
      " 감가상각
      " ================================================================
      "! 월별 감가상각 계산 (시뮬레이션)
      simulate_depreciation
        IMPORTING iv_bukrs              TYPE bukrs
                  iv_anln1              TYPE anln1
                  iv_anln2              TYPE anln2
                  iv_from_gjahr         TYPE gjahr
                  iv_from_period        TYPE n
        RETURNING VALUE(rt_simulation)  TYPE ty_depr_simulations
        RAISING   cx_abap_not_found,

      "! 월 감가상각 전기 (전체 자산 일괄)
      post_depreciation_run
        IMPORTING iv_bukrs     TYPE bukrs
                  iv_gjahr     TYPE gjahr
                  iv_period    TYPE n
        RETURNING VALUE(rv_posted_cnt) TYPE i,

      "! 자산별 감가상각 내역 조회
      find_depr_history
        IMPORTING iv_bukrs           TYPE bukrs
                  iv_anln1           TYPE anln1
                  iv_anln2           TYPE anln2
                  iv_gjahr           TYPE gjahr
        RETURNING VALUE(rt_history)  TYPE ty_asset_deprs,

      "! 자산 장부가액 현황 (클래스별 집계)
      get_asset_balance_by_class
        IMPORTING iv_bukrs          TYPE bukrs
                  iv_gjahr          TYPE gjahr
        RETURNING VALUE(rt_result)  TYPE STANDARD TABLE.

  PRIVATE SECTION.
    METHODS:
      get_next_asset_no
        IMPORTING iv_bukrs         TYPE bukrs
        RETURNING VALUE(rv_anln1)  TYPE anln1,

      calc_monthly_depr
        IMPORTING is_asset           TYPE ty_asset
        RETURNING VALUE(rv_depr_amt) TYPE p LENGTH 15 DECIMALS 2,

      post_fi_depr_document
        IMPORTING iv_bukrs      TYPE bukrs
                  iv_anln1      TYPE anln1
                  iv_anln2      TYPE anln2
                  iv_depr_amt   TYPE p
                  iv_kostl      TYPE kostl
                  iv_period     TYPE n
                  iv_gjahr      TYPE gjahr
        RETURNING VALUE(rv_belnr) TYPE belnr_d
        RAISING   cx_sy_dyn_call_error.

ENDCLASS.


CLASS zcl_fi_asset_service IMPLEMENTATION.

  METHOD find_all_assets.
    IF iv_asset_class IS NOT INITIAL.
      SELECT bukrs anln1 anln2 asset_class txt50 txt20 kostl aufnr prctr
             invdate deact_date vendor orig_cost curr_book_val accum_depr
             depr_key useful_life curr_year_depr waers asset_status location proj_id created_by
        FROM zfi_asset
        WHERE bukrs = @iv_bukrs AND asset_class = @iv_asset_class AND asset_status <> 'D'
        INTO CORRESPONDING FIELDS OF TABLE @rt_assets
        ORDER BY anln1.
    ELSE.
      SELECT bukrs anln1 anln2 asset_class txt50 txt20 kostl aufnr prctr
             invdate deact_date vendor orig_cost curr_book_val accum_depr
             depr_key useful_life curr_year_depr waers asset_status location proj_id created_by
        FROM zfi_asset
        WHERE bukrs = @iv_bukrs AND asset_status <> 'D'
        INTO CORRESPONDING FIELDS OF TABLE @rt_assets
        ORDER BY anln1.
    ENDIF.
  ENDMETHOD.

  METHOD find_asset_by_id.
    SELECT SINGLE bukrs anln1 anln2 asset_class txt50 txt20 kostl aufnr prctr
                  invdate deact_date vendor orig_cost curr_book_val accum_depr
                  depr_key useful_life curr_year_depr waers asset_status location proj_id created_by
      FROM zfi_asset
      WHERE bukrs = @iv_bukrs AND anln1 = @iv_anln1 AND anln2 = @iv_anln2
      INTO CORRESPONDING FIELDS OF @rs_asset.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_not_found.
    ENDIF.
  ENDMETHOD.

  METHOD find_assets_by_project.
    SELECT bukrs anln1 anln2 asset_class txt50 txt20 kostl aufnr prctr
           invdate deact_date vendor orig_cost curr_book_val accum_depr
           depr_key useful_life curr_year_depr waers asset_status location proj_id created_by
      FROM zfi_asset
      WHERE bukrs = @iv_bukrs AND proj_id = @iv_proj_id AND asset_status <> 'D'
      INTO CORRESPONDING FIELDS OF TABLE @rt_assets
      ORDER BY asset_class anln1.
  ENDMETHOD.

  METHOD acquire_asset.
    DATA ls_db TYPE zfi_asset.
    rs_asset = is_asset.
    rs_asset-anln1       = get_next_asset_no( iv_bukrs = is_asset-bukrs ).
    rs_asset-anln2       = '0000'.
    rs_asset-curr_book_val = is_asset-orig_cost.
    rs_asset-accum_depr    = 0.
    rs_asset-asset_status  = 'A'.

    MOVE-CORRESPONDING rs_asset TO ls_db.
    ls_db-mandt      = sy-mandt.
    ls_db-created_by = sy-uname.
    GET TIME STAMP FIELD ls_db-created_at.
    INSERT zfi_asset FROM ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.

    " 취득 FI 전표: 차) 자산(111000) / 대) 보통예금(101100) or 미지급금(202000)
    DATA ls_gl_svc TYPE REF TO zcl_fi_gl_service.
    CREATE OBJECT ls_gl_svc.
    DATA ls_header TYPE zcl_fi_gl_service=>ty_journal_header.
    ls_header-bukrs = rs_asset-bukrs.
    ls_header-blart = 'SA'.
    ls_header-bldat = rs_asset-invdate.
    ls_header-budat = rs_asset-invdate.
    ls_header-waers = rs_asset-waers.
    ls_header-bktxt = |자산취득:{ rs_asset-txt20 }|.

    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '001' saknr = '111000' shkzg = 'S'
      dmbtr = rs_asset-orig_cost wrbtr = rs_asset-orig_cost
      kostl = rs_asset-kostl anln1 = rs_asset-anln1 anln2 = rs_asset-anln2
      sgtxt = ls_header-bktxt ) TO ls_header-items.
    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '002' saknr = '202000' shkzg = 'H'
      dmbtr = rs_asset-orig_cost wrbtr = rs_asset-orig_cost
      sgtxt = ls_header-bktxt ) TO ls_header-items.

    ls_gl_svc->post_journal( ls_header ).
  ENDMETHOD.

  METHOD update_asset.
    find_asset_by_id( iv_bukrs = iv_bukrs iv_anln1 = iv_anln1 iv_anln2 = iv_anln2 ).
    rs_asset = is_asset.
    UPDATE zfi_asset
      SET txt50      = @rs_asset-txt50,
          txt20      = @rs_asset-txt20,
          kostl      = @rs_asset-kostl,
          prctr      = @rs_asset-prctr,
          location   = @rs_asset-location,
          depr_key   = @rs_asset-depr_key,
          useful_life = @rs_asset-useful_life
      WHERE bukrs = @iv_bukrs AND anln1 = @iv_anln1 AND anln2 = @iv_anln2
        AND mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD transfer_asset.
    find_asset_by_id( iv_bukrs = iv_bukrs iv_anln1 = iv_anln1 iv_anln2 = iv_anln2 ).
    UPDATE zfi_asset
      SET kostl        = @iv_new_kostl,
          prctr        = @iv_new_prctr,
          asset_status = 'T'
      WHERE bukrs = @iv_bukrs AND anln1 = @iv_anln1 AND anln2 = @iv_anln2
        AND mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_dyn_call_error.
    ENDIF.
  ENDMETHOD.

  METHOD retire_asset.
    DATA(ls_asset) = find_asset_by_id(
      iv_bukrs = iv_bukrs iv_anln1 = iv_anln1 iv_anln2 = iv_anln2 ).

    " 제각 FI 전표: 차) 감가상각누계액 + 유형자산처분손실 / 대) 자산
    DATA ls_gl_svc TYPE REF TO zcl_fi_gl_service.
    CREATE OBJECT ls_gl_svc.
    DATA ls_header TYPE zcl_fi_gl_service=>ty_journal_header.
    ls_header-bukrs = iv_bukrs.
    ls_header-blart = 'SA'.
    ls_header-bldat = iv_retire_date.
    ls_header-budat = iv_retire_date.
    ls_header-waers = ls_asset-waers.
    ls_header-bktxt = |자산제각:{ iv_anln1 }|.

    " 차변: 감가상각 누계액
    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '001' saknr = '112000' shkzg = 'S'
      dmbtr = ls_asset-accum_depr wrbtr = ls_asset-accum_depr
      sgtxt = ls_header-bktxt ) TO ls_header-items.
    " 차변: 처분손실 (장부가 - 처분가)
    DATA lv_loss TYPE p LENGTH 15 DECIMALS 2.
    lv_loss = ls_asset-curr_book_val - iv_retire_val.
    IF lv_loss > 0.
      APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
        buzei = '002' saknr = '506500' shkzg = 'S'
        dmbtr = lv_loss wrbtr = lv_loss sgtxt = ls_header-bktxt ) TO ls_header-items.
    ENDIF.
    " 대변: 자산
    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '003' saknr = '111000' shkzg = 'H'
      dmbtr = ls_asset-orig_cost wrbtr = ls_asset-orig_cost
      sgtxt = ls_header-bktxt ) TO ls_header-items.

    ls_gl_svc->post_journal( ls_header ).

    UPDATE zfi_asset
      SET asset_status = 'D', deact_date = @iv_retire_date
      WHERE bukrs = @iv_bukrs AND anln1 = @iv_anln1 AND anln2 = @iv_anln2
        AND mandt = @sy-mandt.
  ENDMETHOD.

  METHOD simulate_depreciation.
    DATA(ls_asset) = find_asset_by_id(
      iv_bukrs = iv_bukrs iv_anln1 = iv_anln1 iv_anln2 = iv_anln2 ).

    DATA lv_monthly_depr TYPE p LENGTH 15 DECIMALS 2.
    lv_monthly_depr = calc_monthly_depr( ls_asset ).

    DATA lv_accum TYPE p LENGTH 15 DECIMALS 2.
    lv_accum = ls_asset-accum_depr.
    DATA lv_book  TYPE p LENGTH 15 DECIMALS 2.
    lv_book = ls_asset-curr_book_val.

    " 남은 내용연수(월) 계산
    DATA lv_gjahr  TYPE gjahr.
    DATA lv_period TYPE n LENGTH 2.
    lv_gjahr  = iv_from_gjahr.
    lv_period = iv_from_period.

    DO 60 TIMES.  " 최대 5년 시뮬레이션
      IF lv_book <= 0.
        EXIT.
      ENDIF.
      DATA lv_this_depr TYPE p LENGTH 15 DECIMALS 2.
      lv_this_depr = COND #( WHEN lv_book < lv_monthly_depr THEN lv_book
                             ELSE lv_monthly_depr ).
      lv_accum = lv_accum + lv_this_depr.
      lv_book  = lv_book - lv_this_depr.

      APPEND VALUE ty_depr_simulation(
        gjahr       = lv_gjahr
        period      = lv_period
        depr_amount = lv_this_depr
        accum_depr  = lv_accum
        book_value  = lv_book ) TO rt_simulation.

      lv_period = lv_period + 1.
      IF lv_period > 12.
        lv_period = 1.
        lv_gjahr  = lv_gjahr + 1.
      ENDIF.
    ENDDO.
  ENDMETHOD.

  METHOD post_depreciation_run.
    " 해당 기간에 아직 전기 안 된 활성 자산 조회
    SELECT bukrs anln1 anln2 asset_class txt50 txt20 kostl aufnr prctr
           invdate orig_cost curr_book_val accum_depr depr_key useful_life waers asset_status
      FROM zfi_asset
      WHERE bukrs = @iv_bukrs AND asset_status = 'A' AND curr_book_val > 0
      INTO CORRESPONDING FIELDS OF TABLE @DATA(lt_assets).

    LOOP AT lt_assets INTO DATA(ls_asset).
      " 이미 전기된 자산 skip
      SELECT COUNT(*) FROM zfi_asset_depr
        WHERE bukrs = @iv_bukrs AND anln1 = @ls_asset-anln1 AND anln2 = @ls_asset-anln2
          AND gjahr = @iv_gjahr AND depr_period = @iv_period AND depr_status = 'A'
        INTO @DATA(lv_cnt).
      IF lv_cnt > 0. CONTINUE. ENDIF.

      DATA lv_depr TYPE p LENGTH 15 DECIMALS 2.
      lv_depr = calc_monthly_depr( ls_asset ).
      IF lv_depr <= 0. CONTINUE. ENDIF.
      IF ls_asset-curr_book_val < lv_depr.
        lv_depr = ls_asset-curr_book_val.
      ENDIF.

      " FI 감가상각 전표 전기
      DATA lv_belnr TYPE belnr_d.
      TRY.
          lv_belnr = post_fi_depr_document(
            iv_bukrs    = iv_bukrs
            iv_anln1    = ls_asset-anln1
            iv_anln2    = ls_asset-anln2
            iv_depr_amt = lv_depr
            iv_kostl    = ls_asset-kostl
            iv_period   = iv_period
            iv_gjahr    = iv_gjahr ).
        CATCH cx_sy_dyn_call_error.
          CONTINUE.
      ENDTRY.

      " 감가상각 내역 INSERT
      DATA ls_depr_rec TYPE zfi_asset_depr.
      ls_depr_rec-mandt        = sy-mandt.
      ls_depr_rec-bukrs        = iv_bukrs.
      ls_depr_rec-anln1        = ls_asset-anln1.
      ls_depr_rec-anln2        = ls_asset-anln2.
      ls_depr_rec-gjahr        = iv_gjahr.
      ls_depr_rec-afabe        = '01'.
      ls_depr_rec-depr_period  = iv_period.
      ls_depr_rec-depr_amount  = lv_depr.
      ls_depr_rec-accum_depr   = ls_asset-accum_depr + lv_depr.
      ls_depr_rec-book_value   = ls_asset-curr_book_val - lv_depr.
      ls_depr_rec-depr_status  = 'A'.
      ls_depr_rec-posted_belnr = lv_belnr.
      ls_depr_rec-post_date    = sy-datum.
      INSERT zfi_asset_depr FROM ls_depr_rec.

      " 자산 장부가액 갱신
      UPDATE zfi_asset
        SET accum_depr     = ls_depr_rec-accum_depr,
            curr_book_val  = ls_depr_rec-book_value,
            curr_year_depr = curr_year_depr + @lv_depr
        WHERE bukrs = @iv_bukrs AND anln1 = @ls_asset-anln1 AND anln2 = @ls_asset-anln2
          AND mandt = @sy-mandt.

      rv_posted_cnt = rv_posted_cnt + 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD find_depr_history.
    SELECT bukrs anln1 anln2 gjahr afabe depr_period depr_amount accum_depr
           book_value depr_status posted_belnr post_date
      FROM zfi_asset_depr
      WHERE bukrs = @iv_bukrs AND anln1 = @iv_anln1 AND anln2 = @iv_anln2
        AND gjahr = @iv_gjahr
      INTO CORRESPONDING FIELDS OF TABLE @rt_history
      ORDER BY afabe depr_period.
  ENDMETHOD.

  METHOD get_asset_balance_by_class.
    SELECT asset_class
           SUM( orig_cost )     AS orig_cost
           SUM( accum_depr )    AS accum_depr
           SUM( curr_book_val ) AS curr_book_val
           COUNT(*)             AS asset_cnt
      FROM zfi_asset
      WHERE bukrs = @iv_bukrs AND asset_status = 'A'
      GROUP BY asset_class
      INTO TABLE @rt_result
      ORDER BY asset_class.
  ENDMETHOD.

  METHOD get_next_asset_no.
    SELECT MAX( anln1 ) FROM zfi_asset WHERE bukrs = @iv_bukrs INTO @rv_anln1.
    rv_anln1 = COND #( WHEN rv_anln1 IS NOT INITIAL THEN rv_anln1 + 1
                       ELSE '000000000001' ).
  ENDMETHOD.

  METHOD calc_monthly_depr.
    " 정액법: 취득원가 / (내용연수 * 12)
    " 정률법: 장부가액 * 상각률
    DATA lv_rate TYPE p LENGTH 10 DECIMALS 6.
    CASE is_asset-depr_key.
      WHEN 'DG10'. " 정액법 10년
        IF is_asset-useful_life > 0.
          lv_rate = 1 / ( is_asset-useful_life * 12 ).
        ELSE.
          lv_rate = 1 / 120.
        ENDIF.
        rv_depr_amt = is_asset-orig_cost * lv_rate.
      WHEN 'DG05'. " 정액법 5년
        rv_depr_amt = is_asset-orig_cost / 60.
      WHEN 'DG03'. " 정액법 3년
        rv_depr_amt = is_asset-orig_cost / 36.
      WHEN 'DB20'. " 정률법 20%
        rv_depr_amt = is_asset-curr_book_val * '0.2' / 12.
      WHEN OTHERS.
        rv_depr_amt = 0.
    ENDCASE.
    " 소수점 이하 절사 (원 단위)
    rv_depr_amt = CONV p( TRUNC( rv_depr_amt ) ).
  ENDMETHOD.

  METHOD post_fi_depr_document.
    " 감가상각 전표: 차) 감가상각비(506100) / 대) 감가상각누계액(112000)
    DATA ls_gl_svc TYPE REF TO zcl_fi_gl_service.
    CREATE OBJECT ls_gl_svc.
    DATA ls_header TYPE zcl_fi_gl_service=>ty_journal_header.
    ls_header-bukrs = iv_bukrs.
    ls_header-blart = 'AB'.
    ls_header-bldat = sy-datum.
    ls_header-budat = sy-datum.
    ls_header-waers = 'KRW'.
    ls_header-bktxt = |감가상각 { iv_gjahr }/{ iv_period }|.

    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '001' saknr = '506100' shkzg = 'S'
      dmbtr = iv_depr_amt wrbtr = iv_depr_amt
      kostl = iv_kostl anln1 = iv_anln1 anln2 = iv_anln2
      sgtxt = ls_header-bktxt ) TO ls_header-items.
    APPEND VALUE zcl_fi_gl_service=>ty_journal_item(
      buzei = '002' saknr = '112000' shkzg = 'H'
      dmbtr = iv_depr_amt wrbtr = iv_depr_amt
      anln1 = iv_anln1 anln2 = iv_anln2
      sgtxt = ls_header-bktxt ) TO ls_header-items.

    DATA(ls_posted) = ls_gl_svc->post_journal( ls_header ).
    rv_belnr = ls_posted-belnr.
  ENDMETHOD.

ENDCLASS.
