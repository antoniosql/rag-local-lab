#!/usr/bin/env sh
set -eu

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

OLLAMA_PORT="${OLLAMA_PORT:-11434}"
QDRANT_PORT="${QDRANT_PORT:-6333}"
ANYTHINGLLM_PORT="${ANYTHINGLLM_PORT:-3001}"

wait_for_url() {
  url="$1"
  name="$2"
  retries="${3:-20}"
  delay="${4:-2}"

  i=1
  while [ "$i" -le "$retries" ]; do
    if curl -sf "$url" >/dev/null; then
      echo "${name} OK"
      return 0
    fi
    sleep "$delay"
    i=$((i + 1))
  done

  echo "${name} no responde tras ${retries} intentos: ${url}"
  return 1
}

echo "==> Estado de contenedores"
docker compose ps

echo "==> Comprobando Ollama..."
wait_for_url "http://localhost:${OLLAMA_PORT}/api/tags" "Ollama"

echo "==> Comprobando Qdrant..."
wait_for_url "http://localhost:${QDRANT_PORT}/collections" "Qdrant"

echo "==> Comprobando AnythingLLM..."
wait_for_url "http://localhost:${ANYTHINGLLM_PORT}" "AnythingLLM"

echo "==> Stack verificado"
