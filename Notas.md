# Notas Instructor

Las instrucciones del `README.md` funcionan con el enfoque actual del taller.

Conviene recordar al grupo que los scripts de `scripts/` tienen versión `bash` y versión `PowerShell`.

## Comandos Docker
Debemos de tener docker desktop ejecutándose, para poder lanzarlo. 
Cuando lanzaoms el compose up, se genera el contenedor con las imágenes que tenemos definidas en el yaml
Los cambios en las imágenes se guardan por lo que la siguiente vez que se levante tendrán las modificaciones hechas, si solo se detienen con down. 

- `docker compose up -d` levanta `ollama`,  `qdrant` y `AnythingLLM`.
- `docker compose ps` muestra el estado del stack.
- `docker compose logs ollama` y `docker compose logs qdrant` por ejemplo ayudan a diagnosticar problemas.
- `docker exec -it taller-rag-local-qdrant /bin/bash` permite entrar en el contenedor si hace falta inspección manual.

## Ollama
Lista de Modelos: https://ollama.com/library 
Para descargar un modelo en Ollama, el nombre que necesitas sigue generalmente un formato de nombre-del-modelo:tag. Si no especificas un "tag" (la versión o tamaño), Ollama descargará por defecto la versión latest

ollama pull gemma4:e4b 
ollama pull deepseek-r1:1.5b
con ollama list veo la lista de modelos
con ollama rm puedo eliminarlos

## Qdrant

- `http://localhost:6333/dashboard` abre la interfaz web.
- Es útil enseñar la colección tras ejecutar el notebook de indexación.
- El alumnado debería comprobar `payload`, `chunk_id` y `source`.

## Guion sugerido

1. Empezar con `AnythingLLM` como demo de RAG local ya funcionando.
2. Probar `Ollama` por separado.
3. Probar `Qdrant` con vectores manuales.
4. Hacer chunking con `LangChain`.
5. Indexar en `Qdrant`.
6. Montar el RAG final y discutir qué falla cuando la respuesta es mala.
