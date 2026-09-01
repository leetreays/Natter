# Natter — Architecture Snapshot

**Status:** historical implementation snapshot from 2026. Verify against the current repository before changing code.

## Application

Historically:

- Flutter
- target platforms: Web + Android
- a large proportion of application logic lived in a single `main.dart`
- Firebase provided backend services

Known Flutter toolchain snapshot:

- Flutter stable 3.44.6

Known dependency snapshot:

- `firebase_core ^4.1.1`
- `cloud_firestore ^6.0.1`
- `firebase_auth ^6.0.2`
- `shared_preferences ^2.3.2`
- `cupertino_icons ^1.0.8`

Do not downgrade or pin to these versions merely because they appear here. Inspect `pubspec.yaml`.

## Authentication

Known design:

- child uses anonymous Firebase authentication;
- parent account/UID underpins parent-side data;
- child device linking is persisted locally;
- a linked auth UID has historically been used.

## Data architecture

Firestore is the primary persistence layer.

Relationship architecture deliberately moved toward a friendship document as the relationship-level source of truth.

## Behaviour pipeline

Historical message send flow included:

1. apply/decay conversation escalation;
2. check blocked status;
3. check Quiet Hours;
4. run message safety checks;
5. intervene if needed;
6. record signals;
7. send/persist message;
8. update relationship intelligence.

## Parent signals

Known architecture persisted parent-facing behavioural signals in Firestore and streamed them to the parent experience in real time.

## Project resilience

Cloud/logging continuity became a roadmap item after the Google Cloud free trial ended.

Treat operational resilience, logging, backups and deployment knowledge as an explicit workstream rather than an afterthought.

## Editing caution

The historical `main.dart` became very large (~17k lines by mid-2026), and a number of implementation issues were caused by nesting/scope/bracket errors.

If the current repo still resembles that structure:

- make small edits;
- inspect surrounding widget/build scopes;
- preserve builder-local variable scope;
- validate braces before broad edits;
- avoid huge search-and-replace refactors without tests.
