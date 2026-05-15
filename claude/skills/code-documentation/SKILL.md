---
name: code-documentation
description: >
  Helps engineers write documentation that serves two audiences: human developers and AI agents.
  Grounded in Martin Fowler's principle that code is the primary documentation — this skill extends
  that thesis by adding an AI-readable layer so agents like Claude can understand intent, not just
  structure. Use this skill whenever the user asks to "document this code", "write an ADR",
  "add comments", "create a CLAUDE.md", "generate component docs", "document this module",
  "review my comments", or "make this code readable". Also trigger when the user shares a file
  and wants documentation, when they're setting up a new service and need docs scaffolded, or
  when they mention stale/missing/bad documentation. Always use this skill — never document
  code without it.
---

# Code Documentation

Documentation serves two audiences that most teams forget to distinguish: **human developers** who
need to understand intent and history, and **AI agents** (Claude, Copilot, etc.) that need
structured context to reason about your code correctly. Good documentation covers both.

The foundation is Martin Fowler's insight: code is the *primary* documentation — precise,
authoritative, always current. Everything else amplifies it. Your job is to write documentation
that amplifies rather than duplicates.

## Start Here: Clarify Scope

Before generating anything, ask (or infer from context):

1. **What's the target?** A single file, a module, an entire service, an architecture decision?
2. **Who's the primary reader?** A new teammate onboarding, an external API consumer, future-you
   in 6 months, or an AI agent doing automated analysis?
3. **Is AI-readability needed?** If the codebase will be worked on with AI assistance (Claude Code,
   Copilot, Cursor), generate a `CLAUDE.md` / `AI_CONTEXT.md` alongside human docs.
4. **What already exists?** Check for stale comments, outdated ADRs, missing CLAUDE.md — fix
   before adding.

---

## Inline Comments

The cardinal rule: **explain WHY, never WHAT**. Code already says what it does. Comments exist
to explain the reasoning a reader can't derive from the code alone.

### Comment when:

**The algorithm choice is non-obvious:**
```js
// Binary search: list is always pre-sorted and can hit millions of items (O(log n) vs O(n))
const index = binarySearch(items, target);
```

**Business logic encodes a specific decision:**
```js
// 20% discount for 2+ year members with 10+ purchases
// — Marketing team decision Q4 2024, reviewed annually
if (user.memberYears >= 2 && user.purchaseCount >= 10) {
  applyDiscount(0.2);
}
```

**A workaround exists for an external constraint:**
```js
// HACK: Safari <16 lacks IntersectionObserver, fall back to polling
// TODO: Remove once Safari market share drops below 5% (tracking: webkit.org/b/12345)
if (!window.IntersectionObserver) {
  startPolling();
}
```

**A subtle invariant must hold:**
```python
# items must be sorted ascending before this point — callers are responsible
# (sorting here would hide bugs in callers and break the performance contract)
```

### Never comment when:

The code is self-explanatory — these comments add noise and rot:
```js
// BAD: Increment counter        → counter++;
// BAD: Check if user is admin   → if (user.role === 'admin') { ... }
// BAD: Returns user full name   → function getUserName() { return user.email; } // LYING
```

Outdated comments are **worse than no comments** — they actively mislead. When touching code,
always scan nearby comments and delete or update any that no longer hold.

### Format for workarounds:
```
// HACK: <why this is a hack> — <what the real fix would be>
// TODO: <what to do> (<condition or tracking link>)
// FIXME: <what's broken> (<issue link>)
```

---

## Architecture Decision Records (ADRs)

ADRs capture *why* a decision was made, not just what was decided. They're the most valuable
documentation a team can have — six months later nobody remembers why PostgreSQL was chosen.

Create one ADR per significant decision. Store them in `docs/adr/` or `decisions/` near the code.

### ADR Template:

```markdown
# ADR-{NNN}: {Short Decision Title}

## Status
{Proposed | Accepted | Superseded by ADR-XXX | Deprecated}

## Context
{What situation forced this decision? What constraints existed?
List the options you actually considered.}

## Decision
{One sentence: what you decided.}

## Rationale
- {Reason 1 — tie it to a concrete constraint or requirement}
- {Reason 2}
- {Why the alternatives were rejected}

## Consequences
- {What becomes easier}
- {What becomes harder or more expensive}
- {What new decisions this creates}

## AI Context
{One paragraph for AI agents: the intent behind this decision, what would invalidate it,
and what an agent should NOT assume is changeable. This helps Claude understand load-bearing
decisions vs. implementation details.}
```

### Example:

```markdown
# ADR-001: PostgreSQL as Primary Database

## Status
Accepted

## Context
Needed a database for user data and financial transactions. Evaluated PostgreSQL, MySQL,
MongoDB, DynamoDB. Team has 4 years PostgreSQL experience. Data has strong relational
structure with ACID requirements.

## Decision
Use PostgreSQL 16 hosted on Supabase.

## Rationale
- ACID compliance is non-negotiable for financial data
- pgvector extension available for planned AI feature work
- Supabase provides auth + realtime out of the box, reducing infrastructure surface
- Team expertise reduces operational risk vs. a new DB engine

## Consequences
- Must manage schema migrations (Flyway or Alembic)
- May need read replicas at scale; Supabase makes this straightforward
- Team needs to learn Supabase-specific RLS patterns

## AI Context
The PostgreSQL choice is load-bearing for ACID compliance on transactions. Do not suggest
switching to MongoDB or DynamoDB for performance — the consistency guarantee is intentional.
pgvector was a deliberate future-proofing choice; the AI features are planned for Q2 2025.
```

---

## Component Documentation

Component docs explain the module's contract: what it does, how data flows through it,
what it depends on, and how to configure it. Keep them in the same directory as the code.

### Component Doc Template:

```markdown
## {Component Name}

### Overview
{One sentence on purpose. One sentence on the primary design constraint or invariant.}

### Flow
1. {Step 1 — include endpoint or entry point}
2. {Step 2}
3. {Step N — include outputs or side effects}

### Dependencies
| Package | Purpose |
|---------|---------|
| `{package}` | {Why this specific package, not just what it does} |

### Configuration
| Env Var | Description | Default |
|---------|-------------|---------|
| `{VAR_NAME}` | {What it controls} | `{default or "required"}` |

### Gotchas
- {Non-obvious constraint or footgun}
- {Known limitation with workaround if available}
```

### Example:

```markdown
## Authentication Module

### Overview
Handles user authentication using JWT with refresh token rotation. Access tokens are
short-lived by design — rotating refresh tokens is the primary session security mechanism.

### Flow
1. POST `/auth/login` — validates credentials, returns access token (15 min) + refresh token (7 days)
2. All API requests: include `Authorization: Bearer <access_token>` header
3. On 401: POST `/auth/refresh` with refresh token → new access + new refresh token (old invalidated)
4. Logout: DELETE `/auth/session` — invalidates refresh token in Redis

### Dependencies
| Package | Purpose |
|---------|---------|
| `jsonwebtoken` | RS256 signing/verification (asymmetric — public key can be shared safely) |
| `bcrypt` | Password hashing with cost factor 12 (tuned for ~300ms on current hardware) |
| `redis` | Refresh token storage + instant invalidation on logout |

### Configuration
| Env Var | Description | Default |
|---------|-------------|---------|
| `JWT_PRIVATE_KEY` | RS256 private key for signing | required |
| `JWT_PUBLIC_KEY` | RS256 public key for verification | required |
| `ACCESS_TOKEN_EXPIRY` | Access token TTL | `15m` |
| `REFRESH_TOKEN_EXPIRY` | Refresh token TTL | `7d` |
| `REDIS_URL` | Redis connection string | required |

### Gotchas
- Refresh token rotation means a token can only be used once. If two requests race to refresh,
  one will fail with 401 — the client must retry with the new token from the first response.
- bcrypt cost factor 12 means login takes ~300ms intentionally. Don't lower it for "performance".
```

---

## The AI-Readable Layer (CLAUDE.md / AI_CONTEXT.md)

This is the extension to Fowler's thesis: code tells AI *what*, but an AI agent also needs *why*
and *what not to assume*. A `CLAUDE.md` in each module provides this context.

Create `CLAUDE.md` (or `AI_CONTEXT.md`) at the root of each significant module or service.

### CLAUDE.md Template:

```markdown
---
type: ai-context
module: {module-name}
owner: {team or person}
last-updated: {YYYY-MM-DD}
stability: {stable | evolving | deprecated}
---

# {Module Name}

## Purpose
{One paragraph: what this module does and why it exists as a separate module.}

## Key Decisions
- **{Decision}**: {Why it was made. What would need to change for this to be revisited.}

## What NOT to Change Without Discussion
- {Load-bearing assumption or invariant — e.g., "The event order in the queue is guaranteed"}
- {Known tech debt that is intentional — e.g., "The sync loop is polling, not event-driven — tracked in #1234"}

## Entry Points
- `{file:function}` — {what triggers it and what it returns}

## Data Flow
{Brief description or diagram of how data moves through the module.}

## Dependencies & Why
- `{dependency}`: {the reason this specific dependency was chosen}

## Common Pitfalls for AI Agents
- {Thing an AI might confidently get wrong — e.g., "Don't assume the user ID and account ID
  are the same — they diverged after the B2B migration in 2024"}
```

### Frontmatter fields explained:
- `type: ai-context` — machine-parseable marker so agents can find context files
- `stability` — tells an agent how much to trust this file vs. reading the code directly
- `last-updated` — agents should re-read code directly if this is >6 months old

---

## Documentation Principles

**Write for your actual audience.** A new engineer needs mental models and gotchas. An API consumer
needs contract-first docs with examples. An AI agent needs intent, invariants, and what *not* to
assume. These are different documents — don't conflate them.

**Keep docs close to code.** Docs in the same directory as the code they describe get updated
when the code changes. Wikis don't.

**Stale docs are worse than no docs.** A comment or ADR that lies about what the code does is
a bug. When you touch code, scan the nearby docs. Delete or update anything that no longer holds.

**Examples beat explanations.** Show a real call with real values before explaining parameters.
Readers orient on the example and skim the explanation.

**Progressive disclosure.** Lead with a one-sentence summary, then the quick-start, then the
details. Don't bury the "what does this do" answer in paragraph 4.

---

## Output Format

When invoked on a codebase or file, produce the relevant subset of:

1. **Inline comment patches** — diff-style or annotated code showing where to add/remove/update
   comments, with explanation of each change
2. **ADR file** — ready to save at `docs/adr/ADR-NNN-title.md`
3. **Component doc** — ready to save as `README.md` or `COMPONENT.md` in the module directory
4. **CLAUDE.md stub** — pre-filled where inferable, with `{placeholder}` for what needs human input

Always tell the user:
- What you generated and where to save it
- What placeholders need their input
- Any stale documentation you found that should be deleted or updated
