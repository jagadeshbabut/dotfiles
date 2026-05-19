---
name: feature-backlog-researcher
description: >
  Researches competitor or inspiration websites, extracts their product features,
  and appends relevant backlog items to an existing developer portal backlog file
  in a standard BL-XXX numbered format. Use this skill whenever the user provides
  a product URL or name and asks to research it, incorporate its features, add it
  to a backlog, or "do the same exercise" for a new product. Also triggers when
  the user says things like "let's look at [site]", "what features does [product]
  have that we should build", or "add this to our backlog". Always use this skill
  when a URL is shared alongside a backlog or feature list context.
---

# Feature Backlog Researcher

You help product and engineering teams build developer experience portal backlogs by researching real products, extracting their core features, and appending well-structured backlog items to an existing file.

## What This Skill Does

Given one or more product URLs, you:
1. Research the product's features thoroughly using web search (and WebFetch if accessible)
2. Filter down to core, developer-facing features — stripping enterprise/compliance noise
3. Read the existing backlog file to understand current numbering and avoid duplication
4. Append new sections in the standard BL-XXX format

## Step-by-Step Process

### Step 1 — Research the Product

For each URL provided:
- Try `WebFetch` first. If blocked, use `WebSearch` with 2–3 targeted queries to get comprehensive coverage. Good query patterns:
  - `[product name] features capabilities product overview [year]`
  - `[product name] integrations developer tools how it works`
  - `[product name] platform [specific area: e.g. monitoring, alerts, code quality]`
- Run searches in parallel when possible to cover breadth efficiently.
- Aim to understand: core product categories, specific features per category, integrations, and the problem space the product addresses.

### Step 2 — Filter: Keep Core, Drop Enterprise

Before writing any backlog items, mentally sort each feature into "keep" or "drop":

**Keep — core, developer-facing features:**
- Features an individual engineering team or small org would use daily
- Developer tooling, integrations, automation workflows
- Observability, alerting, debugging, code quality capabilities
- Collaboration tools, bots, and dashboards that benefit engineers directly
- Onboarding flows and self-serve configuration

**Drop — enterprise/overhead features (unless user explicitly asks):**
- SSO, SAML/OIDC, 2FA enforcement
- RBAC and fine-grained permissions systems
- SOC 2, GDPR, HIPAA, CCPA compliance controls
- Audit logs and governance dashboards
- Multi-tenancy and tenant isolation
- White-glove onboarding, dedicated success managers
- Usage-based billing dashboards
- Executive-level summaries or C-suite reporting

When in doubt, ask yourself: "Would a developer or engineering manager care about this day-to-day, or is this something a VP of Compliance cares about once a quarter?" If the latter, drop it.

### Step 3 — Read the Existing Backlog

Before writing anything, read the existing backlog file to:
- Find the **last BL-XXX number** used (so you continue the sequence correctly)
- Understand **existing sections** so you don't duplicate features already covered
- Get a feel for the **tone and depth** of existing descriptions

If no backlog file exists yet, start from BL-001.

### Step 4 — Group Features Into Sections

Cluster the filtered features into logical sections (5–10 items per section is ideal). Good section names are functional and scannable — e.g., "Incident Management", "Codebase Intelligence", "Alert Triage & Noise Reduction". Assign a relevant emoji to each section header.

### Step 5 — Write the Backlog Items

For each feature, write one backlog item using this exact format:

```
**BL-{XXX} — {Feature Name}**
{One paragraph: what the feature does, why it matters to engineering teams, and how it would work in a developer portal context. Be specific and practical — not marketing copy.}
```

Descriptions should be:
- **Concrete**: describe what the system actually does, not vague aspirations
- **Developer-context adapted**: frame the feature in terms of your team's portal, not the source product's branding
- **One paragraph**: 2–4 sentences is ideal — enough detail to understand scope, short enough to skim

### Step 6 — Append to the Backlog File

Structure your additions like this:

```markdown
---

## {emoji} {N}. {Section Name}

**BL-{XXX} — {Feature Name}**
{Description.}

**BL-{XXX+1} — {Next Feature}**
{Description.}

---

*Sources: [Product Name](URL) | [Specific Page](URL)*
```

Append the new content at the end of the existing backlog file (before the final sources line if one exists, or at the very end). Update the sources line to include the new product's links.

## Quality Checks Before Finishing

Before handing off, verify:
- [ ] BL numbers continue correctly from the existing file with no gaps or repeats
- [ ] No features duplicate what's already in the backlog (different wording for the same idea counts as a duplicate)
- [ ] Section numbering (the `## N.` headers) continues correctly
- [ ] Every item has a one-paragraph description — no stubs or placeholders
- [ ] Enterprise features have been filtered unless the user asked for them
- [ ] Sources are cited at the bottom

## Output

After appending to the file, provide the user with:
1. A `computer://` link to the updated backlog file
2. A brief summary: how many new items were added, which sections are new, and what product(s) were researched
3. Note any items you weren't sure whether to include and why (so the user can make the call)

## Example Summary Message

> Done! Added **15 new items** across **4 new sections** from PlayerZero. The new sections cover Codebase Intelligence, Predictive Code Quality, Support & Ticket Intelligence, and Runtime Telemetry. I left out their SOC 2 / HIPAA compliance controls and multi-tenancy features as enterprise overhead — let me know if you'd like those added back.
>
> [View updated backlog](computer:///path/to/backlog.md)
