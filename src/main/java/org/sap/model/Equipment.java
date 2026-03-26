package org.sap.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * PM 모듈 - 건설 장비 관리 (Plant Maintenance)
 * 굴착기, 크레인, 덤프트럭 등 건설 장비 관리
 */
@Entity
@Table(name = "equipment")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Equipment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 장비 코드
    @Column(nullable = false, unique = true, length = 20)
    private String equipmentCode;

    // 장비명
    @Column(nullable = false, length = 200)
    private String equipmentName;

    // 장비 유형
    @Enumerated(EnumType.STRING)
    private EquipmentType equipmentType;

    // 모델명
    @Column(length = 100)
    private String model;

    // 제조사
    @Column(length = 100)
    private String manufacturer;

    // 등록 번호 (차량번호 등)
    @Column(length = 50)
    private String registrationNumber;

    // 장비 상태
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private EquipmentStatus status = EquipmentStatus.AVAILABLE;

    // 현재 투입 현장 (프로젝트)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "current_project_id")
    private Project currentProject;

    // 취득 일자
    private LocalDate acquisitionDate;

    // 취득 금액
    @Column(precision = 20, scale = 0)
    private BigDecimal acquisitionCost;

    // 임대 여부
    private Boolean isRented;

    // 임대 단가 (일/월)
    @Column(precision = 10, scale = 0)
    private BigDecimal rentalCostPerDay;

    // 다음 정기 점검일
    private LocalDate nextMaintenanceDate;

    // 누적 가동 시간 (시간)
    @Builder.Default
    private Integer totalOperatingHours = 0;

    // 등록일시
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public enum EquipmentType {
        EXCAVATOR("굴착기"),
        CRANE("크레인"),
        DUMP_TRUCK("덤프트럭"),
        CONCRETE_PUMP("콘크리트 펌프카"),
        BULLDOZER("불도저"),
        FORKLIFT("지게차"),
        ROLLER("롤러"),
        COMPRESSOR("컴프레서"),
        GENERATOR("발전기"),
        OTHER("기타");

        public final String label;
        EquipmentType(String label) { this.label = label; }
    }

    public enum EquipmentStatus {
        AVAILABLE("가용"),
        IN_USE("투입중"),
        MAINTENANCE("정비중"),
        BROKEN("고장"),
        DISPOSED("폐기");

        public final String label;
        EquipmentStatus(String label) { this.label = label; }
    }
}
