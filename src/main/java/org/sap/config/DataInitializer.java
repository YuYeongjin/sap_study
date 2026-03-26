package org.sap.config;

import lombok.RequiredArgsConstructor;
import org.sap.model.*;
import org.sap.repository.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 학습용 초기 데이터 설정
 */
@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final ProjectRepository projectRepository;
    private final MaterialRepository materialRepository;
    private final PurchaseOrderRepository purchaseOrderRepository;
    private final EquipmentRepository equipmentRepository;
    private final CostEntryRepository costEntryRepository;

    @Override
    public void run(String... args) {
        initProjects();
        initMaterials();
        initEquipment();
        initPurchaseOrders();
        initCostEntries();
    }

    private void initProjects() {
        Project p1 = Project.builder()
                .projectCode("PRJ-2024-001")
                .projectName("서울 강남 주상복합 신축공사")
                .location("서울시 강남구 역삼동 123-4")
                .client("강남개발(주)")
                .projectType(Project.ProjectType.BUILDING)
                .status(Project.ProjectStatus.IN_PROGRESS)
                .contractAmount(new BigDecimal("85000000000"))
                .budget(new BigDecimal("78000000000"))
                .executionBudget(new BigDecimal("75000000000"))
                .actualCost(new BigDecimal("42500000000"))
                .startDate(LocalDate.of(2024, 3, 1))
                .plannedEndDate(LocalDate.of(2026, 6, 30))
                .progressRate(52)
                .siteManager("김현장")
                .build();

        Project p2 = Project.builder()
                .projectCode("PRJ-2024-002")
                .projectName("인천 제2경인고속도로 교량 공사")
                .location("인천시 남동구 ~ 부평구")
                .client("한국도로공사")
                .projectType(Project.ProjectType.CIVIL)
                .status(Project.ProjectStatus.IN_PROGRESS)
                .contractAmount(new BigDecimal("125000000000"))
                .budget(new BigDecimal("118000000000"))
                .executionBudget(new BigDecimal("115000000000"))
                .actualCost(new BigDecimal("28750000000"))
                .startDate(LocalDate.of(2024, 1, 15))
                .plannedEndDate(LocalDate.of(2027, 12, 31))
                .progressRate(23)
                .siteManager("박도로")
                .build();

        Project p3 = Project.builder()
                .projectCode("PRJ-2023-015")
                .projectName("여수 화학공장 플랜트 증설공사")
                .location("전남 여수시 삼일동 공단내")
                .client("여수석유화학(주)")
                .projectType(Project.ProjectType.PLANT)
                .status(Project.ProjectStatus.COMPLETED)
                .contractAmount(new BigDecimal("34000000000"))
                .budget(new BigDecimal("32000000000"))
                .executionBudget(new BigDecimal("31500000000"))
                .actualCost(new BigDecimal("31200000000"))
                .startDate(LocalDate.of(2023, 6, 1))
                .plannedEndDate(LocalDate.of(2024, 8, 31))
                .actualEndDate(LocalDate.of(2024, 9, 15))
                .progressRate(100)
                .siteManager("이플랜트")
                .build();

        Project p4 = Project.builder()
                .projectCode("PRJ-2025-001")
                .projectName("부산 스마트시티 전기 인프라 구축")
                .location("부산시 강서구 명지지구")
                .client("부산광역시")
                .projectType(Project.ProjectType.ELECTRICAL)
                .status(Project.ProjectStatus.CONTRACTED)
                .contractAmount(new BigDecimal("18500000000"))
                .budget(new BigDecimal("17000000000"))
                .executionBudget(new BigDecimal("16500000000"))
                .actualCost(BigDecimal.ZERO)
                .startDate(LocalDate.of(2025, 4, 1))
                .plannedEndDate(LocalDate.of(2026, 3, 31))
                .progressRate(0)
                .siteManager("최전기")
                .build();

        projectRepository.save(p1);
        projectRepository.save(p2);
        projectRepository.save(p3);
        projectRepository.save(p4);
    }

    private void initMaterials() {
        materialRepository.save(Material.builder()
                .materialCode("MAT-0001")
                .materialName("고강도 철근 (HD25)")
                .category(Material.MaterialCategory.STEEL)
                .specification("HD25, KS D 3504, 항복강도 400MPa")
                .unit("TON")
                .standardPrice(new BigDecimal("950000"))
                .stockQuantity(new BigDecimal("125.5"))
                .safetyStock(new BigDecimal("50"))
                .primaryVendor("현대제철(주)")
                .leadTimeDays(14)
                .build());

        materialRepository.save(Material.builder()
                .materialCode("MAT-0002")
                .materialName("레미콘 (25-24-150)")
                .category(Material.MaterialCategory.CONCRETE)
                .specification("설계기준강도 25MPa, 굵은골재 24mm, 슬럼프 150mm")
                .unit("M3")
                .standardPrice(new BigDecimal("95000"))
                .stockQuantity(new BigDecimal("0"))
                .safetyStock(new BigDecimal("0"))
                .primaryVendor("삼표레미콘(주)")
                .leadTimeDays(1)
                .build());

        materialRepository.save(Material.builder()
                .materialCode("MAT-0003")
                .materialName("H형강 (H-200x200)")
                .category(Material.MaterialCategory.STEEL)
                .specification("H-200x200x8x12, SS400")
                .unit("TON")
                .standardPrice(new BigDecimal("1150000"))
                .stockQuantity(new BigDecimal("32.8"))
                .safetyStock(new BigDecimal("20"))
                .primaryVendor("포스코(주)")
                .leadTimeDays(21)
                .build());

        materialRepository.save(Material.builder()
                .materialCode("MAT-0004")
                .materialName("안전망 (추락방지용)")
                .category(Material.MaterialCategory.SAFETY)
                .specification("규격 2x6m, 내충격 강도 등급 A형")
                .unit("EA")
                .standardPrice(new BigDecimal("85000"))
                .stockQuantity(new BigDecimal("18"))
                .safetyStock(new BigDecimal("30"))
                .primaryVendor("세이프티코리아")
                .leadTimeDays(5)
                .build());

        materialRepository.save(Material.builder()
                .materialCode("MAT-0005")
                .materialName("합판 (12mm 콘크리트 거푸집용)")
                .category(Material.MaterialCategory.WOOD)
                .specification("12T x 900 x 1800mm, 내수합판")
                .unit("EA")
                .standardPrice(new BigDecimal("28000"))
                .stockQuantity(new BigDecimal("450"))
                .safetyStock(new BigDecimal("200"))
                .primaryVendor("성창기업(주)")
                .leadTimeDays(7)
                .build());

        materialRepository.save(Material.builder()
                .materialCode("MAT-0006")
                .materialName("동관 (배관용, DN50)")
                .category(Material.MaterialCategory.PIPING)
                .specification("동관 DN50, KS D 5301")
                .unit("M")
                .standardPrice(new BigDecimal("35000"))
                .stockQuantity(new BigDecimal("85"))
                .safetyStock(new BigDecimal("100"))
                .primaryVendor("대한동관(주)")
                .leadTimeDays(10)
                .build());
    }

    private void initEquipment() {
        Project p1 = projectRepository.findByProjectCode("PRJ-2024-001").orElseThrow();
        Project p2 = projectRepository.findByProjectCode("PRJ-2024-002").orElseThrow();

        equipmentRepository.save(Equipment.builder()
                .equipmentCode("EQP-0001")
                .equipmentName("굴착기 21톤")
                .equipmentType(Equipment.EquipmentType.EXCAVATOR)
                .model("Volvo EC220E")
                .manufacturer("Volvo CE")
                .registrationNumber("서울 가 1234")
                .status(Equipment.EquipmentStatus.IN_USE)
                .currentProject(p1)
                .acquisitionDate(LocalDate.of(2022, 5, 10))
                .acquisitionCost(new BigDecimal("280000000"))
                .isRented(false)
                .nextMaintenanceDate(LocalDate.of(2025, 3, 1))
                .totalOperatingHours(3250)
                .build());

        equipmentRepository.save(Equipment.builder()
                .equipmentCode("EQP-0002")
                .equipmentName("타워크레인 50톤")
                .equipmentType(Equipment.EquipmentType.CRANE)
                .model("Liebherr 280 EC-H")
                .manufacturer("Liebherr")
                .status(Equipment.EquipmentStatus.IN_USE)
                .currentProject(p1)
                .isRented(true)
                .rentalCostPerDay(new BigDecimal("2500000"))
                .nextMaintenanceDate(LocalDate.of(2025, 6, 1))
                .totalOperatingHours(1820)
                .build());

        equipmentRepository.save(Equipment.builder()
                .equipmentCode("EQP-0003")
                .equipmentName("덤프트럭 15톤")
                .equipmentType(Equipment.EquipmentType.DUMP_TRUCK)
                .model("현대 메가트럭")
                .manufacturer("현대자동차")
                .registrationNumber("인천 나 5678")
                .status(Equipment.EquipmentStatus.IN_USE)
                .currentProject(p2)
                .acquisitionDate(LocalDate.of(2023, 1, 20))
                .acquisitionCost(new BigDecimal("95000000"))
                .isRented(false)
                .nextMaintenanceDate(LocalDate.of(2025, 2, 15))
                .totalOperatingHours(5600)
                .build());

        equipmentRepository.save(Equipment.builder()
                .equipmentCode("EQP-0004")
                .equipmentName("불도저 D6T")
                .equipmentType(Equipment.EquipmentType.BULLDOZER)
                .model("Caterpillar D6T")
                .manufacturer("Caterpillar")
                .status(Equipment.EquipmentStatus.AVAILABLE)
                .acquisitionDate(LocalDate.of(2021, 8, 5))
                .acquisitionCost(new BigDecimal("320000000"))
                .isRented(false)
                .nextMaintenanceDate(LocalDate.of(2025, 1, 30))
                .totalOperatingHours(7800)
                .build());

        equipmentRepository.save(Equipment.builder()
                .equipmentCode("EQP-0005")
                .equipmentName("콘크리트 펌프카 52M")
                .equipmentType(Equipment.EquipmentType.CONCRETE_PUMP)
                .model("Putzmeister M52-6")
                .manufacturer("Putzmeister")
                .status(Equipment.EquipmentStatus.MAINTENANCE)
                .isRented(true)
                .rentalCostPerDay(new BigDecimal("1800000"))
                .nextMaintenanceDate(LocalDate.of(2025, 2, 1))
                .totalOperatingHours(2100)
                .build());
    }

    private void initPurchaseOrders() {
        Project p1 = projectRepository.findByProjectCode("PRJ-2024-001").orElseThrow();
        Project p2 = projectRepository.findByProjectCode("PRJ-2024-002").orElseThrow();
        Material mat1 = materialRepository.findByMaterialCode("MAT-0001").orElseThrow();
        Material mat3 = materialRepository.findByMaterialCode("MAT-0003").orElseThrow();

        PurchaseOrder po1 = new PurchaseOrder();
        po1.setPoNumber("PO-2025-0001");
        po1.setProject(p1);
        po1.setVendorName("현대제철(주)");
        po1.setVendorCode("VND-001");
        po1.setStatus(PurchaseOrder.POStatus.APPROVED);
        po1.setOrderDate(LocalDate.of(2025, 1, 10));
        po1.setDeliveryDate(LocalDate.of(2025, 1, 25));
        po1.setDeliveryAddress("서울시 강남구 역삼동 123-4 강남 주상복합 현장");
        po1.setPurchaser("구매팀 홍길동");
        po1.setTotalAmount(new BigDecimal("52250000"));

        purchaseOrderRepository.save(po1);

        PurchaseOrder po2 = new PurchaseOrder();
        po2.setPoNumber("PO-2025-0002");
        po2.setProject(p2);
        po2.setVendorName("포스코(주)");
        po2.setVendorCode("VND-002");
        po2.setStatus(PurchaseOrder.POStatus.ORDERED);
        po2.setOrderDate(LocalDate.of(2025, 1, 15));
        po2.setDeliveryDate(LocalDate.of(2025, 2, 5));
        po2.setDeliveryAddress("인천시 남동구 제2경인고속도로 공사현장");
        po2.setPurchaser("구매팀 김구매");
        po2.setTotalAmount(new BigDecimal("126500000"));

        purchaseOrderRepository.save(po2);

        PurchaseOrder po3 = new PurchaseOrder();
        po3.setPoNumber("PO-2025-0003");
        po3.setProject(p1);
        po3.setVendorName("삼표레미콘(주)");
        po3.setVendorCode("VND-003");
        po3.setStatus(PurchaseOrder.POStatus.RECEIVED);
        po3.setOrderDate(LocalDate.of(2025, 1, 5));
        po3.setDeliveryDate(LocalDate.of(2025, 1, 8));
        po3.setDeliveryAddress("서울시 강남구 역삼동 123-4 강남 주상복합 현장");
        po3.setPurchaser("구매팀 홍길동");
        po3.setTotalAmount(new BigDecimal("20900000"));

        purchaseOrderRepository.save(po3);
    }

    private void initCostEntries() {
        Project p1 = projectRepository.findByProjectCode("PRJ-2024-001").orElseThrow();
        Project p2 = projectRepository.findByProjectCode("PRJ-2024-002").orElseThrow();

        costEntryRepository.save(CostEntry.builder()
                .entryNumber("CE-2025-001")
                .project(p1)
                .costType(CostEntry.CostType.LABOR)
                .costAccount("직접노무비")
                .entryDate(LocalDate.of(2025, 1, 31))
                .amount(new BigDecimal("285000000"))
                .description("2025년 1월 강남 주상복합 직접노무비")
                .createdBy("원가팀 이원가")
                .build());

        costEntryRepository.save(CostEntry.builder()
                .entryNumber("CE-2025-002")
                .project(p1)
                .costType(CostEntry.CostType.MATERIAL)
                .costAccount("철근비")
                .entryDate(LocalDate.of(2025, 1, 25))
                .amount(new BigDecimal("52250000"))
                .description("철근 HD25 55톤 구매비")
                .documentNumber("TI-2025-0045")
                .createdBy("원가팀 이원가")
                .build());

        costEntryRepository.save(CostEntry.builder()
                .entryNumber("CE-2025-003")
                .project(p1)
                .costType(CostEntry.CostType.EQUIPMENT_COST)
                .costAccount("타워크레인 임대비")
                .entryDate(LocalDate.of(2025, 1, 31))
                .amount(new BigDecimal("75000000"))
                .description("타워크레인 1월 임대비 (30일)")
                .documentNumber("INV-2025-0012")
                .createdBy("원가팀 이원가")
                .build());

        costEntryRepository.save(CostEntry.builder()
                .entryNumber("CE-2025-004")
                .project(p2)
                .costType(CostEntry.CostType.SUBCONTRACT)
                .costAccount("토공 외주비")
                .entryDate(LocalDate.of(2025, 1, 31))
                .amount(new BigDecimal("380000000"))
                .description("교량 기초 토공 외주 작업비")
                .documentNumber("SC-2025-0008")
                .createdBy("원가팀 박원가")
                .build());

        costEntryRepository.save(CostEntry.builder()
                .entryNumber("CE-2025-005")
                .project(p2)
                .costType(CostEntry.CostType.MATERIAL)
                .costAccount("H형강 자재비")
                .entryDate(LocalDate.of(2025, 1, 20))
                .amount(new BigDecimal("126500000"))
                .description("H형강 110톤 구매")
                .documentNumber("TI-2025-0038")
                .createdBy("원가팀 박원가")
                .build());
    }
}
