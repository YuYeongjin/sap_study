package org.sap.repository;

import org.sap.model.PurchaseOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PurchaseOrderRepository extends JpaRepository<PurchaseOrder, Long> {

    Optional<PurchaseOrder> findByPoNumber(String poNumber);

    List<PurchaseOrder> findByStatus(PurchaseOrder.POStatus status);

    List<PurchaseOrder> findByProjectId(Long projectId);

    List<PurchaseOrder> findByVendorNameContaining(String keyword);

    @Query("SELECT SUM(po.totalAmount) FROM PurchaseOrder po WHERE po.project.id = :projectId AND po.status != 'CANCELLED'")
    java.math.BigDecimal sumTotalAmountByProjectId(Long projectId);
}
