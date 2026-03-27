"""
Navigation Node
화면 이동 요청을 파싱해 프론트엔드 경로와 응답 메시지를 반환.
"""

import re
from graph.state import AgentState

# App.jsx 라우트와 정확히 일치시켜야 함
_NAV_MAP = [
    (r"대시보드|dashboard|홈|메인",                       "/dashboard",       "대시보드"),
    (r"프로젝트 목록|프로젝트 리스트|프로젝트 관리|projects list", "/projects",   "프로젝트 목록"),
    (r"자재|materials|material|재고",                      "/materials",       "자재 관리"),
    (r"구매.*발주|발주.*구매|purchase.order|구매발주|발주",  "/purchase-orders", "구매발주 관리"),
    (r"장비|equipment|크레인|굴착기|덤프",                  "/equipment",       "장비 관리"),
    (r"원가|cost|비용|CO 모듈",                            "/cost",            "원가 관리"),
    (r"프로젝트|project",                                  "/projects",        "프로젝트 목록"),
]


def navigation_node(state: AgentState) -> dict:
    message = state["message"]

    path  = "/dashboard"
    label = "대시보드"

    for pattern, nav_path, nav_label in _NAV_MAP:
        if re.search(pattern, message, re.IGNORECASE):
            path  = nav_path
            label = nav_label
            break

    return {
        "navigation_path":  path,
        "navigation_label": label,
        "response":         f"{label} 화면으로 이동합니다.",
        "agent_type":       "NAVIGATION",
    }
