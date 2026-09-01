# Natter — Current Product State

**Checkpoint basis:** consolidated project context through August 2026.

This document describes the latest known state from the ChatGPT Natter project. The repository itself is authoritative for exact implementation details.

## Foundation / infrastructure — largely implemented

Known completed or mostly completed work includes:

- parent/child account structure;
- child device linking;
- Firestore-backed conversations;
- friend requests and approvals;
- persistent message history;
- conversation restoration;
- Quiet Hours architecture;
- parent insight architecture;
- Firestore signal persistence;
- real-time parent signal streaming;
- child-specific signal isolation;
- Protected Delivery tracking;
- rewrite tracking;
- blocked-word tracking;
- Firestore-backed behavioural summaries.

## Child experience — implemented / substantial progress

Known:

- messaging;
- coaching;
- Protected Delivery;
- Quiet Hours;
- Behaviour Engine;
- Friendship Health inputs;
- Repair Momentum;
- Meaningful Moments;
- Outcome Engine.

## Parent experience — implemented / substantial progress

Known:

- Parent Dashboard;
- Digital Readiness Report;
- Rules & Quiet Time;
- Parent Insights;
- Friendships;
- Friendship Journey.

## Parent Insights — major progress

Known connections to Firestore include:

- Recent Signals;
- Patterns;
- Support Ideas;
- At a Glance;
- Weekly Summaries;
- donut visualisation.

Signal persistence survives resets/reloads in the known implementation.

Past work also addressed duplicate insight behaviour and misleading signal wording.

## Friendship Engine — implemented / substantial progress

Known completed components:

- Friendship Health;
- Repair Momentum;
- Outcome Engine;
- Meaningful Moments;
- Meaningful Moments Registry;
- Journey Stages;
- Conversation Milestones;
- Parent Friendship Journey architecture.

## Parent Friendship Journey — completed five-commit visual/structural pass

Implemented sequence:

1. Relationship identity
2. Current Relationship
3. Journey So Far
4. Looking Ahead / Coming Up
5. Privacy Promise

Final known section order:

- Relationship identity
- Current Relationship
- Journey So Far
- Coming Up
- Privacy Promise

Known header language:

**Built through kindness, repair and trust.**

Privacy language:

**Your child's conversations remain private.**

**You understand relationships, not messages.**

## Kindness Engine

v1 is substantially implemented.

Known recent addition: all-caps detection.

Next planned evolution is richer pattern detection, smarter intervention choice and repair-aware nudges.

## Brand

Current preferred direction:

- original shield concept remains primary;
- white N / shield speech-bubble identity;
- navy is a core brand colour;
- symbolism should remain subtle;
- three coloured dots may represent core promises / Connect-Protect-Grow;
- third dot was explicitly explored in green.

Core palette known historically:

- Blue `#3DA6F3`
- Green `#A4D35A`
- Yellow `#FBC02D`
- Pink `#FF5DA2`
- Navy `#06112E`

## Website

Domain:

**getnatter.co.uk**

A holding page was successfully deployed and domain routing verified in August 2026.

Browser tab title was changed to **Natter.**

The full site concept remains a scroll narrative moving from darkness/dusk toward daylight, introducing the product through Connect · Protect · Grow.

## Legal / compliance

This is an active due-diligence workstream rather than a completed capability.

Key areas include:

- ownership/IP;
- brand protection;
- privacy;
- children's data;
- safeguarding;
- terms/policies;
- UK regulatory obligations;
- website disclosures;
- data-processing governance.

## Important note

This export does not claim every feature above is production-ready. It records the latest known development checkpoint and product decisions. Verify code, Firebase rules, deployed environments and tests before making release claims.
