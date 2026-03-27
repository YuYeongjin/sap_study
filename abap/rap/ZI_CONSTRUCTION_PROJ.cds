/*+-----------------------------------------------------------------------+*/
/*| CDS View: ZI_CONSTRUCTION_PROJ                                        |*/
/*| Description: 건설 프로젝트 인터페이스 CDS View (RAP 모델)              |*/
/*| 트랜잭션: ABAP Development Tools (ADT) 에서 New > Core Data Services  |*/
/*+-----------------------------------------------------------------------+*/

@AbapCatalog.sqlViewName: 'ZV_CONSTR_PROJ'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: '건설 프로젝트 인터페이스 뷰'
@Search.searchable: true
@OData.publish: true

define view ZI_CONSTRUCTION_PROJ
  as select from zconstruction_proj as Proj
{
  key Proj.project_id       as ProjectId,
      Proj.project_code     as ProjectCode,
      @Search.defaultSearchElement: true
      Proj.project_name     as ProjectName,
      Proj.location         as Location,
      Proj.client           as Client,
      @UI.selectionField: [{ position: 10 }]
      Proj.project_type     as ProjectType,
      @UI.selectionField: [{ position: 20 }]
      Proj.status           as Status,

      @Semantics.amount.currencyCode: 'Waers'
      Proj.contract_amt     as ContractAmt,
      @Semantics.amount.currencyCode: 'Waers'
      Proj.budget           as Budget,
      @Semantics.amount.currencyCode: 'Waers'
      Proj.exec_budget      as ExecBudget,
      @Semantics.amount.currencyCode: 'Waers'
      Proj.actual_cost      as ActualCost,
      @Semantics.currencyCode: true
      Proj.waers            as Waers,

      @Semantics.businessDate.from: true
      Proj.start_date       as StartDate,
      Proj.plan_end_date    as PlanEndDate,
      Proj.actual_end_date  as ActualEndDate,
      Proj.progress_rate    as ProgressRate,
      Proj.site_manager     as SiteManager,
      Proj.created_by       as CreatedBy,
      Proj.created_at       as CreatedAt,

      /* 계산 필드: 예산 집행률 */
      case
        when Proj.budget > 0
        then cast( Proj.actual_cost * 100 / Proj.budget as abap.dec(5,2) )
        else cast( 0 as abap.dec(5,2) )
      end                   as BudgetExecutionRate,

      /* 계산 필드: 계약 대비 잔여 예산 */
      Proj.budget - Proj.actual_cost as RemainingBudget
}
