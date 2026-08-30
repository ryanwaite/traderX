# Research: Redis Database Cache

## Cache interaction pattern

- **Decision**: Use cache-aside reads while PostgreSQL remains authoritative.
- **Rationale**: Existing repository and service contracts remain unchanged, and cache failures cannot become accepted writes.
- **Alternatives considered**: Write-through caching was rejected because it would make the cache part of the write path. Read-through infrastructure was rejected because it would require a broader persistence abstraction change.

## Consistency after writes

- **Decision**: Refresh item caches or invalidate affected collection caches after successful writes; defer transactional invalidations until commit.
- **Rationale**: Readers must not observe a cache state that represents a database transaction that later rolls back.
- **Alternatives considered**: Pre-write eviction creates stale windows on rollback. TTL-only consistency leaves known stale values available unnecessarily.

## Cache lifetime

- **Decision**: Expire entries after 30 seconds by default and allow runtime override.
- **Rationale**: Explicit invalidation supplies normal consistency while a bounded lifetime limits the impact of missed invalidations.
- **Alternatives considered**: Non-expiring entries were rejected because they amplify invalidation defects. Very short lifetimes reduce cache value under repeated reads.

## Compatibility

- **Decision**: Keep caching disabled in shared templates and enable it only in state 016 runtime configuration.
- **Rationale**: Earlier states must preserve their existing runtime behavior and must not require Redis.
- **Alternatives considered**: Enabling caching globally would make Redis an undeclared dependency of earlier states.

## Runtime and deployment

- **Decision**: Use an unauthenticated local Redis container for compose and managed secret-backed credentials with encrypted transport in cloud environments.
- **Rationale**: Local development remains simple while deployed credentials and transport follow the target environment's security boundary.
- **Alternatives considered**: Embedding shared credentials in generated configuration was rejected.
