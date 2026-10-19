'use strict';

// Run against the Firestore emulator, never a production project.
// npm install --no-save @firebase/rules-unit-testing firebase
// FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node --test test/journey-send-route.rules.test.js
const assert = require('node:assert/strict');
const {test, after} = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertSucceeds, assertFails} =
  require('@firebase/rules-unit-testing');
const {doc, setDoc, serverTimestamp} = require('firebase/firestore');

const projectId = 'demo-natter-journey';
const host = process.env.FIRESTORE_EMULATOR_HOST;
if (!host || !/^(127\.0\.0\.1|localhost):\d+$/.test(host)) {
  throw new Error('Set FIRESTORE_EMULATOR_HOST to the local emulator, e.g. 127.0.0.1:8080');
}
const [emulatorHost, port] = host.split(':');
let env;
const ready = initializeTestEnvironment({
  projectId,
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
    await setDoc(doc(db, 'parents/parent-b/children/child-b'), {
      name: 'Bailey', linkedAuthUid: 'auth-b', linkedDevice: true,
    });
    await setDoc(doc(db, 'conversations/child-a_child-b'), {
      friendshipId: 'child-a_child-b',
      participantChildIds: ['child-a', 'child-b'],
      participantParentIds: ['parent-a', 'parent-b'],
      blockedByChildIds: [],
    });
  });
  return value;
});
after(async () => {
  if (env) await env.cleanup();
});
let counter = 0;
function message(extra = {}) {
  return {
    text: 'Hello',
    senderUid: 'child-a',
    senderParentId: 'parent-a',
    senderChildName: 'Alex',
    createdAt: serverTimestamp(),
    createdAtMs: Date.now(),
    isFlagged: false,
    receiverAction: '',
    receiverActionAt: null,
    receiverActionByChildId: null,
    ...extra,
  };
}
async function writeAs(uid, payload) {
  const testEnv = await ready;
  const db = testEnv.authenticatedContext(uid).firestore();
  return setDoc(doc(db, 'conversations/child-a_child-b/messages',
    `journey-rule-${++counter}`), payload);
}
test('legacy message without route is allowed', async () => {
  await assertSucceeds(writeAs('auth-a', message()));
});
test('direct and coached observations are allowed', async () => {
  for (const route of ['direct_unflagged', 'direct_after_guidance', 'unverified']) {
    await assertSucceeds(writeAs('auth-a', message({journeySendRoute: route})));
  }
});
test('protected delivery requires protected route', async () => {
  await assertSucceeds(writeAs('auth-a', message({
    isFlagged: true, journeySendRoute: 'protected_delivery',
  })));
  await assertFails(writeAs('auth-a', message({
    isFlagged: true, journeySendRoute: 'direct_unflagged',
  })));
  await assertFails(writeAs('auth-a', message({
    journeySendRoute: 'protected_delivery',
  })));
});
test('unknown, forged and malformed routes are rejected', async () => {
  for (const route of ['verified', 'independent', '', 123, null]) {
    await assertFails(writeAs('auth-a', message({journeySendRoute: route})));
  }
});
test('unexpected extra message field is rejected', async () => {
  await assertFails(writeAs('auth-a', message({independenceVerified: true})));
});
test('unlinked and unauthenticated actors cannot create messages', async () => {
  await assertFails(writeAs('auth-other', message({journeySendRoute: 'direct_unflagged'})));
  const testEnv = await ready;
  const db = testEnv.unauthenticatedContext().firestore();
  await assertFails(setDoc(doc(db, 'conversations/child-a_child-b/messages',
    `journey-rule-${++counter}`), message()));
});
test('a linked child cannot impersonate the other sender', async () => {
  await assertFails(writeAs('auth-a', message({
    senderUid: 'child-b', senderParentId: 'parent-b', senderChildName: 'Bailey',
    journeySendRoute: 'direct_unflagged',
  })));
});
