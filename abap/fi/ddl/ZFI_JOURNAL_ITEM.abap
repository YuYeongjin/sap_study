*&---------------------------------------------------------------------*
*& Table Definition: ZFI_JOURNAL_ITEM
*& Description    : 회계전표 라인항목 (Journal Entry Line Item)
*& Transaction    : SE11 → Transparent Table
*&---------------------------------------------------------------------*
*
* Table Name  : ZFI_JOURNAL_ITEM
* Description : FI Journal Entry Line Item
*
* Fields:
* -----------------------------------------------------------------------
* Field Name       Key  Data Type  Length  Description
* -----------------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* BUKRS            X    CHAR       4       회사코드
* BELNR            X    CHAR       10      전표번호
* GJAHR            X    NUMC       4       회계연도
* BUZEI            X    NUMC       3       항목번호 (Line Item Number, 001~999)
* BUZID                 CHAR       1       항목분류
* SAKNR                 CHAR       10      계정번호 (GL Account)
* SHKZG                 CHAR       1       차/대변 구분 (S=차변 Debit, H=대변 Credit)
* DMBTR                 CURR       15      전표금액(회사통화) (Amount in Company Currency)
* WRBTR                 CURR       15      전표금액(전표통화) (Amount in Document Currency)
* MWSKZ                 CHAR       2       세금코드 (Tax Code)
* MWSTS                 CURR       15      세액(회사통화)
* WMWST                 CURR       15      세액(전표통화)
* KOSTL                 CHAR       10      코스트센터 (Cost Center)
* AUFNR                 CHAR       12      내부오더번호 (Internal Order)
* PRCTR                 CHAR       18      수익센터 (Profit Center)
* PS_POSID              CHAR       24      WBS 요소
* MATNR                 CHAR       18      자재번호
* ANLN1                 CHAR       12      자산번호 (Asset)
* ANLN2                 CHAR       4       자산부번
* ZTERM                 CHAR       4       지급조건 (Payment Terms)
* ZFBDT                 DATS       8       기준일 (Baseline Date)
* ZBD1T                 DEC        3       할인일수1
* ZBD1P                 DEC        5       할인율1
* ZLSCH                 CHAR       1       지급방법 (Payment Method)
* ZLZLD                 NUMC       3       지급블록 지시자
* AUGDT                 DATS       8       결제일 (Clearing Date)
* AUGBL                 CHAR       10      결제전표번호
* AUGGJ                 NUMC       4       결제전표 회계연도
* SGTXT                 CHAR       50      항목 텍스트 (Item Text)
* LIFNR                 CHAR       10      벤더번호 (Vendor)
* KUNNR                 CHAR       10      고객번호 (Customer)
* -----------------------------------------------------------------------
*
* 복식부기 원칙:
*   - 모든 전표의 차변합계 = 대변합계
*   - SHKZG='S' → 차변 (Debit)
*   - SHKZG='H' → 대변 (Credit)
*
* 건설회사 회계처리 예시:
*   [자재 매입]
*     차) 재료비(502000) 10,000,000 / 대) 매입채무(201000) 10,000,000
*   [공사대금 청구]
*     차) 매출채권(102000) 11,000,000 / 대) 건설공사수익(401000) 10,000,000
*                                      대) 부가세예수금(202500) 1,000,000
*   [노무비 지급]
*     차) 노무비(501000) 5,000,000 / 대) 현금(101000) 5,000,000
*&---------------------------------------------------------------------*

PROGRAM zfi_journal_item_ddl.

TYPES: BEGIN OF ty_fi_journal_item,
         mandt    TYPE mandt,
         bukrs    TYPE bukrs,
         belnr    TYPE belnr_d,
         gjahr    TYPE gjahr,
         buzei    TYPE buzei,
         buzid    TYPE c LENGTH 1,
         saknr    TYPE saknr,
         shkzg    TYPE shkzg,
         dmbtr    TYPE dmbtr,
         wrbtr    TYPE wrbtr,
         mwskz    TYPE mwskz,
         mwsts    TYPE mwsts,
         wmwst    TYPE wmwst,
         kostl    TYPE kostl,
         aufnr    TYPE aufnr,
         prctr    TYPE prctr,
         ps_posid TYPE ps_posid,
         matnr    TYPE matnr,
         anln1    TYPE anln1,
         anln2    TYPE anln2,
         zterm    TYPE dzterm,
         zfbdt    TYPE dzfbdt,
         zbd1t    TYPE dzbd1t,
         zbd1p    TYPE dzbd1p,
         zlsch    TYPE dzlsch,
         augdt    TYPE augdt,
         augbl    TYPE augbl,
         auggj    TYPE gjahr,
         sgtxt    TYPE sgtxt,
         lifnr    TYPE lifnr,
         kunnr    TYPE kunnr,
       END OF ty_fi_journal_item.

CONSTANTS:
  gc_shkzg_debit  TYPE shkzg VALUE 'S',   " 차변
  gc_shkzg_credit TYPE shkzg VALUE 'H'.   " 대변
