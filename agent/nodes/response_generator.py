"""
Response Generator Node
RAG / Data Query 결과를 컨텍스트로 삼아 Ollama LLM이 최종 응답 생성.
"""

from langchain_ollama import ChatOllama
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage
from ..graph.state import AgentState
from ..config import OLLAMA_BASE_URL, OLLAMA_MODEL

_SYSTEM_PROMPT = """당신은 건설 프로젝트 관리 SAP 시스템의 AI 어시스턴트입니다.
사용자의 질문에 대해 아래 컨텍스트를 참고하여 친절하고 정확하게 답변하세요.
컨텍스트에 없는 내용은 일반 지식으로 보완하되, 확실하지 않은 내용은 솔직히 밝히세요.
답변은 한국어로 하며, 핵심 내용을 먼저 말하고 필요 시 상세 설명을 추가하세요."""


def _build_messages(state: AgentState, context: str) -> list:
    messages = [SystemMessage(content=_SYSTEM_PROMPT)]

    # 이전 대화 히스토리 추가 (최근 6턴)
    for turn in state.get("history", [])[-6:]:
        role    = turn.get("role", "user")
        content = turn.get("content", "")
        if role == "user":
            messages.append(HumanMessage(content=content))
        else:
            messages.append(AIMessage(content=content))

    # 컨텍스트 + 현재 질문
    user_msg = f"[참고 정보]\n{context}\n\n[질문]\n{state['message']}"
    messages.append(HumanMessage(content=user_msg))
    return messages


def response_generator(state: AgentState) -> dict:
    llm = ChatOllama(base_url=OLLAMA_BASE_URL, model=OLLAMA_MODEL, temperature=0.3)

    # RAG 또는 데이터 쿼리 컨텍스트 선택
    if state.get("retrieved_docs"):
        context = "\n\n".join(state["retrieved_docs"])
    elif state.get("data_context"):
        context = state["data_context"]
    else:
        context = "관련 정보 없음"

    messages = _build_messages(state, context)
    result   = llm.invoke(messages)

    return {"response": result.content}
