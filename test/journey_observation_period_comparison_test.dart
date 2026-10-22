import 'package:flutter_test/flutter_test.dart';
import 'package:natter/journey/journey_guidance_observation_summary.dart';
import 'package:natter/journey/journey_observation_period_comparison.dart';

void main() {
  const analyzer = JourneyObservationPeriodAnalyzer();
  final start = DateTime.utc(2026, 10, 1);
  final middle = DateTime.utc(2026, 10, 8);
  final end = DateTime.utc(2026, 10, 15);

  JourneyGuidanceObservation message(
    String id,
    DateTime at,
    String route, {
    String child = 'child-a',
  }) =>
      JourneyGuidanceObservation(id, {
        'senderUid': child,
        'createdAtMs': at.millisecondsSinceEpoch,
        'journeySendRoute': route,
        'isFlagged': false,
      });

  JourneyObservationPeriodComparison compare(
    Iterable<JourneyGuidanceObservation> messages,
  ) =>
      analyzer.compare(
        childId: 'child-a',
        messages: messages,
        earlierStart: start,
        earlierEnd: middle,
        laterStart: middle,
        laterEnd: end,
      );

  test('compares distinct UTC days rather than message totals', () {
    final result = compare([
      message('a', start, 'direct_after_guidance'),
      message('b', start, 'direct_after_guidance'),
      message('c', middle, 'direct_unflagged'),
      message('d', middle, 'direct_unflagged'),
    ]);
    expect(result.earlier.activeDays, 1);
    expect(result.earlier.guidanceReportedDays, 1);
    expect(result.later.activeDays, 1);
    expect(result.later.provisionalDirectDays, 1);
  });

  test('a boundary observation belongs to the later window only', () {
    final result = compare([message('a', middle, 'direct_unflagged')]);
    expect(result.earlier.activeDays, 0);
    expect(result.later.activeDays, 1);
  });

  test('excludes messages outside windows and from another child', () {
    final result = compare([
      message('before', start.subtract(const Duration(days: 1)), 'direct_unflagged'),
      message('after', end, 'direct_unflagged'),
      message('other', middle, 'direct_unflagged', child: 'child-b'),
    ]);
    expect(result.earlier.activeDays, 0);
    expect(result.later.activeDays, 0);
  });

  test('unknown routes remain unverified in their own period', () {
    final result = compare([message('unknown', middle, 'claimed_independent')]);
    expect(result.later.unverifiedDays, 1);
    expect(result.later.provisionalDirectDays, 0);
  });

  test('rejects overlapping, reversed and empty windows', () {
    expect(
      () => analyzer.compare(
        childId: 'child-a',
        messages: const [],
        earlierStart: start,
        earlierEnd: middle.add(const Duration(days: 1)),
        laterStart: middle,
        laterEnd: end,
      ),
      throwsArgumentError,
    );
    expect(
      () => analyzer.compare(
        childId: 'child-a',
        messages: const [],
        earlierStart: start,
        earlierEnd: start,
        laterStart: middle,
        laterEnd: end,
      ),
      throwsArgumentError,
    );
  });
}
