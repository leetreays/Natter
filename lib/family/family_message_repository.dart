import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The family thread is per child and intentionally separate from friendships.
String familyMessagesPath({
  required String parentId,
  required String childId,
}) {
  if (parentId.isEmpty || childId.isEmpty ||
      parentId.contains('/') || childId.contains('/')) {
    throw ArgumentError('Invalid family thread identity');
  }
  return 'parents/$parentId/children/$childId/family_messages';
}

/// A family message's role is set by Firestore security rules at creation,
/// and remains stable if a child's linked device/auth UID changes later.
bool familyMessageIsMine(Map<String, dynamic> data, {required bool asParent}) =>
    data['senderRole'] == (asParent ? 'parent' : 'child');

/// Count messages from the *other* family participant newer than this
/// participant's last-read marker. No parent/child Firebase IDs are compared.
int countUnreadFamilyMessages(
  Iterable<Map<String, dynamic>> messages, {
  required bool asParent,
  Timestamp? lastReadAt,
}) {
  var unread = 0;
  for (final message in messages) {
    if (familyMessageIsMine(message, asParent: asParent)) continue;
    final senderRole = message['senderRole'];
    if (senderRole != 'parent' && senderRole != 'child') continue;
    final createdAt = message['createdAt'];
    if (createdAt is! Timestamp) continue;
    if (lastReadAt == null ||
        createdAt.toDate().isAfter(lastReadAt.toDate())) {
      unread++;
    }
  }
  return unread;
}

class FamilyMessageRepository {
  const FamilyMessageRepository({
    required this.parentId,
    required this.childId,
  });

  final String parentId;
  final String childId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection(
        familyMessagesPath(parentId: parentId, childId: childId),
      );

  DocumentReference<Map<String, dynamic>> _readDocument(bool asParent) =>
      _collection.parent.collection('family_read_state')
          .doc(asParent ? 'parent' : 'child');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages() =>
      _collection.orderBy('createdAt', descending: true).limit(100).snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchReadState({
    required bool asParent,
  }) => _readDocument(asParent).snapshots();

  Future<void> markRead({required bool asParent}) async {
    await _readDocument(asParent).set({
      'lastReadAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendMessage({
    required String text,
    required bool asParent,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > 5000) {
      throw ArgumentError('Family message is too long');
    }
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid == null || authUid.isEmpty) {
      throw StateError('No authenticated family participant');
    }
    await _collection.add({
      'text': trimmed,
      'senderRole': asParent ? 'parent' : 'child',
      'senderAuthUid': authUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
