# Laboratorios guiados

Esta carpeta contiene el bloque practico del seminario en formato notebook.

Cada laboratorio tiene dos versiones:

- notebook del alumno: guiado, con pasos, TODOs, checkpoints y reflexion;
- notebook de solucion: mismo recorrido, pero completamente resuelto.

## Orden recomendado

1. `01_laboratorio_ollama_y_embeddings.ipynb`
2. `02_laboratorio_qdrant_y_chunking.ipynb`
3. `03_laboratorio_indexacion_y_retrieval.ipynb`
4. `04_laboratorio_rag_y_evaluacion.ipynb`

## Duracion sugerida

- Laboratorio 1: 2 horas
- Laboratorio 2: 2 horas
- Laboratorio 3: 2 horas
- Laboratorio 4: 2 horas

Total: 8 horas

## Prerequisitos

- `docker compose up -d`
- modelos descargados en Ollama
- entorno Python del repositorio instalado
- familiaridad basica con Python, terminal y Jupyter

Para la preparacion del entorno, usa:

- `requisitos_alumnos.md`
- `scripts/preflight.ps1` o `scripts/preflight.sh`
- `scripts/pull-models.ps1` o `scripts/pull-models.sh`

## Relacion con los notebooks base

- Laboratorio 1 se apoya en `notebooks/00_ollama_y_embeddings.ipynb`
- Laboratorio 2 se apoya en `notebooks/01_qdrant_desde_cero.ipynb` y `notebooks/02_langchain_chunking.ipynb`
- Laboratorio 3 se apoya en `notebooks/03_indexacion_en_qdrant.ipynb`
- Laboratorio 4 se apoya en `notebooks/04_rag_con_langchain.ipynb`

## Sugerencia de uso en aula

- Explicar primero el notebook base correspondiente.
- Pasar despues al notebook del alumno para trabajo guiado.
- Reservar los ultimos 15-20 minutos para reflexion y puesta en comun.
- Usar la version resuelta como referencia o correccion.
