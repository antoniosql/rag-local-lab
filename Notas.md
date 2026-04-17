# Notas Instructor

las instrucciones del README.md funcionan ok. solo mencionar que la ejecución de scripts depende de SO (bash o powershell) En la carpeta de scripts están ambas versiones. 

## Comandos docker

- docker compose build app --> construye la imagen (fichero dockerfile en directorio app) de la app
- docker-compose up --> construye y despliega lo especificado en docker-compose.yml
- docker-compose start: inicia los contenedores existentes en el archivo docker-compose.yml.
- docker-compose stop: detiene los contenedores existentes en el archivo docker-compose.yml.
- docker-compose restart: reinicia los contenedores existentes en el archivo docker-compose.yml.
- docker-compose ps: muestra el estado de los contenedores definidos en el archivo docker-compose.yml.
- docker-compose logs: muestra los logs de los contenedores definidos en el archivo docker-compose.yml.
- dockers ps me permite ver los que están levantados
- docker exec -it taller-rag-local-qdrant /bin/bash --> permite abrir un shell en el contenedor. Se sale con exit

## QDRANT

- http://localhost:6333/dashboard --> Web UI