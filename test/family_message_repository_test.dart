import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natter/family/family_message_repository.dart';

void main() {
  test('family conversation path is distinct from friendship messages', () {
    expect(
      familyMessagesPath(parentId: 'parent-a', childId: 'child-a'),
      'parents/parent-a/children/child-a/family_messages',
    );
  });

  test('a family thread requires both valid document identifiers', () {
    expect(
      () => familyMessagesPath(parentId: '', childId: 'child-a'),
      throwsArgumentError,
    );
    expect(
      () => familyMessagesPath(parentId: 'parent-a', childId: 'child/a'),
      throwsArgumentError,
    );
  });
  test('family bubble ownership survives a child auth relink', () {
    final childMessage = {
      'senderRole': 'child',
      'senderAuthUid': 'previous-device-auth',
    };
    expect(familyMessageIsMine(childMessage, asParent: false), isTrue);
    expect(familyMessageIsMine(childMessage, asParent: true), isFalse);
    expect(
      familyMessageIsMine({'senderRole': 'parent'}, asParent: true),
      isTrue,
    );
  });

  test('unread counts exclude our messages and previously read messages', () {
    final earlier = Timestamp.fromDate(DateTime.utc(2026, 11, 1));
    final lastRead = Timestamp.fromDate(DateTime.utc(2026, 11, 2));
    final later = Timestamp.fromDate(DateTime.utc(2026, 11, 3));
    final messages = <Map<String, dynamic>>[
      {'senderRole': 'parent', 'createdAt': earlier},
      {'senderRole': 'child', 'createdAt': later},
      {'senderRole': 'parent', 'createdAt': later},
    ];
    expect(
      countUnreadFamilyMessages(
        messages, asParent: false, lastReadAt: lastRead,
      ),
      1,
    );
    expect(
      countUnreadFamilyMessages(
        messages, asParent: true, lastReadAt: lastRead,
      ),
      1,
    );
    expect(
      countUnreadFamilyMessages(messages, asParent: false),
      2,
    );
  });

  test('pending or invalid timestamps cannot create unread badges', () {
    final messages = <Map<String, dynamic>>[
      {'senderRole': 'parent', 'createdAt': null},
      {'senderRole': 'parent', 'createdAt': 'yesterday'},
      {'senderRole': 'unknown', 'createdAt': Timestamp.now()},
    ];
    expect(countUnreadFamilyMessages(messages, asParent: false), 0);
  });

}
