#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

EXPECTED_HEAD = "180079104febef071bef4ff3e7a82226a39ff738"

root = Path.cwd()
if not (root / "firestore.rules").exists() or not (root / "lib/main.dart").exists():
    raise SystemExit("ABORT: run this from the Natter repository root.")

head = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
if head != EXPECTED_HEAD:
    raise SystemExit(
        f"ABORT: expected HEAD {EXPECTED_HEAD}, found {head}. No files changed."
    )

rules_path = root / "firestore.rules"
main_path = root / "lib/main.dart"
test_path = root / "test/firestore.rules.test.js"

rules = rules_path.read_text()
main = main_path.read_text()
tests = test_path.read_text()

if "function validTypingUpdate(conversation)" in rules:
    raise SystemExit("ABORT: typing ownership rules already appear to be present.")
if "transaction-safe typing ownership" in tests.lower():
    raise SystemExit("ABORT: typing ownership tests already appear to be present.")

rules_anchor = """    function conversationCanonicalIdentityUnchanged() {
      return !request.resource.data.diff(resource.data).affectedKeys().hasAny([
        'friendshipId',
        'participantChildIds',
        'participantParentIds',
        'participantNames',
        'status',
        'createdAt'
      ]);
    }
"""

rules_replacement = rules_anchor + """

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

if rules.count(rules_anchor) != 1:
    raise SystemExit("ABORT: canonical-rule anchor mismatch. No files changed.")
rules_new = rules.replace(rules_anchor, rules_replacement, 1)

update_anchor = """      allow update: if isLinkedConversationParticipant(resource.data)
        && conversationCanonicalIdentityUnchanged()
        && validBlockedByChildIdsUpdate(resource.data);
"""
update_replacement = """      allow update: if isLinkedConversationParticipant(resource.data)
        && conversationCanonicalIdentityUnchanged()
        && validBlockedByChildIdsUpdate(resource.data)
        && validTypingUpdate(resource.data);
"""
if rules_new.count(update_anchor) != 1:
    raise SystemExit("ABORT: conversation-update anchor mismatch. No files changed.")
rules_new = rules_new.replace(update_anchor, update_replacement, 1)

main_anchor = """Future<void> clearTyping({
  required String conversationId,
}) async {
  if (!hasActiveChildSession) return;

  await conversationsRef().doc(conversationId).set({
    'typingChildId': null,
  }, SetOptions(merge: true));
}
"""
main_replacement = """Future<void> clearTyping({
  required String conversationId,
}) async {
  if (!hasActiveChildSession) return;

  final childId = activeChildId;
  if (childId == null || childId.trim().isEmpty) return;

  final conversationRef = conversationsRef().doc(conversationId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(conversationRef);
    final data = snapshot.data();

    if (data == null || data['typingChildId'] != childId) {
      return;
    }

    transaction.update(conversationRef, {
      'typingChildId': null,
      'typingAt': null,
    });
  });
}
"""
if main.count(main_anchor) != 1:
    raise SystemExit("ABORT: clearTyping anchor mismatch. No files changed.")
main_new = main.replace(main_anchor, main_replacement, 1)

import_anchor = """  orderBy,
  query,
  serverTimestamp,
"""
import_replacement = """  orderBy,
  query,
  runTransaction,
  serverTimestamp,
"""
if tests.count(import_anchor) != 1:
    raise SystemExit("ABORT: test import anchor mismatch. No files changed.")
tests_new = tests.replace(import_anchor, import_replacement, 1)

helper_anchor = """async function createValidMessage({
"""
helper_block = """async function seedTypingState(
  {
    typingChildId,
    typingAt,
  },
  id = conversationId,
) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await updateDoc(
      doc(context.firestore(), `conversations/${id}`),
      {
        typingChildId,
        typingAt,
      },
    );
  });
}

function setTypingAs(db, childId, id = conversationId) {
  return updateDoc(doc(db, `conversations/${id}`), {
    typingChildId: childId,
    typingAt: serverTimestamp(),
  });
}

function clearTypingAs(db, id = conversationId) {
  return updateDoc(doc(db, `conversations/${id}`), {
    typingChildId: null,
    typingAt: null,
  });
}

""" + helper_anchor
if tests_new.count(helper_anchor) != 1:
    raise SystemExit("ABORT: createValidMessage anchor mismatch. No files changed.")
tests_new = tests_new.replace(helper_anchor, helper_block, 1)

suite_anchor = """describe('child-scoped conversation references', () => {
"""

suite = r"""describe('conversation typing ownership', () => {
  const conversationRefFor = (db, id = conversationId) =>
    doc(db, `conversations/${id}`);

  test('both children can set themselves when typing fields are missing',
    async () => {
      const childADb = firestoreFor('child-a-auth');
      await assertSucceeds(setTypingAs(childADb, 'child-a'));

      await testEnvironment.withSecurityRulesDisabled(async (context) => {
        await updateDoc(
          conversationRefFor(context.firestore()),
          {
            typingChildId: deleteField(),
            typingAt: deleteField(),
          },
        );
      });

      const childBDb = firestoreFor('child-b-auth');
      await assertSucceeds(setTypingAs(childBDb, 'child-b'));
    });

  test('Child A can set itself from null and stale timestamp state',
    async () => {
      await seedTypingState({
        typingChildId: null,
        typingAt: new Date('2026-01-01T00:00:00Z'),
      });

      const db = firestoreFor('child-a-auth');
      await assertSucceeds(setTypingAs(db, 'child-a'));
    });

  test('both children can refresh their own typing state', async () => {
    await seedTypingState({
      typingChildId: 'child-a',
      typingAt: new Date('2026-01-01T00:00:00Z'),
    });

    const childADb = firestoreFor('child-a-auth');
    await assertSucceeds(setTypingAs(childADb, 'child-a'));

    await seedTypingState({
      typingChildId: 'child-b',
      typingAt: new Date('2026-01-01T00:00:00Z'),
    });

    const childBDb = firestoreFor('child-b-auth');
    await assertSucceeds(setTypingAs(childBDb, 'child-b'));
  });

  test('latest legitimate typing event wins between participants',
    async () => {
      await seedTypingState({
        typingChildId: 'child-b',
        typingAt: new Date('2026-01-01T00:00:00Z'),
      });

      const childADb = firestoreFor('child-a-auth');
      await assertSucceeds(setTypingAs(childADb, 'child-a'));

      const childBDb = firestoreFor('child-b-auth');
      await assertSucceeds(setTypingAs(childBDb, 'child-b'));
    });

  test('each child can clear only its own stored typing state', async () => {
    await seedTypingState({
      typingChildId: 'child-a',
      typingAt: new Date('2026-01-01T00:00:00Z'),
    });

    const childADb = firestoreFor('child-a-auth');
    await assertSucceeds(clearTypingAs(childADb));

    await seedTypingState({
      typingChildId: 'child-b',
      typingAt: new Date('2026-01-01T00:00:00Z'),
    });

    const childBDb = firestoreFor('child-b-auth');
    await assertSucceeds(clearTypingAs(childBDb));
  });

  test('a participant cannot claim another or malformed child identity',
    async () => {
      const childADb = firestoreFor('child-a-auth');

      for (const typingChildId of [
        'child-b',
        'child-c',
        'not-a-participant',
        123,
      ]) {
        await assertFails(
          updateDoc(conversationRefFor(childADb), {
            typingChildId,
            typingAt: serverTimestamp(),
          }),
        );
      }

      const childBDb = firestoreFor('child-b-auth');

      for (const typingChildId of [
        'child-a',
        'child-c',
        'not-a-participant',
        123,
      ]) {
        await assertFails(
          updateDoc(conversationRefFor(childBDb), {
            typingChildId,
            typingAt: serverTimestamp(),
          }),
        );
      }
    });

  test('a participant cannot clear the other participant typing state',
    async () => {
      await seedTypingState({
        typingChildId: 'child-b',
        typingAt: new Date('2026-01-01T00:00:00Z'),
      });

      const childADb = firestoreFor('child-a-auth');
      await assertFails(clearTypingAs(childADb));

      await seedTypingState({
        typingChildId: 'child-a',
        typingAt: new Date('2026-01-01T00:00:00Z'),
      });

      const childBDb = firestoreFor('child-b-auth');
      await assertFails(clearTypingAs(childBDb));
    });

  test('a participant cannot forge or independently corrupt typingAt',
    async () => {
      await seedTypingState({
        typingChildId: 'child-a',
        typingAt: new Date('2026-01-01T00:00:00Z'),
      });

      const childADb = firestoreFor('child-a-auth');

      await assertFails(
        updateDoc(conversationRefFor(childADb), {
          typingChildId: 'child-a',
          typingAt: new Date('2030-01-01T00:00:00Z'),
        }),
      );

      await assertFails(
        updateDoc(conversationRefFor(childADb), {
          typingAt: new Date('2030-01-01T00:00:00Z'),
        }),
      );

      await assertFails(
        updateDoc(conversationRefFor(childADb), {
          typingAt: deleteField(),
        }),
      );
    });

  test('partial typing clears are denied', async () => {
    await seedTypingState({
      typingChildId: 'child-a',
      typingAt: new Date('2026-01-01T00:00:00Z'),
    });

    const childADb = firestoreFor('child-a-auth');

    await assertFails(
      updateDoc(conversationRefFor(childADb), {
        typingChildId: null,
      }),
    );

    await assertFails(
      updateDoc(conversationRefFor(childADb), {
        typingAt: null,
      }),
    );
  });

  test('unrelated updates remain permitted while typing state is unchanged',
    async () => {
      await seedTypingState({
        typingChildId: 'child-b',
        typingAt: new Date('2026-01-01T00:00:00Z'),
      });

      const childADb = firestoreFor('child-a-auth');
      await assertSucceeds(
        updateDoc(conversationRefFor(childADb), {
          spikeHeat: 2,
        }),
      );

      await assertSucceeds(
        updateDoc(conversationRefFor(childADb), {
          blockedByChildIds: ['child-a'],
        }),
      );
    });

  test('a valid typing operation cannot conceal canonical mutation',
    async () => {
      await seedCanonicalConversationIdentity();

      const childADb = firestoreFor('child-a-auth');
      await assertFails(
        updateDoc(conversationRefFor(childADb), {
          typingChildId: 'child-a',
          typingAt: serverTimestamp(),
          friendshipId: 'different-friendship',
        }),
      );
    });

  test('valid typing ownership works with reversed participant ordering',
    async () => {
      const childADb = firestoreFor('child-a-auth');
      await assertSucceeds(
        setTypingAs(childADb, 'child-a', reversedConversationId),
      );
      await assertSucceeds(
        clearTypingAs(childADb, reversedConversationId),
      );

      const childBDb = firestoreFor('child-b-auth');
      await assertSucceeds(
        setTypingAs(childBDb, 'child-b', reversedConversationId),
      );
      await assertSucceeds(
        clearTypingAs(childBDb, reversedConversationId),
      );
    });

  test('typing ownership follows current child linkage', async () => {
    await seedTypingState({
      typingChildId: 'child-a',
      typingAt: new Date('2026-01-01T00:00:00Z'),
    });

    await testEnvironment.withSecurityRulesDisabled(async (context) => {
      await updateDoc(
        doc(
          context.firestore(),
          'parents/parent-a/children/child-a',
        ),
        {
          linkedAuthUid: null,
          linkedDevice: false,
        },
      );
    });

    const oldChildDb = firestoreFor('child-a-auth');
    await assertFails(setTypingAs(oldChildDb, 'child-a'));
    await assertFails(clearTypingAs(oldChildDb));

    await simulateCallableClaim(
      'parent-a',
      'child-a',
      'child-a-new-auth',
    );

    const newChildDb = firestoreFor('child-a-new-auth');
    await assertSucceeds(setTypingAs(newChildDb, 'child-a'));
    await assertSucceeds(clearTypingAs(newChildDb));

    await assertFails(setTypingAs(oldChildDb, 'child-a'));
    await assertFails(clearTypingAs(oldChildDb));
  });

  test('a valid set recovers malformed historical typing state',
    async () => {
      const malformedStates = [
        {
          typingChildId: 'child-c',
          typingAt: 'bad',
        },
        {
          typingChildId: 123,
          typingAt: null,
        },
        {
          typingChildId: null,
          typingAt: new Date('2026-01-01T00:00:00Z'),
        },
      ];

      const childADb = firestoreFor('child-a-auth');

      for (const malformedState of malformedStates) {
        await seedTypingState(malformedState);
        await assertSucceeds(setTypingAs(childADb, 'child-a'));
      }
    });

  test('a participant cannot clear malformed or unowned typing state',
    async () => {
      const childADb = firestoreFor('child-a-auth');

      for (const malformedState of [
        {
          typingChildId: 'child-c',
          typingAt: 'bad',
        },
        {
          typingChildId: 123,
          typingAt: null,
        },
        {
          typingChildId: null,
          typingAt: new Date('2026-01-01T00:00:00Z'),
        },
      ]) {
        await seedTypingState(malformedState);
        await assertFails(clearTypingAs(childADb));
      }
    });

  test('transactional stale clear preserves the newer participant state',
    async () => {
      await seedTypingState({
        typingChildId: 'child-a',
        typingAt: new Date('2026-01-01T00:00:00Z'),
      });

      const childADb = firestoreFor('child-a-auth');
      const childBDb = firestoreFor('child-b-auth');
      const childAConversationRef = conversationRefFor(childADb);

      let releaseFirstAttempt;
      const firstAttemptMayContinue = new Promise((resolve) => {
        releaseFirstAttempt = resolve;
      });

      let reportFirstRead;
      const firstReadCompleted = new Promise((resolve) => {
        reportFirstRead = resolve;
      });

      let attempts = 0;

      const staleClear = runTransaction(childADb, async (transaction) => {
        const snapshot = await transaction.get(childAConversationRef);
        attempts += 1;

        if (attempts == 1) {
          reportFirstRead();
          await firstAttemptMayContinue;
        }

        if (snapshot.data()?.typingChildId != 'child-a') {
          return;
        }

        transaction.update(childAConversationRef, {
          typingChildId: null,
          typingAt: null,
        });
      });

      await firstReadCompleted;
      await assertSucceeds(setTypingAs(childBDb, 'child-b'));
      releaseFirstAttempt();

      await assertSucceeds(staleClear);
      assert.equal(attempts >= 2, true);

      const finalSnapshot = await assertSucceeds(
        getDoc(conversationRefFor(childBDb)),
      );
      assert.equal(finalSnapshot.data().typingChildId, 'child-b');
      assert.notEqual(finalSnapshot.data().typingAt, null);
    });
});

"""

if tests_new.count(suite_anchor) != 1:
    raise SystemExit("ABORT: child-scoped refs anchor mismatch. No files changed.")
tests_new = tests_new.replace(suite_anchor, suite + suite_anchor, 1)

# Write only after every guard and transformation has succeeded.
rules_path.write_text(rules_new)
main_path.write_text(main_new)
test_path.write_text(tests_new)

print("Applied transaction-safe typing ownership slice.")
print("Changed only:")
print("  firestore.rules")
print("  lib/main.dart")
print("  test/firestore.rules.test.js")
