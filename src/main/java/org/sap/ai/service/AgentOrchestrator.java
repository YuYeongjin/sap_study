package org.sap.ai.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.sap.ai.model.*;
import org.sap.model.Equipment;
import org.sap.model.Material;
import org.sap.model.Project;
import org.sap.service.EquipmentService;
import org.sap.service.MaterialService;
import org.sap.service.ProjectService;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Multi-Agent Orchestrator
 *
 * Agent 종류:
 *   ORCHESTRATOR - 인텐트 분류 후 라우팅
 *   NAVIGATION   - 화면 이동 처리
 *   RAG          - SAP/건설 지식 검색 + LLM 답변
 *   DATA_QUERY   - 실시간 DB 데이터 조회 + LLM 요약
 *   CHAT         - 일반 대화 (fallback)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AgentOrchestrator {

    private final OllamaService ollamaService;
    private final RagDocumentService ragDocumentService;
    private final ProjectService projectService;
    private final MaterialService materialService;
    private final EquipmentService equipmentService;

    // ── 화면 네비게이션 맵 ──────────────────────────────────────────────
    private static final List<NavEntry> NAV_MAP = List.of(
            new NavEntry(new NavigationInfo("/dashboard",       "대시보드"),       new String[]{"대시보드","홈","메인","home"}),
            new NavEntry(new NavigationInfo("/projects",        "프로젝트 목록"),   new String[]{"프로젝트","공사","ps","현장"}),
            new NavEntry(new NavigationInfo("/materials",       "자재 관리"),       new String[]{"자재","mrp","재고","mm 자재"}),
            new NavEntry(new NavigationInfo("/purchase-orders", "구매 발주"),       new String[]{"구매","발주","po","구매발주","purchase"}),
            new NavEntry(new NavigationInfo("/equipment",       "장비 관리"),       new String[]{"장비","기계","pm","중장비"}),
            new NavEntry(new NavigationInfo("/cost",            "원가 관리"),       new String[]{"원가","비용","co","코스트","cost"})
    );

    // ── 진입점 ─────────────────────────────────────────────────────────
    public ChatResponse process(ChatRequest request) {
        String msg = request.getMessage();
        List<ChatMessage> history = request.getHistory() != null ? request.getHistory() : List.of();

        try {
            String intent = classifyIntent(msg);
            log.info("[Orchestrator] intent={} msg={}", intent, msg);

            return switch (intent) {
                case "NAVIGATION"  -> handleNavigation(msg);
                case "RAG_SEARCH"  -> handleRag(msg, history);
                case "DATA_QUERY"  -> handleDataQuery(msg, history);
                default            -> handleChat(msg, history);
            };
        } catch (Exception e) {
            log.error("[Orchestrator] 처리 오류: {}", e.getMessage(), e);
            return ChatResponse.builder()
                    .success(false)
                    .agentType("ERROR")
                    .error("AI 서비스 오류: " + e.getMessage())
                    .build();
        }
    }

    // ── 인텐트 분류 Agent ──────────────────────────────────────────────
    private String classifyIntent(String msg) {
        String low = msg.toLowerCase();

        // 1) 네비게이션 빠른 판별
        boolean hasNavVerb = containsAny(low,
                "이동", "열어", "보여줘", "화면", "페이지", "탭", "메뉴", "가고싶", "이동해", "켜줘");
        if (hasNavVerb) {
            for (NavEntry e : NAV_MAP) {
                if (containsAny(low, e.keywords())) return "NAVIGATION";
            }
        }

        // 2) 데이터 조회 빠른 판별
        boolean hasDataVerb = containsAny(low, "현재", "지금", "얼마나", "몇개", "몇 개", "조회", "알려줘", "확인해줘");
        boolean hasDataTopic = containsAny(low, "프로젝트", "자재", "장비", "발주", "원가");
        if (hasDataVerb && hasDataTopic) return "DATA_QUERY";

        // 3) SAP 지식 검색 빠른 판별
        if (containsAny(msg, "SAP", "PS", "MM", "CO", "PM", "WBS", "MRP", "BOM",
                "모듈", "원가요소", "구매요청", "마스터데이터", "트랜잭션")) {
            return "RAG_SEARCH";
        }

        // 4) LLM 분류 (모호한 경우)
        String prompt = """
                SAP 건설 관리 시스템의 인텐트 분류기입니다.
                아래 메시지를 다음 중 정확히 하나로 분류하세요:
                NAVIGATION  - 특정 화면/메뉴 이동 요청
                RAG_SEARCH  - SAP 또는 건설 관련 지식/개념 질문
                DATA_QUERY  - 현재 시스템 데이터 조회 요청
                GENERAL_CHAT - 일반 대화

                메시지: "%s"

                인텐트 이름만 출력 (다른 텍스트 금지):""".formatted(msg);

        try {
            String result = ollamaService.simpleChat(prompt).trim().toUpperCase();
            if (result.contains("NAVIGATION"))  return "NAVIGATION";
            if (result.contains("RAG"))         return "RAG_SEARCH";
            if (result.contains("DATA"))        return "DATA_QUERY";
        } catch (Exception e) {
            log.warn("[Orchestrator] LLM 분류 실패, fallback GENERAL_CHAT");
        }
        return "GENERAL_CHAT";
    }

    // ── Navigation Agent ───────────────────────────────────────────────
    private ChatResponse handleNavigation(String msg) {
        String low = msg.toLowerCase();

        for (NavEntry entry : NAV_MAP) {
            if (containsAny(low, entry.keywords())) {
                NavigationInfo nav = entry.nav();
                return ChatResponse.builder()
                        .success(true)
                        .agentType("NAVIGATION")
                        .message(nav.getLabel() + " 화면으로 이동합니다.")
                        .navigation(nav)
                        .build();
            }
        }

        // LLM으로 경로 추론
        String prompt = """
                다음 SAP 건설 시스템 화면 중 사용자 요청에 맞는 경로를 골라 경로만 출력하세요.
                /dashboard, /projects, /materials, /purchase-orders, /equipment, /cost

                요청: "%s"
                경로만 출력:""".formatted(msg);

        try {
            String path = ollamaService.simpleChat(prompt).trim();
            for (NavEntry entry : NAV_MAP) {
                if (path.contains(entry.nav().getPath())) {
                    NavigationInfo nav = entry.nav();
                    return ChatResponse.builder()
                            .success(true)
                            .agentType("NAVIGATION")
                            .message(nav.getLabel() + " 화면으로 이동합니다.")
                            .navigation(nav)
                            .build();
                }
            }
        } catch (Exception ignored) {}

        return ChatResponse.builder()
                .success(true)
                .agentType("NAVIGATION")
                .message("어느 화면으로 이동할까요? 프로젝트·자재·장비·원가·구매발주·대시보드 중 선택해주세요.")
                .build();
    }

    // ── RAG Agent ──────────────────────────────────────────────────────
    private ChatResponse handleRag(String msg, List<ChatMessage> history) {
        List<String> docs = ragDocumentService.retrieve(msg, 3);

        String context = docs.isEmpty() ? ""
                : "참고 문서:\n" + String.join("\n\n---\n", docs);

        String system = """
                당신은 SAP 건설 관리 시스템 전문가입니다.
                아래 참고 문서를 활용하여 사용자 질문에 한국어로 답변하세요.
                참고 문서에 없는 내용은 일반 전문 지식으로 보완하세요.
                답변은 간결하고 구체적으로 작성하세요.

                %s""".formatted(context);

        String answer = ollamaService.chat(system, history, msg);

        List<String> sources = docs.stream()
                .map(d -> { int s = d.indexOf('[') + 1, e = d.indexOf(']'); return (s > 0 && e > s) ? d.substring(s, e) : "SAP 지식"; })
                .distinct().collect(Collectors.toList());

        return ChatResponse.builder()
                .success(true)
                .agentType("RAG")
                .message(answer)
                .sources(sources)
                .build();
    }

    // ── Data Query Agent ───────────────────────────────────────────────
    private ChatResponse handleDataQuery(String msg, List<ChatMessage> history) {
        String low = msg.toLowerCase();
        StringBuilder data = new StringBuilder("=== 현재 시스템 데이터 ===\n");

        if (containsAny(low, "프로젝트", "공사", "현장")) {
            try {
                List<Project> list = projectService.findAll();
                data.append("\n[프로젝트 현황] 총 ").append(list.size()).append("건\n");
                list.stream().limit(8).forEach(p ->
                        data.append("• ").append(p.getProjectName())
                                .append(" | 상태: ").append(p.getStatus())
                                .append(" | 진도: ").append(p.getProgressRate()).append("%\n"));
            } catch (Exception e) { log.warn("프로젝트 조회 실패: {}", e.getMessage()); }
        }

        if (containsAny(low, "자재", "재고", "mrp")) {
            try {
                List<Material> list = materialService.findAll();
                data.append("\n[자재 현황] 총 ").append(list.size()).append("종\n");
                list.stream().limit(8).forEach(m ->
                        data.append("• ").append(m.getMaterialName())
                                .append(" | 재고: ").append(m.getStockQuantity())
                                .append(" ").append(m.getUnit()).append("\n"));
                List<Material> low2 = materialService.findLowStockMaterials();
                if (!low2.isEmpty()) {
                    data.append("⚠ 안전재고 미달 자재: ")
                            .append(low2.stream().map(Material::getMaterialName).collect(Collectors.joining(", ")))
                            .append("\n");
                }
            } catch (Exception e) { log.warn("자재 조회 실패: {}", e.getMessage()); }
        }

        if (containsAny(low, "장비", "기계", "중장비")) {
            try {
                List<Equipment> list = equipmentService.findAll();
                data.append("\n[장비 현황] 총 ").append(list.size()).append("대\n");
                list.stream().limit(8).forEach(eq ->
                        data.append("• ").append(eq.getEquipmentName())
                                .append(" | 상태: ").append(eq.getStatus()).append("\n"));
            } catch (Exception e) { log.warn("장비 조회 실패: {}", e.getMessage()); }
        }

        String system = """
                당신은 SAP 건설 관리 시스템의 데이터 분석 어시스턴트입니다.
                아래 실시간 데이터를 기반으로 사용자 질문에 한국어로 답변하세요.

                %s""".formatted(data);

        String answer = ollamaService.chat(system, history, msg);

        return ChatResponse.builder()
                .success(true)
                .agentType("DATA_QUERY")
                .message(answer)
                .build();
    }

    // ── General Chat Agent ─────────────────────────────────────────────
    private ChatResponse handleChat(String msg, List<ChatMessage> history) {
        String system = """
                당신은 SAP 건설 관리 시스템의 AI 어시스턴트입니다.
                건설 프로젝트 관리, SAP 모듈(PS/MM/CO/PM), 원가 관리 등에 관해 도움을 드립니다.
                한국어로 친절하고 전문적으로 답변하세요.

                시스템 주요 메뉴: 대시보드 / PS-프로젝트 / MM-자재관리 / MM-구매발주 / PM-장비관리 / CO-원가관리
                화면 이동이나 데이터 조회가 필요하면 말씀해 주세요.""";

        String answer = ollamaService.chat(system, history, msg);

        return ChatResponse.builder()
                .success(true)
                .agentType("CHAT")
                .message(answer)
                .build();
    }

    // ── 헬퍼 ─────────────────────────────────────────────────────────
    private boolean containsAny(String text, String... keywords) {
        String low = text.toLowerCase();
        for (String kw : keywords) if (low.contains(kw.toLowerCase())) return true;
        return false;
    }

    record NavEntry(NavigationInfo nav, String[] keywords) {}
}
