#!/usr/bin/env python3
from pathlib import Path
import subprocess

EXPECTED_HEAD = "180079104febef071bef4ff3e7a82226a39ff738"

root = Path.cwd()
rules_path = root / "firestore.rules"
main_path = root / "lib/main.dart"
test_path = root / "test/firestore.rules.test.js"

if not rules_path.exists() or not main_path.exists() or not test_path.exists():
    raise SystemExit("ABORT: run this from the Natter repository root.")

head = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
if head != EXPECTED_HEAD:
    raise SystemExit(
        f"ABORT: expected HEAD {EXPECTED_HEAD}, found {head}. No files changed."
    )

rules = rules_path.read_text()
main = main_path.read_text()
tests = test_path.read_text()

# Guard: this correction is ONLY for the already-applied first typing patch.
required_markers = [
    "function validTypingSetAt(conversation, index)",
    "function validTypingClearAt(conversation, index)",
    "function validTypingUpdate(conversation)",
    "&& validTypingUpdate(resource.data);",
]
for marker in required_markers:
    if marker not in rules:
        raise SystemExit(
            f"ABORT: expected applied typing-patch marker not found: {marker}. No files changed."
        )

if "await FirebaseFirestore.instance.runTransaction((transaction) async {" not in main:
    raise SystemExit(
        "ABORT: transactional clearTyping() marker not found. No files changed."
    )

old_block_helper = """    function validBlockedByChildIdsUpdate(conversation) {
      return !request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['blockedByChildIds'])
        || validSelfBlockedByChildIdsChangeAt(conversation, 0, 1)
        || validSelfBlockedByChildIdsChangeAt(conversation, 1, 0);
    }
"""
new_block_helper = """    function validBlockedByChildIdsUpdate(conversation, affectedKeys) {
      return !affectedKeys.hasAny(['blockedByChildIds'])
        || validSelfBlockedByChildIdsChangeAt(conversation, 0, 1)
        || validSelfBlockedByChildIdsChangeAt(conversation, 1, 0);
    }
"""
if rules.count(old_block_helper) != 1:
    raise SystemExit("ABORT: block-helper anchor mismatch. No files changed.")
rules_new = rules.replace(old_block_helper, new_block_helper, 1)

old_typing_block = """    function conversationCanonicalIdentityUnchanged() {
      return !request.resource.data.diff(resource.data).affectedKeys().hasAny([
        'friendshipId',
        'participantChildIds',
        'participantParentIds',
        'participantNames',
        'status',
        'createdAt'
      ]);
    }


    function validTypingSetAt(conversation, index) {
      return isLinkedParticipantAt(conversation, index)
        && request.resource.data.keys().hasAll([
          'typingChildId',
          'typingAt'
        ])
        && request.resource.data.typingChildId
          == conversation.participantChildIds[index]
        && request.resource.data.typingAt == request.time;
    }

    function validTypingClearAt(conversation, index) {
      return isLinkedParticipantAt(conversation, index)
        && conversation.keys().hasAny(['typingChildId'])
        && conversation.typingChildId
          == conversation.participantChildIds[index]
        && request.resource.data.keys().hasAll([
          'typingChildId',
          'typingAt'
        ])
        && request.resource.data.typingChildId == null
        && request.resource.data.typingAt == null;
    }

    function validTypingUpdate(conversation) {
      return !request.resource.data.diff(resource.data).affectedKeys().hasAny([
          'typingChildId',
          'typingAt'
        ])
        || validTypingSetAt(conversation, 0)
        || validTypingSetAt(conversation, 1)
        || validTypingClearAt(conversation, 0)
        || validTypingClearAt(conversation, 1);
    }
"""

# Tolerate the same applied block without the extra blank line inserted by the transfer script.
if old_typing_block not in rules_new:
    old_typing_block = old_typing_block.replace("    }\n\n\n    function validTypingSetAt", "    }\n\n    function validTypingSetAt")

new_typing_block = """    function validTypingChangeAt(conversation, index) {
      return (
          (
            request.resource.data.keys().hasAll([
              'typingChildId',
              'typingAt'
            ])
            && request.resource.data.typingChildId
              == conversation.participantChildIds[index]
            && request.resource.data.typingAt == request.time
          )
          || (
            conversation.keys().hasAny(['typingChildId'])
            && conversation.typingChildId
              == conversation.participantChildIds[index]
            && request.resource.data.keys().hasAll([
              'typingChildId',
              'typingAt'
            ])
            && request.resource.data.typingChildId == null
            && request.resource.data.typingAt == null
          )
        )
        && isLinkedParticipantAt(conversation, index);
    }

    function validConversationUpdate(conversation) {
      let affectedKeys =
        request.resource.data.diff(resource.data).affectedKeys();

      return !affectedKeys.hasAny([
          'friendshipId',
          'participantChildIds',
          'participantParentIds',
          'participantNames',
          'status',
          'createdAt'
        ])
        && validBlockedByChildIdsUpdate(conversation, affectedKeys)
        && (
          (
            !affectedKeys.hasAny([
              'typingChildId',
              'typingAt'
            ])
            && isLinkedConversationParticipant(conversation)
          )
          || (
            affectedKeys.hasAny([
              'typingChildId',
              'typingAt'
            ])
            && (
              validTypingChangeAt(conversation, 0)
              || validTypingChangeAt(conversation, 1)
            )
          )
        );
    }
"""

if rules_new.count(old_typing_block) != 1:
    raise SystemExit("ABORT: typing-helper anchor mismatch. No files changed.")
rules_new = rules_new.replace(old_typing_block, new_typing_block, 1)

old_update_rule = """      allow update: if isLinkedConversationParticipant(resource.data)
        && conversationCanonicalIdentityUnchanged()
        && validBlockedByChildIdsUpdate(resource.data)
        && validTypingUpdate(resource.data);
"""
new_update_rule = """      allow update: if validConversationUpdate(resource.data);
"""
if rules_new.count(old_update_rule) != 1:
    raise SystemExit("ABORT: conversation-update anchor mismatch. No files changed.")
rules_new = rules_new.replace(old_update_rule, new_update_rule, 1)

old_typing_test = """      updateDoc(doc(db, conversationPath), {
        typingChildId: 'child-a',
        typingAt: new Date('2026-09-08T10:00:00Z'),
      }),
"""
new_typing_test = """      updateDoc(doc(db, conversationPath), {
        typingChildId: 'child-a',
        typingAt: serverTimestamp(),
      }),
"""
if tests.count(old_typing_test) != 1:
    raise SystemExit("ABORT: legacy Child A typing-test anchor mismatch. No files changed.")
tests_new = tests.replace(old_typing_test, new_typing_test, 1)

old_unlink_test = """  test('unlinking Child A immediately revokes conversation update access', async () => {
    const oldChildDb = firestoreFor('child-a-auth');
    await assertSucceeds(
      updateDoc(doc(oldChildDb, conversationPath), {
        typingChildId: 'child-a',
      }),
    );
    await assertSucceeds(
      updateDoc(doc(oldChildDb, 'parents/parent-a/children/child-a'), {
        linkedAuthUid: null,
        linkedDevice: false,
      }),
    );
    await assertFails(
      updateDoc(doc(oldChildDb, conversationPath), {
        typingChildId: null,
      }),
    );
  });
"""
new_unlink_test = """  test('unlinking Child A immediately revokes conversation update access', async () => {
    const oldChildDb = firestoreFor('child-a-auth');
    await assertSucceeds(
      updateDoc(doc(oldChildDb, conversationPath), {
        typingChildId: 'child-a',
        typingAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(oldChildDb, 'parents/parent-a/children/child-a'), {
        linkedAuthUid: null,
        linkedDevice: false,
      }),
    );
    await assertFails(
      updateDoc(doc(oldChildDb, conversationPath), {
        typingChildId: 'child-a',
        typingAt: serverTimestamp(),
      }),
    );
  });
"""
if tests_new.count(old_unlink_test) != 1:
    raise SystemExit("ABORT: unlink test anchor mismatch. No files changed.")
tests_new = tests_new.replace(old_unlink_test, new_unlink_test, 1)

old_relink_test = """  test('relinking grants the new UID access and keeps the old UID denied', async () => {
    const oldChildDb = firestoreFor('child-a-auth');
    await assertSucceeds(
      updateDoc(doc(oldChildDb, 'parents/parent-a/children/child-a'), {
        linkedAuthUid: null,
        linkedDevice: false,
      }),
    );
    await simulateCallableClaim('parent-a', 'child-a', 'child-a-new-auth');

    const newChildDb = firestoreFor('child-a-new-auth');
    await assertSucceeds(
      updateDoc(doc(newChildDb, conversationPath), {
        typingChildId: 'child-a',
      }),
    );
    await assertFails(
      updateDoc(doc(oldChildDb, conversationPath), {
        typingChildId: null,
      }),
    );
  });
"""
new_relink_test = """  test('relinking grants the new UID access and keeps the old UID denied', async () => {
    const oldChildDb = firestoreFor('child-a-auth');
    await assertSucceeds(
      updateDoc(doc(oldChildDb, 'parents/parent-a/children/child-a'), {
        linkedAuthUid: null,
        linkedDevice: false,
      }),
    );
    await simulateCallableClaim('parent-a', 'child-a', 'child-a-new-auth');

    const newChildDb = firestoreFor('child-a-new-auth');
    await assertSucceeds(
      updateDoc(doc(newChildDb, conversationPath), {
        typingChildId: 'child-a',
        typingAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(oldChildDb, conversationPath), {
        typingChildId: 'child-a',
        typingAt: serverTimestamp(),
      }),
    );
  });
"""
if tests_new.count(old_relink_test) != 1:
    raise SystemExit("ABORT: relink test anchor mismatch. No files changed.")
tests_new = tests_new.replace(old_relink_test, new_relink_test, 1)

# Final guards before writing anything.
if "function validTypingUpdate(conversation)" in rules_new:
    raise SystemExit("ABORT: old typing dispatcher still present. No files changed.")
if "function validConversationUpdate(conversation)" not in rules_new:
    raise SystemExit("ABORT: consolidated conversation helper missing. No files changed.")
if rules_new.count("request.resource.data.diff(resource.data).affectedKeys()") != 2:
    # One use is in validConversationUpdate; one remains in childLinkageResetOnly.
    raise SystemExit(
        "ABORT: unexpected affectedKeys() count after rewrite. No files changed."
    )

rules_path.write_text(rules_new)
test_path.write_text(tests_new)

print("Applied typing expression-budget correction.")
print("Modified only:")
print("  firestore.rules")
print("  test/firestore.rules.test.js")
print("lib/main.dart transaction left unchanged.")
