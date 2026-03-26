package org.sap.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * MM 모듈 - 구매 발주 (Purchase Order)
 * 건설 자재 구매 발주서 관리
 */
@Entity
@Table(name = "purchase_orders")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PurchaseOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 발주 번호 (예: PO-2024-0001)
    @Column(nullable = false, unique = true, length = 20)
    private String poNumber;

    // 연관 프로젝트
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id")
    private Project project;

    // 공급업체명
    @Column(nullable = false, length = 200)
    private String vendorName;

    // 공급업체 코드
    @Column(length = 20)
    private String vendorCode;

    // 발주 상태
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private POStatus status = POStatus.DRAFT;

    // 발주 일자
    private LocalDate orderDate;

    // 납품 요청일
    private LocalDate deliveryDate;

    // 납품 주소 (현장)
    @Column(length = 300)
    private String deliveryAddress;

    // 총 발주 금액
    @Column(precision = 20, scale = 2)
    @Builder.Default
    private BigDecimal totalAmount = BigDecimal.ZERO;

    // 담당자
    @Column(length = 100)
    private String purchaser;

    // 비고
    @Column(length = 500)
    private String remarks;

    // 발주 품목 목록
    @OneToMany(mappedBy = "purchaseOrder", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PurchaseOrderItem> items;

    // 등록일시
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public enum POStatus {
        DRAFT("초안"),
        PENDING("승인대기"),
        APPROVED("승인완료"),
        ORDERED("발주완료"),
        PARTIAL_RECEIVED("부분입고"),
        RECEIVED("입고완료"),
        CANCELLED("취소");

        public final String label;
        POStatus(String label) { this.label = label; }
    }
}
