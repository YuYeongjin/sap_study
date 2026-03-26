package org.sap.controller;

import lombok.RequiredArgsConstructor;
import org.sap.model.Material;
import org.sap.service.MaterialService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * MM 모듈 - 자재 마스터 API
 */
@RestController
@RequestMapping("/api/materials")
@RequiredArgsConstructor
public class MaterialController {

    private final MaterialService materialService;

    @GetMapping
    public List<Material> findAll(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Boolean lowStock) {

        if (Boolean.TRUE.equals(lowStock)) {
            return materialService.findLowStockMaterials();
        }
        if (keyword != null && !keyword.isBlank()) {
            return materialService.search(keyword);
        }
        if (category != null && !category.isBlank()) {
            return materialService.findByCategory(Material.MaterialCategory.valueOf(category));
        }
        return materialService.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Material> findById(@PathVariable Long id) {
        return materialService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Material create(@RequestBody Material material) {
        return materialService.save(material);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Material> update(@PathVariable Long id, @RequestBody Material material) {
        return ResponseEntity.ok(materialService.update(id, material));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        materialService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
