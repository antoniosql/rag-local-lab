#!/usr/bin/env sh
set -eu

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

OLLAMA_PORT="${OLLAMA_PORT:-11434}"
CHAT_MODEL="${CHAT_MODEL:-llama3}"
EMBEDDING_MODEL="${EMBEDDING_MODEL:-embeddinggemma}"

echo "==> Precargando ${CHAT_MODEL}"
curl -s "http://localhost:${OLLAMA_PORT}/api/generate" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"${CHAT_MODEL}\",\"keep_alive\":-1}" >/dev/null

echo "==> Precargando ${EMBEDDING_MODEL}"
curl -s "http://localhost:${OLLAMA_PORT}/api/embed" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"${EMBEDDING_MODEL}\",\"input\":\"warmup\",\"keep_alive\":\"10m\"}" >/dev/null

echo "==> Modelos precargados"
