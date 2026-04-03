"""
ABAP Explain Node
사용자 질문과 관련된 ABAP 코드를 벡터 검색으로 찾아
gemma3:12b LLM이 한국어로 상세 설명.
"""

from langchain_ollama import ChatOllama
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage
from graph.state import AgentState
from rag.vector_store import VectorStore
from config import OLLAMA_BASE_URL, OLLAMA_MODEL

_SYSTEM_PROMPT = """당신은 SAP ABAP 코드 전문 설명가입니다.
아래 ABAP 코드 참고 자료를 바탕으로 사용자의 질문에 한국어로 명확하게 답변하세요.

답변 구조:
1. **목적/역할**: 이 코드/클래스가 무엇을 하는지 한 문장으로 요약
2. **주요 로직**: 핵심 메서드나 처리 흐름 설명
3. **SAP 연계**: FI/CO/PS/MM 등 어떤 모듈·비즈니스 맥락에서 쓰이는지
4. **특이사항**: 주목할 패턴, 예외 처리, 중요 필드 등

기술적으로 정확하되 이해하기 쉽게 설명하세요.
코드 참고 자료가 부족하면 일반 ABAP·SAP 지식으로 보완하고 그 사실을 알려주세요."""


def abap_explain_node(state: AgentState) -> dict:
    store = VectorStore.get()

    # ABAP 코드 인덱스 우선 검색
    abap_docs = store.retrieve_abap(state["message"])

    # 지식 베이스에서도 보완 검색
    knowledge_docs = store.retrieve(state["message"])

    all_docs = abap_docs + knowledge_docs
    if not all_docs:
        return {
            "response":        "관련 ABAP 코드를 찾지 못했습니다. 질문을 더 구체적으로 입력해 주세요.",
            "retrieved_docs":  [],
            "sources":         [],
            "agent_type":      "ABAP_EXPLAIN",
        }

    code_context = "\n\n---\n\n".join(doc.page_content for doc in all_docs)
    sources = list(dict.fromkeys(
        doc.metadata.get("source", "") for doc in all_docs
    ))

    llm = ChatOllama(base_url=OLLAMA_BASE_URL, model=OLLAMA_MODEL, temperature=0.2)

    messages = [SystemMessage(content=_SYSTEM_PROMPT)]

    # 최근 대화 히스토리 (최근 4턴)
    for turn in state.get("history", [])[-4:]:
        role    = turn.get("role", "user")
        content = turn.get("content", "")
        if role == "user":
            messages.append(HumanMessage(content=content))
        else:
            messages.append(AIMessage(content=content))

    user_msg = f"[ABAP 코드 참고 자료]\n{code_context}\n\n[질문]\n{state['message']}"
    messages.append(HumanMessage(content=user_msg))

    result = llm.invoke(messages)

    return {
        "response":       result.content,
        "retrieved_docs": [doc.page_content for doc in all_docs],
        "sources":        sources,
        "agent_type":     "ABAP_EXPLAIN",
    }
