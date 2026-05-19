---
type: ai-context
module: auth
owner: platform-team
last-updated: 2026-05-15
stability: stable
---

# Auth Module

## Purpose

This module owns all authentication and session lifecycle: login, token issuance, token refresh, and logout. It is a security-critical module — changes here affect the entire system's session security model. It exists as a separate module to enforce a clear trust boundary: nothing outside this module should issue or validate tokens.

## Key Decisions

- **JWT with refresh token rotation (not long-lived access tokens)**: Access tokens expire in 15 minutes to limit the blast radius of a leaked token. Refresh tokens rotate on every use — once a refresh token is consumed, it is deleted from Redis and a new one is issued. This means stolen tokens are detectable (a legitimate client will get a 401 when the attacker uses the token first). Do not change to long-lived access tokens or non-rotating refresh tokens without a formal security review.

- **Redis for refresh token storage (not database)**: Refresh tokens are stored in Redis — not the SQL database — because revocation must be instant. On logout or forced sign-out, the token is deleted; there is no polling or TTL-based grace period. If Redis is unavailable, the system must fail closed (deny requests). Do not route around Redis with a database fallback — that would delay revocation.

- **bcrypt cost factor 12**: Password hashing uses bcrypt at cost 12. At current hardware this produces ~300ms hash times, which is the intended brute-force deterrent. The cost was explicitly chosen after benchmarking. Do not lower it. If you need to benchmark or test, use a test-only flag that mocks bcrypt — do not change the production cost factor.

- **RS256 (asymmetric JWT signing)**: Tokens are signed with a private key and can be verified with the public key. This allows other services to verify tokens independently without access to the signing secret. Do not switch to HS256 (symmetric, `JWT_SECRET`) — it would require sharing the signing secret with every consuming service.

## What NOT to Change Without Discussion

- **bcrypt cost factor**: Hard-coded at 12. Do not accept a PR that lowers this, parameterises it to a lower default, or bypasses it in any non-test path. If you see `bcrypt.hash(password, rounds)` where `rounds < 12`, that is a bug.

- **Refresh token rotation**: The single-use constraint on refresh tokens is load-bearing for the security model. Do not add caching, retry-safe multi-use tokens, or grace windows without a security review. The correct fix for refresh races is client-side retry logic.

- **Redis as session source of truth**: JWT validity alone is not sufficient to authorise a request. The middleware must verify the refresh token exists in Redis. Do not add a bypass path (e.g., "if Redis is slow, skip the check") — that defeats revocation.

- **RS256 key pair**: The `JWT_PRIVATE_KEY` / `JWT_PUBLIC_KEY` pair must stay asymmetric. The legacy `JWT_SECRET` env var exists only for backwards compatibility during migration and must not be used for new token issuance or verification.

## Entry Points

- `auth/login.ts:loginHandler` — POST `/auth/login`; validates credentials, issues access + refresh tokens
- `auth/refresh.ts:refreshHandler` — POST `/auth/refresh`; validates refresh token in Redis, rotates token pair
- `auth/logout.ts:logoutHandler` — DELETE `/auth/session`; deletes refresh token from Redis
- `auth/middleware.ts:requireAuth` — Express middleware; validates access token JWT signature + expiry on every protected route

## Data Flow

```
Client
  │
  ├─ POST /auth/login ──► loginHandler
  │                          ├─ bcrypt.verify(password, hash)  [~300ms, intentional]
  │                          ├─ sign accessToken (RS256, 15m)
  │                          ├─ sign refreshToken (RS256, 7d)
  │                          ├─ Redis SET refresh:<userId>:<tokenId>  TTL=7d
  │                          └─ return { accessToken, refreshToken }
  │
  ├─ GET /api/* ──────────► requireAuth middleware
  │                          ├─ verify JWT signature (RS256 public key)
  │                          ├─ check exp claim
  │                          └─ attach req.user, call next()
  │
  ├─ POST /auth/refresh ──► refreshHandler
  │                          ├─ verify refreshToken JWT signature
  │                          ├─ Redis GET refresh:<userId>:<tokenId>  [must exist]
  │                          ├─ Redis DEL refresh:<userId>:<tokenId>  [rotate: invalidate old]
  │                          ├─ sign new accessToken + new refreshToken
  │                          ├─ Redis SET refresh:<userId>:<newTokenId>  TTL=7d
  │                          └─ return { accessToken, refreshToken }
  │
  └─ DELETE /auth/session ► logoutHandler
                             ├─ Redis DEL refresh:<userId>:<tokenId>
                             └─ 204 No Content
```

## Dependencies & Why

- `jsonwebtoken`: RS256 signing/verification. Asymmetric so the public key can be shared with downstream services safely.
- `bcrypt`: Password hashing. Cost factor 12 chosen for ~300ms brute-force resistance on current hardware. Do not substitute with argon2 or scrypt without migrating all existing password hashes.
- `redis` (ioredis): Refresh token store. Fast enough for synchronous middleware checks. The module depends on Redis being available — it does not implement a fallback store.

## Common Pitfalls for AI Agents

- **Do not treat a valid JWT as sufficient for authorisation.** The middleware must also verify the refresh token exists in Redis. A JWT can be cryptographically valid but the session revoked (e.g., after logout or forced sign-out by an admin).

- **Do not lower bcrypt cost.** If you see slow test runs caused by bcrypt, the correct fix is to mock bcrypt in tests (e.g., `jest.mock('bcrypt')`), not to change the cost factor. Lowering the cost is a security regression.

- **Refresh tokens are single-use.** Do not add retry logic inside the module that reuses a refresh token after it has been consumed. The client is responsible for retrying with the new token.

- **`JWT_SECRET` is legacy.** Do not use it for any new functionality. It remains in the codebase to support tokens issued before the RS256 migration. New code should only reference `JWT_PRIVATE_KEY` / `JWT_PUBLIC_KEY`.

- **Redis key namespace matters.** Refresh tokens are stored at `refresh:<userId>:<tokenId>`. Do not use a wildcard scan on `refresh:<userId>:*` to enumerate sessions in the hot path — use the explicit `sessions:<userId>` set for multi-device session listing.

- **The 15-minute access token TTL is a product constraint, not an accident.** If a feature requires knowing session state for longer than 15 minutes without a re-auth, the correct solution is to call `/auth/refresh`, not to extend the access token TTL.
