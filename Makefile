SHELL := /bin/sh
COMPOSE := docker compose

.PHONY: up down status logs pull-models warm-models verify ingest ask evaluate reset

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

reset:
	$(COMPOSE) down -v

status:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f --tail=100

pull-models:
	./scripts/pull-models.sh

warm-models:
	./scripts/warm-models.sh

verify:
	./scripts/verify-stack.sh

ingest:
	cd app && python -m rag.ingest --docs-dir ../docs --force-recreate

ask:
	@if [ -z "$(Q)" ]; then echo 'Usa: make ask Q="tu pregunta"'; exit 1; fi
	cd app && python -m rag.ask --question "$(Q)"

evaluate:
	cd app && python -m rag.evaluate --csv ../evaluation/questions.csv
