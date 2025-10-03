#!/usr/bin/env sh
set -e

# DB 준비 대기
until php -r "exit(fsockopen(getenv('DB_HOST') ?: 'db', getenv('DB_PORT') ?: 3306) ? 0 : 1);"; do
  echo "⏳ waiting for database..."
  sleep 2
done

# 개발 환경일 때만 migrate 실행
if [ "$APP_ENV" = "local" ]; then
  echo "🚀 Running migrations in local env..."
  php artisan migrate --force || true
else
  echo "ℹ️ APP_ENV=$APP_ENV → skip migrations"
fi

# php-fpm 실행
exec php-fpm