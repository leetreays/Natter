#!/usr/bin/env python3
from pathlib import Path

RULES_PATH = Path('firestore.rules')
TESTS_PATH = Path('test/firestore.rules.test.js')


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f'ABORT: expected exactly one {label} anchor, found {count}. '
            'No files were written.'
        )
    return text.replace(old, new, 1)


if not RULES_PATH.exists() or not TESTS_PATH.exists():
    raise SystemExit('ABORT: run this from the Natter repository root.')

rules = RULES_PATH.read_text()
tests = TESTS_PATH.read_text()

# Refuse to run against a stale/pre-block-safety rules file.
required_rule_markers = [
    'function conversationParticipantsUnchanged() {',
    '&& validBlockedByChildIdsUpdate(resource.data);',
    'function conversationAllowsNewMessages(conversation) {',
    '&& isLinkedMessageSender(conversation, request.resource.data);',
]
for marker in required_rule_markers:
    if marker not in rules:
        raise SystemExit(
            f'ABORT: authoritative security marker missing: {marker!r}. '
            'No files were written.'
        )

required_test_markers = [
    "describe('conversation block ownership', () => {",
    "test('Child A cannot delete Child B block state'",
    "describe('message creation authorization', () => {",
    "describe('child-scoped conversation references', () => {",
]
for marker in required_test_markers:
    if marker not in tests:
        raise SystemExit(
            f'ABORT: authoritative test marker missing: {marker!r}. '
            'No files were written.'
        )

old_helper = """    function conversationParticipantsUnchanged() {
      return request.resource.data.participantChildIds
          == resource.data.participantChildIds
        && request.resource.data.participantParentIds
          == resource.data.participantParentIds;
    }"""

new_helper = """    function conversationCanonicalIdentityUnchanged() {
      return !request.resource.data.diff(resource.data).affectedKeys().hasAny([
        'friendshipId',
        'participantChildIds',
        'participantParentIds',
        'participantNames',
        'status',
        'createdAt'
      ]);
    }"""

rules = replace_once(
    rules,
    old_helper,
    new_helper,
    'conversation participant helper',
)

old_update_rule = """      allow update: if isLinkedConversationParticipant(resource.data)
        && conversationParticipantsUnchanged()
        && validBlockedByChildIdsUpdate(resource.data);"""

new_update_rule = """      allow update: if isLinkedConversationParticipant(resource.data)
        && conversationCanonicalIdentityUnchanged()
        && validBlockedByChildIdsUpdate(resource.data);"""

rules = replace_once(
    rules,
    old_update_rule,
    new_update_rule,
    'conversation update rule',
)

seed_block_helper = """async function seedBlockedByChildIds(value) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await updateDoc(
      doc(context.firestore(), `conversations/${conversationId}`),
      {blockedByChildIds: value},
    );
  });
}
"""

seed_canonical_helper = seed_block_helper + """
async function seedCanonicalConversationIdentity() {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await updateDoc(
      doc(context.firestore(), `conversations/${conversationId}`),
      {
        friendshipId: conversationId,
        participantNames: ['Child A', 'Child B'],
        createdAt: new Date('2026-09-01T00:00:00Z'),
      },
    );
  });
}
"""

tests = replace_once(
    tests,
    seed_block_helper,
    seed_canonical_helper,
    'seedBlockedByChildIds helper',
)

suite_anchor = "describe('child-scoped conversation references', () => {"

canonical_suite = """describe('canonical conversation identity immutability', () => {
  const conversationRefFor = (db, id = conversationId) =>
    doc(db, `conversations/${id}`);

  test('linked children cannot replace canonical conversation fields',
    async () => {
      await seedCanonicalConversationIdentity();

      const replacements = [
        ['friendshipId', 'different-friendship'],
        ['participantChildIds', ['child-a', 'child-c']],
        ['participantParentIds', ['parent-a', 'parent-c']],
        ['participantNames', ['Renamed Child A', 'Child B']],
        ['status', 'closed'],
        ['createdAt', new Date('2030-01-01T00:00:00Z')],
      ];

      for (const authUid of ['child-a-auth', 'child-b-auth']) {
        const db = firestoreFor(authUid);

        for (const [field, value] of replacements) {
          await assertFails(
            updateDoc(conversationRefFor(db), {
              [field]: value,
            }),
          );
        }
      }
    });

  test('linked children cannot delete canonical conversation fields',
    async () => {
      await seedCanonicalConversationIdentity();

      for (const authUid of ['child-a-auth', 'child-b-auth']) {
        const db = firestoreFor(authUid);

        for (const field of [
          'friendshipId',
          'participantNames',
          'status',
          'createdAt',
        ]) {
          await assertFails(
            updateDoc(conversationRefFor(db), {
              [field]: deleteField(),
            }),
          );
        }
      }
    });

  test('a missing legacy canonical field may remain missing but cannot be added',
    async () => {
      await testEnvironment.withSecurityRulesDisabled(async (context) => {
        await updateDoc(
          conversationRefFor(context.firestore()),
          {
            friendshipId: deleteField(),
          },
        );
      });

      const childADb = firestoreFor('child-a-auth');
      await assertSucceeds(
        updateDoc(conversationRefFor(childADb), {
          spikeHeat: 2,
        }),
      );
      await assertFails(
        updateDoc(conversationRefFor(childADb), {
          friendshipId: conversationId,
        }),
      );

      const childBDb = firestoreFor('child-b-auth');
      await assertSucceeds(
        updateDoc(conversationRefFor(childBDb), {
          typingChildId: 'child-b',
        }),
      );
      await assertFails(
        updateDoc(conversationRefFor(childBDb), {
          friendshipId: conversationId,
        }),
      );
    });

  test('canonical mutation cannot be hidden inside an otherwise valid update',
    async () => {
      await seedCanonicalConversationIdentity();

      const childADb = firestoreFor('child-a-auth');
      await assertFails(
        updateDoc(conversationRefFor(childADb), {
          blockedByChildIds: ['child-a'],
          friendshipId: 'different-friendship',
        }),
      );

      const childBDb = firestoreFor('child-b-auth');
      await assertFails(
        updateDoc(conversationRefFor(childBDb), {
          spikeHeat: 3,
          status: 'closed',
        }),
      );
    });

  test('canonical hardening preserves reversed-order participant updates',
    async () => {
      const childADb = firestoreFor('child-a-auth');
      await assertSucceeds(
        updateDoc(
          conversationRefFor(childADb, reversedConversationId),
          {
            spikeHeat: 1,
          },
        ),
      );

      const childBDb = firestoreFor('child-b-auth');
      await assertSucceeds(
        updateDoc(
          conversationRefFor(childBDb, reversedConversationId),
          {
            typingChildId: 'child-b',
          },
        ),
      );
    });
});

"""

tests = replace_once(
    tests,
    suite_anchor,
    canonical_suite + suite_anchor,
    'child-scoped conversation references suite',
)

# Only write after all anchors have been validated and replacements completed.
RULES_PATH.write_text(rules)
TESTS_PATH.write_text(tests)

print('Applied canonical conversation identity immutability.')
print('Changed only:')
print('  firestore.rules')
print('  test/firestore.rules.test.js')
