namespace zconstruction;

using { managed, Currency } from '@sap/cds/common';

/* 1. 실제 DB 테이블 정의 (Entity) */
entity ZCONSTRUCTION_PROJ : managed {
    key ProjectId       : UUID;
    ProjectCode         : String(20);
    ProjectName         : String(100);
    Location            : String(100);
    Client              : String(50);
    ProjectType         : String(20);
    Status              : String(10);
    
    // 금액 관련 필드 (Currency 타입 활용)
    ContractAmt         : Decimal(15, 2);
    Budget              : Decimal(15, 2);
    ExecBudget          : Decimal(15, 2);
    ActualCost          : Decimal(15, 2);
    Waers               : Currency; // 통화 코드

    StartDate           : Date;
    PlanEndDate         : Date;
    ActualEndDate       : Date;
    ProgressRate        : Decimal(5, 2);
    SiteManager         : String(50);
}

/* 2. 외부 노출용 서비스 정의 (Service Layer) */
@path: '/sap/bc/zconstruction'
service ConstructionService {
    
    // 1. 리액트가 호출하는 /projects 경로 대응
    entity projects as select from ZCONSTRUCTION_PROJ {
        *,
        case 
            when Budget > 0 then cast((ActualCost * 100 / Budget) as Decimal(5,2))
            else 0 
        end as BudgetExecutionRate : Decimal(5, 2),
        (Budget - ActualCost) as RemainingBudget : Decimal(15, 2)
    };

    // 2. 리액트가 호출하는 /cost-entries 경로 대응 (임시 엔티티)
    @readonly
    entity "cost-entries" as select from ZCONSTRUCTION_PROJ {
        key ProjectId as ID,
        ActualCost as amount,
        'Summary' as description
    };

    // 기존에 만든 것도 유지하고 싶다면
    entity ProjectInterface as projection on projects;
}