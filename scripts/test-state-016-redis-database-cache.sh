#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATED_ROOT="${TRADERX_GENERATED_ROOT:-${ROOT}/generated}"
COMPOSE_FILE="${GENERATED_ROOT}/code/target-generated/postgres-database-replacement/docker-compose.yml"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-traderx-state-016}"

if [[ "${TRADERX_SKIP_PARENT_SMOKE:-0}" != "1" ]]; then
  TRADERX_LOCAL_RUNTIME_SCRIPT=1 \
  COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME}" \
    "${ROOT}/scripts/test-state-005-postgres-database-replacement.sh" "$@"
fi

docker compose -f "${COMPOSE_FILE}" --project-name "${COMPOSE_PROJECT_NAME}" exec -T redis \
  redis-cli ping | grep -Fxq PONG

redis_cli() {
  docker compose -f "${COMPOSE_FILE}" --project-name "${COMPOSE_PROJECT_NAME}" exec -T redis \
    redis-cli "$@" | tr -d '\r'
}

echo "[check] cache-aside reads populate Redis"
redis_cli FLUSHDB >/dev/null
curl -fsS "http://localhost:18088/account/22214" >/dev/null
curl -fsS "http://localhost:18090/positions/22214" >/dev/null
curl -fsS "http://localhost:18090/trades/22214" >/dev/null

for key in \
  "accountById::22214" \
  "positionsByAccount::22214" \
  "tradesByAccount::22214"; do
  [[ "$(redis_cli EXISTS "${key}")" == "1" ]] || {
    echo "[error] expected cache key was not populated: ${key}"
    exit 1
  }
done

echo "[check] successful account writes refresh item cache and invalidate collection cache"
curl -fsS "http://localhost:18088/account/" >/dev/null
[[ "$(redis_cli EXISTS "accounts::SimpleKey []")" == "1" ]] || {
  echo "[error] account collection cache was not populated"
  exit 1
}

curl -fsS -X PUT \
  -H "Content-Type: application/json" \
  --data '{"id":22214,"displayName":"Test Account 20"}' \
  "http://localhost:18088/account/" >/dev/null

[[ "$(redis_cli EXISTS "accountById::22214")" == "1" ]] || {
  echo "[error] account item cache was not refreshed after write"
  exit 1
}
[[ "$(redis_cli EXISTS "accounts::SimpleKey []")" == "0" ]] || {
  echo "[error] account collection cache was not invalidated after write"
  exit 1
}

echo "[done] state 016 Redis cache smoke tests passed"
