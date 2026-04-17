from __future__ import annotations

from typing import Iterable

from qdrant_client import QdrantClient
from qdrant_client.models import Distance, PointStruct, VectorParams


class VectorStore:
    def __init__(self, url: str) -> None:
        self.client = QdrantClient(url=url)

    def list_collections(self) -> list[str]:
        collections = self.client.get_collections().collections
        return [collection.name for collection in collections]

    def ensure_collection(self, collection_name: str, vector_size: int, recreate: bool = False) -> None:
        existing = self.list_collections()

        if recreate and collection_name in existing:
            self.client.delete_collection(collection_name=collection_name)
            existing = [name for name in existing if name != collection_name]

        if collection_name not in existing:
            self.client.create_collection(
                collection_name=collection_name,
                vectors_config=VectorParams(size=vector_size, distance=Distance.COSINE),
            )

    def upsert(self, collection_name: str, chunks: Iterable[dict], vectors: Iterable[list[float]]) -> None:
        points: list[PointStruct] = []

        for chunk, vector in zip(chunks, vectors):
            points.append(
                PointStruct(
                    id=chunk["id"],
                    vector=vector,
                    payload={
                        "source": chunk["source"],
                        "doc_type": chunk["doc_type"],
                        "chunk_id": chunk["chunk_id"],
                        "text": chunk["text"],
                    },
                )
            )

        if not points:
            raise ValueError("No hay puntos para insertar en Qdrant")

        self.client.upsert(collection_name=collection_name, wait=True, points=points)

    def query(self, collection_name: str, query_vector: list[float], limit: int = 3) -> list[dict]:
        result = self.client.query_points(
            collection_name=collection_name,
            query=query_vector,
            with_payload=True,
            limit=limit,
        ).points

        hits: list[dict] = []
        for point in result:
            payload = point.payload or {}
            hits.append(
                {
                    "id": str(point.id),
                    "score": float(point.score),
                    "source": payload.get("source", ""),
                    "doc_type": payload.get("doc_type", ""),
                    "chunk_id": payload.get("chunk_id", 0),
                    "text": payload.get("text", ""),
                }
            )

        return hits
