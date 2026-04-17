from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    ollama_base_url: str
    qdrant_url: str
    chat_model: str
    embedding_model: str
    collection_name: str
    chunk_size: int
    chunk_overlap: int
    top_k: int

    @property
    def ollama_host(self) -> str:
        if self.ollama_base_url.endswith("/api"):
            return self.ollama_base_url[: -len("/api")]
        return self.ollama_base_url.rstrip("/")

    @classmethod
    def from_env(cls) -> "Settings":
        chunk_size = int(os.getenv("CHUNK_SIZE", "650"))
        chunk_overlap = int(os.getenv("CHUNK_OVERLAP", "100"))
        top_k = int(os.getenv("TOP_K", "3"))

        if chunk_overlap >= chunk_size:
            raise ValueError("CHUNK_OVERLAP debe ser menor que CHUNK_SIZE")

        return cls(
            ollama_base_url=os.getenv("OLLAMA_BASE_URL", "http://localhost:11434/api"),
            qdrant_url=os.getenv("QDRANT_URL", "http://localhost:6333"),
            chat_model=os.getenv("CHAT_MODEL", "llama3"),
            embedding_model=os.getenv("EMBEDDING_MODEL", "embeddinggemma"),
            collection_name=os.getenv("COLLECTION_NAME", "frasohome_docs"),
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap,
            top_k=top_k,
        )
