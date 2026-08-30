#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRADERX_LOCAL_RUNTIME_SCRIPT=1 \
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-traderx-state-016}" \
  exec "${ROOT}/scripts/stop-state-005-postgres-database-replacement-generated.sh" "$@"
