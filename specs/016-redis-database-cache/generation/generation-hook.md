# Generation Hook: 016-redis-database-cache

- Hook script: `pipeline/generate-state-016-redis-database-cache.sh`
- Parent state: `005-postgres-database-replacement`
- Runtime overrides: `specs/016-redis-database-cache/generation/runtime-overrides/`

The hook generates state 005, overlays Redis-aware service sources and configuration, then adds the Redis service to the inherited compose runtime.
