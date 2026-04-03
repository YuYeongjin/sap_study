from typing import TypedDict, Literal


class AgentState(TypedDict):
    """LangGraph 전체 에이전트 공유 상태"""

    # 입력
    message: str
    history: list[dict]          # [{"role": "user"|"assistant", "content": "..."}]

    # 라우팅
    intent: Literal["navigation", "rag", "data_query", "crud", "chat", "abap_explain"]

    # RAG 에이전트 결과
    retrieved_docs: list[str]
    sources: list[str]

    # 데이터 조회 에이전트 결과
    data_context: str

    # 네비게이션 에이전트 결과
    navigation_path: str | None   # 프론트엔드 경로 (e.g. "/projects")
    navigation_label: str | None  # 화면명 (e.g. "프로젝트 목록")

    # CRUD 에이전트 결과
    crud_result: str              # 처리 결과 메시지

    # 최종 응답
    response: str
    agent_type: str              # 프론트엔드 뱃지 표시용
