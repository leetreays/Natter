# Natter — Codex Project Instructions

Natter is a child/parent friendship-learning platform designed to help children learn to build healthy friendships while giving parents meaningful understanding **without surveillance**.

This file is a map, not the full product manual. Before making substantial changes, read the relevant sources of truth in `docs/natter/`.

## Start here

For almost every task, read:

1. `docs/natter/PRINCIPLES_AND_ETHOS.md`
2. `docs/natter/CURRENT_PRODUCT_STATE.md`
3. `docs/natter/CURRENT_WORK.md`
4. The topic-specific document relevant to the task.

## Non-negotiable product principles

- **Children own their conversations.**
- **Parents understand relationships, not messages.**
- **Celebrate growth more than monitor mistakes.**
- **Privacy is a feature, not a compromise.**
- Behavioural intelligence should power helpful experiences without exposing children to visible behavioural scores.
- Natter should teach, coach and support rather than defaulting to punishment or surveillance.
- The product should ultimately help a child become ready to outgrow Natter; retention is not the highest-order goal.
- The Digital Rite of Passage is a platform-level graduation/end-state, not something that happens per friendship.
- `Connect · Protect · Grow` is a core expression of the product's purpose.

Do not silently weaken these principles for implementation convenience. If a requested or proposed technical change conflicts with them, surface the conflict.

## Repository knowledge

The structured Natter project brain lives in `docs/natter/`.

- `PRODUCT_VISION.md` — what Natter is and why it exists
- `PRINCIPLES_AND_ETHOS.md` — product philosophy and decision filters
- `PRODUCT_LANGUAGE.md` — canonical concepts, naming and tone
- `CHILD_EXPERIENCE.md` — child-facing experience
- `PARENT_EXPERIENCE.md` — parent-facing experience and privacy boundary
- `FRIENDSHIP_ENGINE.md` — relationship intelligence and Friendship Journey
- `KINDNESS_ENGINE.md` — coaching, moderation and safer communication
- `ARCHITECTURE.md` — technical architecture snapshot
- `FIRESTORE_DATA_MODEL.md` — known Firestore structures
- `CURRENT_PRODUCT_STATE.md` — latest consolidated product checkpoint
- `ACTIVE_ROADMAP.md` — priorities and remaining work
- `BRAND_AND_DESIGN.md` — visual identity and brand direction
- `WEBSITE.md` — getnatter.co.uk direction and website state
- `LEGAL_AND_COMPLIANCE.md` — legal/compliance workstream
- `DECISIONS_LOG.md` — important decisions and rejected directions
- `CURRENT_WORK.md` — short rolling handoff for the active task

## Source-of-truth hierarchy

When sources conflict, use this order:

1. Current user instruction
2. Working code and current repository configuration for implementation facts
3. `CURRENT_WORK.md` for active task state
4. The authoritative product/ethos documents in `docs/natter/`
5. `CURRENT_PRODUCT_STATE.md`
6. `ACTIVE_ROADMAP.md`
7. Historical notes in `DECISIONS_LOG.md`

Product philosophy is not overridden merely because old code implements something differently. Implementation facts, however, must be verified against current code when possible.

## Coding approach

Natter has historically been developed cautiously and incrementally. Prefer:

- small, reviewable changes;
- preserving working behaviour unless change is intentional;
- explicit placement instructions when editing large files;
- avoiding broad refactors during feature work unless necessary;
- validating brackets, widget nesting, builder scope and Firestore field assumptions carefully;
- using existing naming and visual language instead of inventing parallel concepts;
- tracing the existing data flow before adding a second source of truth.

The Flutter application has historically concentrated substantial logic in `main.dart`. Do not assume this is still exact: inspect the current repository before editing.

## Product safety and privacy

Natter deals with children and family relationships. Treat privacy, child safety, data minimisation, access boundaries and parental visibility as architectural requirements, not polish.

Do not expose child message content to parents unless the product specification is deliberately changed by the product owner.

Do not transform behavioural intelligence into visible child scoring, ranking, shame mechanics or punitive dashboards.

## Before coding

For non-trivial changes:

1. Inspect the relevant existing implementation.
2. Identify the current source of truth for the data being changed.
3. Read the relevant Natter product documentation.
4. Preserve established terminology.
5. State any conflict between code, documentation and requested behaviour.

## Verification

Use the repository's current build/test/lint commands once discovered. Do not invent commands that are not supported by the repo.

At minimum for Flutter changes, inspect current project configuration and make a best effort to run the appropriate analyzer/build/test checks available in the repository.

## Documentation maintenance

After substantial work:

- Update `CURRENT_WORK.md` if the active state changed.
- Update `CURRENT_PRODUCT_STATE.md` when a meaningful capability becomes implemented or removed.
- Update `ACTIVE_ROADMAP.md` when priorities or completion status change.
- Add an entry to `DECISIONS_LOG.md` when a meaningful product or architectural decision is made.
- Update topic-specific docs when the implementation changes their factual content.

Do **not** casually edit the core principles in `PRINCIPLES_AND_ETHOS.md`. If a task requires changing them, make that change explicit and record it in `DECISIONS_LOG.md`.

## Secrets

Never place API keys, passwords, private credentials, signing secrets, tokens or sensitive personal data in these project-brain files or commits.
