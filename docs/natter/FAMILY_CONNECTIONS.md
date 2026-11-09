# Family Connections — Messaging V1

**Status:** Feature branch in testing. Family message and read-state rules have been published to the existing Natter Firebase project; testing uses test accounts. The latest Quiet Hours exception is not yet verified in the running app. PR #14 remains a draft.

## Concept

Family communication is a direct connection to **home**, separate from a child's friendships. It does not have friendship stages, Friendship Health, a journey, scores, friend codes, or approval requests.

## Child experience

- A distinct **Home** card near the top of Chats, preceding the friendship list.
- House icon with a gentle warm glow against the existing navy night-sky design.
- Primary line: **Home**. Action: **Message home**.
- Enter a reassuring, familiar chat space using Natter's existing rounded chat language.
- **Home messaging is always available during Quiet Hours.** Ordinary friendship messages continue to honour the child's Quiet Hours settings; the linked family thread is not an emergency service and does not guarantee an immediate response.
- This is not an emergency contact channel, and the app should not imply continuous parental availability.
- Parent display names and additional verified guardians are future enhancements. The first version links to the existing parent account.

## Parent experience

- A conventional chat-bubble icon/button on each child's existing card.
- It opens the corresponding child thread directly.
- No additional parent landing page, friendship stages, progress bars or new dashboard.
- The thread itself can follow familiar left/right message alignment.

## Authentication and privacy

The initial family conversation is stored at:

`parents/{parentId}/children/{childId}/family_messages/{messageId}`

Only the authenticated parent account `parentId` and the child whose Firebase auth UID matches that child record's `linkedAuthUid` can read or create messages.

- Every created message records `text`, `senderRole`, `senderAuthUid`, `createdAt`.
- Sender role is enforced in Firestore rules and cannot be spoofed.
- No edits/deletes in V1. No message content is copied into friendship projections or parent insights.
- Unread counters use `family_read_state/parent` and `family_read_state/child` beneath each child document, with `lastReadAt` written as a server timestamp by the actor only. Unread messages are counted from the latest 100 family messages and shown as 9+ above nine.
- The sender role, not an easily changed device authentication UID, determines message alignment.
- Both parent and child views clear only their own unread badge when the thread is open; unread state persists across app sessions.
- Siblings, other families and unlinked or anonymous sessions without a matching child link have no access.
- This new path must never grant parents read access to their children's separate friend-to-friend `conversations/{id}/messages`.
- Production rules must be **explicitly deployed** after testing, before enabling the UI in an environment that writes messages.

## Planned implementation and validation

1. Review the security rules with Firestore emulator tests, including sibling and role-spoofing negatives.
2. Add a small shared repository + reusable message UI, with child and parent-specific entry points.
3. Preserve unsent text and show failures; verify real-time updates across separate parent and child sessions.
4. Check device recovery, sign-out, Quiet Hours interactions and errors before merge.
5. Post-launch: consider unread state, notifications, additional guardians, and calling in separate iterations.

**Scope:** In-app text messaging only. No calling, external phone/SMS integration, file attachments or emergency-service promises.
