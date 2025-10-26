# ===============================
# 🐳 Blog Docker Multi-Env Makefile (v7: Octane BG + Attach)
# ===============================

DC = docker compose
BACKEND_DIR = ../blog.backend
FRONTEND_DIR = ../blog.frontend
BLOG_ENV_SECRET ?= $(shell echo $$BLOG_ENV_SECRET)

.PHONY: up-local up-production down-local down-production \
        build clean reset-docker \
        sh-laravel sh-nextjs migrate seed yarn \
        laravel-log laravel-log-clear laravel-log-error \
        env-encrypt-local env-encrypt-production \
        decrypt-backend-local decrypt-backend-production \
        decrypt-frontend-local decrypt-frontend-production \
        status verify-env backup-env

# ===============================
# 🚀 UP / DOWN
# ===============================

up-local:
	@echo "🚀 Starting LOCAL containers (Octane direct on :4000)..."
	$(MAKE) decrypt-backend-local
	$(MAKE) decrypt-frontend-local
	APP_ENV=local NODE_ENV=development $(DC) -f ./docker-compose.local.yml up -d --build
	@echo "✅ Local containers running (Octane direct on :4000)"

up-production:
	@echo "🚀 Starting PRODUCTION containers (Nginx + Next.js + Laravel)..."
	$(MAKE) decrypt-backend-production
	$(MAKE) decrypt-frontend-production
	APP_ENV=production NODE_ENV=production $(DC) -f ./docker-compose.production.yml up -d --build
	@echo "✅ Production containers running (Nginx + Laravel + Next.js)"

down-local:
	@echo "🛑 Stopping LOCAL containers..."
	$(DC) -f ./docker-compose.local.yml down -v
	rm -f $(BACKEND_DIR)/.env $(FRONTEND_DIR)/.env
	@echo "✅ Local containers stopped."

down-production:
	@echo "🛑 Stopping PRODUCTION containers..."
	$(DC) -f ./docker-compose.production.yml down -v
	rm -f $(BACKEND_DIR)/.env $(FRONTEND_DIR)/.env
	@echo "✅ Production containers stopped."

# ===============================
# 🧩 Build / Clean / Reset
# ===============================

build:
	@echo "🔧 Building Docker images..."
	$(DC) -f ./docker-compose.local.yml build --no-cache
	$(DC) -f ./docker-compose.production.yml build --no-cache

clean:
	@echo "🧹 Cleaning environment..."
	$(DC) down -v || true
	rm -f $(BACKEND_DIR)/.env $(FRONTEND_DIR)/.env
	@echo "✅ Clean complete."

reset-docker:
	@echo "🔥 Resetting all containers & images for this project..."
	@docker compose -f ./docker-compose.local.yml down -v --remove-orphans || true
	@docker compose -f ./docker-compose.production.yml down -v --remove-orphans || true
	@docker image prune -af
	@docker volume prune -f
	@docker network prune -f
	@echo "✅ Docker environment reset complete."

# ===============================
# 🧩 Laravel / Next.js Utilities
# ===============================

migrate:
	./scripts/artisan.sh migrate

seed:
	./scripts/artisan.sh db:seed

yarn:
	./scripts/yarn.sh

# ✅ Laravel attach 모드 (Octane 백그라운드 호환)
sh-laravel:
	@if ! docker ps | grep -q blog-laravel; then \
		echo "⚙️ Laravel container not running — starting..."; \
		$(DC) -f ./docker-compose.local.yml up -d laravel; \
	fi
	@echo "🧩 Attaching to Laravel container shell..."
	$(DC) -f ./docker-compose.local.yml exec -it laravel /bin/sh || true

sh-nextjs:
	$(DC) -f ./docker-compose.local.yml exec nextjs sh

# ===============================
# 📜 Laravel Log Commands
# ===============================

laravel-log:
	@echo "🧾 Viewing Laravel Octane log..."
	@$(DC) -f ./docker-compose.local.yml exec laravel sh -c "tail -n 50 -f /var/log/octane.log"

laravel-log-clear:
	@$(DC) -f ./docker-compose.local.yml exec laravel sh -c "echo '' > /var/log/octane.log"
	@echo "✅ Octane log cleared."

laravel-log-error:
	@$(DC) -f ./docker-compose.local.yml exec laravel sh -c "grep -i 'ERROR' /var/log/octane.log || echo 'No errors found ✅'"

# ===============================
# 🔐 Encrypt / Decrypt ENV
# ===============================

env-encrypt-local:
	@echo "🔐 Encrypting backend .env → .env.local.enc..."
	@if [ -f $(BACKEND_DIR)/.env ]; then \
		cd $(BACKEND_DIR) && openssl enc -aes-256-cbc -pbkdf2 -salt \
			-in .env -out .env.local.enc -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Backend .env.local.enc 생성 완료."; \
	else echo "⚠️  Backend .env not found."; fi
	@echo "🔐 Encrypting frontend .env → .env.local.enc..."
	@if [ -f $(FRONTEND_DIR)/.env ]; then \
		cd $(FRONTEND_DIR) && openssl enc -aes-256-cbc -pbkdf2 -salt \
			-in .env -out .env.local.enc -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Frontend .env.local.enc 생성 완료."; \
	else echo "⚠️  Frontend .env not found."; fi

env-encrypt-production:
	@echo "🔐 Encrypting backend .env → .env.production.enc..."
	@if [ -f $(BACKEND_DIR)/.env ]; then \
		cd $(BACKEND_DIR) && openssl enc -aes-256-cbc -pbkdf2 -salt \
			-in .env -out .env.production.enc -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Backend .env.production.enc 생성 완료."; \
	else echo "⚠️  Backend .env not found."; fi
	@echo "🔐 Encrypting frontend .env → .env.production.enc..."
	@if [ -f $(FRONTEND_DIR)/.env ]; then \
		cd $(FRONTEND_DIR) && openssl enc -aes-256-cbc -pbkdf2 -salt \
			-in .env -out .env.production.enc -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Frontend .env.production.enc 생성 완료."; \
	else echo "⚠️  Frontend .env not found."; fi

decrypt-backend-local:
	@echo "🔓 Decrypting backend .env.local.enc..."
	@if [ -f $(BACKEND_DIR)/.env.local.enc ]; then \
		openssl enc -d -aes-256-cbc -pbkdf2 \
			-in $(BACKEND_DIR)/.env.local.enc \
			-out $(BACKEND_DIR)/.env -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Backend .env.local.enc 복호화 완료."; \
	else echo "⚠️  Backend .env.local.enc not found."; fi

decrypt-backend-production:
	@echo "🔓 Decrypting backend .env.production.enc..."
	@if [ -f $(BACKEND_DIR)/.env.production.enc ]; then \
		openssl enc -d -aes-256-cbc -pbkdf2 \
			-in $(BACKEND_DIR)/.env.production.enc \
			-out $(BACKEND_DIR)/.env -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Backend .env.production.enc 복호화 완료."; \
	else echo "⚠️  Backend .env.production.enc not found."; fi

decrypt-frontend-local:
	@echo "🔓 Decrypting frontend .env.local.enc..."
	@if [ -f $(FRONTEND_DIR)/.env.local.enc ]; then \
		openssl enc -d -aes-256-cbc -pbkdf2 \
			-in $(FRONTEND_DIR)/.env.local.enc \
			-out $(FRONTEND_DIR)/.env -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Frontend .env.local.enc 복호화 완료."; \
	else echo "⚠️  Frontend .env.local.enc not found."; fi

decrypt-frontend-production:
	@echo "🔓 Decrypting frontend .env.production.enc..."
	@if [ -f $(FRONTEND_DIR)/.env.production.enc ]; then \
		openssl enc -d -aes-256-cbc -pbkdf2 \
			-in $(FRONTEND_DIR)/.env.production.enc \
			-out $(FRONTEND_DIR)/.env -k "$(BLOG_ENV_SECRET)"; \
		echo "✅ Frontend .env.production.enc 복호화 완료."; \
	else echo "⚠️  Frontend .env.production.enc not found."; fi

# ===============================
# 🧠 System Status & Backup
# ===============================

verify-env:
	@echo "\n🧠 Verifying Environment Variables..."
	-@$(DC) exec laravel printenv | grep APP_ENV || echo "⚠️ Laravel not running."
	-@$(DC) exec nextjs printenv | grep NODE_ENV || echo "⚠️ Next.js not running."
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
	@echo "──────────────────────────────────────────────"

backup-env:
	@mkdir -p ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs
	cp -v $(BACKEND_DIR)/.env.*.enc ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs/ 2>/dev/null || true
	cp -v $(FRONTEND_DIR)/.env.*.enc ~/Library/Mobile\ Documents/com~apple~CloudDocs/blog_envs/ 2>/dev/null || true
	@echo "✅ Encrypted envs backed up to iCloud."