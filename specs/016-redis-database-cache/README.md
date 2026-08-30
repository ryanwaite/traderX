# Feature Pack 016: Redis Database Cache

![linux/mac support](https://badgen.net/badge/linux%2Fmac/supported/green?icon=linux) ![windows support](https://badgen.net/badge/windows/not%20supported/red?icon=windows)

Status: Implemented  
Track: `architecture`  
Previous state: `005-postgres-database-replacement`

This state adds opt-in cache-aside reads for account, trade, and position data. PostgreSQL remains authoritative, and write-driven invalidation is transaction-aware.

Generate it with:

```bash
bash pipeline/generate-state.sh 016-redis-database-cache
```

Runtime entrypoints:

- `./scripts/start-state-016-redis-database-cache-generated.sh`
- `./scripts/status-state-016-redis-database-cache-generated.sh`
- `./scripts/test-state-016-redis-database-cache.sh`
- `./scripts/stop-state-016-redis-database-cache-generated.sh`

PowerShell (`.ps1`) runtime entrypoints are not provided for this state.
