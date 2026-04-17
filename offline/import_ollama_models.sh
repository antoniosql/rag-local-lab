#!/usr/bin/env sh
set -eu

ARCHIVE="${1:-offline/ollama-models.tar.gz}"
HELPER_IMAGE="busybox:1.36.1"

if [ ! -f "${ARCHIVE}" ]; then
  echo "No existe ${ARCHIVE}"
  exit 1
fi

echo "==> Creando volumen de Ollama si no existe..."
docker volume create taller-rag-local_ollama_data >/dev/null

echo "==> Restaurando modelos en el volumen..."
docker run --rm \
  -v taller-rag-local_ollama_data:/to \
  -v "$(pwd)/offline:/from" \
  "${HELPER_IMAGE}" \
  sh -c "cd /to && tar xzf /from/$(basename "${ARCHIVE}")"

echo "==> Restauración completada"
