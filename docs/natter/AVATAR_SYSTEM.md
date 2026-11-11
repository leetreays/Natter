# Natter — Child Avatar Identity (V1 draft)

**Status:** Design discovery; awaiting visual direction and approval.  
**Branch:** `feature/child-avatar-identity`  
**Started:** 11 November 2026

## Product intent

A child should feel that their Natter identity is theirs. Avatar creation is a moment of self-expression introduced early in the experience, near the child's promises, rather than a reward, streak, score or retention mechanic.

## Known product requirements

- A child chooses or creates an avatar early in onboarding, with a sensible default for existing accounts and interrupted onboarding.
- The same identity appears on the child's Chats/profile surfaces, approved friends' conversation identity circles, and the linked parent's **Your family** card.
- The child can edit their avatar later without unlocking parts through messaging, engagement, purchases, or behavioral assessments.
- The avatar must be inclusive, recognisable at mobile small sizes, visually consistent with Natter's premium navy/night-sky design, and not require photos.
- Existing children, friendships, parent cards, device relinks and message history must continue to work.

## Current implementation findings (inspect against main before coding)

- `AvatarData`, `AvatarPreview` and a legacy `AvatarBuilderScreen` exist in `lib/main.dart`, but the builder uses emoji-style components; the `AppState.avatar` value is in memory and is not an authoritative shared identity.
- The persisted `parents/{parentId}/children/{childId}.avatar` value and child device session currently use a short icon ID such as `owl`. Parent family cards use this string to choose a generic icon.
- `NatterChildChatTile` already exposes an optional `avatar` widget slot; without it, the tile shows the friend's initial.
- The current child profile deliberately does not surface the legacy avatar builder.
- Firestore child documents are private to the linked child/parent under present rules. Approved friends must **not** gain broad read access to them merely to see avatars.

## Questions for design decision

1. Visual language: illustrated human characters, fictional creatures/mascots, or a hybrid choice?
2. Customisation depth: starting templates vs individually chosen face, hair, clothes and accessories?
3. Onboarding moment: before promises, between promise-selection and sealing, or after the rite?
4. Later edits: always available from Profile; no reward locks. Consider a clear edit/save/revert flow.

No choice above is final without review.

## Proposed implementation sequence (after direction is approved)

1. Define a compact, versioned avatar configuration with reliable defaults and backwards-compatible migration from the legacy icon strings.
2. Build reusable, deterministic Flutter rendering at small and large sizes (chat tile, child identity, parent family card).
3. Provide child-owned builder, first-run placement and later Profile edit entry point; avoid accidental changes until Save.
4. Persist the canonical avatar configuration under the child's own record with appropriate write permissions. Ensure device recovery and another authenticated session restore it.
5. Make an **avatar-only, least-privilege projection** available to approved friends through an authorised path; do not expose child profile fields or messages.
6. Verify live updates across parent/child/approved-friend devices, unapproved access denial, deletion/relink behavior and fallbacks.
7. Flutter tests, Firestore emulator rules tests where rules are modified, web profile build and staged manual visual review before merge.

## Not in V1

Photo uploads, public browsing or search, avatar marketplaces, earned/unlocked items, spending, behavioural scores, visible engagement counters, AI-generated likenesses or unrestricted user-uploaded artwork.

## Adjacent work

Offline/pending message status is separately tracked in [Issue #17](https://github.com/leetreays/Natter/issues/17) and the active roadmap, queued after the avatar project. This work must not be forgotten or folded into avatar scope.
