*&---------------------------------------------------------------------*
*& Table Definition: ZFI_AP_INVOICE / ZFI_AP_ITEM
*& Description    : 매입전표 헤더/아이템 (Accounts Payable Invoice)
*& Transaction    : SE11 → Transparent Table
*&---------------------------------------------------------------------*
*
* =====================================================================
* Table Name  : ZFI_AP_INVOICE (매입전표 헤더)
* =====================================================================
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* BUKRS            X    CHAR       4       회사코드
* AP_INVNO         X    CHAR       10      매입전표번호
* GJAHR            X    NUMC       4       회계연도
* LIFNR                 CHAR       10      벤더번호
* BELNR                 CHAR       10      FI 전표번호 (전기 후 생성)
* BLDAT                 DATS       8       전표일
* BUDAT                 DATS       8       전기일
* XBLNR                 CHAR       16      참조번호 (벤더 인보이스번호)
* BKTXT                 CHAR       25      전표 텍스트
* WAERS                 CUKY       5       통화
* GROSS_AMOUNT          CURR       15      총액(세금포함)
* NET_AMOUNT            CURR       15      순액(세금제외)
* TAX_AMOUNT            CURR       15      세액
* ZTERM                 CHAR       4       지급조건
* ZFBDT                 DATS       8       기준일
* DUE_DATE              DATS       8       만기일
* ZLSCH                 CHAR       1       지급방법 (T:이체, C:수표, B:어음)
* PAY_STATUS            CHAR       1       지급상태
*                                          ' ': 미지급
*                                          'P': 부분지급
*                                          'F': 완전지급
*                                          'B': 지급블록
* PAID_AMOUNT           CURR       15      지급액
* PAID_DATE             DATS       8       지급일
* PAY_BELNR             CHAR       10      지급전표번호
* BUKRS_PO              CHAR       4       구매발주 회사코드
* EBELN                 CHAR       10      구매발주번호 (PO)
* AP_TYPE               CHAR       4       매입유형
*                                          MATL: 자재매입
*                                          SUBK: 외주비
*                                          SERV: 용역비
*                                          RENT: 장비임대료
*                                          OVER: 경비
* CREATED_BY            CHAR       12      생성자
* CREATED_AT            DEC        15      생성일시
*
* =====================================================================
* Table Name  : ZFI_AP_ITEM (매입전표 아이템)
* =====================================================================
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* BUKRS            X    CHAR       4       회사코드
* AP_INVNO         X    CHAR       10      매입전표번호
* GJAHR            X    NUMC       4       회계연도
* AP_ITEMNO        X    NUMC       3       아이템번호
* SAKNR                 CHAR       10      계정번호
* KOSTL                 CHAR       10      코스트센터
* AUFNR                 CHAR       12      내부오더
* PRCTR                 CHAR       18      수익센터
* ITEM_TEXT             CHAR       50      항목 텍스트
* NET_AMOUNT            CURR       15      순액
* TAX_CODE              CHAR       2       세금코드
* TAX_AMOUNT            CURR       15      세액
* GROSS_AMOUNT          CURR       15      총액
* MATNR                 CHAR       18      자재번호
* MENGE                 QUAN       13      수량
* MEINS                 UNIT       3       단위
* NETPR                 CURR       15      단가
* -----------------------------------------------------------------------
*&---------------------------------------------------------------------*

PROGRAM zfi_ap_invoice_ddl.

" 매입전표 헤더
TYPES: BEGIN OF ty_fi_ap_invoice,
         mandt        TYPE mandt,
         bukrs        TYPE bukrs,
         ap_invno     TYPE c LENGTH 10,
         gjahr        TYPE gjahr,
         lifnr        TYPE lifnr,
         belnr        TYPE belnr_d,
         bldat        TYPE bldat,
         budat        TYPE budat,
         xblnr        TYPE xblnr,
         bktxt        TYPE bktxt,
         waers        TYPE waers,
         gross_amount TYPE p LENGTH 15 DECIMALS 2,
         net_amount   TYPE p LENGTH 15 DECIMALS 2,
         tax_amount   TYPE p LENGTH 15 DECIMALS 2,
         zterm        TYPE dzterm,
         zfbdt        TYPE dzfbdt,
         due_date     TYPE datum,
         zlsch        TYPE dzlsch,
         pay_status   TYPE c LENGTH 1,
         paid_amount  TYPE p LENGTH 15 DECIMALS 2,
         paid_date    TYPE datum,
         pay_belnr    TYPE belnr_d,
         ebeln        TYPE ebeln,
         ap_type      TYPE c LENGTH 4,
         created_by   TYPE uname,
         created_at   TYPE timestamp,
       END OF ty_fi_ap_invoice.

" 매입전표 아이템
TYPES: BEGIN OF ty_fi_ap_item,
         mandt        TYPE mandt,
         bukrs        TYPE bukrs,
         ap_invno     TYPE c LENGTH 10,
         gjahr        TYPE gjahr,
         ap_itemno    TYPE n LENGTH 3,
         saknr        TYPE saknr,
         kostl        TYPE kostl,
         aufnr        TYPE aufnr,
         prctr        TYPE prctr,
         item_text    TYPE c LENGTH 50,
         net_amount   TYPE p LENGTH 15 DECIMALS 2,
         tax_code     TYPE mwskz,
         tax_amount   TYPE p LENGTH 15 DECIMALS 2,
         gross_amount TYPE p LENGTH 15 DECIMALS 2,
         matnr        TYPE matnr,
         menge        TYPE menge_d,
         meins        TYPE meins,
         netpr        TYPE p LENGTH 15 DECIMALS 2,
       END OF ty_fi_ap_item.

CONSTANTS:
  gc_pay_open  TYPE c LENGTH 1 VALUE ' ',   " 미지급
  gc_pay_part  TYPE c LENGTH 1 VALUE 'P',   " 부분지급
  gc_pay_full  TYPE c LENGTH 1 VALUE 'F',   " 완전지급
  gc_pay_block TYPE c LENGTH 1 VALUE 'B',   " 지급블록
  gc_ap_matl   TYPE c LENGTH 4 VALUE 'MATL',
  gc_ap_subk   TYPE c LENGTH 4 VALUE 'SUBK',
  gc_ap_serv   TYPE c LENGTH 4 VALUE 'SERV',
  gc_ap_rent   TYPE c LENGTH 4 VALUE 'RENT',
  gc_ap_over   TYPE c LENGTH 4 VALUE 'OVER'.
