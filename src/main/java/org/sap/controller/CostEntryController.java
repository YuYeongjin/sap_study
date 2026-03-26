package org.sap.controller;

import lombok.RequiredArgsConstructor;
import org.sap.model.CostEntry;
import org.sap.service.CostEntryService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * CO 모듈 - 원가 관리 API
 */
@RestController
@RequestMapping("/api/cost-entries")
@RequiredArgsConstructor
public class CostEntryController {

    private final CostEntryService costEntryService;

    @GetMapping
    public List<CostEntry> findAll(@RequestParam(required = false) Long projectId) {
        if (projectId != null) {
            return costEntryService.findByProjectId(projectId);
        }
        return costEntryService.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<CostEntry> findById(@PathVariable Long id) {
        return costEntryService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // 프로젝트별 원가 유형 합계
    @GetMapping("/summary")
    public Map<String, BigDecimal> getSummary(@RequestParam(required = false) Long projectId) {
        if (projectId != null) {
            return costEntryService.getCostSummaryByProject(projectId);
        }
        return costEntryService.getAllCostSummary();
    }

    @PostMapping
    public CostEntry create(@RequestBody CostEntry entry) {
        return costEntryService.save(entry);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        costEntryService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
