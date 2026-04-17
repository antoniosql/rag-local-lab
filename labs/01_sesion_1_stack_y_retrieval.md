# Laboratorio — Sesión 1

## Objetivo

Levantar la infraestructura, arrancar el seminario con una demo visual en `AnythingLLM` y construir después la primera mitad del pipeline en local: **documentos + chunking + embeddings + Qdrant**.

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

## Paso 5 — Demo visual inicial

Abrir:

- `http://localhost:3001`
- `http://localhost:6333/dashboard`

En `AnythingLLM`, comentad en grupo:

1. Qué piezas del sistema parece esconder la herramienta.
2. Qué opciones de configuración creéis que afectan a la calidad.
3. Qué ganamos en velocidad y qué perdemos en control.

## Paso 6 — Preparar Python local

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-local.txt
```

## Paso 7 — Leer los documentos

Revisad:

- `docs/politica_devoluciones.md`
- `docs/manual_mesa_oslo.md`

Antes de indexar, responded verbalmente:

1. Qué documento responde mejor a preguntas de devolución.
2. Qué documento responde mejor a preguntas de montaje.
3. Qué preguntas no se podrían responder con estos documentos.

## Paso 8 — Notebook de chunking

Ejecutad:

- `notebooks/00_entender_arquitectura.ipynb`
- `notebooks/01_laboratorio_chunking.ipynb`

La idea es inspeccionar cómo LangChain divide el contenido y qué cambia al tocar `chunk_size` y `chunk_overlap`.

## Paso 9 — Notebook de embeddings e indexación

Ejecutad:

- `notebooks/02_laboratorio_embeddings_qdrant.ipynb`

## Paso 10 — Inspeccionar Qdrant

Comprobad en el dashboard que:

- existe la colección `frasohome_docs`,
- hay puntos cargados,
- el payload contiene `source`, `doc_type`, `chunk_id`, `text`.

## Checkpoints de la sesión

- [ ] Los servicios `ollama`, `qdrant` y `anythingllm` están arriba.
- [ ] Ollama responde.
- [ ] Qdrant responde.
- [ ] AnythingLLM abre correctamente.
- [ ] La colección está creada.
- [ ] Los chunks son razonables para las preguntas del dominio.

## Debate final

1. ¿Qué simplifica AnythingLLM y qué queda oculto?
2. ¿Tiene sentido el tamaño de chunk usado?
3. ¿Cambiarías el overlap?
