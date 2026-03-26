package org.sap.ai.model;

import lombok.Data;
import java.util.List;

@Data
public class ChatRequest {
    private String message;
    private List<ChatMessage> history;
    private String sessionId;
}
