# Notas Instructor

Las instrucciones del `README.md` funcionan con el enfoque actual del taller.

Conviene recordar al grupo que los scripts de `scripts/` tienen versión `bash` y versión `PowerShell`.

## Comandos Docker

- `docker compose up -d` levanta `ollama` y `qdrant`.
- `docker compose ps` muestra el estado del stack.
- `docker compose logs ollama` y `docker compose logs qdrant` ayudan a diagnosticar problemas.
- `docker exec -it taller-rag-local-qdrant /bin/bash` permite entrar en el contenedor si hace falta inspección manual.

## Qdrant

- `http://localhost:6333/dashboard` abre la interfaz web.
- Es útil enseñar la colección tras ejecutar el notebook de indexación.
- El alumnado debería comprobar `payload`, `chunk_id` y `source`.

## Guion sugerido

1. Probar `Ollama` por separado.
2. Probar `Qdrant` con vectores manuales.
3. Hacer chunking con `LangChain`.
4. Indexar en `Qdrant`.
5. Montar el RAG final y discutir qué falla cuando la respuesta es mala.
