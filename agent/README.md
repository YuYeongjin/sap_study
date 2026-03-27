# SAP 건설관리 AI Agent (LangGraph)

Python + LangGraph 기반 멀티 에이전트 AI 챗봇.
Spring Boot의 AgentOrchestrator를 LangGraph 워크플로우로 재구현.

## 아키텍처

```
사용자 메시지
    ↓
intent_classifier  ← 키워드 우선, LLM 보조로 intent 분류
    ├── navigation  → navigation_node  → 프론트엔드 경로 반환
    ├── rag         → rag_node  → response_generator  → LLM 응답
    ├── data_query  → data_query_node → response_generator  → LLM 응답
    └── chat        → chat_node  → LLM 자유 대화
```

## 폴더 구조

```
agent/
├── main.py                   # FastAPI 서버 (POST /api/ai/chat, GET /api/ai/status)
├── config.py                 # 환경변수 설정
├── requirements.txt
├── .env.example
├── graph/
│   ├── state.py              # AgentState (LangGraph 공유 상태)
│   └── orchestrator.py      # StateGraph 정의 및 컴파일
├── nodes/
│   ├── intent_classifier.py # 키워드 + LLM 기반 intent 분류
│   ├── navigation_node.py   # 화면 이동 경로 매핑
│   ├── rag_node.py          # FAISS 벡터 검색
│   ├── data_query_node.py   # ABAP REST API 호출
│   ├── response_generator.py # RAG/데이터 결과 → LLM 응답
│   └── chat_node.py         # 일반 대화 (Fallback)
├── rag/
│   └── vector_store.py      # FAISS + HuggingFace 임베딩 싱글턴
├── tools/
│   └── abap_api.py          # ABAP REST API 호출 유틸
└── knowledge/
    └── sap_knowledge.txt    # RAG 지식 베이스
```

## 설치 및 실행

```bash
cd agent

# 가상환경 생성
python -m venv venv
source venv/bin/activate     # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# 환경변수 설정
cp .env.example .env
# .env 파일에서 ABAP_BASE_URL, OLLAMA_MODEL 등 설정

# 서버 실행 (포트 8080)
python -m agent.main
```

## 에이전트 역할

| 에이전트 | 트리거 | 동작 |
|---------|-------|------|
| **NAVIGATION** | "대시보드 열어줘", "자재 페이지 이동" | 프론트엔드 경로 반환 |
| **RAG** | "SAP PS란?", "WBS가 뭐야" | FAISS 검색 → LLM 응답 + 출처 |
| **DATA_QUERY** | "현재 진행중 프로젝트", "재고 부족 자재" | ABAP API 호출 → LLM 요약 |
| **CHAT** | 일반 대화, 기타 | 히스토리 유지 LLM 대화 |

## 기술 스택

| 역할 | 라이브러리 |
|------|-----------|
| 멀티 에이전트 오케스트레이션 | LangGraph 0.2 |
| LLM 호출 | LangChain + Ollama (llama3.1) |
| 벡터 검색 (RAG) | FAISS + sentence-transformers |
| 임베딩 모델 | paraphrase-multilingual-MiniLM-L12-v2 (한국어 지원) |
| REST 서버 | FastAPI + uvicorn |
| ABAP API 호출 | httpx |

## API

### POST /api/ai/chat
ChatBot.jsx와 동일한 인터페이스.

**Request**
```json
{
  "message": "진행중인 프로젝트 현황 알려줘",
  "history": [
    { "role": "user", "content": "안녕" },
    { "role": "assistant", "content": "안녕하세요!" }
  ]
}
```

**Response**
```json
{
  "message": "현재 진행중인 프로젝트는 2건입니다...",
  "agentType": "DATA_QUERY",
  "sources": [],
  "navigationPath": null
}
```

### GET /api/ai/status
```json
{
  "available": true,
  "model": "llama3.1",
  "models": ["llama3.1", "llama3.2"]
}
```
