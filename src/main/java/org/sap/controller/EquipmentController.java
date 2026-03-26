package org.sap.controller;

import lombok.RequiredArgsConstructor;
import org.sap.model.Equipment;
import org.sap.service.EquipmentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * PM 모듈 - 건설 장비 관리 API
 */
@RestController
@RequestMapping("/api/equipment")
@RequiredArgsConstructor
public class EquipmentController {

    private final EquipmentService equipmentService;

    @GetMapping
    public List<Equipment> findAll(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Long projectId) {

        if (projectId != null) {
            return equipmentService.findByProjectId(projectId);
        }
        if (status != null && !status.isBlank()) {
            return equipmentService.findByStatus(Equipment.EquipmentStatus.valueOf(status));
        }
        return equipmentService.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Equipment> findById(@PathVariable Long id) {
        return equipmentService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Equipment create(@RequestBody Equipment equipment) {
        return equipmentService.save(equipment);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Equipment> update(@PathVariable Long id, @RequestBody Equipment equipment) {
        return ResponseEntity.ok(equipmentService.update(id, equipment));
    }

    // 장비 현장 배치
    @PatchMapping("/{id}/assign")
    public ResponseEntity<Equipment> assign(
            @PathVariable Long id,
            @RequestBody Map<String, Long> body) {
        Long projectId = body.get("projectId");
        return ResponseEntity.ok(equipmentService.assignToProject(id, projectId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        equipmentService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
