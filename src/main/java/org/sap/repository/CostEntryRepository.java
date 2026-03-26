package org.sap.repository;

import org.sap.model.CostEntry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface CostEntryRepository extends JpaRepository<CostEntry, Long> {

    List<CostEntry> findByProjectId(Long projectId);

    List<CostEntry> findByProjectIdAndCostType(Long projectId, CostEntry.CostType costType);

    @Query("SELECT SUM(c.amount) FROM CostEntry c WHERE c.project.id = :projectId")
    BigDecimal sumAmountByProjectId(Long projectId);

    @Query("SELECT c.costType, SUM(c.amount) FROM CostEntry c WHERE c.project.id = :projectId GROUP BY c.costType")
    List<Object[]> sumAmountGroupByCostType(Long projectId);

    @Query("SELECT c.costType, SUM(c.amount) FROM CostEntry c GROUP BY c.costType")
    List<Object[]> sumAllAmountGroupByCostType();
}
