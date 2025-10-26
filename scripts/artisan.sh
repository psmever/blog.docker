#!/usr/bin/env bash
set -euo pipefail

# 루트 경로 계산
PROJ_ROOT=$(cd "$(dirname "$0")/.." && pwd)
COMPOSE_FILE="$PROJ_ROOT/docker-compose.local.yml"
SERVICE_NAME="laravel"

# 실행 중인 laravel 컨테이너 ID 확인
LARAVEL_CONTAINER=$(docker compose -f "$COMPOSE_FILE" ps -q $SERVICE_NAME || true)

if [ -n "$LARAVEL_CONTAINER" ] && [ "$(docker inspect -f '{{.State.Running}}' "$LARAVEL_CONTAINER" 2>/dev/null)" = "true" ]; then
  echo "🚀 Executing artisan command in running $SERVICE_NAME container..."
  docker compose -f "$COMPOSE_FILE" exec $SERVICE_NAME php artisan "$@"
else
  echo "⚙️ Laravel container not running — starting temporary container..."
  docker compose -f "$COMPOSE_FILE" run --rm $SERVICE_NAME php artisan "$@"
fi