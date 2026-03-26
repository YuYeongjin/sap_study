package org.sap.ai.service;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 키워드 기반 문서 검색 (Ollama 임베딩 없이 동작하는 경량 RAG)
 */
@Service
@Slf4j
public class RagDocumentService {

    private final List<DocumentChunk> chunks = new ArrayList<>();

    @PostConstruct
    public void loadDocuments() {
        try {
            ClassPathResource resource = new ClassPathResource("rag/sap_knowledge.txt");
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {

                String content = reader.lines().collect(Collectors.joining("\n"));

                // [섹션 제목] 단위로 분리
                String[] sections = content.split("(?=\\[)");
                for (String section : sections) {
                    if (section.isBlank()) continue;
                    String title = extractTitle(section);

                    // 빈 줄 기준으로 단락 분리
                    String[] paragraphs = section.split("\n\n");
                    for (String para : paragraphs) {
                        String trimmed = para.trim();
                        if (trimmed.length() > 30) {
                            chunks.add(new DocumentChunk(trimmed, title));
                        }
                    }
                }
                log.info("RAG 문서 로드 완료 - {} 청크", chunks.size());
            }
        } catch (Exception e) {
            log.error("RAG 문서 로드 실패: {}", e.getMessage());
        }
    }

    /**
     * TF 기반 키워드 유사도로 상위 K 개 청크 반환
     */
    public List<String> retrieve(String query, int topK) {
        if (chunks.isEmpty()) return Collections.emptyList();

        String[] terms = query.toLowerCase().split("[\\s,./·]+");

        return chunks.stream()
                .map(chunk -> Map.entry(chunk, score(chunk.content().toLowerCase(), terms)))
                .filter(e -> e.getValue() > 0)
                .sorted(Comparator.comparingDouble(e -> -e.getValue()))
                .limit(topK)
                .map(e -> "[출처: " + e.getKey().source() + "]\n" + e.getKey().content())
                .collect(Collectors.toList());
    }

    private double score(String text, String[] terms) {
        double s = 0;
        for (String term : terms) {
            if (term.length() < 2) continue;
            int cnt = countOccurrences(text, term);
            if (cnt > 0) s += (1 + Math.log(cnt)) / Math.sqrt(text.length() + 1);
        }
        return s;
    }

    private int countOccurrences(String text, String term) {
        int count = 0, idx = 0;
        while ((idx = text.indexOf(term, idx)) != -1) { count++; idx += term.length(); }
        return count;
    }

    private String extractTitle(String section) {
        int s = section.indexOf('['), e = section.indexOf(']');
        return (s >= 0 && e > s) ? section.substring(s + 1, e) : "SAP 지식";
    }

    record DocumentChunk(String content, String source) {}
}
