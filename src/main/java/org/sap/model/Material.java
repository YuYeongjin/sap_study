package org.sap.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * MM 모듈 - 자재 마스터 (Material Master)
 * 건설 현장에서 사용하는 자재 기본 정보
 */
@Entity
@Table(name = "materials")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Material {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 자재 코드 (예: MAT-0001)
    @Column(nullable = false, unique = true, length = 20)
    private String materialCode;

    // 자재명
    @Column(nullable = false, length = 200)
    private String materialName;

    // 자재 분류
    @Enumerated(EnumType.STRING)
    private MaterialCategory category;

    // 규격/사양
    @Column(length = 300)
    private String specification;

    // 단위 (EA, KG, M, M2, M3, TON 등)
    @Column(length = 20)
    private String unit;

    // 표준 단가
    @Column(precision = 15, scale = 2)
    private BigDecimal standardPrice;

    // 현재 재고 수량
    @Builder.Default
    private BigDecimal stockQuantity = BigDecimal.ZERO;

    // 안전 재고 수량 (이하면 구매 요청)
    private BigDecimal safetyStock;

    // 주요 공급업체
    @Column(length = 200)
    private String primaryVendor;

    // 리드타임 (일)
    private Integer leadTimeDays;

    // 등록일시
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public enum MaterialCategory {
        STEEL("철강"),
        CONCRETE("콘크리트"),
        WOOD("목재"),
        ELECTRICAL("전기자재"),
        PIPING("배관"),
        FINISHING("마감재"),
        EQUIPMENT("장비"),
        SAFETY("안전용품"),
        CHEMICAL("화학"),
        OTHER("기타");

        public final String label;
        MaterialCategory(String label) { this.label = label; }
    }
}
