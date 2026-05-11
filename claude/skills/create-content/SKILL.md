---
name: create-content
description: >
  Generates publish-ready content for Jagadesh Babu Thangavelu across LinkedIn,
  X/Twitter, and website essays. Use this skill whenever Jagadesh wants to write
  or draft content — including phrases like "write a post", "draft a LinkedIn",
  "create content", "turn this into a thread", "write an essay", "help me write
  about", "adapt this post", or when he shares a voice note transcript, rough
  idea, or experience and wants it turned into publishable content. This skill
  handles content creation only — for publishing to Hugo, use the
  publish-website skill.
---

# create-content

Turns rough ideas, voice note transcripts, or existing content into
publish-ready pieces for LinkedIn, X/Twitter, and long-form website essays —
all in Jagadesh's exact brand voice.

**Website:** jagadeshbabu.com
**LinkedIn:** linkedin.com/in/jagadeshbabut | **X:** @jagadeshbabut

---

## Session Flow

### 1 — Identify the request

Determine:
- **Mode:** Fresh (new idea / voice note) OR Adapt (existing content)?
- **Platform(s):** LinkedIn / X / Website essay / All three?
- **Input:** Do you have the raw material, or ask for it?

### 2 — Gather input

**Fresh content:**
> "Paste your voice note transcript or type freely. Don't structure it —
> say what happened, what you observed, or what frustrated/surprised you."

**Adapt mode:**
> "Paste the existing content."

### 3 — Confirm tuning (if not already clear)

**Pillar** (one):
- `org-culture` — team building, org design, hiring, expectations
- `platform-infra` — cloud-native, DevEx, platform thinking, compliance
- `leadership` — IC to EM, EM to Director, career transitions

**Audience** (one):
- Early-career engineers (2–6 yrs, aspiring leaders)
- EMs / Directors
- CTOs / Founders

**Length** (LinkedIn only):
- Short (100–150w) / Medium (200–320w) / Long (350–500w)

**Website hook** (LinkedIn + X only — ask every time):
> "Add a link to jagadeshbabu.com at the end?"
> If yes: "Slug? e.g. `clarity-is-manufactured` — or blank for homepage."

### 4 — Generate

Load `references/brand.md` and `references/platforms.md` before writing.
Follow every rule exactly.

### 5 — After generating, always offer

1. **Different hook** — new first line, same content
2. **Cross-post** — adapt to another platform
3. **Website hook** — toggle jagadeshbabu.com CTA
4. **Publish to Hugo** — "Run `publish-website` to deploy this as an essay"

---

## Content Workflow

```
Voice note / rough idea
        ↓
  LinkedIn post  ←── always start here
        ↓
  X thread       ←── repurpose top performers
        ↓
  Website essay  ←── long-form expansion
        ↓
  [hand off to publish-website skill]
```

---

## Reference Files

Read these before every generation:

- `references/brand.md` — identity, background facts, voice rules,
  contrarian beliefs, audience rings, BFSI constraints
- `references/platforms.md` — LinkedIn, X, and essay formatting rules,
  website hook rules, cross-platform adaptation
