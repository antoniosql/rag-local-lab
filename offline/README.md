# Preparación offline del laboratorio

Esta carpeta es para el **instructor** o para quien tenga que preparar un aula sin Internet.

## Objetivo
Llegar al aula con:
- imágenes Docker ya cargadas o exportadas,
- volumen de Ollama ya sembrado con modelos,
- servicios listos para arrancar sin depender de Internet,
- dependencias Python locales ya preparadas para notebooks y CLI.

## Qué hay que preparar antes de desconectar el aula

### 1. Levantar la infraestructura
```bash
docker compose up -d
```

### 2. Cargar los modelos
```bash
./scripts/pull-models.sh
```

### 3. Exportar las imágenes
```bash
./offline/export_bundle.sh
```

### 4. Exportar el volumen de modelos de Ollama
```bash
./offline/export_ollama_models.sh
```

### 5. Llevar también un wheelhouse o entorno Python ya preparado

Como la solución Python corre en local, conviene llegar al aula con una de estas dos opciones:

- una carpeta con ruedas (`wheelhouse`) para instalar `requirements-local.txt` sin Internet,
- o un entorno `.venv` ya montado y validado en máquinas equivalentes.

## Qué distribuyes al aula

- `offline/docker-images.tar`
- `offline/ollama-models.tar.gz`

## Qué hace el alumno en el aula

```bash
docker load -i offline/docker-images.tar
./offline/import_ollama_models.sh
docker compose up -d --no-build
./scripts/verify-stack.sh
```

## Nota
Este flujo no elimina todos los riesgos operativos de un entorno aislado, pero evita depender de Internet para:
- descargar imágenes,
- descargar modelos,
- arrancar los servicios del workshop.
