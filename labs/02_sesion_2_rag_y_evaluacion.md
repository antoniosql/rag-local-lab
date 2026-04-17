# Laboratorio — Sesión 2

## Objetivo

Construir la fase de **retrieval + RAG completo** con Python local y LangChain, y terminar con una mini evaluación.

## Paso 1 — Notebook de retrieval y RAG

Ejecutad:

- `notebooks/03_laboratorio_retrieval_y_rag.ipynb`

## Paso 2 — Primera consulta RAG por CLI local

```bash
cd app
python -m rag.ask --question "¿Puedo devolver una mesa ya montada si solo he cambiado de opinión?"
python -m rag.ask --question "¿Qué hago si faltan tornillos en la caja?"
```

## Paso 3 — Probar una consulta que debe abstenerse

```bash
cd app
python -m rag.ask --question "¿Cuál es el plazo de entrega de la mesa Oslo?"
```

## Paso 4 — API opcional en local

```bash
cd app
uvicorn api:app --host 127.0.0.1 --port 8000
```

En otra terminal:

```bash
curl http://localhost:8000/health
```

Consulta RAG por API:

```bash
curl -X POST http://localhost:8000/ask \
  -H "Content-Type: application/json" \
  -d '{
    "question": "¿Qué herramientas necesito para montar la mesa Oslo?",
    "top_k": 3
  }'
```

## Paso 5 — Cambiar una variable del sistema

Modificar en `.env` una sola cosa:

- `CHUNK_SIZE`
- `CHUNK_OVERLAP`
- `TOP_K`

Luego reindexar en local:

```bash
cd app
python -m rag.ingest --docs-dir ../docs --force-recreate
```

## Paso 6 — Notebook de evaluación

Ejecutad:

- `notebooks/04_laboratorio_evaluacion.ipynb`

## Paso 7 — Mini evaluación por CLI

```bash
cd app
python -m rag.evaluate --csv ../evaluation/questions.csv
```

## Checkpoints de la sesión

- [ ] El sistema responde con fuentes.
- [ ] El sistema se abstiene cuando falta evidencia.
- [ ] Se ha cambiado una variable y reindexado.
- [ ] Se ha ejecutado la mini evaluación.
- [ ] El grupo distingue con claridad retrieval y generación.

## Preguntas para discutir

1. ¿Qué falla antes: retrieval o generación?
2. ¿Cómo afecta `TOP_K` a la respuesta?
3. ¿Qué aporta LangChain aquí y qué podríamos hacer sin él?
4. ¿Qué cambiarías para pasar de esta demo a un piloto interno?
