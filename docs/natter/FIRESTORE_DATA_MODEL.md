# Natter — Firestore Data Model Snapshot

**Important:** This is a known historical snapshot, not a generated schema. Inspect current Firestore usage before migration or destructive changes.

## Parent / child hierarchy

Known pattern:

```text
parents/{parentId}/children/{childId}/
```

Known child subcollections have included:

```text
chats
messages
contact_requests
approved_contacts
```

## Global access-code collections

Known:

```text
child_access_codes/{code}
child_friend_codes/{code}
```

## Conversations

Known global structure:

```text
conversations/{conversationId}
```

Known fields have included:

- `participantChildIds`
- `blockedByChildIds`
- `spikeHeat`
- `lastSpikeHeatAt`
- `lastSpikeHeatReason`

## Quiet Hours

Known child-level fields:

- `quietHoursEnabled`
- `quietStartHour`
- `quietStartMinute`
- `quietEndHour`
- `quietEndMinute`

Historical defaults were approximately 20:00–07:00.

## Friendship data

A deliberate architectural direction was to make the friendship document the relationship-level source of truth.

Known relationship information includes concepts such as:

- participating children / child names
- friendship stage
- relationship state
- journey data
- relationship intelligence outputs

Meaningful Moments have been streamed separately in at least one historical implementation.

## Signals

Known persisted behavioural/parent insight concepts include:

- blocked word
- Quiet Hours attempt
- targeting concern
- rewrite tracking
- Protected Delivery
- behavioural summaries

## Rule for future work

Before adding a new Firestore field or collection, answer:

1. What concept owns this data?
2. Is there already a source of truth?
3. Who may read it?
4. How long should it exist?
5. Is it necessary to retain?
6. Could it expose private child conversation content indirectly?
7. Does it require rules/index changes?
