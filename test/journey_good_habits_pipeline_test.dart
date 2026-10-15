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

  test('historical messages remain unverified', () {
    final result = const JourneyGoodHabitsPipeline().analyze('child-a', [
      JourneyMessageEvidence('old', {
        'senderUid': 'child-a',
        'createdAtMs': 1791936000000,
      }),
    ]);
    expect(result.unverifiedDays, 1);
    expect(result.independentActivityDays, 0);
  });

  test('missing sender is excluded', () {
    final result = const JourneyGoodHabitsPipeline().analyze('child-a', [
      JourneyMessageEvidence('missing', {'createdAtMs': 1791936000000}),
    ]);
    expect(result.activeDays, 0);
  });

  test('missing timestamp is excluded', () {
    final result = const JourneyGoodHabitsPipeline().analyze('child-a', [
      JourneyMessageEvidence('missing', {'senderUid': 'child-a'}),
    ]);
    expect(result.activeDays, 0);
  });

  test('invalid timestamp is excluded', () {
    final result = const JourneyGoodHabitsPipeline().analyze('child-a', [
      JourneyMessageEvidence('invalid', {
        'senderUid': 'child-a',
        'createdAtMs': 'not-a-timestamp',
      }),
    ]);
    expect(result.activeDays, 0);
  });

  test('guided and protected activity is not independent', () {
    final result = const JourneyGoodHabitsPipeline().analyze('child-a', [
      JourneyMessageEvidence('guided', {
        'senderUid': 'child-a',
        'createdAtMs': 1791936000000,
        'journeySendRoute': 'direct_after_guidance',
      }),
      JourneyMessageEvidence('protected', {
        'senderUid': 'child-a',
        'createdAtMs': 1791936000000,
        'isFlagged': true,
      }),
    ]);
    expect(result.activeDays, 1);
    expect(result.unverifiedDays, 1);
    expect(result.independentActivityDays, 0);
  });
}
