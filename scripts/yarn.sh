#!/usr/bin/env bash
set -euo pipefail
PROJ_ROOT=$(cd "$(dirname "$0")/.." && pwd)
docker compose -f "$PROJ_ROOT/docker-compose.yml" run --rm node yarn "$@"