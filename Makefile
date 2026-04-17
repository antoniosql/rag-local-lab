SHELL := /bin/sh
COMPOSE := docker compose

.PHONY: up down status logs pull-models warm-models verify reset

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
