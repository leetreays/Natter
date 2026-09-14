'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {test} = require('node:test');
const {Timestamp} = require('firebase-admin/firestore');
const r = require('../backfill/reconciliation');
const cli = require('../backfill/conversation-projection-backfill');
const at = (seconds) => new Timestamp(seconds, 0);
const id = 'conversation-a-b';
const conversation = {friendshipId: id, createdAt: at(1),
  participantChildIds: ['child-a', 'child-b'],
  participantParentIds: ['parent-a', 'parent-b']};
const message = (id, sender, seconds, extra = {}) => ({id, data: {
  senderUid: sender, senderParentId: sender === 'child-a' ? 'parent-a' : 'parent-b',
  createdAt: at(seconds), isFlagged: false, text: `text-${id}`, ...extra}});
function build(messages = [], acknowledgements = [null, null], value = conversation) {
  return r.reconstructProjection(id, value, messages, acknowledgements).projections;
}
test('empty conversation produces complete projections', () => {
  for (const value of build()) {
    assert.deepEqual({summaryMessageId: value.summaryMessageId,
      lastMessagePreview: value.lastMessagePreview,
      lastMessageSenderChildId: value.lastMessageSenderChildId,
      lastMessageAt: value.lastMessageAt,
      latestReceivedMessageId: value.latestReceivedMessageId,
      latestReceivedAt: value.latestReceivedAt, hasUnread: value.hasUnread},
    {summaryMessageId: null, lastMessagePreview: '',
      lastMessageSenderChildId: null, lastMessageAt: null,
      latestReceivedMessageId: null, latestReceivedAt: null, hasUnread: false});
  }
});
test('alternating messages derive shared and per-child state', () => {
  const [a, b] = build([message('m1', 'child-a', 10),
    message('m2', 'child-b', 20), message('m3', 'child-a', 30)]);
  assert.equal(a.summaryMessageId, 'm3');
  assert.equal(b.summaryMessageId, 'm3');
  assert.equal(a.latestReceivedMessageId, 'm2');
  assert.equal(b.latestReceivedMessageId, 'm3');
});
test('timestamp and exact lexical ID order determine summary', () => {
  assert.equal(build([message('z', 'child-a', 10),
    message('a', 'child-b', 20)])[0].summaryMessageId, 'a');
  assert.equal(build([message('a', 'child-a', 20),
    message('b', 'child-b', 20)])[0].summaryMessageId, 'b');
});
test('flagged latest uses fixed preview without raw text', () => {
  const raw = 'never-report-this';
  const values = build([message('m1', 'child-a', 10,
      {isFlagged: true, text: raw})]);
  assert.equal(values[0].lastMessagePreview, 'Message needs review');
  assert.equal(JSON.stringify(values).includes(raw), false);
});
test('read before/equal/after derives unread', () => {
  assert.equal(build([message('m1', 'child-a', 10)], [null, at(9)])[1].hasUnread, true);
  assert.equal(build([message('m1', 'child-a', 10)], [null, at(10)])[1].hasUnread, false);
  assert.equal(build([message('m1', 'child-a', 10)], [null, at(11)])[1].hasUnread, false);
});
test('malformed messages and sender-parent mismatch fail closed', () => {
  assert.throws(() => build([message('m1', 'child-a', 10, {createdAt: 'bad'})]));
  assert.throws(() => build([message('m1', 'child-a', 10,
      {senderParentId: 'parent-b'})]));
});
test('newer live complete summary remains coupled', () => {
  const historical = build([message('m1', 'child-a', 10)])[0];
  const current = {...historical, summaryMessageId: 'm9',
    lastMessagePreview: 'new preview', lastMessageSenderChildId: 'child-b',
    lastMessageAt: at(90)};
  const merged = r.mergeWithCurrent(current, historical);
  assert.deepEqual([merged.summaryMessageId, merged.lastMessagePreview,
    merged.lastMessageSenderChildId, merged.lastMessageAt],
  ['m9', 'new preview', 'child-b', at(90)]);
});
test('newer received and acknowledgement never regress', () => {
  const historical = build([message('m1', 'child-a', 10)], [null, at(8)])[1];
  const current = {...historical, latestReceivedMessageId: 'm9',
    latestReceivedAt: at(90), acknowledgedAt: at(80)};
  const merged = r.mergeWithCurrent(current, historical);
  assert.equal(merged.latestReceivedMessageId, 'm9');
  assert.deepEqual(merged.acknowledgedAt, at(80));
  assert.equal(merged.hasUnread, true);
});
test('semantic equality ignores update timestamp but requires all fields', () => {
  const desired = build()[0];
  assert.equal(r.semanticallyEqual({...desired, projectionUpdatedAt: at(9)}, desired), true);
  const incomplete = {...desired}; delete incomplete.hasUnread;
  assert.equal(r.semanticallyEqual(incomplete, desired), false);
});
test('identity conflicts are detected', () => {
  const desired = build()[0];
  assert.equal(r.identityConflict({...desired, friendshipId: 'wrong'}, desired), true);
  assert.equal(r.identityConflict(desired, desired), false);
});
test('CLI defaults to dry-run and apply needs confirmations', () => {
  const previousEmulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
  delete process.env.FIRESTORE_EMULATOR_HOST;
  try {
    const dry = cli.parseArgs(['--project', 'p', '--report', '/tmp/r.json',
      '--checkpoint', '/tmp/c.json']);
    assert.equal(dry.apply, false); assert.equal(dry.pageSize, 100);
    assert.throws(() => cli.parseArgs(['--project', 'p', '--report', '/tmp/r.json',
      '--checkpoint', '/tmp/c.json', '--apply']));
    assert.equal(cli.parseArgs(['--project', 'p', '--confirm-project', 'p',
      '--report', '/tmp/r.json', '--checkpoint', '/tmp/c.json',
      '--apply']).apply, true);
  } finally {
    if (previousEmulatorHost === undefined) {
      delete process.env.FIRESTORE_EMULATOR_HOST;
    } else {
      process.env.FIRESTORE_EMULATOR_HOST = previousEmulatorHost;
    }
  }
});
test('project environment conflicts fail', () => {
  assert.throws(() => cli.validateProjectEnvironment('a',
      {GCLOUD_PROJECT: 'a', GOOGLE_CLOUD_PROJECT: 'b'}));
  assert.doesNotThrow(() => cli.validateProjectEnvironment('a',
      {GCLOUD_PROJECT: 'a'}));
});
test('identifiers default to keyed HMAC and plain is explicit', () => {
  const hashed = cli.identifier('child-secret', {identifierMode: 'hmac'}, 'key');
  assert.match(hashed, /^hmac-sha256:/); assert.equal(hashed.includes('child-secret'), false);
  assert.equal(cli.identifier('id', {identifierMode: 'plain'}), 'id');
  assert.throws(() => cli.identifier('id', {identifierMode: 'hmac'}, ''));
});
test('report paths inside repositories are rejected', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'natter-report-'));
  fs.mkdirSync(path.join(root, '.git'));
  assert.throws(() => cli.validateReportPath(path.join(root, 'report.json'),
      {allowReportInRepo: false}, root));
  assert.doesNotThrow(() => cli.validateReportPath(path.join(root, 'report.json'),
      {allowReportInRepo: true}, root));
  assert.throws(() => cli.validateOperationalPath(
      path.join(root, 'checkpoint.json'), {allowReportInRepo: false}, root));
});
test('checkpoint stores raw cursor privately while report stores only HMAC', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'natter-checkpoint-'));
  const checkpoint = path.join(root, 'checkpoint.json');
  const raw = 'raw-conversation-id';
  cli.writeCheckpoint(checkpoint, raw);
  assert.equal(cli.loadCheckpoint(checkpoint), raw);
  assert.equal(fs.statSync(checkpoint).mode & 0o777, 0o600);
  process.env.NATTER_REPORT_HMAC_KEY = 'test-only-key';
  const report = cli.newReport({apply: false, identifierMode: 'hmac',
    startAfter: raw});
  const serialized = JSON.stringify(report);
  assert.equal(serialized.includes(raw), false);
  assert.match(report.checkpoint.lastCompletedConversation, /^hmac-sha256:/);
});
