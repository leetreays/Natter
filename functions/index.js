const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {setGlobalOptions} = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();

// Keep defaults simple and explicit.
setGlobalOptions({
  region: 'europe-west2',
  memory: '256MiB',
  timeoutSeconds: 30,
});

const db = admin.firestore();

async function getVerifiedLinkedChild(parentId, childId, authUid) {
  if (!parentId || !childId) {
    throw new HttpsError(
        'invalid-argument',
        'requesterParentId and requesterChildId are required.',
    );
  }

  const childRef = db
      .collection('parents')
      .doc(parentId)
      .collection('children')
      .doc(childId);

  const childSnap = await childRef.get();

  if (!childSnap.exists) {
    throw new HttpsError(
        'not-found',
        'Requester child profile not found.',
    );
  }

  const data = childSnap.data() || {};

  if (data.linkedAuthUid !== authUid) {
    throw new HttpsError(
        'permission-denied',
        'Signed-in user is not linked to this child.',
    );
  }

  return {
    parentId,
    childId,
    name: data.name || '',
    friendCode: data.friendCode || '',
    ref: childRef,
    data,
  };
}

async function getChildByFriendCode(friendCode) {
  const codeRef = db.collection('child_friend_codes').doc(friendCode);
  const codeSnap = await codeRef.get();

  if (!codeSnap.exists) {
    throw new HttpsError('not-found', 'Friend code not found.');
  }

  const codeData = codeSnap.data() || {};
  const parentId = codeData.parentId;
  const childId = codeData.childId;

  if (!parentId || !childId) {
    throw new HttpsError(
        'failed-precondition',
        'Friend code record is missing parentId or childId.',
    );
  }

  const childSnap = await db
      .collection('parents')
      .doc(parentId)
      .collection('children')
      .doc(childId)
      .get();

  if (!childSnap.exists) {
    throw new HttpsError('not-found', 'Target child profile not found.');
  }

  const childData = childSnap.data() || {};

  return {
    parentId,
    childId,
    name: childData.name || '',
    friendCode: childData.friendCode || friendCode,
    ref: childSnap.ref,
    data: childData,
  };
}

exports.createFriendRequest = onCall(async (request) => {
  try {
    console.log('STEP 1: callable entered');

    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'You must be signed in.');
    }

    console.log('STEP 2: auth present', request.auth.uid);

    const targetFriendCode = String(
        (request.data && request.data.targetFriendCode) || '',
    ).trim();

    const requesterParentId = String(
        (request.data && request.data.requesterParentId) || '',
    ).trim();

    const requesterChildId = String(
        (request.data && request.data.requesterChildId) || '',
    ).trim();

    console.log('STEP 3: targetFriendCode', targetFriendCode);

    if (!targetFriendCode) {
      throw new HttpsError(
          'invalid-argument',
          'targetFriendCode is required.',
      );
    }

    console.log('STEP 4: before requester lookup');
    const requester = await getVerifiedLinkedChild(
        requesterParentId,
        requesterChildId,
        request.auth.uid,
    );
    console.log('STEP 5: requester resolved', requester.childId);

    console.log('STEP 6: before recipient lookup');
    const recipient = await getChildByFriendCode(targetFriendCode);
    console.log('STEP 7: recipient resolved', recipient.childId);

    if (requester.childId === recipient.childId) {
      throw new HttpsError(
          'invalid-argument',
          'A child cannot add themselves as a friend.',
      );
    }

    console.log('STEP 8: before request write');
    const pair = [requester.childId, recipient.childId].sort();
    const requestId = `${pair[0]}_${pair[1]}`;
    const requestRef = db.collection('friend_requests').doc(requestId);

    await requestRef.set({
      status: 'pending',

      requesterParentId: requester.parentId,
      requesterChildId: requester.childId,
      requesterChildName: requester.name,
      requesterFriendCode: requester.friendCode,

      recipientParentId: recipient.parentId,
      recipientChildId: recipient.childId,
      recipientChildName: recipient.name,
      recipientFriendCode: recipient.friendCode,

      participantChildIds: [requester.childId, recipient.childId],
      participantParentIds: [requester.parentId, recipient.parentId],

      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      respondedAt: null,
      respondedByParentId: null,
    }, {merge: false});

    console.log('STEP 9: request write complete');

    return {
      ok: true,
      requestId: requestRef.id,
      recipientChildName: recipient.name,
    };
  } catch (error) {
    console.error('createFriendRequest failed', error);
    throw error;
  }
});

exports.approveFriendRequest = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }

  const requestId = String(
      (request.data && request.data.requestId) || '',
  ).trim();

  if (!requestId) {
    throw new HttpsError(
        'invalid-argument',
        'requestId is required.',
    );
  }

  const requestRef = db.collection('friend_requests').doc(requestId);
  const requestSnap = await requestRef.get();

  if (!requestSnap.exists) {
    throw new HttpsError(
        'not-found',
        'Friend request not found.',
    );
  }

  const data = requestSnap.data() || {};

  if (data.status !== 'pending') {
    throw new HttpsError(
        'failed-precondition',
        'Request is not pending.',
    );
  }

  const {
    requesterChildId,
    requesterParentId,
    requesterChildName,
    requesterFriendCode,
    recipientChildId,
    recipientParentId,
    recipientChildName,
    recipientFriendCode,
  } = data;

  const pair = [requesterChildId, recipientChildId].sort();
  const friendshipId = `${pair[0]}_${pair[1]}`;
  const conversationId = friendshipId;

  const friendshipRef = db.collection('friendships').doc(friendshipId);
  const conversationRef = db.collection('conversations').doc(conversationId);

  const batch = db.batch();

  batch.set(friendshipRef, {
    childIds: [requesterChildId, recipientChildId],
    parentIds: [requesterParentId, recipientParentId],

    children: {
      [requesterChildId]: {
        parentId: requesterParentId,
        name: requesterChildName,
        friendCode: requesterFriendCode,
      },
      [recipientChildId]: {
        parentId: recipientParentId,
        name: recipientChildName,
        friendCode: recipientFriendCode,
      },
    },

    status: 'active',
    blockedByChildIds: [],
    blockedAtByChildId: {},

    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: false});

  batch.set(conversationRef, {
    friendshipId: friendshipId,
    participantChildIds: [requesterChildId, recipientChildId],
    participantParentIds: [requesterParentId, recipientParentId],
    participantNames: [requesterChildName, recipientChildName],

    status: 'active',
    blockedByChildIds: [],

    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastMessage: '',
    lastMessageSenderChildId: null,
    lastMessageAt: null,
  }, {merge: false});

  batch.set(requestRef, {
    status: 'approved',
    respondedAt: admin.firestore.FieldValue.serverTimestamp(),
    respondedByParentId: request.auth.uid,
  }, {merge: true});

  await batch.commit();

  return {
    ok: true,
    friendshipId,
    conversationId,
  };
});

exports.blockFriendRequest = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }

  const requestId = String(request.data && request.data.requestId || '').trim();

  if (!requestId) {
    throw new HttpsError('invalid-argument', 'requestId is required.');
  }

  const parentId = request.auth.uid;
  const friendRequestRef = db.collection('friend_requests').doc(requestId);
  const friendRequestSnap = await friendRequestRef.get();

  if (!friendRequestSnap.exists) {
    throw new HttpsError('not-found', 'Friend request not found.');
  }

  const fr = friendRequestSnap.data() || {};

  if (fr.recipientParentId !== parentId) {
    throw new HttpsError(
        'permission-denied',
        'Only the recipient parent can block this request.',
    );
  }

  if (fr.status !== 'pending') {
    throw new HttpsError(
        'failed-precondition',
        'This request is no longer pending.',
    );
  }

  await friendRequestRef.set(
      {
        status: 'blocked',
        respondedAt: admin.firestore.FieldValue.serverTimestamp(),
        respondedByParentId: parentId,
      },
      {merge: true},
  );

  return {ok: true};
});
