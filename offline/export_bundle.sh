#!/usr/bin/env sh
set -eu

OUT_DIR="${1:-offline}"
OUT_FILE="${OUT_DIR}/docker-images.tar"
HELPER_IMAGE="busybox:1.36.1"

mkdir -p "${OUT_DIR}"

echo "==> Asegurando imagen auxiliar para exportar el volumen..."
docker pull "${HELPER_IMAGE}"

echo "==> Exportando imágenes Docker a ${OUT_FILE} ..."
docker save -o "${OUT_FILE}" \
  ollama/ollama \
  qdrant/qdrant \
  "${HELPER_IMAGE}"

echo "==> Bundle creado en ${OUT_FILE}"
