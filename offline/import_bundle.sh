#!/usr/bin/env sh
set -eu

BUNDLE_FILE="${1:-offline/docker-images.tar}"

if [ ! -f "${BUNDLE_FILE}" ]; then
  echo "No existe ${BUNDLE_FILE}"
  exit 1
fi

echo "==> Cargando imágenes desde ${BUNDLE_FILE} ..."
docker load -i "${BUNDLE_FILE}"
echo "==> Imágenes cargadas"
