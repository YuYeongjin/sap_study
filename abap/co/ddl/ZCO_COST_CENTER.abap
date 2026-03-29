*&---------------------------------------------------------------------*
*& Table Definition: ZCO_COST_CENTER
*& Description    : 코스트센터 마스터 (Cost Center Master - CO-CCA)
*& Transaction    : SE11 → Transparent Table
*&---------------------------------------------------------------------*
*
* Table Name  : ZCO_COST_CENTER
* Description : Cost Center Master Data
*
* Fields:
* -----------------------------------------------------------------------
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* KOKRS            X    CHAR       4       통제영역 (Controlling Area)
* KOSTL            X    CHAR       10      코스트센터번호
* DATBI            X    DATS       8       유효 종료일 (Valid To)
* DATAB                 DATS       8       유효 시작일 (Valid From)
* KTEXT                 CHAR       20      코스트센터명(단축)
* LTEXT                 CHAR       40      코스트센터명(상세)
* KOSAR                 CHAR       1       코스트센터 유형
*                                          'F': 생산/공사 (Productive)
*                                          'H': 보조 (Auxiliary)
*                                          'V': 관리 (Administrative)
*                                          'E': 연구개발 (R&D)
* VERAK                 CHAR       12      책임자 (Person Responsible)
* ABTEI                 CHAR       12      부서
* BUKRS                 CHAR       4       회사코드
* GSBER                 CHAR       4       사업영역
* PRCTR                 CHAR       18      수익센터
* WAERS                 CUKY       5       통화
* STAT_IND              CHAR       1       상태 (A:활성, I:비활성, D:삭제)
* HIER_AREA             CHAR       12      표준계층 영역
* FUNC_AREA             CHAR       16      기능영역 (비용기능분류)
*                                          'PROD': 생산/공사
*                                          'SALE': 영업
*                                          'ADMN': 관리
*                                          'RFIN': 연구개발
* CREATED_BY            CHAR       12      생성자
* CREATED_AT            DEC        15      생성일시
* CHANGED_BY            CHAR       12      변경자
* CHANGED_AT            DEC        15      변경일시
* -----------------------------------------------------------------------
*
* 건설회사 코스트센터 체계:
*   1000-1999: 현장 코스트센터 (공사 현장별)
*     1001: 서울 도심재개발 현장
*     1002: 부산 해운대 주거단지 현장
*     1003: 인천 산업단지 현장
*   2000-2999: 기능별 코스트센터
*     2001: 공사관리팀
*     2002: 품질관리팀
*     2003: 안전관리팀
*   3000-3999: 간접부서
*     3001: 경영지원팀
*     3002: 인사총무팀
*     3003: 재무회계팀
*     3004: 구매팀
*   4000-4999: 영업팀
*     4001: 영업1팀
*     4002: 영업2팀
*&---------------------------------------------------------------------*

PROGRAM zco_cost_center_ddl.

TYPES: BEGIN OF ty_co_cost_center,
         mandt      TYPE mandt,
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
         gsber      TYPE gsber,
         prctr      TYPE prctr,
         waers      TYPE waers,
         stat_ind   TYPE c LENGTH 1,
         hier_area  TYPE c LENGTH 12,
         func_area  TYPE fkber,
         created_by TYPE uname,
         created_at TYPE timestamp,
         changed_by TYPE uname,
         changed_at TYPE timestamp,
       END OF ty_co_cost_center.

CONSTANTS:
  gc_kosar_prod TYPE kosar VALUE 'F',   " 생산/공사
  gc_kosar_aux  TYPE kosar VALUE 'H',   " 보조
  gc_kosar_admn TYPE kosar VALUE 'V',   " 관리
  gc_kosar_rnd  TYPE kosar VALUE 'E',   " 연구개발
  gc_stat_act   TYPE c LENGTH 1 VALUE 'A',
  gc_stat_inact TYPE c LENGTH 1 VALUE 'I'.
