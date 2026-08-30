# Implementation Plan: Redis Database Cache

## Scope

- Branch from `005-postgres-database-replacement`.
- Add opt-in cache-aside behavior to PostgreSQL-backed services.
- Add a shared Redis runtime resource and Radius relationship.

## Design

- Account and position query services populate named caches on reads.
- Account writes refresh item caches and invalidate collection caches.
- Trade processing invalidates account-scoped trade and position caches through a transaction-aware cache manager.
- Cache configuration is disabled by default and enabled by state-local runtime configuration.

## Exit Criteria

- State generation produces Redis-enabled services and compose wiring.
- Service tests compile and pass.
- The Radius model compiles and renders Redis and consumer relationships.
- Root SpecKit quality gates pass.
