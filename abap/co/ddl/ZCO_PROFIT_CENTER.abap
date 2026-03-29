*&---------------------------------------------------------------------*
*& Table Definition: ZCO_PROFIT_CENTER
*& Description    : 수익센터 마스터 (Profit Center Master - CO-PCA)
*& Transaction    : SE11 → Transparent Table
*&---------------------------------------------------------------------*
*
* Table Name  : ZCO_PROFIT_CENTER
* Description : Profit Center Master Data (EC-PCA)
*
* Fields:
* -----------------------------------------------------------------------
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* KOKRS            X    CHAR       4       통제영역
* PRCTR            X    CHAR       18      수익센터번호
* DATBI            X    DATS       8       유효 종료일
* DATAB                 DATS       8       유효 시작일
* KTEXT                 CHAR       20      수익센터명(단축)
* LTEXT                 CHAR       40      수익센터명(상세)
* VERAK                 CHAR       12      책임자
* ABTEI                 CHAR       12      부서
* BUKRS                 CHAR       4       회사코드
* GSBER                 CHAR       4       사업영역
* WAERS                 CUKY       5       통화
* PC_TYPE               CHAR       4       수익센터 유형
*                                          PUBL: 공공건설
*                                          PRIV: 민간건설
*                                          RESI: 주거건설
*                                          INFR: 인프라건설
* HIER_AREA             CHAR       12      계층 영역
* STAT_IND              CHAR       1       상태 (A:활성, I:비활성)
* REVENUE_PLAN          CURR       15      수익 계획금액
* REVENUE_ACTUAL        CURR       15      수익 실적금액
* COST_PLAN             CURR       15      원가 계획금액
* COST_ACTUAL           CURR       15      원가 실적금액
* PROFIT_PLAN           CURR       15      이익 계획금액
* PROFIT_ACTUAL         CURR       15      이익 실적금액
* CREATED_BY            CHAR       12      생성자
* CREATED_AT            DEC        15      생성일시
* CHANGED_BY            CHAR       12      변경자
* CHANGED_AT            DEC        15      변경일시
* -----------------------------------------------------------------------
*
* 건설회사 수익센터 체계 (사업부문별):
*   PC1000: 공공건설사업부 (도로, 교량, 공공건물)
*   PC2000: 민간건설사업부 (오피스, 상업시설)
*   PC3000: 주거건설사업부 (아파트, 주택)
*   PC4000: 인프라사업부 (산업단지, 플랜트)
*   PC9000: 공통/관리 (배부 전 집합)
*
* 수익 인식 방식 (건설):
*   - 진행기준 수익 인식 (K-IFRS 1115)
*   - 기성률에 따른 수익 인식
*&---------------------------------------------------------------------*

PROGRAM zco_profit_center_ddl.

TYPES: BEGIN OF ty_co_profit_center,
         mandt          TYPE mandt,
         kokrs          TYPE kokrs,
         prctr          TYPE prctr,
         datbi          TYPE datum,
         datab          TYPE datum,
         ktext          TYPE c LENGTH 20,
         ltext          TYPE c LENGTH 40,
         verak          TYPE uname,
         abtei          TYPE c LENGTH 12,
         bukrs          TYPE bukrs,
         gsber          TYPE gsber,
         waers          TYPE waers,
         pc_type        TYPE c LENGTH 4,
         hier_area      TYPE c LENGTH 12,
         stat_ind       TYPE c LENGTH 1,
         revenue_plan   TYPE p LENGTH 15 DECIMALS 2,
         revenue_actual TYPE p LENGTH 15 DECIMALS 2,
         cost_plan      TYPE p LENGTH 15 DECIMALS 2,
         cost_actual    TYPE p LENGTH 15 DECIMALS 2,
         profit_plan    TYPE p LENGTH 15 DECIMALS 2,
         profit_actual  TYPE p LENGTH 15 DECIMALS 2,
         created_by     TYPE uname,
         created_at     TYPE timestamp,
         changed_by     TYPE uname,
         changed_at     TYPE timestamp,
       END OF ty_co_profit_center.

CONSTANTS:
  gc_pctype_publ TYPE c LENGTH 4 VALUE 'PUBL',  " 공공건설
  gc_pctype_priv TYPE c LENGTH 4 VALUE 'PRIV',  " 민간건설
  gc_pctype_resi TYPE c LENGTH 4 VALUE 'RESI',  " 주거건설
  gc_pctype_infr TYPE c LENGTH 4 VALUE 'INFR'.  " 인프라건설
