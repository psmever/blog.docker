# ===============================
# 📦 Blog Docker Makefile
# (local / development / production)
# ===============================

DC = docker compose -f ./docker-compose.yml
BACKEND_DIR = ../blog.backend
FRONTEND_DIR = ../blog.frontend
BLOG_ENV_SECRET ?= $(shell echo $$BLOG_ENV_SECRET)

# 환경 지정 (예: make up local → ENV=local)
ARG ?= $(word 2, $(MAKECMDGOALS))
ENV ?= $(if $(ARG),$(ARG),local)

# “phony target” 에러 방지용
%:
	@:

.PHONY: up down build logs sh-php sh-node migrate seed yarn clean \
        env-encrypt decrypt decrypt-local decrypt-development decrypt-production backup-env

# ===============================
# 🚀 Docker 컨테이너 관리
# ===============================

up:
	@echo "🚀 Starting containers for ENV=$(ENV)..."
	@$(MAKE) decrypt-$(ENV)
	@echo "✅ .env 복호화 및 교체 완료"
	$(DC) up -d --build
	@echo ""
	@echo "✅ Containers running for $(ENV)!"
	@echo "💡 .env files remain on disk for debugging."

down:
	@echo "🛑 Stopping containers for ENV=$(ENV)..."
	$(DC) down -v
	@echo "✅ Containers stopped."

# ===============================
# 🔐 Encrypt / Decrypt per ENV
# ===============================

# 공통 암호화
define ENCRYPT_ENV
	@echo "🔐 Encrypting backend .env → .env.$(1).enc ..."
	@if [ -f $(BACKEND_DIR)/.env ]; then \
		cd $(BACKEND_DIR) && openssl enc -aes-256-cbc -pbkdf2 -salt \
			-in .env -out .env.$(1).enc -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Backend .env.$(1).enc created."; \
	else echo "⚠️  $(BACKEND_DIR)/.env not found."; fi

	@echo "🔐 Encrypting frontend .env → .env.$(1).enc ..."
	@if [ -f $(FRONTEND_DIR)/.env ]; then \
		cd $(FRONTEND_DIR) && openssl enc -aes-256-cbc -pbkdf2 -salt \
			-in .env -out .env.$(1).enc -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Frontend .env.$(1).enc created."; \
	else echo "⚠️  $(FRONTEND_DIR)/.env not found."; fi
endef

# 공통 복호화 (덮어쓰기 교체 전용)
define DECRYPT_ENV
	@echo "🔓 Decrypting backend .env.$(1).enc ..."
	@if [ -f $(BACKEND_DIR)/.env.$(1).enc ]; then \
		echo "→ using key: $(BLOG_ENV_SECRET)"; \
		echo "→ decrypting: $(BACKEND_DIR)/.env.$(1).enc"; \
		openssl enc -d -aes-256-cbc -pbkdf2 \
			-in $(BACKEND_DIR)/.env.$(1).enc \
			-out $(BACKEND_DIR)/.env.tmp -k "$(BLOG_ENV_SECRET)" || echo "❌ openssl failed"; \
		if [ -s $(BACKEND_DIR)/.env.tmp ]; then \
			mv -f $(BACKEND_DIR)/.env.tmp $(BACKEND_DIR)/.env; \
			echo "✅ Backend .env.$(1).enc → .env 복호화 완료"; \
		else \
			echo "❌ Backend 복호화 실패 — .env.tmp 비어 있음"; \
			rm -f $(BACKEND_DIR)/.env.tmp; \
		fi; \
	else \
		echo "⚠️  $(BACKEND_DIR)/.env.$(1).enc not found."; \
	fi; \
	echo "🔓 Decrypting frontend .env.$(1).enc ..."; \
	if [ -f $(FRONTEND_DIR)/.env.$(1).enc ]; then \
		openssl enc -d -aes-256-cbc -pbkdf2 \
			-in $(FRONTEND_DIR)/.env.$(1).enc \
			-out $(FRONTEND_DIR)/.env.tmp -k "$(BLOG_ENV_SECRET)" || echo "❌ openssl failed"; \
		if [ -s $(FRONTEND_DIR)/.env.tmp ]; then \
			mv -f $(FRONTEND_DIR)/.env.tmp $(FRONTEND_DIR)/.env; \
			echo "✅ Frontend .env.$(1).enc → .env 복호화 완료"; \
		else \
			echo "❌ Frontend 복호화 실패 — .env.tmp 비어 있음"; \
			rm -f $(FRONTEND_DIR)/.env.tmp; \
		fi; \
	else \
		echo "⚠️  $(FRONTEND_DIR)/.env.$(1).enc not found."; \
	fi
endef

# 환경별 명령
env-encrypt:
	$(call ENCRYPT_ENV,$(ENV))

decrypt:
	$(call DECRYPT_ENV,$(ENV))

decrypt-local:
	$(call DECRYPT_ENV,local)

decrypt-development:
	$(call DECRYPT_ENV,development)

decrypt-production:
	$(call DECRYPT_ENV,production)

# ===============================
# 🧩 Utility Commands
# ===============================

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
	rm -f $(BACKEND_DIR)/.env $(FRONTEND_DIR)/.env
	@echo "🧹 .env cleanup completed."

# ===============================
# ☁️ iCloud 백업 (선택)
# ===============================

backup-env:
	@mkdir -p ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs
	cp -v $(BACKEND_DIR)/.env.*.enc ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs/
	cp -v $(FRONTEND_DIR)/.env.*.enc ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs/
	@echo "✅ Encrypted .env files backed up to iCloud!"