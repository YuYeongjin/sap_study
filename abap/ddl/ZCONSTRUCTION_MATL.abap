*&---------------------------------------------------------------------*
*& Table Definition: ZCONSTRUCTION_MATL
*& Description    : 자재 마스터 테이블 (MM 모듈)
*& SE11 에서 Transparent Table 로 생성
*&---------------------------------------------------------------------*
*
* Table Name  : ZCONSTRUCTION_MATL
* Description : Construction Material Master
*
* Fields:
* ----------------------------------------------------------------
* Field Name       Key  Data Type  Length  Description
* ----------------------------------------------------------------
* MANDT            X    CLNT       3       클라이언트
* MATERIAL_ID      X    NUMC       10      자재 ID
* MATERIAL_CODE        CHAR       20      자재 코드
* MATERIAL_NAME        CHAR       200     자재명
* CATEGORY             CHAR       20      자재 카테고리
* SPECIFICATION        CHAR       300     규격
* UNIT                 UNIT       3       단위
* STANDARD_PRICE       CURR       15      표준단가 (WAERS)
* STOCK_QTY            QUAN       13      재고수량 (UNIT)
* SAFETY_STOCK         QUAN       13      안전재고 (UNIT)
* PRIMARY_VENDOR       CHAR       100     주공급업체
* LEAD_TIME_DAYS       INT2       5       리드타임(일)
* WAERS                CUKY       5       통화키
* CREATED_BY           CHAR       12      생성자
* CREATED_AT           DEC        15      생성일시
* ----------------------------------------------------------------
*
* Allowed values for CATEGORY:
*   'STEEL'      - 철강재
*   'CONCRETE'   - 콘크리트
*   'WOOD'       - 목재
*   'ELECTRICAL' - 전기자재
*   'PIPING'     - 배관자재
*   'FINISHING'  - 마감자재
*   'EQUIPMENT'  - 장비
*   'SAFETY'     - 안전용품
*   'CHEMICAL'   - 화학재료
*   'OTHER'      - 기타
*&---------------------------------------------------------------------*

PROGRAM zconstruction_matl_ddl.

TYPES: BEGIN OF ty_construction_matl,
         mandt          TYPE mandt,
         material_id    TYPE n LENGTH 10,
         material_code  TYPE c LENGTH 20,
         material_name  TYPE c LENGTH 200,
         category       TYPE c LENGTH 20,
         specification  TYPE c LENGTH 300,
         unit           TYPE t006-msehi,
         standard_price TYPE p LENGTH 15 DECIMALS 2,
         stock_qty      TYPE p LENGTH 13 DECIMALS 3,
         safety_stock   TYPE p LENGTH 13 DECIMALS 3,
         primary_vendor TYPE c LENGTH 100,
         lead_time_days TYPE i,
         waers          TYPE waers,
         created_by     TYPE uname,
         created_at     TYPE timestamp,
       END OF ty_construction_matl.

CONSTANTS:
  gc_cat_steel      TYPE c LENGTH 20 VALUE 'STEEL',
  gc_cat_concrete   TYPE c LENGTH 20 VALUE 'CONCRETE',
  gc_cat_wood       TYPE c LENGTH 20 VALUE 'WOOD',
  gc_cat_electrical TYPE c LENGTH 20 VALUE 'ELECTRICAL',
  gc_cat_piping     TYPE c LENGTH 20 VALUE 'PIPING',
  gc_cat_finishing  TYPE c LENGTH 20 VALUE 'FINISHING',
  gc_cat_equipment  TYPE c LENGTH 20 VALUE 'EQUIPMENT',
  gc_cat_safety     TYPE c LENGTH 20 VALUE 'SAFETY',
  gc_cat_chemical   TYPE c LENGTH 20 VALUE 'CHEMICAL',
  gc_cat_other      TYPE c LENGTH 20 VALUE 'OTHER'.
