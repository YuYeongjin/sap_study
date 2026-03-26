package org.sap.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * PS 모듈 - 공사 프로젝트 (Project System)
 * 건설회사의 핵심 - 각 공사 현장을 프로젝트로 관리
 */
@Entity
@Table(name = "projects")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Project {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 프로젝트 코드 (예: PRJ-2024-001)
    @Column(nullable = false, unique = true, length = 20)
    private String projectCode;

    // 공사명
    @Column(nullable = false, length = 200)
    private String projectName;

    // 공사 위치
    @Column(length = 300)
    private String location;

    // 발주처
    @Column(length = 200)
    private String client;

    // 공사 유형 (토목/건축/플랜트/전기 등)
    @Enumerated(EnumType.STRING)
    private ProjectType projectType;

    // 공사 상태
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private ProjectStatus status = ProjectStatus.PLANNING;

    // 계약 금액
    @Column(precision = 20, scale = 0)
    private BigDecimal contractAmount;

    // 예산
    @Column(precision = 20, scale = 0)
    private BigDecimal budget;

    // 실행 예산 (원가 관리)
    @Column(precision = 20, scale = 0)
    private BigDecimal executionBudget;

    // 실제 투입 원가
    @Column(precision = 20, scale = 0)
    @Builder.Default
    private BigDecimal actualCost = BigDecimal.ZERO;

    // 공사 시작일
    private LocalDate startDate;

    // 공사 완료 예정일
    private LocalDate plannedEndDate;

    // 실제 완료일
    private LocalDate actualEndDate;

    // 공정률 (0-100%)
    @Builder.Default
    private Integer progressRate = 0;

    // 현장 소장
    @Column(length = 100)
    private String siteManager;

    // 등록일시
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public enum ProjectType {
        CIVIL("토목"),
        BUILDING("건축"),
        PLANT("플랜트"),
        ELECTRICAL("전기"),
        MECHANICAL("기계");

        public final String label;
        ProjectType(String label) { this.label = label; }
    }

    public enum ProjectStatus {
        PLANNING("계획"),
        BIDDING("입찰"),
        CONTRACTED("수주"),
        IN_PROGRESS("진행중"),
        COMPLETED("완료"),
        SUSPENDED("일시중지");

        public final String label;
        ProjectStatus(String label) { this.label = label; }
    }
}
