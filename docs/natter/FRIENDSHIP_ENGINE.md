# Natter — Friendship Engine

## Purpose

The Friendship Engine interprets how a relationship develops over time.

It should not reduce friendship to a single simplistic number.

## Known components

### Friendship Health

Represents overall relationship quality/health using behavioural and interaction context.

### Repair Momentum

Recognises whether a relationship is moving toward repair after difficulty.

This is important because Natter should value recovery, not merely record conflict.

### Outcome Engine

Interprets the direction or outcome of meaningful interaction patterns.

### Meaningful Moments

Captures important relationship events that deserve to be reflected in the Friendship Journey.

Examples conceptually include:

- beginning/growth;
- kindness;
- repair;
- reconnection;
- milestone moments.

### Meaningful Moments Registry

Known architecture included a registry for mapping moment types to presentation/meaning.

### Journey Stages

Friendships can progress through named stages.

The parent Journey should explain the current relationship and what may come next.

### Conversation Milestones

Meaningful conversation progress can feed the broader relationship journey.

## Single source of truth

A deliberate architectural direction was to centralise relationship-level state into the **friendship document** so that multiple experiences consume one consistent source of truth.

Avoid re-deriving the same relationship truth independently in multiple screens unless there is a strong reason.

## Parent Friendship Journey checkpoint

Known implementation used:

- outer friendship-document stream;
- inner meaningful-moments stream;
- relationship title derived from child names;
- friendship stage from friendship data;
- stage registry mapping;
- current journey stage number;
- future/coming-up cards;
- privacy promise.

Historical helper names included:

- `_journeyStageNumberFromFriendshipStage()`
- `_comingUpCards()`
- `_outerSectionDecoration()`
- `_emojiForIcon()`
- `_formatMomentDate()`

These names are useful clues when locating existing code but are not requirements if the codebase has since changed.
