*&---------------------------------------------------------------------*
*& Table Definition: ZCO_ACTUAL_LINE / ZCO_PLAN_LINE / ZCO_BUDGET
*& Description    : CO 실적/계획 라인아이템 + 예산 테이블
*& Transaction    : SE11 → Transparent Table
*&---------------------------------------------------------------------*
*
* =====================================================================
* Table Name  : ZCO_ACTUAL_LINE (CO 실적 라인아이템)
* =====================================================================
* Fields:
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* KOKRS            X    CHAR       4       통제영역
* GJAHR            X    NUMC       4       회계연도
* CO_DOCNO         X    CHAR       10      CO 전표번호
* CO_ITEMNO        X    NUMC       3       항목번호
* KOSTL                 CHAR       10      코스트센터 (원가수신)
* AUFNR                 CHAR       12      내부오더 (원가수신)
* PRCTR                 CHAR       18      수익센터
* KSTAR                 CHAR       10      원가요소
* BUZEI                 NUMC       3       FI 항목번호
* BELNR                 CHAR       10      FI 전표번호
* BUKRS                 CHAR       4       회사코드
* BLDAT                 DATS       8       전표일
* BUDAT                 DATS       8       전기일
* MONAT                 NUMC       2       기간(월)
* WKGBTR                CURR       15      실적금액(원가관리통화)
* TWAER                 CUKY       5       원가관리통화
* WRTTP                 CHAR       2       가치유형
*                                          '04': 실적
*                                          '01': 계획
* LIFNR                 CHAR       10      벤더번호
* MATNR                 CHAR       18      자재번호
* MENGE                 QUAN       13      수량
* MEINS                 UNIT       3       단위
* SGTXT                 CHAR       50      항목 텍스트
* USNAM                 CHAR       12      입력자
*
* =====================================================================
* Table Name  : ZCO_PLAN_LINE (CO 계획 라인아이템)
* =====================================================================
* MANDT            X    CLNT       3       클라이언트
* KOKRS            X    CHAR       4       통제영역
* GJAHR            X    NUMC       4       회계연도
* VERSION          X    CHAR       3       버전 (000=실행계획, 001=대안계획)
* KOSTL            X    CHAR       10      코스트센터
* AUFNR            X    CHAR       12      내부오더
* KSTAR            X    CHAR       10      원가요소
* MONAT            X    NUMC       2       기간(월)
* PLAN_AMOUNT           CURR       15      계획금액
* PLAN_QTY              QUAN       13      계획수량
* PLAN_UNIT             UNIT       3       단위
* PLAN_PRICE            CURR       15      계획단가
* TWAER                 CUKY       5       통화
* PLAN_STATUS           CHAR       1       계획상태 (E:작성중, A:승인됨, L:잠김)
* CREATED_BY            CHAR       12      생성자
* CREATED_AT            DEC        15      생성일시
*
* =====================================================================
* Table Name  : ZCO_BUDGET (CO 예산)
* =====================================================================
* MANDT            X    CLNT       3       클라이언트
* KOKRS            X    CHAR       4       통제영역
* GJAHR            X    NUMC       4       회계연도
* AUFNR            X    CHAR       12      내부오더 (예산은 주로 오더 단위)
* KOSTL            X    CHAR       10      코스트센터
* BUDGET_TYPE      X    CHAR       2       예산유형 (OR:원예산, SU:추경)
* ORIG_BUDGET           CURR       15      원예산
* SUPPL_BUDGET          CURR       15      추경예산
* TOTAL_BUDGET          CURR       15      총예산 (원예산+추경)
* ACTUAL_COST           CURR       15      실적원가 (자동갱신)
* COMMIT_COST           CURR       15      확약원가 (PO 미결)
* AVAIL_BUDGET          CURR       15      가용예산 (총예산-실적-확약)
* BUDGET_STATUS         CHAR       2       예산상태
*                                          'OP': 오픈
*                                          'AP': 승인됨
*                                          'CL': 마감됨
* WAERS                 CUKY       5       통화
* APPROVED_BY           CHAR       12      승인자
* APPROVED_AT           DEC        15      승인일시
* CREATED_BY            CHAR       12      생성자
* CREATED_AT            DEC        15      생성일시
* -----------------------------------------------------------------------
*&---------------------------------------------------------------------*

PROGRAM zco_actual_line_ddl.

" CO 실적 라인아이템
TYPES: BEGIN OF ty_co_actual_line,
         mandt     TYPE mandt,
         kokrs     TYPE kokrs,
         gjahr     TYPE gjahr,
         co_docno  TYPE c LENGTH 10,
         co_itemno TYPE n LENGTH 3,
         kostl     TYPE kostl,
         aufnr     TYPE aufnr,
         prctr     TYPE prctr,
         kstar     TYPE kstar,
         buzei     TYPE buzei,
         belnr     TYPE belnr_d,
         bukrs     TYPE bukrs,
         bldat     TYPE bldat,
         budat     TYPE budat,
         monat     TYPE monat,
         wkgbtr    TYPE p LENGTH 15 DECIMALS 2,
         twaer     TYPE waers,
         wrttp     TYPE wrttp,
         lifnr     TYPE lifnr,
         matnr     TYPE matnr,
         menge     TYPE menge_d,
         meins     TYPE meins,
         sgtxt     TYPE sgtxt,
         usnam     TYPE usnam,
       END OF ty_co_actual_line.

" CO 계획 라인아이템
TYPES: BEGIN OF ty_co_plan_line,
         mandt       TYPE mandt,
         kokrs       TYPE kokrs,
         gjahr       TYPE gjahr,
         version     TYPE c LENGTH 3,
         kostl       TYPE kostl,
         aufnr       TYPE aufnr,
         kstar       TYPE kstar,
         monat       TYPE monat,
         plan_amount TYPE p LENGTH 15 DECIMALS 2,
         plan_qty    TYPE p LENGTH 13 DECIMALS 3,
         plan_unit   TYPE meins,
         plan_price  TYPE p LENGTH 15 DECIMALS 2,
         twaer       TYPE waers,
         plan_status TYPE c LENGTH 1,
         created_by  TYPE uname,
         created_at  TYPE timestamp,
       END OF ty_co_plan_line.

" CO 예산
TYPES: BEGIN OF ty_co_budget,
         mandt         TYPE mandt,
         kokrs         TYPE kokrs,
         gjahr         TYPE gjahr,
         aufnr         TYPE aufnr,
         kostl         TYPE kostl,
         budget_type   TYPE c LENGTH 2,
         orig_budget   TYPE p LENGTH 15 DECIMALS 2,
         suppl_budget  TYPE p LENGTH 15 DECIMALS 2,
         total_budget  TYPE p LENGTH 15 DECIMALS 2,
         actual_cost   TYPE p LENGTH 15 DECIMALS 2,
         commit_cost   TYPE p LENGTH 15 DECIMALS 2,
         avail_budget  TYPE p LENGTH 15 DECIMALS 2,
         budget_status TYPE c LENGTH 2,
         waers         TYPE waers,
         approved_by   TYPE uname,
         approved_at   TYPE timestamp,
         created_by    TYPE uname,
         created_at    TYPE timestamp,
       END OF ty_co_budget.

CONSTANTS:
  gc_wrttp_actual TYPE wrttp VALUE '04',   " 실적
  gc_wrttp_plan   TYPE wrttp VALUE '01',   " 계획
  gc_btype_orig   TYPE c LENGTH 2 VALUE 'OR',   " 원예산
  gc_btype_supl   TYPE c LENGTH 2 VALUE 'SU',   " 추경예산
  gc_bstat_open   TYPE c LENGTH 2 VALUE 'OP',   " 오픈
  gc_bstat_appr   TYPE c LENGTH 2 VALUE 'AP',   " 승인됨
  gc_bstat_clos   TYPE c LENGTH 2 VALUE 'CL'.   " 마감됨
