"""
FAISS 기반 벡터 스토어
- 한국어/다국어 지원 임베딩: paraphrase-multilingual-MiniLM-L12-v2
- 앱 시작 시 sap_knowledge.txt를 로드해 인덱스 빌드
- 싱글턴으로 관리
"""

import re
import glob
import os
from pathlib import Path

from langchain_community.vectorstores import FAISS
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_core.documents import Document

from config import KNOWLEDGE_DIR, ABAP_CODE_DIR, EMBEDDING_MODEL, RAG_TOP_K
from rag.abap_loader import load_abap_documents


def _load_documents(knowledge_dir: str) -> list[Document]:
    """
    knowledge/ 디렉토리의 .txt 파일을 [Section] 헤더 단위로 청킹.
    """
    docs = []
    pattern = os.path.join(knowledge_dir, "*.txt")

    for file_path in glob.glob(pattern):
        text = Path(file_path).read_text(encoding="utf-8")
        filename = Path(file_path).stem

        # [Section Title] 헤더로 분리
        sections = re.split(r"\n(?=\[)", text.strip())
        for section in sections:
            if not section.strip():
                continue
            # 헤더 추출
            header_match = re.match(r"\[(.+?)\]", section)
            source = header_match.group(1) if header_match else filename

            # 빈 줄 단위로 추가 청킹 (문단 분리)
            paragraphs = [p.strip() for p in section.split("\n\n") if p.strip()]
            for para in paragraphs:
                docs.append(Document(
                    page_content=para,
                    metadata={"source": source, "file": filename},
                ))

    return docs


class VectorStore:
    _instance: "VectorStore | None" = None

    def __init__(self):
        embeddings = HuggingFaceEmbeddings(model_name=EMBEDDING_MODEL)

        # SAP 지식 베이스 인덱스
        knowledge_docs = _load_documents(KNOWLEDGE_DIR)
        self._knowledge_store = FAISS.from_documents(knowledge_docs, embeddings)
        self._knowledge_retriever = self._knowledge_store.as_retriever(
            search_type="similarity",
            search_kwargs={"k": RAG_TOP_K},
        )

        # ABAP 코드 인덱스 (별도)
        abap_docs = load_abap_documents(ABAP_CODE_DIR)
        if abap_docs:
            self._abap_store = FAISS.from_documents(abap_docs, embeddings)
            self._abap_retriever = self._abap_store.as_retriever(
                search_type="similarity",
                search_kwargs={"k": 5},
            )
        else:
            self._abap_store = None
            self._abap_retriever = None

    @classmethod
    def get(cls) -> "VectorStore":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def retrieve(self, query: str) -> list[Document]:
        """SAP 지식 베이스에서 검색."""
        return self._knowledge_retriever.invoke(query)

    def retrieve_abap(self, query: str) -> list[Document]:
        """ABAP 코드 인덱스에서 검색."""
        if self._abap_retriever:
            return self._abap_retriever.invoke(query)
        return []
