'use strict';
const {FieldPath, FieldValue} = require('firebase-admin/firestore');
const {
  ProjectionValidationError,
  baseProjection,
  compareTuple,
  hasUnread,
  isTimestamp,
  latestTimestamp,
  mergeMessageProjection,
  resolveConversation,
  resolveMessage,
  safePreview,
  unchanged,
} = require('../projection');
const REASONS = Object.freeze({
  MALFORMED_CONVERSATION: 'MALFORMED_CONVERSATION',
  MISSING_CHILD_PROFILE: 'MISSING_CHILD_PROFILE',
  MALFORMED_MESSAGE: 'MALFORMED_MESSAGE',
  MALFORMED_READ_STATE: 'MALFORMED_READ_STATE',
  CONFLICTING_REF_IDENTITY: 'CONFLICTING_REF_IDENTITY',
});
const SEMANTIC_FIELDS = Object.freeze([
  'conversationId', 'friendshipId', 'createdAt', 'projectionVersion',
  'summaryMessageId', 'lastMessagePreview', 'lastMessageSenderChildId',
  'lastMessageAt', 'latestReceivedMessageId', 'latestReceivedAt',
  'acknowledgedAt', 'hasUnread',
]);
function emptyProjection(conversationId, conversation, acknowledgedAt) {
  return {
    ...baseProjection(conversationId, conversation, null),
    acknowledgedAt,
    hasUnread: false,
  };
}
function reconstructProjection(conversationId, conversation, messages,
    acknowledgements) {
  const participants = resolveConversation(conversation, conversationId);
  const projections = participants.map((participant, index) =>
    emptyProjection(conversationId, conversation, acknowledgements[index]));
  for (const item of messages) {
    const resolved = resolveMessage(item.data, item.id, participants);
    safePreview(item.data);
    for (let index = 0; index < 2; index += 1) {
      projections[index] = mergeMessageProjection({
        conversationId,
        conversation,
        existing: projections[index],
        message: item.data,
        messageId: item.id,
        isReceiver: index === resolved.receiverIndex,
        acknowledgedAt: acknowledgements[index],
      }) || projections[index];
    }
  }
  return {participants, projections};
}
function identityConflict(existing, desired) {
  if (!existing) return false;
  return existing.conversationId !== desired.conversationId ||
existing.friendshipId !== desired.friendshipId ||
!isTimestamp(existing.createdAt) ||
existing.createdAt.seconds !== desired.createdAt.seconds ||
existing.createdAt.nanoseconds !== desired.createdAt.nanoseconds;
}
function completeSummary(value) {
  if (value.summaryMessageId === null && value.lastMessageAt === null) {
    return value.lastMessagePreview === '' &&
value.lastMessageSenderChildId === null;
  }
  return typeof value.summaryMessageId === 'string' &&
isTimestamp(value.lastMessageAt) &&
typeof value.lastMessagePreview === 'string' &&
typeof value.lastMessageSenderChildId === 'string';
}
function completeReceived(value) {
  return (value.latestReceivedMessageId === null &&
value.latestReceivedAt === null) ||
(typeof value.latestReceivedMessageId === 'string' &&
isTimestamp(value.latestReceivedAt));
}
function mergeWithCurrent(current, reconstructed) {
  const result = {...reconstructed};
  if (current && current.projectionVersion === 1) {
    if (completeSummary(current) && compareTuple(current.lastMessageAt,
        current.summaryMessageId, result.lastMessageAt,
        result.summaryMessageId) > 0) {
      result.summaryMessageId = current.summaryMessageId;
      result.lastMessagePreview = current.lastMessagePreview;
      result.lastMessageSenderChildId = current.lastMessageSenderChildId;
      result.lastMessageAt = current.lastMessageAt;
    }
    if (completeReceived(current) && compareTuple(current.latestReceivedAt,
        current.latestReceivedMessageId, result.latestReceivedAt,
        result.latestReceivedMessageId) > 0) {
      result.latestReceivedMessageId = current.latestReceivedMessageId;
      result.latestReceivedAt = current.latestReceivedAt;
    }
    result.acknowledgedAt = latestTimestamp(
        result.acknowledgedAt,
isTimestamp(current.acknowledgedAt) ? current.acknowledgedAt : null,
    );
  }
  result.hasUnread = hasUnread(result.latestReceivedAt, result.acknowledgedAt);
  return result;
}
function semanticProjection(data) {
  return Object.fromEntries(SEMANTIC_FIELDS.map((field) => [field, data[field]]));
}
function semanticallyEqual(existing, desired) {
  return unchanged(existing, semanticProjection(desired)) &&
SEMANTIC_FIELDS.every((field) => Object.hasOwn(existing, field));
}
function projectionRef(db, participant, conversationId) {
  return db.doc(`parents/${participant.parentId}/children/${participant.childId}` +
`/conversation_refs/${conversationId}`);
}
async function applyReconciliation(db, conversationId, participants,
    reconstructed, apply) {
  const refs = participants.map((participant) =>
    projectionRef(db, participant, conversationId));
  if (!apply) {
    const snapshots = await db.getAll(...refs);
    const current = snapshots.map((snapshot) =>
snapshot.exists ? snapshot.data() : null);
    if (current.some((value, index) =>
      identityConflict(value, reconstructed[index]))) {
      return {reason: REASONS.CONFLICTING_REF_IDENTITY, writes: 0};
    }
    const desired = current.map((value, index) =>
      mergeWithCurrent(value, reconstructed[index]));
    return {
      writes: desired.filter((value, index) =>
        !semanticallyEqual(current[index], value)).length,
      missing: snapshots.filter((snapshot) => !snapshot.exists).length,
    };
  }
  return db.runTransaction(async (transaction) => {
    const snapshots = await transaction.getAll(...refs);
    const current = snapshots.map((snapshot) =>
snapshot.exists ? snapshot.data() : null);
    if (current.some((value, index) =>
      identityConflict(value, reconstructed[index]))) {
      return {reason: REASONS.CONFLICTING_REF_IDENTITY, writes: 0};
    }
    const desired = current.map((value, index) =>
      mergeWithCurrent(value, reconstructed[index]));
    let writes = 0;
    for (let index = 0; index < 2; index += 1) {
      if (!semanticallyEqual(current[index], desired[index])) {
        transaction.set(refs[index], {
          ...desired[index],
          projectionUpdatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
        writes += 1;
      }
    }
    return {writes, missing: snapshots.filter((snapshot) =>
      !snapshot.exists).length};
  });
}
async function scanMessages(db, conversationId, pageSize, visit) {
  let count = 0;
  let cursor = null;
  do {
    let query = db.collection(`conversations/${conversationId}/messages`)
        .orderBy(FieldPath.documentId()).limit(pageSize);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    for (const document of page.docs) {
      await visit({id: document.id, data: document.data()});
      count += 1;
    }
    cursor = page.empty ? null : page.docs[page.docs.length - 1];
    if (page.size < pageSize) break;
  } while (cursor);
  return count;
}
async function reconcileConversation(db, snapshot, options) {
  const conversationId = snapshot.id;
  let participants;
  try {
    participants = resolveConversation(snapshot.data(), conversationId);
  } catch (error) {
    if (!(error instanceof ProjectionValidationError)) throw error;
    return {reason: REASONS.MALFORMED_CONVERSATION, writes: 0};
  }
  const childRefs = participants.map((participant) =>
    db.doc(`parents/${participant.parentId}/children/${participant.childId}`));
  const readRefs = participants.map((participant) =>
    db.doc(`conversations/${conversationId}/read_state/${participant.childId}`));
  const supporting = await db.getAll(...childRefs, ...readRefs);
  if (supporting.slice(0, 2).some((child) => !child.exists)) {
    return {reason: REASONS.MISSING_CHILD_PROFILE, writes: 0};
  }
  const acknowledgements = [];
  for (const readState of supporting.slice(2)) {
    if (!readState.exists) {
      acknowledgements.push(null);
    } else if (!isTimestamp(readState.data().lastReadAt)) {
      return {reason: REASONS.MALFORMED_READ_STATE, writes: 0};
    } else {
      acknowledgements.push(readState.data().lastReadAt);
    }
  }
  let reconstructed;
  try {
    reconstructed = reconstructProjection(conversationId, snapshot.data(),
        [], acknowledgements);
    await scanMessages(db, conversationId, options.messagePageSize,
        async (item) => {
          const resolved = resolveMessage(item.data, item.id,
              reconstructed.participants);
          safePreview(item.data);
          for (let index = 0; index < 2; index += 1) {
            reconstructed.projections[index] = mergeMessageProjection({
              conversationId,
              conversation: snapshot.data(),
              existing: reconstructed.projections[index],
              message: item.data,
              messageId: item.id,
              isReceiver: index === resolved.receiverIndex,
              acknowledgedAt: acknowledgements[index],
            }) || reconstructed.projections[index];
          }
        });
  } catch (error) {
    if (!(error instanceof ProjectionValidationError)) throw error;
    return {reason: REASONS.MALFORMED_MESSAGE, writes: 0};
  }
  return applyReconciliation(db, conversationId, reconstructed.participants,
      reconstructed.projections, options.apply);
}
module.exports = {
  REASONS,
  SEMANTIC_FIELDS,
  applyReconciliation,
  emptyProjection,
  identityConflict,
  mergeWithCurrent,
  reconstructProjection,
  reconcileConversation,
  scanMessages,
  semanticallyEqual,
};
