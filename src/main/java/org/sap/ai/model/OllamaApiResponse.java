package org.sap.ai.model;

import lombok.Data;

@Data
public class OllamaApiResponse {
    private ChatMessage message;
    private Boolean done;
    private String error;
}
