*&---------------------------------------------------------------------*
*& Table Definition: ZCO_INTERNAL_ORDER
*& Description    : 내부오더 마스터 (Internal Order Master - CO-OPA)
*& Transaction    : SE11 → Transparent Table
*&---------------------------------------------------------------------*
*
* Table Name  : ZCO_INTERNAL_ORDER
* Description : Internal Order Master (CO-OPA)
*
* Fields:
* -----------------------------------------------------------------------
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* KOKRS            X    CHAR       4       통제영역
* AUFNR            X    CHAR       12      오더번호
* AUART                 CHAR       4       오더유형 (Order Type)
*                                          ZCO1: 공사현장 원가수집오더
*                                          ZCO2: 간접비 오더
*                                          ZCO3: 마케팅 오더
*                                          ZCO4: 자산취득 오더
*                                          ZCO5: 유지보수 오더
* KTEXT                 CHAR       20      오더명(단축)
* LTEXT                 CHAR       40      오더명(상세)
* BUKRS                 CHAR       4       회사코드
* KOSTL                 CHAR       10      책임 코스트센터
* PRCTR                 CHAR       18      수익센터
* GSBER                 CHAR       4       사업영역
* PROJ_ID               NUMC       10      프로젝트 ID (ZCONSTRUCTION_PROJ 연계)
* WERKS                 CHAR       4       플랜트
* WAERS                 CUKY       5       통화
* ERDAT                 DATS       8       생성일
* AEDAT                 DATS       8       변경일
* IDAT1                 DATS       8       오더 시작일
* IDAT2                 DATS       8       오더 종료일
* ORDER_STATUS          CHAR       2       오더 상태
*                                          'CR': 생성됨
*                                          'RE': 릴리즈됨
*                                          'CL': 결산완료
*                                          'LK': 잠금
* BUDGET_AMOUNT         CURR       15      예산 금액
* ACTUAL_COST           CURR       15      실적 원가 (자동갱신)
* COMMIT_COST           CURR       15      확약 원가 (PO기반)
* PLAN_COST             CURR       15      계획 원가
* VARIANCE              CURR       15      차이 금액 (예산-실적)
* SETTLE_RULE           CHAR       1       정산규칙
*                                          'F': 고정비율 정산
*                                          'V': 변동비율 정산
*                                          'P': 우선순위 정산
* SETTLE_RCVR           CHAR       10      정산수신자 (코스트센터/GL계정)
* RCVR_TYPE             CHAR       3       수신자 유형 (CTR:코스트센터, GL:계정)
* CREATED_BY            CHAR       12      생성자
* CREATED_AT            DEC        15      생성일시
* CHANGED_BY            CHAR       12      변경자
* CHANGED_AT            DEC        15      변경일시
* -----------------------------------------------------------------------
*
* 건설현장 내부오더 활용:
*   - 공사별 원가 수집 (프로젝트 내 세부공종별 원가 추적)
*   - 간접비 수집 후 공사비로 배부
*   - 장비 취득/유지보수 원가 수집
*   - 입찰/수주 관련 영업비용 수집
*
* 정산 흐름:
*   내부오더 (원가 수집) → 코스트센터 또는 WBS 요소로 정산
*&---------------------------------------------------------------------*

PROGRAM zco_internal_order_ddl.

TYPES: BEGIN OF ty_co_internal_order,
         mandt         TYPE mandt,
         kokrs         TYPE kokrs,
         aufnr         TYPE aufnr,
         auart         TYPE auart,
         ktext         TYPE c LENGTH 20,
         ltext         TYPE c LENGTH 40,
         bukrs         TYPE bukrs,
         kostl         TYPE kostl,
         prctr         TYPE prctr,
         gsber         TYPE gsber,
         proj_id       TYPE n LENGTH 10,
         werks         TYPE werks_d,
         waers         TYPE waers,
         erdat         TYPE erdat,
         aedat         TYPE aedat,
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
         created_at    TYPE timestamp,
         changed_by    TYPE uname,
         changed_at    TYPE timestamp,
       END OF ty_co_internal_order.

CONSTANTS:
  gc_auart_site  TYPE auart VALUE 'ZCO1',  " 공사현장 오더
  gc_auart_indr  TYPE auart VALUE 'ZCO2',  " 간접비 오더
  gc_auart_mktg  TYPE auart VALUE 'ZCO3',  " 마케팅 오더
  gc_auart_capx  TYPE auart VALUE 'ZCO4',  " 자산취득 오더
  gc_auart_maint TYPE auart VALUE 'ZCO5',  " 유지보수 오더
  gc_ostatus_cr  TYPE c LENGTH 2 VALUE 'CR',  " 생성됨
  gc_ostatus_re  TYPE c LENGTH 2 VALUE 'RE',  " 릴리즈됨
  gc_ostatus_cl  TYPE c LENGTH 2 VALUE 'CL',  " 결산완료
  gc_ostatus_lk  TYPE c LENGTH 2 VALUE 'LK'.  " 잠금
