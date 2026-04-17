# Taller RAG Local con Ollama, LangChain y Qdrant

Repositorio base para un taller de RAG local orientado a aula.

La idea es trabajar con el menor número de capas posible:

1. `Docker` solo para los servicios de infraestructura.
2. `Jupyter` como entorno principal de aprendizaje.
3. `LangChain`, `langchain-ollama` y `qdrant-client` como librerías del laboratorio.
4. Todo el código explicativo dentro de los notebooks.

## Qué incluye este repositorio

- `docker-compose.yml` con:
  - `ollama`
  - `qdrant`
- `notebooks/` con el recorrido didáctico completo.
- `docs/` con los documentos de ejemplo.
- `evaluation/questions.csv` con preguntas para probar el RAG.
- `scripts/` para arrancar, verificar y preparar el entorno.

## Filosofía del taller

El recorrido empieza por entender cada pieza por separado y solo después se monta el RAG:

1. Probar `Ollama` como modelo de chat y embeddings.
2. Probar `Qdrant` como base vectorial sin LangChain ni pipeline.
3. Usar `LangChain` para cargar documentos y hacer chunking.
4. Generar embeddings con Ollama e indexar en Qdrant.
5. Unir retrieval y generación en un flujo RAG sencillo.

## Arranque rápido

### 1. Verifica prerequisitos

```bash
./scripts/preflight.sh
```

En Windows PowerShell:

```powershell
.\scripts\preflight.ps1
```

### 2. Levanta la infraestructura

```bash
docker compose up -d
./scripts/pull-models.sh
./scripts/verify-stack.sh
```

En PowerShell:

```powershell
docker compose up -d
.\scripts\pull-models.ps1
.\scripts\verify-stack.ps1
```

### 3. Prepara Python local

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-local.txt
jupyter lab
```

En PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
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

## Variables de entorno

Si no tienes `.env`, copia `.env.example`.

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
```

## Comandos útiles

Levantar servicios:

```bash
docker compose up -d
```

Ver estado:

```bash
docker compose ps
```

Ver logs:

```bash
docker compose logs -f ollama
docker compose logs -f qdrant
```

Descargar modelos:

```bash
./scripts/pull-models.sh
```

Verificar stack:

```bash
./scripts/verify-stack.sh
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

```bash
./scripts/pull-models.sh
```

### Qdrant no responde

```bash
docker compose logs qdrant
```

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

Levanta `ollama` y `qdrant`, instala dependencias locales y abre `notebooks/00_ollama_y_embeddings.ipynb`.
