# Temario y guía de estudio — RAG local con Ollama, Qdrant y FrasoHome

**Duración propuesta:** 2 sesiones de 5 horas, 10 horas totales.  
**Formato:** taller guiado con explicación narrativa, discusión técnica y práctica de laboratorio.  
**Caso conductor:** FrasoHome, un asistente privado que responde preguntas sobre dos documentos locales: una política de devoluciones y un manual de montaje.  
**Restricción central:** todo debe ejecutarse en local, en Docker, sin llamadas a servicios cloud durante la práctica.

---

## 0. Punto de partida: qué vamos a construir

El objetivo del taller no es enseñar una herramienta suelta, sino que el alumno entienda cómo se monta una solución mínima de IA generativa local de extremo a extremo. La arquitectura que se practica en el repositorio es deliberadamente sencilla:

```text
Documentos locales
  ↓
Limpieza y chunking
  ↓
Embeddings locales con Ollama
  ↓
Qdrant como base vectorial
  ↓
Retrieval semántico
  ↓
Prompt con contexto
  ↓
llama3 en Ollama
  ↓
Respuesta con fuentes
```

La idea pedagógica es que el alumno vea cada capa por separado. Primero levanta los servicios, después comprueba que Ollama genera texto, después comprueba que Ollama genera embeddings, después inserta vectores en Qdrant, luego recupera fragmentos relevantes y finalmente combina esos fragmentos con un modelo generativo para responder con RAG.

El repositorio que se entrega a los alumnos está pensado para que no dependan de ningún servicio externo en la ejecución del laboratorio. Usa `docker-compose.yml` para levantar tres servicios: `ollama`, `qdrant` y `app`. Ollama queda configurado con `OLLAMA_NO_CLOUD=1`, Qdrant guarda datos en un volumen local y la app Python contiene la lógica mínima del pipeline.

Fragmento relevante del repositorio:

```yaml
services:
  ollama:
    image: ollama/ollama
    ports:
      - "127.0.0.1:${OLLAMA_PORT:-11434}:11434"
    environment:
      OLLAMA_NO_CLOUD: "1"
      OLLAMA_KEEP_ALIVE: "10m"
    volumes:
      - ollama_data:/root/.ollama

  qdrant:
    image: qdrant/qdrant
    ports:
      - "127.0.0.1:${QDRANT_PORT:-6333}:6333"
      - "127.0.0.1:6334:6334"
    volumes:
      - qdrant_data:/qdrant/storage

  app:
    image: taller-rag-local-app:latest
    build:
      context: ./app
    environment:
      OLLAMA_BASE_URL: http://ollama:11434/api
      QDRANT_URL: http://qdrant:6333
      CHAT_MODEL: ${CHAT_MODEL:-llama3}
      EMBEDDING_MODEL: ${EMBEDDING_MODEL:-embeddinggemma}
      COLLECTION_NAME: ${COLLECTION_NAME:-frasohome_docs}
```

Esta arquitectura es pequeña, pero reproduce el patrón de una solución corporativa: separación entre inferencia, almacenamiento vectorial, lógica de aplicación, configuración y evaluación.

---

# 1. Opciones para tener modelos LLM o SLM en local

Antes de tocar el repositorio, conviene que el alumno entienda que “tener un modelo local” puede significar cosas muy distintas. Puede significar ejecutar un modelo desde una interfaz de escritorio, levantar un runtime de inferencia con API, usar un servidor compatible con OpenAI, montar un entorno multiusuario o empaquetar todo como servicio Docker.

También conviene introducir la diferencia entre **LLM** y **SLM**. En la práctica, un LLM suele referirse a modelos grandes de lenguaje con muchas capacidades generales; un SLM, o small language model, suele ser más pequeño, barato y manejable, aunque menos potente. Para un taller local, muchas veces es preferible empezar con modelos pequeños o medianos: arrancan antes, consumen menos memoria y permiten que todos los alumnos completen el flujo.

## 1.1 Ollama

Ollama es la opción elegida en el repositorio porque reduce mucho la fricción para ejecutar modelos locales. Expone una API local por defecto en `http://localhost:11434/api`, ofrece imagen Docker oficial y permite usar modelos de chat y modelos de embeddings desde una interfaz HTTP simple. Además, para RAG es especialmente cómodo porque el endpoint `/api/embed` genera embeddings con modelos específicos como `embeddinggemma`, `qwen3-embedding` o `all-minilm`.

**Pros:**

- Muy sencillo de instalar y usar.
- Buena experiencia para talleres y prototipos.
- API local clara para generación y embeddings.
- Encaja muy bien con Docker.
- Permite trabajar sin cloud si se preparan los modelos previamente.
- La misma herramienta sirve para el modelo generativo y el modelo de embeddings.

**Contras:**

- Abstrae detalles internos de inferencia que puede interesar aprender en cursos avanzados.
- No es la opción más especializada para serving multiusuario de alto rendimiento.
- La gestión fina de batching, paralelismo y rendimiento es más limitada que en runtimes orientados a producción intensiva.

En el taller, Ollama cumple dos papeles:

```python
# Generar embeddings
self.ollama.embed(batch, model=self.settings.embedding_model)

# Generar respuesta final
self.ollama.chat(
    model=self.settings.chat_model,
    system_prompt=RAG_SYSTEM_PROMPT,
    user_prompt=user_prompt,
)
```

Ese doble papel es didácticamente muy útil, porque los alumnos ven que el modelo de embeddings y el modelo de chat son piezas distintas, aunque las sirva la misma plataforma.

**Referencias oficiales:** Ollama documenta su API local, su endpoint `/api/embed`, su uso con Docker y la opción de ejecución local-only. Ver: https://docs.ollama.com/api/introduction, https://docs.ollama.com/api/embed, https://docs.ollama.com/docker y https://docs.ollama.com/faq.

## 1.2 llama.cpp

llama.cpp es una de las piezas fundamentales del ecosistema local. Está pensado para inferencia eficiente en C/C++, especialmente con modelos en formato GGUF, y permite ejecutar modelos cuantizados en CPU y GPU. Además, su servidor HTTP ofrece endpoints compatibles con OpenAI, rutas para chat, embeddings, respuestas y otros patrones habituales.

**Pros:**

- Muy eficiente y portable.
- Excelente para entender formatos como GGUF y cuantización.
- Permite mucho control de bajo nivel.
- Puede servir modelos con un servidor OpenAI-compatible.
- Es una gran opción para entornos muy ajustados o donde se quiere controlar exactamente el runtime.

**Contras:**

- Requiere más conocimiento técnico que Ollama.
- El flujo de descarga, formato, cuantización y parámetros puede ser más intimidante para alumnos junior.
- En un taller de 10 horas puede distraer del objetivo principal, que es construir el RAG completo.

En este curso lo mencionamos como alternativa importante, pero no lo usamos como runtime principal porque el objetivo es que todos completen el pipeline. Si el curso fuera más avanzado, una buena extensión sería repetir el laboratorio usando llama.cpp y un modelo GGUF.

**Referencias oficiales:** el repositorio de llama.cpp documenta su servidor ligero compatible con OpenAI y el soporte de modelos cuantizados; Hugging Face documenta el uso de GGUF con llama.cpp. Ver: https://github.com/ggml-org/llama.cpp y https://huggingface.co/docs/hub/gguf-llamacpp.

## 1.3 LM Studio

LM Studio es una aplicación de escritorio orientada a descargar, ejecutar y probar modelos locales con una interfaz gráfica. También puede actuar como servidor local con endpoints compatibles con OpenAI, lo que permite reutilizar clientes existentes cambiando el `base_url` a una dirección local.

**Pros:**

- Muy cómodo para usuarios que prefieren interfaz gráfica.
- Buen entorno para explorar modelos y comparar respuestas.
- Permite levantar un servidor local en `localhost`.
- Facilita la adopción en perfiles menos técnicos.

**Contras:**

- Es menos apropiado para enseñar despliegue reproducible con Docker.
- Puede ocultar demasiado la arquitectura real.
- No es ideal cuando se quiere que todos los alumnos practiquen `docker compose`, volúmenes, servicios y red local.

En el taller, LM Studio se presenta como una opción práctica para experimentar, pero no como base del laboratorio porque la prioridad es aprender una arquitectura reproducible y automatizable.

**Referencias oficiales:** LM Studio documenta su servidor local y endpoints compatibles con OpenAI. Ver: https://lmstudio.ai/docs/developer/core/server y https://lmstudio.ai/docs/developer/openai-compat.

## 1.4 AnythingLLM

AnythingLLM es una aplicación all-in-one que permite trabajar con modelos, documentos, RAG y agentes con poca o ninguna configuración. Puede ser muy útil para usuarios de negocio o para una demo rápida de “chat con documentos”.

**Pros:**

- Experiencia muy integrada.
- Permite tener documentos, chats, RAG y agentes en una misma aplicación.
- Reduce mucho la barrera de entrada.
- Puede ser muy útil para demostrar valor rápidamente.

**Contras:**

- Para un taller técnico puede ocultar demasiado el pipeline.
- El alumno puede terminar usando una herramienta, pero sin entender bien embeddings, chunking, vector DB y prompt con contexto.
- Menos adecuado si el objetivo es que ellos construyan la solución por capas.

En este curso se menciona como comparación: AnythingLLM es interesante cuando quieres productividad inmediata; el repositorio del taller es mejor cuando quieres aprendizaje técnico profundo.

**Referencias oficiales:** AnythingLLM se presenta como una aplicación de escritorio para local LLMs, RAG y agentes con poca configuración. Ver: https://docs.anythingllm.com/installation-desktop/overview y https://docs.anythingllm.com/introduction.

## 1.5 Open WebUI

Open WebUI es una interfaz web self-hosted que puede operar offline y conectarse a Ollama o APIs compatibles con OpenAI. Tiene funcionalidades de Knowledge/RAG, modelos, chats y gestión de experiencia de usuario.

**Pros:**

- Muy buena experiencia de usuario.
- Self-hosted y compatible con Ollama.
- Permite cargar documentos y usar RAG sin construir todo desde cero.
- Muy útil para un piloto interno o una demo ejecutiva.

**Contras:**

- En un curso donde el objetivo es construir el pipeline, puede hacer demasiadas cosas automáticamente.
- Puede distraer del aprendizaje de Qdrant, embeddings y chunking.
- No sustituye la necesidad de entender qué ocurre por debajo.

Open WebUI es una buena continuación del taller: cuando el alumno ya entiende cómo funciona el RAG por dentro, se puede añadir una interfaz de usuario para hacerlo más adoptable.

**Referencias oficiales:** Open WebUI se describe como plataforma self-hosted que puede operar offline y soporta Ollama y APIs compatibles con OpenAI; también documenta Knowledge/RAG. Ver: https://docs.openwebui.com/ y https://docs.openwebui.com/features/workspace/knowledge/.

## 1.6 vLLM y servidores de producción

vLLM no es la herramienta que usaría para este laboratorio junior, pero sí merece aparecer como referencia. Está más orientada a servir modelos con mayor rendimiento, mejor throughput y patrones de backend. En despliegues multiusuario con GPU, colas, concurrencia y latencia controlada, empiezan a aparecer necesidades que van más allá del prototipo local.

**Pros:**

- Más orientado a serving de alto rendimiento.
- Encaja bien en arquitecturas backend.
- Compatible con clientes HTTP y patrones de API.

**Contras:**

- Más complejo para un taller inicial.
- Requiere más atención a hardware y configuración.
- No aporta tanto al objetivo pedagógico de construir el RAG desde cero.

La idea que debe quedar es que Ollama es una gran puerta de entrada, llama.cpp enseña control de inferencia y vLLM se acerca más a serving de producción. El repositorio está diseñado para Ollama porque prioriza claridad, reproducibilidad y baja fricción.

---

# 2. Análisis del repositorio del taller

El repositorio tiene una estructura pequeña pero completa. Cada carpeta representa una capa del sistema:

```text
taller-rag-local-starter/
├── docker-compose.yml
├── docker-compose.gpu.yml
├── .env.example
├── app/
│   ├── api.py
│   ├── settings.py
│   └── rag/
│       ├── chunking.py
│       ├── ollama_client.py
│       ├── vector_store.py
│       ├── prompting.py
│       ├── pipeline.py
│       ├── ingest.py
│       ├── ask.py
│       └── evaluate.py
├── docs/
│   ├── politica_devoluciones.md
│   └── manual_mesa_oslo.md
├── evaluation/
│   └── questions.csv
├── labs/
│   ├── 01_sesion_1_stack_y_retrieval.md
│   └── 02_sesion_2_rag_y_evaluacion.md
├── scripts/
└── offline/
```

El diseño es muy intencionado. No se usa LangChain ni LlamaIndex en el código base, porque se quiere que el alumno vea la mecánica interna sin una abstracción alta. Sin embargo, durante la teoría sí se explica cómo estos frameworks encapsulan patrones parecidos.

## 2.1 `settings.py`: configuración centralizada

`settings.py` lee variables de entorno y define la configuración operativa: URL de Ollama, URL de Qdrant, modelo de chat, modelo de embeddings, colección, chunk size, overlap y top-k.

```python
@dataclass(frozen=True)
class Settings:
    ollama_base_url: str
    qdrant_url: str
    chat_model: str
    embedding_model: str
    collection_name: str
    chunk_size: int
    chunk_overlap: int
    top_k: int

    @classmethod
    def from_env(cls) -> "Settings":
        chunk_size = int(os.getenv("CHUNK_SIZE", "650"))
        chunk_overlap = int(os.getenv("CHUNK_OVERLAP", "100"))
        top_k = int(os.getenv("TOP_K", "3"))

        if chunk_overlap >= chunk_size:
            raise ValueError("CHUNK_OVERLAP debe ser menor que CHUNK_SIZE")
```

Este fichero es importante porque enseña una práctica de ingeniería: no hardcodear parámetros. En RAG, `CHUNK_SIZE`, `CHUNK_OVERLAP` y `TOP_K` son variables experimentales. Deben poder cambiarse sin tocar el código.

## 2.2 `chunking.py`: del documento al fragmento recuperable

`chunking.py` carga documentos `.md` o `.txt`, limpia el texto, infiere un tipo básico de documento y lo divide en chunks con solape. Este módulo representa la fase de preparación documental.

```python
def chunk_text(text: str, chunk_size: int, overlap: int) -> list[str]:
    if not text:
        return []

    chunks: list[str] = []
    start = 0
    text_len = len(text)

    while start < text_len:
        ideal_end = min(start + chunk_size, text_len)
        end = _best_split_position(text, start, ideal_end)
        if end <= start:
            end = min(start + chunk_size, text_len)

        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)

        if end >= text_len:
            break

        start = max(0, end - overlap)
```

La función `_best_split_position` intenta cortar por doble salto de línea, por final de frase o por espacio. Es una aproximación sencilla al problema de chunking. Sirve para enseñar que no todos los cortes son iguales: cortar en mitad de una frase o una tabla puede degradar la recuperación.

## 2.3 `ollama_client.py`: hablar con el modelo local

Este cliente encapsula las llamadas HTTP a Ollama. Tiene tres métodos centrales: listar modelos, generar embeddings y chatear con el modelo.

```python
def embed(self, input_text: str | list[str], model: str) -> list[list[float]]:
    data = self._request(
        "POST",
        "embed",
        json={
            "model": model,
            "input": input_text,
        },
    )
    embeddings = data.get("embeddings")
    if not embeddings:
        raise OllamaAPIError("La respuesta de embeddings no contiene vectores")
    return embeddings
```

Este punto es clave en la explicación: embeddings no son respuestas generativas; son vectores. En el repositorio, `llama3` se usa para responder y `embeddinggemma` para representar texto como vectores.

## 2.4 `vector_store.py`: encapsular Qdrant

`vector_store.py` crea colecciones, inserta puntos y consulta por similitud. Cada punto de Qdrant contiene un vector y un payload con metadatos.

```python
PointStruct(
    id=chunk["id"],
    vector=vector,
    payload={
        "source": chunk["source"],
        "doc_type": chunk["doc_type"],
        "chunk_id": chunk["chunk_id"],
        "text": chunk["text"],
    },
)
```

El payload es tan importante como el vector. El vector sirve para encontrar fragmentos similares; el payload permite reconstruir qué texto se recuperó, de qué documento procede y qué fuente debe citarse.

## 2.5 `prompting.py`: convertir retrieval en contexto

El RAG no consiste sólo en recuperar fragmentos. Hay que insertarlos en el prompt de forma clara para que el modelo entienda qué puede usar y qué no.

```python
RAG_SYSTEM_PROMPT = """Eres un asistente interno de FrasoHome.

Responde únicamente con la información proporcionada en el contexto recuperado.
Si el contexto no es suficiente para responder, debes decir exactamente:
"No tengo evidencia suficiente en los documentos proporcionados."

No inventes políticas, plazos ni características no presentes en el contexto.
Responde en español, de forma breve y clara.
Al final añade una línea con las fuentes en el formato:
Fuentes: archivo1, archivo2
"""
```

Este prompt convierte una generación libre en una generación gobernada. No garantiza perfección, pero establece una regla fundamental: el modelo debe responder sólo con el contexto recuperado.

## 2.6 `pipeline.py`: orquestación completa

`pipeline.py` es el corazón del sistema. Orquesta la ingesta y la consulta.

En ingesta:

```python
documents = load_documents(docs_dir)
chunks = chunk_documents(
    documents,
    chunk_size=self.settings.chunk_size,
    overlap=self.settings.chunk_overlap,
)

texts = [chunk["text"] for chunk in chunks]
vectors: list[list[float]] = []

for batch in batched(texts, size=16):
    vectors.extend(self.ollama.embed(batch, model=self.settings.embedding_model))
```

En consulta:

```python
def retrieve(self, question: str, top_k: int | None = None) -> list[dict]:
    top_k = top_k or self.settings.top_k
    query_vector = self.ollama.embed(question, model=self.settings.embedding_model)[0]
    return self.store.query(
        collection_name=self.settings.collection_name,
        query_vector=query_vector,
        limit=top_k,
    )
```

Y en generación final:

```python
context = build_context(hits)
user_prompt = build_user_prompt(question=question, context=context)
answer = self.ollama.chat(
    model=self.settings.chat_model,
    system_prompt=RAG_SYSTEM_PROMPT,
    user_prompt=user_prompt,
)
```

Esta clase permite explicar el patrón completo del taller: **leer → partir → embeber → indexar → recuperar → construir prompt → generar**.

## 2.7 `api.py`: convertir el pipeline en servicio

La API FastAPI expone tres rutas principales:

```python
@app.post("/ingest")
def ingest(request: IngestRequest) -> dict:
    docs_dir = Path(request.docs_dir)
    return pipeline.ingest_directory(docs_dir=docs_dir, force_recreate=request.force_recreate)

@app.post("/ask")
def ask(request: AskRequest) -> dict:
    return pipeline.ask(question=request.question, top_k=request.top_k)

@app.post("/retrieve")
def retrieve(request: AskRequest) -> dict:
    hits = pipeline.retrieve(question=request.question, top_k=request.top_k)
    return {"question": request.question, "hits": hits}
```

Esto permite enseñar una diferencia importante: el RAG puede ejecutarse como script de consola, pero una solución real suele exponerse como API para integrarse con una interfaz, un sistema interno o una automatización.

---

# 3. ¿Por qué un RAG?

La pregunta “¿por qué un RAG?” debe formularse después de haber entendido qué puede y qué no puede hacer un modelo local. Un modelo como `llama3` puede generar respuestas fluidas, pero no tiene por qué conocer las políticas concretas de FrasoHome, ni el contenido exacto de un manual interno, ni cambios recientes en procedimientos.

RAG, Retrieval-Augmented Generation, aparece para resolver tres limitaciones:

1. **Conocimiento privado:** el modelo no ha sido entrenado con los documentos internos de la organización.
2. **Conocimiento cambiante:** las políticas y manuales pueden cambiar más rápido que los modelos.
3. **Necesidad de evidencia:** en empresa no basta con una respuesta plausible; necesitamos saber de dónde sale.

El patrón RAG separa dos tareas. Primero, una tarea de recuperación: encontrar fragmentos relevantes. Después, una tarea generativa: redactar una respuesta usando esos fragmentos. Esa separación permite depurar el sistema. Si la respuesta es mala, podemos preguntar: ¿falló la recuperación o falló el modelo al usar el contexto?

En el repositorio, esto se ve muy bien con el modo `--only-retrieve`:

```bash
docker compose run --rm app python -m rag.ask \
  --question "¿Qué herramientas necesito para montar la mesa Oslo?" \
  --only-retrieve
```

Antes de pedir al modelo que responda, los alumnos pueden ver los fragmentos recuperados, el score y la fuente. Esto es muy importante porque les enseña que RAG no es magia: es búsqueda semántica más generación controlada.

LangChain describe retrieval como el mecanismo para traer conocimiento externo en tiempo de consulta y lo presenta como base de RAG, especialmente porque los LLM tienen contexto finito y conocimiento estático. Ver: https://docs.langchain.com/oss/python/langchain/retrieval.

---

# 4. Conversión de documentos a Markdown

El repositorio usa directamente dos documentos Markdown para simplificar el laboratorio:

```text
docs/politica_devoluciones.md
docs/manual_mesa_oslo.md
```

Esta decisión es intencional. El curso no quiere consumir media sesión resolviendo OCR, PDFs escaneados o tablas complejas. Sin embargo, en proyectos reales los documentos rara vez llegan tan limpios. Lo habitual es encontrar PDFs, DOCX, PPTX, HTML, hojas Excel, correos o documentos escaneados. Por eso hay que dedicar un bloque teórico a la conversión documental.

El objetivo de esta fase no es “convertir por convertir”. El objetivo es transformar documentos heterogéneos en una representación textual y estructurada que pueda pasar por chunking, embeddings y retrieval. Markdown es un buen formato intermedio porque conserva títulos, listas, tablas simples y cierta estructura semántica sin introducir demasiada complejidad.

## 4.1 MarkItDown

MarkItDown, de Microsoft, es una utilidad ligera de Python para convertir diversos archivos a Markdown pensando en pipelines de LLMs y análisis de texto. Es especialmente atractiva cuando se quieren transformar documentos de Office, PDFs, HTML u otros formatos a un texto más amigable para RAG.

**Cuándo usarlo:**

- Necesitas una conversión rápida a Markdown.
- Quieres preparar documentos para LLMs con poco código.
- Los documentos no tienen una estructura visual excesivamente complicada.

**Cuándo tener cuidado:**

- PDFs con tablas complejas.
- Documentos escaneados.
- Formularios con lectura visual difícil.
- Necesidad de trazabilidad por página o coordenadas.

Referencia oficial: https://github.com/microsoft/markitdown.

## 4.2 Docling

Docling está orientado a preparar documentos para GenAI, con procesamiento de formatos variados y comprensión avanzada de PDFs. Su documentación destaca capacidades como detección de tablas, fórmulas, orden de lectura y OCR. Además, ofrece un `DocumentConverter` como entrada principal para convertir diversos formatos.

**Cuándo usarlo:**

- PDFs complejos.
- Documentos con tablas, estructura visual o necesidad de mejor lectura de layout.
- Casos donde importa más la calidad de extracción que la simplicidad.

**Cuándo tener cuidado:**

- Puede ser más pesado que alternativas ligeras.
- Puede requerir más dependencias.
- El tiempo de procesamiento puede ser mayor.

Referencia oficial: https://docling-project.github.io/docling/ y https://docling-project.github.io/docling/reference/document_converter/.

## 4.3 PyMuPDF4LLM

PyMuPDF4LLM convierte PDFs a Markdown, JSON o TXT y se integra con entornos LLM/RAG. Es una opción muy interesante cuando el origen principal son PDFs y se busca una extracción razonablemente limpia sin montar un pipeline documental pesado.

**Cuándo usarlo:**

- PDFs relativamente bien formados.
- Necesitas salida Markdown rápida.
- Quieres integración con LangChain o LlamaIndex.

Referencia oficial: https://pymupdf.readthedocs.io/en/latest/pymupdf4llm/.

## 4.4 Unstructured

Unstructured es una librería orientada a particionar documentos no estructurados en elementos. Puede detectar el tipo de archivo y usar la función adecuada de particionado. Soporta múltiples formatos como PDF, DOCX, PPTX, HTML, imágenes y otros.

**Cuándo usarlo:**

- Hay muchos tipos documentales.
- Quieres trabajar con elementos como títulos, texto narrativo, tablas o listas.
- Necesitas un pipeline de ingesta más flexible.

Referencia oficial: https://docs.unstructured.io/open-source/core-functionality/partitioning.

## 4.5 Idea docente clave

El alumno debe entender que convertir documentos no es un paso administrativo. Es una fase crítica de calidad. Un mal parsing puede hacer que el RAG falle antes de generar embeddings. Si un título desaparece, una tabla se desordena o una cláusula queda separada de su excepción, el retrieval recuperará contexto incompleto o engañoso.

Por eso en el taller partimos de Markdown limpio, pero explicamos que en producción habría una fase previa:

```text
PDF / DOCX / HTML / PPTX
  ↓
Conversión a Markdown o estructura intermedia
  ↓
Limpieza
  ↓
Chunking
  ↓
Embeddings
```

---

# 5. Chunking: cómo partir documentos sin destruir conocimiento

El chunking es una de las partes más importantes de un RAG. Un chunk es la unidad que se va a recuperar. Si el chunk es malo, el vector será malo, la recuperación será mala y la respuesta final será mala.

La regla narrativa para clase es:

> No partimos texto para que quepa en una base de datos. Partimos texto para que cada fragmento tenga sentido cuando sea recuperado.

## 5.1 Chunking fijo por caracteres

Es la estrategia más sencilla. Se define un tamaño máximo y un solape. El repositorio usa este enfoque, aunque intenta buscar puntos de corte razonables.

```python
def chunk_text(text: str, chunk_size: int, overlap: int) -> list[str]:
    ...
    ideal_end = min(start + chunk_size, text_len)
    end = _best_split_position(text, start, ideal_end)
    ...
    start = max(0, end - overlap)
```

**Ventajas:**

- Fácil de entender.
- Fácil de implementar.
- Perfecto para un primer laboratorio.
- Permite experimentar con `CHUNK_SIZE` y `CHUNK_OVERLAP`.

**Desventajas:**

- Puede cortar secciones en lugares poco naturales.
- No entiende estructura documental.
- Puede separar una regla de su excepción.

## 5.2 Chunking por estructura Markdown

En documentación técnica o políticas internas, los títulos son muy importantes. Una alternativa es partir por encabezados Markdown (`#`, `##`, `###`) y mantener metadatos de sección.

Ejemplo conceptual:

```text
## Devoluciones por desistimiento
Texto...

## Productos personalizados
Texto...

## Producto dañado en transporte
Texto...
```

Cada sección puede convertirse en un chunk o en un conjunto de chunks. Esta estrategia conserva mejor el significado porque respeta la organización del documento.

**Ventajas:**

- Mejor trazabilidad.
- Mejor cita de secciones.
- Menos riesgo de mezclar temas.

**Desventajas:**

- Si una sección es muy larga, hay que volver a partirla.
- Si el Markdown está mal estructurado, la calidad baja.

## 5.3 Chunking por frases o párrafos

Otra opción es partir por frases o párrafos. Es útil cuando se quiere preservar unidades lingüísticas naturales.

**Ventajas:**

- Evita cortar frases.
- Suele producir fragmentos legibles.

**Desventajas:**

- Puede generar chunks demasiado pequeños o demasiado grandes.
- Requiere más control si los documentos tienen listas, tablas o apartados.

## 5.4 Chunking semántico

El chunking semántico intenta partir el documento cuando cambia el tema. Puede apoyarse en embeddings o heurísticas más avanzadas.

**Ventajas:**

- Puede producir chunks más coherentes.
- Útil en documentos largos y heterogéneos.

**Desventajas:**

- Más complejo.
- Más lento.
- Más difícil de explicar y depurar en un primer laboratorio.

## 5.5 Chunking jerárquico o parent-child

En RAGs más avanzados se puede recuperar un fragmento pequeño, pero enviar al LLM un contexto mayor asociado a ese fragmento. Por ejemplo, indexar párrafos pero devolver la sección completa. Este patrón ayuda a equilibrar precisión de búsqueda y riqueza de contexto.

**Ventajas:**

- Precisión en retrieval.
- Más contexto en generación.

**Desventajas:**

- Requiere almacenar relaciones entre chunks pequeños y documentos padre.
- Aumenta complejidad del pipeline.

## 5.6 Cómo se procesa en LangChain

Aunque el repositorio implementa chunking propio, es importante introducir cómo lo haríamos con LangChain. LangChain ofrece text splitters, document loaders, retrievers, vector stores e integraciones con modelos. Su ecosistema permite conectar muchas piezas con interfaces estándar.

Una forma típica de partir texto con LangChain sería:

```python
from langchain_text_splitters import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    chunk_size=650,
    chunk_overlap=100,
    separators=["\n\n", "\n", ". ", " ", ""],
)

chunks = splitter.create_documents(
    texts=[markdown_text],
    metadatas=[{"source": "politica_devoluciones.md", "doc_type": "policy"}],
)
```

El `RecursiveCharacterTextSplitter` intenta partir por una lista de separadores de forma recursiva. Para muchos casos de uso, la propia documentación de LangChain recomienda empezar con este splitter porque ofrece un equilibrio razonable entre mantener contexto y controlar tamaño.

Referencia oficial: https://docs.langchain.com/oss/python/integrations/splitters y https://docs.langchain.com/oss/python/integrations/splitters/recursive_text_splitter.

## 5.7 Intro rápida a LangChain

LangChain es un framework open source para construir aplicaciones con LLMs. En RAG, sus piezas más relevantes son:

- **Document Loaders:** leen datos desde archivos, APIs o fuentes externas y los convierten a objetos `Document`.
- **Text Splitters:** dividen documentos en chunks.
- **Embedding Models:** convierten texto en vectores.
- **Vector Stores:** guardan y consultan embeddings.
- **Retrievers:** devuelven documentos relevantes para una consulta.
- **Chains / Runnables:** componen pasos.
- **LangGraph:** permite modelar workflows y agentes con mayor control.

El repositorio no usa LangChain para que el alumno vea el mecanismo interno, pero todo lo que hace se puede mapear a LangChain:

```text
load_documents()       ≈ Document Loader
chunk_documents()      ≈ Text Splitter
OllamaClient.embed()   ≈ Embedding Model
VectorStore            ≈ Vector Store
pipeline.retrieve()    ≈ Retriever
pipeline.ask()         ≈ RAG Chain
```

Referencia oficial: LangChain documenta retrieval, document loaders, retrievers e integraciones. Ver: https://docs.langchain.com/oss/python/langchain/retrieval, https://docs.langchain.com/oss/python/integrations/document_loaders y https://docs.langchain.com/oss/python/integrations/retrievers.

---

# 6. Embeddings: convertir texto en vectores

Una vez tenemos chunks, necesitamos convertir cada fragmento en una representación numérica. Esa representación es un embedding. Dos textos con significado parecido deberían generar vectores cercanos en el espacio vectorial.

En el repositorio, la generación de embeddings ocurre aquí:

```python
texts = [chunk["text"] for chunk in chunks]
vectors: list[list[float]] = []

for batch in batched(texts, size=16):
    vectors.extend(self.ollama.embed(batch, model=self.settings.embedding_model))
```

Este código enseña tres ideas importantes:

1. No se embebe el documento completo, sino cada chunk.
2. Se puede hacer en lotes para ser más eficiente.
3. El modelo de embeddings es distinto del modelo de chat.

La consulta del usuario también se convierte en embedding:

```python
query_vector = self.ollama.embed(question, model=self.settings.embedding_model)[0]
```

Después Qdrant compara el vector de la pregunta con los vectores de los chunks y devuelve los más cercanos.

## 6.1 Embeddings locales vs embeddings cloud

En un entorno corporativo con restricciones de privacidad, los embeddings también deben generarse localmente. No basta con que el LLM sea local si los documentos se envían a un proveedor externo para generar vectores. Por eso el laboratorio usa Ollama también para embeddings.

En producción se podrían usar embeddings cloud si la política de datos lo permite, pero entonces el diseño ya no sería air-gapped.

## 6.2 Criterios para elegir un modelo de embeddings

Al elegir embeddings hay que mirar:

- idioma del corpus;
- tamaño del vector;
- calidad semántica;
- coste de inferencia;
- velocidad;
- compatibilidad local;
- licencia;
- comportamiento en dominios técnicos.

En el laboratorio, `embeddinggemma` se usa porque Ollama lo recomienda entre sus modelos de embeddings para semantic search y RAG. También podrían probarse `all-minilm` o `qwen3-embedding` para comparar resultados.

Referencia oficial: Ollama documenta embeddings para búsqueda semántica, vector DB y RAG, y lista modelos recomendados. Ver: https://docs.ollama.com/capabilities/embeddings.

---

# 7. Bases de datos vectoriales

Una base de datos vectorial almacena embeddings y permite consultar por similitud. En RAG, cumple el papel de memoria indexada: no “entiende” como un LLM, pero puede encontrar fragmentos cercanos a una pregunta.

El flujo básico es:

```text
chunk → embedding → vector DB
pregunta → embedding → búsqueda top-k → chunks relevantes
```

## 7.1 Qdrant

Qdrant es la base vectorial elegida en el repositorio porque es open source, funciona bien con Docker, tiene una API cómoda, permite payloads y se inspecciona fácilmente con dashboard local. Qdrant se describe como un motor de búsqueda vectorial y semántica escrito en Rust.

En el repo, la colección se crea así:

```python
self.client.create_collection(
    collection_name=collection_name,
    vectors_config=VectorParams(size=vector_size, distance=Distance.COSINE),
)
```

La distancia usada es coseno. Esto es habitual en búsqueda semántica porque interesa comparar orientación de vectores más que magnitud.

La inserción usa puntos con `id`, `vector` y `payload`:

```python
self.client.upsert(collection_name=collection_name, wait=True, points=points)
```

La consulta usa `query_points`:

```python
result = self.client.query_points(
    collection_name=collection_name,
    query=query_vector,
    with_payload=True,
    limit=limit,
).points
```

Qdrant devuelve puntos ordenados por similitud, con `score` y payload. El payload es lo que permite construir después el contexto:

```python
{
    "score": float(point.score),
    "source": payload.get("source", ""),
    "doc_type": payload.get("doc_type", ""),
    "chunk_id": payload.get("chunk_id", 0),
    "text": payload.get("text", ""),
}
```

### Qué debe aprender el alumno sobre Qdrant

Primero, una colección tiene una dimensión vectorial fija. Si cambias de modelo de embeddings y cambia la dimensión, normalmente tendrás que recrear la colección.

Segundo, Qdrant no sólo almacena vectores. Almacena payloads. En una solución real, payloads como `source`, `section`, `effective_date`, `department`, `confidentiality_level` o `language` son fundamentales.

Tercero, los filtros importan. Aunque el laboratorio no implementa filtros, Qdrant permite filtrar por payload. Esto es crítico cuando hay corpus por área, permisos o fechas de vigencia.

Cuarto, el dashboard no es un adorno: sirve para que el alumno vea que realmente hay puntos indexados, payloads y colecciones.

Referencias oficiales: Qdrant documenta su quickstart, payloads e interfaz web. Ver: https://qdrant.tech/documentation/quickstart/, https://qdrant.tech/documentation/manage-data/payload/ y https://qdrant.tech/documentation/web-ui/.

## 7.2 ChromaDB

Chroma es una opción popular para prototipos locales y desarrollo. Ofrece almacenamiento de documentos, metadatos, embeddings y búsqueda densa, sparse e híbrida. Puede funcionar en memoria, con cliente persistente o en modo cliente-servidor.

**Pros:**

- Muy fácil para notebooks y prototipos.
- Buena experiencia de desarrollo.
- Open source.
- Integra bien con frameworks de RAG.

**Contras:**

- Para producción conviene revisar bien el modo de despliegue.
- En entornos corporativos con requisitos de seguridad y operación puede requerir una arquitectura más cuidada.

Referencia oficial: https://docs.trychroma.com/docs/overview/introduction y https://docs.trychroma.com/docs/overview/getting-started.

## 7.3 Pinecone

Pinecone es una base vectorial gestionada, pensada para producción y escalado. Es útil cuando se quieren evitar operaciones de infraestructura y se acepta usar cloud.

**Pros:**

- Servicio gestionado.
- Orientado a producción y escalado.
- Menos operación propia.

**Contras:**

- No sirve para el objetivo air-gapped del taller.
- Los datos y embeddings se gestionan en un servicio externo.
- Puede tener implicaciones de privacidad, coste y gobierno.

Referencia oficial: Pinecone se presenta como base vectorial gestionada para aplicaciones AI a escala. Ver: https://docs.pinecone.io/guides/get-started/overview.

## 7.4 Azure AI Search

Azure AI Search es un servicio enterprise de búsqueda que soporta texto, vector, multimodalidad y búsqueda híbrida. Es una opción muy relevante en organizaciones que ya trabajan sobre Azure y necesitan seguridad, integración y gobierno corporativo.

**Pros:**

- Búsqueda vectorial, textual e híbrida.
- Integración con ecosistema Azure.
- Capacidades enterprise de seguridad y operación.
- Muy útil para RAG en arquitecturas cloud corporativas.

**Contras:**

- No es local ni air-gapped.
- Requiere diseño de índices y permisos en Azure.
- Tiene coste de servicio.

Referencia oficial: Azure AI Search documenta vector search e hybrid search con fusión de resultados. Ver: https://learn.microsoft.com/en-us/azure/search/vector-search-overview y https://learn.microsoft.com/en-us/azure/search/hybrid-search-overview.

## 7.5 Por qué Qdrant en este taller

Qdrant es la elección adecuada para el laboratorio porque combina cuatro cosas: Docker sencillo, API clara, almacenamiento local y dashboard. Pinecone y Azure AI Search son muy buenos en producción cloud, pero no respetan la restricción de aislamiento. Chroma también sería una opción válida, especialmente en notebooks, pero Qdrant obliga a pensar desde el principio en un servicio separado, más parecido a una arquitectura real.

---

# 8. Prompting RAG: cómo obligar al modelo a usar contexto

Una vez recuperados los chunks, el sistema debe construir un prompt. Este paso es delicado porque el modelo tiende a completar y razonar con conocimiento general. En RAG corporativo, queremos lo contrario: que use sólo el contexto recuperado y que se abstenga si no hay evidencia.

El repositorio lo resuelve con dos funciones:

```python
def build_context(hits: list[dict]) -> str:
    blocks: list[str] = []
    for idx, hit in enumerate(hits, start=1):
        blocks.append(
            f"[Fragmento {idx}]\n"
            f"Fuente: {hit['source']}\n"
            f"Tipo: {hit['doc_type']}\n"
            f"Chunk: {hit['chunk_id']}\n"
            f"Score: {hit['score']:.4f}\n"
            f"Contenido:\n{hit['text']}"
        )
    return "\n\n".join(blocks)
```

Y:

```python
def build_user_prompt(question: str, context: str) -> str:
    return (
        f"Pregunta del usuario:\n{question}\n\n"
        f"Contexto recuperado:\n{context}\n\n"
        "Redacta una respuesta apoyada solo en el contexto anterior."
    )
```

Este diseño permite enseñar que el prompt tiene dos capas: un mensaje de sistema con reglas y un mensaje de usuario con pregunta y contexto. La combinación es la que convierte los chunks recuperados en una respuesta útil.

Una buena práctica docente es pedir a los alumnos que prueben la misma pregunta en tres modos:

1. Modelo sin contexto.
2. Retrieval-only.
3. RAG completo.

Así ven cómo cambia el comportamiento y por qué el contexto importa.

---

# 9. Evaluación de soluciones de IA Generativa

Evaluar una solución de IA generativa no es sólo preguntar “¿me gusta la respuesta?”. Hay que separar dimensiones.

En una app generativa general, podríamos evaluar:

- corrección factual;
- relevancia de la respuesta;
- completitud;
- tono;
- seguridad;
- cumplimiento de formato;
- latencia;
- coste;
- estabilidad entre ejecuciones;
- tasa de abstención correcta;
- errores por tipo de consulta.

En un RAG, además, hay que separar **retrieval** y **generation**.

## 9.1 Evaluación de retrieval

La evaluación de retrieval pregunta: ¿hemos recuperado el contexto correcto?

Métricas útiles:

- **Hit@K:** el documento esperado aparece en los K primeros resultados.
- **Recall@K:** proporción de contextos relevantes recuperados.
- **Precision@K:** proporción de contextos recuperados que son útiles.
- **MRR:** qué tan arriba aparece el primer resultado relevante.
- **Score distribution:** análisis de scores para detectar umbrales de confianza.

En el repositorio, la evaluación es simple pero didáctica. El CSV define la pregunta, la fuente esperada y si el sistema debe abstenerse:

```csv
id,question,expected_source,should_abstain,notes
Q1,"¿Puedo devolver una mesa ya montada si simplemente no me convence?",politica_devoluciones.md,false,"Debe responder que no por desistimiento simple."
Q6,"¿Cuál es el plazo de entrega de la mesa Oslo?",,true,"No está en los documentos."
```

El script comprueba si aparece la fuente esperada:

```python
expected_source = (row.get("expected_source") or "").strip()
source_ok = expected_source in sources if expected_source else True
```

Esto no es una evaluación completa, pero enseña el hábito correcto: medir si el sistema recupera la fuente adecuada.

## 9.2 Evaluación de generación

La evaluación de generación pregunta: dado el contexto, ¿la respuesta es correcta, fiel y útil?

Métricas típicas:

- **Faithfulness / groundedness:** las afirmaciones de la respuesta están soportadas por el contexto.
- **Answer relevance:** la respuesta contesta a la pregunta.
- **Correctness:** coincide con una respuesta esperada.
- **Completeness:** cubre todos los puntos necesarios.
- **Abstention accuracy:** se abstiene cuando no hay evidencia y responde cuando sí la hay.

En el repositorio, la abstención se evalúa así:

```python
ABSTENTION_TEXT = "No tengo evidencia suficiente en los documentos proporcionados."

abstained = ABSTENTION_TEXT in answer
abstention_ok = abstained == should_abstain
```

Este patrón es muy útil porque enseña que abstenerse correctamente es una métrica de calidad, no un fallo.

## 9.3 Evaluación manual vs evaluación automática

Para un primer taller, la evaluación manual es mejor. Los alumnos entienden los errores y pueden inspeccionar retrieval y respuesta. Sin embargo, en proyectos reales se suele evolucionar hacia evaluación semiautomática o automática.

La progresión recomendada es:

```text
Evaluación manual con 8-20 preguntas
  ↓
Evaluación scriptada con fuentes esperadas
  ↓
Métricas de retrieval
  ↓
LLM-as-a-judge local o controlado
  ↓
Evaluación continua/regresión
```

## 9.4 Frameworks de evaluación

### Ragas

Ragas ofrece métricas para evaluar componentes de un pipeline RAG, como faithfulness, answer relevancy, context recall y context precision. Es muy útil cuando se quiere pasar de una evaluación artesanal a una más sistemática.

**Útil para:** medir RAGs con métricas conocidas, comparar configuraciones y construir datasets de evaluación.

**Cuidado:** muchas métricas usan un LLM como juez; si el entorno es air-gapped, ese juez debe ser local o se rompe la restricción de privacidad.

Referencias: https://docs.ragas.io/en/stable/concepts/metrics/available_metrics/ y https://docs.ragas.io/en/stable/concepts/metrics/available_metrics/faithfulness/.

### DeepEval

DeepEval es un framework de evaluación para aplicaciones LLM que incluye métricas RAG como answer relevancy, faithfulness, contextual recall, contextual precision y contextual relevancy.

**Útil para:** tests automatizados, integración en CI/CD y validación de métricas específicas.

**Cuidado:** igual que con Ragas, conviene revisar qué juez LLM se usa y si encaja con el entorno de privacidad.

Referencias: https://deepeval.com/docs/metrics-answer-relevancy, https://deepeval.com/docs/metrics-contextual-relevancy y https://deepeval.com/docs/metrics-contextual-precision.

### TruLens

TruLens populariza el concepto de RAG Triad: context relevance, groundedness y answer relevance. Es una forma muy pedagógica de explicar la evaluación RAG.

- **Context relevance:** ¿el contexto recuperado es relevante para la pregunta?
- **Groundedness:** ¿la respuesta está soportada por el contexto?
- **Answer relevance:** ¿la respuesta contesta a la pregunta?

Referencia: https://www.trulens.org/getting_started/core_concepts/rag_triad/.

### LangSmith

LangSmith permite crear datasets, ejecutar aplicaciones sobre esos datasets y medir rendimiento con diferentes evaluadores. Es muy potente para trazas, depuración y comparación de experimentos, especialmente en equipos que ya usan LangChain/LangGraph.

**Cuidado:** para un entorno completamente aislado hay que revisar si su uso es compatible con las restricciones de la organización, ya que muchas configuraciones se apoyan en plataforma gestionada.

Referencias: https://docs.langchain.com/langsmith/evaluate-rag-tutorial y https://docs.langchain.com/langsmith/evaluation.

## 9.5 Evaluación en el taller

En este curso no hace falta instalar Ragas o DeepEval. El repositorio ya incluye una evaluación mínima que enseña lo esencial:

```bash
docker compose run --rm app python -m rag.evaluate \
  --csv /workspace/evaluation/questions.csv
```

El resultado resume qué casos pasan y cuáles fallan:

```python
output = {
    "summary": {
        "passed": passed,
        "total": total,
        "pass_rate": round(passed / total, 3) if total else 0.0,
    },
    "results": results,
}
```

La narrativa para los alumnos debe ser:

> Primero medimos simple. Después sofisticamos. No al revés.

---

# 10. Temario de la Sesión 1 — De modelo local a retrieval

## Objetivo de la sesión 1

Al finalizar la primera sesión, cada pareja debe tener el stack levantado, los modelos disponibles, los documentos leídos, los chunks generados, la colección de Qdrant creada y la recuperación semántica funcionando.

La sesión 1 no termina con un chatbot bonito. Termina con algo más importante: la prueba de que el sistema puede encontrar fragmentos relevantes en documentos locales.

---

## 10.1 Bloque 1 — Opciones de modelos locales y decisión del stack

**Tiempo:** 00:00–00:45

La sesión comienza con el mapa de opciones: Ollama, llama.cpp, LM Studio, AnythingLLM, Open WebUI y runtimes de producción. El objetivo no es dominar todas, sino entender por qué se ha elegido Ollama para este laboratorio.

La conversación debe conducir a esta conclusión: para un grupo que necesita montar un RAG local, aislado y reproducible, Ollama en Docker ofrece la mejor relación entre simplicidad y control. AnythingLLM u Open WebUI serían excelentes para demostrar valor rápido; llama.cpp sería excelente para aprender inferencia y cuantización; LM Studio sería cómodo para exploración; pero el repositorio usa Ollama porque permite enseñar API, embeddings y generación dentro de un mismo stack.

**Actividad:** cada alumno debe responder verbalmente:

- ¿Qué herramienta elegirías para una demo rápida?
- ¿Cuál elegirías para aprender inferencia de bajo nivel?
- ¿Cuál usarás hoy y por qué?

---

## 10.2 Bloque 2 — Arquitectura del repositorio y Docker Compose

**Tiempo:** 00:45–01:30

Aquí se abre el repositorio y se recorre la estructura. Es fundamental explicar que no hay “magia”: sólo tres servicios y una app Python.

Se revisa `docker-compose.yml` y se explica:

- por qué Ollama y Qdrant son servicios separados;
- por qué los puertos se publican en `127.0.0.1`;
- por qué los volúmenes son persistentes;
- por qué `OLLAMA_NO_CLOUD=1` es relevante;
- cómo la app habla con Ollama por `http://ollama:11434/api` dentro de la red Docker;
- cómo el host accede a los servicios por `localhost`.

**Comandos de práctica:**

```bash
cp .env.example .env
docker compose build app
docker compose up -d
docker compose ps
```

**Checkpoint:** los tres contenedores deben estar levantados.

---

## 10.3 Bloque 3 — Ollama: generación y embeddings son llamadas distintas

**Tiempo:** 01:30–02:15

En este bloque el alumno prueba Ollama directamente. Primero generación:

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3",
  "prompt": "Explica en una frase qué es una devolución.",
  "stream": false
}'
```

Después embeddings:

```bash
curl http://localhost:11434/api/embed -d '{
  "model": "embeddinggemma",
  "input": "Un cliente quiere devolver una mesa ya montada."
}'
```

La explicación clave es que la primera llamada devuelve lenguaje y la segunda devuelve números. No son intercambiables. El RAG necesita ambas.

**Actividad:** mirar la respuesta JSON de `/api/embed` y localizar la lista de vectores.

**Checkpoint:** cada pareja sabe explicar por qué usamos `llama3` para responder y `embeddinggemma` para embeddings.

---

## 10.4 Pausa

**Tiempo:** 02:15–02:30

---

## 10.5 Bloque 4 — Por qué RAG y qué papel juegan los documentos

**Tiempo:** 02:30–03:00

Se leen los dos documentos:

```text
docs/politica_devoluciones.md
docs/manual_mesa_oslo.md
```

La pregunta docente es:

> ¿Qué preguntas puede contestar el sistema con estos documentos y qué preguntas no?

Ejemplos de preguntas contestables:

- ¿Puedo devolver una mesa ya montada?
- ¿Qué hago si faltan tornillos?
- ¿Cuánto tiempo tengo para comunicar daño en transporte?

Ejemplos de preguntas no contestables:

- ¿Cuál es el plazo de entrega?
- ¿Hay stock en Sevilla?
- ¿Cuánto cuesta el producto?

Este bloque prepara la evaluación posterior. Los alumnos deben entender que un buen sistema RAG también debe saber abstenerse.

---

## 10.6 Bloque 5 — Chunking con el código del repositorio

**Tiempo:** 03:00–03:45

Se abre `app/rag/chunking.py` y se explica paso a paso. La función `clean_text` normaliza el texto, `load_documents` carga `.md` y `.txt`, `guess_doc_type` etiqueta el documento y `chunk_documents` produce registros con metadatos.

El alumno debe fijarse en esta estructura final:

```python
{
    "id": stable_id,
    "source": document["source"],
    "doc_type": document["doc_type"],
    "chunk_id": idx,
    "text": chunk,
}
```

Esa estructura será la que termine como payload en Qdrant. Por eso es tan importante que el chunk lleve metadatos.

**Actividad:** cambiar `CHUNK_SIZE` y `CHUNK_OVERLAP` en `.env`, reindexar y comparar número de chunks.

---

## 10.7 Bloque 6 — Ingesta en Qdrant

**Tiempo:** 03:45–04:30

Se ejecuta la ingesta:

```bash
docker compose run --rm app python -m rag.ingest \
  --docs-dir /workspace/docs \
  --force-recreate
```

El instructor explica qué ocurre dentro:

```text
load_documents()
  ↓
chunk_documents()
  ↓
ollama.embed()
  ↓
ensure_collection()
  ↓
upsert()
```

Después se abre el dashboard:

```text
http://localhost:6333/dashboard
```

El alumno debe comprobar:

- existe la colección `frasohome_docs`;
- hay puntos cargados;
- cada punto tiene payload;
- el payload contiene `source`, `doc_type`, `chunk_id`, `text`.

---

## 10.8 Bloque 7 — Retrieval-only

**Tiempo:** 04:30–05:00

Se prueba recuperación sin generación:

```bash
docker compose run --rm app python -m rag.ask \
  --question "¿Qué herramientas necesito para montar la mesa Oslo?" \
  --only-retrieve
```

Y:

```bash
docker compose run --rm app python -m rag.ask \
  --question "¿Puedo devolver una mesa ya montada?" \
  --only-retrieve
```

La clase termina con una discusión: ¿los chunks recuperados tienen sentido? ¿El score más alto corresponde al documento esperado? ¿Qué ocurriría si `top_k=1`? ¿Y si `top_k=5`?

**Entregable de sesión 1:** retrieval semántico local funcionando.

---

# 11. Temario de la Sesión 2 — De retrieval a RAG evaluado

## Objetivo de la sesión 2

Al finalizar la segunda sesión, cada pareja debe tener un RAG completo funcionando, una API local operativa, una evaluación mínima ejecutada y una mejora documentada.

---

## 11.1 Bloque 1 — Recapitulación: del chunk al prompt

**Tiempo:** 00:00–00:30

Se arranca recordando el flujo:

```text
pregunta
  ↓
embedding de pregunta
  ↓
query Qdrant
  ↓
top-k chunks
  ↓
contexto
  ↓
prompt
  ↓
llama3
  ↓
respuesta con fuentes
```

El instructor debe insistir en que el modelo no busca en los documentos por sí mismo. La aplicación recupera contexto y se lo entrega.

---

## 11.2 Bloque 2 — Construcción del prompt RAG

**Tiempo:** 00:30–01:15

Se abre `prompting.py` y se analiza `RAG_SYSTEM_PROMPT`. La pregunta es: ¿qué reglas gobiernan la respuesta?

Reglas importantes:

- responder sólo con contexto;
- abstenerse si no hay evidencia;
- no inventar políticas;
- responder en español;
- citar fuentes.

Se ejecutan consultas RAG completas:

```bash
docker compose run --rm app python -m rag.ask \
  --question "¿Puedo devolver una mesa ya montada si solo he cambiado de opinión?"
```

Y:

```bash
docker compose run --rm app python -m rag.ask \
  --question "¿Qué hago si faltan tornillos en la caja?"
```

**Actividad:** comparar los `hits` con la respuesta final.

---

## 11.3 Bloque 3 — Abstención y preguntas sin evidencia

**Tiempo:** 01:15–01:45

Se lanzan preguntas que el sistema no debería contestar:

```bash
docker compose run --rm app python -m rag.ask \
  --question "¿Cuál es el plazo de entrega de la mesa Oslo?"
```

El sistema debe decir:

```text
No tengo evidencia suficiente en los documentos proporcionados.
```

La idea docente es muy importante: la abstención correcta es una señal de calidad. En sistemas corporativos, inventar una política puede ser peor que no responder.

---

## 11.4 Bloque 4 — API local con FastAPI

**Tiempo:** 01:45–02:15

Se muestra que el RAG ya no es sólo un script. La app expone rutas HTTP:

```bash
curl http://localhost:8000/health
```

Consulta:

```bash
curl -X POST http://localhost:8000/ask \
  -H "Content-Type: application/json" \
  -d '{
    "question": "¿Qué herramientas necesito para montar la mesa Oslo?",
    "top_k": 3
  }'
```

La narrativa aquí es que una solución real necesita una interfaz estable. Hoy usamos FastAPI; mañana podría conectarse a una UI, intranet, bot interno o sistema de tickets.

---

## 11.5 Pausa

**Tiempo:** 02:15–02:30

---

## 11.6 Bloque 5 — Evaluación básica del RAG

**Tiempo:** 02:30–03:15

Se revisa `evaluation/questions.csv`. El instructor explica que cada fila define una expectativa. No buscamos perfección, buscamos un primer benchmark.

Ejecución:

```bash
docker compose run --rm app python -m rag.evaluate \
  --csv /workspace/evaluation/questions.csv
```

Se abre `evaluate.py` y se explica cómo calcula `source_ok`, `abstention_ok` y `pass`.

```python
source_ok = expected_source in sources if expected_source else True
abstention_ok = abstained == should_abstain
```

**Actividad:** cada pareja identifica un caso que falla y decide si falló retrieval, generación o abstención.

---

## 11.7 Bloque 6 — Mejoras controladas

**Tiempo:** 03:15–04:00

Los alumnos cambian una sola variable:

- `CHUNK_SIZE`
- `CHUNK_OVERLAP`
- `TOP_K`

Después reindexan:

```bash
docker compose run --rm app python -m rag.ingest \
  --docs-dir /workspace/docs \
  --force-recreate
```

Y vuelven a evaluar:

```bash
docker compose run --rm app python -m rag.evaluate \
  --csv /workspace/evaluation/questions.csv
```

La regla del bloque es: no se cambian tres cosas a la vez. Si cambias tres cosas, no sabes cuál causó la mejora o el empeoramiento.

**Actividad:** documentar una mejora y una degradación.

---

## 11.8 Bloque 7 — Qué faltaría para producción

**Tiempo:** 04:00–04:40

Se discute qué falta para pasar de laboratorio a piloto interno:

- autenticación;
- autorización por corpus;
- control de versiones de documentos;
- reindexado incremental;
- filtros por metadatos;
- observabilidad;
- logs sin datos sensibles;
- evaluación continua;
- selección de modelos por caso de uso;
- backup de Qdrant;
- hardening de red;
- límites de tamaño de petición;
- estrategia de actualización de modelos.

Se recalca que el laboratorio es correcto como aprendizaje, no como producto final.

---

## 11.9 Bloque 8 — Demo final y reflexión

**Tiempo:** 04:40–05:00

Cada pareja demuestra:

1. stack activo;
2. ingesta realizada;
3. pregunta respondida con fuente;
4. pregunta con abstención correcta;
5. resultado de evaluación;
6. cambio realizado y efecto observado.

La sesión cierra con esta idea:

> Un RAG local no es un chatbot con documentos. Es una arquitectura donde cada dato tiene procedencia, cada respuesta debería estar soportada por evidencia y cada mejora debe poder medirse.

---

# 12. Resumen ejecutivo para el alumno

Al terminar el taller, el alumno debería poder explicar este flujo sin mirar apuntes:

```text
1. Levanto Ollama y Qdrant en Docker.
2. Uso llama3 para generación y embeddinggemma para embeddings.
3. Leo documentos locales.
4. Limpio y parto documentos en chunks.
5. Genero embeddings de cada chunk.
6. Guardo vectores y payloads en Qdrant.
7. Convierto la pregunta en embedding.
8. Recupero top-k fragmentos similares.
9. Construyo un prompt con contexto.
10. Pido a llama3 que responda sólo con ese contexto.
11. Cito fuentes.
12. Evalúo si recuperó la fuente correcta y si se abstuvo cuando debía.
```

Ese es el resultado formativo central. No se trata de memorizar comandos; se trata de entender qué pieza hace cada cosa.

---

# 13. Material recomendado para entregar junto al taller

Además del repositorio, es recomendable entregar:

- una hoja de arquitectura con el flujo completo;
- una chuleta de comandos Docker;
- una tabla de errores frecuentes;
- una rúbrica de evaluación;
- una comparativa de herramientas locales;
- una extensión opcional con LangChain;
- una extensión opcional con conversión de PDF a Markdown.

## Rúbrica rápida

| Criterio | Peso |
|---|---:|
| Stack local levantado correctamente | 20% |
| Ingesta y chunking entendidos | 20% |
| Qdrant con payloads inspeccionable | 15% |
| Retrieval correcto | 15% |
| RAG con fuentes y abstención | 20% |
| Evaluación y mejora controlada | 10% |

---

# 14. Fuentes oficiales consultadas

- Ollama API: https://docs.ollama.com/api/introduction
- Ollama embeddings: https://docs.ollama.com/api/embed
- Ollama Docker: https://docs.ollama.com/docker
- Ollama FAQ y privacidad local: https://docs.ollama.com/faq
- Ollama modelos de embeddings: https://docs.ollama.com/capabilities/embeddings
- llama.cpp: https://github.com/ggml-org/llama.cpp
- GGUF con llama.cpp: https://huggingface.co/docs/hub/gguf-llamacpp
- LM Studio local server: https://lmstudio.ai/docs/developer/core/server
- LM Studio OpenAI compatibility: https://lmstudio.ai/docs/developer/openai-compat
- AnythingLLM docs: https://docs.anythingllm.com/introduction
- Open WebUI docs: https://docs.openwebui.com/
- Open WebUI Knowledge/RAG: https://docs.openwebui.com/features/workspace/knowledge/
- MarkItDown: https://github.com/microsoft/markitdown
- Docling docs: https://docling-project.github.io/docling/
- Docling DocumentConverter: https://docling-project.github.io/docling/reference/document_converter/
- PyMuPDF4LLM: https://pymupdf.readthedocs.io/en/latest/pymupdf4llm/
- Unstructured partitioning: https://docs.unstructured.io/open-source/core-functionality/partitioning
- LangChain retrieval: https://docs.langchain.com/oss/python/langchain/retrieval
- LangChain splitters: https://docs.langchain.com/oss/python/integrations/splitters
- LangChain recursive splitter: https://docs.langchain.com/oss/python/integrations/splitters/recursive_text_splitter
- LangChain document loaders: https://docs.langchain.com/oss/python/integrations/document_loaders
- Qdrant quickstart: https://qdrant.tech/documentation/quickstart/
- Qdrant payload: https://qdrant.tech/documentation/manage-data/payload/
- Qdrant Web UI: https://qdrant.tech/documentation/web-ui/
- Chroma docs: https://docs.trychroma.com/docs/overview/introduction
- Pinecone docs: https://docs.pinecone.io/guides/get-started/overview
- Azure AI Search vector search: https://learn.microsoft.com/en-us/azure/search/vector-search-overview
- Azure AI Search hybrid search: https://learn.microsoft.com/en-us/azure/search/hybrid-search-overview
- Ragas metrics: https://docs.ragas.io/en/stable/concepts/metrics/available_metrics/
- DeepEval metrics: https://deepeval.com/docs/metrics-answer-relevancy
- TruLens RAG Triad: https://www.trulens.org/getting_started/core_concepts/rag_triad/
- LangSmith RAG evaluation: https://docs.langchain.com/langsmith/evaluate-rag-tutorial
