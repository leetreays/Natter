import assert from 'node:assert/strict';
import {after, before, beforeEach, describe, test} from 'node:test';

import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {deleteApp, initializeApp} from 'firebase/app';
import {
  connectAuthEmulator,
  getAuth,
  signInAnonymously,
} from 'firebase/auth';
import {
  connectFunctionsEmulator,
  getFunctions,
  httpsCallable,
} from 'firebase/functions';
import {collection, doc, getDoc, getDocs, setDoc} from 'firebase/firestore';

const projectId = 'natter-drp';
const requestId = 'child-a_child-b';

let testEnvironment;
const apps = [];
const actors = {};

async function createActor(name, {authenticated = true} = {}) {
  const app = initializeApp({projectId, apiKey: 'demo-api-key'}, name);
  apps.push(app);

  if (authenticated) {
    const auth = getAuth(app);
    connectAuthEmulator(auth, 'http://127.0.0.1:9099', {
      disableWarnings: true,
    });
    await signInAnonymously(auth);
  }

  const functions = getFunctions(app, 'europe-west2');
  connectFunctionsEmulator(functions, '127.0.0.1', 5001);
  return {
    uid: authenticated ? getAuth(app).currentUser.uid : null,
    approve: httpsCallable(functions, 'approveFriendRequest'),
  };
}

async function seedRequest(overrides = {}) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `friend_requests/${requestId}`), {
      status: 'pending',
      requesterParentId: actors.requester.uid,
      requesterChildId: 'child-a',
      requesterChildName: 'Child A',
      requesterFriendCode: 'FRIEND-A',
      recipientParentId: actors.recipient.uid,
      recipientChildId: 'child-b',
      recipientChildName: 'Child B',
      recipientFriendCode: 'FRIEND-B',
      participantChildIds: ['child-a', 'child-b'],
      participantParentIds: [actors.requester.uid, actors.recipient.uid],
      ...overrides,
    });
  });
}

async function approvalArtifacts() {
  let artifacts;

  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const [
      request,
      friendship,
      conversation,
      requesterRef,
      recipientRef,
      friendshipMoments,
    ] =
      await Promise.all([
        getDoc(doc(db, `friend_requests/${requestId}`)),
        getDoc(doc(db, `friendships/${requestId}`)),
        getDoc(doc(db, `conversations/${requestId}`)),
        getDoc(doc(
          db,
          `parents/${actors.requester.uid}/children/child-a/` +
            `conversation_refs/${requestId}`,
        )),
        getDoc(doc(
          db,
          `parents/${actors.recipient.uid}/children/child-b/` +
            `conversation_refs/${requestId}`,
        )),
        getDocs(collection(
          db,
          `friendships/${requestId}/friendship_moments`,
        )),
      ]);

    artifacts = {
      request,
      friendship,
      conversation,
      requesterRef,
      recipientRef,
      friendshipMoments,
    };
  });

  return artifacts;
}

async function expectCallableError(call, code) {
  await assert.rejects(call, (error) => error.code === `functions/${code}`);
}

async function assertNoApprovalSideEffects() {
  const artifacts = await approvalArtifacts();
  assert.equal(artifacts.request.data().status, 'pending');
  assert.equal(artifacts.friendship.exists(), false);
  assert.equal(artifacts.conversation.exists(), false);
  assert.equal(artifacts.requesterRef.exists(), false);
  assert.equal(artifacts.recipientRef.exists(), false);
  assert.equal(artifacts.friendshipMoments.size, 0);
}

before(async () => {
  testEnvironment = await initializeTestEnvironment({projectId});
  actors.requester = await createActor('requester-parent');
  actors.recipient = await createActor('recipient-parent');
  actors.unrelated = await createActor('unrelated-parent');
  actors.child = await createActor('anonymous-child');
  actors.unauthenticated = await createActor('unauthenticated', {
    authenticated: false,
  });
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
  await seedRequest();
});

after(async () => {
  await Promise.all(apps.map((app) => deleteApp(app)));
  await testEnvironment.cleanup();
});

describe('approveFriendRequest callable authorization', () => {
  test('the intended recipient parent can approve a pending request', async () => {
    const result = await actors.recipient.approve({requestId});
    assert.equal(result.data.friendshipId, requestId);
    assert.equal(result.data.conversationId, requestId);

    const artifacts = await approvalArtifacts();
    assert.equal(artifacts.request.data().status, 'approved');
    assert.equal(
      artifacts.request.data().respondedByParentId,
      actors.recipient.uid,
    );
    assert.equal(artifacts.friendship.exists(), true);
    assert.equal(artifacts.conversation.exists(), true);
    assert.equal(artifacts.requesterRef.exists(), true);
    assert.equal(artifacts.recipientRef.exists(), true);
    assert.equal(artifacts.friendshipMoments.size, 1);
  });

  test('the requester parent cannot approve the request', async () => {
    await expectCallableError(
      () => actors.requester.approve({requestId}),
      'permission-denied',
    );
    await assertNoApprovalSideEffects();
  });

  test('an unrelated parent cannot approve the request', async () => {
    await expectCallableError(
      () => actors.unrelated.approve({requestId}),
      'permission-denied',
    );
    await assertNoApprovalSideEffects();
  });

  test('an anonymous child cannot approve the request', async () => {
    await expectCallableError(
      () => actors.child.approve({requestId}),
      'permission-denied',
    );
    await assertNoApprovalSideEffects();
  });

  test('an unauthenticated caller cannot approve the request', async () => {
    await expectCallableError(
      () => actors.unauthenticated.approve({requestId}),
      'unauthenticated',
    );
    await assertNoApprovalSideEffects();
  });

  test('missing recipient parent identity fails closed', async () => {
    await seedRequest({recipientParentId: null});
    await expectCallableError(
      () => actors.recipient.approve({requestId}),
      'failed-precondition',
    );
    await assertNoApprovalSideEffects();
  });

  test('an approved request cannot be approved again', async () => {
    await actors.recipient.approve({requestId});
    await expectCallableError(
      () => actors.recipient.approve({requestId}),
      'failed-precondition',
    );
  });

  test('only one concurrent approval can commit', async () => {
    const results = await Promise.allSettled([
      actors.recipient.approve({requestId}),
      actors.recipient.approve({requestId}),
    ]);

    const successful = results.filter((result) =>
      result.status === 'fulfilled',
    );
    const failed = results.filter((result) => result.status === 'rejected');

    assert.equal(successful.length, 1);
    assert.equal(failed.length, 1);
    assert.equal(failed[0].reason.code, 'functions/failed-precondition');

    const artifacts = await approvalArtifacts();
    assert.equal(artifacts.request.data().status, 'approved');
    assert.equal(artifacts.friendship.exists(), true);
    assert.equal(artifacts.conversation.exists(), true);
    assert.equal(artifacts.requesterRef.exists(), true);
    assert.equal(artifacts.recipientRef.exists(), true);
    assert.equal(artifacts.friendshipMoments.size, 1);
  });
});
