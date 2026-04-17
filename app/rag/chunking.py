from __future__ import annotations

import re
import uuid
from collections import defaultdict
from pathlib import Path
from typing import Iterable

from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter


SUPPORTED_EXTENSIONS = {".md", ".txt"}


def clean_text(text: str) -> str:
    """Normaliza saltos de línea y espacios sin destruir la estructura básica."""
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def guess_doc_type(path: Path) -> str:
    name = path.stem.lower()
    if "politica" in name:
        return "policy"
    if "manual" in name:
        return "manual"
    return "document"


def load_documents(docs_dir: Path) -> list[Document]:
    if not docs_dir.exists():
        raise FileNotFoundError(f"No existe el directorio de documentos: {docs_dir}")

    documents: list[Document] = []
    for path in sorted(docs_dir.iterdir()):
        if path.suffix.lower() not in SUPPORTED_EXTENSIONS:
            continue
        text = clean_text(path.read_text(encoding="utf-8"))
        if not text:
            continue
        documents.append(
            Document(
                page_content=text,
                metadata={
                    "source": path.name,
                    "doc_type": guess_doc_type(path),
                },
            )
        )

    if not documents:
        raise ValueError("No se han encontrado documentos compatibles para indexar")

    return documents


def build_splitter(chunk_size: int, overlap: int) -> RecursiveCharacterTextSplitter:
    return RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=overlap,
        separators=["\n\n", "\n", ". ", " ", ""],
    )


def chunk_text(text: str, chunk_size: int, overlap: int) -> list[str]:
    if not text:
        return []
    return build_splitter(chunk_size=chunk_size, overlap=overlap).split_text(text)


def chunk_documents(documents: Iterable[Document], chunk_size: int, overlap: int) -> list[dict]:
    chunk_records: list[dict] = []
    splitter = build_splitter(chunk_size=chunk_size, overlap=overlap)
    per_source_index: dict[str, int] = defaultdict(int)

    for chunk in splitter.split_documents(list(documents)):
        source = str(chunk.metadata.get("source", "documento"))
        per_source_index[source] += 1
        chunk_id = per_source_index[source]
        stable_id = str(uuid.uuid5(uuid.NAMESPACE_URL, f"{source}:{chunk_id}:{chunk.page_content[:80]}"))
        chunk_records.append(
            {
                "id": stable_id,
                "source": source,
                "doc_type": str(chunk.metadata.get("doc_type", "document")),
                "chunk_id": chunk_id,
                "text": chunk.page_content,
            }
        )

    return chunk_records
