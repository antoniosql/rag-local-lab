from __future__ import annotations

RAG_SYSTEM_PROMPT = """Eres un asistente interno de FrasoHome.

Responde únicamente con la información proporcionada en el contexto recuperado.
Si el contexto no es suficiente para responder, debes decir exactamente:
"No tengo evidencia suficiente en los documentos proporcionados."

No inventes políticas, plazos ni características no presentes en el contexto.
Responde en español, de forma breve y clara.
Al final añade una línea con las fuentes en el formato:
Fuentes: archivo1, archivo2
"""


def build_context(hits: list[dict]) -> str:
    blocks: list[str] = []
    for idx, hit in enumerate(hits, start=1):
        blocks.append(
            f"[Fragmento {idx}]\n"
            f"Fuente: {hit['source']}\n"
            f"Tipo: {hit['doc_type']}\n"
            f"Chunk: {hit['chunk_id']}\n"
            f"Score: {hit['score']:.4f}\n"
            f"Contenido:\n{hit['text']}"
        )
    return "\n\n".join(blocks)


def build_user_prompt(question: str, context: str) -> str:
    return (
        f"Pregunta del usuario:\n{question}\n\n"
        f"Contexto recuperado:\n{context}\n\n"
        "Redacta una respuesta apoyada solo en el contexto anterior."
    )


def extract_unique_sources(hits: list[dict]) -> list[str]:
    seen: list[str] = []
    for hit in hits:
        source = hit.get("source", "")
        if source and source not in seen:
            seen.append(source)
    return seen
