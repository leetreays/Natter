import 'package:flutter_test/flutter_test.dart';
import 'package:natter/journey/journey_evidence.dart';

void main() {
  const analyzer = JourneyEvidenceAnalyzer();

  JourneyEvidenceRecord record(
    String id,
    String context,
    String date, {
    String type = 'guidance',
  }) {
    return JourneyEvidenceRecord(
      id: id,
      type: type,
      context: context,
      occurredAt: DateTime.parse(date),
    );
  }

  test('repeated rewrites on one day count once', () {
    final result = analyzer.analyze([
      record('a', 'rewrite_used', '2026-10-01T09:00:00Z'),
      record('b', 'rewrite_used', '2026-10-01T10:00:00Z'),
      record('c', 'rewrite_used', '2026-10-01T11:00:00Z'),
    ]);

    expect(result.distinctDays, 1);
    expect(result.daysFor(JourneyEvidenceKind.kindRewrite), 1);
    expect(result.kindsObserved, 1);
  });

  test('different kinds and different days are recognised', () {
    final result = analyzer.analyze([
      record('a', 'rewrite_used', '2026-10-01T09:00:00Z'),
      record('b', 'pause_respected', '2026-10-01T10:00:00Z'),
      record('c', 'conversation_recovered', '2026-10-02T10:00:00Z'),
    ]);

    expect(result.distinctDays, 2);
    expect(result.kindsObserved, 3);
    expect(result.daysFor(JourneyEvidenceKind.calmPause), 1);
    expect(result.daysFor(JourneyEvidenceKind.friendshipRecovery), 1);
  });

  test('duplicate document IDs cannot count twice', () {
    final entry = record('same', 'rewrite_used', '2026-10-01T09:00:00Z');
    final result = analyzer.analyze([entry, entry]);

    expect(result.duplicateIds, 1);
    expect(result.daysFor(JourneyEvidenceKind.kindRewrite), 1);
  });

  test('missing timestamps are excluded, not guessed', () {
    final result = analyzer.analyze([
      const JourneyEvidenceRecord(
        id: 'missing',
        type: 'guidance',
        context: 'rewrite_used',
        occurredAt: null,
      ),
    ]);

    expect(result.distinctDays, 0);
    expect(result.recordsWithoutDates, 1);
  });

  test('quiet hours attempts are distinguished from achievements', () {
    final result = analyzer.analyze([
      record(
        'quiet',
        'message_attempt',
        '2026-10-01T20:00:00Z',
        type: 'quietHours',
      ),
    ]);

    expect(result.daysFor(JourneyEvidenceKind.quietHoursAttempt), 1);
    expect(result.daysFor(JourneyEvidenceKind.kindRewrite), 0);
  });

  test('unrecognised signals do not contribute', () {
    final result = analyzer.analyze([
      record('a', 'message_blocked', '2026-10-01T09:00:00Z'),
    ]);

    expect(result.distinctDays, 0);
    expect(result.kindsObserved, 0);
  });
}
