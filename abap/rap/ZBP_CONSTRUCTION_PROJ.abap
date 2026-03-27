*&---------------------------------------------------------------------*
*& Class: ZBP_CONSTRUCTION_PROJ
*& Description: 건설 프로젝트 RAP Behavior Implementation
*& RAP (RESTful ABAP Programming Model) - Managed Behavior
*&
*& Behavior Definition (BDEF) ZB_CONSTRUCTION_PROJ 내용:
*&
*& managed;
*& define behavior for ZI_CONSTRUCTION_PROJ alias Project
*&   persistent table zconstruction_proj
*&   lock master
*&   authorization master ( instance )
*&   etag master ChangedAt
*& {
*&   field ( readonly ) ProjectId;
*&   field ( mandatory ) ProjectCode, ProjectName, Client, ProjectType, Status;
*&
*&   create;
*&   update;
*&   delete;
*&
*&   action  ( features : instance ) setInProgress result [1] $self;
*&   action  ( features : instance ) setCompleted  result [1] $self;
*&   action  ( features : instance ) setSuspended  result [1] $self;
*&
*&   determination setActualCost on save { create; update; }
*&
*&   mapping for zconstruction_proj
*&   {
*&     ProjectId    = project_id;
*&     ProjectCode  = project_code;
*&     ProjectName  = project_name;
*&     ...
*&   }
*& }
*&---------------------------------------------------------------------*

CLASS zbp_construction_proj DEFINITION
  PUBLIC
  ABSTRACT
  FINAL
  FOR BEHAVIOR OF zi_construction_proj.

  PUBLIC SECTION.

ENDCLASS.

CLASS zbp_construction_proj IMPLEMENTATION.
ENDCLASS.


*&---------------------------------------------------------------------*
*& Local Class: 실제 Behavior 구현 (ABAP 클래스 내 local)
*&---------------------------------------------------------------------*
CLASS lhc_project DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    "! 프로젝트를 '진행중' 상태로 변경
    METHODS set_in_progress FOR MODIFY
      IMPORTING keys FOR ACTION project~setInProgress RESULT result.

    "! 프로젝트를 '완료' 상태로 변경
    METHODS set_completed FOR MODIFY
      IMPORTING keys FOR ACTION project~setCompleted RESULT result.

    "! 프로젝트를 '중단' 상태로 변경
    METHODS set_suspended FOR MODIFY
      IMPORTING keys FOR ACTION project~setSuspended RESULT result.

    "! 저장 시 실적원가 자동 계산 (CO → PS 연계)
    METHODS set_actual_cost FOR DETERMINE ON SAVE
      IMPORTING keys FOR project~setActualCost.

    "! 인스턴스 기반 권한 체크
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations
      RESULT result.

    "! Action 기능 활성화 제어
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features
      RESULT result.

ENDCLASS.

CLASS lhc_project IMPLEMENTATION.

  METHOD set_in_progress.
    MODIFY ENTITIES OF zi_construction_proj IN LOCAL MODE
      ENTITY project
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR key IN keys
                      ( %tky   = key-%tky
                        Status = 'IN_PROGRESS' ) )
      REPORTED DATA(lt_reported).

    READ ENTITIES OF zi_construction_proj IN LOCAL MODE
      ENTITY project ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls IN lt_result
                      ( %tky   = ls-%tky
                        %param = ls ) ).
  ENDMETHOD.


  METHOD set_completed.
    MODIFY ENTITIES OF zi_construction_proj IN LOCAL MODE
      ENTITY project
        UPDATE FIELDS ( Status ActualEndDate )
        WITH VALUE #( FOR key IN keys
                      ( %tky           = key-%tky
                        Status         = 'COMPLETED'
                        ActualEndDate  = cl_abap_context_info=>get_system_date( ) ) )
      REPORTED DATA(lt_reported).

    READ ENTITIES OF zi_construction_proj IN LOCAL MODE
      ENTITY project ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls IN lt_result
                      ( %tky   = ls-%tky
                        %param = ls ) ).
  ENDMETHOD.


  METHOD set_suspended.
    MODIFY ENTITIES OF zi_construction_proj IN LOCAL MODE
      ENTITY project
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR key IN keys
                      ( %tky   = key-%tky
                        Status = 'SUSPENDED' ) )
      REPORTED DATA(lt_reported).

    READ ENTITIES OF zi_construction_proj IN LOCAL MODE
      ENTITY project ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls IN lt_result
                      ( %tky   = ls-%tky
                        %param = ls ) ).
  ENDMETHOD.


  METHOD set_actual_cost.
    "! 원가전표 합계를 프로젝트 실적원가에 자동 반영
    READ ENTITIES OF zi_construction_proj IN LOCAL MODE
      ENTITY project
        FIELDS ( ProjectId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_projects).

    LOOP AT lt_projects INTO DATA(ls_proj).
      DATA lv_total TYPE p LENGTH 15 DECIMALS 2.

      SELECT SUM( amount ) FROM zconstruction_cost
        WHERE project_id = @ls_proj-ProjectId
        INTO @lv_total.

      MODIFY ENTITIES OF zi_construction_proj IN LOCAL MODE
        ENTITY project
          UPDATE FIELDS ( ActualCost )
          WITH VALUE #( ( %tky       = ls_proj-%tky
                          ActualCost = lv_total ) ).
    ENDLOOP.
  ENDMETHOD.


  METHOD get_instance_authorizations.
    "! 상태에 따른 액션 권한 제어
    READ ENTITIES OF zi_construction_proj IN LOCAL MODE
      ENTITY project
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_projects).

    result = VALUE #( FOR ls IN lt_projects
                      LET is_completed = xsdbool( ls-Status = 'COMPLETED' )
                          is_suspended = xsdbool( ls-Status = 'SUSPENDED' )
                      IN
                      ( %tky                         = ls-%tky
                        %update                       = COND #( WHEN is_completed = abap_true
                                                                THEN if_abap_behv=>auth-unauthorized
                                                                ELSE if_abap_behv=>auth-allowed )
                        %delete                       = COND #( WHEN is_completed = abap_true
                                                                THEN if_abap_behv=>auth-unauthorized
                                                                ELSE if_abap_behv=>auth-allowed )
                        %action-setInProgress         = if_abap_behv=>auth-allowed
                        %action-setCompleted          = if_abap_behv=>auth-allowed
                        %action-setSuspended          = if_abap_behv=>auth-allowed ) ).
  ENDMETHOD.


  METHOD get_instance_features.
    READ ENTITIES OF zi_construction_proj IN LOCAL MODE
      ENTITY project
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_projects).

    result = VALUE #( FOR ls IN lt_projects
                      LET is_in_progress = xsdbool( ls-Status = 'IN_PROGRESS' )
                          is_completed   = xsdbool( ls-Status = 'COMPLETED' )
                      IN
                      ( %tky                 = ls-%tky
                        %action-setInProgress = COND #( WHEN is_in_progress = abap_true
                                                        THEN if_abap_behv=>fc-o-disabled
                                                        ELSE if_abap_behv=>fc-o-enabled )
                        %action-setCompleted  = COND #( WHEN is_completed = abap_true
                                                        THEN if_abap_behv=>fc-o-disabled
                                                        ELSE if_abap_behv=>fc-o-enabled )
                        %action-setSuspended  = COND #( WHEN is_completed = abap_true
                                                        THEN if_abap_behv=>fc-o-disabled
                                                        ELSE if_abap_behv=>fc-o-enabled ) ) ).
  ENDMETHOD.

ENDCLASS.
