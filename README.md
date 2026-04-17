# Taller RAG Local con Ollama + Qdrant + LangChain

Repositorio base para un workshop de RAG local pensado para aula.

La filosofía del taller cambia respecto a una demo "todo en contenedores":

1. Docker se usa para los servicios compartidos y fáciles de visualizar.
2. La solución Python se ejecuta en local, en el equipo del alumno.
3. El recorrido principal se hace con notebooks para poder inspeccionar cada etapa.
4. LangChain se usa como capa didáctica de orquestación, chunking y construcción del flujo RAG.
5. AnythingLLM se añade al inicio del seminario para enseñar visualmente una solución RAG completa antes de bajar al código.

---

## Arquitectura del workshop

```text
Seminario
  ↓
docker compose up
  ↓
Ollama + Qdrant + AnythingLLM
  ↓
Demo visual de RAG y discusión de opciones
  ↓
Python local + notebooks
  ↓
LangChain
  ├── carga de documentos
  ├── chunking con RecursiveCharacterTextSplitter
  ├── embeddings con Ollama
  ├── retrieval sobre Qdrant
  └── cadena RAG para respuesta final
```

---

## Qué incluye este repositorio

- `docker-compose.yml` para levantar:
  - `ollama`
  - `qdrant`
  - `anythingllm`
- `docker-compose.gpu.yml` como override opcional para NVIDIA.
- Código Python en `app/` para reutilizar desde CLI, notebooks y API local.
- Notebooks guiados en `notebooks/`.
- Documentos de ejemplo en `docs/`.
- Preguntas de evaluación en `evaluation/questions.csv`.
- Scripts de utilidad en `scripts/`.
- Material para preparar un aula sin Internet en `offline/`.

---

## Filosofía didáctica

### Fase 1: ver una solución RAG funcionando

La sesión arranca con `AnythingLLM` para enseñar:

- qué aspecto tiene una experiencia RAG para negocio,
- cómo se conectan LLM, embeddings y vector DB,
- qué decisiones de producto aparecen antes de escribir código,
- qué se gana y qué se pierde con una herramienta low-code.

### Fase 2: reconstruir el sistema por dentro

Después pasamos a los notebooks para que el alumnado vea y modifique:

- cómo se cargan y limpian documentos,
- cómo afecta el chunking,
- cómo se generan embeddings,
- cómo se indexa en Qdrant,
- cómo retrieval y generación se combinan en un pipeline RAG.

### Fase 3: ejecutar Python en local

La app Python ya no es el centro del `docker compose`.
Ahora corre en local para que sea más sencillo:

- depurar,
- imprimir variables intermedias,
- editar código rápidamente,
- usar notebooks sin fricción,
- comparar alternativas de implementación.

---

## Requisitos

### Infraestructura

- Docker Engine o Docker Desktop con Docker Compose v2.
- 16 GB de RAM recomendados.
- 15 GB libres en disco para modelos y volúmenes.

### Entorno local de desarrollo

- Python 3.11 o superior.
- `pip`.
- `venv`.
- JupyterLab recomendado para los notebooks.

### GPU NVIDIA opcional

- Linux o Windows con WSL2.
- NVIDIA Container Toolkit.
- Docker configurado para exponer la GPU a `ollama`.

---

## Modelos usados

Por defecto:

- chat: `llama3`
- embeddings: `embeddinggemma`

Se pueden cambiar en `.env`.

---

## Configuración

Si no tienes `.env`, copia el ejemplo:

```bash
cp .env.example .env
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
APP_PORT=8000
ANYTHINGLLM_PORT=3001
```

---

## Arranque rápido

### 1. Verifica prerequisitos

```bash
./scripts/preflight.sh
```

En Windows:

```powershell
.\scripts\preflight.ps1
```

### 2. Levanta la infraestructura

```bash
docker compose up -d
./scripts/pull-models.sh
./scripts/verify-stack.sh
```

Esto deja arriba:

- Ollama
- Qdrant
- AnythingLLM

### 3. Crea el entorno local de Python

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-local.txt
```

En Windows PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-local.txt
```

### 4. Arranca los notebooks

```bash
jupyter lab
```

### 5. Ejecuta la solución local

CLI desde `app/`:

```bash
cd app
python -m rag.ingest --docs-dir ../docs --force-recreate
python -m rag.ask --question "¿Puedo devolver una mesa ya montada?"
python -m rag.evaluate --csv ../evaluation/questions.csv
```

API opcional en local:

```bash
cd app
uvicorn api:app --host 127.0.0.1 --port 8000
```

---

## Inicio del seminario con AnythingLLM

Abre:

- AnythingLLM: `http://localhost:3001`
- Qdrant Dashboard: `http://localhost:6333/dashboard`

Sugerencia de arranque para el instructor:

1. Entrar en AnythingLLM.
2. Crear un workspace con los documentos del taller.
3. Configurar Ollama apuntando a `http://ollama:11434`.
4. Configurar Qdrant apuntando a `http://qdrant:6333`.
5. Hacer una o dos preguntas y discutir:
   - diferencia entre chat y RAG,
   - decisión de modelo,
   - decisión de embedder,
   - decisión de vector store,
   - importancia del chunking,
   - coste de usar una herramienta empaquetada frente a código propio.

El objetivo no es que AnythingLLM sustituya el laboratorio en Python, sino usarlo como mapa visual del problema.

---

## Flujo recomendado para el alumnado

### Sesión 1

1. Levantar Ollama, Qdrant y AnythingLLM.
2. Observar una solución RAG terminada desde la UI.
3. Abrir `notebooks/00_entender_arquitectura.ipynb`.
4. Ejecutar `notebooks/01_laboratorio_chunking.ipynb`.
5. Ejecutar `notebooks/02_laboratorio_embeddings_qdrant.ipynb`.

Guion: `labs/01_sesion_1_stack_y_retrieval.md`

### Sesión 2

1. Ejecutar `notebooks/03_laboratorio_retrieval_y_rag.ipynb`.
2. Ajustar `CHUNK_SIZE`, `CHUNK_OVERLAP` y `TOP_K`.
3. Ejecutar `notebooks/04_laboratorio_evaluacion.ipynb`.
4. Probar la CLI y la API local.

Guion: `labs/02_sesion_2_rag_y_evaluacion.md`

---

## Servicios y puertos

| Servicio | URL local | Uso |
|---|---|---|
| Ollama | `http://localhost:11434` | Generación y embeddings |
| Qdrant REST | `http://localhost:6333` | API vectorial |
| Qdrant Dashboard | `http://localhost:6333/dashboard` | Inspección de colecciones |
| AnythingLLM | `http://localhost:3001` | Demo visual y low-code RAG |
| API Python local | `http://127.0.0.1:8000` | Opcional, si lanzas `uvicorn` en local |

---

## LangChain en este repo

LangChain se usa para reforzar conceptos clave del workshop:

- `RecursiveCharacterTextSplitter` para chunking reproducible.
- `ChatPromptTemplate` y `StrOutputParser` para la parte de orquestación.
- `ChatOllama` y `OllamaEmbeddings` como integración local con Ollama.

La intención es que el alumnado vea una estructura realista, pero sin perder transparencia sobre cada paso.

---

## Comandos útiles

Levantar el stack:

```bash
docker compose up -d
```

Ver contenedores:

```bash
docker compose ps
```

Ver logs:

```bash
docker compose logs -f ollama
docker compose logs -f qdrant
docker compose logs -f anythingllm
```

Ver modelos cargados:

```bash
docker compose exec ollama ollama list
```

Ingesta local:

```bash
cd app
python -m rag.ingest --docs-dir ../docs --force-recreate
```

Pregunta local:

```bash
cd app
python -m rag.ask --question "¿Qué debo hacer si faltan tornillos?"
```

Evaluación local:

```bash
cd app
python -m rag.evaluate --csv ../evaluation/questions.csv
```

---

## Uso con `make`

```bash
make up
make pull-models
make verify
make ingest
make ask Q="¿Puedo devolver una mesa ya montada?"
make evaluate
make down
```

---

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
├── offline/
├── scripts/
└── app/
    ├── requirements.txt
    ├── api.py
    ├── settings.py
    └── rag/
        ├── ask.py
        ├── chunking.py
        ├── evaluate.py
        ├── ingest.py
        ├── ollama_client.py
        ├── pipeline.py
        ├── prompting.py
        └── vector_store.py
```

---

## Troubleshooting

### `model not found`

Faltan modelos en Ollama:

```bash
./scripts/pull-models.sh
```

### Qdrant no arranca

```bash
docker compose logs qdrant
```

### AnythingLLM abre pero no responde bien

Revisa en la UI que esté usando:

- Ollama: `http://ollama:11434`
- Qdrant: `http://qdrant:6333`

### Python local no recupera nada

Probablemente no has ejecutado la ingesta local:

```bash
cd app
python -m rag.ingest --docs-dir ../docs --force-recreate
```

### En CPU va lento

Es normal.
Puedes:

- precargar modelos con `./scripts/warm-models.sh`,
- usar preguntas más cortas,
- bajar `TOP_K`,
- trabajar por parejas.

---

## Notas para el instructor

- La demo visual va primero; el código va después.
- El alumnado no necesita construir una imagen Docker de la app Python.
- Si el aula es offline, prepara imágenes de:
  - `ollama`
  - `qdrant`
  - `anythingllm`
- Lleva también el volumen de modelos de Ollama ya sembrado.
- Usa los notebooks para ir revelando el sistema por capas.

---

## Siguiente paso

Empieza por:

```bash
./scripts/preflight.sh
docker compose up -d
./scripts/pull-models.sh
```

y abre `http://localhost:3001` para la primera demo visual.
