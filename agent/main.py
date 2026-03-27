"""
FastAPI 서버 - SAP 건설관리 AI 챗봇 (LangGraph 멀티 에이전트)
엔드포인트:
  POST /api/ai/chat   - ChatBot.jsx 호환 인터페이스
  GET  /api/ai/status - Ollama 연결 상태 확인
"""

from contextlib import asynccontextmanager
import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from graph.orchestrator import get_graph
from rag.vector_store import VectorStore
from config import OLLAMA_BASE_URL, OLLAMA_MODEL, API_HOST, API_PORT


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("▶ 벡터 스토어 초기화 중...")
    VectorStore.get()
    print("▶ LangGraph 그래프 컴파일 중...")
    get_graph()
    print("✓ AI 에이전트 준비 완료")
    yield


app = FastAPI(title="SAP Construction AI Agent", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── 스키마 ──────────────────────────────────────────────────────────

class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    message: str
    history: list[ChatMessage] = []


class NavigationInfo(BaseModel):
    path: str
    label: str


class ChatResponse(BaseModel):
    message: str
    agentType: str
    sources: list[str] = []
    navigation: NavigationInfo | None = None  # ChatBot.jsx: data.navigation?.path


# ── 엔드포인트 ──────────────────────────────────────────────────────

@app.post("/api/ai/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    graph = get_graph()

    initial_state = {
        "message":          req.message,
        "history":          [m.model_dump() for m in req.history],
        "intent":           "chat",
        "retrieved_docs":   [],
        "sources":          [],
        "data_context":     "",
        "navigation_path":  None,
        "navigation_label": None,
        "crud_result":      "",
        "response":         "",
        "agent_type":       "CHAT",
    }

    final_state = await graph.ainvoke(initial_state)

    # 네비게이션 정보 구성 (ChatBot.jsx: data.navigation?.path)
    nav = None
    if final_state.get("navigation_path"):
        nav = NavigationInfo(
            path  = final_state["navigation_path"],
            label = final_state.get("navigation_label") or "",
        )

    return ChatResponse(
        message    = final_state.get("response", ""),
        agentType  = final_state.get("agent_type", "CHAT"),
        sources    = final_state.get("sources", []),
        navigation = nav,
    )


@app.get("/api/ai/status")
async def status():
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=5)
            resp.raise_for_status()
            models = [m["name"] for m in resp.json().get("models", [])]
        return {"available": True, "model": OLLAMA_MODEL, "models": models}
    except Exception as e:
        return {"available": False, "model": OLLAMA_MODEL, "error": str(e)}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=API_HOST, port=API_PORT, reload=True)
