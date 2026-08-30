# Architecture (State 016 Redis Database Cache)

State 016 adds cache-aside reads and post-commit invalidation while PostgreSQL remains authoritative.

- Inherits architectural baseline from: `005-postgres-database-replacement`
- Generated from: `system/architecture.model.json`
- Canonical flows: `../../001-baseline-uncontainerized-parity/system/end-to-end-flows.md`

## Entry Points

- `ingress`: `http://localhost:8080`

## Architecture Diagram

```mermaid
flowchart LR
  trader["Trader Browser"]
  ingress["NGINX Ingress"]
  account["Account Service"]
  position["Position Service"]
  tradeProcessor["Trade Processor"]
  redis["Redis Cache"]
  database["PostgreSQL Database"]
  trader -->|"Requests"| ingress
  ingress -->|"Account API"| account
  ingress -->|"Portfolio API"| position
  account -->|"Cache-aside reads"| redis
  position -->|"Cache-aside reads"| redis
  tradeProcessor -->|"Post-commit invalidation"| redis
  account -->|"Authoritative reads/writes"| database
  position -->|"Cache misses"| database
  tradeProcessor -->|"Authoritative writes"| database
```

## Node Catalog

| Node | Kind | Label | Notes |
| --- | --- | --- | --- |
| `trader` | actor | Trader Browser | Uses TraderX through ingress. |
| `ingress` | gateway | NGINX Ingress | Single browser entrypoint. |
| `account` | service | Account Service | Caches account and account-user reads. |
| `position` | service | Position Service | Caches trade and position reads. |
| `tradeProcessor` | service | Trade Processor | Persists trades and invalidates affected caches after commit. |
| `redis` | cache | Redis Cache | Shared, time-bounded read cache. |
| `database` | database | PostgreSQL Database | Authoritative account, trade, and position store. |

## State Notes

- Cache behavior is opt-in and state-local.
- Writes always target PostgreSQL.
- Default cache lifetime is 30 seconds.

