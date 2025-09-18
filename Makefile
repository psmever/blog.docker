DC=docker compose -f ./docker-compose.yml

.PHONY: up down logs build sh-php sh-node init-laravel migrate seed yarn

up:
	$(DC) up -d --build

down:
	$(DC) down -v

logs:
	$(DC) logs -f --tail=200

build:
	$(DC) build --no-cache

sh-php:
	$(DC) exec php bash

sh-node:
	$(DC) exec node sh

init-laravel:
	./scripts/init-laravel.sh

migrate:
	./scripts/artisan.sh migrate

seed:
	./scripts/artisan.sh db:seed

yarn:
	./scripts/yarn.sh