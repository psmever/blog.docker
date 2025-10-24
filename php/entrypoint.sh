#!/usr/bin/env sh
set -e

echo "🚀 Laravel Octane Entrypoint Starting..."

if [ -f .env ]; then
  echo "✅ .env 파일이 감지되었습니다."
else
  echo "⚠️  .env 파일이 없습니다. 기본값으로 시작합니다."
fi

# 캐시 초기화
php artisan optimize:clear || true
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

# 마이그레이션 (선택)
php artisan migrate --force || true

echo "⚡ Starting Laravel Octane (Swoole)..."
exec php artisan octane:start --server=swoole --host=0.0.0.0 --port=8000