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
}
