# Feature Specification: Redis Database Cache

**Feature Branch**: `016-redis-database-cache`  
**Created**: 2026-08-30  
**Status**: Implemented  
**Input**: Add a cache in front of PostgreSQL to scale database reads while preserving reliable writes.

## User Scenarios & Testing

### User Story 1 - Faster repeated portfolio reads (Priority: P1)

As a trader, I want repeated account, trade, and position reads to remain responsive as usage grows.

**Why this priority**: Read-heavy portfolio workflows are the primary scaling pressure.

**Independent Test**: Repeat the same account, trade, and position requests and verify the responses remain equivalent while subsequent reads avoid the primary data store.

**Acceptance Scenarios**:

1. **Given** an uncached account query, **When** it is requested twice, **Then** both responses match and the second request is served from the cache.
2. **Given** cached trade and position queries, **When** another client requests the same account data, **Then** it receives the cached results.

---

### User Story 2 - Consistent data after writes (Priority: P1)

As a trader, I want completed trades and account updates to appear in later reads without stale cached results.

**Why this priority**: Scaling cannot compromise portfolio correctness.

**Independent Test**: Prime relevant caches, perform a successful write, and verify the next read returns the newly committed data.

**Acceptance Scenarios**:

1. **Given** a cached account, **When** that account is updated successfully, **Then** the account list cache is invalidated and the item cache contains the updated account.
2. **Given** cached trades and positions, **When** a trade commits successfully, **Then** caches for that account are invalidated only after the write succeeds.
3. **Given** a failed write, **When** the transaction rolls back, **Then** existing cache entries are not invalidated as though the write succeeded.

### Edge Cases

- Cached entries expire after a bounded interval so missed invalidations cannot remain indefinitely.
- Empty query results are cached, but null values are not.
- Cache keys include the query scope so one account cannot receive another account's data.

## Requirements

### Functional Requirements

- **FR-001**: The system MUST cache repeated account, account-user, trade, and position reads.
- **FR-002**: PostgreSQL MUST remain the source of truth for all writes.
- **FR-003**: The system MUST invalidate or refresh affected entries after a successful write.
- **FR-004**: Cache changes caused by a transactional write MUST occur only after that transaction commits.
- **FR-005**: Cached data MUST expire within 30 seconds by default.
- **FR-006**: Earlier generated states MUST retain their existing behavior unless caching is explicitly enabled.
- **FR-007**: The generated runtime and application model MUST declare the cache and wire every cache consumer to it.

### Key Entities

- **Cache Entry**: A time-bounded representation of an account, account user, trade list, or position list keyed by its query scope.
- **Database Record**: The authoritative persisted account, account-user, trade, or position data.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A repeated unchanged read returns an equivalent result without a second authoritative-store query.
- **SC-002**: The first read after a successful write returns the committed value in 100% of functional test runs.
- **SC-003**: A failed write causes zero cache invalidations in transactional tests.
- **SC-004**: Any stale entry expires within 30 seconds under the default configuration.

## Assumptions

- Workloads are read-heavy; cache-aside improves reads but does not increase PostgreSQL write capacity.
- A 30-second default lifetime provides a bounded recovery window while explicit invalidation provides normal consistency.
- Cache credentials and transport security are supplied by the target environment.
