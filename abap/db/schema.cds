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
    
    // 금액 관련 필드
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
// (신규) 자재 마스터 테이블 추가
entity ZCONSTRUCTION_MATL : managed {
    key MaterialId      : UUID;
    MaterialCode        : String(20);
    MaterialName        : String(100);
    Unit                : String(10);
    UnitPrice           : Decimal(15, 2);
}

// (신규) 발주 테이블 추가
entity ZCONSTRUCTION_PO : managed {
    key PoId            : UUID;
    PoNumber            : String(20);
    Vendor              : String(100);
    TotalAmount         : Decimal(15, 2);
    Status              : String(10);
}
/* 2. 외부 노출용 서비스 정의 (Service Layer) */
@path: '/sap/bc/zconstruction'
service ConstructionService {
    
    // 1. 리액트가 호출하는 /projects 경로 대응
    // 필드명을 소문자로 별칭(Alias) 처리하여 리액트와의 연동성을 높였습니다.
    entity projects as select from ZCONSTRUCTION_PROJ {
        ProjectId as id,
        ProjectCode as projectCode, 
        ProjectName as projectName,
        Location as location,
        Client as client,
        ProjectType as projectType,
        Status as status,
        ContractAmt as contractAmount,
        Budget as budget,
        ActualCost as actualCost,
        Waers as currency,
        StartDate as startDate,
        PlanEndDate as endDate,
        ProgressRate as progress,
        /* 계산 필드 */
        case 
            when Budget > 0 then cast((ActualCost * 100 / Budget) as Decimal(5,2))
            else 0 
        end as budgetExecutionRate : Decimal(5, 2),
        (Budget - ActualCost) as remainingBudget : Decimal(15, 2)
    };

    // 2. 하이픈(-)이 들어간 엔티티는 반드시 ![ ] 문법을 사용해야 에러가 없습니다.
    @readonly
    entity ![cost-entries] as select from ZCONSTRUCTION_PROJ {
        key ProjectId as id,
        ActualCost as amount,
        'Summary' as description
    };

    // 기존 인터페이스 유지
    entity ProjectInterface as projection on projects;
}