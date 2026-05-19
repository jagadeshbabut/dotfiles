# Commentary: Inline Comments Added to payment-service.ts

## Comments Added and Why

### Stripe client initialization (line 6)
**What was added:** Explanation of the `!` non-null assertion on the env var, and why the `apiVersion` is pinned.
**Why non-obvious:** New engineers often don't know that Stripe's Node SDK uses the API version to gate behavior, not just for documentation. The `!` is a TypeScript assertion with a real runtime risk — if the env var is missing the failure message comes from deep in the Stripe SDK, not at this line.

### `IDEMPOTENCY_TTL` constant (line 8)
**What was added:** Converts the raw number 86400 to "24 hours" and explains *what* it gates.
**Why non-obvious:** Magic numbers for time durations are never obvious. More importantly, the semantic meaning — that this controls the deduplication window for duplicate charge requests — is invisible from the name alone.

### `RETRY_DELAYS` array (lines 10-11)
**What was added:** Explanation of the back-off pattern, the time values in human-readable units, and the indexing scheme (`attempt - 1`).
**Why non-obvious:** The index offset (`RETRY_DELAYS[attempt - 1]` inside a loop that starts at 0) is a common off-by-one trap. A new engineer reading the loop might think it's a bug. The comment pre-empts that confusion.

### `amount` parameter (line 13)
**What was added:** Documents the expected unit (major currency unit, not cents).
**Why non-obvious:** The function signature says `number` with no unit. The conversion to cents happens inside (`Math.round(amount * 100)`), but callers need to know what to pass. Without this comment, a caller might pass cents and silently charge 100x.

### Idempotency key construction (line 18)
**What was added:** Explains the scope (customer + order) and the guarantee it provides.
**Why non-obvious:** The key's structure encodes an important business rule: one charge per customer per order. The comment clarifies this is intentional deduplication, not just a cache key.

### Redis cache short-circuit (lines 20-23)
**What was added:** Explains that this is the idempotency fast-path for duplicate requests, including the "across process restarts" nuance.
**Why non-obvious:** Without context, this looks like a performance cache. Its real purpose is idempotency correctness — a critical distinction when debugging duplicate payment reports.

### `stripeCustomerId` check (lines 25-28)
**What was added:** Explains why we check for both customer existence AND the Stripe ID, and why we fail fast.
**Why non-obvious:** The optional chaining on `customer?.stripeCustomerId` handles two different failure modes in one expression. New engineers may not realize `customer` itself could be null vs. the field being unset.

### EU currency coercion block (lines 30-33)
**What was added:** Documents the compliance rationale, notes the silent mutation, and flags the caller-visibility gap (caller's currency arg is overwritten).
**Why non-obvious:** This is the most surprising behavior in the file. A caller who passes `USD` for an EU customer gets silently charged `EUR`. Without a comment, this looks like a bug. The regulatory reason ("EU compliance") is completely absent from the code.

### `if (attempt > 0)` sleep guard (lines 39-41)
**What was added:** One-liner explaining why the sleep is skipped on attempt 0.
**Why non-obvious:** The `attempt - 1` index into `RETRY_DELAYS` would be `-1` on the first attempt (producing `undefined`), so the guard is load-bearing, not stylistic. This is easy to miss on code review.

### `amount: Math.round(amount * 100)` (line 44)
**What was added:** Explains Stripe's smallest-unit requirement and why `Math.round` is used (float precision).
**Why non-obvious:** The `* 100` is obvious, but `Math.round` is defensive — without it, `10.99 * 100` produces `1098.9999...` which Stripe would reject or truncate. The comment explains the defensive intent.

### `currency: currency.toLowerCase()` (line 45)
**What was added:** Notes that Stripe requires lowercase ISO 4217 codes.
**Why non-obvious:** This is a Stripe-specific API constraint that isn't obvious from the code itself.

### `confirm: true` and `off_session: true` (lines 48-50)
**What was added:** Explains what each flag does, and specifically what `off_session` signals to Stripe regarding 3DS/SCA handling.
**Why non-obvious:** These two Stripe flags have non-obvious interactions. `off_session: true` tells Stripe not to present a 3DS challenge inline — instead, the `requires_action` status is returned (handled below). Without understanding this, the `requires_3ds` error path below is inexplicable.

### Per-attempt idempotency key (line 51)
**What was added:** Explains why each attempt gets a unique Stripe-level key (to avoid replaying a failed intent).
**Why non-obvious:** Using the same idempotency key across Stripe retries would replay the original failed result rather than create a new attempt. The `:attempt:N` suffix is intentional and critical — it looks like boilerplate but has real correctness implications.

### `requires_action` status check (lines 54-56)
**What was added:** Explains what `requires_action` means in a Stripe payment flow and why we return `requires_3ds` specifically.
**Why non-obvious:** `requires_action` is Stripe's way of signaling a 3DS/SCA challenge. In an off-session context there's no way to complete it inline. The comment connects this status to the `off_session: true` flag above and explains what the caller should do with `requires_3ds`.

### Redis cache write after success (line 59)
**What was added:** Clarifies this is the idempotency store for future duplicate requests.
**Why non-obvious:** This is a symmetrical write to the read on line 20. Without the comment it looks like generic caching.

### DB transaction write after success (lines 61-70)
**What was added:** Flags the lack of a distributed transaction and the race condition: Stripe charge succeeds, but the DB write could fail.
**Why non-obvious:** This is a subtle operational risk. A new engineer might assume "if `chargeCustomer` returns success, there's a DB record." That's not guaranteed. The comment surfaces this so they don't build reporting that relies on DB completeness.

### Terminal error break (lines 77-79)
**What was added:** Explains why `card_declined` and `insufficient_funds` skip remaining retries, and mentions the Stripe fraud signal risk.
**Why non-obvious:** The `break` inside the `catch` is easy to miss. More importantly, the *reason* for breaking (retrying won't help AND could trigger fraud flags) is business knowledge, not code knowledge.

### Failed transaction write (lines 85-94)
**What was added:** Explains this is the authoritative failure record, written both after exhausted retries AND after a terminal break, and notes no Stripe ID is available.
**Why non-obvious:** This write is outside the loop, which means it runs in both the "retry exhausted" and "terminal break" cases. New engineers might wonder why there's no try/catch here or why there's no Stripe ID.

### `convertCurrency` function (lines 99-103)
**What was added:** Documents the Redis key format, explains that the rate is NOT fetched live (must be pre-populated), and explains why we throw rather than use a default.
**Why non-obvious:** The function looks like it converts currency, but it's entirely dependent on an external process having populated the Redis key. If that job fails or the key expires, charges fail. The "no live fetch" behavior is a major operational dependency invisible from the code.

---

## Lines Deliberately Left Uncommented

The following lines are self-explanatory from standard TypeScript/JS knowledge and do not need comments:

| Line(s) | Reason not commented |
|---------|----------------------|
| `import` statements (1-4) | Standard imports; names are clear (`stripe`, `db`, `redis`, `logger`) |
| `const stripe = new Stripe(...)` — the instantiation itself | Obvious; commented only the non-obvious parts (env var assertion, apiVersion) |
| `MAX_RETRY_ATTEMPTS = 3` | Name + value are self-documenting |
| `customer = await db.customers.findUnique(...)` | Standard ORM query pattern |
| `let lastError: Error | null = null` | Standard retry pattern variable initialization |
| `for (let attempt = 0; ...)` loop structure | Standard for-loop |
| `lastError = error` | Obvious assignment inside catch |
| `logger.warn(...)` call | Logger calls with descriptive messages don't need explanation |
| `const result = { success: true, chargeId: paymentIntent.id }` | Shape is clear |
| `return result` / `return { success: false, error: ... }` | Return statements are obvious |
| `sleep` function body | `setTimeout` wrapped in a Promise is a well-known JS pattern |
| `return amount * parseFloat(rate)` | Arithmetic is obvious given context |
