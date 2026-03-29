*&---------------------------------------------------------------------*
*& Table Definition: ZFI_ASSET / ZFI_ASSET_DEPR
*& Description    : 자산 마스터 / 감가상각 내역 (Asset Accounting)
*& Transaction    : SE11 → Transparent Table
*&---------------------------------------------------------------------*
*
* =====================================================================
* Table Name  : ZFI_ASSET (자산 마스터)
* =====================================================================
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* BUKRS            X    CHAR       4       회사코드
* ANLN1            X    CHAR       12      자산번호
* ANLN2            X    CHAR       4       자산부번 (0000=마스터)
* ASSET_CLASS           CHAR       8       자산등급
*                                          MACH: 기계장비
*                                          VEHI: 차량운반구
*                                          TOOL: 공기구비품
*                                          BLDG: 건물구축물
*                                          LAND: 토지
*                                          COMP: 전산장비
* TXT50                 CHAR       50      자산명
* TXT20                 CHAR       20      자산명(단축)
* KOSTL                 CHAR       10      코스트센터
* AUFNR                 CHAR       12      내부오더
* PRCTR                 CHAR       18      수익센터
* GSBER                 CHAR       4       사업영역
* INVDATE               DATS       8       취득일 (Capitalization Date)
* DEACT_DATE            DATS       8       제각일 (Deactivation Date)
* INVNR                 CHAR       25      재물조사번호
* SERNR                 CHAR       18      시리얼번호
* VENDOR                CHAR       10      공급업체번호
* ORIG_COST             CURR       15      취득원가 (Original Cost)
* CURR_BOOK_VAL         CURR       15      현재 장부가액
* ACCUM_DEPR            CURR       15      감가상각 누계액
* DEPR_KEY              CHAR       4       감가상각 키
*                                          DG10: 정액법 10년
*                                          DG05: 정액법 5년
*                                          DG03: 정액법 3년
*                                          DB20: 정률법 20%
* USEFUL_LIFE           NUMC       3       내용연수(년)
* CURR_YEAR_DEPR        CURR       15      당기 감가상각비
* WAERS                 CUKY       5       통화
* ASSET_STATUS          CHAR       1       자산상태
*                                          'A': 사용중
*                                          'D': 제각됨
*                                          'T': 이관됨
* LOCATION              CHAR       30      자산 위치(현장명)
* PROJ_ID               NUMC       10      프로젝트 ID
* CREATED_BY            CHAR       12      생성자
* CREATED_AT            DEC        15      생성일시
*
* =====================================================================
* Table Name  : ZFI_ASSET_DEPR (감가상각 내역)
* =====================================================================
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* BUKRS            X    CHAR       4       회사코드
* ANLN1            X    CHAR       12      자산번호
* ANLN2            X    CHAR       4       자산부번
* GJAHR            X    NUMC       4       회계연도
* AFABE            X    NUMC       2       감가상각영역 (01:세무, 20:원가)
* DEPR_PERIOD       X    NUMC       2       감가상각기간(월)
* DEPR_AMOUNT           CURR       15      감가상각비
* ACCUM_DEPR            CURR       15      누계 감가상각비
* BOOK_VALUE            CURR       15      기말 장부가액
* DEPR_STATUS           CHAR       1       처리상태 (P:계획,A:실적,C:결산)
* POSTED_BELNR          CHAR       10      전기 FI 전표번호
* POST_DATE             DATS       8       전기일
* -----------------------------------------------------------------------
*&---------------------------------------------------------------------*

PROGRAM zfi_asset_ddl.

" 자산 마스터
TYPES: BEGIN OF ty_fi_asset,
         mandt          TYPE mandt,
         bukrs          TYPE bukrs,
         anln1          TYPE anln1,
         anln2          TYPE anln2,
         asset_class    TYPE c LENGTH 8,
         txt50          TYPE c LENGTH 50,
         txt20          TYPE c LENGTH 20,
         kostl          TYPE kostl,
         aufnr          TYPE aufnr,
         prctr          TYPE prctr,
         gsber          TYPE gsber,
         invdate        TYPE datum,
         deact_date     TYPE datum,
         invnr          TYPE c LENGTH 25,
         sernr          TYPE c LENGTH 18,
         vendor         TYPE lifnr,
         orig_cost      TYPE p LENGTH 15 DECIMALS 2,
         curr_book_val  TYPE p LENGTH 15 DECIMALS 2,
         accum_depr     TYPE p LENGTH 15 DECIMALS 2,
         depr_key       TYPE c LENGTH 4,
         useful_life    TYPE n LENGTH 3,
         curr_year_depr TYPE p LENGTH 15 DECIMALS 2,
         waers          TYPE waers,
         asset_status   TYPE c LENGTH 1,
         location       TYPE c LENGTH 30,
         proj_id        TYPE n LENGTH 10,
         created_by     TYPE uname,
         created_at     TYPE timestamp,
       END OF ty_fi_asset.

" 감가상각 내역
TYPES: BEGIN OF ty_fi_asset_depr,
         mandt        TYPE mandt,
         bukrs        TYPE bukrs,
         anln1        TYPE anln1,
         anln2        TYPE anln2,
         gjahr        TYPE gjahr,
         afabe        TYPE n LENGTH 2,
         depr_period  TYPE n LENGTH 2,
         depr_amount  TYPE p LENGTH 15 DECIMALS 2,
         accum_depr   TYPE p LENGTH 15 DECIMALS 2,
         book_value   TYPE p LENGTH 15 DECIMALS 2,
         depr_status  TYPE c LENGTH 1,
         posted_belnr TYPE belnr_d,
         post_date    TYPE datum,
       END OF ty_fi_asset_depr.

CONSTANTS:
  gc_aclass_mach TYPE c LENGTH 8 VALUE 'MACH',    " 기계장비
  gc_aclass_vehi TYPE c LENGTH 8 VALUE 'VEHI',    " 차량운반구
  gc_aclass_tool TYPE c LENGTH 8 VALUE 'TOOL',    " 공기구비품
  gc_aclass_bldg TYPE c LENGTH 8 VALUE 'BLDG',    " 건물구축물
  gc_aclass_land TYPE c LENGTH 8 VALUE 'LAND',    " 토지
  gc_aclass_comp TYPE c LENGTH 8 VALUE 'COMP',    " 전산장비
  gc_astat_actv  TYPE c LENGTH 1 VALUE 'A',       " 사용중
  gc_astat_dact  TYPE c LENGTH 1 VALUE 'D',       " 제각됨
  gc_astat_trsf  TYPE c LENGTH 1 VALUE 'T',       " 이관됨
  gc_depr_dg10   TYPE c LENGTH 4 VALUE 'DG10',    " 정액법 10년
  gc_depr_dg05   TYPE c LENGTH 4 VALUE 'DG05',    " 정액법 5년
  gc_depr_dg03   TYPE c LENGTH 4 VALUE 'DG03',    " 정액법 3년
  gc_depr_db20   TYPE c LENGTH 4 VALUE 'DB20'.    " 정률법 20%
