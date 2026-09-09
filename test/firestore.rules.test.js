import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {after, before, beforeEach, describe, test} from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const projectId = 'natter-firestore-rules-test';
const conversationId = 'child-a_child-b';
const reversedConversationId = 'child-b_child-a';
const newlyLinkedConversationId = 'child-b_child-d';

let testEnvironment;

function firestoreFor(uid) {
  return testEnvironment.authenticatedContext(uid).firestore();
}

async function seedConversation() {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'parents/parent-a/children/child-a'), {
      linkedAuthUid: 'child-a-auth',
      linkedDevice: true,
      parentId: 'parent-a',
      accessCode: 'ACCESS-A',
      name: 'Child A',
      avatar: 'owl',
      friendCode: 'FRIEND-A',
      quietHoursEnabled: true,
    });
    await setDoc(doc(db, 'parents/parent-b/children/child-b'), {
      linkedAuthUid: 'child-b-auth',
      linkedDevice: true,
      parentId: 'parent-b',
      accessCode: 'ACCESS-B',
      name: 'Child B',
    });
    await setDoc(doc(db, 'parents/parent-c/children/child-c'), {
      linkedAuthUid: 'child-c-auth',
      linkedDevice: true,
      parentId: 'parent-c',
      accessCode: 'ACCESS-C',
      name: 'Child C',
    });
    await setDoc(doc(db, 'parents/parent-d/children/child-d'), {
      linkedAuthUid: null,
      linkedDevice: false,
      parentId: 'parent-d',
      accessCode: 'ACCESS-D',
      quietHoursEnabled: true,
      name: 'Child D',
    });

    await setDoc(doc(db, 'child_access_codes/ACCESS-D'), {
      parentId: 'parent-d',
      childId: 'child-d',
    });

    await setDoc(doc(db, `conversations/${conversationId}`), {
      participantChildIds: ['child-a', 'child-b'],
      participantParentIds: ['parent-a', 'parent-b'],
      status: 'active',
    });
    await setDoc(
      doc(db, `conversations/${conversationId}/messages/message-1`),
      {
        text: 'Private child message',
        senderUid: 'child-a',
        senderParentId: 'parent-a',
        senderChildName: 'Child A',
        createdAt: new Date('2026-09-04T00:00:00Z'),
        createdAtMs: 1,
        isFlagged: false,
        receiverAction: '',
        receiverActionAt: null,
        receiverActionByChildId: null,
      },
    );
    await setDoc(
      doc(db, `conversations/${conversationId}/messages/flagged-message`),
      {
        text: 'Flagged child message',
        senderUid: 'child-a',
        senderParentId: 'parent-a',
        senderChildName: 'Child A',
        createdAt: new Date('2026-09-04T00:00:00Z'),
        createdAtMs: 2,
        isFlagged: true,
        receiverAction: '',
        receiverActionAt: null,
        receiverActionByChildId: null,
      },
    );

    await setDoc(doc(db, `conversations/${reversedConversationId}`), {
      participantChildIds: ['child-b', 'child-a'],
      participantParentIds: ['parent-b', 'parent-a'],
      status: 'active',
    });
    await setDoc(doc(db, `conversations/${newlyLinkedConversationId}`), {
      participantChildIds: ['child-b', 'child-d'],
      participantParentIds: ['parent-b', 'parent-d'],
      status: 'active',
    });

    const conversationReferenceData = {
      conversationId,
      friendshipId: conversationId,
      createdAt: new Date('2026-09-04T00:00:00Z'),
    };
    await setDoc(
      doc(
        db,
        `parents/parent-a/children/child-a/conversation_refs/${conversationId}`,
      ),
      conversationReferenceData,
    );
    await setDoc(
      doc(
        db,
        `parents/parent-b/children/child-b/conversation_refs/${conversationId}`,
      ),
      conversationReferenceData,
    );
  });
}

function validMessageData({
  childId = 'child-a',
  parentId = 'parent-a',
  childName = 'Child A',
  text = 'Hello',
  isFlagged = false,
} = {}) {
  return {
    text,
    senderUid: childId,
    senderParentId: parentId,
    senderChildName: childName,
    createdAt: serverTimestamp(),
    createdAtMs: Date.now(),
    isFlagged,
    receiverAction: '',
    receiverActionAt: null,
    receiverActionByChildId: null,
  };
}

function messageDoc(db, messageId) {
  return doc(db, `conversations/${conversationId}/messages/${messageId}`);
}


async function seedBlockedByChildIds(value) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await updateDoc(
      doc(context.firestore(), `conversations/${conversationId}`),
      {blockedByChildIds: value},
    );
  });
}

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

async function simulateCallableClaim(parentId, childId, authUid) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await updateDoc(doc(db, `parents/${parentId}/children/${childId}`), {
      linkedAuthUid: authUid,
      linkedDevice: true,
    });
  });
}

before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync('firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
  await seedConversation();
});

after(async () => {
  await testEnvironment.cleanup();
});

describe('conversation privacy', () => {
  test('linked Child A can read the conversation', async () => {
    const db = firestoreFor('child-a-auth');
    await assertSucceeds(getDoc(doc(db, `conversations/${conversationId}`)));
  });

  test('linked Child B can read the same conversation', async () => {
    const db = firestoreFor('child-b-auth');
    await assertSucceeds(getDoc(doc(db, `conversations/${conversationId}`)));
  });

  test('an unrelated anonymous user cannot read the conversation', async () => {
    const db = firestoreFor('unrelated-anonymous-auth');
    await assertFails(getDoc(doc(db, `conversations/${conversationId}`)));
  });

  test('Parent A cannot read the conversation', async () => {
    const db = firestoreFor('parent-a');
    await assertFails(getDoc(doc(db, `conversations/${conversationId}`)));
  });

  test('Parent B cannot read the conversation', async () => {
    const db = firestoreFor('parent-b');
    await assertFails(getDoc(doc(db, `conversations/${conversationId}`)));
  });

  test('the legacy participant-child conversation query remains denied', async () => {
    for (const [authUid, childId] of [
      ['child-a-auth', 'child-a'],
      ['child-b-auth', 'child-b'],
    ]) {
      const db = firestoreFor(authUid);
      await assertFails(
        getDocs(
          query(
            collection(db, 'conversations'),
            where('participantChildIds', 'array-contains', childId),
          ),
        ),
      );
    }
  });

  test('reversed participant ordering authorises both children', async () => {
    for (const authUid of ['child-a-auth', 'child-b-auth']) {
      const db = firestoreFor(authUid);
      await assertSucceeds(
        getDoc(doc(db, `conversations/${reversedConversationId}`)),
      );
    }
  });

  for (const [label, authUid] of [
    ['unrelated linked Child C', 'child-c-auth'],
    ['Child A', 'child-a-auth'],
    ['Child B', 'child-b-auth'],
    ['Parent A', 'parent-a'],
    ['Parent B', 'parent-b'],
  ]) {
    test(`${label} cannot rewrite participant identity`, async () => {
      const db = firestoreFor(authUid);
      await assertFails(
        updateDoc(doc(db, `conversations/${conversationId}`), {
          participantChildIds: ['child-c', 'child-b'],
          participantParentIds: ['parent-c', 'parent-b'],
        }),
      );
    });
  }
});

describe('conversation update actor authorization', () => {
  const conversationPath = `conversations/${conversationId}`;

  test('Child A can update typing state', async () => {
    const db = firestoreFor('child-a-auth');
    await assertSucceeds(
      updateDoc(doc(db, conversationPath), {
        typingChildId: 'child-a',
        typingAt: new Date('2026-09-08T10:00:00Z'),
      }),
    );
  });

  test('Child B can update behavioral state', async () => {
    const db = firestoreFor('child-b-auth');
    await assertSucceeds(
      updateDoc(doc(db, conversationPath), {
        spikeHeat: 2,
        lastSpikeHeatReason: 'test-behavioral-update',
      }),
    );
  });

  test('a linked participant can update unread and read state', async () => {
    const db = firestoreFor('child-a-auth');
    await assertSucceeds(
      updateDoc(doc(db, conversationPath), {
        unreadCounts: {'child-a': 0, 'child-b': 1},
        lastReadAtByChildId: {
          'child-a': new Date('2026-09-08T10:00:00Z'),
        },
      }),
    );
  });

  test('a linked participant can update blocking state', async () => {
    const db = firestoreFor('child-b-auth');
    await assertSucceeds(
      updateDoc(doc(db, conversationPath), {
        blockedByChildIds: ['child-b'],
      }),
    );
  });

  test('a linked participant can update message summary state', async () => {
    const db = firestoreFor('child-a-auth');
    await assertSucceeds(
      updateDoc(doc(db, conversationPath), {
        lastMessage: 'Hello',
        lastMessageSenderChildId: 'child-a',
        lastMessageAt: new Date('2026-09-08T10:00:00Z'),
      }),
    );
  });

  for (const [label, context] of [
    ['Parent A', () => firestoreFor('parent-a')],
    ['Parent B', () => firestoreFor('parent-b')],
    ['linked Child C', () => firestoreFor('child-c-auth')],
    ['an unrelated authenticated user', () => firestoreFor('unrelated-auth')],
    [
      'an unauthenticated user',
      () => testEnvironment.unauthenticatedContext().firestore(),
    ],
  ]) {
    test(`${label} cannot update conversation state`, async () => {
      const db = context();
      await assertFails(
        updateDoc(doc(db, conversationPath), {
          spikeHeat: 99,
        }),
      );
    });
  }

  test('unlinking Child A immediately revokes conversation update access', async () => {
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

  test('relinking grants the new UID access and keeps the old UID denied', async () => {
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
});


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

  test('Child A cannot delete Child B block state', async () => {
    await seedBlockedByChildIds(['child-b']);
    const db = firestoreFor('child-a-auth');
    await assertFails(
      updateDoc(conversationRefFor(db), {
        blockedByChildIds: deleteField(),
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

describe('canonical conversation identity immutability', () => {
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

  test('linked children cannot reorder canonical participant identity',
    async () => {
      await seedCanonicalConversationIdentity();

      for (const authUid of ['child-a-auth', 'child-b-auth']) {
        const db = firestoreFor(authUid);

        await assertFails(
          updateDoc(conversationRefFor(db), {
            participantChildIds: ['child-b', 'child-a'],
          }),
        );

        await assertFails(
          updateDoc(conversationRefFor(db), {
            participantParentIds: ['parent-b', 'parent-a'],
          }),
        );
      }
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

describe('child-scoped conversation references', () => {
  const childARefs =
    'parents/parent-a/children/child-a/conversation_refs';
  const childBRefs =
    'parents/parent-b/children/child-b/conversation_refs';

  test('Child A can list its own conversation references', async () => {
    const db = firestoreFor('child-a-auth');
    const snapshot = await assertSucceeds(getDocs(collection(db, childARefs)));
    assert.deepEqual(snapshot.docs.map((item) => item.id), [conversationId]);
  });

  test('Child B can list its own conversation references', async () => {
    const db = firestoreFor('child-b-auth');
    const snapshot = await assertSucceeds(getDocs(collection(db, childBRefs)));
    assert.deepEqual(snapshot.docs.map((item) => item.id), [conversationId]);
  });

  test("Child C cannot list either participant's references", async () => {
    const db = firestoreFor('child-c-auth');
    await assertFails(getDocs(collection(db, childARefs)));
    await assertFails(getDocs(collection(db, childBRefs)));
  });

  test('parents cannot list their child references', async () => {
    await assertFails(
      getDocs(collection(firestoreFor('parent-a'), childARefs)),
    );
    await assertFails(
      getDocs(collection(firestoreFor('parent-b'), childBRefs)),
    );
  });

  test('an unrelated authenticated user cannot list references', async () => {
    const db = firestoreFor('unrelated-auth');
    await assertFails(getDocs(collection(db, childARefs)));
    await assertFails(getDocs(collection(db, childBRefs)));
  });

  test('clients cannot create a conversation reference', async () => {
    const db = firestoreFor('child-a-auth');
    await assertFails(
      setDoc(doc(db, `${childARefs}/another-conversation`), {
        conversationId: 'another-conversation',
        friendshipId: 'another-conversation',
        createdAt: new Date('2026-09-04T00:00:00Z'),
      }),
    );
  });

  test('clients cannot update a conversation reference', async () => {
    const db = firestoreFor('child-a-auth');
    await assertFails(
      updateDoc(doc(db, `${childARefs}/${conversationId}`), {
        friendshipId: 'changed',
      }),
    );
  });

  test('clients cannot delete a conversation reference', async () => {
    const db = firestoreFor('child-a-auth');
    await assertFails(
      deleteDoc(doc(db, `${childARefs}/${conversationId}`)),
    );
  });

  test('unlinking immediately revokes the old UID reference list', async () => {
    const oldChildDb = firestoreFor('child-a-auth');
    await assertSucceeds(getDocs(collection(oldChildDb, childARefs)));
    await assertSucceeds(
      updateDoc(doc(oldChildDb, 'parents/parent-a/children/child-a'), {
        linkedAuthUid: null,
        linkedDevice: false,
      }),
    );
    await assertFails(getDocs(collection(oldChildDb, childARefs)));
  });

  test('relinking grants the new UID access to unchanged references', async () => {
    const oldChildDb = firestoreFor('child-a-auth');
    await assertSucceeds(
      updateDoc(doc(oldChildDb, 'parents/parent-a/children/child-a'), {
        linkedAuthUid: null,
        linkedDevice: false,
      }),
    );
    await simulateCallableClaim('parent-a', 'child-a', 'child-a-new-auth');

    const newChildDb = firestoreFor('child-a-new-auth');
    const snapshot = await assertSucceeds(
      getDocs(collection(newChildDb, childARefs)),
    );
    assert.deepEqual(snapshot.docs.map((item) => item.id), [conversationId]);
    await assertFails(getDocs(collection(oldChildDb, childARefs)));
  });
});

describe('raw message privacy', () => {
  test('a linked participant child can read messages', async () => {
    const db = firestoreFor('child-a-auth');
    await assertSucceeds(
      getDocs(
        query(
          collection(db, `conversations/${conversationId}/messages`),
          orderBy('createdAtMs', 'desc'),
        ),
      ),
    );
  });

  test('the other linked participant child can read messages', async () => {
    const db = firestoreFor('child-b-auth');
    await assertSucceeds(
      getDocs(
        query(
          collection(db, `conversations/${conversationId}/messages`),
          orderBy('createdAtMs', 'desc'),
        ),
      ),
    );
  });

  test('an unrelated linked child cannot read messages', async () => {
    const db = firestoreFor('child-c-auth');
    await assertFails(
      getDocs(collection(db, `conversations/${conversationId}/messages`)),
    );
  });

  test('an unrelated anonymous user cannot read messages', async () => {
    const db = firestoreFor('unrelated-anonymous-auth');
    await assertFails(
      getDocs(collection(db, `conversations/${conversationId}/messages`)),
    );
  });

  test('neither parent can read messages', async () => {
    for (const parentUid of ['parent-a', 'parent-b']) {
      const db = firestoreFor(parentUid);
      await assertFails(
        getDocs(collection(db, `conversations/${conversationId}/messages`)),
      );
    }
  });
});

describe('message creation authorization', () => {

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

  test('Child A can create a valid message as Child A', async () => {
    const db = firestoreFor('child-a-auth');
    await assertSucceeds(
      setDoc(messageDoc(db, 'child-a-message'), validMessageData()),
    );
  });

  test('Child B can create a valid message as Child B', async () => {
    const db = firestoreFor('child-b-auth');
    await assertSucceeds(
      setDoc(
        messageDoc(db, 'child-b-message'),
        validMessageData({
          childId: 'child-b',
          parentId: 'parent-b',
          childName: 'Child B',
        }),
      ),
    );
  });

  for (const [label, context] of [
    ['Parent A', () => firestoreFor('parent-a')],
    ['Parent B', () => firestoreFor('parent-b')],
    ['Child C', () => firestoreFor('child-c-auth')],
    ['an unrelated authenticated user', () => firestoreFor('unrelated-auth')],
    [
      'an unauthenticated user',
      () => testEnvironment.unauthenticatedContext().firestore(),
    ],
  ]) {
    test(`${label} cannot create a message`, async () => {
      const db = context();
      await assertFails(
        setDoc(messageDoc(db, `denied-${label}`), validMessageData()),
      );
    });
  }

  test('Child A cannot claim Child B as senderUid', async () => {
    const db = firestoreFor('child-a-auth');
    await assertFails(
      setDoc(
        messageDoc(db, 'forged-sender-child'),
        validMessageData({childId: 'child-b'}),
      ),
    );
  });

  test('Child A cannot claim Parent B as senderParentId', async () => {
    const db = firestoreFor('child-a-auth');
    await assertFails(
      setDoc(
        messageDoc(db, 'forged-sender-parent'),
        validMessageData({parentId: 'parent-b'}),
      ),
    );
  });

  test('Child A cannot forge senderChildName', async () => {
    const db = firestoreFor('child-a-auth');
    await assertFails(
      setDoc(
        messageDoc(db, 'forged-sender-name'),
        validMessageData({childName: 'Not Child A'}),
      ),
    );
  });

  test('a message missing a required field is denied', async () => {
    const db = firestoreFor('child-a-auth');
    const data = validMessageData();
    delete data.senderChildName;
    await assertFails(setDoc(messageDoc(db, 'missing-field'), data));
  });

  test('a message with an arbitrary field is denied', async () => {
    const db = firestoreFor('child-a-auth');
    await assertFails(
      setDoc(messageDoc(db, 'extra-field'), {
        ...validMessageData(),
        arbitraryField: true,
      }),
    );
  });

  for (const [label, text] of [
    ['empty', ''],
    ['whitespace-only', '   \n'],
    ['non-string', 42],
    ['over-limit', 'a'.repeat(10001)],
  ]) {
    test(`${label} message text is denied`, async () => {
      const db = firestoreFor('child-a-auth');
      await assertFails(
        setDoc(messageDoc(db, `${label}-text`), validMessageData({text})),
      );
    });
  }

  test('non-Boolean isFlagged is denied', async () => {
    const db = firestoreFor('child-a-auth');
    await assertFails(
      setDoc(messageDoc(db, 'invalid-flag'), {
        ...validMessageData(),
        isFlagged: 'true',
      }),
    );
  });

  for (const [label, fields] of [
    ['receiverAction', {receiverAction: 'read'}],
    ['receiverActionAt', {receiverActionAt: serverTimestamp()}],
    ['receiverActionByChildId', {receiverActionByChildId: 'child-b'}],
  ]) {
    test(`non-empty initial ${label} is denied`, async () => {
      const db = firestoreFor('child-a-auth');
      await assertFails(
        setDoc(messageDoc(db, `initial-${label}`), {
          ...validMessageData({isFlagged: true}),
          ...fields,
        }),
      );
    });
  }

  test('createdAt not equal to request.time is denied', async () => {
    const db = firestoreFor('child-a-auth');
    await assertFails(
      setDoc(messageDoc(db, 'invalid-created-at'), {
        ...validMessageData(),
        createdAt: new Date('2026-09-04T00:00:00Z'),
      }),
    );
  });

  test('message deletion remains denied', async () => {
    const db = firestoreFor('child-a-auth');
    await assertFails(deleteDoc(messageDoc(db, 'message-1')));
  });
});

describe('Protected Delivery receiver actions', () => {
  function receiverAction(action, overrides = {}) {
    return {
      receiverAction: action,
      receiverActionAt: serverTimestamp(),
      receiverActionByChildId: 'child-b',
      ...overrides,
    };
  }

  for (const action of ['read', 'not_now', 'blocked']) {
    test(`Child B can mark a flagged message ${action}`, async () => {
      const db = firestoreFor('child-b-auth');
      await assertSucceeds(
        updateDoc(messageDoc(db, 'flagged-message'), receiverAction(action)),
      );
    });
  }

  test('the sender cannot fabricate a receiver action', async () => {
    const db = firestoreFor('child-a-auth');
    await assertFails(
      updateDoc(messageDoc(db, 'flagged-message'), receiverAction('read')),
    );
  });

  for (const [label, uid] of [
    ['Parent A', 'parent-a'],
    ['Parent B', 'parent-b'],
    ['Child C', 'child-c-auth'],
    ['an unrelated authenticated user', 'unrelated-auth'],
  ]) {
    test(`${label} cannot set a receiver action`, async () => {
      const db = firestoreFor(uid);
      await assertFails(
        updateDoc(messageDoc(db, 'flagged-message'), receiverAction('read')),
      );
    });
  }

  for (const [label, fields] of [
    ['text', {text: 'Changed'}],
    ['senderUid', {senderUid: 'child-b'}],
    ['senderParentId', {senderParentId: 'parent-b'}],
    ['senderChildName', {senderChildName: 'Child B'}],
    ['createdAt', {createdAt: serverTimestamp()}],
    ['createdAtMs', {createdAtMs: 999}],
    ['isFlagged', {isFlagged: false}],
    ['an arbitrary field', {arbitraryField: true}],
  ]) {
    test(`the receiver cannot change ${label}`, async () => {
      const db = firestoreFor('child-b-auth');
      await assertFails(
        updateDoc(messageDoc(db, 'flagged-message'), {
          ...receiverAction('read'),
          ...fields,
        }),
      );
    });
  }

  test('receiverActionByChildId must equal the caller child ID', async () => {
    const db = firestoreFor('child-b-auth');
    await assertFails(
      updateDoc(
        messageDoc(db, 'flagged-message'),
        receiverAction('read', {receiverActionByChildId: 'child-a'}),
      ),
    );
  });

  test('receiver action on an unflagged message is denied', async () => {
    const db = firestoreFor('child-b-auth');
    await assertFails(
      updateDoc(messageDoc(db, 'message-1'), receiverAction('read')),
    );
  });

  test('an invalid receiver action is denied', async () => {
    const db = firestoreFor('child-b-auth');
    await assertFails(
      updateDoc(messageDoc(db, 'flagged-message'), receiverAction('ignored')),
    );
  });

  test('receiverActionAt must equal request.time', async () => {
    const db = firestoreFor('child-b-auth');
    await assertFails(
      updateDoc(
        messageDoc(db, 'flagged-message'),
        receiverAction('read', {
          receiverActionAt: new Date('2026-09-04T00:00:00Z'),
        }),
      ),
    );
  });
});

describe('child linking trust anchor', () => {
  test('an attacker cannot replace an existing linkedAuthUid or read', async () => {
    const db = firestoreFor('attacker-auth');
    await assertFails(
      updateDoc(doc(db, 'parents/parent-a/children/child-a'), {
        linkedAuthUid: 'attacker-auth',
        linkedDevice: true,
      }),
    );
    await assertFails(getDoc(doc(db, `conversations/${conversationId}`)));
    await assertFails(
      getDocs(collection(db, `conversations/${conversationId}/messages`)),
    );
  });

  test('direct client claim cannot modify unrelated child fields', async () => {
    const db = firestoreFor('new-child-d-auth');
    await assertFails(
      updateDoc(doc(db, 'parents/parent-d/children/child-d'), {
        linkedAuthUid: 'new-child-d-auth',
        linkedDevice: true,
        quietHoursEnabled: false,
        arbitraryField: 'not allowed',
      }),
    );
  });

  test('the callable claim path enables legitimate initial linking', async () => {
    await simulateCallableClaim('parent-d', 'child-d', 'new-child-d-auth');

    const childDb = firestoreFor('new-child-d-auth');
    const snapshot = await assertSucceeds(
      getDoc(doc(childDb, 'parents/parent-d/children/child-d')),
    );
    assert.equal(snapshot.data().quietHoursEnabled, true);
    assert.equal(snapshot.data().name, 'Child D');
    await assertSucceeds(
      getDoc(doc(childDb, `conversations/${newlyLinkedConversationId}`)),
    );
  });

  test('a parent cannot link a child profile to the parent Auth UID', async () => {
    const db = firestoreFor('parent-a');
    await assertFails(
      updateDoc(doc(db, 'parents/parent-a/children/child-a'), {
        linkedAuthUid: 'parent-a',
        linkedDevice: true,
      }),
    );
  });
});

describe('child access-code records', () => {
  const validAccessCodeData = {
    parentId: 'parent-a',
    childId: 'child-a',
    childName: 'Child A',
    avatar: 'owl',
    friendCode: 'FRIEND-A',
    createdAt: new Date('2026-09-04T00:00:00Z'),
  };

  test('an arbitrary signed-in user cannot create a code record', async () => {
    const db = firestoreFor('attacker-auth');
    await assertFails(
      setDoc(doc(db, 'child_access_codes/ATTACKER-CODE'), {
        ...validAccessCodeData,
        parentId: 'parent-d',
        childId: 'child-d',
      }),
    );
  });

  test('an unrelated parent cannot create another child code', async () => {
    const db = firestoreFor('parent-b');
    await assertFails(
      setDoc(doc(db, 'child_access_codes/ACCESS-A'), validAccessCodeData),
    );
  });

  test('the owning parent can create its valid child code', async () => {
    const db = firestoreFor('parent-a');
    await assertSucceeds(
      setDoc(doc(db, 'child_access_codes/ACCESS-A'), validAccessCodeData),
    );
  });

  test('a client cannot update an existing code', async () => {
    const db = firestoreFor('parent-d');
    await assertFails(
      updateDoc(doc(db, 'child_access_codes/ACCESS-D'), {
        childName: 'Changed',
      }),
    );
  });

  test('a client cannot delete an existing code', async () => {
    const db = firestoreFor('parent-d');
    await assertFails(deleteDoc(doc(db, 'child_access_codes/ACCESS-D')));
  });

  test('a client cannot list access codes', async () => {
    const db = firestoreFor('signed-in-auth');
    await assertFails(getDocs(collection(db, 'child_access_codes')));
  });

  test('a client cannot get an exact access code', async () => {
    const db = firestoreFor('signed-in-auth');
    await assertFails(getDoc(doc(db, 'child_access_codes/ACCESS-D')));
  });
});
