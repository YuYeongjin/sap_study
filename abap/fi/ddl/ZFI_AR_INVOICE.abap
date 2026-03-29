*&---------------------------------------------------------------------*
*& Table Definition: ZFI_AR_INVOICE / ZFI_AR_ITEM
*& Description    : 매출전표 헤더/아이템 (Accounts Receivable Invoice)
*& Transaction    : SE11 → Transparent Table
*&---------------------------------------------------------------------*
*
* =====================================================================
* Table Name  : ZFI_AR_INVOICE (매출전표 헤더)
* =====================================================================
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* BUKRS            X    CHAR       4       회사코드
* AR_INVNO         X    CHAR       10      매출전표번호
* GJAHR            X    NUMC       4       회계연도
* KUNNR                 CHAR       10      고객번호
* BELNR                 CHAR       10      FI 전표번호
* BLDAT                 DATS       8       전표일(청구일)
* BUDAT                 DATS       8       전기일
* XBLNR                 CHAR       16      참조번호 (공사계약번호)
* BKTXT                 CHAR       25      전표 텍스트
* WAERS                 CUKY       5       통화
* GROSS_AMOUNT          CURR       15      청구총액(세금포함)
* NET_AMOUNT            CURR       15      청구순액
* TAX_AMOUNT            CURR       15      세액(부가세)
* ZTERM                 CHAR       4       수금조건
* ZFBDT                 DATS       8       기준일
* DUE_DATE              DATS       8       수금만기일
* RCV_STATUS            CHAR       1       수금상태
*                                          ' ': 미수금
*                                          'P': 부분수금
*                                          'F': 완전수금
*                                          'D': 대손처리
* RCVD_AMOUNT           CURR       15      수금액
* RCVD_DATE             DATS       8       수금일
* RCV_BELNR             CHAR       10      수금전표번호
* PROJ_ID               NUMC       10      프로젝트ID → FK ZCONSTRUCTION_PROJ
* CONTRACT_NO           CHAR       20      공사계약번호
* BILL_TYPE             CHAR       4       청구유형
*                                          PROG: 기성청구 (Progress Billing)
*                                          FINL: 최종청구
*                                          ADDL: 추가공사청구
*                                          RETD: 하자보수 지급청구
* WORK_FROM             DATS       8       공사기간 시작일
* WORK_TO               DATS       8       공사기간 종료일
* PROGRESS_RATE         DEC        5       기성률(%)
* CREATED_BY            CHAR       12      생성자
* CREATED_AT            DEC        15      생성일시
*
* =====================================================================
* Table Name  : ZFI_AR_ITEM (매출전표 아이템)
* =====================================================================
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* BUKRS            X    CHAR       4       회사코드
* AR_INVNO         X    CHAR       10      매출전표번호
* GJAHR            X    NUMC       4       회계연도
* AR_ITEMNO        X    NUMC       3       아이템번호
* SAKNR                 CHAR       10      계정번호
* ITEM_TEXT             CHAR       50      항목 텍스트
* NET_AMOUNT            CURR       15      순액
* TAX_CODE              CHAR       2       세금코드
* TAX_AMOUNT            CURR       15      세액
* GROSS_AMOUNT          CURR       15      총액
* PRCTR                 CHAR       18      수익센터
* WORK_DESC             CHAR       100     공사내역 설명
* -----------------------------------------------------------------------
*
* 건설 기성청구 프로세스:
*   1. 기성검사 완료 후 기성청구서 발행
*   2. AR Invoice 생성 (PROG 유형)
*   3. FI 전기: 차) 매출채권 / 대) 건설공사수익 + 부가세예수금
*   4. 수금 시: 차) 현금/보통예금 / 대) 매출채권
*   5. 선수금 정산: 차) 선수금 / 대) 매출채권
*&---------------------------------------------------------------------*

PROGRAM zfi_ar_invoice_ddl.

" 매출전표 헤더
TYPES: BEGIN OF ty_fi_ar_invoice,
         mandt         TYPE mandt,
         bukrs         TYPE bukrs,
         ar_invno      TYPE c LENGTH 10,
         gjahr         TYPE gjahr,
         kunnr         TYPE kunnr,
         belnr         TYPE belnr_d,
         bldat         TYPE bldat,
         budat         TYPE budat,
         xblnr         TYPE xblnr,
         bktxt         TYPE bktxt,
         waers         TYPE waers,
         gross_amount  TYPE p LENGTH 15 DECIMALS 2,
         net_amount    TYPE p LENGTH 15 DECIMALS 2,
         tax_amount    TYPE p LENGTH 15 DECIMALS 2,
         zterm         TYPE dzterm,
         zfbdt         TYPE dzfbdt,
         due_date      TYPE datum,
         rcv_status    TYPE c LENGTH 1,
         rcvd_amount   TYPE p LENGTH 15 DECIMALS 2,
         rcvd_date     TYPE datum,
         rcv_belnr     TYPE belnr_d,
         proj_id       TYPE n LENGTH 10,
         contract_no   TYPE c LENGTH 20,
         bill_type     TYPE c LENGTH 4,
         work_from     TYPE datum,
         work_to       TYPE datum,
         progress_rate TYPE p LENGTH 5 DECIMALS 2,
         created_by    TYPE uname,
         created_at    TYPE timestamp,
       END OF ty_fi_ar_invoice.

" 매출전표 아이템
TYPES: BEGIN OF ty_fi_ar_item,
         mandt        TYPE mandt,
         bukrs        TYPE bukrs,
         ar_invno     TYPE c LENGTH 10,
         gjahr        TYPE gjahr,
         ar_itemno    TYPE n LENGTH 3,
         saknr        TYPE saknr,
         item_text    TYPE c LENGTH 50,
         net_amount   TYPE p LENGTH 15 DECIMALS 2,
         tax_code     TYPE mwskz,
         tax_amount   TYPE p LENGTH 15 DECIMALS 2,
         gross_amount TYPE p LENGTH 15 DECIMALS 2,
         prctr        TYPE prctr,
         work_desc    TYPE c LENGTH 100,
       END OF ty_fi_ar_item.

CONSTANTS:
  gc_rcv_open  TYPE c LENGTH 1 VALUE ' ',    " 미수금
  gc_rcv_part  TYPE c LENGTH 1 VALUE 'P',    " 부분수금
  gc_rcv_full  TYPE c LENGTH 1 VALUE 'F',    " 완전수금
  gc_rcv_bad   TYPE c LENGTH 1 VALUE 'D',    " 대손처리
  gc_bill_prog TYPE c LENGTH 4 VALUE 'PROG', " 기성청구
  gc_bill_finl TYPE c LENGTH 4 VALUE 'FINL', " 최종청구
  gc_bill_addl TYPE c LENGTH 4 VALUE 'ADDL', " 추가공사
  gc_bill_retd TYPE c LENGTH 4 VALUE 'RETD'. " 하자보수
