# ===============================
# 🐳 Blog Docker Multi-Env Makefile (v7: Octane BG + Attach)
# ===============================

# Colima / macOS 호환 Compose Wrapper
# (v2가 없으면 v1 명령으로 fallback)
DC = $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose"; else echo "docker-compose"; fi)
BACKEND_DIR = ../blog.backend
FRONTEND_DIR = ../blog.frontend
BLOG_ENV_SECRET ?= $(shell echo $$BLOG_ENV_SECRET)
COLIMA_CPU ?= 4
COLIMA_MEMORY ?= 8
COLIMA_DISK ?= 60
.DEFAULT_GOAL := help

.PHONY: colima colima-start colima-start-custom colima-status colima-stop \
        up-local up-production down-local down-production \
        build clean reset-docker \
        sh-laravel sh-nextjs migrate seed yarn \
        logs laravel-log laravel-log-clear laravel-log-error \
        env-encrypt-local env-encrypt-production \
        decrypt-backend-local decrypt-backend-production \
        decrypt-frontend-local decrypt-frontend-production \
        restart-docker restart-all-local restart-all-production \
        restart-laravel-local restart-nextjs-local restart-mariadb-local \
        restart-nginx-production restart-laravel-production restart-nextjs-production restart-mariadb-production \
        status verify-env backup-env help

help:
	@echo "📚 Blog Docker 환경 명령어 안내"
	@echo "──────────────────────────────────────────────"
	@echo "🧊 Colima Runtime:"
	@echo "  make colima             → Colima 자동 실행 (켜져있으면 상태만 표시)"
	@echo "  make colima-start       → config.yaml 기반 Colima 실행"
	@echo "  make colima-start-custom → 환경변수로 리소스 지정 후 실행"
	@echo "  make colima-status      → Colima 현재 상태 출력"
	@echo "  make colima-stop        → Colima 종료"
	@echo ""
	@echo "🎬 실행 및 종료:"
	@echo "  make up-local           → 로컬 컨테이너 실행 (Octane :4000)"
	@echo "  make up-production      → 프로덕션 컨테이너 실행"
	@echo "  make down-local         → 로컬 컨테이너 중지 및 정리"
	@echo "  make down-production    → 프로덕션 컨테이너 중지 및 정리"
	@echo ""
	@echo "🔁 재시작:"
	@echo "  make restart-docker             → Docker(Colima) 런타임 재시작"
	@echo "  make restart-all-local          → Docker 재시작 후 로컬 모든 컨테이너 재시작"
	@echo "  make restart-all-production     → Docker 재시작 후 프로덕션 모든 컨테이너 재시작"
	@echo "  make restart-nextjs-local        → 로컬 Next.js 컨테이너 재시작"
	@echo "  make restart-laravel-local       → 로컬 Laravel 컨테이너 재시작"
	@echo "  make restart-mariadb-local       → 로컬 MariaDB 컨테이너 재시작"
	@echo "  make restart-nginx-production    → 프로덕션 Nginx 컨테이너 재시작"
	@echo "  make restart-nextjs-production   → 프로덕션 Next.js 컨테이너 재시작"
	@echo "  make restart-laravel-production  → 프로덕션 Laravel 컨테이너 재시작"
	@echo "  make restart-mariadb-production  → 프로덕션 MariaDB 컨테이너 재시작"
	@echo ""
	@echo "🧹 빌드 및 정리:"
	@echo "  make build              → 로컬·프로덕션 이미지 재빌드"
	@echo "  make clean              → 모든 컨테이너/볼륨 정리"
	@echo "  make reset-docker       → 관련 이미지·볼륨·네트워크 초기화"
	@echo ""
	@echo "🧩 개발 유틸리티:"
	@echo "  make migrate            → Laravel 마이그레이션 실행"
	@echo "  make seed               → DB 시드 실행"
	@echo "  make yarn               → Next.js 패키지 설치"
	@echo "  make sh-laravel         → Laravel 컨테이너 쉘 접속"
	@echo "  make sh-nextjs          → Next.js 컨테이너 쉘 접속"
	@echo ""
	@echo "📜 로그:"
	@echo "  make logs             → 로컬 docker-compose 로그 tail (기본: laravel 제외, SERVICE=이름 으로 단일 서비스 지정 가능)"
	@echo "  make laravel-log        → Octane 로그 tail"
	@echo "  make laravel-log-clear  → Octane 로그 초기화"
	@echo "  make laravel-log-error  → Octane 로그에서 ERROR 검색"
	@echo ""
	@echo "🔐 ENV 암·복호화:"
	@echo "  make env-encrypt-local        → 로컬 .env 암호화"
	@echo "  make env-encrypt-production   → 프로덕션 .env 암호화"
	@echo "  make decrypt-backend-local    → 백엔드 로컬 .env 복호화"
	@echo "  make decrypt-backend-production → 백엔드 프로덕션 .env 복호화"
	@echo "  make decrypt-frontend-local   → 프런트 로컬 .env 복호화"
	@echo "  make decrypt-frontend-production → 프런트 프로덕션 .env 복호화"
	@echo ""
	@echo "🧠 상태 및 백업:"
	@echo "  make verify-env         → 컨테이너 환경변수 확인"
	@echo "  make status             → 도커 상태 리포트"
	@echo "  make backup-env         → 암호화된 env 파일 iCloud 백업"
	@echo ""
	@echo "👉 원하는 명령어를 make 뒤에 입력하세요. (예: make up-local)"

# ===============================
# 🧊 Colima Runtime Helpers
# ===============================

colima:
	@if colima status >/dev/null 2>&1; then \
		echo "✅ Colima already running. Showing status..."; \
		$(MAKE) colima-status; \
	else \
		echo "🚀 Colima not running. Booting up (config.yaml)..."; \
		$(MAKE) colima-start; \
		$(MAKE) colima-status; \
	fi

colima-start:
	@echo "🚀 Starting Colima using ~/.colima/default/config.yaml (colima start)..."
	@colima start
	@echo "✅ Colima start command finished."

colima-start-custom:
	@echo "🚀 Starting Colima with custom resources (cpu=$(COLIMA_CPU), memory=$(COLIMA_MEMORY)GB, disk=$(COLIMA_DISK)GB)..."
	@colima start --cpu $(COLIMA_CPU) --memory $(COLIMA_MEMORY) --disk $(COLIMA_DISK)
	@echo "✅ Colima custom start command finished."

colima-status:
	@echo "🧊 Checking Colima status..."
	@colima status || echo "⚠️ Colima가 실행 중이 아닙니다."

colima-stop:
	@echo "🛑 Stopping Colima..."
	@colima stop || echo "⚠️ Colima가 이미 중지 상태일 수 있습니다."
	@echo "✅ Colima stop command finished."

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
# 🔁 Restart (Local / Production)
# ===============================

restart-docker:
	@echo "♻️ Restarting Docker runtime (Colima)..."
	@if command -v colima >/dev/null 2>&1; then \
		if colima status >/dev/null 2>&1; then \
			colima restart || { echo "⚠️ colima restart failed, trying stop/start..."; colima stop && colima start; }; \
		else \
			echo "⚠️ Colima not running; starting Colima..."; \
			colima start; \
		fi; \
		echo "✅ Docker runtime ready."; \
	else \
		echo "⚠️ Colima not found. Skipping runtime restart."; \
	fi

restart-all-local:
	@echo "🔄 Restarting Docker runtime + ALL LOCAL containers..."
	@$(MAKE) restart-docker
	$(DC) -f ./docker-compose.local.yml restart
	@echo "✅ Docker runtime + all local containers restarted."

restart-all-production:
	@echo "🔄 Restarting Docker runtime + ALL PRODUCTION containers..."
	@$(MAKE) restart-docker
	$(DC) -f ./docker-compose.production.yml restart
	@echo "✅ Docker runtime + all production containers restarted."

restart-nextjs-local:
	@echo "🔄 Restarting LOCAL Next.js container..."
	$(DC) -f ./docker-compose.local.yml restart nextjs
	@echo "✅ Local Next.js restarted."

restart-laravel-local:
	@echo "🔄 Restarting LOCAL Laravel container..."
	$(DC) -f ./docker-compose.local.yml restart laravel
	@echo "✅ Local Laravel restarted."

restart-mariadb-local:
	@echo "🔄 Restarting LOCAL MariaDB container..."
	$(DC) -f ./docker-compose.local.yml restart mariadb
	@echo "✅ Local MariaDB restarted."

restart-nginx-production:
	@echo "🔄 Restarting PRODUCTION Nginx container..."
	$(DC) -f ./docker-compose.production.yml restart nginx
	@echo "✅ Production Nginx restarted."

restart-nextjs-production:
	@echo "🔄 Restarting PRODUCTION Next.js container..."
	$(DC) -f ./docker-compose.production.yml restart nextjs
	@echo "✅ Production Next.js restarted."

restart-laravel-production:
	@echo "🔄 Restarting PRODUCTION Laravel container..."
	$(DC) -f ./docker-compose.production.yml restart laravel
	@echo "✅ Production Laravel restarted."

restart-mariadb-production:
	@echo "🔄 Restarting PRODUCTION MariaDB container..."
	$(DC) -f ./docker-compose.production.yml restart mariadb
	@echo "✅ Production MariaDB restarted."

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
	@$(DC) -f ./docker-compose.local.yml down -v --remove-orphans || true
	@$(DC) -f ./docker-compose.production.yml down -v --remove-orphans || true
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

logs:
	@if [ -n "$$SERVICE" ]; then \
		echo "🧾 Viewing docker compose logs for service: $$SERVICE..."; \
		$(DC) -f ./docker-compose.local.yml logs -f --tail=100 $$SERVICE; \
	else \
		excluded_service=laravel; \
		echo "🧾 Viewing docker compose logs for all local services (excluding $$excluded_service)..."; \
		services=$$($(DC) -f ./docker-compose.local.yml config --services | grep -v "^$$excluded_service$$"); \
		if [ -z "$$services" ]; then \
			echo "⚠️ No services to tail after applying exclusion."; \
		else \
			$(DC) -f ./docker-compose.local.yml logs -f --tail=100 $$services; \
		fi; \
	fi

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
