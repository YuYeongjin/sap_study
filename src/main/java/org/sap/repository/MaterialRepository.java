package org.sap.repository;

import org.sap.model.Material;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MaterialRepository extends JpaRepository<Material, Long> {

    Optional<Material> findByMaterialCode(String materialCode);

    List<Material> findByCategory(Material.MaterialCategory category);

    List<Material> findByMaterialNameContaining(String keyword);

    // 안전재고 이하인 자재 (구매 요청 필요)
    @Query("SELECT m FROM Material m WHERE m.stockQuantity <= m.safetyStock")
    List<Material> findLowStockMaterials();
}
