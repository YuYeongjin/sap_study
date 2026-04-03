"""
ABAP 코드 파일 로더
- 프로젝트의 .abap 파일을 Document로 변환하여 벡터 스토어에 인덱싱
- METHOD...ENDMETHOD 단위 청킹, 없으면 파일 전체
"""

import re
import glob
import os
from pathlib import Path
from langchain_core.documents import Document


def _detect_module(filepath: str) -> str:
    """파일 경로에서 SAP 모듈 구분."""
    path = filepath.replace("\\", "/").lower()
    if "/fi/" in path:
        return "FI"
    if "/co/" in path:
        return "CO"
    if "/rap/" in path:
        return "RAP"
    if "/rest/" in path:
        return "REST"
    if "/ddl/" in path:
        return "DDL"
    if "/classes/" in path:
        return "SERVICE"
    if "/reports/" in path:
        return "REPORT"
    if "/data_init/" in path:
        return "DATA_INIT"
    return "PS"


def _chunk_by_method(text: str, filename: str, filepath: str, module: str) -> list[Document]:
    """METHOD...ENDMETHOD 단위로 청킹."""
    docs = []
    pattern = re.compile(
        r'(METHOD\s+\w+\.[\s\S]*?ENDMETHOD\s*\.)',
        re.IGNORECASE,
    )
    for m in pattern.finditer(text):
        method_code = m.group(1)
        name_match = re.match(r'METHOD\s+(\w+)', method_code, re.IGNORECASE)
        method_name = name_match.group(1) if name_match else "unknown"
        docs.append(Document(
            page_content=f"[{filename}] METHOD {method_name}\n{method_code}",
            metadata={
                "source": f"{filename}#{method_name}",
                "file": filename,
                "module": module,
                "type": "abap_method",
            },
        ))
    return docs


def _chunk_fallback(text: str, filename: str, filepath: str, module: str) -> list[Document]:
    """메서드 분리 실패 시 단락 단위 청킹."""
    docs = []
    paragraphs = [p.strip() for p in text.split("\n\n") if len(p.strip()) > 50]
    for i, para in enumerate(paragraphs):
        docs.append(Document(
            page_content=f"[{filename}]\n{para}",
            metadata={
                "source": f"{filename}#p{i}",
                "file": filename,
                "module": module,
                "type": "abap_code",
            },
        ))
    return docs


def load_abap_documents(abap_dir: str) -> list[Document]:
    """ABAP 디렉토리에서 모든 .abap 파일을 로드해 Document 목록 반환."""
    docs = []

    if not os.path.exists(abap_dir):
        print(f"⚠ ABAP 디렉토리를 찾을 수 없음: {abap_dir}")
        return docs

    pattern = os.path.join(abap_dir, "**", "*.abap")
    files = glob.glob(pattern, recursive=True)

    for filepath in files:
        try:
            text = Path(filepath).read_text(encoding="utf-8", errors="replace")
            filename = Path(filepath).stem
            module = _detect_module(filepath)

            method_docs = _chunk_by_method(text, filename, filepath, module)

            if method_docs:
                docs.extend(method_docs)
            else:
                docs.extend(_chunk_fallback(text, filename, filepath, module))

            # 파일 전체 요약 문서 (짧은 파일 또는 DDL)
            if len(text) <= 4000:
                docs.append(Document(
                    page_content=f"[{filename}] ({module} 모듈 전체)\n{text}",
                    metadata={
                        "source": filename,
                        "file": filename,
                        "module": module,
                        "type": "abap_file",
                    },
                ))
        except Exception as e:
            print(f"⚠ {filepath} 로드 실패: {e}")

    print(f"✓ ABAP 코드 {len(files)}개 파일, {len(docs)}개 청크 인덱싱 완료")
    return docs
