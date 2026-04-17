from __future__ import annotations

from pathlib import Path

from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_ollama import ChatOllama, OllamaEmbeddings
from settings import Settings

from .chunking import chunk_documents, load_documents
from .ollama_client import OllamaClient
from .prompting import RAG_SYSTEM_PROMPT, build_context, build_user_prompt, extract_unique_sources
from .vector_store import VectorStore


class RAGPipeline:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.ollama = OllamaClient(base_url=settings.ollama_base_url)
        self.store = VectorStore(url=settings.qdrant_url)
        self.embeddings = OllamaEmbeddings(
            model=settings.embedding_model,
            base_url=settings.ollama_host,
        )
        self.chat_model = ChatOllama(
            model=settings.chat_model,
            base_url=settings.ollama_host,
            temperature=0,
        )
        self.answer_chain = (
            ChatPromptTemplate.from_messages(
                [
                    ("system", RAG_SYSTEM_PROMPT),
                    ("human", "{user_prompt}"),
                ]
            )
            | self.chat_model
            | StrOutputParser()
        )

    def ingest_directory(self, docs_dir: Path, force_recreate: bool = False) -> dict:
        documents = load_documents(docs_dir)
        chunks = chunk_documents(
            documents,
            chunk_size=self.settings.chunk_size,
            overlap=self.settings.chunk_overlap,
        )
        if not chunks:
            raise ValueError("No se han generado chunks a partir de los documentos")

        texts = [chunk["text"] for chunk in chunks]
        vectors = self.embeddings.embed_documents(texts)

        vector_size = len(vectors[0])
        self.store.ensure_collection(
            collection_name=self.settings.collection_name,
            vector_size=vector_size,
            recreate=force_recreate,
        )
        self.store.upsert(
            collection_name=self.settings.collection_name,
            chunks=chunks,
            vectors=vectors,
        )

        return {
            "status": "ok",
            "documents_indexed": len(documents),
            "chunks_indexed": len(chunks),
            "collection_name": self.settings.collection_name,
            "embedding_model": self.settings.embedding_model,
            "vector_size": vector_size,
        }

    def retrieve(self, question: str, top_k: int | None = None) -> list[dict]:
        top_k = top_k or self.settings.top_k
        query_vector = self.embeddings.embed_query(question)
        return self.store.query(
            collection_name=self.settings.collection_name,
            query_vector=query_vector,
            limit=top_k,
        )

    def ask(self, question: str, top_k: int | None = None) -> dict:
        hits = self.retrieve(question=question, top_k=top_k)
        sources = extract_unique_sources(hits)

        if not hits:
            abstention = "No tengo evidencia suficiente en los documentos proporcionados."
            return {
                "question": question,
                "answer": abstention,
                "sources": [],
                "hits": [],
            }

        context = build_context(hits)
        user_prompt = build_user_prompt(question=question, context=context)
        answer = self.answer_chain.invoke({"user_prompt": user_prompt}).strip()

        return {
            "question": question,
            "answer": answer,
            "sources": sources,
            "hits": hits,
        }
