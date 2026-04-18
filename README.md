# Taller RAG Local con Ollama, Qdrant, AnythingLLM y LangChain

Repositorio base para un taller de RAG local orientado a aula.

La idea es trabajar con el menor número de capas posible:

1. `Docker` para los servicios compartidos y la demo visual.
2. `AnythingLLM` como demostración inicial de un RAG local ya montado.
3. `Jupyter` como entorno principal de aprendizaje.
4. `LangChain`, `langchain-ollama` y `qdrant-client` como librerías del laboratorio.
5. Todo el código explicativo dentro de los notebooks.

## Qué incluye este repositorio

- `docker-compose.yml` con:
  - `ollama`
  - `qdrant`
  - `anythingllm`
- `notebooks/` con el recorrido didáctico completo.
- `docs/` con los documentos de ejemplo.
- `evaluation/questions.csv` con preguntas para probar el RAG.
- `scripts/` para arrancar, verificar y preparar el entorno.

## Filosofía del taller

El taller tiene dos niveles complementarios:

1. Empezar por una demo visual en `AnythingLLM` para enseñar lo que ya podemos hacer en local con RAG.
2. Bajar luego al detalle técnico en notebooks para construir y entender cada pieza.

El recorrido empieza por entender cada pieza por separado y solo después se monta el RAG:

1. Probar `Ollama` como modelo de chat y embeddings.
2. Probar `Qdrant` como base vectorial sin LangChain ni pipeline.
3. Usar `LangChain` para cargar documentos y hacer chunking.
4. Generar embeddings con Ollama e indexar en Qdrant.
5. Unir retrieval y generación en un flujo RAG sencillo.

## Arranque rápido

### 1. Verifica prerequisitos

```text
./scripts/preflight.sh   # bash
.\scripts\preflight.ps1  # PowerShell
```

### 2. Levanta la infraestructura

```text
docker compose up -d
./scripts/pull-models.sh      # bash
.\scripts\pull-models.ps1     # PowerShell
./scripts/verify-stack.sh     # bash
.\scripts\verify-stack.ps1    # PowerShell
```

### 3. Demo inicial en AnythingLLM

Abre:

- `http://localhost:3001` por defecto
- o `http://localhost:${ANYTHINGLLM_PORT}` si has cambiado el puerto en `.env`

El servicio se arranca ya conectado al mismo `Ollama` y `Qdrant` del stack Docker.

Sugerencia para la demo:

1. Crear un workspace.
2. Subir uno o dos documentos de `docs/`.
3. Verificar que usa `Ollama` para chat y embeddings.
4. Mostrar que los datos vectoriales quedan en `Qdrant`.

### 4. Prepara Python local

```text
python -m venv .venv
source .venv/bin/activate      # bash
.\.venv\Scripts\Activate.ps1   # PowerShell
pip install -r requirements-local.txt
jupyter lab
```

## Orden recomendado de notebooks

1. `notebooks/00_ollama_y_embeddings.ipynb`
2. `notebooks/01_qdrant_desde_cero.ipynb`
3. `notebooks/02_langchain_chunking.ipynb`
4. `notebooks/03_indexacion_en_qdrant.ipynb`
5. `notebooks/04_rag_con_langchain.ipynb`

## Servicios y puertos

| Servicio | URL local | Uso |
|---|---|---|
| Ollama | `http://localhost:11434` | Chat y embeddings |
| Qdrant REST | `http://localhost:6333` | API vectorial |
| Qdrant Dashboard | `http://localhost:6333/dashboard` | Inspección manual |
| AnythingLLM | `http://localhost:3001` por defecto | Demo visual del RAG local |

## Variables de entorno

Si no tienes `.env`, copia `.env.example`.

```text
cp .env.example .env           # bash
Copy-Item .env.example .env    # PowerShell
```

Valores por defecto:

```env
CHAT_MODEL=llama3
EMBEDDING_MODEL=embeddinggemma
COLLECTION_NAME=frasohome_docs
CHUNK_SIZE=650
CHUNK_OVERLAP=100
TOP_K=3
OLLAMA_PORT=11434
QDRANT_PORT=6333
ANYTHINGLLM_PORT=3001
```

## Comandos útiles

Levantar servicios:

```text
docker compose up -d
```

Ver estado:

```text
docker compose ps
```

Ver logs:

```text
docker compose logs -f ollama
docker compose logs -f qdrant
docker compose logs -f anythingllm
```

Descargar modelos:

```text
./scripts/pull-models.sh   # bash
.\scripts\pull-models.ps1  # PowerShell
```

Verificar stack:

```text
./scripts/verify-stack.sh   # bash
.\scripts\verify-stack.ps1  # PowerShell
```

## Estructura del repositorio

```text
.
├── .env.example
├── README.md
├── requirements-local.txt
├── docker-compose.yml
├── docker-compose.gpu.yml
├── docs/
├── evaluation/
├── labs/
├── notebooks/
└── scripts/
```

## Troubleshooting

### `model not found`

Faltan modelos en Ollama:

```text
./scripts/pull-models.sh   # bash
.\scripts\pull-models.ps1  # PowerShell
```

### Qdrant no responde

```text
docker compose logs qdrant
```

### AnythingLLM no responde

```text
docker compose logs anythingllm
```

Comprueba tambien que el puerto configurado en `.env` no este ocupado.

### Los notebooks no conectan con Ollama

Comprueba:

- que `docker compose ps` muestra `ollama` en ejecución,
- que `.env` tiene el puerto correcto,
- que `http://localhost:11434/api/tags` responde.

### Retrieval pobre o vacío

Revisa por este orden:

1. Si el chunking está generando fragmentos razonables.
2. Si la colección correcta existe en Qdrant.
3. Si la indexación se ha ejecutado con el modelo de embeddings esperado.
4. Si `TOP_K` es demasiado bajo.

## Material del taller

- Guion de la primera sesión: `labs/01_sesion_1_stack_y_retrieval.md`
- Guion de la segunda sesión: `labs/02_sesion_2_rag_y_evaluacion.md`

## Siguiente paso

Levanta el stack, abre el puerto definido en `ANYTHINGLLM_PORT` para la demo inicial y despues sigue con `notebooks/00_ollama_y_embeddings.ipynb`.
