package org.sap.ai.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class NavigationInfo {
    private String path;    // e.g. "/projects"
    private String label;   // e.g. "프로젝트 목록"
}
