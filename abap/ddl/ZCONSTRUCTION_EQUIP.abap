*&---------------------------------------------------------------------*
*& Table Definition: ZCONSTRUCTION_EQUIP
*& Description    : 장비 마스터 테이블 (PM 모듈)
*& SE11 에서 Transparent Table 로 생성
*&---------------------------------------------------------------------*
*
* Table Name  : ZCONSTRUCTION_EQUIP
* Description : Construction Equipment Master
*
* Fields:
* ----------------------------------------------------------------
* Field Name         Key  Data Type  Length  Description
* ----------------------------------------------------------------
* MANDT              X    CLNT       3       클라이언트
* EQUIPMENT_ID       X    NUMC       10      장비 ID
* EQUIPMENT_CODE         CHAR       20      장비 코드
* EQUIPMENT_NAME         CHAR       200     장비명
* EQUIPMENT_TYPE         CHAR       20      장비 유형
* MODEL                  CHAR       100     모델명
* MANUFACTURER           CHAR       100     제조사
* REGISTRATION_NO        CHAR       20      등록번호
* STATUS                 CHAR       20      상태
* CURRENT_PROJECT        NUMC       10      현재 프로젝트 ID → FK ZCONSTRUCTION_PROJ
* ACQUISITION_DATE       DATS       8       취득일
* ACQUISITION_COST       CURR       15      취득원가 (WAERS)
* IS_RENTED              CHAR       1       임대여부 (X/공백)
* RENTAL_COST_DAY        CURR       15      일 임대료 (WAERS)
* NEXT_MAINT_DATE        DATS       8       다음 점검일
* TOTAL_OP_HOURS         DEC        10      총 가동시간
* WAERS                  CUKY       5       통화키
* CREATED_BY             CHAR       12      생성자
* CREATED_AT             DEC        15      생성일시
* ----------------------------------------------------------------
*
* Allowed values for EQUIPMENT_TYPE:
*   'EXCAVATOR'      - 굴착기
*   'CRANE'          - 크레인
*   'DUMP_TRUCK'     - 덤프트럭
*   'CONCRETE_PUMP'  - 콘크리트 펌프
*   'BULLDOZER'      - 불도저
*   'FORKLIFT'       - 지게차
*   'ROLLER'         - 다짐기
*   'COMPRESSOR'     - 압축기
*   'GENERATOR'      - 발전기
*
* Allowed values for STATUS:
*   'AVAILABLE'   - 사용가능
*   'IN_USE'      - 사용중
*   'MAINTENANCE' - 점검중
*   'BROKEN'      - 고장
*   'DISPOSED'    - 폐기
*&---------------------------------------------------------------------*

PROGRAM zconstruction_equip_ddl.

TYPES: BEGIN OF ty_construction_equip,
         mandt           TYPE mandt,
         equipment_id    TYPE n LENGTH 10,
         equipment_code  TYPE c LENGTH 20,
         equipment_name  TYPE c LENGTH 200,
         equipment_type  TYPE c LENGTH 20,
         model           TYPE c LENGTH 100,
         manufacturer    TYPE c LENGTH 100,
         registration_no TYPE c LENGTH 20,
         status          TYPE c LENGTH 20,
         current_project TYPE n LENGTH 10,
         acquisition_date TYPE datum,
         acquisition_cost TYPE p LENGTH 15 DECIMALS 2,
         is_rented       TYPE abap_bool,
         rental_cost_day TYPE p LENGTH 15 DECIMALS 2,
         next_maint_date TYPE datum,
         total_op_hours  TYPE p LENGTH 10 DECIMALS 1,
         waers           TYPE waers,
         created_by      TYPE uname,
         created_at      TYPE timestamp,
       END OF ty_construction_equip.

CONSTANTS:
  gc_etype_excavator     TYPE c LENGTH 20 VALUE 'EXCAVATOR',
  gc_etype_crane         TYPE c LENGTH 20 VALUE 'CRANE',
  gc_etype_dump_truck    TYPE c LENGTH 20 VALUE 'DUMP_TRUCK',
  gc_etype_concrete_pump TYPE c LENGTH 20 VALUE 'CONCRETE_PUMP',
  gc_etype_bulldozer     TYPE c LENGTH 20 VALUE 'BULLDOZER',
  gc_etype_forklift      TYPE c LENGTH 20 VALUE 'FORKLIFT',
  gc_etype_roller        TYPE c LENGTH 20 VALUE 'ROLLER',
  gc_etype_compressor    TYPE c LENGTH 20 VALUE 'COMPRESSOR',
  gc_etype_generator     TYPE c LENGTH 20 VALUE 'GENERATOR'.

CONSTANTS:
  gc_estat_available   TYPE c LENGTH 20 VALUE 'AVAILABLE',
  gc_estat_in_use      TYPE c LENGTH 20 VALUE 'IN_USE',
  gc_estat_maintenance TYPE c LENGTH 20 VALUE 'MAINTENANCE',
  gc_estat_broken      TYPE c LENGTH 20 VALUE 'BROKEN',
  gc_estat_disposed    TYPE c LENGTH 20 VALUE 'DISPOSED'.
