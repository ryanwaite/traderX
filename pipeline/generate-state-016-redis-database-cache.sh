#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATED_ROOT="${TRADERX_GENERATED_ROOT:-${ROOT}/generated}"
TARGET_ROOT="${GENERATED_ROOT}/code/target-generated"
STATE_ID="016-redis-database-cache"
PARENT_STATE_ID="005-postgres-database-replacement"

echo "[info] generating parent state ${PARENT_STATE_ID} for ${STATE_ID}"
bash "${ROOT}/pipeline/generate-state.sh" "${PARENT_STATE_ID}"
bash "${ROOT}/pipeline/render-state-016-redis-database-cache.sh"
bash "${ROOT}/pipeline/generate-state-architecture-doc.sh" "${STATE_ID}"

cat <<'EOF'
[summary] state=016-redis-database-cache
[summary] parent-state=005-postgres-database-replacement
[summary] impacted-components=account-service,position-service,trade-processor,redis
[summary] cache-strategy=cache-aside-with-post-commit-invalidation
EOF
