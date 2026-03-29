*&---------------------------------------------------------------------*
*& Table Definition: ZFI_VENDOR
*& Description    : 벤더(거래처) 마스터 (Vendor Master)
*& Transaction    : SE11 → Transparent Table
*&---------------------------------------------------------------------*
*
* Table Name  : ZFI_VENDOR
* Description : Vendor Master (AP)
*
* Fields:
* -----------------------------------------------------------------------
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* LIFNR            X    CHAR       10      벤더번호
* BUKRS            X    CHAR       4       회사코드
* NAME1                 CHAR       35      벤더명1
* NAME2                 CHAR       35      벤더명2
* SORTL                 CHAR       10      정렬코드
* STRAS                 CHAR       35      주소
* ORT01                 CHAR       35      도시
* PSTLZ                 CHAR       10      우편번호
* LAND1                 CHAR       3       국가코드
* SPRAS                 LANG       1       언어
* TELF1                 CHAR       16      전화번호1
* TELFX                 CHAR       31      팩스
* SMTP_ADDR             CHAR       241     이메일
* STCD1                 CHAR       16      사업자등록번호
* STCD2                 CHAR       11      법인번호
* AKONT                 CHAR       10      통합계정 (Reconciliation Account)
* ZTERM                 CHAR       4       지급조건
* ZWELS                 CHAR       10      지급방법
* BANKS                 CHAR       3       은행 국가코드
* BANKL                 CHAR       15      은행코드
* BANKN                 CHAR       18      계좌번호
* WAERS                 CUKY       5       통화
* KTOKK                 CHAR       4       계정그룹
* VEND_TYPE             CHAR       4       거래처유형
*                                          MATL: 자재공급업체
*                                          SUBK: 외주업체
*                                          EQUP: 장비임대업체
*                                          SERV: 용역업체
*                                          CONS: 컨설팅
* SPERR                 CHAR       1       구매블록 (X=블록)
* LOEVM                 CHAR       1       삭제플래그
* CREATED_BY            CHAR       12      생성자
* CREATED_AT            DEC        15      생성일시
* CHANGED_BY            CHAR       12      변경자
* CHANGED_AT            DEC        15      변경일시
* -----------------------------------------------------------------------
*
* 지급조건 (ZTERM) 예시:
*   NT30 : Net 30일 (30일 이내 지급)
*   NT60 : Net 60일
*   2/10NT30 : 10일 이내 2% 할인, 30일 정상 지급
*   IMM  : 즉시지급
*&---------------------------------------------------------------------*

PROGRAM zfi_vendor_ddl.

TYPES: BEGIN OF ty_fi_vendor,
         mandt      TYPE mandt,
         lifnr      TYPE lifnr,
         bukrs      TYPE bukrs,
         name1      TYPE name1,
         name2      TYPE name2_gp,
         sortl      TYPE sortl,
         stras      TYPE stras_gp,
         ort01      TYPE ort01_gp,
         pstlz      TYPE pstlz,
         land1      TYPE land1_gp,
         spras      TYPE spras,
         telf1      TYPE telf1,
         telfx      TYPE telfx,
         smtp_addr  TYPE ad_smtpadr,
         stcd1      TYPE stcd1,
         stcd2      TYPE stcd2,
         akont      TYPE saknr,
         zterm      TYPE dzterm,
         zwels      TYPE c LENGTH 10,
         banks      TYPE banks,
         bankl      TYPE bankl,
         bankn      TYPE bankn,
         waers      TYPE waers,
         ktokk      TYPE ktokk,
         vend_type  TYPE c LENGTH 4,
         sperr      TYPE c LENGTH 1,
         loevm      TYPE c LENGTH 1,
         created_by TYPE uname,
         created_at TYPE timestamp,
         changed_by TYPE uname,
         changed_at TYPE timestamp,
       END OF ty_fi_vendor.

CONSTANTS:
  gc_vtype_matl TYPE c LENGTH 4 VALUE 'MATL',   " 자재공급업체
  gc_vtype_subk TYPE c LENGTH 4 VALUE 'SUBK',   " 외주업체
  gc_vtype_equp TYPE c LENGTH 4 VALUE 'EQUP',   " 장비임대업체
  gc_vtype_serv TYPE c LENGTH 4 VALUE 'SERV',   " 용역업체
  gc_vtype_cons TYPE c LENGTH 4 VALUE 'CONS'.   " 컨설팅
