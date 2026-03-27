"""
RAG Node
FAISS 벡터 스토어에서 관련 문서를 검색해 state에 저장.
실제 LLM 응답은 response_generator 노드에서 생성.
"""

from graph.state import AgentState
from rag.vector_store import VectorStore


def rag_node(state: AgentState) -> dict:
    store = VectorStore.get()
    docs  = store.retrieve(state["message"])

    retrieved_docs = [doc.page_content for doc in docs]
    sources        = list(dict.fromkeys(           # 중복 제거 + 순서 유지
        doc.metadata.get("source", "") for doc in docs
    ))

    return {
        "retrieved_docs": retrieved_docs,
        "sources":        sources,
        "agent_type":     "RAG",
    }
