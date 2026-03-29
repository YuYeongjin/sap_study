*&---------------------------------------------------------------------*
*& Table Definition: ZCO_COST_ELEMENT
*& Description    : 원가요소 마스터 (Cost Element Master - CO-CEL)
*& Transaction    : SE11 → Transparent Table
*&---------------------------------------------------------------------*
*
* Table Name  : ZCO_COST_ELEMENT
* Description : Cost Element Master (Primary & Secondary)
*
* Fields:
* -----------------------------------------------------------------------
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* KOKRS            X    CHAR       4       통제영역
* KSTAR            X    CHAR       10      원가요소번호 (= GL 계정번호)
* DATBI            X    DATS       8       유효 종료일
* DATAB                 DATS       8       유효 시작일
* KTEXT                 CHAR       20      원가요소명(단축)
* LTEXT                 CHAR       40      원가요소명(상세)
* KATYP                 CHAR       1       원가요소 유형
*                                          '1': 1차 원가요소 (FI 비용계정과 연계)
*                                          '3': 내부활동배부
*                                          '4': 간접비 계산
*                                          '11': 수익요소
*                                          '22': 외부결산
*                                          '41': 오버헤드 요율
*                                          '42': 평가배분
*                                          '43': 내부 오더
*                                          '50': 프로젝트 결과
* CEL_GROUP            CHAR       4       원가요소 그룹
*                                          LABR: 노무비
*                                          MATL: 재료비
*                                          EQUP: 장비비
*                                          SUBK: 외주비
*                                          OVER: 경비
*                                          IDRT: 간접비
*                                          REVN: 수익
* WAERS                CUKY       5       통화
* STAT_IND             CHAR       1       상태
* CREATED_BY           CHAR       12      생성자
* CREATED_AT           DEC        15      생성일시
* -----------------------------------------------------------------------
*
* 1차 원가요소 (FI GL 계정과 1:1 매핑):
*   501000: 노무비 (LABR)
*   501100: 일반직 급여
*   501200: 현장 노무비
*   502000: 재료비 (MATL)
*   502100: 철근/콘크리트 재료비
*   502200: 자재 부자재비
*   503000: 장비비 (EQUP)
*   503100: 건설장비 임대료
*   503200: 중장비 운반비
*   504000: 외주비 (SUBK)
*   504100: 전문건설 외주비
*   504200: 노무 외주비
*   505000: 경비 (OVER)
*   505100: 보험료
*   505200: 복리후생비
*   505300: 출장비
*   506000: 판관비 (IDRT)
*   506100: 감가상각비
*   506200: 임차료
*&---------------------------------------------------------------------*

PROGRAM zco_cost_element_ddl.

TYPES: BEGIN OF ty_co_cost_element,
         mandt      TYPE mandt,
         kokrs      TYPE kokrs,
         kstar      TYPE kstar,
         datbi      TYPE datum,
         datab      TYPE datum,
         ktext      TYPE c LENGTH 20,
         ltext      TYPE c LENGTH 40,
         katyp      TYPE katyp,
         cel_group  TYPE c LENGTH 4,
         waers      TYPE waers,
         stat_ind   TYPE c LENGTH 1,
         created_by TYPE uname,
         created_at TYPE timestamp,
       END OF ty_co_cost_element.

CONSTANTS:
  gc_cel_labr TYPE c LENGTH 4 VALUE 'LABR',  " 노무비
  gc_cel_matl TYPE c LENGTH 4 VALUE 'MATL',  " 재료비
  gc_cel_equp TYPE c LENGTH 4 VALUE 'EQUP',  " 장비비
  gc_cel_subk TYPE c LENGTH 4 VALUE 'SUBK',  " 외주비
  gc_cel_over TYPE c LENGTH 4 VALUE 'OVER',  " 경비
  gc_cel_idrt TYPE c LENGTH 4 VALUE 'IDRT',  " 간접비
  gc_cel_revn TYPE c LENGTH 4 VALUE 'REVN',  " 수익
  gc_katyp_primary   TYPE katyp VALUE '1',   " 1차 원가요소
  gc_katyp_activity  TYPE katyp VALUE '3',   " 내부활동배부
  gc_katyp_overhead  TYPE katyp VALUE '4',   " 간접비계산
  gc_katyp_revenue   TYPE katyp VALUE '11'.  " 수익요소
