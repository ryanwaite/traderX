#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -x "${ROOT}/pipeline/generate-state.sh" && "${TRADERX_SKIP_GENERATE:-0}" != "1" ]]; then
  bash "${ROOT}/pipeline/generate-state.sh" 016-redis-database-cache
fi

TRADERX_LOCAL_RUNTIME_SCRIPT=1 \
TRADERX_SKIP_GENERATE=1 \
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-traderx-state-016}" \
  exec "${ROOT}/scripts/start-state-005-postgres-database-replacement-generated.sh" "$@"
