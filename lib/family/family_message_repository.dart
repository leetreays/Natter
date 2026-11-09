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

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages() =>
      _collection.orderBy('createdAt', descending: true).limit(100).snapshots();

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
