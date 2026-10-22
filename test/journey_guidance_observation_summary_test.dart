import 'package:flutter_test/flutter_test.dart';
import 'package:natter/journey/journey_guidance_observation_summary.dart';

void main() {
  const analyzer = JourneyGuidanceObservationAnalyzer();
  final day = DateTime.utc(2026, 10, 20).millisecondsSinceEpoch;

  JourneyGuidanceObservation message(
    String id,
    String route, {
    String sender = 'child-a',
    bool flagged = false,
    int? timestamp,
  }) {
    return JourneyGuidanceObservation(id, {
      'senderUid': sender,
      'createdAtMs': timestamp ?? day,
      'journeySendRoute': route,
      'isFlagged': flagged,
      'text': 'Not read by the analyzer',
    });
  }

  test('groups routes by day without rewarding message volume', () {
    final summary = analyzer.analyze('child-a', [
      message('a', 'direct_unflagged'),
      message('b', 'direct_unflagged'),
      message('c', 'direct_after_guidance'),
      message('d', 'protected_delivery', flagged: true),
      message('e', 'unverified'),
    ]);
    expect(summary.activeDays, 1);
    expect(summary.provisionalDirectDays, 1);
    expect(summary.guidanceReportedDays, 1);
    expect(summary.protectedDeliveryDays, 1);
    expect(summary.unverifiedDays, 1);
  });

  test('rejects other child activity and duplicate identities', () {
    final summary = analyzer.analyze('child-a', [
      message('same', 'direct_unflagged', sender: 'child-b'),
      message('same', 'direct_unflagged'),
      message('own', 'direct_unflagged'),
      message('other', 'direct_unflagged', sender: 'child-b'),
    ]);
    expect(summary.activeDays, 1);
    expect(summary.provisionalDirectDays, 1);
  });

  test('flagged status overrides a reported direct route', () {
    final summary = analyzer.analyze('child-a', [
      message('a', 'direct_unflagged', flagged: true),
    ]);
    expect(summary.provisionalDirectDays, 0);
    expect(summary.guidanceReportedDays, 1);
    expect(summary.protectedDeliveryDays, 1);
  });

  test('historical and unknown routes remain unverified', () {
    final summary = analyzer.analyze('child-a', [
      JourneyGuidanceObservation('old', {
        'senderUid': 'child-a',
        'createdAtMs': day,
      }),
      message('unknown', 'independent'),
    ]);
    expect(summary.unverifiedDays, 1);
    expect(summary.provisionalDirectDays, 0);
  });

  test('missing timestamps and sender identity do not count', () {
    final summary = analyzer.analyze('child-a', [
      JourneyGuidanceObservation('missing-date', {'senderUid': 'child-a'}),
      JourneyGuidanceObservation('missing-sender', {'createdAtMs': day}),
      message('zero', 'direct_unflagged', timestamp: 0),
    ]);
    expect(summary.activeDays, 0);
  });

  test('counts different UTC days, not individual sends', () {
    final summary = analyzer.analyze('child-a', [
      message('first', 'direct_unflagged'),
      message('second', 'direct_unflagged', timestamp: day + 86400000),
    ]);
    expect(summary.activeDays, 2);
    expect(summary.provisionalDirectDays, 2);
  });
}
