package org.sap.ai.model;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class ChatResponse {
    private String message;
    private String agentType;       // CHAT | RAG | NAVIGATION | DATA_QUERY | ERROR
    private NavigationInfo navigation;
    private List<String> sources;   // RAG 출처
    private boolean success;
    private String error;
}
