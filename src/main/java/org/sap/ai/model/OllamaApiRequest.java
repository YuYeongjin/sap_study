package org.sap.ai.model;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class OllamaApiRequest {
    private String model;
    private List<ChatMessage> messages;
    private Boolean stream;
}
