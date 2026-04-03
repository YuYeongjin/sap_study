"""
Intent Classifier Node
사용자 메시지를 분석해 6가지 intent 중 하나로 분류.

navigation   - 화면 이동 요청
rag          - SAP/건설 지식 질문
data_query   - 실시간 데이터 조회 요청
crud         - 데이터 생성/수정/삭제 요청
abap_explain - ABAP 코드·클래스 설명 요청
chat         - 일반 대화
"""

import re
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

# ABAP 코드 설명 트리거
_ABAP_CLASS_RE   = re.compile(r'\bZ[A-Z][A-Z0-9_]{2,}\b')   # ZCL_, ZFI_, ZCO_ 등
_ABAP_CODE_TERMS = {"ABAP", "abap", "클래스", "메서드", "함수모듈", "프로그램", "코드",
                    "DDL", "CDS", "RAP", "REST핸들러", "서비스클래스", "리포트"}
_ABAP_EXPLAIN_VERBS = {"설명", "알려줘", "어떻게", "동작", "구현", "내용", "분석",
                       "뭐야", "뭐하는", "하는거야", "이해", "보여줘"}


def _is_abap_explain(msg: str) -> bool:
    """ABAP 코드 설명 요청인지 판단."""
    has_class   = bool(_ABAP_CLASS_RE.search(msg))
    has_code    = any(t in msg for t in _ABAP_CODE_TERMS)
    has_explain = any(v in msg for v in _ABAP_EXPLAIN_VERBS)

    # Z클래스명 + 설명동사
    if has_class and has_explain:
        return True
    # ABAP 코드 용어 + 설명동사
    if has_code and has_explain:
        return True
    # ABAP 단독 언급
    if "ABAP" in msg or "abap" in msg:
        return True
    return False


def _keyword_classify(message: str) -> str | None:
    msg = message.strip()

    # ABAP 코드 설명 (CRUD보다 먼저 체크)
    if _is_abap_explain(msg):
        return "abap_explain"

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
- abap_explain: User asks to explain ABAP code, a class (ZCL_*, ZFI_*, ZCO_*), method, or program
- chat: General conversation, greetings, or unclear intent

Reply with ONLY the intent word, nothing else."""),
    ("human", "{message}"),
])

_VALID_INTENTS = {"navigation", "rag", "data_query", "crud", "abap_explain", "chat"}


def classify_intent(state: AgentState) -> dict:
    message = state["message"]
    intent  = _keyword_classify(message)

    if intent is None:
        llm    = ChatOllama(base_url=OLLAMA_BASE_URL, model=OLLAMA_MODEL, temperature=0)
        chain  = _CLASSIFIER_PROMPT | llm
        result = chain.invoke({"message": message})
        raw    = result.content.strip().lower()
        intent = raw if raw in _VALID_INTENTS else "chat"

    return {"intent": intent}
