package org.sap.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.math.BigDecimal;

/**
 * MM 모듈 - 발주 품목 (Purchase Order Line Item)
 */
@Entity
@Table(name = "purchase_order_items")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PurchaseOrderItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "purchase_order_id")
    private PurchaseOrder purchaseOrder;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "material_id")
    private Material material;

    // 품목 설명 (자재가 없는 경우 직접 입력)
    @Column(length = 200)
    private String itemDescription;

    // 수량
    @Column(precision = 15, scale = 3)
    private BigDecimal quantity;

    // 단위
    @Column(length = 20)
    private String unit;

    // 단가
    @Column(precision = 15, scale = 2)
    private BigDecimal unitPrice;

    // 공급가액
    @Column(precision = 20, scale = 2)
    private BigDecimal supplyAmount;

    // 부가세
    @Column(precision = 20, scale = 2)
    private BigDecimal vatAmount;

    // 합계 금액
    @Column(precision = 20, scale = 2)
    private BigDecimal totalAmount;

    // 입고 수량
    @Builder.Default
    private BigDecimal receivedQuantity = BigDecimal.ZERO;

    @PrePersist
    @PreUpdate
    protected void calculateAmounts() {
        if (quantity != null && unitPrice != null) {
            supplyAmount = quantity.multiply(unitPrice);
            vatAmount = supplyAmount.multiply(new BigDecimal("0.1"));
            totalAmount = supplyAmount.add(vatAmount);
        }
    }
}
