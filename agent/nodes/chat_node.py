"""
Chat Node
일반 대화 / Fallback 처리.
히스토리를 유지하며 Ollama LLM과 자유 대화.
"""

from langchain_ollama import ChatOllama
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage
from graph.state import AgentState
from config import OLLAMA_BASE_URL, OLLAMA_MODEL

_SYSTEM_PROMPT = """당신은 건설 프로젝트 관리 SAP 시스템의 AI 어시스턴트입니다.
다음 메뉴를 제공하는 시스템에서 동작합니다:
- 대시보드: 프로젝트 전체 현황 요약
- 프로젝트 관리 (PS): 건설 프로젝트 목록, 상태, 진도율
- 자재 관리 (MM): 자재 재고, 안전재고 알림
- 구매발주 관리 (MM): 구매 발주서 관리
- 장비 관리 (PM): 건설 장비 현황 및 배정
- 원가 관리 (CO): 프로젝트별 원가 집계

SAP 건설 ERP, 공사 관련 질문에 친절하고 전문적으로 답변하세요.
답변은 한국어로 하세요."""


def chat_node(state: AgentState) -> dict:
    llm = ChatOllama(base_url=OLLAMA_BASE_URL, model=OLLAMA_MODEL, temperature=0.7)

    messages = [SystemMessage(content=_SYSTEM_PROMPT)]

    # 이전 대화 히스토리 (최근 10턴)
    for turn in state.get("history", [])[-10:]:
        role    = turn.get("role", "user")
        content = turn.get("content", "")
        if role == "user":
            messages.append(HumanMessage(content=content))
        else:
            messages.append(AIMessage(content=content))

    messages.append(HumanMessage(content=state["message"]))

    result = llm.invoke(messages)

    return {
        "response":   result.content,
        "agent_type": "CHAT",
    }
