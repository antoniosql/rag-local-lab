# Requisitos para el alumnado

Este laboratorio está pensado para ejecutarse en local con Docker y con los notebooks abiertos en Visual Studio Code.

## Software obligatorio

- `Visual Studio Code`
- `Docker Desktop` con Docker Compose v2
- `Python 3.11` o superior

## Recomendado en Visual Studio Code

Instalad tambien estas extensiones:

- `Python` (Microsoft)
- `Jupyter` (Microsoft)

Con eso podréis:

- abrir el repositorio y lanzar una terminal integrada;
- ejecutar scripts de Python dentro del entorno virtual del proyecto;
- abrir y ejecutar los notebooks de `notebooks/`;
- seleccionar el kernel `.venv` directamente desde VS Code.

## Requisitos adicionales recomendados

- Acceso a terminal:
  - Windows: `PowerShell`
  - macOS o Linux: shell estándar del sistema
- Conexión a Internet para la primera descarga de imágenes Docker y modelos de Ollama
- Al menos `8 GB` de RAM; mejor `16 GB` si el equipo del alumno lo permite
- Espacio libre en disco suficiente para contenedores, modelos y entorno Python

## Qué comprueba el preflight

Los scripts `scripts/preflight.ps1` y `scripts/preflight.sh` verifican:

- `Docker`
- `Docker Compose v2`
- `Visual Studio Code` mediante el comando `code`
- `Python`

En macOS y Linux tambien se comprueba `curl`, porque varios scripts bash lo utilizan.

## Preparación local recomendada

Levantar la infraestructura de contenedores, para tenerlos descagados y no perder tiempo en el aula. 

```text
docker compose up -d
```

Cuando finaliza comprobar que los contenedores están ok:

`docker compose ps` que muestra el estado del stack.
`docker compose down` que detienen los contenedores

## Nota importante para el aula

Si `Visual Studio Code` está instalado pero el comando `code` no funciona en terminal, el preflight fallará. En ese caso hay que habilitar la instalación del comando de shell de VS Code para que se pueda abrir el proyecto y trabajar con normalidad.
