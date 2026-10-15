import 'package:flutter_test/flutter_test.dart';
import 'package:natter/journey/journey_activity_evidence.dart';
import 'package:natter/journey/journey_good_habits.dart';

void main() {
  const analyzer = JourneyGoodHabitsAnalyzer();

  JourneyActivityRecord record(
    String id,
    int day, {
    bool flagged = false,
    bool verified = false,
  }) {
    return JourneyActivityRecord(
      id: id,
      occurredAt: DateTime.utc(2026, 10, day),
      isFlagged: flagged,
      independenceVerified: verified,
    );
  }

  test('verified activity across days is counted by day', () {
    final result = analyzer.analyze([
      record('a', 1, verified: true),
      record('b', 1, verified: true),
      record('c', 2, verified: true),
    ]);

    expect(result.activeDays, 2);
    expect(result.independentActivityDays, 2);
  });

  test('verified and flagged activity makes a mixed day', () {
    final result = analyzer.analyze([
      record('a', 1, verified: true),
      record('b', 1, flagged: true),
    ]);

    expect(result.mixedDays, 1);
    expect(result.independentActivityDays, 0);
  });

  test('unverified messages never prove independence', () {
    final result = analyzer.analyze([record('a', 1), record('b', 2)]);

    expect(result.unverifiedDays, 2);
    expect(result.independentActivityDays, 0);
  });

  test('flagged-only activity is classified separately', () {
    final result = analyzer.analyze([record('a', 1, flagged: true)]);

    expect(result.flaggedOnlyDays, 1);
  });

  test('duplicate IDs do not change the result', () {
    final result = analyzer.analyze([
      record('a', 1, verified: true),
      record('a', 2, flagged: true),
    ]);

    expect(result.activeDays, 1);
    expect(result.independentActivityDays, 1);
  });

  test('missing timestamps are excluded', () {
    final result = analyzer.analyze([
      const JourneyActivityRecord(id: 'a', occurredAt: null, isFlagged: false),
    ]);

    expect(result.activeDays, 0);
  });

  test('verified and unverified activity makes a mixed day', () {
    final result = analyzer.analyze([
      record('a', 1, verified: true),
      record('b', 1),
    ]);

    expect(result.mixedDays, 1);
    expect(result.independentActivityDays, 0);
  });
}
