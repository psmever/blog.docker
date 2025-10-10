#!/usr/bin/env sh
set -e

echo "🚀 Laravel Entrypoint Starting..."

# DB 연결 대기
until php -r "exit(fsockopen(getenv('DB_HOST') ?: 'db', getenv('DB_PORT') ?: 3306) ? 0 : 1);"; do
  echo "⏳ waiting for database..."
  sleep 2
done

# composer install (최초만)
if [ ! -d "vendor" ]; then
  echo "📦 Installing composer dependencies..."
  composer install --no-interaction --prefer-dist
else
  echo "✅ Composer dependencies already installed."
fi

# 개발환경에서 자동 migrate
if [ "$APP_ENV" = "local" ]; then
  echo "🚀 Running migrations in local env..."
  php artisan migrate --force || true
fi

# ⚙️ artisan 명령 모드 감지
if [ "$1" = "php" ] && [ "$2" = "artisan" ]; then
  echo "🧩 Detected artisan command → skip php-fpm"
  shift 2
  php artisan "$@"
  exit 0
fi

# ✅ 웹 서버 모드일 경우에만 PHP-FPM 실행
echo "✅ Starting PHP-FPM..."
exec php-fpm