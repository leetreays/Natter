from pathlib import Path

functions_path = Path('functions/index.js')
package_path = Path('package.json')

text = functions_path.read_text()
start_marker = "  const requestRef = db.collection('friend_requests').doc(requestId);\n"
end_marker = "\nexports.blockFriendRequest = onCall(async (request) => {"

start = text.find(start_marker, text.find('exports.approveFriendRequest'))
end = text.find(end_marker, start)
if start == -1 or end == -1:
    raise SystemExit('Could not locate approveFriendRequest replacement boundaries.')

current = text[start:end]
if 'return db.runTransaction' in current:
    raise SystemExit('approveFriendRequest already appears transaction-hardened; refusing to reapply.')
if 'const batch = db.batch();' not in current:
    raise SystemExit('Expected pre-transaction approval batch was not found; refusing to modify.')
if "collection('conversation_refs')" not in current:
    raise SystemExit('Phase 1 conversation_refs writes were not found; refusing to modify.')

replacement = r'''  const requestRef = db.collection('friend_requests').doc(requestId);

  return db.runTransaction(async (transaction) => {
    const requestSnap = await transaction.get(requestRef);

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

    const requiredIdentityFields = [
      'requesterChildId',
      'requesterParentId',
      'recipientChildId',
      'recipientParentId',
    ];
    const hasValidIdentity = requiredIdentityFields.every((field) =>
      typeof data[field] === 'string' &&
        data[field].trim().length > 0 &&
        data[field] === data[field].trim(),
    );

    if (!hasValidIdentity) {
      throw new HttpsError(
          'failed-precondition',
          'Friend request has invalid participant identity.',
      );
    }

    if (data.recipientParentId !== request.auth.uid) {
      throw new HttpsError(
          'permission-denied',
          'Only the recipient parent can approve this request.',
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
    const requesterConversationRef = db
        .collection('parents')
        .doc(requesterParentId)
        .collection('children')
        .doc(requesterChildId)
        .collection('conversation_refs')
        .doc(conversationId);
    const recipientConversationRef = db
        .collection('parents')
        .doc(recipientParentId)
        .collection('children')
        .doc(recipientChildId)
        .collection('conversation_refs')
        .doc(conversationId);

    transaction.set(friendshipRef, {
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
      friendshipHealth: 0,
      friendshipStage: 'seedling',
      lastFriendshipStage: 'seedling',

      blockedByChildIds: [],
      blockedAtByChildId: {},

      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: false});

    const seedlingMomentRef = friendshipRef
        .collection('friendship_moments')
        .doc();

    transaction.set(seedlingMomentRef, {
      type: 'friendship_started',
      fromStage: '',
      toStage: 'seedling',
      title: 'Seedling Friendship',
      description: 'This friendship has begun.',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.set(conversationRef, {
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

    const conversationReferenceData = {
      conversationId,
      friendshipId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    transaction.set(requesterConversationRef, conversationReferenceData, {
      merge: false,
    });
    transaction.set(recipientConversationRef, conversationReferenceData, {
      merge: false,
    });

    transaction.set(requestRef, {
      status: 'approved',
      respondedAt: admin.firestore.FieldValue.serverTimestamp(),
      respondedByParentId: request.auth.uid,
    }, {merge: true});

    return {
      ok: true,
      friendshipId,
      conversationId,
    };
  });
});
'''

functions_path.write_text(text[:start] + replacement + text[end:])

package = package_path.read_text()
if 'test:approve-friend-request' not in package:
    old = '    "test:firestore-rules": "firebase emulators:exec --only firestore \\"node --test test/firestore.rules.test.js\\""\n'
    # The file contains literal JSON quotes rather than Python-escaped backslashes.
    old = '    "test:firestore-rules": "firebase emulators:exec --only firestore \\\"node --test test/firestore.rules.test.js\\\""\n'
    if old not in package:
        old = '    "test:firestore-rules": "firebase emulators:exec --only firestore \\"node --test test/firestore.rules.test.js\\""\n'
    if old not in package:
        # Straight literal form as it appears in package.json.
        old = '    "test:firestore-rules": "firebase emulators:exec --only firestore \\\"node --test test/firestore.rules.test.js\\\""\n'
    # Simpler line-oriented insertion to avoid reformatting the JSON.
    lines = package.splitlines()
    idx = next((i for i, line in enumerate(lines) if '"test:firestore-rules"' in line), None)
    if idx is None:
        raise SystemExit('Could not find test:firestore-rules script in package.json.')
    if lines[idx].rstrip().endswith(','):
        raise SystemExit('Unexpected package.json script shape; refusing to modify.')
    lines[idx] = lines[idx] + ','
    lines.insert(idx + 1, '    "test:approve-friend-request": "firebase emulators:exec --only auth,firestore,functions \\\"node --test test/approve-friend-request.callable.test.js\\\""')
    package_path.write_text('\n'.join(lines) + ('\n' if package.endswith('\n') else ''))

print('Applied approveFriendRequest transaction hardening and package test script.')
