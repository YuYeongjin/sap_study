from langgraph.graph import StateGraph, END
from .state import AgentState
from ..nodes.intent_classifier import classify_intent
from ..nodes.rag_node import rag_node
from ..nodes.data_query_node import data_query_node
from ..nodes.navigation_node import navigation_node
from ..nodes.chat_node import chat_node
from ..nodes.response_generator import response_generator


def route_by_intent(state: AgentState) -> str:
    """intent 필드 기반으로 다음 노드 결정"""
    return state["intent"]


def build_graph() -> StateGraph:
    """
    LangGraph 멀티 에이전트 워크플로우

    START
      ↓
    intent_classifier
      ├── "navigation"  → navigation_node → END
      ├── "rag"         → rag_node → response_generator → END
      ├── "data_query"  → data_query_node → response_generator → END
      └── "chat"        → chat_node → END
    """
    graph = StateGraph(AgentState)

    # 노드 등록
    graph.add_node("intent_classifier", classify_intent)
    graph.add_node("navigation",        navigation_node)
    graph.add_node("rag",               rag_node)
    graph.add_node("data_query",        data_query_node)
    graph.add_node("chat",              chat_node)
    graph.add_node("response_generator", response_generator)

    # 진입점
    graph.set_entry_point("intent_classifier")

    # intent_classifier → 각 에이전트 (조건부 엣지)
    graph.add_conditional_edges(
        "intent_classifier",
        route_by_intent,
        {
            "navigation": "navigation",
            "rag":        "rag",
            "data_query": "data_query",
            "chat":       "chat",
        },
    )

    # RAG / 데이터 조회는 LLM 응답 생성 후 종료
    graph.add_edge("rag",        "response_generator")
    graph.add_edge("data_query", "response_generator")

    # 네비게이션 / 채팅은 직접 종료
    graph.add_edge("navigation",        END)
    graph.add_edge("chat",              END)
    graph.add_edge("response_generator", END)

    return graph.compile()


# 싱글턴 그래프 인스턴스
_graph = None


def get_graph():
    global _graph
    if _graph is None:
        _graph = build_graph()
    return _graph
