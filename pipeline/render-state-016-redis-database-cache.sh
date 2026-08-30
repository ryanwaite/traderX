#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATED_ROOT="${TRADERX_GENERATED_ROOT:-${ROOT}/generated}"
TARGET_ROOT="${GENERATED_ROOT}/code/target-generated"
COMPOSE_FILE="${GENERATED_ROOT}/code/target-generated/postgres-database-replacement/docker-compose.yml"

copy_service_overlay() {
  local service="$1"
  shift

  cp "${ROOT}/specs/016-redis-database-cache/generation/gradle/${service}.gradle" \
    "${TARGET_ROOT}/${service}/build.gradle"
  for relative_path in "$@"; do
    mkdir -p "$(dirname "${TARGET_ROOT}/${service}/${relative_path}")"
    cp "${ROOT}/templates/${service}-specfirst/${relative_path}" \
      "${TARGET_ROOT}/${service}/${relative_path}"
  done
}

copy_service_overlay \
  "account-service" \
  "src/main/java/finos/traderx/accountservice/config/CacheConfig.java" \
  "src/main/java/finos/traderx/accountservice/service/AccountService.java" \
  "src/main/java/finos/traderx/accountservice/service/AccountUserService.java"

copy_service_overlay \
  "position-service" \
  "src/main/java/finos/traderx/positionservice/config/CacheConfig.java" \
  "src/main/java/finos/traderx/positionservice/service/PositionService.java" \
  "src/main/java/finos/traderx/positionservice/service/TradeService.java"

copy_service_overlay \
  "trade-processor" \
  "src/main/java/finos/traderx/tradeprocessor/config/CacheConfig.java" \
  "src/main/java/finos/traderx/tradeprocessor/service/TradeService.java"

for service in account-service position-service trade-processor; do
  properties="${TARGET_ROOT}/${service}/src/main/resources/application.properties"
  if ! grep -q '^traderx.cache.enabled=' "${properties}"; then
    printf '\n%s\n' \
      'traderx.cache.enabled=${CACHE_ENABLED:false}' \
      'traderx.cache.ttl=${CACHE_TTL:30s}' \
      'spring.data.redis.host=${REDIS_HOST:localhost}' \
      'spring.data.redis.port=${REDIS_PORT:6379}' \
      'spring.data.redis.password=${REDIS_PASSWORD:}' \
      'spring.data.redis.ssl.enabled=${REDIS_SSL:false}' \
      >> "${properties}"
  fi
done

node - "${COMPOSE_FILE}" <<'NODE'
const fs = require('node:fs');

const composeFile = process.argv[2];
let compose = fs.readFileSync(composeFile, 'utf8');

function replaceOnce(search, replacement) {
  const first = compose.indexOf(search);
  if (first < 0 || compose.indexOf(search, first + search.length) >= 0) {
    throw new Error(`expected exactly one compose fragment: ${search}`);
  }
  compose = compose.replace(search, replacement);
}

function replaceFirst(search, replacement) {
  if (!compose.includes(search)) {
    throw new Error(`missing compose fragment: ${search}`);
  }
  compose = compose.replace(search, replacement);
}

replaceOnce(
  '\n  reference-data:\n',
  `
  redis:
    image: redis:7.4-alpine
    ports:
      - "16379:6379"
    healthcheck:
      test: [ "CMD", "redis-cli", "ping" ]
      interval: 5s
      timeout: 5s
      retries: 20

  reference-data:
`);

for (const [service, portVariable] of [
  ['account-service', 'ACCOUNT_SERVICE_PORT'],
  ['position-service', 'POSITION_SERVICE_PORT'],
  ['trade-processor', 'TRADE_PROCESSOR_SERVICE_PORT']
]) {
  replaceOnce(
    `  ${service}:
    build:`,
    `  ${service}:
    build:`);
  replaceOnce(
    `      ${portVariable}:`,
    `      CACHE_ENABLED: "true"
      CACHE_TTL: "30s"
      REDIS_HOST: "redis"
      REDIS_PORT: "6379"
      REDIS_SSL: "false"
      ${portVariable}:`);
}

for (const nextDependency of ['database', 'database', 'database']) {
  const search = `    depends_on:
      ${nextDependency}:`;
  const replacement = `    depends_on:
      redis:
        condition: service_healthy
      ${nextDependency}:`;
  replaceFirst(search, replacement);
}

fs.writeFileSync(composeFile, compose);
NODE
