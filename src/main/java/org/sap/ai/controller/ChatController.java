package org.sap.ai.controller;

import lombok.RequiredArgsConstructor;
import org.sap.ai.model.ChatRequest;
import org.sap.ai.model.ChatResponse;
import org.sap.ai.service.AgentOrchestrator;
import org.sap.ai.service.OllamaService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class ChatController {

    private final AgentOrchestrator agentOrchestrator;
    private final OllamaService ollamaService;

    /** 메인 채팅 엔드포인트 */
    @PostMapping("/chat")
    public ResponseEntity<ChatResponse> chat(@RequestBody ChatRequest request) {
        ChatResponse response = agentOrchestrator.process(request);
        return ResponseEntity.ok(response);
    }

    /** Ollama 연결 상태 확인 */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> status() {
        boolean available = ollamaService.isAvailable();
        return ResponseEntity.ok(Map.of(
                "available", available,
                "model", ollamaService.getModel(),
                "status", available ? "연결됨" : "연결 안됨"
        ));
    }
}
