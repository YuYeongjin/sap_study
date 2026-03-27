"""
FastAPI 서버 - SAP 건설관리 AI 챗봇
엔드포인트:
  POST /api/ai/chat   - ChatBot.jsx와 동일한 인터페이스
  GET  /api/ai/status - Ollama 연결 상태 확인
"""

from contextlib import asynccontextmanager
import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from .graph.orchestrator import get_graph
from .rag.vector_store import VectorStore
from .config import OLLAMA_BASE_URL, OLLAMA_MODEL, API_HOST, API_PORT


# --- 시작 시 벡터 스토어 초기화 ---
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


# --- 스키마 (ChatBot.jsx 요청/응답 형식과 동일) ---
class ChatMessage(BaseModel):
    role: str      # "user" | "assistant"
    content: str


class ChatRequest(BaseModel):
    message: str
    history: list[ChatMessage] = []


class ChatResponse(BaseModel):
    message: str
    agentType: str
    sources: list[str] = []
    navigationPath: str | None = None


# --- 엔드포인트 ---

@app.post("/api/ai/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    graph = get_graph()

    initial_state = {
        "message":        req.message,
        "history":        [m.model_dump() for m in req.history],
        "intent":         "chat",     # 기본값; intent_classifier가 덮어씀
        "retrieved_docs": [],
        "sources":        [],
        "data_context":   "",
        "navigation_path": None,
        "response":       "",
        "agent_type":     "CHAT",
    }

    final_state = await graph.ainvoke(initial_state)

    return ChatResponse(
        message        = final_state.get("response", ""),
        agentType      = final_state.get("agent_type", "CHAT"),
        sources        = final_state.get("sources", []),
        navigationPath = final_state.get("navigation_path"),
    )


@app.get("/api/ai/status")
async def status():
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=5)
            resp.raise_for_status()
            models = [m["name"] for m in resp.json().get("models", [])]
        return {
            "available": True,
            "model":     OLLAMA_MODEL,
            "models":    models,
        }
    except Exception as e:
        return {
            "available": False,
            "model":     OLLAMA_MODEL,
            "error":     str(e),
        }


# --- 직접 실행 ---
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("agent.main:app", host=API_HOST, port=API_PORT, reload=True)
