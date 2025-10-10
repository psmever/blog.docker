# ===============================
# 📦 Blog Docker Makefile (local / development / production)
# ===============================

DC = docker compose -f ./docker-compose.yml
BACKEND_DIR = ../blog.backend
FRONTEND_DIR = ../blog.frontend
BLOG_ENV_SECRET ?= $(shell echo $$BLOG_ENV_SECRET)
ENV_TARGET := $(word 2,$(MAKECMDGOALS))

.PHONY: up down build logs sh-php sh-node migrate seed yarn clean \
        env-encrypt decrypt-backend decrypt-frontend backup-env verify-env status

# ===============================
# 🚀 UP / DOWN
# ===============================

up:
	@if [ -z "$(ENV_TARGET)" ]; then \
		echo "❌ 사용법: make up [local|development|production]"; exit 1; \
	fi; \
	echo "🚀 Starting containers for ENV=$(ENV_TARGET)..."; \
	$(MAKE) --no-print-directory decrypt-backend ENV=$(ENV_TARGET); \
	$(MAKE) --no-print-directory decrypt-frontend ENV=$(ENV_TARGET); \
	echo "✅ .env 복호화 완료 (backend + frontend)"; \
	$(DC) up -d --build; \
	echo "✅ Containers running for $(ENV_TARGET)!"; \
	exit 0

down:
	@if [ -z "$(ENV_TARGET)" ]; then \
		echo "❌ 사용법: make down [local|development|production]"; exit 1; \
	fi; \
	echo "🛑 Stopping containers for ENV=$(ENV_TARGET)..."; \
	$(DC) down -v; \
	echo "✅ Containers stopped for $(ENV_TARGET)."; \
	exit 0

# ===============================
# 🧩 BUILD / LOGS / ACCESS
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

# ===============================
# 🔐 ENCRYPT / DECRYPT
# ===============================

env-encrypt:
	@if [ -z "$(ENV_TARGET)" ]; then \
		echo "❌ 사용법: make env-encrypt [local|development|production]"; exit 1; \
	fi; \
	echo "🔐 Encrypting backend .env → .env.$(ENV_TARGET).enc..."; \
	if [ -f $(BACKEND_DIR)/.env ]; then \
		cd $(BACKEND_DIR) && openssl enc -aes-256-cbc -pbkdf2 -salt \
			-in .env -out .env.$(ENV_TARGET).enc -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Backend .env.$(ENV_TARGET).enc 생성 완료."; \
	else \
		echo "⚠️  $(BACKEND_DIR)/.env 파일 없음 — skip"; \
	fi; \
	echo "🔐 Encrypting frontend .env → .env.$(ENV_TARGET).enc..."; \
	if [ -f $(FRONTEND_DIR)/.env ]; then \
		cd $(FRONTEND_DIR) && openssl enc -aes-256-cbc -pbkdf2 -salt \
			-in .env -out .env.$(ENV_TARGET).enc -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Frontend .env.$(ENV_TARGET).enc 생성 완료."; \
	else \
		echo "⚠️  $(FRONTEND_DIR)/.env 파일 없음 — skip"; \
	fi; \
	exit 0

decrypt-backend:
	@if [ -z "$(ENV_TARGET)" ]; then \
		echo "❌ 사용법: make decrypt-backend [local|development|production]"; exit 1; \
	fi; \
	echo "🔓 Decrypting backend .env.$(ENV_TARGET).enc ..."; \
	if [ -f $(BACKEND_DIR)/.env.$(ENV_TARGET).enc ]; then \
		rm -rf $(BACKEND_DIR)/.env; \
		openssl enc -d -aes-256-cbc -pbkdf2 \
			-in $(BACKEND_DIR)/.env.$(ENV_TARGET).enc \
			-out $(BACKEND_DIR)/.env -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Backend .env.$(ENV_TARGET).enc → .env 복호화 완료"; \
	else \
		echo "⚠️  $(BACKEND_DIR)/.env.$(ENV_TARGET).enc 없음"; \
	fi; \
	exit 0

decrypt-frontend:
	@if [ -z "$(ENV_TARGET)" ]; then \
		echo "❌ 사용법: make decrypt-frontend [local|development|production]"; exit 1; \
	fi; \
	echo "🔓 Decrypting frontend .env.$(ENV_TARGET).enc ..."; \
	if [ -f $(FRONTEND_DIR)/.env.$(ENV_TARGET).enc ]; then \
		rm -rf $(FRONTEND_DIR)/.env; \
		openssl enc -d -aes-256-cbc -pbkdf2 \
			-in $(FRONTEND_DIR)/.env.$(ENV_TARGET).enc \
			-out $(FRONTEND_DIR)/.env -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Frontend .env.$(ENV_TARGET).enc → .env 복호화 완료"; \
	else \
		echo "⚠️  $(FRONTEND_DIR)/.env.$(ENV_TARGET).enc 없음"; \
	fi; \
	exit 0

# ===============================
# ☁️ BACKUP / VERIFY / STATUS
# ===============================

backup-env:
	@if [ -z "$(ENV_TARGET)" ]; then \
		echo "❌ 사용법: make backup-env [local|development|production]"; exit 1; \
	fi; \
	mkdir -p ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs; \
	cp -v $(BACKEND_DIR)/.env.$(ENV_TARGET).enc ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs/blog_backend.$(ENV_TARGET).enc || true; \
	cp -v $(FRONTEND_DIR)/.env.$(ENV_TARGET).enc ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs/blog_frontend.$(ENV_TARGET).enc || true; \
	echo "✅ $(ENV_TARGET) 환경 .env 암호화 파일 iCloud 백업 완료."; \
	exit 0

verify-env:
	@echo "🔍 Verifying environment in containers..."
	$(DC) exec php printenv | grep APP_ENV || true
	$(DC) exec node printenv | grep NODE_ENV || true
	@echo "✅ .env 반영 상태 확인 완료."

# ===============================
# 🧭 STATUS COMMAND
# ===============================

status:
	@echo "\n🌍 BLOG SYSTEM STATUS REPORT"
	@echo "──────────────────────────────────────────────"
	@echo "📦 Docker Containers:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo "\n⚙️ Environment Summary:"
	@echo "Backend .env →"
	@[ -f $(BACKEND_DIR)/.env ] && stat -f "%N (updated: %SB)" -t "%Y-%m-%d %H:%M" $(BACKEND_DIR)/.env || echo "❌ Not Found"
	@echo "Frontend .env →"
	@[ -f $(FRONTEND_DIR)/.env ] && stat -f "%N (updated: %SB)" -t "%Y-%m-%d %H:%M" $(FRONTEND_DIR)/.env || echo "❌ Not Found"
	@echo "\n🔑 BLOG_ENV_SECRET:"
	@if [ -z "$(BLOG_ENV_SECRET)" ]; then echo "⚠️ Not Set"; else echo "✅ Set (Length: $$(echo -n $(BLOG_ENV_SECRET) | wc -c))"; fi
	@echo "\n🧩 PHP APP_ENV & Node ENV:"
	-@$(DC) exec php printenv | grep APP_ENV || echo "⚠️ PHP not running"
	-@$(DC) exec node printenv | grep NODE_ENV || echo "⚠️ Node not running"
	@echo "\n✅ Status check complete."
	@echo "──────────────────────────────────────────────"

# ===============================
# 🧩 Dummy Rule (에러 방지)
# ===============================
%:
	@: