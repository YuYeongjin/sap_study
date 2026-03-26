package org.sap.ai.service;

import lombok.extern.slf4j.Slf4j;
import org.sap.ai.model.ChatMessage;
import org.sap.ai.model.OllamaApiRequest;
import org.sap.ai.model.OllamaApiResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;

@Service
@Slf4j
public class OllamaService {

    @Value("${ollama.base-url:http://localhost:11434}")
    private String baseUrl;

    @Value("${ollama.model:llama3.1}")
    private String model;

    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * 시스템 프롬프트 + 대화 히스토리 + 사용자 메시지로 Ollama 호출
     */
    public String chat(String systemPrompt, List<ChatMessage> history, String userMessage) {
        List<ChatMessage> messages = new ArrayList<>();

        if (systemPrompt != null && !systemPrompt.isBlank()) {
            messages.add(new ChatMessage("system", systemPrompt));
        }
        if (history != null) {
            messages.addAll(history);
        }
        messages.add(new ChatMessage("user", userMessage));

        OllamaApiRequest request = OllamaApiRequest.builder()
                .model(model)
                .messages(messages)
                .stream(false)
                .build();

        try {
            OllamaApiResponse response = restTemplate.postForObject(
                    baseUrl + "/api/chat", request, OllamaApiResponse.class);

            if (response != null && response.getMessage() != null) {
                return response.getMessage().getContent();
            }
            return "응답을 받지 못했습니다.";
        } catch (Exception e) {
            log.error("Ollama 호출 실패: {}", e.getMessage());
            throw new RuntimeException("Ollama 서비스 오류: " + e.getMessage());
        }
    }

    /** 단순 1회 호출 */
    public String simpleChat(String prompt) {
        return chat(null, null, prompt);
    }

    /** Ollama 가동 여부 확인 */
    public boolean isAvailable() {
        try {
            restTemplate.getForObject(baseUrl + "/api/tags", String.class);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public String getModel() {
        return model;
    }
}
