'use strict';
const assert = require('node:assert/strict');
const {test, after} = require('node:test');
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {ProjectionValidationError, processMessageProjection,
  processReadStateProjection} = require('../projection');
const enabled = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
const app = enabled ? initializeApp({projectId: `natter-projection-${Date.now()}`},
    `projection-${Date.now()}`) : null;
const db = enabled ? getFirestore(app) : null;
after(async () => {
  if (app) await deleteApp(app);
});
const at = (seconds) => new Timestamp(seconds, 0);
let sequence = 0;
function fixture({reversed = false, malformed = false, mismatch = false} = {}) {
  sequence += 1;
  const conversationId = `projection-${Date.now()}-${sequence}`;
  const children = reversed ? ['child-b', 'child-a'] : ['child-a', 'child-b'];
  const parents = reversed ? ['parent-b', 'parent-a'] : ['parent-a', 'parent-b'];
  return {conversationId, conversation: {
    friendshipId: mismatch ? `${conversationId}-wrong` : conversationId,
    createdAt: at(1),
    participantChildIds: malformed ? ['child-a'] : children,
    participantParentIds: parents,
  }};
}
const ref = (conversationId, childId) => {
  const parentId = childId === 'child-a' ? 'parent-a' : 'parent-b';
  return db.doc(`parents/${parentId}/children/${childId}` +
    `/conversation_refs/${conversationId}`);
};
const readRef = (conversationId, childId) =>
  db.doc(`conversations/${conversationId}/read_state/${childId}`);
const message = (sender = 'child-a', seconds = 10, extra = {}) => ({
  senderUid: sender,
  senderParentId: sender === 'child-a' ? 'parent-a' : 'parent-b',
  createdAt: at(seconds), isFlagged: false, text: `${sender} message`, ...extra});
async function seed(options = {}) {
  const value = fixture(options);
  await db.doc(`conversations/${value.conversationId}`).set(value.conversation);
  for (const childId of ['child-a', 'child-b']) {
    await ref(value.conversationId, childId).set({
      conversationId: value.conversationId,
      friendshipId: value.conversation.friendshipId,
      createdAt: value.conversation.createdAt,
    });
  }
  return value;
}
async function states(conversationId) {
  const snapshots = await db.getAll(ref(conversationId, 'child-a'),
      ref(conversationId, 'child-b'));
  return snapshots.map((snapshot) => snapshot.data());
}
const emulator = (name, fn) => test(name, {skip: !enabled}, fn);

emulator('message processor persists shared summary and receiver-only state', async () => {
  const {conversationId} = await seed();
  await processMessageProjection(db, conversationId, 'm1', message());
  const [a, b] = await states(conversationId);
  for (const state of [a, b]) {
    assert.equal(state.projectionVersion, 1);
    assert.equal(state.summaryMessageId, 'm1');
    assert.equal(state.lastMessagePreview, 'child-a message');
    assert.equal(state.lastMessageSenderChildId, 'child-a');
    assert.deepEqual(state.lastMessageAt, at(10));
  }
  assert.equal(a.latestReceivedMessageId, null);
  assert.equal(a.hasUnread, false);
  assert.equal(b.latestReceivedMessageId, 'm1');
  assert.deepEqual(b.latestReceivedAt, at(10));
  assert.equal(b.hasUnread, true);
  await processMessageProjection(db, conversationId, 'm2', message('child-b', 20));
  const [a2, b2] = await states(conversationId);
  assert.equal(a2.latestReceivedMessageId, 'm2');
  assert.equal(a2.hasUnread, true);
  assert.equal(b2.latestReceivedMessageId, 'm1');
});

emulator('reversed participants retain positional sender and receiver mapping', async () => {
  const {conversationId} = await seed({reversed: true});
  await processMessageProjection(db, conversationId, 'm1', message());
  const [a, b] = await states(conversationId);
  assert.equal(a.latestReceivedMessageId, null);
  assert.equal(b.latestReceivedMessageId, 'm1');
});

emulator('Protected Delivery persisted projections contain no raw text', async () => {
  const {conversationId} = await seed();
  const raw = 'private protected payload';
  await processMessageProjection(db, conversationId, 'm1',
      message('child-a', 10, {isFlagged: true, text: raw}));
  const values = await states(conversationId);
  for (const value of values) {
    assert.equal(value.lastMessagePreview, 'Message needs review');
    assert.equal(JSON.stringify(value).includes(raw), false);
  }
});

emulator('read before/after message converges without counters', async () => {
  const {conversationId} = await seed();
  await readRef(conversationId, 'child-b').set({lastReadAt: at(9)});
  await processMessageProjection(db, conversationId, 'm1', message());
  assert.equal((await ref(conversationId, 'child-b').get()).data().hasUnread, true);
  await processReadStateProjection(db, conversationId, 'child-b', {lastReadAt: at(11)});
  const state = (await ref(conversationId, 'child-b').get()).data();
  assert.deepEqual(state.acknowledgedAt, at(11));
  assert.equal(state.hasUnread, false);
});

emulator('message retries and delayed older delivery cannot regress state', async () => {
  const {conversationId} = await seed();
  await processMessageProjection(db, conversationId, 'm2', message('child-a', 20));
  const before = (await ref(conversationId, 'child-b').get()).data();
  await processMessageProjection(db, conversationId, 'm2', message('child-a', 20));
  await processMessageProjection(db, conversationId, 'm1', message('child-a', 10));
  const afterValue = (await ref(conversationId, 'child-b').get()).data();
  assert.equal(afterValue.summaryMessageId, 'm2');
  assert.equal(afterValue.latestReceivedMessageId, 'm2');
  assert.deepEqual(afterValue.projectionUpdatedAt, before.projectionUpdatedAt);
});

emulator('equal-time opposite-direction events converge by lexical ID', async () => {
  const first = await seed();
  await processMessageProjection(db, first.conversationId, 'm2', message('child-b'));
  await processMessageProjection(db, first.conversationId, 'm1', message());
  const second = await seed();
  await processMessageProjection(db, second.conversationId, 'm1', message());
  await processMessageProjection(db, second.conversationId, 'm2', message('child-b'));
  for (const values of [await states(first.conversationId),
    await states(second.conversationId)]) {
    assert.equal(values[0].summaryMessageId, 'm2');
    assert.equal(values[1].summaryMessageId, 'm2');
  }
});

emulator('missing deterministic ref is reconstructed from canonical identity', async () => {
  const {conversationId} = await seed();
  await ref(conversationId, 'child-b').delete();
  await processMessageProjection(db, conversationId, 'm1', message());
  const rebuilt = (await ref(conversationId, 'child-b').get()).data();
  assert.equal(rebuilt.conversationId, conversationId);
  assert.equal(rebuilt.friendshipId, conversationId);
  assert.equal(rebuilt.projectionVersion, 1);
});

emulator('message processor fails closed for invalid canonical or sender data', async () => {
  const missingId = `missing-${Date.now()}`;
  await assert.rejects(processMessageProjection(db, missingId, 'm1', message()),
      ProjectionValidationError);
  for (const options of [{malformed: true}, {mismatch: true}]) {
    const {conversationId} = await seed(options);
    await assert.rejects(processMessageProjection(db, conversationId, 'm1', message()),
        ProjectionValidationError);
  }
  const valid = await seed();
  await assert.rejects(processMessageProjection(db, valid.conversationId, 'm1',
      message('child-c')), ProjectionValidationError);
  await assert.rejects(processMessageProjection(db, valid.conversationId, 'm1',
      message('child-a', 10, {senderParentId: 'parent-b'})),
  ProjectionValidationError);
});

emulator('read processor is monotonic, idempotent, and derives unread', async () => {
  const {conversationId} = await seed();
  await processMessageProjection(db, conversationId, 'm1', message());
  await processReadStateProjection(db, conversationId, 'child-b', {lastReadAt: at(9)});
  let value = (await ref(conversationId, 'child-b').get()).data();
  assert.equal(value.hasUnread, true);
  await processReadStateProjection(db, conversationId, 'child-b', {lastReadAt: at(11)});
  value = (await ref(conversationId, 'child-b').get()).data();
  const updatedAt = value.projectionUpdatedAt;
  assert.equal(value.hasUnread, false);
  await processReadStateProjection(db, conversationId, 'child-b', {lastReadAt: at(8)});
  await processReadStateProjection(db, conversationId, 'child-b', {lastReadAt: at(11)});
  value = (await ref(conversationId, 'child-b').get()).data();
  assert.deepEqual(value.acknowledgedAt, at(11));
  assert.deepEqual(value.projectionUpdatedAt, updatedAt);
});

emulator('read processor handles reversed order and rejects invalid paths/data', async () => {
  const {conversationId} = await seed({reversed: true});
  await processReadStateProjection(db, conversationId, 'child-a', {lastReadAt: at(5)});
  assert.deepEqual((await ref(conversationId, 'child-a').get()).data().acknowledgedAt,
      at(5));
  await assert.rejects(processReadStateProjection(db, conversationId, 'child-c',
      {lastReadAt: at(5)}), ProjectionValidationError);
  await assert.rejects(processReadStateProjection(db, conversationId, 'child-a',
      {lastReadAt: 'bad'}), ProjectionValidationError);
});
