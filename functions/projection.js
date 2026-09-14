'use strict';

const {FieldValue, Timestamp} = require('firebase-admin/firestore');
const PROJECTION_VERSION = 1;
const PROTECTED_PREVIEW = 'Message needs review';
class ProjectionValidationError extends Error {}
const nonEmptyString = (value) => typeof value === 'string' && value.trim().length > 0;
const isTimestamp = (value) => value instanceof Timestamp;
function compareTimestamps(a, b) {
  return a.seconds - b.seconds || a.nanoseconds - b.nanoseconds;
}
function compareTuple(aTime, aId, bTime, bId) {
  if (!isTimestamp(aTime) || !nonEmptyString(aId)) return -1;
  if (!isTimestamp(bTime) || !nonEmptyString(bId)) return 1;
  return compareTimestamps(aTime, bTime) || (aId > bId ? 1 : aId < bId ? -1 : 0);
}
function latestTimestamp(a, b) {
  if (!isTimestamp(a)) return isTimestamp(b) ? b : null;
  if (!isTimestamp(b)) return a;
  return compareTimestamps(a, b) >= 0 ? a : b;
}
function hasUnread(receivedAt, acknowledgedAt) {
  return isTimestamp(receivedAt) && (!isTimestamp(acknowledgedAt) ||
    compareTimestamps(receivedAt, acknowledgedAt) > 0);
}
function safePreview(message) {
  if (message.isFlagged === true) return PROTECTED_PREVIEW;
  if (typeof message.text !== 'string') {
    throw new ProjectionValidationError('invalid ordinary message text');
  }
  return message.text;
}
function resolveConversation(data, conversationId) {
  if (!data || !nonEmptyString(conversationId) ||
      data.friendshipId !== conversationId || !isTimestamp(data.createdAt) ||
      !Array.isArray(data.participantChildIds) ||
      !Array.isArray(data.participantParentIds) ||
      data.participantChildIds.length !== 2 ||
      data.participantParentIds.length !== 2 ||
      !data.participantChildIds.every(nonEmptyString) ||
      !data.participantParentIds.every(nonEmptyString) ||
      data.participantChildIds[0] === data.participantChildIds[1]) {
    throw new ProjectionValidationError('invalid conversation identity');
  }
  return [0, 1].map((index) => ({
    childId: data.participantChildIds[index],
    parentId: data.participantParentIds[index],
  }));
}
function resolveMessage(message, messageId, participants) {
  if (!message || !nonEmptyString(messageId) ||
      !nonEmptyString(message.senderUid) ||
      !nonEmptyString(message.senderParentId) ||
      !isTimestamp(message.createdAt) || typeof message.isFlagged !== 'boolean') {
    throw new ProjectionValidationError('invalid message metadata');
  }
  const senderIndex = participants.findIndex((p) => p.childId === message.senderUid);
  if (senderIndex < 0 || participants[senderIndex].parentId !== message.senderParentId) {
    throw new ProjectionValidationError('invalid message sender');
  }
  return {senderIndex, receiverIndex: senderIndex === 0 ? 1 : 0};
}
const timestampOrNull = (value) => isTimestamp(value) ? value : null;
const stringOrNull = (value) => nonEmptyString(value) ? value : null;
function baseProjection(conversationId, conversation, existing) {
  if (existing && (existing.conversationId !== conversationId ||
      existing.friendshipId !== conversation.friendshipId ||
      !isTimestamp(existing.createdAt) ||
      compareTimestamps(existing.createdAt, conversation.createdAt) !== 0)) {
    throw new ProjectionValidationError('invalid existing projection identity');
  }
  return {
    conversationId,
    friendshipId: conversation.friendshipId,
    createdAt: conversation.createdAt,
    projectionVersion: PROJECTION_VERSION,
    summaryMessageId: stringOrNull(existing && existing.summaryMessageId),
    lastMessagePreview: typeof (existing && existing.lastMessagePreview) === 'string' ?
      existing.lastMessagePreview : '',
    lastMessageSenderChildId: stringOrNull(existing && existing.lastMessageSenderChildId),
    lastMessageAt: timestampOrNull(existing && existing.lastMessageAt),
    latestReceivedMessageId: stringOrNull(existing && existing.latestReceivedMessageId),
    latestReceivedAt: timestampOrNull(existing && existing.latestReceivedAt),
    acknowledgedAt: timestampOrNull(existing && existing.acknowledgedAt),
    hasUnread: false,
  };
}
function equalValue(a, b) {
  return a === b || (isTimestamp(a) && isTimestamp(b) && compareTimestamps(a, b) === 0);
}
function unchanged(existing, next) {
  return Boolean(existing) && Object.entries(next).every(([key, value]) =>
    equalValue(existing[key], value));
}
function mergeMessageProjection(options) {
  const {conversationId, conversation, existing, message, messageId,
    isReceiver, acknowledgedAt} = options;
  const next = baseProjection(conversationId, conversation, existing);
  next.acknowledgedAt = latestTimestamp(next.acknowledgedAt, acknowledgedAt);
  if (compareTuple(message.createdAt, messageId,
      next.lastMessageAt, next.summaryMessageId) > 0) {
    next.summaryMessageId = messageId;
    next.lastMessagePreview = safePreview(message);
    next.lastMessageSenderChildId = message.senderUid;
    next.lastMessageAt = message.createdAt;
  }
  if (isReceiver && compareTuple(message.createdAt, messageId,
      next.latestReceivedAt, next.latestReceivedMessageId) > 0) {
    next.latestReceivedMessageId = messageId;
    next.latestReceivedAt = message.createdAt;
  }
  next.hasUnread = hasUnread(next.latestReceivedAt, next.acknowledgedAt);
  return unchanged(existing, next) ? null : next;
}
function mergeAcknowledgementProjection(options) {
  const {conversationId, conversation, existing, acknowledgedAt} = options;
  const next = baseProjection(conversationId, conversation, existing);
  next.acknowledgedAt = latestTimestamp(next.acknowledgedAt, acknowledgedAt);
  next.hasUnread = hasUnread(next.latestReceivedAt, next.acknowledgedAt);
  return unchanged(existing, next) ? null : next;
}
function projectionRef(db, participant, conversationId) {
  return db.doc(`parents/${participant.parentId}/children/${participant.childId}` +
    `/conversation_refs/${conversationId}`);
}
function readStateRef(db, conversationId, childId) {
  return db.doc(`conversations/${conversationId}/read_state/${childId}`);
}
async function processMessageProjection(db, conversationId, messageId, message) {
  return db.runTransaction(async (transaction) => {
    const conversationRef = db.doc(`conversations/${conversationId}`);
    const conversationSnapshot = await transaction.get(conversationRef);
    if (!conversationSnapshot.exists) throw new ProjectionValidationError('missing conversation');
    const conversation = conversationSnapshot.data();
    const participants = resolveConversation(conversation, conversationId);
    const {receiverIndex} = resolveMessage(message, messageId, participants);
    const refs = participants.map((p) => projectionRef(db, p, conversationId));
    const readRefs = participants.map((p) => readStateRef(db, conversationId, p.childId));
    const snapshots = await transaction.getAll(...refs, ...readRefs);
    for (let index = 0; index < 2; index += 1) {
      const readData = snapshots[index + 2].exists ? snapshots[index + 2].data() : null;
      const next = mergeMessageProjection({
        conversationId, conversation, message, messageId,
        existing: snapshots[index].exists ? snapshots[index].data() : null,
        isReceiver: index === receiverIndex,
        acknowledgedAt: readData && isTimestamp(readData.lastReadAt) ?
          readData.lastReadAt : null,
      });
      if (next) {
        transaction.set(refs[index], {...next,
          projectionUpdatedAt: FieldValue.serverTimestamp()}, {merge: true});
      }
    }
  });
}
async function processReadStateProjection(db, conversationId, childId, readState) {
  if (!readState || !isTimestamp(readState.lastReadAt)) {
    throw new ProjectionValidationError('invalid read acknowledgement');
  }
  return db.runTransaction(async (transaction) => {
    const conversationSnapshot = await transaction.get(
        db.doc(`conversations/${conversationId}`));
    if (!conversationSnapshot.exists) throw new ProjectionValidationError('missing conversation');
    const conversation = conversationSnapshot.data();
    const participants = resolveConversation(conversation, conversationId);
    const participant = participants.find((p) => p.childId === childId);
    if (!participant) throw new ProjectionValidationError('unknown read-state child');
    const ref = projectionRef(db, participant, conversationId);
    const snapshot = await transaction.get(ref);
    const next = mergeAcknowledgementProjection({
      conversationId, conversation,
      existing: snapshot.exists ? snapshot.data() : null,
      acknowledgedAt: readState.lastReadAt,
    });
    if (next) {
      transaction.set(ref, {...next,
        projectionUpdatedAt: FieldValue.serverTimestamp()}, {merge: true});
    }
  });
}
module.exports = {PROTECTED_PREVIEW, ProjectionValidationError, compareTuple,
  compareTimestamps, latestTimestamp, isTimestamp, hasUnread, safePreview,
  resolveConversation, resolveMessage, baseProjection, unchanged,
  mergeMessageProjection, mergeAcknowledgementProjection,
  processMessageProjection, processReadStateProjection};
