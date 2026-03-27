"""
Data Query Node
사용자 메시지에서 조회 대상을 파악해 ABAP REST API를 호출,
결과를 data_context에 저장.
실제 자연어 응답은 response_generator 노드에서 생성.
"""

import re
from graph.state import AgentState
from tools.abap_api import (
    fetch_projects,
    fetch_project_stats,
    fetch_materials,
    fetch_equipment,
    fetch_cost_summary,
    fetch_purchase_orders,
)


def _detect_entity(message: str) -> str:
    """메시지에서 조회 대상 엔티티를 파악."""
    msg = message.lower()

    if any(k in msg for k in ["통계", "stats", "현황 요약", "대시보드"]):
        return "project_stats"
    if any(k in msg for k in ["프로젝트", "project", "공사"]):
        return "projects"
    if any(k in msg for k in ["저재고", "재고 부족", "안전재고", "low stock"]):
        return "low_stock"
    if any(k in msg for k in ["자재", "material"]):
        return "materials"
    if any(k in msg for k in ["장비", "equipment", "크레인", "굴착기", "덤프"]):
        return "equipment"
    if any(k in msg for k in ["원가", "cost", "비용", "노무비", "자재비"]):
        return "cost"
    if any(k in msg for k in ["발주", "purchase", "구매", "po"]):
        return "purchase_orders"

    return "projects"  # 기본값


def _detect_status_filter(message: str) -> str | None:
    """상태 필터 키워드 추출."""
    mapping = {
        "진행중": "IN_PROGRESS",
        "완료":   "COMPLETED",
        "계획":   "PLANNING",
        "입찰":   "BIDDING",
        "수주":   "CONTRACTED",
        "중단":   "SUSPENDED",
        "사용가능": "AVAILABLE",
        "사용중":  "IN_USE",
        "점검":   "MAINTENANCE",
        "고장":   "BROKEN",
    }
    for keyword, status in mapping.items():
        if keyword in message:
            return status
    return None


def data_query_node(state: AgentState) -> dict:
    message = state["message"]
    entity  = _detect_entity(message)
    status  = _detect_status_filter(message)

    match entity:
        case "project_stats":
            context = fetch_project_stats()
        case "projects":
            context = fetch_projects(status=status)
        case "low_stock":
            context = fetch_materials(low_stock_only=True)
        case "materials":
            context = fetch_materials()
        case "equipment":
            context = fetch_equipment(status=status)
        case "cost":
            context = fetch_cost_summary()
        case "purchase_orders":
            context = fetch_purchase_orders(status=status)
        case _:
            context = fetch_projects()

    return {
        "data_context": context,
        "agent_type":   "DATA_QUERY",
    }
