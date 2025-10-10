# ===============================
# 📦 Blog Docker Makefile (local / development / production)
# ===============================

DC = docker compose -f ./docker-compose.yml
BACKEND_DIR = ../blog.backend
FRONTEND_DIR = ../blog.frontend
BLOG_ENV_SECRET ?= $(shell echo $$BLOG_ENV_SECRET)

.PHONY: up down build logs sh-php sh-node migrate seed yarn clean verify-env \
        env-encrypt decrypt-backend decrypt-frontend backup-env

# ===============================
# 🚀 Docker Lifecycle
# ===============================

up:
	@if [ -z "$(filter $(firstword $(MAKECMDGOALS)),local development production)" ]; then \
		echo "❌ 사용법: make up [local|development|production]"; exit 1; \
	fi
	$(MAKE) _up ENV=$(firstword $(MAKECMDGOALS))
	@exit 0

_up:
	@echo "🚀 Starting containers for ENV=$(ENV)..."
	@$(MAKE) decrypt-backend $(ENV)
	@$(MAKE) decrypt-frontend $(ENV)
	@echo "✅ .env 복호화 완료 (backend + frontend)"
	$(DC) up -d --build
	@echo "✅ Containers running for $(ENV)!"

down:
	@if [ -z "$(filter $(firstword $(MAKECMDGOALS)),local development production)" ]; then \
		echo "❌ 사용법: make down [local|development|production]"; exit 1; \
	fi
	$(MAKE) _down ENV=$(firstword $(MAKECMDGOALS))
	@exit 0

_down:
	@echo "🛑 Stopping containers for ENV=$(ENV)..."
	$(DC) down -v

build:
	$(DC) build --no-cache

logs:
	$(DC) logs -f --tail=200

sh-php:
	$(DC) exec php bash

sh-node:
	$(DC) exec node sh

migrate:
	./scripts/artisan.sh migrate

seed:
	./scripts/artisan.sh db:seed

yarn:
	./scripts/yarn.sh

clean:
	$(DC) down -v

# ===============================
# 🔐 Encrypt / Decrypt per ENV
# ===============================

env-encrypt:
	@if [ -z "$(filter $(firstword $(MAKECMDGOALS)),local development production)" ]; then \
		echo "❌ 사용법: make env-encrypt [local|development|production]"; exit 1; \
	fi
	$(MAKE) _env-encrypt ENV=$(firstword $(MAKECMDGOALS))
	@exit 0

_env-encrypt:
	@echo "🔐 Encrypting backend .env → .env.$(ENV).enc ..."
	@if [ -f $(BACKEND_DIR)/.env ]; then \
		cd $(BACKEND_DIR) && openssl enc -aes-256-cbc -pbkdf2 -salt \
			-in .env -out .env.$(ENV).enc -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Backend $(ENV) env encrypted."; \
	else \
		echo "⚠️  Skip: $(BACKEND_DIR)/.env not found."; \
	fi
	@echo "🔐 Encrypting frontend .env → .env.$(ENV).enc ..."
	@if [ -f $(FRONTEND_DIR)/.env ]; then \
		cd $(FRONTEND_DIR) && openssl enc -aes-256-cbc -pbkdf2 -salt \
			-in .env -out .env.$(ENV).enc -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Frontend $(ENV) env encrypted."; \
	else \
		echo "⚠️  Skip: $(FRONTEND_DIR)/.env not found."; \
	fi

decrypt-backend:
	@if [ -z "$(filter $(firstword $(MAKECMDGOALS)),local development production)" ]; then \
		echo "❌ 사용법: make decrypt-backend [local|development|production]"; exit 1; \
	fi
	$(MAKE) _decrypt-backend ENV=$(firstword $(MAKECMDGOALS))
	@exit 0

_decrypt-backend:
	@echo "🔓 Decrypting backend .env.$(ENV).enc ..."
	@if [ -f $(BACKEND_DIR)/.env.$(ENV).enc ]; then \
		rm -f $(BACKEND_DIR)/.env; \
		openssl enc -d -aes-256-cbc -pbkdf2 \
			-in $(BACKEND_DIR)/.env.$(ENV).enc \
			-out $(BACKEND_DIR)/.env \
			-k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Backend .env.$(ENV).enc → .env 복호화 완료"; \
	else \
		echo "⚠️  $(BACKEND_DIR)/.env.$(ENV).enc 파일을 찾을 수 없습니다."; \
	fi

decrypt-frontend:
	@if [ -z "$(filter $(firstword $(MAKECMDGOALS)),local development production)" ]; then \
		echo "❌ 사용법: make decrypt-frontend [local|development|production]"; exit 1; \
	fi
	$(MAKE) _decrypt-frontend ENV=$(firstword $(MAKECMDGOALS))
	@exit 0

_decrypt-frontend:
	@echo "🔓 Decrypting frontend .env.$(ENV).enc ..."
	@if [ -f $(FRONTEND_DIR)/.env.$(ENV).enc ]; then \
		rm -f $(FRONTEND_DIR)/.env; \
		openssl enc -d -aes-256-cbc -pbkdf2 \
			-in $(FRONTEND_DIR)/.env.$(ENV).enc \
			-out $(FRONTEND_DIR)/.env \
			-k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Frontend .env.$(ENV).enc → .env 복호화 완료"; \
	else \
		echo "⚠️  $(FRONTEND_DIR)/.env.$(ENV).enc 파일을 찾을 수 없습니다."; \
	fi

backup-env:
	@if [ -z "$(filter $(firstword $(MAKECMDGOALS)),local development production)" ]; then \
		echo "❌ 사용법: make backup-env [local|development|production]"; exit 1; \
	fi
	$(MAKE) _backup-env ENV=$(firstword $(MAKECMDGOALS))
	@exit 0

_backup-env:
	@mkdir -p ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs
	cp -v $(BACKEND_DIR)/.env.$(ENV).enc ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs/blog_backend.$(ENV).enc || true
	cp -v $(FRONTEND_DIR)/.env.$(ENV).enc ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs/blog_frontend.$(ENV).enc || true
	@echo "✅ Encrypted $(ENV) envs backed up to iCloud."

# ===============================
# 🔍 Verify .env in Containers
# ===============================

verify-env:
	@echo "🔍 Checking backend .env inside PHP container..."
	@$(DC) exec php sh -c "echo '--- /var/www/html/.env (first 5 lines) ---'; head -n 5 /var/www/html/.env || echo '⚠️  .env not found';"
	@echo ""
	@echo "🔍 Checking frontend .env inside Node container..."
	@$(DC) exec node sh -c "echo '--- /usr/src/app/.env (first 5 lines) ---'; head -n 5 /usr/src/app/.env || echo '⚠️  .env not found';"