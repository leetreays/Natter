import 'package:flutter_test/flutter_test.dart';
import 'package:natter/journey/journey_good_habits_pipeline.dart';

void main() {
  test('message evidence remains cautious and child-specific', () {
    final time = DateTime.utc(2026, 10, 14).millisecondsSinceEpoch;
    JourneyMessageEvidence msg(String id, String sender, String route) =>
        JourneyMessageEvidence(id, {
          'senderUid': sender,
          'createdAtMs': time,
          'journeySendRoute': route,
          'isFlagged': route == 'protected_delivery',
        });

    final result = const JourneyGoodHabitsPipeline().analyze('child-a', [
      msg('1', 'child-a', 'direct_unflagged'),
      msg('2', 'child-a', 'protected_delivery'),
      msg('3', 'child-b', 'direct_unflagged'),
      msg('1', 'child-a', 'direct_unflagged'),
    ]);

    expect(result.activeDays, 1);
    expect(result.unverifiedDays, 1);
    expect(result.independentActivityDays, 0);
  });
}
