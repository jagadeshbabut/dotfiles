# Commentary: Inline Comments Added to `payment-service.ts`

## Comments Added

### `IDEMPOTENCY_TTL = 86400` (line 8)
**Why commented:** `86400` is a magic number. Without a comment, a reader has to convert it in their head to realize it's 24 hours — and even then, they still don't know *why* 24 hours was chosen. The comment explains the business reasoning: it matches the typical window for duplicate charge attempts arriving from network retries or message queue redeliveries.

---

### `RETRY_DELAYS = [1000, 3000, 9000]` (line 10)
**Why commented:** The array looks arbitrary. The comment reveals the exponential back-off intent (1s → 3s → 9s) and explains how the indices map to retry attempts, which is non-obvious from the loop code alone.

---

### `idempotencyKey = charge:${customerId}:${metadata.orderId}` (line 18)
**Why commented:** A new engineer seeing this key pattern might wonder why it's scoped to both customer *and* order (why not just orderId?). The comment explains the multi-instance deduplication intent — critical for understanding why the key is structured the way it is.

---

### Redis cache check (lines 20–23)
**Why commented:** The short-circuit return from cache is a non-obvious architectural decision. Without a comment, a reader might think it's a performance optimization. The comment explains the actual guard: preventing duplicate charges from at-least-once delivery and network retries.

---

### EU currency coercion block (lines 30–33)
**Why commented:** This is the most dangerous block in the file for a new engineer. It silently mutates `currency` and `amount` without any visible signal in the function signature. The comment explains: (1) which regulation drives this, (2) what the caller may have passed that triggers it, and (3) what PSD2 / cross-border error it prevents. Without this comment, a new engineer might treat the silent mutation as a bug and "fix" it.

---

### `if (attempt > 0)` delay skip (line 39)
**Why commented:** The off-by-one relationship between `attempt` and `RETRY_DELAYS` is subtle. `attempt - 1` as the index is easy to misread as a bug. The comment confirms this is intentional: no delay on the first attempt, then back-off kicks in.

---

### `amount: Math.round(amount * 100)` (line 44)
**Why commented:** The `* 100` is a well-known Stripe convention, but `Math.round` is not. A reader might change it to `Math.floor` or remove it, causing subtle off-by-one errors on fractional cent amounts. The comment explains the floating-point risk explicitly.

---

### `off_session: true` (line 49)
**Why commented:** This flag has a non-obvious consequence: it changes how Stripe applies SCA (Strong Customer Authentication) exemptions. Using it incorrectly — or omitting it — causes legitimate off-session charges to fail. The comment explains what "off_session" means in business terms and why the flag is required here.

---

### Per-attempt idempotency key suffix `:attempt:${attempt}` (line 51)
**Why commented:** This is a subtle but critical Stripe interaction. A reader might think using different keys per retry is wrong — surely you want idempotency across retries? The comment explains why the opposite is true: Stripe would replay the failed result if you reused the same key.

---

### `requires_action` / 3DS check (lines 54–56)
**Why commented:** `requires_action` is a Stripe-specific status that a reader unfamiliar with Stripe's payment flow won't recognize. The comment explains the 3DS flow, why it can't be handled server-side, and what the caller is expected to do with the `requires_3ds` error code.

---

### Post-success Redis cache write (lines 59)
**Why commented:** The cache write after success is paired conceptually with the cache read at the top of the function. The comment makes the contract explicit: this is what makes the idempotency system work, and it explains the asymmetry (only cache successes, not failures).

---

### Hard-stop errors `card_declined` / `insufficient_funds` (lines 77–79)
**Why commented:** The `break` on deterministic errors is non-obvious — a reader might expect `continue` or `throw`. The comment explains why retrying these would be harmful (duplicate failed charge notifications to the customer), making the intent clear.

---

### Failed transaction record after the loop (lines 85–94)
**Why commented:** Two non-obvious things happen here: (1) the record is written *outside* the retry loop (after all attempts fail), and (2) it also runs for the hard-stop case, not just exhausted retries. The comment calls out both, preventing a future engineer from "fixing" the placement by moving it inside the loop.

---

### `convertCurrency` function (lines 99–103)
**Why commented:** The function depends on a Redis cache that is populated by a *separate, unrelated process* (an FX rate sync job). There is no visible coupling in this file. Without the comment, a reader has no idea where rates come from, when they might be stale, or why the function throws instead of returning a default. The comment also warns callers not to retry without a cache warm-up.

---

## Lines Deliberately Left Uncommented

| Line(s) | Reason not commented |
|---------|----------------------|
| `import` statements (1–4) | Self-explanatory — standard module imports |
| `const stripe = new Stripe(...)` (6) | Constructor call; the API version pin is standard practice and visible |
| `MAX_RETRY_ATTEMPTS = 3` (9) | The name is fully self-describing |
| `customer = await db.customers.findUnique(...)` (25) | Standard DB lookup, no hidden behavior |
| `!customer?.stripeCustomerId` guard (26–28) | The condition and return are obvious |
| `let lastError: Error \| null = null` (35) | Standard error accumulation pattern |
| `for` loop setup (37) | Standard retry loop structure |
| `logger.warn(...)` (81) | Self-explanatory logging call |
| `sleep` function body (105–107) | One-liner Promise wrapper; the implementation matches the name exactly |
| `currency.toLowerCase()` (45) | Self-explanatory normalization |
| `return result` (72) | Self-explanatory |
| `return { success: false, error: ... }` (96) | Self-explanatory failure return |
