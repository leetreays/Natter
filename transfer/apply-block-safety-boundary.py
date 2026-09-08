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

# Refuse to run against a stale/pre-hardening rules file.
required_markers = [
    'allow update: if isLinkedConversationParticipant(resource.data)',
    'function validNewMessage(conversation) {',
    '&& isLinkedMessageSender(conversation, request.resource.data);',
]
for marker in required_markers:
    if marker not in rules:
        raise SystemExit(
            f'ABORT: authoritative security marker missing: {marker!r}. '
            'No files were written.'
        )

participant_helper = """    function isLinkedConversationParticipant(conversation) {
      return isLinkedParticipantAt(conversation, 0)
        || isLinkedParticipantAt(conversation, 1);
    }
"""

block_helpers = participant_helper + """

    function conversationAllowsNewMessages(conversation) {
      return !conversation.keys().hasAny(['blockedByChildIds'])
        || (
          conversation.blockedByChildIds is list
          && conversation.blockedByChildIds.size() == 0
        );
    }

    function validOneToOneParticipantMapping(conversation) {
      return conversation.participantChildIds is list
        && conversation.participantParentIds is list
        && conversation.participantChildIds.size() == 2
        && conversation.participantParentIds.size() == 2
        && conversation.participantChildIds[0] is string
        && conversation.participantChildIds[1] is string
        && conversation.participantParentIds[0] is string
        && conversation.participantParentIds[1] is string
        && conversation.participantChildIds[0].size() > 0
        && conversation.participantChildIds[1].size() > 0
        && conversation.participantParentIds[0].size() > 0
        && conversation.participantParentIds[1].size() > 0
        && conversation.participantChildIds[0]
          != conversation.participantChildIds[1];
    }

    function validBlockedByChildIdsList(conversation, blockedChildIds) {
      return blockedChildIds is list
        && blockedChildIds.size() == blockedChildIds.toSet().size()
        && blockedChildIds.toSet().hasOnly(
          conversation.participantChildIds
        );
    }

    function validSelfBlockChangeFromMissingAt(
      conversation,
      newBlockedChildIds,
      index
    ) {
      return isLinkedParticipantAt(conversation, index)
        && newBlockedChildIds.toSet().hasOnly([
          conversation.participantChildIds[index]
        ]);
    }

    function validSelfBlockChangeFromListAt(
      conversation,
      oldBlockedChildIds,
      newBlockedChildIds,
      index,
      otherIndex
    ) {
      return isLinkedParticipantAt(conversation, index)
        && (
          oldBlockedChildIds.toSet().hasAny([
            conversation.participantChildIds[otherIndex]
          ])
          ==
          newBlockedChildIds.toSet().hasAny([
            conversation.participantChildIds[otherIndex]
          ])
        );
    }

    function validSelfBlockedByChildIdsChangeAt(
      conversation,
      index,
      otherIndex
    ) {
      return validOneToOneParticipantMapping(conversation)
        && request.resource.data.keys().hasAny(['blockedByChildIds'])
        && validBlockedByChildIdsList(
          conversation,
          request.resource.data.blockedByChildIds
        )
        && (
          (
            !resource.data.keys().hasAny(['blockedByChildIds'])
            && validSelfBlockChangeFromMissingAt(
              conversation,
              request.resource.data.blockedByChildIds,
              index
            )
          )
          || (
            resource.data.keys().hasAny(['blockedByChildIds'])
            && validBlockedByChildIdsList(
              conversation,
              resource.data.blockedByChildIds
            )
            && validSelfBlockChangeFromListAt(
              conversation,
              resource.data.blockedByChildIds,
              request.resource.data.blockedByChildIds,
              index,
              otherIndex
            )
          )
        );
    }

    function validBlockedByChildIdsUpdate(conversation) {
      return !request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['blockedByChildIds'])
        || validSelfBlockedByChildIdsChangeAt(conversation, 0, 1)
        || validSelfBlockedByChildIdsChangeAt(conversation, 1, 0);
    }
"""

rules = replace_once(
    rules,
    participant_helper,
    block_helpers,
    'participant-helper',
)

rules = replace_once(
    rules,
    """    function validNewMessage(conversation) {
      return request.resource.data.keys().hasOnly([
""",
    """    function validNewMessage(conversation) {
      return conversationAllowsNewMessages(conversation)
        && request.resource.data.keys().hasOnly([
""",
    'validNewMessage',
)

rules = replace_once(
    rules,
    """      allow update: if isLinkedConversationParticipant(resource.data)
        && conversationParticipantsUnchanged();
""",
    """      allow update: if isLinkedConversationParticipant(resource.data)
        && conversationParticipantsUnchanged()
        && validBlockedByChildIdsUpdate(resource.data);
""",
    'conversation-update-rule',
)

message_doc_helper = """function messageDoc(db, messageId) {
  return doc(db, `conversations/${conversationId}/messages/${messageId}`);
}
"""

new_test_helpers = message_doc_helper + """

async function seedBlockedByChildIds(value) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await updateDoc(
      doc(context.firestore(), `conversations/${conversationId}`),
      {blockedByChildIds: value},
    );
  });
}

async function createValidMessage({
  authUid,
  messageId,
  childId = 'child-a',
  parentId = 'parent-a',
  childName = 'Child A',
  isFlagged = false,
}) {
  const db = firestoreFor(authUid);
  return setDoc(
    messageDoc(db, messageId),
    validMessageData({
      childId,
      parentId,
      childName,
      isFlagged,
    }),
  );
}
"""

tests = replace_once(
    tests,
    message_doc_helper,
    new_test_helpers,
    'messageDoc-helper',
)

block_suite = r"""
describe('conversation block ownership', () => {
  const conversationRefFor = (db, id = conversationId) =>
    doc(db, `conversations/${id}`);

  test('Child A can add itself when block state is missing', async () => {
    const db = firestoreFor('child-a-auth');
    await assertSucceeds(
      updateDoc(conversationRefFor(db), {
        blockedByChildIds: ['child-a'],
      }),
    );
  });

  test('Child A can add itself to an empty block list', async () => {
    await seedBlockedByChildIds([]);
    const db = firestoreFor('child-a-auth');
    await assertSucceeds(
      updateDoc(conversationRefFor(db), {
        blockedByChildIds: ['child-a'],
      }),
    );
  });

  test('Child A preserves Child B while adding itself', async () => {
    await seedBlockedByChildIds(['child-b']);
    const db = firestoreFor('child-a-auth');
    await assertSucceeds(
      updateDoc(conversationRefFor(db), {
        blockedByChildIds: ['child-b', 'child-a'],
      }),
    );
  });

  test('Child A can remove only itself', async () => {
    await seedBlockedByChildIds(['child-a']);
    const db = firestoreFor('child-a-auth');
    await assertSucceeds(
      updateDoc(conversationRefFor(db), {
        blockedByChildIds: [],
      }),
    );
  });

  test('Child A preserves Child B while removing itself', async () => {
    await seedBlockedByChildIds(['child-a', 'child-b']);
    const db = firestoreFor('child-a-auth');
    await assertSucceeds(
      updateDoc(conversationRefFor(db), {
        blockedByChildIds: ['child-b'],
      }),
    );
  });

  test('Child A cannot add Child B block state', async () => {
    await seedBlockedByChildIds([]);
    const db = firestoreFor('child-a-auth');
    await assertFails(
      updateDoc(conversationRefFor(db), {
        blockedByChildIds: ['child-b'],
      }),
    );
  });

  test('Child A cannot remove Child B block state', async () => {
    await seedBlockedByChildIds(['child-b']);
    const db = firestoreFor('child-a-auth');
    await assertFails(
      updateDoc(conversationRefFor(db), {
        blockedByChildIds: [],
      }),
    );
  });

  for (const [label, blockedByChildIds] of [
    ['Child C', ['child-c']],
    ['an arbitrary child ID', ['not-a-participant']],
    ['a non-string value', [123]],
    ['duplicate values', ['child-a', 'child-a']],
    ['forged cross-child state', ['child-b']],
  ]) {
    test(`Child A cannot introduce ${label}`, async () => {
      const db = firestoreFor('child-a-auth');
      await assertFails(
        updateDoc(conversationRefFor(db), {blockedByChildIds}),
      );
    });
  }

  test('Child B can add and remove only itself', async () => {
    await seedBlockedByChildIds(['child-a']);
    const db = firestoreFor('child-b-auth');

    await assertSucceeds(
      updateDoc(conversationRefFor(db), {
        blockedByChildIds: ['child-a', 'child-b'],
      }),
    );
    await assertSucceeds(
      updateDoc(conversationRefFor(db), {
        blockedByChildIds: ['child-a'],
      }),
    );
  });

  test('Child B cannot add Child A block state', async () => {
    await seedBlockedByChildIds([]);
    const db = firestoreFor('child-b-auth');
    await assertFails(
      updateDoc(conversationRefFor(db), {
        blockedByChildIds: ['child-a'],
      }),
    );
  });

  test('Child B cannot remove Child A block state', async () => {
    await seedBlockedByChildIds(['child-a']);
    const db = firestoreFor('child-b-auth');
    await assertFails(
      updateDoc(conversationRefFor(db), {
        blockedByChildIds: [],
      }),
    );
  });

  test('Child B cannot introduce unrelated or malformed IDs', async () => {
    const db = firestoreFor('child-b-auth');
    for (const blockedByChildIds of [
      ['child-c'],
      ['not-a-participant'],
      [123],
      ['child-b', 'child-b'],
    ]) {
      await assertFails(
        updateDoc(conversationRefFor(db), {blockedByChildIds}),
      );
    }
  });

  test('Child A can update another field while valid block state is unchanged',
      async () => {
        await seedBlockedByChildIds(['child-b']);
        const db = firestoreFor('child-a-auth');
        await assertSucceeds(
          updateDoc(conversationRefFor(db), {
            spikeHeat: 2,
          }),
        );
      });

  test('Child B can update another field while valid block state is unchanged',
      async () => {
        await seedBlockedByChildIds(['child-a']);
        const db = firestoreFor('child-b-auth');
        await assertSucceeds(
          updateDoc(conversationRefFor(db), {
            typingChildId: 'child-b',
          }),
        );
      });

  test('another field can update while malformed block state is untouched',
      async () => {
        await seedBlockedByChildIds('malformed');
        const db = firestoreFor('child-a-auth');
        await assertSucceeds(
          updateDoc(conversationRefFor(db), {
            spikeHeat: 3,
          }),
        );
      });

  test('a child cannot repair malformed block state', async () => {
    await seedBlockedByChildIds('malformed');
    const db = firestoreFor('child-a-auth');
    await assertFails(
      updateDoc(conversationRefFor(db), {
        blockedByChildIds: [],
      }),
    );
  });

  test('block ownership remains tied to current linkage', async () => {
    const oldChildDb = firestoreFor('child-a-auth');
    await assertSucceeds(
      updateDoc(
        doc(oldChildDb, 'parents/parent-a/children/child-a'),
        {
          linkedAuthUid: null,
          linkedDevice: false,
        },
      ),
    );

    await assertFails(
      updateDoc(conversationRefFor(oldChildDb), {
        blockedByChildIds: ['child-a'],
      }),
    );

    await simulateCallableClaim(
      'parent-a',
      'child-a',
      'child-a-new-auth',
    );

    const newChildDb = firestoreFor('child-a-new-auth');
    await assertSucceeds(
      updateDoc(conversationRefFor(newChildDb), {
        blockedByChildIds: ['child-a'],
      }),
    );
    await assertFails(
      updateDoc(conversationRefFor(oldChildDb), {
        blockedByChildIds: [],
      }),
    );
  });

  test('participant identity cannot change with a valid self-block operation',
      async () => {
        const db = firestoreFor('child-a-auth');
        await assertFails(
          updateDoc(conversationRefFor(db), {
            blockedByChildIds: ['child-a'],
            participantChildIds: ['child-a', 'child-c'],
          }),
        );
      });

  test('self-only ownership works with reversed participant ordering',
      async () => {
        const db = firestoreFor('child-a-auth');
        await assertSucceeds(
          updateDoc(conversationRefFor(db, reversedConversationId), {
            blockedByChildIds: ['child-a'],
          }),
        );
        await assertFails(
          updateDoc(conversationRefFor(db, reversedConversationId), {
            blockedByChildIds: ['child-b'],
          }),
        );
      });
});

"""

tests = replace_once(
    tests,
    "describe('child-scoped conversation references', () => {\n",
    block_suite + "describe('child-scoped conversation references', () => {\n",
    'block-suite-insertion',
)

message_block_tests = r"""
  test('both children can create messages with an empty block list',
      async () => {
        await seedBlockedByChildIds([]);

        await assertSucceeds(
          createValidMessage({
            authUid: 'child-a-auth',
            messageId: 'child-a-empty-block-list',
          }),
        );
        await assertSucceeds(
          createValidMessage({
            authUid: 'child-b-auth',
            messageId: 'child-b-empty-block-list',
            childId: 'child-b',
            parentId: 'parent-b',
            childName: 'Child B',
          }),
        );
      });

  test('Child A cannot send when Child B has blocked', async () => {
    await seedBlockedByChildIds(['child-b']);
    await assertFails(
      createValidMessage({
        authUid: 'child-a-auth',
        messageId: 'blocked-by-child-b',
      }),
    );
  });

  test('Child B cannot send while its own block is active', async () => {
    await seedBlockedByChildIds(['child-b']);
    await assertFails(
      createValidMessage({
        authUid: 'child-b-auth',
        messageId: 'child-b-own-block',
        childId: 'child-b',
        parentId: 'parent-b',
        childName: 'Child B',
      }),
    );
  });

  test('neither child can send when Child A has blocked', async () => {
    await seedBlockedByChildIds(['child-a']);

    await assertFails(
      createValidMessage({
        authUid: 'child-a-auth',
        messageId: 'child-a-blocked-by-a',
      }),
    );
    await assertFails(
      createValidMessage({
        authUid: 'child-b-auth',
        messageId: 'child-b-blocked-by-a',
        childId: 'child-b',
        parentId: 'parent-b',
        childName: 'Child B',
      }),
    );
  });

  test('neither child can send when both have blocked', async () => {
    await seedBlockedByChildIds(['child-a', 'child-b']);

    await assertFails(
      createValidMessage({
        authUid: 'child-a-auth',
        messageId: 'child-a-both-blocked',
      }),
    );
    await assertFails(
      createValidMessage({
        authUid: 'child-b-auth',
        messageId: 'child-b-both-blocked',
        childId: 'child-b',
        parentId: 'parent-b',
        childName: 'Child B',
      }),
    );
  });

  test('Protected Delivery cannot bypass a block', async () => {
    await seedBlockedByChildIds(['child-b']);
    await assertFails(
      createValidMessage({
        authUid: 'child-a-auth',
        messageId: 'flagged-block-bypass',
        isFlagged: true,
      }),
    );
  });

  test('blocking does not prevent a receiver action on an existing flagged message',
      async () => {
        await seedBlockedByChildIds(['child-b']);
        const db = firestoreFor('child-b-auth');
        await assertSucceeds(
          updateDoc(messageDoc(db, 'flagged-message'), {
            receiverAction: 'read',
            receiverActionAt: serverTimestamp(),
            receiverActionByChildId: 'child-b',
          }),
        );
      });

  for (const [label, malformedState] of [
    ['null', null],
    ['string', 'child-b'],
    ['non-string-list-entry', [123]],
    ['unrelated-child-id', ['child-c']],
    ['duplicate-ids', ['child-b', 'child-b']],
  ]) {
    test(`message creation fails closed for ${label} block state`,
        async () => {
          await seedBlockedByChildIds(malformedState);
          await assertFails(
            createValidMessage({
              authUid: 'child-a-auth',
              messageId: `malformed-block-${label}`,
            }),
          );
        });
  }

  test('unblocking restores message-create permission', async () => {
    await seedBlockedByChildIds(['child-b']);

    const childBDb = firestoreFor('child-b-auth');
    await assertSucceeds(
      updateDoc(
        doc(childBDb, `conversations/${conversationId}`),
        {blockedByChildIds: []},
      ),
    );

    await assertSucceeds(
      createValidMessage({
        authUid: 'child-a-auth',
        messageId: 'message-after-unblock',
      }),
    );
  });

"""

tests = replace_once(
    tests,
    "describe('message creation authorization', () => {\n",
    "describe('message creation authorization', () => {\n" + message_block_tests,
    'message-block-tests-insertion',
)

# Write only after every authoritative anchor has been validated and transformed.
RULES_PATH.write_text(rules)
TESTS_PATH.write_text(tests)

print('Applied block safety boundary to:')
print('  firestore.rules')
print('  test/firestore.rules.test.js')
print('No files were staged, committed, pushed, or deployed.')
