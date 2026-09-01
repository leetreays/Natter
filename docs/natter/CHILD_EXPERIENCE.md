# Natter — Child Experience

## Purpose

The child experience is a private friendship and communication space with embedded support.

It is not intended to feel like a surveillance interface.

## Known child-side capabilities

Implementation checkpoint: mid-2026. Verify current code before relying on exact implementation details.

- Child account/device linking
- Persistent conversations
- Friend requests / approvals
- Friend codes / Add Friend
- Messaging
- Conversation restoration
- Coaching prompts
- Protected Delivery
- Quiet Hours awareness / gating
- Behaviour Engine signals
- Friendship Health inputs
- Repair Momentum inputs
- Meaningful Moments
- Outcome Engine inputs
- Pause behaviour during heightened conversation states
- Daily Sparks / quests in product scope

## Messaging philosophy

When a message presents a concern, Natter may:

- coach;
- ask for a rewrite;
- protect delivery;
- block;
- introduce a short pause;
- record behavioural information for relationship intelligence.

The precise choice should depend on severity and context.

## Quiet Hours

Quiet Hours are configured per child from the parent side.

Known historical defaults:

- 20:00 start
- 07:00 end

Exact defaults and current behaviour must be verified against code.

The child should be aware of the boundary without the experience feeling punitive.

## Conversation heat / escalation

A historical implementation used conversation-level `spikeHeat` with states conceptually similar to:

- calm
- heated
- pause

Known past behaviour included:

- heat increases after concerning events;
- heat can decay with time and kinder interaction;
- a pause may temporarily disable sending;
- a historical send lock was approximately 30 seconds;
- heat could clear after a longer calm period.

Treat these as an implementation snapshot, not immutable product rules.

## Rite onboarding

An explored/implemented child rite flow includes:

1. name
2. promises
3. seal
4. ceremony
5. badge

Do not confuse this onboarding/ceremonial language with the platform-level Digital Rite of Passage graduation concept.
