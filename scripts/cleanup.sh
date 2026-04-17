#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

REMOVE_IMAGES=0
REMOVE_OFFLINE_BUNDLES=0
REMOVE_ENV_FILE=0

usage() {
  cat <<'USAGE'
Uso:
  ./scripts/cleanup.sh [--full] [--offline] [--env] [--all]

Qué hace por defecto:
  - Para y elimina contenedores del taller
  - Elimina red y volúmenes del taller
  - Borra cachés Python locales (__pycache__, *.pyc)

Opciones:
  --full      Además elimina imágenes Docker del taller y de base
  --offline   Además elimina bundles offline generados (*.tar, *.tar.gz)
  --env       Además elimina el archivo .env del repositorio
  --all       Equivale a: --full --offline --env
  -h, --help  Muestra esta ayuda
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --full)
      REMOVE_IMAGES=1
      shift
      ;;
    --offline)
      REMOVE_OFFLINE_BUNDLES=1
      shift
      ;;
    --env)
      REMOVE_ENV_FILE=1
      shift
      ;;
    --all)
      REMOVE_IMAGES=1
      REMOVE_OFFLINE_BUNDLES=1
      REMOVE_ENV_FILE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Opción no reconocida: $1" >&2
      echo >&2
      usage >&2
      exit 1
      ;;
  esac
done

cd "$REPO_ROOT"

echo ">> Parando y eliminando contenedores, red, orphans y volúmenes del taller..."
docker compose down -v --remove-orphans || true

echo ">> Eliminando cachés Python locales..."
find "$REPO_ROOT" -type d -name '__pycache__' -prune -exec rm -rf {} + 2>/dev/null || true
find "$REPO_ROOT" -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete 2>/dev/null || true
rm -rf "$REPO_ROOT"/.pytest_cache "$REPO_ROOT"/.mypy_cache 2>/dev/null || true

if [[ "$REMOVE_IMAGES" -eq 1 ]]; then
  echo ">> Eliminando imágenes Docker del taller..."
  docker image rm -f mintplexlabs/anythingllm:latest 2>/dev/null || true
  docker image rm -f busybox:1.36.1 2>/dev/null || true
  docker image rm -f ollama/ollama qdrant/qdrant 2>/dev/null || true
fi

if [[ "$REMOVE_OFFLINE_BUNDLES" -eq 1 ]]; then
  echo ">> Eliminando bundles offline generados..."
  rm -f "$REPO_ROOT"/offline/docker-images.tar \
        "$REPO_ROOT"/offline/ollama-models.tar.gz \
        "$REPO_ROOT"/offline/taller-rag-local-bundle.tar.gz 2>/dev/null || true
fi

if [[ "$REMOVE_ENV_FILE" -eq 1 ]]; then
  echo ">> Eliminando .env local..."
  rm -f "$REPO_ROOT"/.env 2>/dev/null || true
fi

echo
echo "Limpieza completada."
echo
echo "Verificación recomendada:"
echo "  docker ps -a | grep taller-rag-local || true"
echo "  docker volume ls | grep taller-rag-local || true"
if [[ "$REMOVE_IMAGES" -eq 1 ]]; then
  echo "  docker images | egrep 'mintplexlabs/anythingllm|busybox|ollama/ollama|qdrant/qdrant' || true"
fi
