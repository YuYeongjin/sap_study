*&---------------------------------------------------------------------*
*& Program: ZINIT_CONSTRUCTION_DATA
*& Description: 건설관리 시스템 초기 샘플 데이터 생성
*&              (DataInitializer.java 동일 기능)
*& SE38 에서 작성 후 실행
*&
*& 주의: 이 프로그램을 실행하면 기존 데이터가 삭제되고 재생성됩니다.
*&---------------------------------------------------------------------*

REPORT zinit_construction_data.

START-OF-SELECTION.

  PERFORM delete_all_data.
  PERFORM init_projects.
  PERFORM init_materials.
  PERFORM init_equipment.
  PERFORM init_purchase_orders.
  PERFORM init_cost_entries.

  WRITE: / '✓ 샘플 데이터 초기화 완료'.
  WRITE: / '  - 프로젝트 4건'.
  WRITE: / '  - 자재 6건'.
  WRITE: / '  - 장비 5건'.
  WRITE: / '  - 구매발주 3건'.
  WRITE: / '  - 원가전표 5건'.

*&---------------------------------------------------------------------*
*& Form delete_all_data
*&---------------------------------------------------------------------*
FORM delete_all_data.
  DELETE FROM zconstruction_cost WHERE mandt = sy-mandt.
  DELETE FROM zconstruction_poi  WHERE mandt = sy-mandt.
  DELETE FROM zconstruction_po   WHERE mandt = sy-mandt.
  DELETE FROM zconstruction_equip WHERE mandt = sy-mandt.
  DELETE FROM zconstruction_matl  WHERE mandt = sy-mandt.
  DELETE FROM zconstruction_proj  WHERE mandt = sy-mandt.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form init_projects - 프로젝트 4건 생성
*&---------------------------------------------------------------------*
FORM init_projects.
  DATA lt_proj TYPE STANDARD TABLE OF zconstruction_proj.
  DATA ls_proj TYPE zconstruction_proj.

  ls_proj-mandt         = sy-mandt.
  ls_proj-waers         = 'KRW'.
  ls_proj-created_by    = 'SYSTEM'.
  GET TIME STAMP FIELD ls_proj-created_at.

  " 1. 서울 강남 주상복합 신축공사
  ls_proj-project_id    = '0000000001'.
  ls_proj-project_code  = 'PS-2024-001'.
  ls_proj-project_name  = '서울 강남 주상복합 신축공사'.
  ls_proj-location      = '서울특별시 강남구 테헤란로 100'.
  ls_proj-client        = '강남개발(주)'.
  ls_proj-project_type  = 'BUILDING'.
  ls_proj-status        = 'IN_PROGRESS'.
  ls_proj-contract_amt  = '85000000000'.    " 850억
  ls_proj-budget        = '80000000000'.    " 800억
  ls_proj-exec_budget   = '78000000000'.    " 780억
  ls_proj-actual_cost   = '0'.
  ls_proj-start_date    = '20240101'.
  ls_proj-plan_end_date = '20261231'.
  ls_proj-progress_rate = '52'.
  ls_proj-site_manager  = '김건설'.
  APPEND ls_proj TO lt_proj.

  " 2. 인천 제2경인고속도로 교량 공사
  ls_proj-project_id    = '0000000002'.
  ls_proj-project_code  = 'PS-2024-002'.
  ls_proj-project_name  = '인천 제2경인고속도로 교량 공사'.
  ls_proj-location      = '인천광역시 남동구 고속도로 구간'.
  ls_proj-client        = '한국도로공사'.
  ls_proj-project_type  = 'CIVIL'.
  ls_proj-status        = 'IN_PROGRESS'.
  ls_proj-contract_amt  = '120000000000'.   " 1200억
  ls_proj-budget        = '115000000000'.   " 1150억
  ls_proj-exec_budget   = '112000000000'.   " 1120억
  ls_proj-actual_cost   = '0'.
  ls_proj-start_date    = '20240301'.
  ls_proj-plan_end_date = '20271231'.
  ls_proj-progress_rate = '23'.
  ls_proj-site_manager  = '이토목'.
  APPEND ls_proj TO lt_proj.

  " 3. 여수 화학공장 플랜트 증설공사
  ls_proj-project_id    = '0000000003'.
  ls_proj-project_code  = 'PS-2023-015'.
  ls_proj-project_name  = '여수 화학공장 플랜트 증설공사'.
  ls_proj-location      = '전라남도 여수시 여수국가산업단지'.
  ls_proj-client        = '여수화학(주)'.
  ls_proj-project_type  = 'PLANT'.
  ls_proj-status        = 'COMPLETED'.
  ls_proj-contract_amt  = '45000000000'.    " 450억
  ls_proj-budget        = '43000000000'.    " 430억
  ls_proj-exec_budget   = '42000000000'.    " 420억
  ls_proj-actual_cost   = '0'.
  ls_proj-start_date    = '20230601'.
  ls_proj-plan_end_date = '20241231'.
  ls_proj-actual_end_date = '20241215'.
  ls_proj-progress_rate = '100'.
  ls_proj-site_manager  = '박플랜트'.
  APPEND ls_proj TO lt_proj.

  " 4. 부산 스마트시티 전기 인프라
  ls_proj-project_id    = '0000000004'.
  ls_proj-project_code  = 'PS-2025-001'.
  ls_proj-project_name  = '부산 스마트시티 전기 인프라'.
  ls_proj-location      = '부산광역시 강서구 에코델타시티'.
  ls_proj-client        = '부산시'.
  ls_proj-project_type  = 'ELECTRICAL'.
  ls_proj-status        = 'CONTRACTED'.
  ls_proj-contract_amt  = '32000000000'.    " 320억
  ls_proj-budget        = '30000000000'.    " 300억
  ls_proj-exec_budget   = '29500000000'.    " 295억
  ls_proj-actual_cost   = '0'.
  ls_proj-start_date    = '20250401'.
  ls_proj-plan_end_date = '20270331'.
  ls_proj-actual_end_date = '00000000'.
  ls_proj-progress_rate = '0'.
  ls_proj-site_manager  = '최전기'.
  APPEND ls_proj TO lt_proj.

  INSERT zconstruction_proj FROM TABLE lt_proj.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form init_materials - 자재 6건 생성
*&---------------------------------------------------------------------*
FORM init_materials.
  DATA lt_matl TYPE STANDARD TABLE OF zconstruction_matl.
  DATA ls_matl TYPE zconstruction_matl.

  ls_matl-mandt      = sy-mandt.
  ls_matl-waers      = 'KRW'.
  ls_matl-created_by = 'SYSTEM'.
  GET TIME STAMP FIELD ls_matl-created_at.

  " 1. 고강도 철근 HD25
  ls_matl-material_id    = '0000000001'.
  ls_matl-material_code  = 'MM-STL-001'.
  ls_matl-material_name  = '고강도 철근 HD25'.
  ls_matl-category       = 'STEEL'.
  ls_matl-specification  = 'HD25, SD500, KS D 3504'.
  ls_matl-unit           = 'T'.
  ls_matl-standard_price = '950000'.      " 95만원/T
  ls_matl-stock_qty      = '850'.
  ls_matl-safety_stock   = '200'.
  ls_matl-primary_vendor = '(주)현대제철'.
  ls_matl-lead_time_days = 7.
  APPEND ls_matl TO lt_matl.

  " 2. 레디믹스 콘크리트 25-24-150
  ls_matl-material_id    = '0000000002'.
  ls_matl-material_code  = 'MM-CON-001'.
  ls_matl-material_name  = '레디믹스 콘크리트 25-24-150'.
  ls_matl-category       = 'CONCRETE'.
  ls_matl-specification  = '설계기준강도 25MPa, 슬럼프 150mm'.
  ls_matl-unit           = 'M3'.
  ls_matl-standard_price = '85000'.       " 8.5만원/M3
  ls_matl-stock_qty      = '120'.
  ls_matl-safety_stock   = '500'.         " 안전재고 미달 상태 (low stock 테스트)
  ls_matl-primary_vendor = '(주)삼표레미콘'.
  ls_matl-lead_time_days = 1.
  APPEND ls_matl TO lt_matl.

  " 3. H형강 200x200
  ls_matl-material_id    = '0000000003'.
  ls_matl-material_code  = 'MM-STL-002'.
  ls_matl-material_name  = 'H형강 200x200'.
  ls_matl-category       = 'STEEL'.
  ls_matl-specification  = 'H-200x200x8x12, SS275'.
  ls_matl-unit           = 'T'.
  ls_matl-standard_price = '1100000'.     " 110만원/T
  ls_matl-stock_qty      = '45'.
  ls_matl-safety_stock   = '30'.
  ls_matl-primary_vendor = '(주)포스코'.
  ls_matl-lead_time_days = 14.
  APPEND ls_matl TO lt_matl.

  " 4. 안전망 2mx50m
  ls_matl-material_id    = '0000000004'.
  ls_matl-material_code  = 'MM-SAF-001'.
  ls_matl-material_name  = '안전망 2mx50m'.
  ls_matl-category       = 'SAFETY'.
  ls_matl-specification  = '낙하물 방지망, KCS 21 70 05'.
  ls_matl-unit           = 'EA'.
  ls_matl-standard_price = '45000'.       " 4.5만원/EA
  ls_matl-stock_qty      = '300'.
  ls_matl-safety_stock   = '100'.
  ls_matl-primary_vendor = '(주)안전산업'.
  ls_matl-lead_time_days = 3.
  APPEND ls_matl TO lt_matl.

  " 5. 합판 12T 1220x2440
  ls_matl-material_id    = '0000000005'.
  ls_matl-material_code  = 'MM-WOD-001'.
  ls_matl-material_name  = '합판 12T 1220x2440'.
  ls_matl-category       = 'WOOD'.
  ls_matl-specification  = '두께 12mm, 1220x2440mm, KS F 3110'.
  ls_matl-unit           = 'EA'.
  ls_matl-standard_price = '18000'.       " 1.8만원/EA
  ls_matl-stock_qty      = '25'.
  ls_matl-safety_stock   = '100'.         " 안전재고 미달 (low stock 테스트)
  ls_matl-primary_vendor = '(주)동화기업'.
  ls_matl-lead_time_days = 5.
  APPEND ls_matl TO lt_matl.

  " 6. 동관 3/4인치
  ls_matl-material_id    = '0000000006'.
  ls_matl-material_code  = 'MM-PIP-001'.
  ls_matl-material_name  = '동관 3/4인치 L타입'.
  ls_matl-category       = 'PIPING'.
  ls_matl-specification  = '3/4인치, L타입, KS D 5301'.
  ls_matl-unit           = 'M'.
  ls_matl-standard_price = '12000'.       " 1.2만원/M
  ls_matl-stock_qty      = '500'.
  ls_matl-safety_stock   = '200'.
  ls_matl-primary_vendor = '(주)LS전선'.
  ls_matl-lead_time_days = 10.
  APPEND ls_matl TO lt_matl.

  INSERT zconstruction_matl FROM TABLE lt_matl.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form init_equipment - 장비 5건 생성
*&---------------------------------------------------------------------*
FORM init_equipment.
  DATA lt_equip TYPE STANDARD TABLE OF zconstruction_equip.
  DATA ls_equip TYPE zconstruction_equip.

  ls_equip-mandt      = sy-mandt.
  ls_equip-waers      = 'KRW'.
  ls_equip-created_by = 'SYSTEM'.
  GET TIME STAMP FIELD ls_equip-created_at.

  " 1. 굴착기 21톤 (Volvo)
  ls_equip-equipment_id    = '0000000001'.
  ls_equip-equipment_code  = 'EQ-EXC-001'.
  ls_equip-equipment_name  = '굴착기 21톤'.
  ls_equip-equipment_type  = 'EXCAVATOR'.
  ls_equip-model           = 'EC220E'.
  ls_equip-manufacturer    = 'Volvo Construction Equipment'.
  ls_equip-registration_no = '경기 12가 3456'.
  ls_equip-status          = 'IN_USE'.
  ls_equip-current_project = '0000000001'.
  ls_equip-acquisition_date = '20220315'.
  ls_equip-acquisition_cost = '280000000'.   " 2.8억
  ls_equip-is_rented       = abap_false.
  ls_equip-rental_cost_day = '0'.
  ls_equip-next_maint_date = '20250630'.
  ls_equip-total_op_hours  = '3420'.
  APPEND ls_equip TO lt_equip.

  " 2. 타워크레인 50톤 (Liebherr, 임대)
  ls_equip-equipment_id    = '0000000002'.
  ls_equip-equipment_code  = 'EQ-CRN-001'.
  ls_equip-equipment_name  = '타워크레인 50톤'.
  ls_equip-equipment_type  = 'CRANE'.
  ls_equip-model           = 'LTM 1050-3.1'.
  ls_equip-manufacturer    = 'Liebherr'.
  ls_equip-registration_no = '임대-2024-001'.
  ls_equip-status          = 'IN_USE'.
  ls_equip-current_project = '0000000001'.
  ls_equip-acquisition_date = '20240101'.
  ls_equip-acquisition_cost = '0'.
  ls_equip-is_rented       = abap_true.
  ls_equip-rental_cost_day = '2500000'.      " 250만원/일
  ls_equip-next_maint_date = '20250301'.
  ls_equip-total_op_hours  = '890'.
  APPEND ls_equip TO lt_equip.

  " 3. 덤프트럭 15톤
  ls_equip-equipment_id    = '0000000003'.
  ls_equip-equipment_code  = 'EQ-DMP-001'.
  ls_equip-equipment_name  = '덤프트럭 15톤'.
  ls_equip-equipment_type  = 'DUMP_TRUCK'.
  ls_equip-model           = 'HD270'.
  ls_equip-manufacturer    = '현대자동차'.
  ls_equip-registration_no = '경기 55나 7890'.
  ls_equip-status          = 'IN_USE'.
  ls_equip-current_project = '0000000002'.
  ls_equip-acquisition_date = '20230801'.
  ls_equip-acquisition_cost = '120000000'.   " 1.2억
  ls_equip-is_rented       = abap_false.
  ls_equip-rental_cost_day = '0'.
  ls_equip-next_maint_date = '20250415'.
  ls_equip-total_op_hours  = '5620'.
  APPEND ls_equip TO lt_equip.

  " 4. 불도저 D6T
  ls_equip-equipment_id    = '0000000004'.
  ls_equip-equipment_code  = 'EQ-BLD-001'.
  ls_equip-equipment_name  = '불도저 D6T'.
  ls_equip-equipment_type  = 'BULLDOZER'.
  ls_equip-model           = 'D6T'.
  ls_equip-manufacturer    = 'Caterpillar'.
  ls_equip-registration_no = '충남 22나 1234'.
  ls_equip-status          = 'AVAILABLE'.
  ls_equip-current_project = '0000000000'.   " 미배정
  ls_equip-acquisition_date = '20210601'.
  ls_equip-acquisition_cost = '350000000'.   " 3.5억
  ls_equip-is_rented       = abap_false.
  ls_equip-rental_cost_day = '0'.
  ls_equip-next_maint_date = '20250515'.
  ls_equip-total_op_hours  = '8900'.
  APPEND ls_equip TO lt_equip.

  " 5. 콘크리트 펌프카 52M
  ls_equip-equipment_id    = '0000000005'.
  ls_equip-equipment_code  = 'EQ-CPM-001'.
  ls_equip-equipment_name  = '콘크리트 펌프카 52M붐'.
  ls_equip-equipment_type  = 'CONCRETE_PUMP'.
  ls_equip-model           = 'BSF52-5Z.16H'.
  ls_equip-manufacturer    = 'Putzmeister'.
  ls_equip-registration_no = '서울 33다 5678'.
  ls_equip-status          = 'MAINTENANCE'.
  ls_equip-current_project = '0000000000'.   " 점검중
  ls_equip-acquisition_date = '20220101'.
  ls_equip-acquisition_cost = '450000000'.   " 4.5억
  ls_equip-is_rented       = abap_false.
  ls_equip-rental_cost_day = '0'.
  ls_equip-next_maint_date = '20250201'.
  ls_equip-total_op_hours  = '4230'.
  APPEND ls_equip TO lt_equip.

  INSERT zconstruction_equip FROM TABLE lt_equip.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form init_purchase_orders - 발주 3건 생성
*&---------------------------------------------------------------------*
FORM init_purchase_orders.
  DATA lt_po  TYPE STANDARD TABLE OF zconstruction_po.
  DATA lt_poi TYPE STANDARD TABLE OF zconstruction_poi.
  DATA ls_po  TYPE zconstruction_po.
  DATA ls_poi TYPE zconstruction_poi.

  ls_po-mandt      = sy-mandt.
  ls_po-waers      = 'KRW'.
  ls_po-created_by = 'SYSTEM'.
  GET TIME STAMP FIELD ls_po-created_at.
  ls_poi-mandt = sy-mandt.
  ls_poi-waers = 'KRW'.

  " PO 1: 철근 구매 발주 (ORDERED)
  ls_po-po_id         = '0000000001'.
  ls_po-po_number     = 'PO-2024-0001'.
  ls_po-project_id    = '0000000001'.
  ls_po-vendor_name   = '현대제철(주)'.
  ls_po-vendor_code   = 'V-001'.
  ls_po-status        = 'ORDERED'.
  ls_po-order_date    = '20240120'.
  ls_po-delivery_date = '20240201'.
  ls_po-delivery_addr = '서울 강남구 테헤란로 100 현장'.
  ls_po-total_amount  = '523875000'.     " 합계
  ls_po-purchaser     = '구매팀 홍길동'.
  ls_po-remarks       = '1차 철근 구매'.
  APPEND ls_po TO lt_po.

  ls_poi-po_id         = '0000000001'.
  ls_poi-item_no       = '001'.
  ls_poi-material_id   = '0000000001'.
  ls_poi-item_desc     = '고강도 철근 HD25'.
  ls_poi-quantity      = '500'.
  ls_poi-unit          = 'T'.
  ls_poi-unit_price    = '950000'.
  ls_poi-supply_amount = '475000000'.
  ls_poi-vat_amount    = '47500000'.
  ls_poi-total_amount  = '522500000'.
  ls_poi-received_qty  = '500'.
  APPEND ls_poi TO lt_poi.

  ls_poi-item_no       = '002'.
  ls_poi-material_id   = '0000000003'.
  ls_poi-item_desc     = 'H형강 200x200'.
  ls_poi-quantity      = '0.5'.
  ls_poi-unit          = 'T'.
  ls_poi-unit_price    = '1100000'.
  ls_poi-supply_amount = '550000'.
  ls_poi-vat_amount    = '55000'.
  ls_poi-total_amount  = '605000'.
  ls_poi-received_qty  = '0'.
  APPEND ls_poi TO lt_poi.

  " PO 2: H형강 발주 (APPROVED)
  ls_po-po_id         = '0000000002'.
  ls_po-po_number     = 'PO-2024-0002'.
  ls_po-project_id    = '0000000001'.
  ls_po-vendor_name   = '(주)포스코'.
  ls_po-vendor_code   = 'V-002'.
  ls_po-status        = 'APPROVED'.
  ls_po-order_date    = '20240215'.
  ls_po-delivery_date = '20240301'.
  ls_po-delivery_addr = '서울 강남구 테헤란로 100 현장'.
  ls_po-total_amount  = '55000000'.
  ls_po-purchaser     = '구매팀 홍길동'.
  ls_po-remarks       = 'H형강 1차 발주'.
  APPEND ls_po TO lt_po.

  ls_poi-po_id         = '0000000002'.
  ls_poi-item_no       = '001'.
  ls_poi-material_id   = '0000000003'.
  ls_poi-item_desc     = 'H형강 200x200'.
  ls_poi-quantity      = '45'.
  ls_poi-unit          = 'T'.
  ls_poi-unit_price    = '1100000'.
  ls_poi-supply_amount = '49500000'.
  ls_poi-vat_amount    = '4950000'.
  ls_poi-total_amount  = '54450000'.
  ls_poi-received_qty  = '0'.
  APPEND ls_poi TO lt_poi.

  " PO 3: 레미콘 발주 (PARTIAL_RECEIVED)
  ls_po-po_id         = '0000000003'.
  ls_po-po_number     = 'PO-2024-0003'.
  ls_po-project_id    = '0000000002'.
  ls_po-vendor_name   = '(주)삼표레미콘'.
  ls_po-vendor_code   = 'V-003'.
  ls_po-status        = 'PARTIAL_RECEIVED'.
  ls_po-order_date    = '20240301'.
  ls_po-delivery_date = '20240315'.
  ls_po-delivery_addr = '인천 남동구 고속도로 2공구 현장'.
  ls_po-total_amount  = '9350000'.
  ls_po-purchaser     = '구매2팀 이구매'.
  ls_po-remarks       = '교량 기초 콘크리트 타설'.
  APPEND ls_po TO lt_po.

  ls_poi-po_id         = '0000000003'.
  ls_poi-item_no       = '001'.
  ls_poi-material_id   = '0000000002'.
  ls_poi-item_desc     = '레디믹스 콘크리트 25-24-150'.
  ls_poi-quantity      = '100'.
  ls_poi-unit          = 'M3'.
  ls_poi-unit_price    = '85000'.
  ls_poi-supply_amount = '8500000'.
  ls_poi-vat_amount    = '850000'.
  ls_poi-total_amount  = '9350000'.
  ls_poi-received_qty  = '60'.
  APPEND ls_poi TO lt_poi.

  INSERT zconstruction_po  FROM TABLE lt_po.
  INSERT zconstruction_poi FROM TABLE lt_poi.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form init_cost_entries - 원가전표 5건 생성
*&---------------------------------------------------------------------*
FORM init_cost_entries.
  DATA lt_cost TYPE STANDARD TABLE OF zconstruction_cost.
  DATA ls_cost TYPE zconstruction_cost.

  ls_cost-mandt      = sy-mandt.
  ls_cost-waers      = 'KRW'.
  ls_cost-created_by = 'SYSTEM'.
  GET TIME STAMP FIELD ls_cost-created_at.

  " 1. 노무비 - 프로젝트1
  ls_cost-cost_id      = '0000000001'.
  ls_cost-entry_number = 'CE-2024-001'.
  ls_cost-project_id   = '0000000001'.
  ls_cost-cost_type    = 'LABOR'.
  ls_cost-cost_account = '510100'.
  ls_cost-entry_date   = '20240131'.
  ls_cost-quantity     = '200'.
  ls_cost-unit         = 'H'.
  ls_cost-unit_price   = '75000'.
  ls_cost-amount       = '15000000'.    " 1500만원
  ls_cost-description  = '1월 형틀목수 노무비'.
  ls_cost-document_no  = 'DOC-2024-001'.
  APPEND ls_cost TO lt_cost.

  " 2. 재료비 - 프로젝트1
  ls_cost-cost_id      = '0000000002'.
  ls_cost-entry_number = 'CE-2024-002'.
  ls_cost-project_id   = '0000000001'.
  ls_cost-cost_type    = 'MATERIAL'.
  ls_cost-cost_account = '511000'.
  ls_cost-entry_date   = '20240201'.
  ls_cost-quantity     = '100'.
  ls_cost-unit         = 'T'.
  ls_cost-unit_price   = '950000'.
  ls_cost-amount       = '95000000'.    " 9500만원
  ls_cost-description  = '1차 철근 입고 원가'.
  ls_cost-document_no  = 'DOC-2024-002'.
  APPEND ls_cost TO lt_cost.

  " 3. 장비비 - 프로젝트1
  ls_cost-cost_id      = '0000000003'.
  ls_cost-entry_number = 'CE-2024-003'.
  ls_cost-project_id   = '0000000001'.
  ls_cost-cost_type    = 'EQUIPMENT_COST'.
  ls_cost-cost_account = '512000'.
  ls_cost-entry_date   = '20240131'.
  ls_cost-quantity     = '20'.
  ls_cost-unit         = 'DAY'.
  ls_cost-unit_price   = '2500000'.
  ls_cost-amount       = '50000000'.    " 5000만원
  ls_cost-description  = '1월 타워크레인 임대료'.
  ls_cost-document_no  = 'DOC-2024-003'.
  APPEND ls_cost TO lt_cost.

  " 4. 외주비 - 프로젝트2
  ls_cost-cost_id      = '0000000004'.
  ls_cost-entry_number = 'CE-2024-004'.
  ls_cost-project_id   = '0000000002'.
  ls_cost-cost_type    = 'SUBCONTRACT'.
  ls_cost-cost_account = '513000'.
  ls_cost-entry_date   = '20240228'.
  ls_cost-quantity     = '1'.
  ls_cost-unit         = 'LOT'.
  ls_cost-unit_price   = '80000000'.
  ls_cost-amount       = '80000000'.    " 8000만원
  ls_cost-description  = '교량 기초 파일 시공 외주'.
  ls_cost-document_no  = 'DOC-2024-004'.
  APPEND ls_cost TO lt_cost.

  " 5. 노무비 - 프로젝트2
  ls_cost-cost_id      = '0000000005'.
  ls_cost-entry_number = 'CE-2024-005'.
  ls_cost-project_id   = '0000000002'.
  ls_cost-cost_type    = 'LABOR'.
  ls_cost-cost_account = '510100'.
  ls_cost-entry_date   = '20240229'.
  ls_cost-quantity     = '350'.
  ls_cost-unit         = 'H'.
  ls_cost-unit_price   = '70000'.
  ls_cost-amount       = '24500000'.    " 2450만원
  ls_cost-description  = '2월 철근공 노무비'.
  ls_cost-document_no  = 'DOC-2024-005'.
  APPEND ls_cost TO lt_cost.

  INSERT zconstruction_cost FROM TABLE lt_cost.

  " 프로젝트 실적원가 갱신
  PERFORM update_actual_costs.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form update_actual_costs - 프로젝트별 실적원가 집계
*&---------------------------------------------------------------------*
FORM update_actual_costs.
  SELECT project_id SUM( amount ) AS total_amount
    FROM zconstruction_cost
    GROUP BY project_id
    INTO TABLE @DATA(lt_sums).

  LOOP AT lt_sums INTO DATA(ls_sum).
    UPDATE zconstruction_proj
      SET actual_cost = @ls_sum-total_amount
      WHERE project_id = @ls_sum-project_id
        AND mandt        = @sy-mandt.
  ENDLOOP.
ENDFORM.
