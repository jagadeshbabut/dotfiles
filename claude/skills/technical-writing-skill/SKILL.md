---
name: technical-writing
description: >
  Write or improve technical design documents, engineering specs, architecture docs, RFCs, and
  decision records with clarity, structure, and empathy for the reader. Use this skill whenever
  the user asks to: write or draft a design doc, tech spec, or RFC; review or improve a technical
  document; turn rough notes into a structured doc; or asks for help making a doc "cleaner",
  "clearer", or "easier to read". Also trigger for requests like "write up my design", "help me
  document this decision", or "review this doc". Prioritize this skill any time technical writing
  quality matters.
---

# Technical Writing Skill

## Core Philosophy

**Clarity is the goal. Every word has a cost.**

Good technical documents communicate; they don't impress. Simple docs get read more. More readers means better alignment and better visibility for the work.

---

## The Golden Rule: Conclusion First

Always start with the answer — what was decided and why it matters. Then add context, alternatives, and details below for those who want depth.

**Why this matters:** Most engineers write by listing every approach first and concluding last. That buries the lead. Readers lose track. Busy reviewers skim or give up. Leading with the conclusion respects everyone's time.

**Structure every doc like this:**

```
1. Conclusion / Decision (What + Why it matters)
2. Problem & Context (Short setup: constraints, prior decisions)
3. Proposed Solution (How)
4. Alternatives Considered (Brief, with reasons rejected)
5. Open Questions / Next Steps (optional)
```

---

## Writing Rules

### Treat every sentence like it has a cost

After writing, cut aggressively:
- Remove filler words and repeated ideas
- Break long sentences into two shorter ones
- Delete any line that doesn't add new information
- Ask of every paragraph: "Would removing this hurt the reader?"

### Use simple language

- Avoid buzzwords unless they are precise technical terms the audience knows
- Prefer the shorter word when both mean the same thing
- Never use a phrase where a word will do

### Use bullets wisely

Prefer bullets when:
- Listing options or alternatives
- Enumerating steps in a process
- Comparing tradeoffs side by side

Use prose for reasoning, context, and explanation — bullets fragment thought.

### Add helpful links, not lengthy explanations

If a reader might pause on a term or concept, add a short inline explanation or a link. Don't assume shared context; don't repeat what a link explains better.

---

## Context Is Not Optional

Every doc needs a short setup section that answers:
- What problem does this solve?
- What constraints existed?
- What prior decisions are we building on?

This prevents unnecessary back-and-forth later and helps readers understand *why* the decision exists, not just what it is.

---

## Empathy Pass (Always Do This)

After drafting, re-read the doc as someone new to the topic. Ask:
- What might confuse them?
- What context is missing?
- Where would they stop and ask a question?

Then fix those spots before publishing.

---

## Editing Checklist

Run this pass before finishing any doc:

- [ ] Does the first section clearly state the outcome or decision?
- [ ] Is the "why" explained before the "how"?
- [ ] Are there filler words to cut? ("basically", "in order to", "it is worth noting that")
- [ ] Can any long sentence be split in two?
- [ ] Are lists used only where listing makes sense?
- [ ] Is there missing context a new reader would need?
- [ ] Are all links and references correct and helpful?
- [ ] Does the doc avoid buzzwords or jargon without explanation?

---

## When Writing a New Doc

1. **Start with the conclusion.** Draft the decision or answer first, even as a placeholder.
2. **Write the context block.** What's the problem, what are the constraints, what's already decided.
3. **Describe the solution.** How does it work? Why does it work for this problem?
4. **List alternatives.** What else was considered? Why was each rejected? Keep this brief.
5. **Apply the editing checklist.**
6. **Do the empathy pass.**

---

## When Improving an Existing Doc

1. Read it through once without editing.
2. Identify: Is the conclusion visible early? Is context missing?
3. Apply the editing checklist line by line.
4. Cut ruthlessly — a shorter doc that communicates is better than a long one that exhausts.
5. Do the empathy pass.

---

## Example Transformation

**Before (conclusion buried):**
> We looked at three approaches. Option A uses a queue-based system. Option B uses a polling mechanism. Option C adds a cache layer. After weighing the tradeoffs we decided to go with Option B due to operational simplicity.

**After (conclusion first):**
> **Decision: Use polling (Option B).** It is operationally simpler than the alternatives and meets our latency requirements without introducing a queue or cache layer.
>
> **Alternatives considered:**
> - Option A (queue-based): Higher reliability but adds operational overhead we don't need at this scale.
> - Option C (cache layer): Reduces load but introduces cache invalidation complexity.
