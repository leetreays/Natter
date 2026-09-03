import 'package:flutter_test/flutter_test.dart';
import 'package:natter/utils/participant_parent_mapping.dart';

void main() {
  group('participantParentIdForChild', () {
    test('maps the child at index 0 to the parent at index 0', () {
      expect(
        participantParentIdForChild(
          participantChildIds: const ['child-a', 'child-b'],
          participantParentIds: const ['parent-a', 'parent-b'],
          senderChildId: 'child-a',
        ),
        'parent-a',
      );
    });

    test('maps the child at index 1 to the parent at index 1', () {
      expect(
        participantParentIdForChild(
          participantChildIds: const ['child-a', 'child-b'],
          participantParentIds: const ['parent-a', 'parent-b'],
          senderChildId: 'child-b',
        ),
        'parent-b',
      );
    });

    test('maps by identity when requester and recipient order is reversed', () {
      expect(
        participantParentIdForChild(
          participantChildIds: const ['child-b', 'child-a'],
          participantParentIds: const ['parent-b', 'parent-a'],
          senderChildId: 'child-a',
        ),
        'parent-a',
      );
    });

    test('returns null for an unknown child', () {
      expect(
        participantParentIdForChild(
          participantChildIds: const ['child-a', 'child-b'],
          participantParentIds: const ['parent-a', 'parent-b'],
          senderChildId: 'child-c',
        ),
        isNull,
      );
    });

    test('returns null when the matching parent position is missing', () {
      expect(
        participantParentIdForChild(
          participantChildIds: const ['child-a', 'child-b'],
          participantParentIds: const ['parent-a'],
          senderChildId: 'child-b',
        ),
        isNull,
      );
    });

    test('returns null when the matching parent ID is empty', () {
      expect(
        participantParentIdForChild(
          participantChildIds: const ['child-a'],
          participantParentIds: const [''],
          senderChildId: 'child-a',
        ),
        isNull,
      );
    });

    test('returns null for an empty sender child ID', () {
      expect(
        participantParentIdForChild(
          participantChildIds: const ['child-a'],
          participantParentIds: const ['parent-a'],
          senderChildId: '',
        ),
        isNull,
      );
    });

    test('returns null for a whitespace-only sender child ID', () {
      expect(
        participantParentIdForChild(
          participantChildIds: const ['child-a'],
          participantParentIds: const ['parent-a'],
          senderChildId: '   ',
        ),
        isNull,
      );
    });

    test('returns null when the matching parent ID is whitespace-only', () {
      expect(
        participantParentIdForChild(
          participantChildIds: const ['child-a'],
          participantParentIds: const ['   '],
          senderChildId: 'child-a',
        ),
        isNull,
      );
    });

    test('returns null when participant child data is not a list', () {
      expect(
        participantParentIdForChild(
          participantChildIds: 'child-a',
          participantParentIds: const ['parent-a'],
          senderChildId: 'child-a',
        ),
        isNull,
      );
    });

    test('returns null when participant parent data is not a list', () {
      expect(
        participantParentIdForChild(
          participantChildIds: const ['child-a'],
          participantParentIds: {'child-a': 'parent-a'},
          senderChildId: 'child-a',
        ),
        isNull,
      );
    });

    test('returns null when the matching parent value is not a string', () {
      expect(
        participantParentIdForChild(
          participantChildIds: const ['child-a'],
          participantParentIds: const [123],
          senderChildId: 'child-a',
        ),
        isNull,
      );
    });
  });
}
