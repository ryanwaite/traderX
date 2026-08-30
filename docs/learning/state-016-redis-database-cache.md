---
title: "State 016: Redis Database Cache"
---

# State 016 Learning Guide

## Position In Learning Graph

- Previous state(s): [005-postgres-database-replacement](/docs/learning/state-005-postgres-database-replacement)
- Dotted-line parent(s): none
- Next state(s): none

## Convergence Metadata

- Convergence state: `no`
- Convergence level: `none`
- Lineage role: `canonical`
- Nearest previous convergence: `none`
- Nearest next convergence: `none`

## Rendered Code

- Generated branch: [code/generated-state-016-redis-database-cache](https://github.com/finos/traderX/tree/code/generated-state-016-redis-database-cache)
- Authoring branch (spec source): [main](https://github.com/finos/traderX/tree/main)

## Code Comparison With Previous State

- Compare against `005-postgres-database-replacement`: [code/generated-state-005-postgres-database-replacement...code/generated-state-016-redis-database-cache](https://github.com/finos/traderX/compare/code%2Fgenerated-state-005-postgres-database-replacement...code%2Fgenerated-state-016-redis-database-cache)

## Plain-English Code Delta

- **Functional intent:** The system MUST cache repeated account, account-user, trade, and position reads.
- **Functional intent:** PostgreSQL MUST remain the source of truth for all writes.
- **Functional intent:** The system MUST invalidate or refresh affected entries after a successful write.
- **Functional intent:** Cache changes caused by a transactional write MUST occur only after that transaction commits.

## Run This State

```bash
./scripts/start-state-016-redis-database-cache-generated.sh
```

## Canonical Spec Links

- State spec pack: [/specs/redis-database-cache](/specs/redis-database-cache)
- Architecture: [/specs/redis-database-cache/system/architecture](/specs/redis-database-cache/system/architecture)
- Flows / topology: [/specs/redis-database-cache/system/system-context](/specs/redis-database-cache/system/system-context)
- Research: [link](/specs/redis-database-cache/research)
- Data model: [link](/specs/redis-database-cache/data-model)
- Quickstart: [link](/specs/redis-database-cache/quickstart)

