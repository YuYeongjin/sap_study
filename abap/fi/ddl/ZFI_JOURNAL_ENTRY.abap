*&---------------------------------------------------------------------*
*& Table Definition: ZFI_JOURNAL_ENTRY
*& Description    : 회계전표 헤더 (Journal Entry Header)
*& Transaction    : SE11 → Transparent Table
*&---------------------------------------------------------------------*
*
* Table Name  : ZFI_JOURNAL_ENTRY
* Description : FI Journal Entry Header
*
* Fields:
* -----------------------------------------------------------------------
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* BUKRS            X    CHAR       4       회사코드
* BELNR            X    CHAR       10      전표번호 (Document Number)
* GJAHR            X    NUMC       4       회계연도 (Fiscal Year)
* BLART                 CHAR       2       전표유형 (Document Type)
*                                          SA: 총계정원장전표
*                                          KR: 매입전표
*                                          DR: 매출전표
*                                          AB: 결산전표
*                                          ZP: 지급전표
*                                          ZE: 수금전표
* BLDAT                 DATS       8       전표일 (Document Date)
* BUDAT                 DATS       8       전기일 (Posting Date)
* MONAT                 NUMC       2       회계기간 (Posting Period)
* WAERS                 CUKY       5       전표통화 (Document Currency)
* KURSF                 DEC        9       환율
* BKTXT                 CHAR       25      전표 헤더 텍스트
* XBLNR                 CHAR       16      참조전표번호 (Reference)
* STBLG                 CHAR       10      역전표번호 (Reversal Doc)
* STJAH                 NUMC       4       역전표 회계연도
* STGRD                 CHAR       2       역전표 사유
* BSTAT                 CHAR       1       전표상태
*                                          ' ': 정상
*                                          'A': 부분결제
*                                          'O': 완전결제
*                                          'S': 역전됨
* USNAM                 CHAR       12      입력자
* TCODE                 CHAR       20      트랜잭션코드
* CPUDT                 DATS       8       입력일
* CPUTM                 TIMS       6       입력시간
* -----------------------------------------------------------------------
*
* 전표번호 채번 규칙:
*   - SA: 1000000000 ~ 1999999999
*   - KR: 5100000000 ~ 5199999999
*   - DR: 1800000000 ~ 1899999999
*   - ZP: 1500000000 ~ 1599999999
*   - ZE: 1400000000 ~ 1499999999
*&---------------------------------------------------------------------*

PROGRAM zfi_journal_entry_ddl.

TYPES: BEGIN OF ty_fi_journal_entry,
         mandt  TYPE mandt,
         bukrs  TYPE bukrs,
         belnr  TYPE belnr_d,
         gjahr  TYPE gjahr,
         blart  TYPE blart,
         bldat  TYPE bldat,
         budat  TYPE budat,
         monat  TYPE monat,
         waers  TYPE waers,
         kursf  TYPE kursf,
         bktxt  TYPE bktxt,
         xblnr  TYPE xblnr,
         stblg  TYPE stblg,
         stjah  TYPE gjahr,
         stgrd  TYPE stgrd,
         bstat  TYPE bstat,
         usnam  TYPE usnam,
         tcode  TYPE tcode,
         cpudt  TYPE cpudt,
         cputm  TYPE cputm,
       END OF ty_fi_journal_entry.

* 전표유형 상수
CONSTANTS:
  gc_blart_sa TYPE blart VALUE 'SA',   " 총계정원장전표
  gc_blart_kr TYPE blart VALUE 'KR',   " 매입전표
  gc_blart_dr TYPE blart VALUE 'DR',   " 매출전표
  gc_blart_ab TYPE blart VALUE 'AB',   " 결산전표
  gc_blart_zp TYPE blart VALUE 'ZP',   " 지급전표
  gc_blart_ze TYPE blart VALUE 'ZE',   " 수금전표
  gc_bstat_open   TYPE bstat VALUE ' ',   " 미결
  gc_bstat_part   TYPE bstat VALUE 'A',   " 부분결제
  gc_bstat_clear  TYPE bstat VALUE 'O',   " 완전결제
  gc_bstat_rev    TYPE bstat VALUE 'S'.   " 역전됨
