'use strict';

// Run only against the local Firestore emulator, never production.
// Example:
// FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node --test test/family-messages.rules.test.js
const assert = require('node:assert/strict');
const {test, after} = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertSucceeds, assertFails} =
  require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, getDocs, collection, updateDoc, deleteDoc,
  serverTimestamp} = require('firebase/firestore');

const host = process.env.FIRESTORE_EMULATOR_HOST;
if (!host || !/^(127\.0\.0\.1|localhost):\d+$/.test(host)) {
  throw new Error('FIRESTORE_EMULATOR_HOST must point to a local emulator');
}
const [emulatorHost, port] = host.split(':');
let env;
const ready = initializeTestEnvironment({
  projectId: 'demo-natter-family-messages',
  firestore: {
    host: emulatorHost,
    port: Number(port),
    rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8'),
  },
}).then(async (value) => {
  env = value;
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'parents/parent-a/children/child-a'), {
      name: 'Alex', linkedAuthUid: 'auth-a', linkedDevice: true,
    });
    await setDoc(doc(db, 'parents/parent-a/children/child-sibling'), {
      name: 'Sibling', linkedAuthUid: 'auth-sibling', linkedDevice: true,
    });
    await setDoc(doc(db, 'parents/parent-b/children/child-b'), {
      name: 'Other', linkedAuthUid: 'auth-b', linkedDevice: true,
    });
    await setDoc(doc(db, 'parents/parent-a/children/child-a/family_messages/seed'), {
      text: 'Hello from home',
      senderRole: 'parent',
      senderAuthUid: 'parent-a',
      createdAt: new Date(),
    });
  });
  return value;
});
after(async () => {
  if (env) await env.cleanup();
});

const pathFor = (childId = 'child-a', parentId = 'parent-a') =>
  `parents/${parentId}/children/${childId}/family_messages`;
let seq = 0;
const message = (role, uid, extra = {}) => ({
  text: 'Hello from the family',
  senderRole: role,
  senderAuthUid: uid,
  createdAt: serverTimestamp(),
  ...extra,
});
async function createAs(uid, payload, childId = 'child-a',
    parentId = 'parent-a') {
  const db = (await ready).authenticatedContext(uid).firestore();
  return setDoc(doc(db, pathFor(childId, parentId), `message-${++seq}`),
    payload);
}
async function readAs(uid, childId = 'child-a', parentId = 'parent-a') {
  const db = (await ready).authenticatedContext(uid).firestore();
  return getDoc(doc(db, pathFor(childId, parentId), 'seed'));
}

test('parent and linked child can send messages in their family thread', async () => {
  await assertSucceeds(createAs('parent-a', message('parent', 'parent-a')));
  await assertSucceeds(createAs('auth-a', message('child', 'auth-a')));
});
test('parent and linked child can read and list their family messages', async () => {
  const testEnv = await ready;
  await assertSucceeds(readAs('parent-a'));
  await assertSucceeds(readAs('auth-a'));
  for (const uid of ['parent-a', 'auth-a']) {
    const db = testEnv.authenticatedContext(uid).firestore();
    await assertSucceeds(getDocs(collection(db, pathFor())));
  }
});
test('a sibling or unrelated family cannot read or write this thread', async () => {
  for (const uid of ['auth-sibling', 'auth-b', 'parent-b', 'unknown']) {
    await assertFails(readAs(uid));
    await assertFails(createAs(uid, message('child', uid)));
  }
});
test('role forgery, wrong auth UID, extra fields and invalid text are denied', async () => {
  await assertFails(createAs('auth-a', message('parent', 'auth-a')));
  await assertFails(createAs('parent-a', message('child', 'parent-a')));
  await assertFails(createAs('parent-a', message('parent', 'auth-a')));
  await assertFails(createAs('auth-a', message('child', 'auth-a', {
    friendshipHealth: 100,
  })));
  await assertFails(createAs('auth-a', message('child', 'auth-a', {text: '  '})));
  await assertFails(createAs('auth-a', message('child', 'auth-a', {
    createdAt: new Date(0),
  })));
});
test('messages cannot be edited or deleted', async () => {
  const db = (await ready).authenticatedContext('parent-a').firestore();
  const messageDoc = doc(db, pathFor(), 'seed');
  await assertFails(updateDoc(messageDoc, {text: 'Changed'}));
  await assertFails(deleteDoc(messageDoc));
});

const readPath = (role, childId = 'child-a', parentId = 'parent-a') =>
  `parents/${parentId}/children/${childId}/family_read_state/${role}`;

test('parent and child may write only their own read markers', async () => {
  const testEnv = await ready;
  for (const [uid, role] of [['parent-a', 'parent'], ['auth-a', 'child']]) {
    const db = testEnv.authenticatedContext(uid).firestore();
    await assertSucceeds(setDoc(doc(db, readPath(role)), {
      lastReadAt: serverTimestamp(),
    }));
    await assertSucceeds(getDoc(doc(db, readPath(role))));
  }
});

test('a family member cannot see or alter the other read marker', async () => {
  const testEnv = await ready;
  for (const [uid, otherRole] of [['parent-a', 'child'], ['auth-a', 'parent']]) {
    const db = testEnv.authenticatedContext(uid).firestore();
    await assertFails(getDoc(doc(db, readPath(otherRole))));
    await assertFails(setDoc(doc(db, readPath(otherRole)), {
      lastReadAt: serverTimestamp(),
    }));
  }
  const other = testEnv.authenticatedContext('auth-sibling').firestore();
  await assertFails(getDoc(doc(other, readPath('child'))));
  await assertFails(setDoc(doc(other, readPath('child')), {
    lastReadAt: serverTimestamp(),
  }));
});

test('read marker fields, timestamps, listing and deletes are restricted', async () => {
  const testEnv = await ready;
  const db = testEnv.authenticatedContext('auth-a').firestore();
  await assertFails(setDoc(doc(db, readPath('child')), {
    lastReadAt: new Date(0),
  }));
  await assertFails(setDoc(doc(db, readPath('child')), {
    lastReadAt: serverTimestamp(), extra: 'not allowed',
  }));
  await assertFails(getDocs(collection(db,
    'parents/parent-a/children/child-a/family_read_state')));
  await assertFails(deleteDoc(doc(db, readPath('child'))));
});

test('unlinked and signed-out sessions cannot access a family thread', async () => {
  const testEnv = await ready;
  const db = testEnv.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, pathFor(), 'seed')));
  await assertFails(setDoc(doc(db, pathFor(), 'no-auth'), message('child', '')));
  // The parent's account cannot use a different family's child path.
  await assertFails(createAs('parent-a', message('parent', 'parent-a'),
    'child-b', 'parent-b'));
});
