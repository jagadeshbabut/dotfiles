## Auth Module

### Overview

Handles user authentication and session management using JWT with refresh token rotation. The primary security invariant is that access tokens are short-lived (15 minutes) and refresh tokens are stored in Redis for instant revocation — this is the foundation of the session security model.

### Quick Start

```bash
# Login
POST /auth/login
{ "email": "user@example.com", "password": "..." }
→ { "accessToken": "eyJ...", "refreshToken": "eyJ..." }

# Authenticated request
GET /api/resource
Authorization: Bearer <accessToken>

# Refresh when access token expires (401 response)
POST /auth/refresh
{ "refreshToken": "eyJ..." }
→ { "accessToken": "eyJ...", "refreshToken": "eyJ..." }  # old refresh token is now invalid

# Logout
DELETE /auth/session
Authorization: Bearer <accessToken>
{ "refreshToken": "eyJ..." }
```

### Flow

1. `POST /auth/login` — validates credentials (bcrypt verify, cost 12), issues access token (15 min TTL) + refresh token (7-day TTL), stores refresh token in Redis
2. All API requests include `Authorization: Bearer <access_token>` header; middleware validates the JWT signature and expiry
3. On `401`: client calls `POST /auth/refresh` with current refresh token → server validates against Redis, issues new access token + new refresh token, **deletes the old refresh token from Redis immediately** (rotation)
4. `DELETE /auth/session` — deletes refresh token from Redis, invalidating the session instantly regardless of remaining TTL

### Dependencies

| Package | Purpose |
|---------|---------|
| `jsonwebtoken` | JWT signing and verification — RS256 (asymmetric) so the public key can be distributed to other services without exposing signing capability |
| `bcrypt` | Password hashing with cost factor 12 — deliberately slow (~300ms) to make brute-force attacks impractical |
| `redis` | Refresh token store — enables instant revocation on logout; tokens are not just stateless JWTs, Redis is the source of truth for session validity |

### Configuration

| Env Var | Description | Default |
|---------|-------------|---------|
| `JWT_PRIVATE_KEY` | RS256 private key for signing access and refresh tokens | required |
| `JWT_PUBLIC_KEY` | RS256 public key for verification | required |
| `JWT_SECRET` | Legacy — do not use for new tokens; kept for backwards compat during migration | deprecated |
| `ACCESS_TOKEN_EXPIRY` | Access token TTL | `15m` |
| `REFRESH_TOKEN_EXPIRY` | Refresh token TTL | `7d` |
| `REDIS_URL` | Redis connection string for refresh token storage | required |
| `BCRYPT_COST` | bcrypt cost factor — **do not set below 12** | `12` |

### Gotchas

- **Refresh token single-use**: Rotation means each refresh token is valid for exactly one `/auth/refresh` call. If two requests race to refresh (e.g., two tabs open simultaneously), the second will get a `401`. Clients must handle this by retrying with the new token returned by the first response. Do not attempt to "fix" this race by making refresh tokens multi-use — that would reintroduce session hijacking risk.

- **bcrypt cost 12 is intentional**: Login takes ~300ms on purpose. Do not reduce the cost factor to improve perceived performance — this is a brute-force defence. If login latency becomes a product concern, address it with UX (loading states, optimistic navigation) not by weakening the hash.

- **Redis is authoritative for session state**: A valid JWT alone does not mean a session is active. Middleware must check Redis for the refresh token. If Redis is unavailable, fail closed (deny requests) not open.

- **RS256 vs HS256**: The module uses RS256 (asymmetric). Do not switch to HS256 (`JWT_SECRET`) — the asymmetric setup allows other services to verify tokens using the public key without access to the signing key. The `JWT_SECRET` env var is a legacy artefact and should not be referenced in new code.

- **Refresh token storage key format**: Keys in Redis follow the pattern `refresh:<userId>:<tokenId>`. Do not query by userId prefix to enumerate sessions — use the explicit key pattern and handle multi-device via a set at `sessions:<userId>`.
