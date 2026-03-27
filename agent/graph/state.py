from typing import TypedDict, Annotated, Literal
from langgraph.graph.message import add_messages


class AgentState(TypedDict):
    """LangGraph 전체 에이전트 공유 상태"""

    # 입력
    message: str
    history: list[dict]          # [{"role": "user"|"assistant", "content": "..."}]

    # 라우팅
    intent: Literal["navigation", "rag", "data_query", "chat"]

    # RAG 에이전트 결과
    retrieved_docs: list[str]    # 검색된 문서 청크
    sources: list[str]           # 출처 섹션명

    # 데이터 조회 에이전트 결과
    data_context: str            # ABAP API에서 가져온 데이터 요약

    # 네비게이션 에이전트 결과
    navigation_path: str | None  # 이동할 프론트엔드 경로

    # 최종 응답
    response: str
    agent_type: str              # 프론트엔드 뱃지 표시용
