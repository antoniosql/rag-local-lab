# Laboratorio — Sesión 1

## Objetivo

Abrir una demo local de RAG con `AnythingLLM` y despues entender por separado los componentes básicos del sistema: `Ollama`, `Qdrant` y el procesamiento de documentos con `LangChain`.

## Paso 1 — Preflight

```bash
./scripts/preflight.sh
```

## Paso 2 — Arranque de servicios

```bash
docker compose up -d
docker compose ps
```

## Paso 3 — Cargar y precalentar modelos

```bash
./scripts/pull-models.sh
./scripts/warm-models.sh
```

## Paso 4 — Verificar infraestructura

```bash
./scripts/verify-stack.sh
```

## Paso 5 — Preparar Python local

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-local.txt
```

## Paso 6 — Demo visual inicial

Abrir:

- `http://localhost:3001` por defecto
- `http://localhost:6333/dashboard`

Comprobad que `AnythingLLM` arranca usando el mismo `Ollama` y `Qdrant` del stack.

Sugerencia:

1. Crear un workspace.
2. Subir un documento de `docs/`.
3. Hacer una pregunta corta.
4. Explicar que despues reconstruiremos ese flujo paso a paso en notebooks.

## Paso 7 — Leer los documentos

Revisad:

- `docs/politica_devoluciones.md`
- `docs/manual_mesa_oslo.md`

Antes de indexar, responded verbalmente:

1. Qué documento responde mejor a preguntas de devolución.
2. Qué documento responde mejor a preguntas de montaje.
3. Qué preguntas no se podrían responder con estos documentos.

## Paso 8 — Notebook de Ollama

Ejecutad:

- `notebooks/00_ollama_y_embeddings.ipynb`

## Paso 9 — Notebook de Qdrant

Ejecutad:

- `notebooks/01_qdrant_desde_cero.ipynb`

## Paso 10 — Notebook de chunking

Ejecutad:

- `notebooks/02_langchain_chunking.ipynb`

## Checkpoints de la sesión

- [ ] `ollama` está arriba.
- [ ] `qdrant` está arriba.
- [ ] `anythingllm` está arriba.
- [ ] La demo inicial responde.
- [ ] Ollama responde para chat.
- [ ] Ollama genera embeddings.
- [ ] Qdrant acepta una colección y búsquedas vectoriales.
- [ ] Los chunks son razonables para el dominio.

## Debate final

1. Qué aprende el grupo al ver cada componente aislado.
2. Cómo afecta el tamaño de chunk.
3. Qué información conviene guardar como payload en Qdrant.
