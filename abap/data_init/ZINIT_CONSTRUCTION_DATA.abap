*&---------------------------------------------------------------------*
*& Program: ZINIT_CONSTRUCTION_DATA
*& Description: 건설관리 시스템 초기 샘플 데이터 생성
*& SE38 에서 실행 (기존 데이터 삭제 후 재생성)
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
  WRITE: / '  - 프로젝트 10건'.
  WRITE: / '  - 자재    15건'.
  WRITE: / '  - 장비    10건'.
  WRITE: / '  - 구매발주  8건'.
  WRITE: / '  - 원가전표 20건'.

*&---------------------------------------------------------------------*
FORM delete_all_data.
  DELETE FROM zconstruction_cost  WHERE mandt = sy-mandt.
  DELETE FROM zconstruction_poi   WHERE mandt = sy-mandt.
  DELETE FROM zconstruction_po    WHERE mandt = sy-mandt.
  DELETE FROM zconstruction_equip WHERE mandt = sy-mandt.
  DELETE FROM zconstruction_matl  WHERE mandt = sy-mandt.
  DELETE FROM zconstruction_proj  WHERE mandt = sy-mandt.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form init_projects - 10건
*&---------------------------------------------------------------------*
FORM init_projects.
  DATA lt TYPE STANDARD TABLE OF zconstruction_proj.
  DATA ls TYPE zconstruction_proj.

  ls-mandt      = sy-mandt.
  ls-waers      = 'KRW'.
  ls-created_by = 'SYSTEM'.
  GET TIME STAMP FIELD ls-created_at.

  " 1
  ls-project_id = '0000000001'. ls-project_code = 'PS-2024-001'.
  ls-project_name = '서울 강남 주상복합 신축공사'. ls-location = '서울 강남구 테헤란로 100'.
  ls-client = '강남개발(주)'. ls-project_type = 'BUILDING'. ls-status = 'IN_PROGRESS'.
  ls-contract_amt = '85000000000'. ls-budget = '80000000000'. ls-exec_budget = '78000000000'. ls-actual_cost = '0'.
  ls-start_date = '20240101'. ls-plan_end_date = '20261231'. ls-actual_end_date = '00000000'.
  ls-progress_rate = '52'. ls-site_manager = '김건설'.
  APPEND ls TO lt.

  " 2
  ls-project_id = '0000000002'. ls-project_code = 'PS-2024-002'.
  ls-project_name = '인천 제2경인고속도로 교량 공사'. ls-location = '인천 남동구 고속도로 구간'.
  ls-client = '한국도로공사'. ls-project_type = 'CIVIL'. ls-status = 'IN_PROGRESS'.
  ls-contract_amt = '120000000000'. ls-budget = '115000000000'. ls-exec_budget = '112000000000'. ls-actual_cost = '0'.
  ls-start_date = '20240301'. ls-plan_end_date = '20271231'. ls-actual_end_date = '00000000'.
  ls-progress_rate = '23'. ls-site_manager = '이토목'.
  APPEND ls TO lt.

  " 3
  ls-project_id = '0000000003'. ls-project_code = 'PS-2023-015'.
  ls-project_name = '여수 화학공장 플랜트 증설공사'. ls-location = '전남 여수 국가산업단지'.
  ls-client = '여수화학(주)'. ls-project_type = 'PLANT'. ls-status = 'COMPLETED'.
  ls-contract_amt = '45000000000'. ls-budget = '43000000000'. ls-exec_budget = '42000000000'. ls-actual_cost = '0'.
  ls-start_date = '20230601'. ls-plan_end_date = '20241231'. ls-actual_end_date = '20241215'.
  ls-progress_rate = '100'. ls-site_manager = '박플랜트'.
  APPEND ls TO lt.

  " 4
  ls-project_id = '0000000004'. ls-project_code = 'PS-2025-001'.
  ls-project_name = '부산 스마트시티 전기 인프라'. ls-location = '부산 강서구 에코델타시티'.
  ls-client = '부산광역시'. ls-project_type = 'ELECTRICAL'. ls-status = 'CONTRACTED'.
  ls-contract_amt = '32000000000'. ls-budget = '30000000000'. ls-exec_budget = '29500000000'. ls-actual_cost = '0'.
  ls-start_date = '20250401'. ls-plan_end_date = '20270331'. ls-actual_end_date = '00000000'.
  ls-progress_rate = '0'. ls-site_manager = '최전기'.
  APPEND ls TO lt.

  " 5
  ls-project_id = '0000000005'. ls-project_code = 'PS-2024-003'.
  ls-project_name = '대전 도심 재개발 토목공사'. ls-location = '대전 중구 은행동 일원'.
  ls-client = '대전도시공사'. ls-project_type = 'CIVIL'. ls-status = 'IN_PROGRESS'.
  ls-contract_amt = '68000000000'. ls-budget = '65000000000'. ls-exec_budget = '63000000000'. ls-actual_cost = '0'.
  ls-start_date = '20240601'. ls-plan_end_date = '20270531'. ls-actual_end_date = '00000000'.
  ls-progress_rate = '18'. ls-site_manager = '정도시'.
  APPEND ls TO lt.

  " 6
  ls-project_id = '0000000006'. ls-project_code = 'PS-2025-002'.
  ls-project_name = '광주 수소연료전지 플랜트'. ls-location = '광주 광산구 하남산단'.
  ls-client = '한국에너지공사'. ls-project_type = 'PLANT'. ls-status = 'PLANNING'.
  ls-contract_amt = '55000000000'. ls-budget = '52000000000'. ls-exec_budget = '50000000000'. ls-actual_cost = '0'.
  ls-start_date = '20251001'. ls-plan_end_date = '20280930'. ls-actual_end_date = '00000000'.
  ls-progress_rate = '0'. ls-site_manager = '한에너지'.
  APPEND ls TO lt.

  " 7
  ls-project_id = '0000000007'. ls-project_code = 'PS-2023-020'.
  ls-project_name = '제주 풍력발전 기계설비 공사'. ls-location = '제주 한림읍 해안도로'.
  ls-client = '제주에너지(주)'. ls-project_type = 'MECHANICAL'. ls-status = 'COMPLETED'.
  ls-contract_amt = '28000000000'. ls-budget = '26500000000'. ls-exec_budget = '25800000000'. ls-actual_cost = '0'.
  ls-start_date = '20230101'. ls-plan_end_date = '20241001'. ls-actual_end_date = '20240920'.
  ls-progress_rate = '100'. ls-site_manager = '오기계'.
  APPEND ls TO lt.

  " 8
  ls-project_id = '0000000008'. ls-project_code = 'PS-2024-004'.
  ls-project_name = '울산 항만 준설 및 안벽 공사'. ls-location = '울산 남구 장생포 항만'.
  ls-client = '울산항만공사'. ls-project_type = 'CIVIL'. ls-status = 'BIDDING'.
  ls-contract_amt = '95000000000'. ls-budget = '90000000000'. ls-exec_budget = '88000000000'. ls-actual_cost = '0'.
  ls-start_date = '20250101'. ls-plan_end_date = '20280101'. ls-actual_end_date = '00000000'.
  ls-progress_rate = '0'. ls-site_manager = '강항만'.
  APPEND ls TO lt.

  " 9
  ls-project_id = '0000000009'. ls-project_code = 'PS-2024-005'.
  ls-project_name = '수원 물류센터 건축공사'. ls-location = '경기 수원 권선구 물류단지'.
  ls-client = '쿠팡로지스(주)'. ls-project_type = 'BUILDING'. ls-status = 'IN_PROGRESS'.
  ls-contract_amt = '38000000000'. ls-budget = '36000000000'. ls-exec_budget = '35000000000'. ls-actual_cost = '0'.
  ls-start_date = '20240801'. ls-plan_end_date = '20260201'. ls-actual_end_date = '00000000'.
  ls-progress_rate = '35'. ls-site_manager = '윤물류'.
  APPEND ls TO lt.

  " 10
  ls-project_id = '0000000010'. ls-project_code = 'PS-2025-003'.
  ls-project_name = '세종 정부청사 전기설비 교체'. ls-location = '세종특별자치시 어진동'.
  ls-client = '조달청'. ls-project_type = 'ELECTRICAL'. ls-status = 'PLANNING'.
  ls-contract_amt = '12000000000'. ls-budget = '11500000000'. ls-exec_budget = '11000000000'. ls-actual_cost = '0'.
  ls-start_date = '20251101'. ls-plan_end_date = '20261031'. ls-actual_end_date = '00000000'.
  ls-progress_rate = '0'. ls-site_manager = '임전기'.
  APPEND ls TO lt.

  INSERT zconstruction_proj FROM TABLE lt.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form init_materials - 15건
*&---------------------------------------------------------------------*
FORM init_materials.
  DATA lt TYPE STANDARD TABLE OF zconstruction_matl.
  DATA ls TYPE zconstruction_matl.

  ls-mandt = sy-mandt. ls-waers = 'KRW'. ls-created_by = 'SYSTEM'.
  GET TIME STAMP FIELD ls-created_at.

  ls-material_id = '0000000001'. ls-material_code = 'MM-STL-001'. ls-material_name = '고강도 철근 HD25'.
  ls-category = 'STEEL'. ls-specification = 'HD25, SD500, KS D 3504'. ls-unit = 'T'.
  ls-standard_price = '950000'. ls-stock_qty = '850'. ls-safety_stock = '200'.
  ls-primary_vendor = '현대제철(주)'. ls-lead_time_days = 7.
  APPEND ls TO lt.

  ls-material_id = '0000000002'. ls-material_code = 'MM-CON-001'. ls-material_name = '레디믹스 콘크리트 25-24-150'.
  ls-category = 'CONCRETE'. ls-specification = '설계기준강도 25MPa, 슬럼프150mm'. ls-unit = 'M3'.
  ls-standard_price = '85000'. ls-stock_qty = '120'. ls-safety_stock = '500'.
  ls-primary_vendor = '삼표레미콘(주)'. ls-lead_time_days = 1.
  APPEND ls TO lt.

  ls-material_id = '0000000003'. ls-material_code = 'MM-STL-002'. ls-material_name = 'H형강 200x200'.
  ls-category = 'STEEL'. ls-specification = 'H-200x200x8x12, SS275'. ls-unit = 'T'.
  ls-standard_price = '1100000'. ls-stock_qty = '45'. ls-safety_stock = '30'.
  ls-primary_vendor = '포스코(주)'. ls-lead_time_days = 14.
  APPEND ls TO lt.

  ls-material_id = '0000000004'. ls-material_code = 'MM-SAF-001'. ls-material_name = '안전망 2mx50m'.
  ls-category = 'SAFETY'. ls-specification = '낙하물방지망, KCS 21 70 05'. ls-unit = 'EA'.
  ls-standard_price = '45000'. ls-stock_qty = '300'. ls-safety_stock = '100'.
  ls-primary_vendor = '안전산업(주)'. ls-lead_time_days = 3.
  APPEND ls TO lt.

  ls-material_id = '0000000005'. ls-material_code = 'MM-WOD-001'. ls-material_name = '합판 12T 1220x2440'.
  ls-category = 'WOOD'. ls-specification = '두께12mm, 1220x2440mm, KS F 3110'. ls-unit = 'EA'.
  ls-standard_price = '18000'. ls-stock_qty = '25'. ls-safety_stock = '100'.
  ls-primary_vendor = '동화기업(주)'. ls-lead_time_days = 5.
  APPEND ls TO lt.

  ls-material_id = '0000000006'. ls-material_code = 'MM-PIP-001'. ls-material_name = '동관 3/4인치 L타입'.
  ls-category = 'PIPING'. ls-specification = '3/4인치, L타입, KS D 5301'. ls-unit = 'M'.
  ls-standard_price = '12000'. ls-stock_qty = '500'. ls-safety_stock = '200'.
  ls-primary_vendor = 'LS전선(주)'. ls-lead_time_days = 10.
  APPEND ls TO lt.

  ls-material_id = '0000000007'. ls-material_code = 'MM-STL-003'. ls-material_name = '각형강관 100x100x4'.
  ls-category = 'STEEL'. ls-specification = 'SHS 100x100x4.0T, SS275'. ls-unit = 'T'.
  ls-standard_price = '1050000'. ls-stock_qty = '20'. ls-safety_stock = '15'.
  ls-primary_vendor = '동국제강(주)'. ls-lead_time_days = 10.
  APPEND ls TO lt.

  ls-material_id = '0000000008'. ls-material_code = 'MM-CON-002'. ls-material_name = '고강도 콘크리트 40-24-180'.
  ls-category = 'CONCRETE'. ls-specification = '설계기준강도 40MPa, 슬럼프180mm'. ls-unit = 'M3'.
  ls-standard_price = '120000'. ls-stock_qty = '0'. ls-safety_stock = '200'.
  ls-primary_vendor = '유진레미콘(주)'. ls-lead_time_days = 2.
  APPEND ls TO lt.

  ls-material_id = '0000000009'. ls-material_code = 'MM-ELC-001'. ls-material_name = 'CV 케이블 22.9kV 325sq'.
  ls-category = 'ELECTRICAL'. ls-specification = 'CV 325sq 3C, 22.9kV, KS C IEC 60502'. ls-unit = 'M'.
  ls-standard_price = '85000'. ls-stock_qty = '2000'. ls-safety_stock = '500'.
  ls-primary_vendor = '대한전선(주)'. ls-lead_time_days = 21.
  APPEND ls TO lt.

  ls-material_id = '0000000010'. ls-material_code = 'MM-ELC-002'. ls-material_name = '분전반 200A 3P'.
  ls-category = 'ELECTRICAL'. ls-specification = 'MCCB 200A, 3극, AC 380V'. ls-unit = 'EA'.
  ls-standard_price = '450000'. ls-stock_qty = '30'. ls-safety_stock = '10'.
  ls-primary_vendor = 'LS일렉트릭(주)'. ls-lead_time_days = 14.
  APPEND ls TO lt.

  ls-material_id = '0000000011'. ls-material_code = 'MM-SAF-002'. ls-material_name = '안전모 ABS'.
  ls-category = 'SAFETY'. ls-specification = 'ABS 재질, 내충격, KS G 3101'. ls-unit = 'EA'.
  ls-standard_price = '8000'. ls-stock_qty = '500'. ls-safety_stock = '200'.
  ls-primary_vendor = '산업안전(주)'. ls-lead_time_days = 3.
  APPEND ls TO lt.

  ls-material_id = '0000000012'. ls-material_code = 'MM-FIN-001'. ls-material_name = '포틀랜드 시멘트 40kg'.
  ls-category = 'CONCRETE'. ls-specification = '1종 포틀랜드 시멘트, KS L 5201'. ls-unit = 'BAG'.
  ls-standard_price = '6500'. ls-stock_qty = '3000'. ls-safety_stock = '1000'.
  ls-primary_vendor = '쌍용씨앤이(주)'. ls-lead_time_days = 3.
  APPEND ls TO lt.

  ls-material_id = '0000000013'. ls-material_code = 'MM-PIP-002'. ls-material_name = 'PVC 파이프 50mm'.
  ls-category = 'PIPING'. ls-specification = 'Ø50mm, 두께2.5mm, KS M 3401'. ls-unit = 'M'.
  ls-standard_price = '3500'. ls-stock_qty = '800'. ls-safety_stock = '300'.
  ls-primary_vendor = '한국화성(주)'. ls-lead_time_days = 7.
  APPEND ls TO lt.

  ls-material_id = '0000000014'. ls-material_code = 'MM-WOD-002'. ls-material_name = '각재 6cm x 9cm x 3.6m'.
  ls-category = 'WOOD'. ls-specification = '방부처리, 6x9cm, KS F 2209'. ls-unit = 'EA'.
  ls-standard_price = '4200'. ls-stock_qty = '15'. ls-safety_stock = '200'.
  ls-primary_vendor = '국제목재(주)'. ls-lead_time_days = 5.
  APPEND ls TO lt.

  ls-material_id = '0000000015'. ls-material_code = 'MM-CHM-001'. ls-material_name = '에폭시 방수제 20L'.
  ls-category = 'CHEMICAL'. ls-specification = '2액형 에폭시, 내수성, KS F 4922'. ls-unit = 'EA'.
  ls-standard_price = '85000'. ls-stock_qty = '60'. ls-safety_stock = '30'.
  ls-primary_vendor = '삼화페인트(주)'. ls-lead_time_days = 7.
  APPEND ls TO lt.

  INSERT zconstruction_matl FROM TABLE lt.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form init_equipment - 10건
*&---------------------------------------------------------------------*
FORM init_equipment.
  DATA lt TYPE STANDARD TABLE OF zconstruction_equip.
  DATA ls TYPE zconstruction_equip.

  ls-mandt = sy-mandt. ls-waers = 'KRW'. ls-created_by = 'SYSTEM'.
  GET TIME STAMP FIELD ls-created_at.

  ls-equipment_id = '0000000001'. ls-equipment_code = 'EQ-EXC-001'. ls-equipment_name = '굴착기 21톤'.
  ls-equipment_type = 'EXCAVATOR'. ls-model = 'EC220E'. ls-manufacturer = 'Volvo CE'.
  ls-registration_no = '경기12가3456'. ls-status = 'IN_USE'. ls-current_project = '0000000001'.
  ls-acquisition_date = '20220315'. ls-acquisition_cost = '280000000'.
  ls-is_rented = abap_false. ls-rental_cost_day = '0'.
  ls-next_maint_date = '20250630'. ls-total_op_hours = '3420'.
  APPEND ls TO lt.

  ls-equipment_id = '0000000002'. ls-equipment_code = 'EQ-CRN-001'. ls-equipment_name = '타워크레인 50톤'.
  ls-equipment_type = 'CRANE'. ls-model = 'LTM 1050-3.1'. ls-manufacturer = 'Liebherr'.
  ls-registration_no = '임대-2024-001'. ls-status = 'IN_USE'. ls-current_project = '0000000001'.
  ls-acquisition_date = '20240101'. ls-acquisition_cost = '0'.
  ls-is_rented = abap_true. ls-rental_cost_day = '2500000'.
  ls-next_maint_date = '20250301'. ls-total_op_hours = '890'.
  APPEND ls TO lt.

  ls-equipment_id = '0000000003'. ls-equipment_code = 'EQ-DMP-001'. ls-equipment_name = '덤프트럭 15톤'.
  ls-equipment_type = 'DUMP_TRUCK'. ls-model = 'HD270'. ls-manufacturer = '현대자동차'.
  ls-registration_no = '경기55나7890'. ls-status = 'IN_USE'. ls-current_project = '0000000002'.
  ls-acquisition_date = '20230801'. ls-acquisition_cost = '120000000'.
  ls-is_rented = abap_false. ls-rental_cost_day = '0'.
  ls-next_maint_date = '20250415'. ls-total_op_hours = '5620'.
  APPEND ls TO lt.

  ls-equipment_id = '0000000004'. ls-equipment_code = 'EQ-BLD-001'. ls-equipment_name = '불도저 D6T'.
  ls-equipment_type = 'BULLDOZER'. ls-model = 'D6T'. ls-manufacturer = 'Caterpillar'.
  ls-registration_no = '충남22나1234'. ls-status = 'AVAILABLE'. ls-current_project = '0000000000'.
  ls-acquisition_date = '20210601'. ls-acquisition_cost = '350000000'.
  ls-is_rented = abap_false. ls-rental_cost_day = '0'.
  ls-next_maint_date = '20250515'. ls-total_op_hours = '8900'.
  APPEND ls TO lt.

  ls-equipment_id = '0000000005'. ls-equipment_code = 'EQ-CPM-001'. ls-equipment_name = '콘크리트 펌프카 52M'.
  ls-equipment_type = 'CONCRETE_PUMP'. ls-model = 'BSF52-5Z'. ls-manufacturer = 'Putzmeister'.
  ls-registration_no = '서울33다5678'. ls-status = 'MAINTENANCE'. ls-current_project = '0000000000'.
  ls-acquisition_date = '20220101'. ls-acquisition_cost = '450000000'.
  ls-is_rented = abap_false. ls-rental_cost_day = '0'.
  ls-next_maint_date = '20250201'. ls-total_op_hours = '4230'.
  APPEND ls TO lt.

  ls-equipment_id = '0000000006'. ls-equipment_code = 'EQ-FLT-001'. ls-equipment_name = '지게차 3톤'.
  ls-equipment_type = 'FORKLIFT'. ls-model = 'GC30K'. ls-manufacturer = '두산산업차량'.
  ls-registration_no = '경기88라2211'. ls-status = 'IN_USE'. ls-current_project = '0000000009'.
  ls-acquisition_date = '20230501'. ls-acquisition_cost = '45000000'.
  ls-is_rented = abap_false. ls-rental_cost_day = '0'.
  ls-next_maint_date = '20250801'. ls-total_op_hours = '1230'.
  APPEND ls TO lt.

  ls-equipment_id = '0000000007'. ls-equipment_code = 'EQ-CRN-002'. ls-equipment_name = '이동식 크레인 25톤'.
  ls-equipment_type = 'CRANE'. ls-model = 'AC 25 City'. ls-manufacturer = 'Tadano'.
  ls-registration_no = '임대-2024-002'. ls-status = 'IN_USE'. ls-current_project = '0000000005'.
  ls-acquisition_date = '20240401'. ls-acquisition_cost = '0'.
  ls-is_rented = abap_true. ls-rental_cost_day = '1200000'.
  ls-next_maint_date = '20250601'. ls-total_op_hours = '560'.
  APPEND ls TO lt.

  ls-equipment_id = '0000000008'. ls-equipment_code = 'EQ-RLR-001'. ls-equipment_name = '진동롤러 10톤'.
  ls-equipment_type = 'ROLLER'. ls-model = 'CS 10 GC'. ls-manufacturer = 'Caterpillar'.
  ls-registration_no = '경기12다9900'. ls-status = 'AVAILABLE'. ls-current_project = '0000000000'.
  ls-acquisition_date = '20200301'. ls-acquisition_cost = '180000000'.
  ls-is_rented = abap_false. ls-rental_cost_day = '0'.
  ls-next_maint_date = '20250701'. ls-total_op_hours = '12400'.
  APPEND ls TO lt.

  ls-equipment_id = '0000000009'. ls-equipment_code = 'EQ-GEN-001'. ls-equipment_name = '발전기 200kVA'.
  ls-equipment_type = 'GENERATOR'. ls-model = 'DHY200'. ls-manufacturer = '대한중기'.
  ls-registration_no = '이동식-2022-005'. ls-status = 'IN_USE'. ls-current_project = '0000000002'.
  ls-acquisition_date = '20220601'. ls-acquisition_cost = '65000000'.
  ls-is_rented = abap_false. ls-rental_cost_day = '0'.
  ls-next_maint_date = '20250401'. ls-total_op_hours = '6700'.
  APPEND ls TO lt.

  ls-equipment_id = '0000000010'. ls-equipment_code = 'EQ-EXC-002'. ls-equipment_name = '미니 굴착기 3톤'.
  ls-equipment_type = 'EXCAVATOR'. ls-model = 'R35Z-9A'. ls-manufacturer = '현대건설기계'.
  ls-registration_no = '경남55가1234'. ls-status = 'BROKEN'. ls-current_project = '0000000000'.
  ls-acquisition_date = '20190901'. ls-acquisition_cost = '55000000'.
  ls-is_rented = abap_false. ls-rental_cost_day = '0'.
  ls-next_maint_date = '20250115'. ls-total_op_hours = '18500'.
  APPEND ls TO lt.

  INSERT zconstruction_equip FROM TABLE lt.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form init_purchase_orders - 8건
*&---------------------------------------------------------------------*
FORM init_purchase_orders.
  DATA lt_po  TYPE STANDARD TABLE OF zconstruction_po.
  DATA lt_poi TYPE STANDARD TABLE OF zconstruction_poi.
  DATA ls_po  TYPE zconstruction_po.
  DATA ls_poi TYPE zconstruction_poi.

  ls_po-mandt = sy-mandt. ls_po-waers = 'KRW'. ls_po-created_by = 'SYSTEM'.
  GET TIME STAMP FIELD ls_po-created_at.
  ls_poi-mandt = sy-mandt. ls_poi-waers = 'KRW'.

  " PO1: 철근 발주 (RECEIVED)
  ls_po-po_id = '0000000001'. ls_po-po_number = 'PO-2024-0001'. ls_po-project_id = '0000000001'.
  ls_po-vendor_name = '현대제철(주)'. ls_po-vendor_code = 'V-001'. ls_po-status = 'RECEIVED'.
  ls_po-order_date = '20240120'. ls_po-delivery_date = '20240201'. ls_po-delivery_addr = '서울 강남구 테헤란로 100'.
  ls_po-total_amount = '522500000'. ls_po-purchaser = '홍길동'. ls_po-remarks = '1차 철근'.
  APPEND ls_po TO lt_po.
  ls_poi-po_id = '0000000001'. ls_poi-item_no = '001'. ls_poi-material_id = '0000000001'.
  ls_poi-item_desc = '고강도 철근 HD25'. ls_poi-quantity = '500'. ls_poi-unit = 'T'.
  ls_poi-unit_price = '950000'. ls_poi-supply_amount = '475000000'. ls_poi-vat_amount = '47500000'.
  ls_poi-total_amount = '522500000'. ls_poi-received_qty = '500'.
  APPEND ls_poi TO lt_poi.

  " PO2: H형강 발주 (ORDERED)
  ls_po-po_id = '0000000002'. ls_po-po_number = 'PO-2024-0002'. ls_po-project_id = '0000000001'.
  ls_po-vendor_name = '포스코(주)'. ls_po-vendor_code = 'V-002'. ls_po-status = 'ORDERED'.
  ls_po-order_date = '20240215'. ls_po-delivery_date = '20240301'. ls_po-delivery_addr = '서울 강남구 테헤란로 100'.
  ls_po-total_amount = '54450000'. ls_po-purchaser = '홍길동'. ls_po-remarks = 'H형강 1차'.
  APPEND ls_po TO lt_po.
  ls_poi-po_id = '0000000002'. ls_poi-item_no = '001'. ls_poi-material_id = '0000000003'.
  ls_poi-item_desc = 'H형강 200x200'. ls_poi-quantity = '45'. ls_poi-unit = 'T'.
  ls_poi-unit_price = '1100000'. ls_poi-supply_amount = '49500000'. ls_poi-vat_amount = '4950000'.
  ls_poi-total_amount = '54450000'. ls_poi-received_qty = '0'.
  APPEND ls_poi TO lt_poi.

  " PO3: 레미콘 발주 (PARTIAL_RECEIVED)
  ls_po-po_id = '0000000003'. ls_po-po_number = 'PO-2024-0003'. ls_po-project_id = '0000000002'.
  ls_po-vendor_name = '삼표레미콘(주)'. ls_po-vendor_code = 'V-003'. ls_po-status = 'PARTIAL_RECEIVED'.
  ls_po-order_date = '20240301'. ls_po-delivery_date = '20240315'. ls_po-delivery_addr = '인천 남동구 현장'.
  ls_po-total_amount = '9350000'. ls_po-purchaser = '이구매'. ls_po-remarks = '교량 기초 타설'.
  APPEND ls_po TO lt_po.
  ls_poi-po_id = '0000000003'. ls_poi-item_no = '001'. ls_poi-material_id = '0000000002'.
  ls_poi-item_desc = '레디믹스 콘크리트 25-24-150'. ls_poi-quantity = '100'. ls_poi-unit = 'M3'.
  ls_poi-unit_price = '85000'. ls_poi-supply_amount = '8500000'. ls_poi-vat_amount = '850000'.
  ls_poi-total_amount = '9350000'. ls_poi-received_qty = '60'.
  APPEND ls_poi TO lt_poi.

  " PO4: 안전용품 발주 (APPROVED)
  ls_po-po_id = '0000000004'. ls_po-po_number = 'PO-2024-0004'. ls_po-project_id = '0000000001'.
  ls_po-vendor_name = '안전산업(주)'. ls_po-vendor_code = 'V-004'. ls_po-status = 'APPROVED'.
  ls_po-order_date = '20240310'. ls_po-delivery_date = '20240325'. ls_po-delivery_addr = '서울 강남구 테헤란로 100'.
  ls_po-total_amount = '14850000'. ls_po-purchaser = '박안전'. ls_po-remarks = '2분기 안전용품'.
  APPEND ls_po TO lt_po.
  ls_poi-po_id = '0000000004'. ls_poi-item_no = '001'. ls_poi-material_id = '0000000004'.
  ls_poi-item_desc = '안전망 2mx50m'. ls_poi-quantity = '200'. ls_poi-unit = 'EA'.
  ls_poi-unit_price = '45000'. ls_poi-supply_amount = '9000000'. ls_poi-vat_amount = '900000'.
  ls_poi-total_amount = '9900000'. ls_poi-received_qty = '0'.
  APPEND ls_poi TO lt_poi.
  ls_poi-item_no = '002'. ls_poi-material_id = '0000000011'.
  ls_poi-item_desc = '안전모 ABS'. ls_poi-quantity = '500'. ls_poi-unit = 'EA'.
  ls_poi-unit_price = '8000'. ls_poi-supply_amount = '4000000'. ls_poi-vat_amount = '400000'.
  ls_poi-total_amount = '4400000'. ls_poi-received_qty = '0'.
  APPEND ls_poi TO lt_poi.

  " PO5: 전선 발주 (PENDING)
  ls_po-po_id = '0000000005'. ls_po-po_number = 'PO-2024-0005'. ls_po-project_id = '0000000004'.
  ls_po-vendor_name = '대한전선(주)'. ls_po-vendor_code = 'V-005'. ls_po-status = 'PENDING'.
  ls_po-order_date = '20240401'. ls_po-delivery_date = '20240501'. ls_po-delivery_addr = '부산 강서구 에코델타'.
  ls_po-total_amount = '187000000'. ls_po-purchaser = '최전기'. ls_po-remarks = '22.9kV 케이블'.
  APPEND ls_po TO lt_po.
  ls_poi-po_id = '0000000005'. ls_poi-item_no = '001'. ls_poi-material_id = '0000000009'.
  ls_poi-item_desc = 'CV케이블 22.9kV 325sq'. ls_poi-quantity = '2000'. ls_poi-unit = 'M'.
  ls_poi-unit_price = '85000'. ls_poi-supply_amount = '170000000'. ls_poi-vat_amount = '17000000'.
  ls_poi-total_amount = '187000000'. ls_poi-received_qty = '0'.
  APPEND ls_poi TO lt_poi.

  " PO6: 시멘트 발주 (DRAFT)
  ls_po-po_id = '0000000006'. ls_po-po_number = 'PO-2024-0006'. ls_po-project_id = '0000000005'.
  ls_po-vendor_name = '쌍용씨앤이(주)'. ls_po-vendor_code = 'V-006'. ls_po-status = 'DRAFT'.
  ls_po-order_date = '20240401'. ls_po-delivery_date = '20240415'. ls_po-delivery_addr = '대전 중구 은행동'.
  ls_po-total_amount = '21450000'. ls_po-purchaser = '정구매'. ls_po-remarks = '기초 타설용'.
  APPEND ls_po TO lt_po.
  ls_poi-po_id = '0000000006'. ls_poi-item_no = '001'. ls_poi-material_id = '0000000012'.
  ls_poi-item_desc = '포틀랜드 시멘트 40kg'. ls_poi-quantity = '3000'. ls_poi-unit = 'BAG'.
  ls_poi-unit_price = '6500'. ls_poi-supply_amount = '19500000'. ls_poi-vat_amount = '1950000'.
  ls_poi-total_amount = '21450000'. ls_poi-received_qty = '0'.
  APPEND ls_poi TO lt_poi.

  " PO7: 합판·각재 복합 발주 (RECEIVED)
  ls_po-po_id = '0000000007'. ls_po-po_number = 'PO-2024-0007'. ls_po-project_id = '0000000009'.
  ls_po-vendor_name = '동화기업(주)'. ls_po-vendor_code = 'V-007'. ls_po-status = 'RECEIVED'.
  ls_po-order_date = '20240501'. ls_po-delivery_date = '20240510'. ls_po-delivery_addr = '경기 수원 권선구'.
  ls_po-total_amount = '15950000'. ls_po-purchaser = '윤구매'. ls_po-remarks = '거푸집 목재'.
  APPEND ls_po TO lt_po.
  ls_poi-po_id = '0000000007'. ls_poi-item_no = '001'. ls_poi-material_id = '0000000005'.
  ls_poi-item_desc = '합판 12T'. ls_poi-quantity = '500'. ls_poi-unit = 'EA'.
  ls_poi-unit_price = '18000'. ls_poi-supply_amount = '9000000'. ls_poi-vat_amount = '900000'.
  ls_poi-total_amount = '9900000'. ls_poi-received_qty = '500'.
  APPEND ls_poi TO lt_poi.
  ls_poi-item_no = '002'. ls_poi-material_id = '0000000014'.
  ls_poi-item_desc = '각재 6x9cm'. ls_poi-quantity = '1000'. ls_poi-unit = 'EA'.
  ls_poi-unit_price = '4200'. ls_poi-supply_amount = '4200000'. ls_poi-vat_amount = '420000'.
  ls_poi-total_amount = '4620000'. ls_poi-received_qty = '1000'.
  APPEND ls_poi TO lt_poi.

  " PO8: 방수제 발주 (CANCELLED)
  ls_po-po_id = '0000000008'. ls_po-po_number = 'PO-2024-0008'. ls_po-project_id = '0000000003'.
  ls_po-vendor_name = '삼화페인트(주)'. ls_po-vendor_code = 'V-008'. ls_po-status = 'CANCELLED'.
  ls_po-order_date = '20240201'. ls_po-delivery_date = '20240215'. ls_po-delivery_addr = '전남 여수 국가산단'.
  ls_po-total_amount = '5610000'. ls_po-purchaser = '박구매'. ls_po-remarks = '설계변경으로 취소'.
  APPEND ls_po TO lt_po.
  ls_poi-po_id = '0000000008'. ls_poi-item_no = '001'. ls_poi-material_id = '0000000015'.
  ls_poi-item_desc = '에폭시 방수제 20L'. ls_poi-quantity = '60'. ls_poi-unit = 'EA'.
  ls_poi-unit_price = '85000'. ls_poi-supply_amount = '5100000'. ls_poi-vat_amount = '510000'.
  ls_poi-total_amount = '5610000'. ls_poi-received_qty = '0'.
  APPEND ls_poi TO lt_poi.

  INSERT zconstruction_po  FROM TABLE lt_po.
  INSERT zconstruction_poi FROM TABLE lt_poi.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form init_cost_entries - 20건
*&---------------------------------------------------------------------*
FORM init_cost_entries.
  DATA lt TYPE STANDARD TABLE OF zconstruction_cost.
  DATA ls TYPE zconstruction_cost.

  ls-mandt = sy-mandt. ls-waers = 'KRW'. ls-created_by = 'SYSTEM'.
  GET TIME STAMP FIELD ls-created_at.

  " 프로젝트1 (강남 주상복합) - 7건
  ls-cost_id='0000000001'. ls-entry_number='CE-2024-001'. ls-project_id='0000000001'.
  ls-cost_type='LABOR'. ls-cost_account='510100'. ls-entry_date='20240131'.
  ls-quantity='200'. ls-unit='H'. ls-unit_price='75000'. ls-amount='15000000'.
  ls-description='1월 형틀목수 노무비'. ls-document_no='DOC-2024-001'.
  APPEND ls TO lt.

  ls-cost_id='0000000002'. ls-entry_number='CE-2024-002'. ls-project_id='0000000001'.
  ls-cost_type='MATERIAL'. ls-cost_account='511000'. ls-entry_date='20240201'.
  ls-quantity='100'. ls-unit='T'. ls-unit_price='950000'. ls-amount='95000000'.
  ls-description='1차 철근 입고 원가'. ls-document_no='DOC-2024-002'.
  APPEND ls TO lt.

  ls-cost_id='0000000003'. ls-entry_number='CE-2024-003'. ls-project_id='0000000001'.
  ls-cost_type='EQUIPMENT_COST'. ls-cost_account='512000'. ls-entry_date='20240131'.
  ls-quantity='20'. ls-unit='DAY'. ls-unit_price='2500000'. ls-amount='50000000'.
  ls-description='1월 타워크레인 임대료'. ls-document_no='DOC-2024-003'.
  APPEND ls TO lt.

  ls-cost_id='0000000004'. ls-entry_number='CE-2024-004'. ls-project_id='0000000001'.
  ls-cost_type='LABOR'. ls-cost_account='510100'. ls-entry_date='20240229'.
  ls-quantity='300'. ls-unit='H'. ls-unit_price='70000'. ls-amount='21000000'.
  ls-description='2월 철근공 노무비'. ls-document_no='DOC-2024-004'.
  APPEND ls TO lt.

  ls-cost_id='0000000005'. ls-entry_number='CE-2024-005'. ls-project_id='0000000001'.
  ls-cost_type='OVERHEAD'. ls-cost_account='515000'. ls-entry_date='20240229'.
  ls-quantity='1'. ls-unit='MON'. ls-unit_price='8000000'. ls-amount='8000000'.
  ls-description='2월 현장사무소 운영비'. ls-document_no='DOC-2024-005'.
  APPEND ls TO lt.

  ls-cost_id='0000000006'. ls-entry_number='CE-2024-006'. ls-project_id='0000000001'.
  ls-cost_type='SUBCONTRACT'. ls-cost_account='513000'. ls-entry_date='20240315'.
  ls-quantity='1'. ls-unit='LOT'. ls-unit_price='45000000'. ls-amount='45000000'.
  ls-description='기초 방수공사 외주'. ls-document_no='DOC-2024-006'.
  APPEND ls TO lt.

  ls-cost_id='0000000007'. ls-entry_number='CE-2024-007'. ls-project_id='0000000001'.
  ls-cost_type='MATERIAL'. ls-cost_account='511000'. ls-entry_date='20240331'.
  ls-quantity='45'. ls-unit='T'. ls-unit_price='1100000'. ls-amount='49500000'.
  ls-description='H형강 구매 원가'. ls-document_no='DOC-2024-007'.
  APPEND ls TO lt.

  " 프로젝트2 (인천 교량) - 5건
  ls-cost_id='0000000008'. ls-entry_number='CE-2024-008'. ls-project_id='0000000002'.
  ls-cost_type='SUBCONTRACT'. ls-cost_account='513000'. ls-entry_date='20240228'.
  ls-quantity='1'. ls-unit='LOT'. ls-unit_price='80000000'. ls-amount='80000000'.
  ls-description='교량 기초 파일 시공'. ls-document_no='DOC-2024-008'.
  APPEND ls TO lt.

  ls-cost_id='0000000009'. ls-entry_number='CE-2024-009'. ls-project_id='0000000002'.
  ls-cost_type='LABOR'. ls-cost_account='510100'. ls-entry_date='20240229'.
  ls-quantity='350'. ls-unit='H'. ls-unit_price='70000'. ls-amount='24500000'.
  ls-description='2월 철근공 노무비'. ls-document_no='DOC-2024-009'.
  APPEND ls TO lt.

  ls-cost_id='0000000010'. ls-entry_number='CE-2024-010'. ls-project_id='0000000002'.
  ls-cost_type='EQUIPMENT_COST'. ls-cost_account='512000'. ls-entry_date='20240331'.
  ls-quantity='30'. ls-unit='DAY'. ls-unit_price='600000'. ls-amount='18000000'.
  ls-description='3월 발전기 운영비'. ls-document_no='DOC-2024-010'.
  APPEND ls TO lt.

  ls-cost_id='0000000011'. ls-entry_number='CE-2024-011'. ls-project_id='0000000002'.
  ls-cost_type='MATERIAL'. ls-cost_account='511000'. ls-entry_date='20240315'.
  ls-quantity='60'. ls-unit='M3'. ls-unit_price='85000'. ls-amount='5100000'.
  ls-description='레미콘 입고 원가 (1차 입고분)'. ls-document_no='DOC-2024-011'.
  APPEND ls TO lt.

  ls-cost_id='0000000012'. ls-entry_number='CE-2024-012'. ls-project_id='0000000002'.
  ls-cost_type='INDIRECT'. ls-cost_account='516000'. ls-entry_date='20240331'.
  ls-quantity='1'. ls-unit='MON'. ls-unit_price='5000000'. ls-amount='5000000'.
  ls-description='3월 간접비 (보험료 등)'. ls-document_no='DOC-2024-012'.
  APPEND ls TO lt.

  " 프로젝트3 (여수 플랜트, 완료) - 4건
  ls-cost_id='0000000013'. ls-entry_number='CE-2023-101'. ls-project_id='0000000003'.
  ls-cost_type='LABOR'. ls-cost_account='510100'. ls-entry_date='20231231'.
  ls-quantity='1200'. ls-unit='H'. ls-unit_price='80000'. ls-amount='96000000'.
  ls-description='하반기 노무비 합계'. ls-document_no='DOC-2023-101'.
  APPEND ls TO lt.

  ls-cost_id='0000000014'. ls-entry_number='CE-2023-102'. ls-project_id='0000000003'.
  ls-cost_type='MATERIAL'. ls-cost_account='511000'. ls-entry_date='20231231'.
  ls-quantity='1'. ls-unit='LOT'. ls-unit_price='180000000'. ls-amount='180000000'.
  ls-description='배관 자재비 합계'. ls-document_no='DOC-2023-102'.
  APPEND ls TO lt.

  ls-cost_id='0000000015'. ls-entry_number='CE-2024-013'. ls-project_id='0000000003'.
  ls-cost_type='SUBCONTRACT'. ls-cost_account='513000'. ls-entry_date='20240630'.
  ls-quantity='1'. ls-unit='LOT'. ls-unit_price='120000000'. ls-amount='120000000'.
  ls-description='배관 설치 전문 하도급'. ls-document_no='DOC-2024-013'.
  APPEND ls TO lt.

  ls-cost_id='0000000016'. ls-entry_number='CE-2024-014'. ls-project_id='0000000003'.
  ls-cost_type='OVERHEAD'. ls-cost_account='515000'. ls-entry_date='20241215'.
  ls-quantity='1'. ls-unit='LOT'. ls-unit_price='25000000'. ls-amount='25000000'.
  ls-description='준공 검사 및 행정비용'. ls-document_no='DOC-2024-014'.
  APPEND ls TO lt.

  " 프로젝트5 (대전 재개발) - 2건
  ls-cost_id='0000000017'. ls-entry_number='CE-2024-015'. ls-project_id='0000000005'.
  ls-cost_type='LABOR'. ls-cost_account='510100'. ls-entry_date='20240731'.
  ls-quantity='250'. ls-unit='H'. ls-unit_price='72000'. ls-amount='18000000'.
  ls-description='7월 굴착 작업 노무비'. ls-document_no='DOC-2024-015'.
  APPEND ls TO lt.

  ls-cost_id='0000000018'. ls-entry_number='CE-2024-016'. ls-project_id='0000000005'.
  ls-cost_type='EQUIPMENT_COST'. ls-cost_account='512000'. ls-entry_date='20240731'.
  ls-quantity='25'. ls-unit='DAY'. ls-unit_price='1200000'. ls-amount='30000000'.
  ls-description='7월 이동식 크레인 임대료'. ls-document_no='DOC-2024-016'.
  APPEND ls TO lt.

  " 프로젝트9 (수원 물류센터) - 2건
  ls-cost_id='0000000019'. ls-entry_number='CE-2024-017'. ls-project_id='0000000009'.
  ls-cost_type='MATERIAL'. ls-cost_account='511000'. ls-entry_date='20240915'.
  ls-quantity='500'. ls-unit='EA'. ls-unit_price='18000'. ls-amount='9000000'.
  ls-description='거푸집 합판 원가'. ls-document_no='DOC-2024-017'.
  APPEND ls TO lt.

  ls-cost_id='0000000020'. ls-entry_number='CE-2024-018'. ls-project_id='0000000009'.
  ls-cost_type='SUBCONTRACT'. ls-cost_account='513000'. ls-entry_date='20241001'.
  ls-quantity='1'. ls-unit='LOT'. ls-unit_price='55000000'. ls-amount='55000000'.
  ls-description='창고 슬래브 타설 외주'. ls-document_no='DOC-2024-018'.
  APPEND ls TO lt.

  INSERT zconstruction_cost FROM TABLE lt.

  " 프로젝트 실적원가 갱신
  PERFORM update_actual_costs.
ENDFORM.

*&---------------------------------------------------------------------*
FORM update_actual_costs.
  SELECT project_id SUM( amount ) AS total
    FROM zconstruction_cost
    GROUP BY project_id
    INTO TABLE @DATA(lt).
  LOOP AT lt INTO DATA(ls).
    UPDATE zconstruction_proj SET actual_cost = @ls-total
      WHERE project_id = @ls-project_id AND mandt = @sy-mandt.
  ENDLOOP.
ENDFORM.
