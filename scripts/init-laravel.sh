#!/usr/bin/env bash
set -euo pipefail

PROJ_ROOT=$(cd "$(dirname "$0")/.." && pwd)

# 컨테이너 내부에서 /tmp 에 라라벨 생성 → /var/www/html 로 복사 ('.git*' 보존)
docker compose -f "$PROJ_ROOT/docker-compose.yml" run --rm php bash -lc '
  set -euo pipefail

  APP_DIR="/var/www/html"
  TMP_DIR="$(mktemp -d -p /tmp laravel-init-XXXXXX)"

  echo "[INFO] Container tmp: $TMP_DIR"

  # 1) 임시 디렉토리에 라라벨 스켈레톤 생성
  composer create-project laravel/laravel "$TMP_DIR"

  # 2) .git* 보존하면서 복사 (rsync 없이 tar 파이프 사용)
  #    - 제외: .git, .gitignore, .gitattributes (대상에 있는 건 유지)
  tar -C "$TMP_DIR" \
      --exclude=".git" --exclude=".gitignore" --exclude=".gitattributes" \
      -cf - . \
  | tar -C "$APP_DIR" -xf -

  # 3) 앱 디렉토리에서 키/링크/의존성 처리
  cd "$APP_DIR"
  php artisan key:generate || true
  php artisan storage:link || true
  composer install

  echo "[OK] Laravel installed into $APP_DIR (preserved existing .git*)"
'
echo "[OK] Done."