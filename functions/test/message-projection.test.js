'use strict';
const assert = require('node:assert/strict');
const {test} = require('node:test');
const {Timestamp} = require('firebase-admin/firestore');
const p = require('../projection');
const at = (seconds) => new Timestamp(seconds, 0);
const id = 'friendship-a-b';
const conversation = {friendshipId: id, createdAt: at(1),
  participantChildIds: ['child-a', 'child-b'],
  participantParentIds: ['parent-a', 'parent-b']};
const message = (extra = {}) => ({senderUid: 'child-a',
  senderParentId: 'parent-a', createdAt: at(10), isFlagged: false,
  text: 'Hello', ...extra});
function project(extra = {}) {
  return p.mergeMessageProjection({conversationId: id, conversation,
    existing: null, message: message(), messageId: 'm1', isReceiver: true,
    acknowledgedAt: null, ...extra});
}
test('tuple ordering uses time then lexical ID', () => {
  assert.equal(p.compareTuple(at(2), 'a', at(1), 'z'), 1);
  assert.equal(p.compareTuple(at(2), 'b', at(2), 'a'), 1);
  assert.equal(p.compareTuple(at(2), 'a', at(2), 'b'), -1);
});
test('Protected Delivery never projects raw text', () => {
  const raw = 'protected raw text';
  const result = project({message: message({isFlagged: true, text: raw})});
  assert.equal(result.lastMessagePreview, 'Message needs review');
  assert.equal(JSON.stringify(result).includes(raw), false);
});
test('ordinary message projects summary and receiver state', () => {
  const receiver = project();
  const sender = project({isReceiver: false});
  assert.equal(receiver.summaryMessageId, 'm1');
  assert.equal(receiver.latestReceivedMessageId, 'm1');
  assert.equal(receiver.unreadCount, 1);
  assert.equal(receiver.hasUnread, true);
  assert.equal(sender.latestReceivedMessageId, null);
  assert.equal(sender.unreadCount, 0);
  assert.equal(sender.hasUnread, false);
});
test('read timing derives unread count and Boolean state', () => {
  const before = project({acknowledgedAt: at(9)});
  const equal = project({acknowledgedAt: at(10)});
  const after = project({acknowledgedAt: at(11)});

  assert.equal(before.unreadCount, 1);
  assert.equal(before.hasUnread, true);
  assert.equal(equal.unreadCount, 0);
  assert.equal(equal.hasUnread, false);
  assert.equal(after.unreadCount, 0);
  assert.equal(after.hasUnread, false);
});

test('unread count is exact through nine and caps at ten', () => {
  let state = null;

  for (let index = 1; index <= 12; index += 1) {
    state = project({
      existing: state,
      messageId: `m${index}`,
      message: message({createdAt: at(10 + index)}),
    }) || state;

    assert.equal(state.unreadCount, Math.min(index, 10));
  }

  assert.equal(state.unreadMessageMarkers.length, 10);
  assert.equal(state.hasUnread, true);
});
test('delayed older message counts once without regressing tuples', () => {
  const newer = project({
    messageId: 'm2',
    message: message({createdAt: at(20)}),
  });

  const delayed = project({
    existing: newer,
    messageId: 'm1',
  });

  assert.equal(delayed.summaryMessageId, 'm2');
  assert.equal(delayed.latestReceivedMessageId, 'm2');
  assert.equal(delayed.unreadCount, 2);

  assert.equal(project({
    existing: delayed,
    messageId: 'm1',
  }), null);

  assert.equal(project({
    existing: delayed,
    messageId: 'm2',
    message: message({createdAt: at(20)}),
  }), null);
});
test('equal timestamps converge using lexical message ID', () => {
  const first = project();
  const second = project({existing: first, messageId: 'm2'});
  assert.equal(second.summaryMessageId, 'm2');
  assert.equal(project({existing: second}), null);
});
test('acknowledgement is monotonic and idempotent', () => {
  const existing = project();
  const read = p.mergeAcknowledgementProjection({conversationId: id,
    conversation, existing, acknowledgedAt: at(11)});
  assert.equal(read.unreadCount, 0);
  assert.equal(read.hasUnread, false);
  assert.equal(p.mergeAcknowledgementProjection({conversationId: id,
    conversation, existing: read, acknowledgedAt: at(9)}), null);
  assert.equal(p.mergeAcknowledgementProjection({conversationId: id,
    conversation, existing: read, acknowledgedAt: at(11)}), null);
});
test('reversed positional mapping resolves sender', () => {
  const reversed = {...conversation,
    participantChildIds: ['child-b', 'child-a'],
    participantParentIds: ['parent-b', 'parent-a']};
  assert.deepEqual(p.resolveMessage(message(), 'm1',
      p.resolveConversation(reversed, id)), {senderIndex: 1, receiverIndex: 0});
});
test('conversation path must equal friendship identity', () => {
  assert.throws(() => p.resolveConversation(conversation, 'wrong'),
      p.ProjectionValidationError);
});
test('malformed mappings and senders fail closed', () => {
  assert.throws(() => p.resolveConversation({...conversation,
    participantChildIds: ['child-a']}, id), p.ProjectionValidationError);
  const participants = p.resolveConversation(conversation, id);
  assert.throws(() => p.resolveMessage(message({senderUid: 'child-c'}),
      'm1', participants), p.ProjectionValidationError);
  assert.throws(() => p.resolveMessage(message({senderParentId: 'parent-b'}),
      'm1', participants), p.ProjectionValidationError);
});
test('missing projection reconstructs canonical base fields', () => {
  const result = project();
  assert.equal(result.conversationId, id);
  assert.equal(result.friendshipId, id);
  assert.equal(result.projectionVersion, 2);
});
