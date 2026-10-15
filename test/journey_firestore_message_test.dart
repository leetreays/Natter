import 'package:flutter_test/flutter_test.dart';
import 'package:natter/journey/journey_activity_evidence.dart';
import 'package:natter/journey/journey_message_adapter.dart';

void main() {
  test('existing Firestore message is provisional', () {
    const adapter = JourneyMessageAdapter();

    final record = adapter.activityFor(
      messageId: 'message-1',
      childId: 'child-a',
      data: {
        'senderUid': 'child-a',
        'createdAtMs': 1792000000000,
        'isFlagged': false,
      },
    );

    expect(record, isNotNull);
    expect(record!.status, JourneyActivityStatus.unverified);
  });

  test('flagged Firestore message is not independent', () {
    const adapter = JourneyMessageAdapter();

    final record = adapter.activityFor(
      messageId: 'message-2',
      childId: 'child-a',
      data: {
        'senderUid': 'child-a',
        'createdAtMs': 1792000000000,
        'isFlagged': true,
      },
    );

    expect(record!.status, JourneyActivityStatus.flagged);
  });
}
