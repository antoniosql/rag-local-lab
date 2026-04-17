#!/usr/bin/env sh
set -eu

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

CHAT_MODEL="${CHAT_MODEL:-llama3}"
EMBEDDING_MODEL="${EMBEDDING_MODEL:-embeddinggemma}"

echo "==> Cargando modelo de chat: ${CHAT_MODEL}"
docker compose exec ollama ollama pull "${CHAT_MODEL}"

echo "==> Cargando modelo de embeddings: ${EMBEDDING_MODEL}"
docker compose exec ollama ollama pull "${EMBEDDING_MODEL}"

echo "==> Modelos disponibles:"
docker compose exec ollama ollama list
