package org.sap.service;

import lombok.RequiredArgsConstructor;
import org.sap.model.Project;
import org.sap.model.PurchaseOrder;
import org.sap.model.PurchaseOrderItem;
import org.sap.repository.ProjectRepository;
import org.sap.repository.PurchaseOrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PurchaseOrderService {

    private final PurchaseOrderRepository purchaseOrderRepository;
    private final ProjectRepository projectRepository;

    public List<PurchaseOrder> findAll() {
        return purchaseOrderRepository.findAll();
    }

    public Optional<PurchaseOrder> findById(Long id) {
        return purchaseOrderRepository.findById(id);
    }

    public List<PurchaseOrder> findByProjectId(Long projectId) {
        return purchaseOrderRepository.findByProjectId(projectId);
    }

    public List<PurchaseOrder> findByStatus(PurchaseOrder.POStatus status) {
        return purchaseOrderRepository.findByStatus(status);
    }

    @Transactional
    public PurchaseOrder save(PurchaseOrder po) {
        // 총금액 계산
        if (po.getItems() != null) {
            BigDecimal total = po.getItems().stream()
                    .map(item -> {
                        item.setPurchaseOrder(po);
                        return item.getTotalAmount() != null ? item.getTotalAmount() : BigDecimal.ZERO;
                    })
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            po.setTotalAmount(total);
        }
        return purchaseOrderRepository.save(po);
    }

    @Transactional
    public PurchaseOrder updateStatus(Long id, PurchaseOrder.POStatus newStatus) {
        PurchaseOrder po = purchaseOrderRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("발주서를 찾을 수 없습니다: " + id));
        po.setStatus(newStatus);
        return purchaseOrderRepository.save(po);
    }

    @Transactional
    public void delete(Long id) {
        purchaseOrderRepository.deleteById(id);
    }
}
