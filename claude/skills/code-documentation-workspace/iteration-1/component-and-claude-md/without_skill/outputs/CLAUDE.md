# CLAUDE.md — Auth Module

This file gives AI agents the context needed to work safely on this module. Read it before making any changes.

---

## What This Module Does

Handles user authentication and session management. Issues JWT access tokens (15 min) and opaque refresh tokens (7 days). Stores refresh tokens in Redis for instant revocation. Passwords are hashed with bcrypt.

---

## Security Model — Read Before Changing Anything

### Access Tokens
- JWT, 15-minute TTL. Stateless — not stored server-side.
- Revocation is not supported. If revocation is needed, that is a deliberate architectural constraint: the 15-minute TTL limits exposure.
- **Do not extend the TTL.** If sessions feel too short, fix the refresh flow.

### Refresh Tokens
- Opaque random bytes, 7-day TTL, stored in Redis at key `refresh:<token>`.
- **Rotation is mandatory.** On every `/auth/refresh` call: delete the old token, issue a new one. Both operations happen atomically.
- A refresh token not found in Redis is always rejected (expired, revoked, or already rotated).
- Logout = delete the refresh token from Redis. The access token expires on its own within 15 minutes.
- This rotation scheme detects token theft. If you change it, you break that security property.

### bcrypt Cost Factor
- Cost factor is **12**. This is intentional and must not be lowered.
- It makes offline brute-force attacks against a stolen password database slow.
- If you see slow login times and think "just lower the cost", stop. Profile the full request first — the cost is almost always not bcrypt.
- If the application genuinely needs faster hashing (e.g., for bulk import), use a separate code path that does not involve the login flow.

---

## Things You Must Not Do

- Do not lower the bcrypt cost factor.
- Do not extend the access token TTL beyond 15 minutes without an explicit security review.
- Do not store access tokens server-side — they are designed to be stateless.
- Do not skip refresh token rotation on `/auth/refresh`. Issuing a new token without deleting the old one breaks the revocation model.
- Do not return different error messages for "email not found" vs "password wrong" — this leaks user enumeration.
- Do not log passwords, tokens, or JWT payloads.
- Do not commit `JWT_SECRET` or any credential to source control.

---

## Things That Are Safe To Do

- Add claims to the JWT payload (user roles, feature flags) — keep it small, it is transmitted on every request.
- Add endpoints that use the existing token verification middleware.
- Extend the Redis key schema (e.g., store device metadata alongside the refresh token).
- Change the token format from opaque to structured — as long as it remains server-validated against Redis.
- Increase the bcrypt cost factor (e.g., 13 or 14 if hardware warrants it).

---

## Key Invariants

1. Every valid refresh token has exactly one entry in Redis.
2. After a successful `/auth/refresh`, the presented token no longer exists in Redis.
3. After `/auth/logout`, the refresh token no longer exists in Redis.
4. bcrypt cost is always >= 12 for user passwords.
5. Login failures always return the same error shape regardless of whether the email exists.

---

## Environment Variables

| Variable        | Required | Notes |
|-----------------|----------|-------|
| `JWT_SECRET`    | Yes      | Min 32 random bytes. Rotate by re-deploying (old tokens expire naturally). |
| `REDIS_URL`     | Yes      | Used only for refresh token storage. |
| `BCRYPT_COST`   | No       | Defaults to 12. Never set below 12. |
| `JWT_ACCESS_TTL`| No       | Defaults to 900 (15 min). Do not increase. |
| `JWT_REFRESH_TTL`| No      | Defaults to 604800 (7 days). |

---

## File Map

```
auth/
  login.ts          — credential validation, token issuance
  refresh.ts        — token rotation logic
  logout.ts         — token revocation
  middleware.ts     — access token verification for protected routes
  token.service.ts  — JWT sign/verify, refresh token CRUD in Redis
  password.service.ts — bcrypt hash and compare
  auth.types.ts     — shared types (TokenPair, JwtPayload, etc.)
```

---

## Common Tasks

**Add a claim to the JWT payload**
Edit `token.service.ts` where the token is signed. Keep payload small — prefer IDs over full objects.

**Add a protected route**
Apply `middleware.ts` auth middleware. Do not re-implement token verification inline.

**Force-logout a user (revoke all sessions)**
Delete all Redis keys matching `refresh:*` for that user. You will need to store a secondary index (e.g., `user_sessions:<userId>`) if the current schema does not support this — add it before assuming you can do it.

**Change password**
Hash the new password with `password.service.ts` at the current cost factor. Optionally revoke all existing refresh tokens.

---

## Testing Notes

- Mock `bcrypt`, `jsonwebtoken`, and the Redis client in unit tests.
- For rotation tests: assert that the old refresh token is rejected after a successful refresh call.
- For revocation tests: assert that a logged-out refresh token is rejected.
- Never use real secrets in tests. Use `test-secret-not-for-production` or generated values.
