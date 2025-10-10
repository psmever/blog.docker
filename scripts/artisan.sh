#!/usr/bin/env bash
set -euo pipefail

# 루트 경로 계산
PROJ_ROOT=$(cd "$(dirname "$0")/.." && pwd)
DC="docker compose -f \"$PROJ_ROOT/docker-compose.yml\""

# 실행 중인 php 컨테이너 ID 확인
PHP_CONTAINER=$(docker compose -f "$PROJ_ROOT/docker-compose.yml" ps -q php || true)

if [ -n "$PHP_CONTAINER" ] && [ "$(docker inspect -f '{{.State.Running}}' "$PHP_CONTAINER" 2>/dev/null)" = "true" ]; then
  echo "🚀 Executing artisan command in running php container..."
  docker compose -f "$PROJ_ROOT/docker-compose.yml" exec php php artisan "$@"
else
  echo "⚙️ PHP container not running — starting temporary container..."
  docker compose -f "$PROJ_ROOT/docker-compose.yml" run --rm php php artisan "$@"
fi