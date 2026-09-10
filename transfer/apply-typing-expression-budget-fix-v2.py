#!/usr/bin/env python3
from pathlib import Path
import subprocess
import re

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

# This correction is only valid after the first typing-ownership patch is already applied.
for marker in [
    "function validTypingSetAt(conversation, index)",
    "function validTypingClearAt(conversation, index)",
    "function validTypingUpdate(conversation)",
    "&& validTypingUpdate(resource.data);",
]:
    if marker not in rules:
        raise SystemExit(
            f"ABORT: expected applied typing-patch marker not found: {marker}. No files changed."
        )

if "await FirebaseFirestore.instance.runTransaction((transaction) async {" not in main:
    raise SystemExit("ABORT: transactional clearTyping() marker not found. No files changed.")

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

pattern = re.compile(
    r"    function conversationCanonicalIdentityUnchanged\(\) \{.*?"
    r"    function validTypingUpdate\(conversation\) \{.*?^    \}\n",
    re.S | re.M,
)
replacement = """    function validTypingChangeAt(conversation, index) {
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
rules_new, n = pattern.subn(replacement, rules_new, count=1)
if n != 1:
    raise SystemExit("ABORT: canonical/typing helper block mismatch. No files changed.")

old_update = """      allow update: if isLinkedConversationParticipant(resource.data)
        && conversationCanonicalIdentityUnchanged()
        && validBlockedByChildIdsUpdate(resource.data)
        && validTypingUpdate(resource.data);
"""
new_update = """      allow update: if validConversationUpdate(resource.data);
"""
if rules_new.count(old_update) != 1:
    raise SystemExit("ABORT: conversation-update anchor mismatch. No files changed.")
rules_new = rules_new.replace(old_update, new_update, 1)

# Modernise the three pre-hardening positive/linkage typing payloads.
old = """      updateDoc(doc(db, conversationPath), {
        typingChildId: 'child-a',
        typingAt: new Date('2026-09-08T10:00:00Z'),
      }),
"""
new = """      updateDoc(doc(db, conversationPath), {
        typingChildId: 'child-a',
        typingAt: serverTimestamp(),
      }),
"""
if tests.count(old) != 1:
    raise SystemExit("ABORT: old Child A typing-state test anchor mismatch. No files changed.")
tests_new = tests.replace(old, new, 1)

old_unlink = """  test('unlinking Child A immediately revokes conversation update access', async () => {
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
new_unlink = """  test('unlinking Child A immediately revokes conversation update access', async () => {
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
if tests_new.count(old_unlink) != 1:
    raise SystemExit("ABORT: unlink test anchor mismatch. No files changed.")
tests_new = tests_new.replace(old_unlink, new_unlink, 1)

old_relink = """  test('relinking grants the new UID access and keeps the old UID denied', async () => {
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
new_relink = """  test('relinking grants the new UID access and keeps the old UID denied', async () => {
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
if tests_new.count(old_relink) != 1:
    raise SystemExit("ABORT: relink test anchor mismatch. No files changed.")
tests_new = tests_new.replace(old_relink, new_relink, 1)

# Final guards before writing.
for forbidden in [
    "function conversationCanonicalIdentityUnchanged()",
    "function validTypingSetAt(conversation, index)",
    "function validTypingClearAt(conversation, index)",
    "function validTypingUpdate(conversation)",
]:
    if forbidden in rules_new:
        raise SystemExit(f"ABORT: old helper still present: {forbidden}. No files changed.")
if "function validConversationUpdate(conversation)" not in rules_new:
    raise SystemExit("ABORT: consolidated conversation helper missing. No files changed.")
if rules_new.count("request.resource.data.diff(resource.data).affectedKeys()") != 3:
    raise SystemExit("ABORT: unexpected affectedKeys() count after rewrite. No files changed.")

rules_path.write_text(rules_new)
test_path.write_text(tests_new)

print("Applied revised typing expression-budget correction.")
print("Modified only:")
print("  firestore.rules")
print("  test/firestore.rules.test.js")
print("lib/main.dart transaction left unchanged.")
