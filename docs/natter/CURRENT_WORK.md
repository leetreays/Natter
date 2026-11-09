# Natter — Current Work

**Last updated:** 9 November 2026

## Active task

Family Connections V1: private parent-child in-app messaging with a Home entry point for children and familiar message actions on the existing parent child cards.

## Latest completed work

- PR #11: branded loader and durable, independently acknowledged friendship celebrations.
- PR #12: stop tracking generated Flutter build artifacts.
- PR #13: browser-history-aware app navigation; verified repeated Android back gestures and browser Forward in both experiences.

## Current approach

- Start from the linked parent and child identities; never make a parent a participant in friendship messaging.
- Family messages live in their own per-child Firestore subcollection.
- Security rules and local emulator tests are prepared on this feature branch; they must be validated and deployed separately from GitHub.
- UI remains intentionally different by role: child sees **Home**, parent sees a normal message action by each child.

## Next verification

- Run local Firestore emulator rules tests.
- Implement family messages repository and UI.
- Verify parent and child messaging on separate authenticated sessions, then recheck account boundaries.
