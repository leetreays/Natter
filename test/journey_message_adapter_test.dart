import 'package:flutter_test/flutter_test.dart';
import 'package:natter/journey/journey_activity_evidence.dart';
import 'package:natter/journey/journey_message_adapter.dart';

void main() {
  const adapter = JourneyMessageAdapter();
  const analyzer = JourneyActivityAnalyzer();

  final time = DateTime.utc(2026, 10, 14).millisecondsSinceEpoch;

  Map<String, dynamic> message(
    String route, {
    String sender = 'child-a',
    bool flagged = false,
  }) {
    return {
      'senderUid': sender,
      'createdAtMs': time,
      'journeySendRoute': route,
      'isFlagged': flagged,
    };
  }

  test('direct unflagged remains provisional', () {
    final data = message('direct_unflagged');

    expect(adapter.routeOf(data), JourneySendRoute.directUnflagged);

    final record = adapter.activityFor(
      messageId: 'one',
      childId: 'child-a',
      data: data,
    )!;

    expect(record.status, JourneyActivityStatus.unverified);
    expect(analyzer.analyze([record]).verifiedIndependentDays, 0);
  });

  test('guidance-assisted send is not independent', () {
    final record = adapter.activityFor(
      messageId: 'two',
      childId: 'child-a',
      data: message('direct_after_guidance'),
    )!;

    expect(record.status, JourneyActivityStatus.unverified);
  });

  test('protected delivery remains flagged', () {
    final record = adapter.activityFor(
      messageId: 'three',
      childId: 'child-a',
      data: message('protected_delivery'),
    )!;

    expect(record.status, JourneyActivityStatus.flagged);
  });

  test('flagged metadata overrides a direct route', () {
    final data = message('direct_unflagged', flagged: true);

    expect(adapter.routeOf(data), JourneySendRoute.protectedDelivery);
  });

  test('historical messages remain unverified', () {
    final data = message('unknown')..remove('journeySendRoute');

    expect(adapter.routeOf(data), JourneySendRoute.unverified);
  });

  test('another child messages are excluded', () {
    final record = adapter.activityFor(
      messageId: 'four',
      childId: 'child-a',
      data: message('direct_unflagged', sender: 'child-b'),
    );

    expect(record, isNull);
  });

  test('missing sender identity is excluded', () {
    final data = message('direct_unflagged')..remove('senderUid');

    expect(
      adapter.activityFor(messageId: 'five', childId: 'child-a', data: data),
      isNull,
    );
  });

  test('missing timestamp cannot count as an active day', () {
    final data = message('direct_unflagged')..remove('createdAtMs');

    final record = adapter.activityFor(
      messageId: 'six',
      childId: 'child-a',
      data: data,
    )!;

    expect(analyzer.analyze([record]).activeDays, 0);
  });

  test('multiple messages on one day count as one day', () {
    final records = [
      adapter.activityFor(
        messageId: 'seven',
        childId: 'child-a',
        data: message('direct_unflagged'),
      )!,
      adapter.activityFor(
        messageId: 'eight',
        childId: 'child-a',
        data: message('direct_after_guidance'),
      )!,
    ];

    final summary = analyzer.analyze(records);

    expect(summary.activeDays, 1);
    expect(summary.verifiedIndependentDays, 0);
  });
}
