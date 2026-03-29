*&---------------------------------------------------------------------*
*& Table Definition: ZFI_GL_ACCOUNT
*& Description    : 총계정원장 계정 마스터 (GL Account Master)
*& Transaction    : SE11 → Transparent Table
*&---------------------------------------------------------------------*
*
* Table Name  : ZFI_GL_ACCOUNT
* Description : General Ledger Account Master
*
* Fields:
* -----------------------------------------------------------------------
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* BUKRS            X    CHAR       4       회사코드 (Company Code)
* SAKNR            X    CHAR       10      계정번호 (GL Account Number)
* KTOKS                 CHAR       4       계정그룹 (Account Group)
*                                          BILZ: 대차대조표계정
*                                          GVXX: 손익계산서계정
* XBILK                 CHAR       1       대차대조표계정 여부 (X=BS, 공백=PL)
* SAKAN                 CHAR       10      대체계정번호
* TXT20                 CHAR       20      계정명 단축 (Short Text)
* TXT50                 CHAR       50      계정명 (Long Text)
* WAERS                 CUKY       5       계정통화 (Account Currency)
* XOPVW                 CHAR       1       미결관리 여부 (X=Open Item Managed)
* XKRES                 CHAR       1       라인항목표시 여부
* ZUAWA                 CHAR       3       정렬기준
* FSTAG                 CHAR       5       재무제표 유형
* GVTYP                 CHAR       2       P&L 계정유형 (X:비용, Y:수익)
* MITKZ                 CHAR       2       특수원장 지시자
* STAT_IND              CHAR       1       계정상태 (A:활성, I:비활성)
* CREATED_BY            CHAR       12      생성자
* CREATED_AT            DEC        15      생성일시
* CHANGED_BY            CHAR       12      변경자
* CHANGED_AT            DEC        15      변경일시
* -----------------------------------------------------------------------
*
* 건설회사 주요 계정 구조:
*   1xxxxx : 자산계정 (Assets)
*     10xxxx : 유동자산
*       101xxx : 현금및현금성자산
*       102xxx : 매출채권
*       103xxx : 재고자산
*     11xxxx : 비유동자산
*       111xxx : 유형자산
*       112xxx : 감가상각누계액
*   2xxxxx : 부채계정 (Liabilities)
*     20xxxx : 유동부채
*       201xxx : 매입채무
*       202xxx : 미지급비용
*     21xxxx : 비유동부채
*   3xxxxx : 자본계정 (Equity)
*   4xxxxx : 매출계정 (Revenue)
*     401xxx : 건설공사수익
*     402xxx : 기타수익
*   5xxxxx : 비용계정 (Expenses)
*     501xxx : 노무비
*     502xxx : 재료비
*     503xxx : 장비비
*     504xxx : 외주비
*     505xxx : 경비
*     506xxx : 판관비
*&---------------------------------------------------------------------*

PROGRAM zfi_gl_account_ddl.

TYPES: BEGIN OF ty_fi_gl_account,
         mandt      TYPE mandt,
         bukrs      TYPE bukrs,
         saknr      TYPE saknr,
         ktoks      TYPE ktoks,
         xbilk      TYPE xbilk,
         sakan      TYPE c LENGTH 10,
         txt20      TYPE c LENGTH 20,
         txt50      TYPE c LENGTH 50,
         waers      TYPE waers,
         xopvw      TYPE c LENGTH 1,
         xkres      TYPE c LENGTH 1,
         zuawa      TYPE c LENGTH 3,
         fstag      TYPE c LENGTH 5,
         gvtyp      TYPE gvtyp,
         mitkz      TYPE c LENGTH 2,
         stat_ind   TYPE c LENGTH 1,
         created_by TYPE uname,
         created_at TYPE timestamp,
         changed_by TYPE uname,
         changed_at TYPE timestamp,
       END OF ty_fi_gl_account.

* 계정그룹 상수
CONSTANTS:
  gc_ktoks_bilz TYPE c LENGTH 4 VALUE 'BILZ',   " 대차대조표계정
  gc_ktoks_gvxx TYPE c LENGTH 4 VALUE 'GVXX',   " 손익계산서계정
  gc_xbilk_bs   TYPE c LENGTH 1 VALUE 'X',      " 대차대조표(BS)
  gc_xbilk_pl   TYPE c LENGTH 1 VALUE ' ',      " 손익계산서(PL)
  gc_stat_act   TYPE c LENGTH 1 VALUE 'A',      " 활성
  gc_stat_inact TYPE c LENGTH 1 VALUE 'I'.      " 비활성
