package org.sap.service;

import lombok.RequiredArgsConstructor;
import org.sap.model.Material;
import org.sap.repository.MaterialRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MaterialService {

    private final MaterialRepository materialRepository;

    public List<Material> findAll() {
        return materialRepository.findAll();
    }

    public Optional<Material> findById(Long id) {
        return materialRepository.findById(id);
    }

    public List<Material> findByCategory(Material.MaterialCategory category) {
        return materialRepository.findByCategory(category);
    }

    public List<Material> search(String keyword) {
        return materialRepository.findByMaterialNameContaining(keyword);
    }

    public List<Material> findLowStockMaterials() {
        return materialRepository.findLowStockMaterials();
    }

    @Transactional
    public Material save(Material material) {
        return materialRepository.save(material);
    }

    @Transactional
    public Material update(Long id, Material updated) {
        Material material = materialRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("자재를 찾을 수 없습니다: " + id));

        material.setMaterialName(updated.getMaterialName());
        material.setCategory(updated.getCategory());
        material.setSpecification(updated.getSpecification());
        material.setUnit(updated.getUnit());
        material.setStandardPrice(updated.getStandardPrice());
        material.setStockQuantity(updated.getStockQuantity());
        material.setSafetyStock(updated.getSafetyStock());
        material.setPrimaryVendor(updated.getPrimaryVendor());
        material.setLeadTimeDays(updated.getLeadTimeDays());

        return materialRepository.save(material);
    }

    @Transactional
    public void delete(Long id) {
        materialRepository.deleteById(id);
    }
}
