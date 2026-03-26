package org.sap.service;

import lombok.RequiredArgsConstructor;
import org.sap.model.CostEntry;
import org.sap.model.Project;
import org.sap.repository.CostEntryRepository;
import org.sap.repository.ProjectRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CostEntryService {

    private final CostEntryRepository costEntryRepository;
    private final ProjectRepository projectRepository;

    public List<CostEntry> findAll() {
        return costEntryRepository.findAll();
    }

    public List<CostEntry> findByProjectId(Long projectId) {
        return costEntryRepository.findByProjectId(projectId);
    }

    public Optional<CostEntry> findById(Long id) {
        return costEntryRepository.findById(id);
    }

    // 프로젝트별 원가 유형 합계
    public Map<String, BigDecimal> getCostSummaryByProject(Long projectId) {
        List<Object[]> results = costEntryRepository.sumAmountGroupByCostType(projectId);
        Map<String, BigDecimal> summary = new HashMap<>();
        for (Object[] row : results) {
            CostEntry.CostType type = (CostEntry.CostType) row[0];
            BigDecimal amount = (BigDecimal) row[1];
            summary.put(type.label, amount);
        }
        return summary;
    }

    // 전체 원가 통계
    public Map<String, BigDecimal> getAllCostSummary() {
        List<Object[]> results = costEntryRepository.sumAllAmountGroupByCostType();
        Map<String, BigDecimal> summary = new HashMap<>();
        for (Object[] row : results) {
            CostEntry.CostType type = (CostEntry.CostType) row[0];
            BigDecimal amount = (BigDecimal) row[1];
            summary.put(type.label, amount);
        }
        return summary;
    }

    @Transactional
    public CostEntry save(CostEntry entry) {
        // 금액 계산 (수량 x 단가)
        if (entry.getQuantity() != null && entry.getUnitPrice() != null) {
            entry.setAmount(entry.getQuantity().multiply(entry.getUnitPrice()));
        }

        // 프로젝트 실제 원가 업데이트
        Project project = entry.getProject();
        if (project != null) {
            BigDecimal currentCost = costEntryRepository.sumAmountByProjectId(project.getId());
            BigDecimal newTotal = (currentCost != null ? currentCost : BigDecimal.ZERO).add(entry.getAmount());
            project.setActualCost(newTotal);
            projectRepository.save(project);
        }

        return costEntryRepository.save(entry);
    }

    @Transactional
    public void delete(Long id) {
        costEntryRepository.deleteById(id);
    }
}
