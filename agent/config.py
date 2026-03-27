from dotenv import load_dotenv
import os

load_dotenv()

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL    = os.getenv("OLLAMA_MODEL", "llama3.1")

ABAP_BASE_URL   = os.getenv("ABAP_BASE_URL", "http://localhost:4004/sap/bc/zconstruction")
ABAP_AUTH       = (os.getenv("ABAP_USER"), os.getenv("ABAP_PASSWORD")) \
                  if os.getenv("ABAP_USER") else None

API_HOST        = os.getenv("API_HOST", "0.0.0.0")
API_PORT        = int(os.getenv("API_PORT", "8080"))

EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL",
                             "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2")
KNOWLEDGE_DIR   = os.getenv("KNOWLEDGE_DIR", "./knowledge")
RAG_TOP_K       = int(os.getenv("RAG_TOP_K", "3"))
