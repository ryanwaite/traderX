# Quickstart: Redis Database Cache

## Generate the state

```bash
bash pipeline/generate-state.sh 016-redis-database-cache
```

To isolate generated output:

```bash
TRADERX_GENERATED_ROOT=/tmp/traderx-state-016 \
  bash pipeline/generate-state.sh 016-redis-database-cache
```

## Start and inspect

```bash
./scripts/start-state-016-redis-database-cache-generated.sh
./scripts/status-state-016-redis-database-cache-generated.sh
```

Redis is exposed locally on port `16379`. Account, position, and trade-processor services connect to it on the compose network and use a 30-second default cache lifetime.

## Validate

```bash
./scripts/test-state-016-redis-database-cache.sh
```

The smoke test verifies Redis readiness, cache population for repeated account/portfolio reads, and account cache refresh/invalidation after a successful write.

## Stop

```bash
./scripts/stop-state-016-redis-database-cache-generated.sh
```
