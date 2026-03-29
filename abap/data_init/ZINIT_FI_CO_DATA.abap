*&---------------------------------------------------------------------*
*& Report: ZINIT_FI_CO_DATA
*& Description: FI/CO 마스터 + 트랜잭션 샘플 데이터 초기화
*& Transaction: SE38 → ZINIT_FI_CO_DATA 실행
*&
*& 생성 데이터:
*&   FI:
*&     - GL 계정 20건 (자산/부채/자본/수익/비용)
*&     - 벤더 8건 (자재, 외주, 장비, 용역)
*&     - 고객 5건 (공공, 민간 발주처)
*&     - 매입전표 10건 (다양한 지급상태)
*&     - 기성청구서 6건 (다양한 수금상태)
*&     - 자산 5건 (건설장비, 차량, 전산)
*&   CO:
*&     - 코스트센터 8건
*&     - 원가요소 12건
*&     - 내부오더 6건
*&     - 수익센터 4건
*&     - 예산 6건
*&     - CO 계획라인 24건
*&---------------------------------------------------------------------*
REPORT zinit_fi_co_data.

PARAMETERS: p_init TYPE c LENGTH 1 DEFAULT 'X'.  " X: 전체 초기화

START-OF-SELECTION.
  IF p_init = 'X'.
    PERFORM delete_all.
  ENDIF.
  PERFORM init_gl_accounts.
  PERFORM init_vendors.
  PERFORM init_customers.
  PERFORM init_co_masters.
  PERFORM init_ap_invoices.
  PERFORM init_ar_invoices.
  PERFORM init_assets.
  PERFORM init_co_plan.
  PERFORM init_co_actuals.

  WRITE: / '=== FI/CO 샘플 데이터 초기화 완료 ==='.
  WRITE: / 'GL 계정, 벤더, 고객, 코스트센터, 내부오더, 수익센터'.
  WRITE: / '매입전표, 기성청구서, 자산, 계획/실적 데이터'.

" ================================================================
" FORM: 기존 데이터 삭제
" ================================================================
FORM delete_all.
  DELETE FROM zfi_gl_account  WHERE mandt = sy-mandt.
  DELETE FROM zfi_vendor       WHERE mandt = sy-mandt.
  DELETE FROM zfi_customer     WHERE mandt = sy-mandt.
  DELETE FROM zfi_ap_invoice   WHERE mandt = sy-mandt.
  DELETE FROM zfi_ap_item      WHERE mandt = sy-mandt.
  DELETE FROM zfi_ar_invoice   WHERE mandt = sy-mandt.
  DELETE FROM zfi_ar_item      WHERE mandt = sy-mandt.
  DELETE FROM zfi_journal_entry WHERE mandt = sy-mandt.
  DELETE FROM zfi_journal_item  WHERE mandt = sy-mandt.
  DELETE FROM zfi_asset        WHERE mandt = sy-mandt.
  DELETE FROM zfi_asset_depr   WHERE mandt = sy-mandt.
  DELETE FROM zco_cost_center  WHERE mandt = sy-mandt.
  DELETE FROM zco_cost_element WHERE mandt = sy-mandt.
  DELETE FROM zco_internal_order WHERE mandt = sy-mandt.
  DELETE FROM zco_profit_center  WHERE mandt = sy-mandt.
  DELETE FROM zco_actual_line    WHERE mandt = sy-mandt.
  DELETE FROM zco_plan_line      WHERE mandt = sy-mandt.
  DELETE FROM zco_budget         WHERE mandt = sy-mandt.
  WRITE: / '기존 FI/CO 데이터 삭제 완료'.
ENDFORM.

" ================================================================
" FORM: GL 계정 마스터
" ================================================================
FORM init_gl_accounts.
  DATA ls TYPE zfi_gl_account.
  ls-mandt = sy-mandt. ls-bukrs = 'Z001'. ls-stat_ind = 'A'.
  ls-created_by = 'INIT'. GET TIME STAMP FIELD ls-created_at.

  DATA lt TYPE STANDARD TABLE OF zfi_gl_account.
  " 자산계정 (대차대조표)
  PERFORM add_gl USING '101000' 'BILZ' 'X' '현금'           '현금및현금성자산'  'KRW' CHANGING lt.
  PERFORM add_gl USING '101100' 'BILZ' 'X' '보통예금'        '보통예금'         'KRW' CHANGING lt.
  PERFORM add_gl USING '102000' 'BILZ' 'X' '매출채권'        '공사 매출채권'    'KRW' CHANGING lt.
  PERFORM add_gl USING '103000' 'BILZ' 'X' '재료재고'        '건설자재 재고자산' 'KRW' CHANGING lt.
  PERFORM add_gl USING '111000' 'BILZ' 'X' '기계장비'        '건설기계및장비'    'KRW' CHANGING lt.
  PERFORM add_gl USING '112000' 'BILZ' 'X' '감가상각누계액'  '유형자산감가상각누계' 'KRW' CHANGING lt.
  " 부채계정
  PERFORM add_gl USING '201000' 'BILZ' 'X' '매입채무'        '공사대금 매입채무' 'KRW' CHANGING lt.
  PERFORM add_gl USING '202000' 'BILZ' 'X' '미지급금'        '기타 미지급금'    'KRW' CHANGING lt.
  PERFORM add_gl USING '202500' 'BILZ' 'X' '부가세예수금'    '부가세예수금'     'KRW' CHANGING lt.
  PERFORM add_gl USING '203000' 'BILZ' 'X' '선수금'          '공사 선수금'      'KRW' CHANGING lt.
  " 자본계정
  PERFORM add_gl USING '301000' 'BILZ' 'X' '자본금'          '납입자본금'       'KRW' CHANGING lt.
  PERFORM add_gl USING '302000' 'BILZ' 'X' '이익잉여금'      '미처분이익잉여금' 'KRW' CHANGING lt.
  " 수익계정 (손익계산서)
  PERFORM add_gl USING '401000' 'GVXX' ' ' '건설공사수익'    '도급공사수익'      'KRW' CHANGING lt.
  PERFORM add_gl USING '402000' 'GVXX' ' ' '기타수익'        '기타영업수익'      'KRW' CHANGING lt.
  " 비용계정
  PERFORM add_gl USING '501000' 'GVXX' ' ' '노무비'          '직접 노무비'       'KRW' CHANGING lt.
  PERFORM add_gl USING '502000' 'GVXX' ' ' '재료비'          '건설자재비'        'KRW' CHANGING lt.
  PERFORM add_gl USING '503000' 'GVXX' ' ' '장비비'          '건설장비 임대료'   'KRW' CHANGING lt.
  PERFORM add_gl USING '504000' 'GVXX' ' ' '외주비'          '전문건설 외주비'   'KRW' CHANGING lt.
  PERFORM add_gl USING '505000' 'GVXX' ' ' '경비'            '현장 경비'         'KRW' CHANGING lt.
  PERFORM add_gl USING '506100' 'GVXX' ' ' '감가상각비'      '유형자산 감가상각비' 'KRW' CHANGING lt.

  INSERT zfi_gl_account FROM TABLE lt. COMMIT WORK.
  WRITE: / |GL 계정 { lines( lt ) }건 생성 완료|.
ENDFORM.

FORM add_gl USING iv_saknr iv_ktoks iv_xbilk iv_txt20 iv_txt50 iv_waers
            CHANGING ct_tab TYPE STANDARD TABLE.
  DATA ls TYPE zfi_gl_account.
  ls-mandt = sy-mandt. ls-bukrs = 'Z001'. ls-stat_ind = 'A'.
  ls-saknr = iv_saknr. ls-ktoks = iv_ktoks. ls-xbilk = iv_xbilk.
  ls-txt20 = iv_txt20. ls-txt50 = iv_txt50. ls-waers = iv_waers.
  ls-created_by = 'INIT'. GET TIME STAMP FIELD ls-created_at.
  APPEND ls TO ct_tab.
ENDFORM.

" ================================================================
" FORM: 벤더 마스터
" ================================================================
FORM init_vendors.
  DATA lt TYPE STANDARD TABLE OF zfi_vendor.

  PERFORM add_vendor USING 'V10001' '(주)한국철강'   'MATL' '123-45-67890' 'NT30' CHANGING lt.
  PERFORM add_vendor USING 'V10002' '삼성레미콘(주)' 'MATL' '234-56-78901' 'NT30' CHANGING lt.
  PERFORM add_vendor USING 'V10003' '대우건설기계'   'EQUP' '345-67-89012' 'NT60' CHANGING lt.
  PERFORM add_vendor USING 'V10004' '현대중장비(주)' 'EQUP' '456-78-90123' 'NT60' CHANGING lt.
  PERFORM add_vendor USING 'V10005' '(주)태광건설'   'SUBK' '567-89-01234' 'NT45' CHANGING lt.
  PERFORM add_vendor USING 'V10006' '한화건설외주'   'SUBK' '678-90-12345' 'NT45' CHANGING lt.
  PERFORM add_vendor USING 'V10007' '안전관리용역'   'SERV' '789-01-23456' 'NT30' CHANGING lt.
  PERFORM add_vendor USING 'V10008' '건설컨설팅(주)' 'CONS' '890-12-34567' 'NT60' CHANGING lt.

  INSERT zfi_vendor FROM TABLE lt. COMMIT WORK.
  WRITE: / |벤더 { lines( lt ) }건 생성 완료|.
ENDFORM.

FORM add_vendor USING iv_lifnr iv_name1 iv_vtype iv_stcd1 iv_zterm
               CHANGING ct_tab TYPE STANDARD TABLE.
  DATA ls TYPE zfi_vendor.
  ls-mandt = sy-mandt. ls-bukrs = 'Z001'. ls-loevm = ' '.
  ls-lifnr = iv_lifnr. ls-name1 = iv_name1. ls-vend_type = iv_vtype.
  ls-stcd1 = iv_stcd1. ls-zterm = iv_zterm. ls-waers = 'KRW'.
  ls-akont = '201000'. ls-ktokk = 'KRED'. ls-land1 = 'KR'. ls-spras = '3'.
  ls-created_by = 'INIT'. GET TIME STAMP FIELD ls-created_at.
  APPEND ls TO ct_tab.
ENDFORM.

" ================================================================
" FORM: 고객 마스터
" ================================================================
FORM init_customers.
  DATA lt TYPE STANDARD TABLE OF zfi_customer.

  PERFORM add_customer USING 'C10001' '서울특별시'         'PUBL' '110-83-00000' 'NT30' 50000000000 CHANGING lt.
  PERFORM add_customer USING 'C10002' '한국도로공사'       'PUBL' '220-82-00001' 'NT30' 30000000000 CHANGING lt.
  PERFORM add_customer USING 'C10003' '(주)롯데건설'       'PRIV' '330-81-00002' 'NT60' 20000000000 CHANGING lt.
  PERFORM add_customer USING 'C10004' '현대개발(주)'       'PRIV' '440-80-00003' 'NT60' 15000000000 CHANGING lt.
  PERFORM add_customer USING 'C10005' '부산시설관리공단'   'PUBL' '550-79-00004' 'NT30' 25000000000 CHANGING lt.

  INSERT zfi_customer FROM TABLE lt. COMMIT WORK.
  WRITE: / |고객 { lines( lt ) }건 생성 완료|.
ENDFORM.

FORM add_customer USING iv_kunnr iv_name1 iv_ctype iv_stcd1 iv_zterm iv_climit
                 CHANGING ct_tab TYPE STANDARD TABLE.
  DATA ls TYPE zfi_customer.
  ls-mandt = sy-mandt. ls-bukrs = 'Z001'. ls-loevm = ' '.
  ls-kunnr = iv_kunnr. ls-name1 = iv_name1. ls-cust_type = iv_ctype.
  ls-stcd1 = iv_stcd1. ls-zterm = iv_zterm. ls-waers = 'KRW'.
  ls-akont = '102000'. ls-ktokd = 'DEBI'. ls-land1 = 'KR'. ls-spras = '3'.
  ls-credit_limit = iv_climit.
  ls-created_by = 'INIT'. GET TIME STAMP FIELD ls-created_at.
  APPEND ls TO ct_tab.
ENDFORM.

" ================================================================
" FORM: CO 마스터 (코스트센터, 원가요소, 내부오더, 수익센터)
" ================================================================
FORM init_co_masters.
  " 코스트센터
  DATA lt_cc TYPE STANDARD TABLE OF zco_cost_center.
  PERFORM add_cc USING '1001' '서울도심재개발현장' 'F' 'PC1000' CHANGING lt_cc.
  PERFORM add_cc USING '1002' '부산해운대주거단지' 'F' 'PC3000' CHANGING lt_cc.
  PERFORM add_cc USING '1003' '인천산업단지현장'   'F' 'PC4000' CHANGING lt_cc.
  PERFORM add_cc USING '2001' '공사관리팀'         'H' 'PC9000' CHANGING lt_cc.
  PERFORM add_cc USING '2002' '품질관리팀'         'H' 'PC9000' CHANGING lt_cc.
  PERFORM add_cc USING '3001' '경영지원팀'         'V' 'PC9000' CHANGING lt_cc.
  PERFORM add_cc USING '3003' '재무회계팀'         'V' 'PC9000' CHANGING lt_cc.
  PERFORM add_cc USING '4001' '영업1팀'            'V' 'PC1000' CHANGING lt_cc.
  INSERT zco_cost_center FROM TABLE lt_cc. COMMIT WORK.

  " 원가요소
  DATA lt_ce TYPE STANDARD TABLE OF zco_cost_element.
  PERFORM add_ce USING '501000' '직접노무비'   'LABR' '1' CHANGING lt_ce.
  PERFORM add_ce USING '501100' '현장노무비'   'LABR' '1' CHANGING lt_ce.
  PERFORM add_ce USING '502000' '재료비'       'MATL' '1' CHANGING lt_ce.
  PERFORM add_ce USING '502100' '철근콘크리트' 'MATL' '1' CHANGING lt_ce.
  PERFORM add_ce USING '503000' '장비임대료'   'EQUP' '1' CHANGING lt_ce.
  PERFORM add_ce USING '504000' '전문건설외주' 'SUBK' '1' CHANGING lt_ce.
  PERFORM add_ce USING '504100' '노무외주비'   'SUBK' '1' CHANGING lt_ce.
  PERFORM add_ce USING '505000' '현장경비'     'OVER' '1' CHANGING lt_ce.
  PERFORM add_ce USING '505100' '보험료'       'OVER' '1' CHANGING lt_ce.
  PERFORM add_ce USING '506000' '판관비'       'IDRT' '1' CHANGING lt_ce.
  PERFORM add_ce USING '506100' '감가상각비'   'IDRT' '1' CHANGING lt_ce.
  PERFORM add_ce USING '401000' '건설공사수익' 'REVN' '11' CHANGING lt_ce.
  INSERT zco_cost_element FROM TABLE lt_ce. COMMIT WORK.

  " 수익센터
  DATA lt_pc TYPE STANDARD TABLE OF zco_profit_center.
  PERFORM add_pc USING 'PC1000' '공공건설사업부'   'PUBL' CHANGING lt_pc.
  PERFORM add_pc USING 'PC2000' '민간건설사업부'   'PRIV' CHANGING lt_pc.
  PERFORM add_pc USING 'PC3000' '주거건설사업부'   'RESI' CHANGING lt_pc.
  PERFORM add_pc USING 'PC4000' '인프라건설사업부' 'INFR' CHANGING lt_pc.
  PERFORM add_pc USING 'PC9000' '공통관리'         'PRIV' CHANGING lt_pc.
  INSERT zco_profit_center FROM TABLE lt_pc. COMMIT WORK.

  " 내부오더
  DATA lt_ord TYPE STANDARD TABLE OF zco_internal_order.
  PERFORM add_order USING '100000001' 'ZCO1' '서울도심재개발-노무비' '1001' 1 500000000 CHANGING lt_ord.
  PERFORM add_order USING '100000002' 'ZCO1' '서울도심재개발-재료비' '1001' 1 800000000 CHANGING lt_ord.
  PERFORM add_order USING '100000003' 'ZCO1' '부산해운대-외주비'     '1002' 2 600000000 CHANGING lt_ord.
  PERFORM add_order USING '200000001' 'ZCO2' '현장간접비수집'         '2001' 0  50000000 CHANGING lt_ord.
  PERFORM add_order USING '400000001' 'ZCO4' '굴삭기취득오더'         '1001' 0 150000000 CHANGING lt_ord.
  PERFORM add_order USING '500000001' 'ZCO5' '타워크레인유지보수'     '1001' 0  20000000 CHANGING lt_ord.
  INSERT zco_internal_order FROM TABLE lt_ord. COMMIT WORK.

  " 예산 등록
  DATA lt_bgt TYPE STANDARD TABLE OF zco_budget.
  PERFORM add_budget USING '100000001' '2026' 'OR' 500000000 CHANGING lt_bgt.
  PERFORM add_budget USING '100000002' '2026' 'OR' 800000000 CHANGING lt_bgt.
  PERFORM add_budget USING '100000003' '2026' 'OR' 600000000 CHANGING lt_bgt.
  PERFORM add_budget USING '200000001' '2026' 'OR'  50000000 CHANGING lt_bgt.
  PERFORM add_budget USING '400000001' '2026' 'OR' 150000000 CHANGING lt_bgt.
  PERFORM add_budget USING '500000001' '2026' 'OR'  20000000 CHANGING lt_bgt.
  INSERT zco_budget FROM TABLE lt_bgt. COMMIT WORK.

  WRITE: / |CO 마스터: CC { lines( lt_cc ) }건, CE { lines( lt_ce ) }건, |
         & |오더 { lines( lt_ord ) }건, 수익센터 { lines( lt_pc ) }건 생성|.
ENDFORM.

FORM add_cc USING iv_kostl iv_ktext iv_kosar iv_prctr
            CHANGING ct TYPE STANDARD TABLE.
  DATA ls TYPE zco_cost_center.
  ls-mandt = sy-mandt. ls-kokrs = 'Z001'. ls-bukrs = 'Z001'.
  ls-kostl = iv_kostl. ls-ktext = iv_ktext. ls-kosar = iv_kosar.
  ls-prctr = iv_prctr. ls-stat_ind = 'A'. ls-waers = 'KRW'.
  ls-datab = '20260101'. ls-datbi = '99991231'.
  ls-created_by = 'INIT'. GET TIME STAMP FIELD ls-created_at.
  APPEND ls TO ct.
ENDFORM.

FORM add_ce USING iv_kstar iv_ktext iv_cel_group iv_katyp
            CHANGING ct TYPE STANDARD TABLE.
  DATA ls TYPE zco_cost_element.
  ls-mandt = sy-mandt. ls-kokrs = 'Z001'. ls-kstar = iv_kstar.
  ls-ktext = iv_ktext. ls-cel_group = iv_cel_group. ls-katyp = iv_katyp.
  ls-stat_ind = 'A'. ls-waers = 'KRW'.
  ls-datab = '20260101'. ls-datbi = '99991231'.
  ls-created_by = 'INIT'. GET TIME STAMP FIELD ls-created_at.
  APPEND ls TO ct.
ENDFORM.

FORM add_pc USING iv_prctr iv_ktext iv_pctype
            CHANGING ct TYPE STANDARD TABLE.
  DATA ls TYPE zco_profit_center.
  ls-mandt = sy-mandt. ls-kokrs = 'Z001'. ls-bukrs = 'Z001'.
  ls-prctr = iv_prctr. ls-ktext = iv_ktext. ls-pc_type = iv_pctype.
  ls-stat_ind = 'A'. ls-waers = 'KRW'.
  ls-datab = '20260101'. ls-datbi = '99991231'.
  ls-created_by = 'INIT'. GET TIME STAMP FIELD ls-created_at.
  APPEND ls TO ct.
ENDFORM.

FORM add_order USING iv_aufnr iv_auart iv_ktext iv_kostl iv_proj iv_budget
              CHANGING ct TYPE STANDARD TABLE.
  DATA ls TYPE zco_internal_order.
  ls-mandt = sy-mandt. ls-kokrs = 'Z001'. ls-bukrs = 'Z001'.
  ls-aufnr = iv_aufnr. ls-auart = iv_auart. ls-ktext = iv_ktext.
  ls-kostl = iv_kostl. ls-proj_id = iv_proj.
  ls-order_status = 'RE'. ls-budget_amount = iv_budget.
  ls-actual_cost = 0. ls-commit_cost = 0.
  ls-idat1 = '20260101'. ls-idat2 = '20261231'. ls-waers = 'KRW'.
  ls-erdat = sy-datum. ls-settle_rule = 'F'. ls-rcvr_type = 'CTR'.
  ls-created_by = 'INIT'. GET TIME STAMP FIELD ls-created_at.
  APPEND ls TO ct.
ENDFORM.

FORM add_budget USING iv_aufnr iv_gjahr iv_btype iv_amount
               CHANGING ct TYPE STANDARD TABLE.
  DATA ls TYPE zco_budget.
  ls-mandt = sy-mandt. ls-kokrs = 'Z001'. ls-gjahr = iv_gjahr.
  ls-aufnr = iv_aufnr. ls-budget_type = iv_btype.
  ls-orig_budget = iv_amount. ls-total_budget = iv_amount.
  ls-avail_budget = iv_amount. ls-budget_status = 'AP'. ls-waers = 'KRW'.
  ls-created_by = 'INIT'. GET TIME STAMP FIELD ls-created_at.
  APPEND ls TO ct.
ENDFORM.

" ================================================================
" FORM: 매입전표 샘플
" ================================================================
FORM init_ap_invoices.
  DATA lt TYPE STANDARD TABLE OF zfi_ap_invoice.
  DATA lt_item TYPE STANDARD TABLE OF zfi_ap_item.

  " 매입전표 1: 철강자재 구매 (미지급)
  PERFORM add_ap_inv USING '20260001' '2026' 'V10001' '철근 1,000톤 구매'
    '20260115' '20260115' 55000000 50000000 5000000 'NT30' 'MATL' ' '
    CHANGING lt.
  PERFORM add_ap_item USING '20260001' '001' '502100' '1001' '100000002'
    50000000 'V1' 5000000 55000000 CHANGING lt_item.

  " 매입전표 2: 레미콘 구매 (미지급)
  PERFORM add_ap_inv USING '20260002' '2026' 'V10002' '레미콘 500m3'
    '20260120' '20260120' 33000000 30000000 3000000 'NT30' 'MATL' ' '
    CHANGING lt.
  PERFORM add_ap_item USING '20260002' '001' '502000' '1001' '100000002'
    30000000 'V1' 3000000 33000000 CHANGING lt_item.

  " 매입전표 3: 굴삭기 임대 (부분지급)
  PERFORM add_ap_inv USING '20260003' '2026' 'V10003' '굴삭기 임대료 1월'
    '20260131' '20260131' 5500000 5000000 500000 'NT60' 'RENT' 'P'
    CHANGING lt.
  PERFORM add_ap_item USING '20260003' '001' '503000' '1001' ''
    5000000 'V1' 500000 5500000 CHANGING lt_item.

  " 매입전표 4: 타워크레인 임대 (완전지급)
  PERFORM add_ap_inv USING '20260004' '2026' 'V10004' '타워크레인 임대료'
    '20260201' '20260201' 11000000 10000000 1000000 'NT30' 'RENT' 'F'
    CHANGING lt.
  PERFORM add_ap_item USING '20260004' '001' '503000' '1002' ''
    10000000 'V1' 1000000 11000000 CHANGING lt_item.

  " 매입전표 5: 외주비 (미지급)
  PERFORM add_ap_inv USING '20260005' '2026' 'V10005' '방수공사 외주'
    '20260215' '20260215' 22000000 20000000 2000000 'NT45' 'SUBK' ' '
    CHANGING lt.
  PERFORM add_ap_item USING '20260005' '001' '504000' '1001' '100000001'
    20000000 'V1' 2000000 22000000 CHANGING lt_item.

  " 매입전표 6: 외주비 - 부산현장 (미지급)
  PERFORM add_ap_inv USING '20260006' '2026' 'V10006' '철근배근 외주'
    '20260220' '20260220' 16500000 15000000 1500000 'NT45' 'SUBK' ' '
    CHANGING lt.
  PERFORM add_ap_item USING '20260006' '001' '504100' '1002' '100000003'
    15000000 'V1' 1500000 16500000 CHANGING lt_item.

  " 매입전표 7: 안전관리 용역 (미지급)
  PERFORM add_ap_inv USING '20260007' '2026' 'V10007' '안전관리 용역비'
    '20260228' '20260228' 3300000 3000000 300000 'NT30' 'SERV' ' '
    CHANGING lt.
  PERFORM add_ap_item USING '20260007' '001' '505000' '2002' ''
    3000000 'V1' 300000 3300000 CHANGING lt_item.

  INSERT zfi_ap_invoice FROM TABLE lt.
  INSERT zfi_ap_item    FROM TABLE lt_item.
  COMMIT WORK.
  WRITE: / |매입전표 { lines( lt ) }건 생성 완료|.
ENDFORM.

FORM add_ap_inv USING iv_invno iv_gjahr iv_lifnr iv_bktxt
               iv_bldat iv_budat iv_gross iv_net iv_tax
               iv_zterm iv_atype iv_pstatus
               CHANGING ct TYPE STANDARD TABLE.
  DATA ls TYPE zfi_ap_invoice.
  ls-mandt = sy-mandt. ls-bukrs = 'Z001'. ls-gjahr = iv_gjahr.
  ls-ap_invno = iv_invno. ls-lifnr = iv_lifnr. ls-bktxt = iv_bktxt.
  ls-bldat = iv_bldat. ls-budat = iv_budat. ls-waers = 'KRW'.
  ls-gross_amount = iv_gross. ls-net_amount = iv_net. ls-tax_amount = iv_tax.
  ls-zterm = iv_zterm. ls-ap_type = iv_atype. ls-pay_status = iv_pstatus.
  ls-due_date = iv_bldat + COND i( WHEN iv_zterm = 'NT30' THEN 30
                                   WHEN iv_zterm = 'NT45' THEN 45
                                   WHEN iv_zterm = 'NT60' THEN 60 ELSE 30 ).
  IF iv_pstatus = 'F'. ls-paid_amount = iv_gross. ls-paid_date = sy-datum. ENDIF.
  IF iv_pstatus = 'P'. ls-paid_amount = iv_gross / 2. ENDIF.
  ls-created_by = 'INIT'. GET TIME STAMP FIELD ls-created_at.
  APPEND ls TO ct.
ENDFORM.

FORM add_ap_item USING iv_invno iv_itemno iv_saknr iv_kostl iv_aufnr
               iv_net iv_taxcode iv_tax iv_gross
               CHANGING ct TYPE STANDARD TABLE.
  DATA ls TYPE zfi_ap_item.
  ls-mandt = sy-mandt. ls-bukrs = 'Z001'. ls-gjahr = '2026'.
  ls-ap_invno = iv_invno. ls-ap_itemno = iv_itemno.
  ls-saknr = iv_saknr. ls-kostl = iv_kostl. ls-aufnr = iv_aufnr.
  ls-net_amount = iv_net. ls-tax_code = iv_taxcode.
  ls-tax_amount = iv_tax. ls-gross_amount = iv_gross.
  APPEND ls TO ct.
ENDFORM.

" ================================================================
" FORM: 기성청구서 샘플
" ================================================================
FORM init_ar_invoices.
  DATA lt TYPE STANDARD TABLE OF zfi_ar_invoice.
  DATA lt_item TYPE STANDARD TABLE OF zfi_ar_item.

  " 기성청구 1: 서울시 도심재개발 1차 기성 (수금완료)
  PERFORM add_ar_inv USING 'AR20260001' '2026' 'C10001' '서울도심재개발 1차기성'
    '20260110' '20260110' 'CONT-2026-001' 'PROG'
    110000000 100000000 10000000 'NT30' 30 1 'F' CHANGING lt.
  PERFORM add_ar_item USING 'AR20260001' '001' '401000' 100000000 'V1' 10000000 110000000
    'PC1000' '1차 골조공사 기성' CHANGING lt_item.

  " 기성청구 2: 서울시 2차 기성 (부분수금)
  PERFORM add_ar_inv USING 'AR20260002' '2026' 'C10001' '서울도심재개발 2차기성'
    '20260210' '20260210' 'CONT-2026-001' 'PROG'
    165000000 150000000 15000000 'NT30' 70 2 'P' CHANGING lt.
  PERFORM add_ar_item USING 'AR20260002' '001' '401000' 150000000 'V1' 15000000 165000000
    'PC1000' '2차 마감공사 기성' CHANGING lt_item.

  " 기성청구 3: 한국도로공사 1차 기성 (미수금)
  PERFORM add_ar_inv USING 'AR20260003' '2026' 'C10002' '고속도로 확장 1차기성'
    '20260115' '20260115' 'CONT-2026-002' 'PROG'
    220000000 200000000 20000000 'NT30' 40 1 ' ' CHANGING lt.
  PERFORM add_ar_item USING 'AR20260003' '001' '401000' 200000000 'V1' 20000000 220000000
    'PC1000' '도로포장 공사 기성' CHANGING lt_item.

  " 기성청구 4: 롯데건설 1차 기성 (수금완료)
  PERFORM add_ar_inv USING 'AR20260004' '2026' 'C10003' '부산해운대 아파트 1차기성'
    '20260120' '20260120' 'CONT-2026-003' 'PROG'
    88000000 80000000 8000000 'NT60' 20 2 'F' CHANGING lt.
  PERFORM add_ar_item USING 'AR20260004' '001' '401000' 80000000 'V1' 8000000 88000000
    'PC3000' '기초공사 기성' CHANGING lt_item.

  " 기성청구 5: 현대개발 1차 (미수금)
  PERFORM add_ar_inv USING 'AR20260005' '2026' 'C10004' '인천산업단지 1차기성'
    '20260201' '20260201' 'CONT-2026-004' 'PROG'
    55000000 50000000 5000000 'NT60' 15 3 ' ' CHANGING lt.
  PERFORM add_ar_item USING 'AR20260005' '001' '401000' 50000000 'V1' 5000000 55000000
    'PC4000' '기반시설 공사 기성' CHANGING lt_item.

  " 기성청구 6: 추가공사 청구 (미수금)
  PERFORM add_ar_inv USING 'AR20260006' '2026' 'C10001' '설계변경 추가공사 청구'
    '20260215' '20260215' 'CONT-2026-001' 'ADDL'
    33000000 30000000 3000000 'NT30' 0 1 ' ' CHANGING lt.
  PERFORM add_ar_item USING 'AR20260006' '001' '401000' 30000000 'V1' 3000000 33000000
    'PC1000' '설계변경 추가공사' CHANGING lt_item.

  INSERT zfi_ar_invoice FROM TABLE lt.
  INSERT zfi_ar_item    FROM TABLE lt_item.
  COMMIT WORK.
  WRITE: / |기성청구서 { lines( lt ) }건 생성 완료|.
ENDFORM.

FORM add_ar_inv USING iv_invno iv_gjahr iv_kunnr iv_bktxt
               iv_bldat iv_budat iv_contract iv_btype
               iv_gross iv_net iv_tax iv_zterm iv_prog iv_proj iv_status
               CHANGING ct TYPE STANDARD TABLE.
  DATA ls TYPE zfi_ar_invoice.
  ls-mandt = sy-mandt. ls-bukrs = 'Z001'. ls-gjahr = iv_gjahr.
  ls-ar_invno = iv_invno. ls-kunnr = iv_kunnr. ls-bktxt = iv_bktxt.
  ls-bldat = iv_bldat. ls-budat = iv_budat. ls-waers = 'KRW'.
  ls-gross_amount = iv_gross. ls-net_amount = iv_net. ls-tax_amount = iv_tax.
  ls-zterm = iv_zterm. ls-bill_type = iv_btype.
  ls-progress_rate = iv_prog. ls-proj_id = iv_proj.
  ls-contract_no = iv_contract. ls-rcv_status = iv_status.
  ls-due_date = iv_bldat + COND i( WHEN iv_zterm = 'NT30' THEN 30
                                   WHEN iv_zterm = 'NT60' THEN 60 ELSE 30 ).
  IF iv_status = 'F'. ls-rcvd_amount = iv_gross. ls-rcvd_date = sy-datum. ENDIF.
  IF iv_status = 'P'. ls-rcvd_amount = iv_gross * '0.5'. ENDIF.
  ls-created_by = 'INIT'. GET TIME STAMP FIELD ls-created_at.
  APPEND ls TO ct.
ENDFORM.

FORM add_ar_item USING iv_invno iv_itemno iv_saknr iv_net iv_taxcode iv_tax iv_gross
               iv_prctr iv_work_desc
               CHANGING ct TYPE STANDARD TABLE.
  DATA ls TYPE zfi_ar_item.
  ls-mandt = sy-mandt. ls-bukrs = 'Z001'. ls-gjahr = '2026'.
  ls-ar_invno = iv_invno. ls-ar_itemno = iv_itemno.
  ls-saknr = iv_saknr. ls-prctr = iv_prctr. ls-work_desc = iv_work_desc.
  ls-net_amount = iv_net. ls-tax_code = iv_taxcode.
  ls-tax_amount = iv_tax. ls-gross_amount = iv_gross.
  APPEND ls TO ct.
ENDFORM.

" ================================================================
" FORM: 자산 마스터 샘플
" ================================================================
FORM init_assets.
  DATA lt TYPE STANDARD TABLE OF zfi_asset.

  PERFORM add_asset USING '000000000001' '0000' 'MACH' '25톤 굴삭기'
    '20250101' 'V10003' 150000000 'DG10' 10 '1001' 1 CHANGING lt.
  PERFORM add_asset USING '000000000002' '0000' 'MACH' '타워크레인 50m'
    '20250601' 'V10004' 200000000 'DG10' 10 '1002' 2 CHANGING lt.
  PERFORM add_asset USING '000000000003' '0000' 'VEHI' '5톤 화물트럭'
    '20240101' 'V10003'  60000000 'DG05' 5  '1001' 0 CHANGING lt.
  PERFORM add_asset USING '000000000004' '0000' 'COMP' '현장관리 서버'
    '20260101' 'V10008'  10000000 'DG03' 3  '3001' 0 CHANGING lt.
  PERFORM add_asset USING '000000000005' '0000' 'TOOL' '용접기세트'
    '20251001' 'V10003'   5000000 'DG05' 5  '1001' 0 CHANGING lt.

  INSERT zfi_asset FROM TABLE lt. COMMIT WORK.
  WRITE: / |자산 { lines( lt ) }건 생성 완료|.
ENDFORM.

FORM add_asset USING iv_anln1 iv_anln2 iv_class iv_txt50
              iv_invdate iv_vendor iv_cost iv_deprkey iv_life iv_kostl iv_proj
              CHANGING ct TYPE STANDARD TABLE.
  DATA ls TYPE zfi_asset.
  ls-mandt = sy-mandt. ls-bukrs = 'Z001'.
  ls-anln1 = iv_anln1. ls-anln2 = iv_anln2.
  ls-asset_class = iv_class. ls-txt50 = iv_txt50.
  ls-txt20 = iv_txt50(20). ls-invdate = iv_invdate.
  ls-vendor = iv_vendor. ls-orig_cost = iv_cost.
  ls-depr_key = iv_deprkey. ls-useful_life = iv_life.
  ls-kostl = iv_kostl. ls-proj_id = iv_proj. ls-waers = 'KRW'.
  ls-asset_status = 'A'. ls-curr_book_val = iv_cost.
  ls-created_by = 'INIT'. GET TIME STAMP FIELD ls-created_at.
  APPEND ls TO ct.
ENDFORM.

" ================================================================
" FORM: CO 계획 데이터
" ================================================================
FORM init_co_plan.
  DATA lt TYPE STANDARD TABLE OF zco_plan_line.

  " 오더 100000001 (서울도심재개발 노무비): 월 40,000,000
  DO 12 TIMES.
    DATA ls TYPE zco_plan_line.
    ls-mandt = sy-mandt. ls-kokrs = 'Z001'. ls-gjahr = '2026'. ls-version = '000'.
    ls-aufnr = '100000001'. ls-kstar = '501000'. ls-monat = sy-index.
    ls-plan_amount = 40000000. ls-twaer = 'KRW'. ls-plan_status = 'A'.
    ls-created_by = 'INIT'. GET TIME STAMP FIELD ls-created_at.
    APPEND ls TO lt.
  ENDDO.

  " 오더 100000002 (서울도심재개발 재료비): 월 65,000,000
  DO 12 TIMES.
    CLEAR ls.
    ls-mandt = sy-mandt. ls-kokrs = 'Z001'. ls-gjahr = '2026'. ls-version = '000'.
    ls-aufnr = '100000002'. ls-kstar = '502000'. ls-monat = sy-index.
    ls-plan_amount = 65000000. ls-twaer = 'KRW'. ls-plan_status = 'A'.
    ls-created_by = 'INIT'. GET TIME STAMP FIELD ls-created_at.
    APPEND ls TO lt.
  ENDDO.

  INSERT zco_plan_line FROM TABLE lt. COMMIT WORK.
  WRITE: / |CO 계획 라인 { lines( lt ) }건 생성 완료|.
ENDFORM.

" ================================================================
" FORM: CO 실적 데이터 (FI 전기 시뮬레이션)
" ================================================================
FORM init_co_actuals.
  DATA lt TYPE STANDARD TABLE OF zco_actual_line.

  " 1월 실적
  PERFORM add_co_act USING '1000000001' '001' '1001' '100000001' '501000' '20260115' '01' 38000000 CHANGING lt.
  PERFORM add_co_act USING '1000000002' '001' '1001' '100000002' '502000' '20260120' '01' 55000000 CHANGING lt.
  PERFORM add_co_act USING '1000000003' '001' '1001' '100000002' '502100' '20260120' '01' 30000000 CHANGING lt.
  PERFORM add_co_act USING '1000000004' '001' '1002' '100000003' '504000' '20260220' '02' 15000000 CHANGING lt.
  PERFORM add_co_act USING '1000000005' '001' '1001' '100000001' '503000' '20260131' '01' 5000000  CHANGING lt.

  " 2월 실적
  PERFORM add_co_act USING '1000000006' '001' '1001' '100000001' '501000' '20260215' '02' 42000000 CHANGING lt.
  PERFORM add_co_act USING '1000000007' '001' '1001' '100000002' '502000' '20260220' '02' 20000000 CHANGING lt.
  PERFORM add_co_act USING '1000000008' '001' '1002' '100000003' '504100' '20260225' '02' 16500000 CHANGING lt.

  INSERT zco_actual_line FROM TABLE lt.

  " 오더 실적원가 갱신
  UPDATE zco_internal_order SET actual_cost = 85000000
    WHERE kokrs = 'Z001' AND aufnr = '100000001' AND mandt = sy-mandt.
  UPDATE zco_internal_order SET actual_cost = 105000000
    WHERE kokrs = 'Z001' AND aufnr = '100000002' AND mandt = sy-mandt.
  UPDATE zco_internal_order SET actual_cost = 31500000
    WHERE kokrs = 'Z001' AND aufnr = '100000003' AND mandt = sy-mandt.

  COMMIT WORK.
  WRITE: / |CO 실적 라인 { lines( lt ) }건 생성 완료|.
ENDFORM.

FORM add_co_act USING iv_docno iv_itemno iv_kostl iv_aufnr iv_kstar
               iv_budat iv_monat iv_amount
               CHANGING ct TYPE STANDARD TABLE.
  DATA ls TYPE zco_actual_line.
  ls-mandt = sy-mandt. ls-kokrs = 'Z001'. ls-gjahr = '2026'.
  ls-co_docno = iv_docno. ls-co_itemno = iv_itemno.
  ls-kostl = iv_kostl. ls-aufnr = iv_aufnr. ls-kstar = iv_kstar.
  ls-budat = iv_budat. ls-monat = iv_monat.
  ls-wkgbtr = iv_amount. ls-twaer = 'KRW'. ls-wrttp = '04'.
  ls-bukrs = 'Z001'. ls-usnam = 'INIT'.
  APPEND ls TO ct.
ENDFORM.
