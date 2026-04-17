# Notebooks del taller

Estos notebooks son ahora el camino principal del workshop.

La idea es que el alumnado explore el sistema desde Python local, no desde un contenedor de aplicación.

## Orden recomendado

1. `00_entender_arquitectura.ipynb`
2. `01_laboratorio_chunking.ipynb`
3. `02_laboratorio_embeddings_qdrant.ipynb`
4. `03_laboratorio_retrieval_y_rag.ipynb`
5. `04_laboratorio_evaluacion.ipynb`

## Preparación

Antes de abrir Jupyter:

```bash
docker compose up -d
./scripts/pull-models.sh
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-local.txt
jupyter lab
```

## Enfoque didáctico

- Los notebooks usan Python local.
- La infraestructura vive en Docker.
- LangChain se usa para hacer explícitos chunking, prompts y orquestación.
- El alumnado debe inspeccionar variables intermedias y no tratar el pipeline como una caja negra.

## Recomendación para el instructor

- Empezar la sesión mostrando `AnythingLLM`.
- Pasar a notebooks solo después de que el grupo tenga una imagen mental del sistema.
- Validar cada checkpoint antes de pasar al siguiente notebook.
