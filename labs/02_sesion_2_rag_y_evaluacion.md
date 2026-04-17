# Laboratorio — Sesión 2

## Objetivo

Pasar de componentes aislados a un flujo RAG completo: indexación, retrieval, generación y evaluación simple.

## Paso 1 — Notebook de indexación

Ejecutad:

- `notebooks/03_indexacion_en_qdrant.ipynb`

## Paso 2 — Revisar la colección en Qdrant

Comprobad en `http://localhost:6333/dashboard` que:

- existe la colección `frasohome_docs`,
- hay puntos cargados,
- el payload contiene `source`, `chunk_id`, `text`.

## Paso 3 — Notebook de RAG completo

Ejecutad:

- `notebooks/04_rag_con_langchain.ipynb`

## Paso 4 — Cambiar una variable del sistema

Modificar en `.env` una sola cosa:

- `CHUNK_SIZE`
- `CHUNK_OVERLAP`
- `TOP_K`

Luego repetid indexación y consulta desde los notebooks.

## Paso 5 — Mini evaluación

Usad el bloque de evaluación del notebook final con:

- `evaluation/questions.csv`

## Checkpoints de la sesión

- [ ] La colección se ha recreado desde notebooks.
- [ ] El sistema responde con contexto recuperado.
- [ ] El sistema distingue mejor entre evidence y alucinación.
- [ ] Se ha cambiado una variable y observado el efecto.
- [ ] El grupo distingue retrieval, contexto y generación.

## Preguntas para discutir

1. Qué falla antes: embeddings, retrieval o prompt final.
2. Cómo afecta `TOP_K` a la calidad de la respuesta.
3. Qué aporta LangChain y qué partes podríamos implementar a mano.
4. Qué cambiarías para pasar de este laboratorio a un piloto real.
