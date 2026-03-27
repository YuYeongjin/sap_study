*&---------------------------------------------------------------------*
*& Table Definition: ZCONSTRUCTION_PO / ZCONSTRUCTION_POI
*& Description    : 구매발주 헤더/아이템 테이블 (MM 모듈)
*&---------------------------------------------------------------------*
*
* === 헤더 테이블: ZCONSTRUCTION_PO ===
* Fields:
* ----------------------------------------------------------------
* Field Name         Key  Data Type  Length  Description
* ----------------------------------------------------------------
* MANDT              X    CLNT       3       클라이언트
* PO_ID              X    NUMC       10      발주 ID
* PO_NUMBER              CHAR       20      발주번호
* PROJECT_ID             NUMC       10      프로젝트 ID → FK ZCONSTRUCTION_PROJ
* VENDOR_NAME            CHAR       100     공급업체명
* VENDOR_CODE            CHAR       20      공급업체코드
* STATUS                 CHAR       20      발주 상태
* ORDER_DATE             DATS       8       발주일
* DELIVERY_DATE          DATS       8       납기일
* DELIVERY_ADDR          CHAR       200     납품지 주소
* TOTAL_AMOUNT           CURR       15      총 발주금액 (WAERS)
* WAERS                  CUKY       5       통화키
* PURCHASER              CHAR       50      구매 담당자
* REMARKS                CHAR       500     비고
* CREATED_BY             CHAR       12      생성자
* CREATED_AT             DEC        15      생성일시
* ----------------------------------------------------------------
*
* Allowed values for STATUS:
*   'DRAFT'            - 초안
*   'PENDING'          - 승인대기
*   'APPROVED'         - 승인완료
*   'ORDERED'          - 발주완료
*   'PARTIAL_RECEIVED' - 부분입고
*   'RECEIVED'         - 입고완료
*   'CANCELLED'        - 취소
*
* === 아이템 테이블: ZCONSTRUCTION_POI ===
* Fields:
* ----------------------------------------------------------------
* MANDT              X    CLNT       3       클라이언트
* PO_ID              X    NUMC       10      발주 ID → FK ZCONSTRUCTION_PO
* ITEM_NO            X    NUMC       3       아이템 번호
* MATERIAL_ID            NUMC       10      자재 ID → FK ZCONSTRUCTION_MATL
* ITEM_DESC              CHAR       200     품목 설명
* QUANTITY               QUAN       13      발주수량 (UNIT)
* UNIT                   UNIT       3       단위
* UNIT_PRICE             CURR       15      단가 (WAERS)
* SUPPLY_AMOUNT          CURR       15      공급가액 (= QTY * PRICE)
* VAT_AMOUNT             CURR       15      부가세 (= SUPPLY * 10%)
* TOTAL_AMOUNT           CURR       15      합계 (= SUPPLY + VAT)
* RECEIVED_QTY           QUAN       13      입고수량
* WAERS                  CUKY       5       통화키
* ----------------------------------------------------------------
*&---------------------------------------------------------------------*

PROGRAM zconstruction_po_ddl.

* === 헤더 구조체 ===
TYPES: BEGIN OF ty_construction_po,
         mandt         TYPE mandt,
         po_id         TYPE n LENGTH 10,
         po_number     TYPE c LENGTH 20,
         project_id    TYPE n LENGTH 10,
         vendor_name   TYPE c LENGTH 100,
         vendor_code   TYPE c LENGTH 20,
         status        TYPE c LENGTH 20,
         order_date    TYPE datum,
         delivery_date TYPE datum,
         delivery_addr TYPE c LENGTH 200,
         total_amount  TYPE p LENGTH 15 DECIMALS 2,
         waers         TYPE waers,
         purchaser     TYPE c LENGTH 50,
         remarks       TYPE c LENGTH 500,
         created_by    TYPE uname,
         created_at    TYPE timestamp,
       END OF ty_construction_po.

* === 아이템 구조체 ===
TYPES: BEGIN OF ty_construction_poi,
         mandt         TYPE mandt,
         po_id         TYPE n LENGTH 10,
         item_no       TYPE n LENGTH 3,
         material_id   TYPE n LENGTH 10,
         item_desc     TYPE c LENGTH 200,
         quantity      TYPE p LENGTH 13 DECIMALS 3,
         unit          TYPE t006-msehi,
         unit_price    TYPE p LENGTH 15 DECIMALS 2,
         supply_amount TYPE p LENGTH 15 DECIMALS 2,
         vat_amount    TYPE p LENGTH 15 DECIMALS 2,
         total_amount  TYPE p LENGTH 15 DECIMALS 2,
         received_qty  TYPE p LENGTH 13 DECIMALS 3,
         waers         TYPE waers,
       END OF ty_construction_poi.

CONSTANTS:
  gc_po_draft            TYPE c LENGTH 20 VALUE 'DRAFT',
  gc_po_pending          TYPE c LENGTH 20 VALUE 'PENDING',
  gc_po_approved         TYPE c LENGTH 20 VALUE 'APPROVED',
  gc_po_ordered          TYPE c LENGTH 20 VALUE 'ORDERED',
  gc_po_partial_received TYPE c LENGTH 20 VALUE 'PARTIAL_RECEIVED',
  gc_po_received         TYPE c LENGTH 20 VALUE 'RECEIVED',
  gc_po_cancelled        TYPE c LENGTH 20 VALUE 'CANCELLED'.
