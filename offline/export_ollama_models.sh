#!/usr/bin/env sh
set -eu

OUT_DIR="${1:-offline}"
OUT_FILE="${OUT_DIR}/ollama-models.tar.gz"
HELPER_IMAGE="busybox:1.36.1"

mkdir -p "${OUT_DIR}"

echo "==> Exportando volumen de Ollama a ${OUT_FILE} ..."
docker run --rm \
  -v taller-rag-local_ollama_data:/from \
  -v "$(pwd)/${OUT_DIR}:/to" \
  "${HELPER_IMAGE}" \
  sh -c "cd /from && tar czf /to/ollama-models.tar.gz ."

echo "==> Exportación completada"
