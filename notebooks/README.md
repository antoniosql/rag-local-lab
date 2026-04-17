# Notebooks del taller

Estos notebooks son el camino principal del repositorio.

La secuencia está pensada para enseñar cada componente por separado antes de montar el RAG completo.

## Orden recomendado

1. `00_ollama_y_embeddings.ipynb`
2. `01_qdrant_desde_cero.ipynb`
3. `02_langchain_chunking.ipynb`
4. `03_indexacion_en_qdrant.ipynb`
5. `04_rag_con_langchain.ipynb`

## Idea de cada notebook

- `00`: probar Ollama para chat y embeddings.
- `01`: crear, poblar y consultar una colección en Qdrant sin pipeline.
- `02`: cargar documentos y partirlos con LangChain.
- `03`: generar embeddings e indexar chunks en Qdrant.
- `04`: hacer retrieval, construir contexto y generar respuesta final.

## Preparación

```bash
docker compose up -d
./scripts/pull-models.sh
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-local.txt
jupyter lab
```

## Enfoque didáctico

- Todo el código está dentro de los notebooks.
- No hay una capa de aplicacion intermedia, CLI ni API local.
- La infraestructura vive en Docker.
- El alumnado debe inspeccionar valores intermedios en cada paso.
