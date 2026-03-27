"""
Intent Classifier Node
사용자 메시지를 분석해 4가지 intent 중 하나로 분류.

navigation  - 화면 이동 요청
rag         - SAP/건설 지식 질문
data_query  - 실시간 데이터 조회 요청
chat        - 일반 대화
"""

from langchain_ollama import ChatOllama
from langchain_core.prompts import ChatPromptTemplate
from ..graph.state import AgentState
from ..config import OLLAMA_BASE_URL, OLLAMA_MODEL

# --- 키워드 기반 1차 분류 (LLM 호출 최소화) ---

_NAVIGATION_KEYWORDS = {
    "이동", "열어", "가줘", "열어줘", "보여줘", "화면", "페이지",
    "메뉴", "대시보드", "프로젝트 목록", "자재 관리", "장비 관리",
    "구매발주", "원가 관리", "dashboard", "projects", "materials",
    "equipment", "purchase", "cost",
}

_RAG_KEYWORDS = {
    "SAP", "PS", "MM", "CO", "PM", "WBS", "MRP", "ERP",
    "모듈", "기능", "개념", "뭐야", "무엇", "설명", "알려줘",
    "S/4HANA", "HANA", "마스터", "트랜잭션",
    "노무비", "자재비", "장비비", "하도급", "공정률", "예산",
}

_DATA_QUERY_KEYWORDS = {
    "현재", "지금", "현황", "얼마나", "몇 개", "몇개", "조회",
    "확인해줘", "알려줘", "보여줘", "목록", "상태", "진행중",
    "재고", "안전재고", "미달", "발주", "원가", "실적",
}


def _keyword_classify(message: str) -> str | None:
    """빠른 키워드 기반 분류. 명확하지 않으면 None 반환."""
    msg = message.strip()

    # 이동 요청이 가장 명확 → 먼저 체크
    nav_hits = sum(1 for kw in _NAVIGATION_KEYWORDS if kw in msg)
    if nav_hits >= 1 and any(kw in msg for kw in {"이동", "열어", "가줘", "열어줘", "보여"}):
        return "navigation"

    # SAP 전문용어 다수 포함 → RAG
    rag_hits = sum(1 for kw in _RAG_KEYWORDS if kw in msg)
    if rag_hits >= 2:
        return "rag"

    # 데이터 조회 키워드 포함
    data_hits = sum(1 for kw in _DATA_QUERY_KEYWORDS if kw in msg)
    if data_hits >= 2:
        return "data_query"

    return None  # LLM에 위임


# --- LLM 기반 2차 분류 ---

_CLASSIFIER_PROMPT = ChatPromptTemplate.from_messages([
    ("system", """You are an intent classifier for a SAP construction management chatbot.
Classify the user message into exactly one of these intents:

- navigation: User wants to navigate to a screen/page (이동, 화면, 페이지 등)
- rag: User asks about SAP concepts, module features, construction terms
- data_query: User asks about current data (projects, materials, equipment counts/status)
- chat: General conversation, greetings, or unclear intent

Reply with ONLY the intent word, nothing else."""),
    ("human", "{message}"),
])


def classify_intent(state: AgentState) -> dict:
    message = state["message"]

    # 1차: 키워드 분류
    intent = _keyword_classify(message)

    # 2차: LLM 분류 (키워드로 판단 불가할 때)
    if intent is None:
        llm = ChatOllama(base_url=OLLAMA_BASE_URL, model=OLLAMA_MODEL, temperature=0)
        chain = _CLASSIFIER_PROMPT | llm
        result = chain.invoke({"message": message})
        raw = result.content.strip().lower()
        intent = raw if raw in {"navigation", "rag", "data_query", "chat"} else "chat"

    return {"intent": intent}
