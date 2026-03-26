package org.sap.service;

import lombok.RequiredArgsConstructor;
import org.sap.model.Project;
import org.sap.repository.CostEntryRepository;
import org.sap.repository.ProjectRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ProjectService {

    private final ProjectRepository projectRepository;
    private final CostEntryRepository costEntryRepository;

    public List<Project> findAll() {
        return projectRepository.findAll();
    }

    public Optional<Project> findById(Long id) {
        return projectRepository.findById(id);
    }

    public List<Project> findByStatus(Project.ProjectStatus status) {
        return projectRepository.findByStatus(status);
    }

    public List<Project> search(String keyword) {
        return projectRepository.findByProjectNameContaining(keyword);
    }

    @Transactional
    public Project save(Project project) {
        return projectRepository.save(project);
    }

    @Transactional
    public Project update(Long id, Project updated) {
        Project project = projectRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("프로젝트를 찾을 수 없습니다: " + id));

        project.setProjectName(updated.getProjectName());
        project.setLocation(updated.getLocation());
        project.setClient(updated.getClient());
        project.setProjectType(updated.getProjectType());
        project.setStatus(updated.getStatus());
        project.setContractAmount(updated.getContractAmount());
        project.setBudget(updated.getBudget());
        project.setExecutionBudget(updated.getExecutionBudget());
        project.setStartDate(updated.getStartDate());
        project.setPlannedEndDate(updated.getPlannedEndDate());
        project.setActualEndDate(updated.getActualEndDate());
        project.setProgressRate(updated.getProgressRate());
        project.setSiteManager(updated.getSiteManager());

        return projectRepository.save(project);
    }

    @Transactional
    public void delete(Long id) {
        projectRepository.deleteById(id);
    }

    // 대시보드용 통계
    public Map<String, Object> getDashboardStats() {
        long total = projectRepository.count();
        long inProgress = projectRepository.countByStatus(Project.ProjectStatus.IN_PROGRESS);
        long completed = projectRepository.countByStatus(Project.ProjectStatus.COMPLETED);
        long planning = projectRepository.countByStatus(Project.ProjectStatus.PLANNING);
        BigDecimal totalContractAmount = projectRepository.sumContractAmountInProgress();

        return Map.of(
                "totalProjects", total,
                "inProgress", inProgress,
                "completed", completed,
                "planning", planning,
                "totalContractAmount", totalContractAmount != null ? totalContractAmount : BigDecimal.ZERO
        );
    }
}
