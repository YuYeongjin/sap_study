*&---------------------------------------------------------------------*
*& Table Definition: ZCONSTRUCTION_COST
*& Description    : 원가 전표 테이블 (CO 모듈)
*& SE11 에서 Transparent Table 로 생성
*&---------------------------------------------------------------------*
*
* Table Name  : ZCONSTRUCTION_COST
* Description : Construction Cost Entry
*
* Fields:
* ----------------------------------------------------------------
* Field Name       Key  Data Type  Length  Description
* ----------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* COST_ID          X    NUMC       10      원가전표 ID
* ENTRY_NUMBER         CHAR       20      전표번호
* PROJECT_ID           NUMC       10      프로젝트 ID → FK ZCONSTRUCTION_PROJ
* COST_TYPE            CHAR       20      원가 유형
* COST_ACCOUNT         CHAR       20      원가계정
* ENTRY_DATE           DATS       8       전표일
* AMOUNT               CURR       15      금액 (WAERS)
* QUANTITY             QUAN       13      수량
* UNIT                 UNIT       3       단위
* UNIT_PRICE           CURR       15      단가 (WAERS)
* DESCRIPTION          CHAR       500     설명
* DOCUMENT_NO          CHAR       20      참조 문서번호
* WAERS                CUKY       5       통화키
* CREATED_BY           CHAR       12      생성자
* CREATED_AT           DEC        15      생성일시
* ----------------------------------------------------------------
*
* Allowed values for COST_TYPE:
*   'LABOR'           - 노무비
*   'MATERIAL'        - 재료비
*   'EQUIPMENT_COST'  - 장비비
*   'SUBCONTRACT'     - 외주비
*   'OVERHEAD'        - 경비
*   'INDIRECT'        - 간접비
*
* 비즈니스 로직:
*   - AMOUNT = QUANTITY * UNIT_PRICE (수량 × 단가 자동계산)
*   - 저장 시 ZCONSTRUCTION_PROJ.ACTUAL_COST 자동 갱신
*&---------------------------------------------------------------------*

PROGRAM zconstruction_cost_ddl.

TYPES: BEGIN OF ty_construction_cost,
         mandt       TYPE mandt,
         cost_id     TYPE n LENGTH 10,
         entry_number TYPE c LENGTH 20,
         project_id  TYPE n LENGTH 10,
         cost_type   TYPE c LENGTH 20,
         cost_account TYPE c LENGTH 20,
         entry_date  TYPE datum,
         amount      TYPE p LENGTH 15 DECIMALS 2,
         quantity    TYPE p LENGTH 13 DECIMALS 3,
         unit        TYPE t006-msehi,
         unit_price  TYPE p LENGTH 15 DECIMALS 2,
         description TYPE c LENGTH 500,
         document_no TYPE c LENGTH 20,
         waers       TYPE waers,
         created_by  TYPE uname,
         created_at  TYPE timestamp,
       END OF ty_construction_cost.

CONSTANTS:
  gc_ctype_labor        TYPE c LENGTH 20 VALUE 'LABOR',
  gc_ctype_material     TYPE c LENGTH 20 VALUE 'MATERIAL',
  gc_ctype_equipment    TYPE c LENGTH 20 VALUE 'EQUIPMENT_COST',
  gc_ctype_subcontract  TYPE c LENGTH 20 VALUE 'SUBCONTRACT',
  gc_ctype_overhead     TYPE c LENGTH 20 VALUE 'OVERHEAD',
  gc_ctype_indirect     TYPE c LENGTH 20 VALUE 'INDIRECT'.
