---
name: jagadesh-content
description: >
  Personal content engine for Jagadesh Babu Thangavelu. Use this skill for ANY
  content creation request: writing LinkedIn posts, X/Twitter threads, website
  essays, or adapting content across platforms. Triggers on phrases like "write
  a post", "create content", "help me write", "draft a LinkedIn", "turn this
  into a thread", "write an essay for my website", "adapt this post", or any
  request to generate or transform content for social media or the personal
  website. Also triggers when Jagadesh shares a rough idea, voice note
  transcript, or experience and wants it turned into publishable content.
  Always use this skill — never generate content for Jagadesh without it.
---

# Jagadesh Content Engine

## Overview

This skill turns rough ideas, voice note transcripts, or existing content into
publish-ready posts for LinkedIn, X/Twitter threads, and long-form website
essays — all in Jagadesh's exact brand voice.

**Website:** jagadeshbabu.com
**LinkedIn:** linkedin.com/in/jagadeshbabut

---

## How to Run a Session

### Step 1 — Understand the request

When the user asks for content, determine:

1. **Mode**: Fresh content (new idea/voice note) or Adapt existing (reformat
   something already written)?
2. **Platform**: LinkedIn, X/Twitter, or Website essay?
3. **Input**: What is the raw material — a voice note transcript, a rough
   idea, or existing content?

If any of these are unclear, ask. Keep questions to one at a time.

### Step 2 — Gather the input

For fresh content, prompt:
> "Paste your voice note transcript or type your rough idea freely. Don't
> worry about structure — just say what happened, what you observed, or what
> frustrated/surprised you."

For adapt mode, prompt:
> "Paste the existing content you want to adapt."

### Step 3 — Confirm platform and tuning

If not already specified, ask:

**Platform** (pick one):
- LinkedIn post
- X/Twitter thread (5–7 tweets)
- Website essay (800–1500 words)

**Content pillar** (pick one):
- Org & culture
- Platform & infra
- Leadership transitions

**Primary audience** (pick one):
- Early-career engineers (2–6 yrs, aspiring leaders)
- EMs / Directors
- CTOs / Founders

**Post length** (LinkedIn only):
- Short (100–150 words)
- Medium (200–320 words)
- Long (350–500 words)

**Website hook** (LinkedIn and X only — optional):
- Ask: "Do you want to add a link to jagadeshbabu.com at the end?"
- If yes: "Do you have a specific essay slug? e.g. jagadeshbabu.com/platform-adoption — or leave blank for homepage."

### Step 4 — Generate the content

Load the brand rules from `references/brand.md` and platform rules from
`references/platforms.md`, then generate the content following every rule
exactly.

### Step 5 — Present and offer options

After generating, always offer:
1. "Different hook" — regenerate with a different first line, same content
2. Cross-post — adapt to another platform
3. "Add/remove website hook" — toggle the jagadeshbabu.com CTA

---

## Quick Reference

**Brand in one line:** The engineering leader who builds orgs that ship at scale.

**Tone:** 60% Operator (practical, grounded, no fluff) + 40% Thought Leader
(strategic, opinionated, contrarian).

**4 Contrarian Beliefs:**
1. Clarity is manufactured, not discovered. Expectation setting → buy-in →
   execution, in that order.
2. Platform teams fail at adoption, not technology.
3. DevEx is a product problem, not an infra problem.
4. Speed of execution is a culture output, not a process input.

**The Power Line:** "All of this before AI." — stands alone, never explained.

**Content Pillars:**
1. Engineering culture & org building
2. Platform & infra at scale
3. Leadership transitions (IC → EM → Director)

---

## Reference Files

Read these before generating any content:

- `references/brand.md` — Full brand identity, background facts, voice rules,
  writing constraints. READ THIS FIRST for every content generation task.
- `references/platforms.md` — Platform-specific formatting rules for LinkedIn,
  X/Twitter, and website essays. READ THIS for every generation.

---

## Example Interactions

**User:** "Write a LinkedIn post about a lesson I learned today. In a retro,
nobody could agree on what the team's goal was for the quarter. Turns out
nobody had written it down."

**Claude:** Reads brand.md + platforms.md → generates a medium-form LinkedIn
post opening with a strong hook, weaving in Belief 1 (clarity is manufactured),
offers to add website hook or cross-post.

---

**User:** "Turn that into an X thread"

**Claude:** Adapts the LinkedIn post into 5–7 numbered tweets, each under 280
characters, with the hook in tweet 1 and a landing statement in the last tweet.

---

**User:** "Now write a full essay version for my website"

**Claude:** Expands into an 800–1500 word markdown essay with # title, ##
subheadings, strong opening claim, evidence from real experience, and a
conclusion that reframes the opening.
