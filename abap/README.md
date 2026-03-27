# SAP 건설관리 시스템 - ABAP 구현

Spring Boot + Java 로 구현된 SAP 건설관리 시스템을 **ABAP** 언어로 동일하게 구현한 버전입니다.

---

## 폴더 구조

```
abap/
├── ddl/                          # 데이터베이스 테이블 정의 (SE11)
│   ├── ZCONSTRUCTION_PROJ.abap  # 프로젝트 마스터 (PS)
│   ├── ZCONSTRUCTION_MATL.abap  # 자재 마스터 (MM)
│   ├── ZCONSTRUCTION_EQUIP.abap # 장비 마스터 (PM)
│   ├── ZCONSTRUCTION_PO.abap    # 구매발주 헤더/아이템 (MM)
│   └── ZCONSTRUCTION_COST.abap  # 원가 전표 (CO)
├── classes/                      # 서비스 클래스 (SE24)
│   ├── ZCL_PROJECT_SERVICE.abap
│   ├── ZCL_MATERIAL_SERVICE.abap
│   ├── ZCL_EQUIPMENT_SERVICE.abap
│   ├── ZCL_PO_SERVICE.abap
│   └── ZCL_COST_SERVICE.abap
├── rest/                         # REST API 핸들러 (SICF)
│   ├── ZCL_REST_PROJECT.abap
│   ├── ZCL_REST_MATERIAL.abap
│   ├── ZCL_REST_EQUIPMENT.abap
│   ├── ZCL_REST_PO.abap
│   └── ZCL_REST_COST.abap
├── rap/                          # RAP 모델 (ADT)
│   ├── ZI_CONSTRUCTION_PROJ.cds # CDS Interface View
│   └── ZBP_CONSTRUCTION_PROJ.abap # Behavior Implementation
├── data_init/
│   └── ZINIT_CONSTRUCTION_DATA.abap # 샘플 데이터 생성
└── reports/
    └── ZDISPLAY_CONSTRUCTION.abap   # ALV 조회 리포트
```

---

## Java → ABAP 매핑

| Java (Spring Boot)              | ABAP                              |
|--------------------------------|-----------------------------------|
| `@Entity` JPA 모델             | SE11 Transparent Table            |
| `JpaRepository`                | Open SQL (`SELECT/INSERT/UPDATE`) |
| `@Service` 클래스              | SE24 Global Class                 |
| `@RestController`              | `CL_REST_RESOURCE` 상속 클래스    |
| `application.properties`       | SE11 도메인/허용값 (Fixed Values) |
| `CommandLineRunner` 초기데이터 | SE38 Report (ZINIT_...)           |
| Spring Data 자동 집계          | `SELECT ... GROUP BY SUM()`       |
| JPA `@OneToMany`               | 별도 테이블 JOIN                  |
| `Optional.orElseThrow()`       | `cx_abap_not_found` 예외          |

---

## SAP 모듈 구성

| SAP 모듈 | 테이블                  | 서비스 클래스              |
|---------|------------------------|--------------------------|
| **PS** (Project System)  | `ZCONSTRUCTION_PROJ`  | `ZCL_PROJECT_SERVICE`    |
| **MM** (Materials Mgmt)  | `ZCONSTRUCTION_MATL`  | `ZCL_MATERIAL_SERVICE`   |
| **MM** (Purchasing)      | `ZCONSTRUCTION_PO/I`  | `ZCL_PO_SERVICE`         |
| **PM** (Plant Maint.)    | `ZCONSTRUCTION_EQUIP` | `ZCL_EQUIPMENT_SERVICE`  |
| **CO** (Controlling)     | `ZCONSTRUCTION_COST`  | `ZCL_COST_SERVICE`       |

---

## 설정 순서 (SAP 시스템 기준)

### 1. 테이블 생성 (SE11)
```
각 ddl/ 파일의 주석 참고하여 SE11에서 Transparent Table 생성
→ ZCONSTRUCTION_PROJ, ZCONSTRUCTION_MATL, ZCONSTRUCTION_EQUIP,
   ZCONSTRUCTION_PO, ZCONSTRUCTION_POI, ZCONSTRUCTION_COST
```

### 2. 서비스 클래스 생성 (SE24)
```
각 classes/ 파일을 SE24에서 Global Class로 생성
→ ZCL_PROJECT_SERVICE, ZCL_MATERIAL_SERVICE, ZCL_EQUIPMENT_SERVICE,
   ZCL_PO_SERVICE, ZCL_COST_SERVICE
```

### 3. REST 핸들러 등록 (SICF)
```
트랜잭션 SICF → /default_host/sap/bc/zconstruction/ 하위에 서비스 생성
  - projects       → ZCL_REST_PROJECT
  - materials      → ZCL_REST_MATERIAL
  - equipment      → ZCL_REST_EQUIPMENT
  - purchase-orders → ZCL_REST_PO
  - cost-entries   → ZCL_REST_COST
```

### 4. 샘플 데이터 생성 (SE38)
```
트랜잭션 SE38 → ZINIT_CONSTRUCTION_DATA 실행
→ 프로젝트 4건, 자재 6건, 장비 5건, 발주 3건, 원가전표 5건 생성
```

### 5. 조회 프로그램 실행 (SE38)
```
트랜잭션 SE38 → ZDISPLAY_CONSTRUCTION 실행
  모드 1: 프로젝트 현황 (ALV)
  모드 2: 자재 재고 현황
  모드 3: 장비 현황
  모드 4: 원가 요약
```

---

## REST API 엔드포인트

### 프로젝트 (ProjectController 동일)
```
GET  /sap/bc/zconstruction/projects              → 전체 조회
GET  /sap/bc/zconstruction/projects?id=1         → ID 조회
GET  /sap/bc/zconstruction/projects?status=X     → 상태별 조회
GET  /sap/bc/zconstruction/projects?keyword=서울  → 검색
GET  /sap/bc/zconstruction/projects?stats=X      → 대시보드 통계
POST /sap/bc/zconstruction/projects              → 생성
PUT  /sap/bc/zconstruction/projects?id=1         → 수정
DELETE /sap/bc/zconstruction/projects?id=1       → 삭제
```

### 자재 (MaterialController 동일)
```
GET  /sap/bc/zconstruction/materials             → 전체 조회
GET  /sap/bc/zconstruction/materials?lowstock=X  → 재고부족 조회
GET  /sap/bc/zconstruction/materials?category=STEEL → 카테고리별
```

### 장비 (EquipmentController 동일)
```
PUT  /sap/bc/zconstruction/equipment?id=1&assign=2 → 프로젝트 배정
```

---

## 주요 비즈니스 로직

### CO → PS 연계 (원가 자동 반영)
원가전표(`ZCONSTRUCTION_COST`) 저장/삭제 시 프로젝트의 `ACTUAL_COST` 자동 갱신:
```abap
" ZCL_COST_SERVICE.update_project_actual_cost()
SELECT SUM( amount ) FROM zconstruction_cost
  WHERE project_id = @iv_project_id INTO @lv_total.

UPDATE zconstruction_proj SET actual_cost = @lv_total
  WHERE project_id = @iv_project_id.
```

### 발주 금액 자동계산 (VAT 포함)
```abap
" ZCL_PO_SERVICE.calc_amounts()
<item>-supply_amount = <item>-quantity * <item>-unit_price.
<item>-vat_amount    = <item>-supply_amount * '0.1'.   " 부가세 10%
<item>-total_amount  = <item>-supply_amount + <item>-vat_amount.
```

### 안전재고 미달 자재 조회
```abap
" ZCL_MATERIAL_SERVICE.find_low_stock()
SELECT ... FROM zconstruction_matl
  WHERE stock_qty < safety_stock.
```

### 장비 프로젝트 배정
```abap
" ZCL_EQUIPMENT_SERVICE.assign_to_project()
UPDATE zconstruction_equip
  SET status = 'IN_USE', current_project = @iv_project_id
  WHERE equipment_id = @iv_equipment_id.
```

---

## RAP 모델 (현대적 ABAP 개발)

`rap/` 폴더는 클래식 ABAP 방식 대신 **RAP (RESTful ABAP Programming Model)** 로 구현한 버전입니다:

- `ZI_CONSTRUCTION_PROJ.cds` - CDS Interface View (OData 자동 노출)
- `ZBP_CONSTRUCTION_PROJ.abap` - Behavior Implementation
  - Actions: `setInProgress`, `setCompleted`, `setSuspended`
  - Determination: 저장 시 실적원가 자동 계산
  - Feature Control: 완료된 프로젝트 수정 제한

---

## ABAP 버전 요구사항

| 기능                   | 최소 ABAP 버전 |
|-----------------------|--------------|
| 서비스 클래스 기본     | ABAP 7.40    |
| ABAP OO + Open SQL    | ABAP 7.50    |
| RAP/CDS View          | ABAP 7.55+   |
| `/UI2/CL_JSON`        | SAP NetWeaver 7.4+ |
| `CL_REST_RESOURCE`    | SAP NetWeaver 7.3+ |
