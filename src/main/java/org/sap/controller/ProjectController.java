package org.sap.controller;

import lombok.RequiredArgsConstructor;
import org.sap.model.Project;
import org.sap.service.ProjectService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * PS 모듈 - 프로젝트 관리 API
 */
@RestController
@RequestMapping("/api/projects")
@RequiredArgsConstructor
public class ProjectController {

    private final ProjectService projectService;

    // 전체 프로젝트 목록
    @GetMapping
    public List<Project> findAll(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String keyword) {

        if (keyword != null && !keyword.isBlank()) {
            return projectService.search(keyword);
        }
        if (status != null && !status.isBlank()) {
            return projectService.findByStatus(Project.ProjectStatus.valueOf(status));
        }
        return projectService.findAll();
    }

    // 프로젝트 상세
    @GetMapping("/{id}")
    public ResponseEntity<Project> findById(@PathVariable Long id) {
        return projectService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // 대시보드 통계
    @GetMapping("/stats")
    public Map<String, Object> getStats() {
        return projectService.getDashboardStats();
    }

    // 프로젝트 등록
    @PostMapping
    public Project create(@RequestBody Project project) {
        return projectService.save(project);
    }

    // 프로젝트 수정
    @PutMapping("/{id}")
    public ResponseEntity<Project> update(@PathVariable Long id, @RequestBody Project project) {
        return ResponseEntity.ok(projectService.update(id, project));
    }

    // 진도율 업데이트
    @PatchMapping("/{id}/progress")
    public ResponseEntity<Project> updateProgress(
            @PathVariable Long id,
            @RequestBody Map<String, Integer> body) {
        Project project = projectService.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("프로젝트를 찾을 수 없습니다: " + id));
        project.setProgressRate(body.get("progressRate"));
        return ResponseEntity.ok(projectService.save(project));
    }

    // 프로젝트 삭제
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        projectService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
