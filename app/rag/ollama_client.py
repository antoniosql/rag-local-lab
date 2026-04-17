from __future__ import annotations

from typing import Any

import requests


class OllamaAPIError(RuntimeError):
    """Error de interacción con la API local de Ollama."""


class OllamaClient:
    def __init__(self, base_url: str, timeout: int = 300) -> None:
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.session = requests.Session()

    def _url(self, endpoint: str) -> str:
        endpoint = endpoint.lstrip("/")
        return f"{self.base_url}/{endpoint}"

    def _request(self, method: str, endpoint: str, **kwargs: Any) -> dict:
        try:
            response = self.session.request(method, self._url(endpoint), timeout=self.timeout, **kwargs)
            response.raise_for_status()
        except requests.HTTPError as exc:
            message = exc.response.text if exc.response is not None else str(exc)
            if exc.response is not None and exc.response.status_code == 404 and "model" in message.lower():
                raise OllamaAPIError(
                    "Ollama no encuentra el modelo solicitado. "
                    "Asegúrate de ejecutar scripts/pull-models.sh o de restaurar el volumen offline."
                ) from exc
            raise OllamaAPIError(f"Error HTTP en Ollama: {message}") from exc
        except requests.RequestException as exc:
            raise OllamaAPIError(f"No se pudo contactar con Ollama en {self.base_url}: {exc}") from exc

        if not response.text:
            return {}
        return response.json()

    def list_models(self) -> list[str]:
        data = self._request("GET", "tags")
        return [model["name"] for model in data.get("models", [])]

    def warm_model(self, model: str) -> dict:
        return self._request(
            "POST",
            "generate",
            json={"model": model, "keep_alive": -1},
        )

    def embed(self, input_text: str | list[str], model: str) -> list[list[float]]:
        data = self._request(
            "POST",
            "embed",
            json={
                "model": model,
                "input": input_text,
            },
        )
        embeddings = data.get("embeddings")
        if not embeddings:
            raise OllamaAPIError("La respuesta de embeddings no contiene vectores")
        return embeddings

    def chat(self, *, model: str, system_prompt: str, user_prompt: str) -> str:
        data = self._request(
            "POST",
            "chat",
            json={
                "model": model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                "stream": False,
            },
        )
        message = data.get("message", {})
        content = message.get("content", "").strip()
        if not content:
            raise OllamaAPIError("La respuesta de chat de Ollama está vacía")
        return content
