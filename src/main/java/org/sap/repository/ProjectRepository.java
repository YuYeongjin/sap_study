package org.sap.repository;

import org.sap.model.Project;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProjectRepository extends JpaRepository<Project, Long> {

    Optional<Project> findByProjectCode(String projectCode);

    List<Project> findByStatus(Project.ProjectStatus status);

    List<Project> findByProjectType(Project.ProjectType projectType);

    List<Project> findByProjectNameContaining(String keyword);

    @Query("SELECT COUNT(p) FROM Project p WHERE p.status = :status")
    Long countByStatus(Project.ProjectStatus status);

    @Query("SELECT SUM(p.contractAmount) FROM Project p WHERE p.status = 'IN_PROGRESS'")
    java.math.BigDecimal sumContractAmountInProgress();
}
