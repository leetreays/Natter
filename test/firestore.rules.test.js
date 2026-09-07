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
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
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
    });
    await setDoc(doc(db, 'parents/parent-c/children/child-c'), {
      linkedAuthUid: 'child-c-auth',
      linkedDevice: true,
      parentId: 'parent-c',
      accessCode: 'ACCESS-C',
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
        createdAtMs: 1,
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
