# SAP 건설관리 시스템 - ABAP FI/CO 구현

건설회사 **FI (재무회계)** 및 **CO (관리회계)** 유지보수 담당 업무를 ABAP으로 구현한 학습 프로젝트입니다.

---

## 전체 폴더 구조

```
abap/
├── fi/                           # FI (Financial Accounting)
│   ├── ddl/                      # 테이블 정의 (SE11)
│   │   ├── ZFI_GL_ACCOUNT.abap   # 총계정원장 계정 마스터
│   │   ├── ZFI_JOURNAL_ENTRY.abap # 회계전표 헤더
│   │   ├── ZFI_JOURNAL_ITEM.abap  # 회계전표 라인항목
│   │   ├── ZFI_VENDOR.abap        # 벤더(거래처) 마스터
│   │   ├── ZFI_CUSTOMER.abap      # 고객 마스터
│   │   ├── ZFI_AP_INVOICE.abap    # 매입전표 헤더/아이템
│   │   ├── ZFI_AR_INVOICE.abap    # 매출전표(기성청구) 헤더/아이템
│   │   └── ZFI_ASSET.abap         # 자산 마스터 / 감가상각 내역
│   ├── classes/                  # 서비스 클래스 (SE24)
│   │   ├── ZCL_FI_GL_SERVICE.abap  # GL 서비스 (전표 전기/역전, 잔액조회)
│   │   ├── ZCL_FI_AP_SERVICE.abap  # AP 서비스 (벤더, 매입전표, 지급처리)
│   │   ├── ZCL_FI_AR_SERVICE.abap  # AR 서비스 (고객, 기성청구, 수금처리)
│   │   └── ZCL_FI_ASSET_SERVICE.abap # 자산 서비스 (취득, 감가상각, 제각)
│   ├── rest/                     # REST API 핸들러 (SICF)
│   │   ├── ZCL_REST_FI_AP.abap   # AP REST (/sap/bc/zfi/ap/)
│   │   └── ZCL_REST_FI_AR.abap   # AR REST (/sap/bc/zfi/ar/)
│   └── reports/
│       └── ZFI_AP_AR_REPORT.abap # AP/AR 연령분석, 미결항목 ALV 리포트
│
├── co/                           # CO (Controlling)
│   ├── ddl/                      # 테이블 정의 (SE11)
│   │   ├── ZCO_COST_CENTER.abap  # 코스트센터 마스터
│   │   ├── ZCO_COST_ELEMENT.abap # 원가요소 마스터
│   │   ├── ZCO_INTERNAL_ORDER.abap # 내부오더 마스터
│   │   ├── ZCO_PROFIT_CENTER.abap  # 수익센터 마스터
│   │   └── ZCO_ACTUAL_LINE.abap  # CO 실적/계획 라인 + 예산 테이블
│   ├── classes/                  # 서비스 클래스 (SE24)
│   │   ├── ZCL_CO_COSTCENTER_SERVICE.abap  # 코스트센터 서비스 (계획/차이분석)
│   │   ├── ZCL_CO_ORDER_SERVICE.abap       # 내부오더 서비스 (예산, 정산)
│   │   └── ZCL_CO_PROFITCENTER_SERVICE.abap # 수익센터 서비스 (손익분석)
│   ├── rest/
│   │   └── ZCL_REST_CO_ORDER.abap # CO 오더 REST (/sap/bc/zco/orders/)
│   └── reports/
│       └── ZCO_VARIANCE_REPORT.abap # 계획/실적 차이분석 ALV 리포트
│
├── data_init/
│   ├── ZINIT_CONSTRUCTION_DATA.abap # PS/MM/PM 샘플 데이터
│   └── ZINIT_FI_CO_DATA.abap        # FI/CO 전체 샘플 데이터
│
└── (기존 PS/MM/PM 폴더들 유지)
    ├── classes/  ZCL_PROJECT_SERVICE 등
    ├── ddl/      ZCONSTRUCTION_PROJ 등
    ├── rest/     ZCL_REST_PROJECT 등
    ├── rap/      CDS View, RAP Behavior
    └── reports/  ZDISPLAY_CONSTRUCTION
```

---

## FI 모듈 상세

### 테이블 구조

| 테이블 | 설명 | 주요 필드 |
|--------|------|-----------|
| `ZFI_GL_ACCOUNT` | GL 계정 마스터 | BUKRS, SAKNR, KTOKS, TXT50 |
| `ZFI_JOURNAL_ENTRY` | 회계전표 헤더 | BUKRS, BELNR, GJAHR, BLART, BUDAT |
| `ZFI_JOURNAL_ITEM` | 회계전표 라인 | BELNR, BUZEI, SAKNR, SHKZG, DMBTR |
| `ZFI_VENDOR` | 벤더 마스터 | LIFNR, NAME1, AKONT, ZTERM, VEND_TYPE |
| `ZFI_CUSTOMER` | 고객 마스터 | KUNNR, NAME1, AKONT, CREDIT_LIMIT |
| `ZFI_AP_INVOICE` | 매입전표 헤더 | AP_INVNO, LIFNR, GROSS_AMOUNT, PAY_STATUS |
| `ZFI_AP_ITEM` | 매입전표 아이템 | AP_ITEMNO, SAKNR, KOSTL, AUFNR |
| `ZFI_AR_INVOICE` | 기성청구서 헤더 | AR_INVNO, KUNNR, PROJ_ID, BILL_TYPE |
| `ZFI_AR_ITEM` | 기성청구서 아이템 | AR_ITEMNO, SAKNR, PRCTR, NET_AMOUNT |
| `ZFI_ASSET` | 자산 마스터 | ANLN1, ASSET_CLASS, ORIG_COST, DEPR_KEY |
| `ZFI_ASSET_DEPR` | 감가상각 내역 | GJAHR, DEPR_PERIOD, DEPR_AMOUNT, BOOK_VALUE |

### 건설회사 계정 체계

```
1xxxxx : 자산계정 (BS)
  101000: 현금
  101100: 보통예금
  102000: 공사 매출채권
  111000: 기계장비 (유형자산)
  112000: 감가상각누계액 (차감)
2xxxxx : 부채계정 (BS)
  201000: 매입채무
  202000: 미지급금
  202500: 부가세예수금
  203000: 선수금
4xxxxx : 수익계정 (PL)
  401000: 건설공사수익
5xxxxx : 비용계정 (PL)
  501000: 노무비
  502000: 재료비
  503000: 장비비 (임대료)
  504000: 외주비
  505000: 경비
  506100: 감가상각비
```

### 주요 FI 비즈니스 프로세스

#### AP 프로세스 (매입채무)
```
자재/용역 수령
  → 매입전표 생성 (ZCL_FI_AP_SERVICE.create_ap_invoice)
    → FI 자동전기: 차) 비용 / 대) 매입채무(201000)
    → CO 실적 자동생성 (코스트센터/내부오더)
  → 지급처리 (process_payment)
    → FI 지급전표: 차) 매입채무 / 대) 보통예금
```

#### AR 프로세스 (매출채권 - 기성청구)
```
공사 기성검사 완료
  → 기성청구서 생성 (ZCL_FI_AR_SERVICE.create_ar_invoice)
    → FI 자동전기: 차) 매출채권 / 대) 건설공사수익 + 부가세예수금
  → 수금처리 (process_receipt)
    → FI 수금전표: 차) 보통예금 / 대) 매출채권
  → 대손처리 (write_off_bad_debt) - 필요 시
    → FI 전표: 차) 대손상각비 / 대) 매출채권
```

#### 자산 감가상각 프로세스
```
자산 취득 (acquire_asset)
  → FI 전표: 차) 자산 / 대) 미지급금
월 감가상각 실행 (post_depreciation_run)
  → FI 전표: 차) 감가상각비(506100) / 대) 감가상각누계액(112000)
  → 자산 장부가액 자동 갱신
자산 제각 (retire_asset)
  → FI 전표: 차) 누계액 + 처분손실 / 대) 자산
```

---

## CO 모듈 상세

### 테이블 구조

| 테이블 | 설명 | 주요 필드 |
|--------|------|-----------|
| `ZCO_COST_CENTER` | 코스트센터 마스터 | KOKRS, KOSTL, KTEXT, KOSAR, PRCTR |
| `ZCO_COST_ELEMENT` | 원가요소 마스터 | KOKRS, KSTAR, KATYP, CEL_GROUP |
| `ZCO_INTERNAL_ORDER` | 내부오더 마스터 | KOKRS, AUFNR, AUART, ORDER_STATUS |
| `ZCO_PROFIT_CENTER` | 수익센터 마스터 | KOKRS, PRCTR, PC_TYPE, PROFIT_ACTUAL |
| `ZCO_ACTUAL_LINE` | CO 실적 라인아이템 | CO_DOCNO, KOSTL, AUFNR, KSTAR, WKGBTR |
| `ZCO_PLAN_LINE` | CO 계획 라인아이템 | VERSION, KOSTL, KSTAR, MONAT, PLAN_AMOUNT |
| `ZCO_BUDGET` | CO 예산 | AUFNR, BUDGET_TYPE, TOTAL_BUDGET, AVAIL_BUDGET |

### 코스트센터 체계
```
1001: 서울 도심재개발 현장    (공사현장 CC)
1002: 부산 해운대 주거단지    (공사현장 CC)
1003: 인천 산업단지 현장      (공사현장 CC)
2001: 공사관리팀              (보조 CC)
2002: 품질관리팀              (보조 CC)
3001: 경영지원팀              (관리 CC)
3003: 재무회계팀              (관리 CC)
4001: 영업1팀                 (관리 CC)
```

### 수익센터 (사업부문별)
```
PC1000: 공공건설사업부 (도로, 교량, 공공건물)
PC2000: 민간건설사업부 (오피스, 상업시설)
PC3000: 주거건설사업부 (아파트, 주택)
PC4000: 인프라사업부 (산업단지, 플랜트)
PC9000: 공통/관리 (배부 전 집합)
```

### 내부오더 유형 (AUART)
```
ZCO1: 공사현장 원가수집오더 (프로젝트 내 세부공종)
ZCO2: 간접비 오더 (배부 전 간접비 수집)
ZCO3: 마케팅/입찰 오더 (영업비용 수집)
ZCO4: 자산취득 오더 (자본화 전 원가 수집)
ZCO5: 유지보수 오더 (장비/시설 유지보수)
```

---

## SAP 시스템 설정 순서

### 1단계: FI 테이블 생성 (SE11)

```
ZFI_GL_ACCOUNT    → 총계정원장 계정 마스터
ZFI_JOURNAL_ENTRY → 회계전표 헤더
ZFI_JOURNAL_ITEM  → 회계전표 라인항목
ZFI_VENDOR        → 벤더 마스터
ZFI_CUSTOMER      → 고객 마스터
ZFI_AP_INVOICE    → 매입전표 헤더
ZFI_AP_ITEM       → 매입전표 아이템
ZFI_AR_INVOICE    → 기성청구서 헤더
ZFI_AR_ITEM       → 기성청구서 아이템
ZFI_ASSET         → 자산 마스터
ZFI_ASSET_DEPR    → 감가상각 내역
```

### 2단계: CO 테이블 생성 (SE11)

```
ZCO_COST_CENTER    → 코스트센터 마스터
ZCO_COST_ELEMENT   → 원가요소 마스터
ZCO_INTERNAL_ORDER → 내부오더 마스터
ZCO_PROFIT_CENTER  → 수익센터 마스터
ZCO_ACTUAL_LINE    → CO 실적 라인아이템
ZCO_PLAN_LINE      → CO 계획 라인아이템
ZCO_BUDGET         → CO 예산
```

### 3단계: 서비스 클래스 생성 (SE24)

```
ZCL_FI_GL_SERVICE           → GL 총계정원장 서비스
ZCL_FI_AP_SERVICE           → AP 매입채무 서비스
ZCL_FI_AR_SERVICE           → AR 매출채권 서비스
ZCL_FI_ASSET_SERVICE        → 자산회계 서비스
ZCL_CO_COSTCENTER_SERVICE   → 코스트센터 서비스
ZCL_CO_ORDER_SERVICE        → 내부오더 서비스
ZCL_CO_PROFITCENTER_SERVICE → 수익센터 서비스
```

### 4단계: REST 핸들러 등록 (SICF)

```
/sap/bc/zfi/ap/  → ZCL_REST_FI_AP   (매입채무 API)
/sap/bc/zfi/ar/  → ZCL_REST_FI_AR   (매출채권 API)
/sap/bc/zco/orders/ → ZCL_REST_CO_ORDER (내부오더 API)
```

### 5단계: 샘플 데이터 생성 (SE38)

```
SE38 → ZINIT_FI_CO_DATA 실행 (p_init = 'X')

생성 데이터:
  GL 계정     20건
  벤더         8건 (MATL/EQUP/SUBK/SERV)
  고객         5건 (공공/민간)
  매입전표     7건 (미지급/부분지급/완전지급)
  기성청구서   6건 (미수금/부분수금/완전수금)
  자산         5건 (굴삭기/타워크레인/트럭/서버/공구)
  코스트센터   8건
  원가요소    12건
  내부오더     6건 + 예산
  수익센터     5건
  CO 계획     24건 (월별)
  CO 실적      8건
```

### 6단계: 리포트 실행 (SE38)

```
ZFI_AP_AR_REPORT    → AP/AR 연령분석, 미결항목 조회
  모드 1: AP 연령분석 (벤더별 미지급 연령)
  모드 2: AR 연령분석 (고객별 미수금 연령)
  모드 3: 미결 AP 목록 (신호등 표시)
  모드 4: 미결 AR 목록 (신호등 표시)
  모드 5: AP/AR 잔액 대사

ZCO_VARIANCE_REPORT → CO 계획/실적 차이분석
  모드 1: 코스트센터 계획/실적 차이분석
  모드 2: 내부오더 예산 현황 (신호등)
  모드 3: 수익센터 손익 분석
  모드 4: 원가요소별 집계 (전사)
  모드 5: 프로젝트별 원가 현황
```

---

## REST API 엔드포인트

### FI - AP (매입채무)

```
GET    /sap/bc/zfi/ap/vendors               벤더 전체 조회
GET    /sap/bc/zfi/ap/vendors?id=V10001     벤더 단건
GET    /sap/bc/zfi/ap/vendors?type=SUBK     유형별 (MATL/EQUP/SUBK/SERV)
GET    /sap/bc/zfi/ap/vendors?search=삼성    키워드 검색
POST   /sap/bc/zfi/ap/vendors               벤더 생성
PUT    /sap/bc/zfi/ap/vendors?id=V10001     벤더 수정
DELETE /sap/bc/zfi/ap/vendors?id=V10001     벤더 블록

GET    /sap/bc/zfi/ap/invoices              매입전표 목록
GET    /sap/bc/zfi/ap/invoices?id=20260001  매입전표 단건
GET    /sap/bc/zfi/ap/invoices?overdue=X    연체 전표 조회
POST   /sap/bc/zfi/ap/invoices              매입전표 생성 (FI 자동 전기)
PUT    /sap/bc/zfi/ap/invoices?id=20260001  수정 (미지급만 가능)
DELETE /sap/bc/zfi/ap/invoices?id=20260001  삭제 (미지급만 가능)

POST   /sap/bc/zfi/ap/payment               지급 처리
GET    /sap/bc/zfi/ap/aging                 AP 연령분석
```

### FI - AR (매출채권)

```
GET    /sap/bc/zfi/ar/customers             고객 전체 조회
GET    /sap/bc/zfi/ar/customers?id=C10001   고객 단건
POST   /sap/bc/zfi/ar/customers             고객 생성
PUT    /sap/bc/zfi/ar/customers?id=C10001   고객 수정

GET    /sap/bc/zfi/ar/invoices              기성청구서 목록
GET    /sap/bc/zfi/ar/invoices?proj=1       프로젝트별 조회
GET    /sap/bc/zfi/ar/invoices?id=AR20260001 기성청구서 단건
POST   /sap/bc/zfi/ar/invoices              기성청구서 생성 (FI 자동 전기)
PUT    /sap/bc/zfi/ar/invoices?id=AR20260001 수정
DELETE /sap/bc/zfi/ar/invoices?id=AR20260001 삭제

POST   /sap/bc/zfi/ar/receipt               수금 처리
POST   /sap/bc/zfi/ar/baddebt               대손 처리
GET    /sap/bc/zfi/ar/aging                 AR 연령분석
GET    /sap/bc/zfi/ar/revenue               프로젝트별 수익 현황
```

### CO - 내부오더

```
GET    /sap/bc/zco/orders                   오더 전체 조회
GET    /sap/bc/zco/orders?id=100000001      오더 단건
GET    /sap/bc/zco/orders?proj=1            프로젝트별 조회
GET    /sap/bc/zco/orders?overbudget=X      예산초과 오더
GET    /sap/bc/zco/orders?budget=100000001  예산 현황 (가용예산, %)
GET    /sap/bc/zco/orders?cost=100000001    원가요소별 상세
POST   /sap/bc/zco/orders                   오더 생성
POST   /sap/bc/zco/orders/release           오더 릴리즈 (CR→RE)
POST   /sap/bc/zco/orders/settle            오더 정산 (원가 이전)
PUT    /sap/bc/zco/orders?id=100000001      오더 수정
POST   /sap/bc/zco/budgets                  예산 등록/변경
```

---

## 핵심 비즈니스 로직

### 복식부기 검증 (FI 전표 전기)
```abap
" 차변합계 = 대변합계 → 불균형 시 전기 거부
validate_balance() → abap_false 이면 cx_sy_dyn_call_error
```

### FI 전기 → CO 실적 자동 생성
```abap
" KOSTL/AUFNR 있는 라인 → ZCO_ACTUAL_LINE 자동 생성
" 내부오더 actual_cost 자동 갱신
```

### 기성청구 FI 자동 전기
```abap
차) 매출채권(102000) = 청구총액
대) 건설공사수익(401000) = 청구순액
대) 부가세예수금(202500) = 세액
```

### 예산 가용성 계산
```abap
avail_budget = total_budget - actual_cost - commit_cost
used_pct(%) = actual_cost / total_budget * 100
```

### 감가상각 계산
```abap
정액법(DG10): monthly_depr = orig_cost / (useful_life * 12)
정률법(DB20): monthly_depr = curr_book_val * 0.2 / 12
```

---

## ABAP 버전 요구사항

| 기능 | 최소 버전 |
|------|-----------|
| 기본 OO + Open SQL | ABAP 7.40 |
| 인라인 선언, VALUE 생성자 | ABAP 7.40 SP5+ |
| COND/SWITCH 표현식 | ABAP 7.50 |
| CDS View / RAP | ABAP 7.55+ |
| `/UI2/CL_JSON` | SAP NetWeaver 7.4+ |
| `CL_REST_RESOURCE` | SAP NetWeaver 7.3+ |
| `CL_SALV_TABLE` | SAP 기본 제공 |
