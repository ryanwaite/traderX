# Data Model: Redis Database Cache

State 016 does not change the authoritative PostgreSQL schema. It introduces derived, time-bounded cache entries.

## Cache Entry

| Field | Description | Validation |
|---|---|---|
| Cache name | Identifies the query family | One of the state-defined cache names |
| Key | Identifies the query scope | Empty query key or a valid account/entity identifier |
| Value | Serialized query result | Must represent the same contract returned by the backing service |
| Lifetime | Maximum retained duration | Defaults to 30 seconds and must be positive |

## Cache Names

| Cache | Key | Value |
|---|---|---|
| `accounts` | Empty query key | Account list |
| `accountById` | Account ID | Account |
| `accountUsers` | Empty query key | Account-user list |
| `accountUserById` | Account-user ID | Account user |
| `positions` | Empty query key | Position list |
| `positionsByAccount` | Account ID | Position list |
| `trades` | Empty query key | Trade list |
| `tradesByAccount` | Account ID | Trade list |

## Relationships

- Every cache entry is derived from one or more authoritative PostgreSQL records.
- Account writes refresh `accountById` and invalidate `accounts`.
- Account-user writes refresh `accountUserById` and invalidate `accountUsers`.
- Successful trade commits invalidate global and account-scoped trade and position entries.

## Lifecycle

1. A cache miss reads authoritative data and stores the returned value.
2. Repeated reads return the cached value until it is invalidated or expires.
3. Successful writes refresh or invalidate affected entries.
4. Rolled-back writes leave existing entries unchanged.
5. Expired entries are removed and repopulated by the next read.
