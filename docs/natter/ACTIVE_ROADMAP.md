# Natter — Active Roadmap

**Consolidated from the latest known 2026 project context.**

This is a prioritisation document, not a release commitment.

## Current delivery sequence — 11 November 2026

**Recently completed:** Family Connections V1 and parent family-card polish (PRs #14–15); smoother child messaging and stable chat rendering (PR #16).

### Now — Child-owned avatars (design and implementation)

Build an identity feature introduced early in the child's welcome/Promise journey, not an engagement reward. The child should be able to choose and subsequently update a distinctive, inclusive avatar, displayed consistently on:
- their own Chats/profile areas;
- friendship chat-list identity circles for approved friends;
- the linked parent's **Your family** card.

Decide avatar visual language, customisation boundaries, onboarding placement, persistence and privacy model *before* writing the full feature. Maintain backward compatibility with existing `avatar` icon strings; the old `AvatarBuilderScreen` / in-memory `AvatarData` are a starting point to inspect, **not** an approved final design. Never require messaging volume, streaks, levels, or payment to change an avatar. Do not expose child account records or profile details to other families merely to show an avatar.

### Queued next — Offline / pending message status

**Tracked:** [Issue #17 — Messaging: clearly show pending/offline delivery status in child chats](https://github.com/leetreays/Natter/issues/17).

The PR #16 offline test showed that while disconnected, Firestore can show a locally pending bubble before server acknowledgement; the draft stays in the composer until reconnection. The recipient later received the message exactly once, but the duplicate-looking draft/bubble is confusing.

**Requirement:** Provide discreet, reliable delivery-state feedback (pending/waiting; acknowledged; genuine failure) without misleading children, losing drafts, duplicating messages, introducing flicker or weakening security. Determine pending status from Firestore write metadata rather than assuming a locally rendered bubble has reached the server. Test reconnection, receiver delivery, rejected writes and recovery. This is a **separate follow-up after avatars**, not part of the already merged performance PR.

### Later child development priorities

Continue kindness-engine nuance/reliability, consistent non-gamified friendship journeys, and meaningful readiness/graduation criteria. These features should recognise demonstrated communication growth, not message volume or time spent in the app.

## 1. Kindness Engine evolution

### v1.5

Expand beyond basic blocked-word logic into richer patterns:

- exclusion;
- coercion;
- repeated targeting;
- escalating tone;
- all-caps/context signals;
- intervention selection;
- rewrite flows;
- time-aware nudges;
- nudge deduplication;
- apology / reconnect support.

### v2

Explore AI-assisted moderation for:

- context-aware intent;
- longitudinal bullying;
- adaptive coaching;
- richer conversational context.

Maintain privacy and dignity constraints.

## 2. Friendship intelligence refinement

Continue strengthening:

- Friendship Health;
- Repair Momentum;
- Outcome Engine;
- Meaningful Moments;
- journey-stage quality;
- relationship-level single source of truth.

Audit for duplicate derived state.

## 3. Parent experience polish

Continue improving:

- Friendship Journey typography and visual hierarchy;
- insight clarity;
- support ideas;
- weekly summaries;
- relationship language;
- privacy reassurance;
- reducing alarmist or overly technical signal language.

## 4. Digital Rite of Passage

Develop the platform-level graduation experience.

Key requirement:

**This is a child's readiness / independence milestone, not a per-friendship stage.**

Explore:

- readiness criteria;
- ceremony;
- parent communication;
- child ownership;
- transition beyond Natter;
- what data/report persists after graduation.

## 5. Child experience

Continue evolving:

- Daily Sparks / quests;
- coaching variety;
- kindness/repair reinforcement;
- reconnection support;
- clearer progression without visible behavioural scoring.

## 6. Architecture and maintainability

Historical architecture concentrated too much logic in `main.dart`.

Potential future work:

- establish safe module boundaries;
- separate domain logic from UI;
- centralise behavioural/friendship logic;
- reduce duplicate Firestore queries;
- document data ownership;
- improve testability.

Do not undertake a sweeping refactor casually. Preserve working product behaviour.

## 7. Project resilience

- logging;
- Firebase/Google Cloud configuration review;
- deployment documentation;
- backups;
- environment documentation;
- dependency maintenance;
- recovery procedures;
- release checks.

## 8. Legal / compliance

Complete formal due diligence for a UK children's product:

- ownership/IP;
- trademark strategy;
- Privacy Notice;
- Children's Privacy information;
- Terms of Use;
- parent/guardian consent model where required;
- UK GDPR;
- Age Appropriate Design Code / Children's Code;
- data mapping;
- lawful bases;
- retention/deletion;
- DSAR processes;
- DPIA;
- processor/vendor register;
- safeguarding/escalation policy;
- cookie/website compliance;
- security and breach response.

Obtain qualified legal advice before launch decisions.

## 9. Website

Move from holding page to full branded site:

- scroll story;
- Story;
- How it works;
- Join the journey;
- parent explanation;
- product trust/privacy;
- school/investor paths;
- legal links;
- full Connect · Protect · Grow narrative.

## 10. Brand system

Consolidate:

- final shield/N assets;
- monochrome and colour variants;
- favicon;
- spacing;
- typography;
- colour roles;
- three-dot usage;
- animation/evolution rules;
- brand book.

## Definition of roadmap hygiene

When a workstream becomes materially complete, move it from future priority into `CURRENT_PRODUCT_STATE.md` and record the completion/decision in `DECISIONS_LOG.md`.
