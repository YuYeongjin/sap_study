package org.sap.controller;

import lombok.RequiredArgsConstructor;
import org.sap.model.PurchaseOrder;
import org.sap.service.PurchaseOrderService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * MM 모듈 - 구매 발주 API
 */
@RestController
@RequestMapping("/api/purchase-orders")
@RequiredArgsConstructor
public class PurchaseOrderController {

    private final PurchaseOrderService purchaseOrderService;

    @GetMapping
    public List<PurchaseOrder> findAll(
            @RequestParam(required = false) Long projectId,
            @RequestParam(required = false) String status) {

        if (projectId != null) {
            return purchaseOrderService.findByProjectId(projectId);
        }
        if (status != null && !status.isBlank()) {
            return purchaseOrderService.findByStatus(PurchaseOrder.POStatus.valueOf(status));
        }
        return purchaseOrderService.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<PurchaseOrder> findById(@PathVariable Long id) {
        return purchaseOrderService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public PurchaseOrder create(@RequestBody PurchaseOrder po) {
        return purchaseOrderService.save(po);
    }

    // 상태 변경 (승인, 발주 완료, 입고 등)
    @PatchMapping("/{id}/status")
    public ResponseEntity<PurchaseOrder> updateStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        PurchaseOrder.POStatus newStatus = PurchaseOrder.POStatus.valueOf(body.get("status"));
        return ResponseEntity.ok(purchaseOrderService.updateStatus(id, newStatus));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        purchaseOrderService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
