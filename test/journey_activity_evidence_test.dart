import 'package:flutter_test/flutter_test.dart';
import 'package:natter/journey/journey_activity_evidence.dart';

void main() {
  const analyzer = JourneyActivityAnalyzer();

  JourneyActivityRecord message(
    String id,
    String date, {
    bool flagged = false,
    bool verified = false,
  }) {
    return JourneyActivityRecord(
      id: id,
      occurredAt: DateTime.parse(date),
      isFlagged: flagged,
      independenceVerified: verified,
    );
  }

  test('ordinary messages are unverified by default', () {
    final result = analyzer.analyze([
      message('a', '2026-10-01T10:00:00Z'),
    ]);

    expect(result.activeDays, 1);
    expect(result.unverifiedDays, 1);
    expect(result.verifiedIndependentDays, 0);
  });

  test('high message volume does not multiply days', () {
    final messages = List.generate(
      100,
      (index) => message(
        '$index',
        '2026-10-01T10:00:00Z',
      ),
    );

    final result = analyzer.analyze(messages);

    expect(result.activeDays, 1);
    expect(result.unverifiedDays, 1);
  });

  test('activity across days is recognised', () {
    final result = analyzer.analyze([
      message('a', '2026-10-01T10:00:00Z'),
      message('b', '2026-10-02T10:00:00Z'),
      message('c', '2026-10-03T10:00:00Z'),
    ]);

    expect(result.activeDays, 3);
    expect(result.unverifiedDays, 3);
  });

  test('flagged messages never count as independent', () {
    final result = analyzer.analyze([
      message(
        'a',
        '2026-10-01T10:00:00Z',
        flagged: true,
        verified: true,
      ),
    ]);

    expect(result.flaggedDays, 1);
    expect(result.verifiedIndependentDays, 0);
  });

  test('verified independence requires explicit evidence', () {
    final result = analyzer.analyze([
      message(
        'a',
        '2026-10-01T10:00:00Z',
        verified: true,
      ),
      message('b', '2026-10-02T10:00:00Z'),
    ]);

    expect(result.verifiedIndependentDays, 1);
    expect(result.unverifiedDays, 1);
  });

  test('duplicate IDs do not count twice', () {
    final entry = message('same', '2026-10-01T10:00:00Z');
    final result = analyzer.analyze([entry, entry]);

    expect(result.duplicateIds, 1);
    expect(result.activeDays, 1);
  });

  test('missing timestamps are excluded', () {
    final result = analyzer.analyze([
      const JourneyActivityRecord(
        id: 'missing',
        occurredAt: null,
        isFlagged: false,
      ),
    ]);

    expect(result.activeDays, 0);
    expect(result.missingTimestampRecords, 1);
  });

  test('inactive days do not erase earlier evidence', () {
    final result = analyzer.analyze([
      message('a', '2026-09-01T10:00:00Z'),
      message('b', '2026-10-01T10:00:00Z'),
    ]);

    expect(result.activeDays, 2);
  });

  test('UTC calendar boundaries are deterministic', () {
    final result = analyzer.analyze([
      message('a', '2026-10-01T23:30:00Z'),
      message('b', '2026-10-02T00:30:00+01:00'),
    ]);

    expect(result.activeDays, 1);
  });
}
