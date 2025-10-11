# ===============================
# 🐳 Blog Docker Multi-Env Makefile (v4)
# ===============================

DC = docker compose -f ./docker-compose.yml
BACKEND_DIR = ../blog.backend
FRONTEND_DIR = ../blog.frontend
BLOG_ENV_SECRET ?= $(shell echo $$BLOG_ENV_SECRET)
ENV_TARGET ?= $(word 2,$(MAKECMDGOALS))

.PHONY: up down logs build sh-php sh-node migrate seed yarn clean \
        env-encrypt decrypt-backend decrypt-frontend verify-env status backup-env

# ===============================
# 🚀 Docker up/down
# ===============================

up:
	@if [ -z "$(ENV_TARGET)" ]; then \
		echo "❌ 사용법: make up [local|development|production]"; exit 1; \
	fi; \
	echo "🚀 Starting containers for ENV=$(ENV_TARGET)..."; \
	$(MAKE) --no-print-directory decrypt-backend $(ENV_TARGET); \
	$(MAKE) --no-print-directory decrypt-frontend $(ENV_TARGET); \
	echo "✅ .env 복호화 완료 (backend + frontend)"; \
	APP_ENV=$(ENV_TARGET) NODE_ENV=$(ENV_TARGET) $(DC) up -d --build; \
	echo "✅ Containers running for $(ENV_TARGET)!"; \
	exit 0

down:
	@echo "🛑 Stopping all containers..."
	$(DC) down -v
	@echo "🧹 Cleaning temporary .env files..."
	rm -f $(BACKEND_DIR)/.env $(FRONTEND_DIR)/.env
	@echo "✅ All containers stopped and .env cleaned."

# ===============================
# 🧩 Common Docker Utilities
# ===============================

logs:
	$(DC) logs -f --tail=200

# ===============================
# 📜 Laravel Log Commands
# ===============================

laravel-log:
	@echo "🧾 Viewing Laravel logs from container (blog-php)..."
	@tail_count=$(or $(tail),50); \
	follow_flag=$(if $(filter true,$(follow)),-f,); \
	docker compose -f ./docker-compose.yml exec php sh -c "cd /var/www/html && tail $$follow_flag -n $$tail_count storage/logs/laravel.log"

laravel-log-clear:
	@echo "🧹 Clearing Laravel log file..."
	@docker compose -f ./docker-compose.yml exec php sh -c "echo '' > /var/www/html/storage/logs/laravel.log"
	@echo "✅ Laravel log file cleared."

laravel-log-error:
	@echo "❗ Showing only ERROR lines from Laravel log..."
	@docker compose -f ./docker-compose.yml exec php sh -c "grep -i 'ERROR' /var/www/html/storage/logs/laravel.log || echo 'No errors found ✅'"
# ===============================

# 🛠 Build & Shell Access
build:
	$(DC) build --no-cache

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
	echo "🧹 Cleaned Docker and .env files."

# ===============================
# 🔐 Encrypt / Decrypt per environment
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
		echo "⚠️  $(BACKEND_DIR)/.env 파일이 없습니다. 건너뜀."; \
	fi; \
	echo "🔐 Encrypting frontend .env → .env.$(ENV_TARGET).enc..."; \
	if [ -f $(FRONTEND_DIR)/.env ]; then \
		cd $(FRONTEND_DIR) && openssl enc -aes-256-cbc -pbkdf2 -salt \
			-in .env -out .env.$(ENV_TARGET).enc -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Frontend .env.$(ENV_TARGET).enc 생성 완료."; \
	else \
		echo "⚠️  $(FRONTEND_DIR)/.env 파일이 없습니다. 건너뜀."; \
	fi

decrypt-backend:
	@if [ -z "$(ENV_TARGET)" ]; then \
		echo "❌ 사용법: make decrypt-backend [local|development|production]"; exit 1; \
	fi; \
	echo "🔓 Decrypting backend .env.$(ENV_TARGET).enc ..."; \
	if [ -f $(BACKEND_DIR)/.env.$(ENV_TARGET).enc ]; then \
		openssl enc -d -aes-256-cbc -pbkdf2 \
			-in $(BACKEND_DIR)/.env.$(ENV_TARGET).enc \
			-out $(BACKEND_DIR)/.env \
			-k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Backend .env.$(ENV_TARGET).enc → .env 복호화 완료"; \
	else \
		echo "⚠️  $(BACKEND_DIR)/.env.$(ENV_TARGET).enc 파일이 없습니다."; \
	fi

decrypt-frontend:
	@if [ -z "$(ENV_TARGET)" ]; then \
		echo "❌ 사용법: make decrypt-frontend [local|development|production]"; exit 1; \
	fi; \
	echo "🔓 Decrypting frontend .env.$(ENV_TARGET).enc ..."; \
	if [ -f $(FRONTEND_DIR)/.env.$(ENV_TARGET).enc ]; then \
		openssl enc -d -aes-256-cbc -pbkdf2 \
			-in $(FRONTEND_DIR)/.env.$(ENV_TARGET).enc \
			-out $(FRONTEND_DIR)/.env \
			-k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Frontend .env.$(ENV_TARGET).enc → .env 복호화 완료"; \
	else \
		echo "⚠️  $(FRONTEND_DIR)/.env.$(ENV_TARGET).enc 파일이 없습니다."; \
	fi

backup-env:
	@mkdir -p ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs
	cp -v $(BACKEND_DIR)/.env.*.enc ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs/ 2>/dev/null || true
	cp -v $(FRONTEND_DIR)/.env.*.enc ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs/ 2>/dev/null || true
	echo "✅ Encrypted .env.*.enc 파일이 iCloud로 백업되었습니다."

# ===============================
# 🧠 Verification & Status Check
# ===============================

verify-env:
	@echo "\n🧠 Verifying Environment Variables..."
	@echo "Backend:"
	-@$(DC) exec php printenv | grep APP_ENV || echo "⚠️ PHP 컨테이너가 실행 중이 아닙니다."
	@echo "\nFrontend:"
	-@$(DC) exec node printenv | grep NODE_ENV || echo "⚠️ Node 컨테이너가 실행 중이 아닙니다."
	@echo "✅ Environment 확인 완료."

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
# 🧩 Ignore Unused Args (Fix warnings)
# ===============================
%:
	@: