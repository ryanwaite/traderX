# Cache Behavior Contract

## Read contract

- Account, account-user, trade, and position response schemas remain unchanged.
- A cache miss reads PostgreSQL and stores the successful response.
- A cache hit returns a value equivalent to the authoritative response.
- Cache keys include the query scope.

## Write contract

- PostgreSQL remains the only authoritative write target.
- A successful account or account-user write refreshes its item entry and invalidates the corresponding collection entry.
- A successful trade transaction invalidates global and account-scoped trade and position entries.
- A rolled-back transaction does not publish cache invalidations.

## Runtime contract

- Caching is disabled unless `CACHE_ENABLED=true`.
- `CACHE_TTL` defaults to `30s`.
- Redis connection settings are supplied through `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`, and `REDIS_SSL`.
