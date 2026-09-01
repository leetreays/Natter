# Natter — Active Roadmap

**Consolidated from the latest known 2026 project context.**

This is a prioritisation document, not a release commitment.

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
