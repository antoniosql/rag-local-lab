#!/usr/bin/env sh
set -eu

echo "==> Comprobando Docker..."
docker --version >/dev/null 2>&1 || { echo "Docker no está disponible"; exit 1; }

echo "==> Comprobando Docker Compose..."
docker compose version >/dev/null 2>&1 || { echo "Docker Compose v2 no está disponible"; exit 1; }

echo "==> Comprobando Visual Studio Code..."
code --version >/dev/null 2>&1 || { echo "Visual Studio Code no está disponible desde terminal (comando code)"; exit 1; }

echo "==> Comprobando curl..."
curl --version >/dev/null 2>&1 || { echo "curl no está disponible"; exit 1; }

echo "==> Comprobando Python..."
python --version >/dev/null 2>&1 || { echo "Python no está disponible"; exit 1; }

echo "==> Comprobación básica OK para Docker, VS Code y Python"
