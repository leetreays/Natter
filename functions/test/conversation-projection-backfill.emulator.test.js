'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {after, test} = require('node:test');
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {reconcileConversation} = require('../backfill/reconciliation');
const {runBackfill} = require('../backfill/conversation-projection-backfill');
const enabled = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
const app = enabled ? initializeApp({projectId: `backfill-${Date.now()}`},
    `backfill-${Date.now()}`) : null;
const db = enabled ? getFirestore(app) : null;
after(async () => {
  if (app) await deleteApp(app);
});
const emulator = (name, fn) => test(name, {skip: !enabled}, fn);
const at = (seconds) => new Timestamp(seconds, 0);
let serial = 0;
function ref(id, child) {
  const parent = child === 'child-a' ? 'parent-a' : 'parent-b';
  return db.doc(`parents/${parent}/children/${child}/conversation_refs/${id}`);
}
async function seed(options = {}) {
  const id = `bf-${Date.now()}-${++serial}`;
  const reversed = options.reversed || false;
  const conversation = {friendshipId: options.mismatch ? `${id}-wrong` : id,
    createdAt: at(1), participantChildIds: options.duplicate ?
['child-a', 'child-a'] : reversed ? ['child-b', 'child-a'] : ['child-a', 'child-b'],
    participantParentIds: reversed ? ['parent-b', 'parent-a'] : ['parent-a', 'parent-b']};
  const snapshotRef = db.doc(`conversations/${id}`);
  await snapshotRef.set(conversation);
  if (!options.missingChild) {
    await db.doc('parents/parent-a/children/child-a').set({stable: true});
    await db.doc('parents/parent-b/children/child-b').set({stable: true});
  } else {
    await db.doc('parents/parent-a/children/child-a').delete();
    await db.doc('parents/parent-b/children/child-b').delete();
  }
  if (options.refs !== false) {
    await ref(id, 'child-a').set({conversationId: id,
      friendshipId: conversation.friendshipId, createdAt: at(1)});
    await ref(id, 'child-b').set({conversationId: id,
      friendshipId: conversation.friendshipId, createdAt: at(1)});
  }
  return {id, snapshot: await snapshotRef.get()};
}
async function addMessage(id, messageId, sender, seconds, extra = {}) {
  await db.doc(`conversations/${id}/messages/${messageId}`).set({
    senderUid: sender, senderParentId: sender === 'child-a' ? 'parent-a' : 'parent-b',
    createdAt: at(seconds), isFlagged: false, text: `text-${messageId}`, ...extra});
}
const options = (apply = true, messagePageSize = 2) => ({apply, messagePageSize});
async function values(id) {
  return Promise.all(['child-a', 'child-b'].map(async (child) =>
    (await ref(id, child).get()).data()));
}
emulator('empty apply completes both legacy refs and second run is no-op', async () => {
  const item = await seed();
  assert.equal((await reconcileConversation(db, item.snapshot, options())).writes, 2);
  const [a, b] = await values(item.id);
  assert.equal(a.projectionVersion, 1); assert.equal(b.summaryMessageId, null);
  const updatedAt = a.projectionUpdatedAt;
  assert.equal((await reconcileConversation(db, item.snapshot, options())).writes, 0);
  assert.deepEqual((await ref(item.id, 'child-a').get()).data().projectionUpdatedAt,
      updatedAt);
});
emulator('messages paginate and derive both directions and read timing', async () => {
  const item = await seed();
  await addMessage(item.id, 'm1', 'child-a', 10);
  await addMessage(item.id, 'm2', 'child-b', 20);
  await addMessage(item.id, 'm3', 'child-a', 30);
  await db.doc(`conversations/${item.id}/read_state/child-b`).set({lastReadAt: at(30)});
  await reconcileConversation(db, item.snapshot, options(true, 1));
  const [a, b] = await values(item.id);
  assert.equal(a.latestReceivedMessageId, 'm2');
  assert.equal(b.latestReceivedMessageId, 'm3');
  assert.equal(b.hasUnread, false);
});
emulator('equal time uses message ID and protected content never persists', async () => {
  const item = await seed(); const raw = 'protected-child-content';
  await addMessage(item.id, 'a', 'child-a', 10);
  await addMessage(item.id, 'z', 'child-b', 10, {isFlagged: true, text: raw});
  await reconcileConversation(db, item.snapshot, options());
  for (const value of await values(item.id)) {
    assert.equal(value.summaryMessageId, 'z');
    assert.equal(value.lastMessagePreview, 'Message needs review');
    assert.equal(JSON.stringify(value).includes(raw), false);
  }
});
emulator('malformed message or read state blocks both refs', async () => {
  const badMessage = await seed();
  await addMessage(badMessage.id, 'm1', 'child-a', 10, {createdAt: 'bad'});
  const result = await reconcileConversation(db, badMessage.snapshot, options());
  assert.equal(result.reason, 'MALFORMED_MESSAGE');
  assert.equal((await ref(badMessage.id, 'child-a').get()).data().projectionVersion,
      undefined);
  const badRead = await seed();
  await db.doc(`conversations/${badRead.id}/read_state/child-a`).set({lastReadAt: 'bad'});
  assert.equal((await reconcileConversation(db, badRead.snapshot, options())).reason,
      'MALFORMED_READ_STATE');
});
emulator('invalid canonical identity or missing child blocks both refs', async () => {
  for (const setup of [{mismatch: true}, {duplicate: true}, {missingChild: true}]) {
    const item = await seed(setup);
    const result = await reconcileConversation(db, item.snapshot, options());
    assert.ok(result.reason);
  }
});
emulator('missing refs are reconstructed only for eligible conversations', async () => {
  const item = await seed({refs: false});
  assert.equal((await reconcileConversation(db, item.snapshot, options())).writes, 2);
  assert.equal((await ref(item.id, 'child-a').get()).data().friendshipId, item.id);
});
emulator('one conflicting ref prevents both writes', async () => {
  const item = await seed();
  await ref(item.id, 'child-a').update({friendshipId: 'wrong'});
  const before = (await ref(item.id, 'child-b').get()).data();
  const result = await reconcileConversation(db, item.snapshot, options());
  assert.equal(result.reason, 'CONFLICTING_REF_IDENTITY');
  assert.deepEqual((await ref(item.id, 'child-b').get()).data(), before);
});
emulator('dry run performs no writes and reports intended changes', async () => {
  const item = await seed();
  const before = await values(item.id);
  const result = await reconcileConversation(db, item.snapshot, options(false));
  assert.equal(result.writes, 2);
  assert.deepEqual(await values(item.id), before);
});
emulator('newer live tuples and acknowledgement survive stale reconstruction', async () => {
  const item = await seed(); await addMessage(item.id, 'm1', 'child-a', 10);
  const live = {projectionVersion: 1, summaryMessageId: 'm9',
    lastMessagePreview: 'live', lastMessageSenderChildId: 'child-b',
    lastMessageAt: at(90), latestReceivedMessageId: 'm8',
    latestReceivedAt: at(80), acknowledgedAt: at(70), hasUnread: true};
  await ref(item.id, 'child-a').update(live);
  await reconcileConversation(db, item.snapshot, options());
  const value = (await ref(item.id, 'child-a').get()).data();
  assert.deepEqual([value.summaryMessageId, value.lastMessagePreview,
    value.lastMessageSenderChildId], ['m9', 'live', 'child-b']);
  assert.equal(value.latestReceivedMessageId, 'm8');
  assert.deepEqual(value.acknowledgedAt, at(70));
});
emulator('run paginates conversations and writes privacy-safe report', async () => {
  await seed(); await seed(); await seed();
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'backfill-report-'));
  const reportPath = path.join(directory, 'report.json');
  const checkpointPath = path.join(directory, 'checkpoint.json');
  process.env.NATTER_REPORT_HMAC_KEY = 'test-only-key';
  const report = await runBackfill(db, {apply: false, project: 'test',
    report: reportPath, identifierMode: 'hmac', pageSize: 1,
    messagePageSize: 1, startAfter: null, maxConversations: 3,
    conversation: null}, reportPath, checkpointPath);
  assert.equal(report.counts.scanned, 3);
  const serialized = fs.readFileSync(reportPath, 'utf8');
  assert.equal(serialized.includes('child-a'), false);
  assert.equal(serialized.includes('text-'), false);
  const checkpoint = JSON.parse(fs.readFileSync(checkpointPath, 'utf8'));
  assert.equal(typeof checkpoint.lastCompletedConversationId, 'string');
  assert.equal(serialized.includes(checkpoint.lastCompletedConversationId), false);
});
emulator('resume from raw checkpoint converges without rewriting completed refs',
    async () => {
      const first = await seed();
      const second = await seed();
      const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'resume-'));
      process.env.NATTER_REPORT_HMAC_KEY = 'test-only-key';
      const checkpointPath = path.join(directory, 'checkpoint.json');
      await reconcileConversation(db, first.snapshot, options());
      fs.writeFileSync(checkpointPath, JSON.stringify({schemaVersion: 1,
        lastCompletedConversationId: first.id}), {mode: 0o600});
      const firstUpdatedAt = (await ref(first.id, 'child-a').get())
          .data().projectionUpdatedAt;
      const cursor = JSON.parse(fs.readFileSync(checkpointPath, 'utf8'))
          .lastCompletedConversationId;
      await runBackfill(db, {apply: true, identifierMode: 'hmac', pageSize: 1,
        messagePageSize: 1, startAfter: cursor, maxConversations: 1,
        conversation: null}, path.join(directory, 'second.json'), checkpointPath);
      assert.deepEqual((await ref(first.id, 'child-a').get())
          .data().projectionUpdatedAt, firstUpdatedAt);
      assert.equal((await ref(second.id, 'child-a').get())
          .data().projectionVersion, 1);
    });
