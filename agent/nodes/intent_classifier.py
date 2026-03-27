"""
Intent Classifier Node
사용자 메시지를 분석해 5가지 intent 중 하나로 분류.

navigation  - 화면 이동 요청
rag         - SAP/건설 지식 질문
data_query  - 실시간 데이터 조회 요청
crud        - 데이터 생성/수정/삭제 요청
chat        - 일반 대화
"""

from langchain_ollama import ChatOllama
from langchain_core.prompts import ChatPromptTemplate
from graph.state import AgentState
from config import OLLAMA_BASE_URL, OLLAMA_MODEL

# --- 키워드 기반 1차 분류 ---

_NAV_TRIGGERS = {"이동해", "열어줘", "가줘", "화면", "페이지", "열어", "보여줘"}
_NAV_SCREENS  = {"대시보드", "dashboard", "프로젝트 목록", "자재", "장비", "구매발주", "원가"}

_CRUD_CREATE  = {"만들어", "생성", "추가", "등록", "새로", "create", "add"}
_CRUD_UPDATE  = {"수정", "변경", "업데이트", "바꿔", "update", "edit", "설정"}
_CRUD_DELETE  = {"삭제", "제거", "지워", "remove", "delete"}

_RAG_TERMS    = {"SAP", "PS", "MM", "CO", "PM", "WBS", "MRP", "ERP", "S/4HANA",
                 "모듈", "개념", "기능", "마스터", "트랜잭션", "하도급", "공정률"}

_DATA_TERMS   = {"현황", "현재", "조회", "확인", "얼마나", "몇 개", "몇개",
                 "목록", "상태", "재고", "통계", "실적", "집계"}


def _keyword_classify(message: str) -> str | None:
    msg = message.strip()

    # CRUD 가장 먼저 (명확한 동작 의도)
    if any(k in msg for k in _CRUD_CREATE | _CRUD_UPDATE | _CRUD_DELETE):
        return "crud"

    # 이동 요청
    nav_trigger = any(k in msg for k in _NAV_TRIGGERS)
    nav_screen  = any(k in msg for k in _NAV_SCREENS)
    if nav_trigger or (nav_screen and "이동" in msg):
        return "navigation"

    # SAP 전문용어 2개 이상 → RAG
    if sum(1 for k in _RAG_TERMS if k in msg) >= 2:
        return "rag"

    # 데이터 조회
    if sum(1 for k in _DATA_TERMS if k in msg) >= 2:
        return "data_query"

    return None


_CLASSIFIER_PROMPT = ChatPromptTemplate.from_messages([
    ("system", """You are an intent classifier for a SAP construction management chatbot.
Classify the user message into exactly one of these intents:

- navigation: User wants to navigate to a screen/page
- rag: User asks about SAP concepts, module features, construction terminology
- data_query: User asks to view/check current data (list, status, count, stock)
- crud: User wants to create, update, or delete data
- chat: General conversation, greetings, or unclear intent

Reply with ONLY the intent word, nothing else."""),
    ("human", "{message}"),
])


def classify_intent(state: AgentState) -> dict:
    message = state["message"]
    intent  = _keyword_classify(message)

    if intent is None:
        llm    = ChatOllama(base_url=OLLAMA_BASE_URL, model=OLLAMA_MODEL, temperature=0)
        chain  = _CLASSIFIER_PROMPT | llm
        result = chain.invoke({"message": message})
        raw    = result.content.strip().lower()
        intent = raw if raw in {"navigation", "rag", "data_query", "crud", "chat"} else "chat"

    return {"intent": intent}
