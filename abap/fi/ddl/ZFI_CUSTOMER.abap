*&---------------------------------------------------------------------*
*& Table Definition: ZFI_CUSTOMER
*& Description    : 고객 마스터 (Customer Master - AR)
*& Transaction    : SE11 → Transparent Table
*&---------------------------------------------------------------------*
*
* Table Name  : ZFI_CUSTOMER
* Description : Customer Master (AR)
*
* Fields:
* -----------------------------------------------------------------------
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* KUNNR            X    CHAR       10      고객번호
* BUKRS            X    CHAR       4       회사코드
* NAME1                 CHAR       35      고객명1
* NAME2                 CHAR       35      고객명2
* SORTL                 CHAR       10      정렬코드
* STRAS                 CHAR       35      주소
* ORT01                 CHAR       35      도시
* PSTLZ                 CHAR       10      우편번호
* LAND1                 CHAR       3       국가코드
* TELF1                 CHAR       16      전화번호
* TELFX                 CHAR       31      팩스
* SMTP_ADDR             CHAR       241     이메일
* STCD1                 CHAR       16      사업자등록번호
* STCD2                 CHAR       11      법인번호
* AKONT                 CHAR       10      통합계정 (매출채권 통합계정)
* ZTERM                 CHAR       4       수금조건
* ZWELS                 CHAR       10      수금방법
* BANKS                 CHAR       3       은행 국가코드
* BANKL                 CHAR       15      은행코드
* BANKN                 CHAR       18      계좌번호
* WAERS                 CUKY       5       통화
* KTOKD                 CHAR       4       계정그룹
* CUST_TYPE             CHAR       4       고객유형
*                                          PUBL: 공공기관
*                                          PRIV: 민간기업
*                                          RESI: 주거용
*                                          COMM: 상업용
* CREDIT_LIMIT          CURR       15      신용한도
* CREDIT_USED           CURR       15      신용사용액
* SPERR                 CHAR       1       납품블록
* LOEVM                 CHAR       1       삭제플래그
* CREATED_BY            CHAR       12      생성자
* CREATED_AT            DEC        15      생성일시
* CHANGED_BY            CHAR       12      변경자
* CHANGED_AT            DEC        15      변경일시
* -----------------------------------------------------------------------
*
* 건설회사 고객 유형:
*   PUBL: 공공발주처 (지자체, 공기업 등)
*   PRIV: 민간발주처 (건물주, 시행사 등)
*   RESI: 주거용 건설 발주처
*   COMM: 상업용 건설 발주처
*&---------------------------------------------------------------------*

PROGRAM zfi_customer_ddl.

TYPES: BEGIN OF ty_fi_customer,
         mandt        TYPE mandt,
         kunnr        TYPE kunnr,
         bukrs        TYPE bukrs,
         name1        TYPE name1,
         name2        TYPE name2_gp,
         sortl        TYPE sortl,
         stras        TYPE stras_gp,
         ort01        TYPE ort01_gp,
         pstlz        TYPE pstlz,
         land1        TYPE land1_gp,
         telf1        TYPE telf1,
         telfx        TYPE telfx,
         smtp_addr    TYPE ad_smtpadr,
         stcd1        TYPE stcd1,
         stcd2        TYPE stcd2,
         akont        TYPE saknr,
         zterm        TYPE dzterm,
         zwels        TYPE c LENGTH 10,
         banks        TYPE banks,
         bankl        TYPE bankl,
         bankn        TYPE bankn,
         waers        TYPE waers,
         ktokd        TYPE ktokd,
         cust_type    TYPE c LENGTH 4,
         credit_limit TYPE p LENGTH 15 DECIMALS 2,
         credit_used  TYPE p LENGTH 15 DECIMALS 2,
         sperr        TYPE c LENGTH 1,
         loevm        TYPE c LENGTH 1,
         created_by   TYPE uname,
         created_at   TYPE timestamp,
         changed_by   TYPE uname,
         changed_at   TYPE timestamp,
       END OF ty_fi_customer.

CONSTANTS:
  gc_ctype_publ TYPE c LENGTH 4 VALUE 'PUBL',   " 공공기관
  gc_ctype_priv TYPE c LENGTH 4 VALUE 'PRIV',   " 민간기업
  gc_ctype_resi TYPE c LENGTH 4 VALUE 'RESI',   " 주거용
  gc_ctype_comm TYPE c LENGTH 4 VALUE 'COMM'.   " 상업용
