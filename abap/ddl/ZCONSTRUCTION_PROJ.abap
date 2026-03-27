*&---------------------------------------------------------------------*
*& Table Definition: ZCONSTRUCTION_PROJ
*& Description    : 건설 프로젝트 마스터 테이블 (PS 모듈)
*& SE11 에서 Transparent Table 로 생성
*&---------------------------------------------------------------------*
*
* === SE11 Table Field Definitions ===
*
* Table Name  : ZCONSTRUCTION_PROJ
* Description : Construction Project Master
* Delivery Cl.: A (Application Table)
* Data Class  : APPL0
* Size Categ. : 0
*
* Fields:
* ----------------------------------------------------------------
* Field Name       Key  Data Element         Data Type  Length
* ----------------------------------------------------------------
* MANDT            X    MANDT                CLNT       3
* PROJECT_ID       X    ZCONSTRUCTION_PROJID NUMC       10
* PROJECT_CODE         ZCONSTRUCTION_CODE   CHAR       20
* PROJECT_NAME         ZCONSTRUCTION_NAME   CHAR       200
* LOCATION             ZCONSTRUCTION_ADDR   CHAR       200
* CLIENT               ZCONSTRUCTION_CLIENT CHAR       100
* PROJECT_TYPE         ZCONSTRUCTION_PROJTP CHAR       20
* STATUS               ZCONSTRUCTION_STATUS CHAR       20
* CONTRACT_AMT         ZCONSTRUCTION_AMT    CURR       15  (WAERS)
* BUDGET               ZCONSTRUCTION_AMT    CURR       15  (WAERS)
* EXEC_BUDGET          ZCONSTRUCTION_AMT    CURR       15  (WAERS)
* ACTUAL_COST          ZCONSTRUCTION_AMT    CURR       15  (WAERS)
* WAERS                WAERS                CUKY       5
* START_DATE           DATUM                DATS       8
* PLAN_END_DATE        DATUM                DATS       8
* ACTUAL_END_DATE      DATUM                DATS       8
* PROGRESS_RATE        ZCONSTRUCTION_RATE   DEC        5   (2 decimal)
* SITE_MANAGER         ZCONSTRUCTION_PERSON CHAR       50
* CREATED_BY           UNAME                CHAR       12
* CREATED_AT           TIMESTAMP            DEC        15
* CHANGED_BY           UNAME                CHAR       12
* CHANGED_AT           TIMESTAMP            DEC        15
* ----------------------------------------------------------------
*
* Allowed values for PROJECT_TYPE:
*   'CIVIL'       - 토목공사
*   'BUILDING'    - 건축공사
*   'PLANT'       - 플랜트공사
*   'ELECTRICAL'  - 전기공사
*   'MECHANICAL'  - 기계공사
*
* Allowed values for STATUS:
*   'PLANNING'    - 계획
*   'BIDDING'     - 입찰
*   'CONTRACTED'  - 계약완료
*   'IN_PROGRESS' - 진행중
*   'COMPLETED'   - 완료
*   'SUSPENDED'   - 중단
*
*&---------------------------------------------------------------------*
*& Number Range Object: ZCONSTRUCTION_PROJ
*& Number Range Interval: 01 → 0000000001 ~ 9999999999
*&---------------------------------------------------------------------*

"! <p class="shortText">건설 프로젝트 마스터 테이블 정의 보조 프로그램</p>
PROGRAM zconstruction_proj_ddl.

* === 테이블 구조 참조용 구조체 ===
TYPES: BEGIN OF ty_construction_proj,
         mandt           TYPE mandt,
         project_id      TYPE n LENGTH 10,
         project_code    TYPE c LENGTH 20,
         project_name    TYPE c LENGTH 200,
         location        TYPE c LENGTH 200,
         client          TYPE c LENGTH 100,
         project_type    TYPE c LENGTH 20,
         status          TYPE c LENGTH 20,
         contract_amt    TYPE p LENGTH 15 DECIMALS 2,
         budget          TYPE p LENGTH 15 DECIMALS 2,
         exec_budget     TYPE p LENGTH 15 DECIMALS 2,
         actual_cost     TYPE p LENGTH 15 DECIMALS 2,
         waers           TYPE waers,
         start_date      TYPE datum,
         plan_end_date   TYPE datum,
         actual_end_date TYPE datum,
         progress_rate   TYPE p LENGTH 5 DECIMALS 2,
         site_manager    TYPE c LENGTH 50,
         created_by      TYPE uname,
         created_at      TYPE timestamp,
         changed_by      TYPE uname,
         changed_at      TYPE timestamp,
       END OF ty_construction_proj.

* === 허용값 상수 (PROJECT_TYPE) ===
CONSTANTS:
  gc_type_civil      TYPE c LENGTH 20 VALUE 'CIVIL',
  gc_type_building   TYPE c LENGTH 20 VALUE 'BUILDING',
  gc_type_plant      TYPE c LENGTH 20 VALUE 'PLANT',
  gc_type_electrical TYPE c LENGTH 20 VALUE 'ELECTRICAL',
  gc_type_mechanical TYPE c LENGTH 20 VALUE 'MECHANICAL'.

* === 허용값 상수 (STATUS) ===
CONSTANTS:
  gc_stat_planning    TYPE c LENGTH 20 VALUE 'PLANNING',
  gc_stat_bidding     TYPE c LENGTH 20 VALUE 'BIDDING',
  gc_stat_contracted  TYPE c LENGTH 20 VALUE 'CONTRACTED',
  gc_stat_in_progress TYPE c LENGTH 20 VALUE 'IN_PROGRESS',
  gc_stat_completed   TYPE c LENGTH 20 VALUE 'COMPLETED',
  gc_stat_suspended   TYPE c LENGTH 20 VALUE 'SUSPENDED'.
