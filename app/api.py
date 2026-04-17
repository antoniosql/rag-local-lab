from __future__ import annotations

from pathlib import Path

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from settings import Settings
from rag.pipeline import RAGPipeline


settings = Settings.from_env()
pipeline = RAGPipeline(settings)

app = FastAPI(
    title="Taller RAG Local - FrasoHome",
    version="1.0.0",
    description="API mínima para ingesta, retrieval y RAG local con Ollama + Qdrant.",
)


class IngestRequest(BaseModel):
    docs_dir: str = Field(default="../docs", description="Ruta del directorio de documentos")
    force_recreate: bool = Field(default=False, description="Borra y recrea la colección antes de indexar")


class AskRequest(BaseModel):
    question: str = Field(..., min_length=3, description="Pregunta del usuario")
    top_k: int = Field(default=settings.top_k, ge=1, le=10, description="Número de fragmentos a recuperar")


@app.get("/health")
def health() -> dict:
    try:
        return {
            "status": "ok",
            "ollama_models": pipeline.ollama.list_models(),
            "qdrant_collections": pipeline.store.list_collections(),
            "settings": {
                "chat_model": settings.chat_model,
                "embedding_model": settings.embedding_model,
                "collection_name": settings.collection_name,
                "chunk_size": settings.chunk_size,
                "chunk_overlap": settings.chunk_overlap,
                "top_k": settings.top_k,
            },
        }
    except Exception as exc:  # pragma: no cover - infraestructura
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/ingest")
def ingest(request: IngestRequest) -> dict:
    try:
        docs_dir = Path(request.docs_dir)
        return pipeline.ingest_directory(docs_dir=docs_dir, force_recreate=request.force_recreate)
    except Exception as exc:  # pragma: no cover - infraestructura
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/ask")
def ask(request: AskRequest) -> dict:
    try:
        return pipeline.ask(question=request.question, top_k=request.top_k)
    except Exception as exc:  # pragma: no cover - infraestructura
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/retrieve")
def retrieve(request: AskRequest) -> dict:
    try:
        hits = pipeline.retrieve(question=request.question, top_k=request.top_k)
        return {"question": request.question, "hits": hits}
    except Exception as exc:  # pragma: no cover - infraestructura
        raise HTTPException(status_code=500, detail=str(exc)) from exc
