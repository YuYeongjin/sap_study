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
 * CO 모듈 - 원가 전표 (Cost Entry)
 * 프로젝트별 원가 발생 내역 관리
 * 노무비, 재료비, 경비, 외주비 등
 */
@Entity
@Table(name = "cost_entries")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CostEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 전표 번호
    @Column(nullable = false, unique = true, length = 20)
    private String entryNumber;

    // 연관 프로젝트
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id", nullable = false)
    private Project project;

    // 원가 유형
    @Enumerated(EnumType.STRING)
    private CostType costType;

    // 원가 항목 (세부 계정)
    @Column(length = 100)
    private String costAccount;

    // 발생일
    private LocalDate entryDate;

    // 금액
    @Column(precision = 20, scale = 2, nullable = false)
    private BigDecimal amount;

    // 수량 (노무비의 경우 인원수, 자재비의 경우 수량)
    private BigDecimal quantity;

    // 단위
    @Column(length = 20)
    private String unit;

    // 단가
    @Column(precision = 15, scale = 2)
    private BigDecimal unitPrice;

    // 적요 (내용 설명)
    @Column(length = 500)
    private String description;

    // 증빙 문서 번호 (세금계산서, 영수증 등)
    @Column(length = 50)
    private String documentNumber;

    // 입력자
    @Column(length = 100)
    private String createdBy;

    // 등록일시
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public enum CostType {
        LABOR("노무비"),
        MATERIAL("재료비"),
        EQUIPMENT_COST("장비비"),
        SUBCONTRACT("외주비"),
        OVERHEAD("경비"),
        INDIRECT("간접비");

        public final String label;
        CostType(String label) { this.label = label; }
    }
}
