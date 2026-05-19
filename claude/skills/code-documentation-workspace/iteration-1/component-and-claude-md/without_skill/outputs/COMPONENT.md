# Auth Module

Handles authentication and session lifecycle for the application. Issues short-lived JWT access tokens and long-lived refresh tokens, enforces secure password storage, and supports instant token revocation via Redis.

---

## Architecture Overview

```
Client
  │
  ├─ POST /auth/login  ──────────────────────► AuthService.login()
  │                                               │
  │                                        bcrypt.compare(password, hash)
  │                                               │
  │                              ┌────────────────┴───────────────┐
  │                              │                                │
  │                        Issue access token            Issue refresh token
  │                        (JWT, 15 min TTL)             (opaque, 7 day TTL)
  │                                                              │
  │                                                    Store in Redis (TTL = 7d)
  │
  ├─ POST /auth/refresh ─────────────────────► TokenService.rotate()
  │                                               │
  │                                    Lookup refresh token in Redis
  │                                    Delete old token (rotation)
  │                                    Issue new access + refresh tokens
  │
  └─ POST /auth/logout  ─────────────────────► TokenService.revoke()
                                                   │
                                          Delete refresh token from Redis
                                          (access token expires naturally)
```

---

## Token Model

### Access Token

| Property     | Value                        |
|--------------|------------------------------|
| Format       | JWT (signed HS256 or RS256)  |
| TTL          | 15 minutes                   |
| Storage      | Client memory / Authorization header |
| Revocation   | Not supported — expires naturally |

The access token is stateless. Once issued it is valid until expiry. **Do not extend the TTL** — if you need longer sessions, improve the refresh flow, not the access token lifetime.

### Refresh Token

| Property     | Value                               |
|--------------|-------------------------------------|
| Format       | Opaque random token (UUID or crypto bytes) |
| TTL          | 7 days                              |
| Storage      | Redis (key: `refresh:<token>`, value: `userId`) |
| Revocation   | Immediate — delete key from Redis   |

Refresh tokens are rotated on every use: the old token is deleted and a new one is issued atomically. A presented token that is not in Redis is treated as invalid (expired or already rotated). This detects token theft — if an attacker reuses a rotated token, the legitimate user's session is also invalidated.

---

## Password Storage

Passwords are hashed with **bcrypt at cost factor 12**.

- Cost factor 12 was deliberately chosen to make offline brute-force attacks slow.
- A single hash operation takes ~250–400 ms on modern hardware, which is acceptable for login but prohibitive for bulk cracking.
- This value must not be lowered. If you think it is causing a performance problem, profile first — the bottleneck is almost certainly elsewhere.
- When a user changes their password, the new password is hashed with the current cost factor before storage.

---

## Configuration

| Environment Variable | Required | Description |
|----------------------|----------|-------------|
| `JWT_SECRET`         | Yes      | HMAC signing key (min 32 bytes, random) |
| `JWT_ACCESS_TTL`     | No       | Access token TTL in seconds (default: `900`) |
| `JWT_REFRESH_TTL`    | No       | Refresh token TTL in seconds (default: `604800`) |
| `REDIS_URL`          | Yes      | Redis connection string for refresh token store |
| `BCRYPT_COST`        | No       | bcrypt cost factor (default: `12`, do not lower) |

Generate `JWT_SECRET` with: `openssl rand -base64 48`

---

## Endpoints

### `POST /auth/login`

Authenticates a user and issues both tokens.

**Request**
```json
{
  "email": "user@example.com",
  "password": "plaintext-password"
}
```

**Response `200 OK`**
```json
{
  "access_token": "<jwt>",
  "refresh_token": "<opaque-token>",
  "expires_in": 900
}
```

**Error responses**
- `401` — invalid credentials (email not found or password mismatch)
- `429` — rate limit exceeded

### `POST /auth/refresh`

Rotates the refresh token and issues a new access token.

**Request**
```json
{
  "refresh_token": "<opaque-token>"
}
```

**Response `200 OK`**
```json
{
  "access_token": "<new-jwt>",
  "refresh_token": "<new-opaque-token>",
  "expires_in": 900
}
```

**Error responses**
- `401` — token not found in Redis (expired, revoked, or already rotated)

### `POST /auth/logout`

Revokes the refresh token immediately.

**Request**
```json
{
  "refresh_token": "<opaque-token>"
}
```

**Response `204 No Content`**

---

## Security Properties

1. **Short-lived access tokens** limit the blast radius of a leaked JWT. An attacker holding a stolen access token can only use it for up to 15 minutes.
2. **Refresh token rotation** provides forward secrecy for sessions. Each use of a refresh token invalidates the previous one.
3. **Redis-backed revocation** means logout and token theft responses are instant — no waiting for TTL expiry.
4. **bcrypt cost 12** protects the password database. Even if the database is exfiltrated, cracking is computationally expensive.
5. **No refresh token in JWT** — refresh tokens are opaque and server-validated, preventing offline forgery.

---

## Error Handling

All auth errors return a consistent envelope:

```json
{
  "error": "unauthorized",
  "message": "Human-readable description"
}
```

Do not leak whether the email exists or only the password was wrong — always return a generic `invalid credentials` message for login failures.

---

## Testing

- Unit tests: mock `bcrypt`, `jwt`, and the Redis client to isolate business logic.
- Integration tests: use a real Redis instance (test container or in-memory Redis mock).
- Never hardcode real passwords or secrets in test fixtures — use generated values.
- Test the token rotation path: verify the old refresh token is rejected after a successful `/auth/refresh` call.

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `jsonwebtoken` (or equivalent) | JWT signing and verification |
| `bcrypt` | Password hashing |
| `ioredis` / `redis` | Refresh token store |
