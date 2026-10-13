/// Read-only evidence analysis for the child Journey.
///
/// This module does not access Firestore, write data, or award stages.
/// Callers supply records from an existing signal snapshot.
enum JourneyEvidenceKind {
  kindRewrite,
  calmPause,
  friendshipRecovery,
  quietHoursAttempt,
}

class JourneyEvidenceRecord {
  const JourneyEvidenceRecord({
    required this.id,
    required this.type,
    required this.context,
    required this.occurredAt,
  });

  final String id;
  final String type;
  final String context;
  final DateTime? occurredAt;
}

class JourneyEvidenceSummary {
  const JourneyEvidenceSummary({
    required this.distinctDays,
    required this.daysByKind,
    required this.recordsWithoutDates,
    required this.duplicateIds,
  });

  /// All distinct UTC calendar days with recognised evidence.
  final int distinctDays;

  /// Each evidence kind contributes at most once per UTC day.
  final Map<JourneyEvidenceKind, int> daysByKind;

  /// Recognised records excluded because their date is unavailable.
  final int recordsWithoutDates;

  /// Duplicate record IDs ignored during analysis.
  final int duplicateIds;

  int daysFor(JourneyEvidenceKind kind) => daysByKind[kind] ?? 0;

  int get kindsObserved => daysByKind.values.where((days) => days > 0).length;
}

class JourneyEvidenceAnalyzer {
  const JourneyEvidenceAnalyzer();

  JourneyEvidenceKind? _kindFor(JourneyEvidenceRecord record) {
    switch (record.context) {
      case 'rewrite_used':
        return JourneyEvidenceKind.kindRewrite;
      case 'pause_respected':
        return JourneyEvidenceKind.calmPause;
      case 'conversation_recovered':
        return JourneyEvidenceKind.friendshipRecovery;
    }

    if (record.type == 'quietHours') {
      return JourneyEvidenceKind.quietHoursAttempt;
    }

    return null;
  }

  JourneyEvidenceSummary analyze(Iterable<JourneyEvidenceRecord> records) {
    final seenIds = <String>{};
    final allDays = <String>{};
    final daysByKind = <JourneyEvidenceKind, Set<String>>{};
    var missingDates = 0;
    var duplicateIds = 0;

    for (final record in records) {
      if (!seenIds.add(record.id)) {
        duplicateIds++;
        continue;
      }

      final kind = _kindFor(record);
      if (kind == null) continue;

      final occurredAt = record.occurredAt;
      if (occurredAt == null) {
        missingDates++;
        continue;
      }

      final utc = occurredAt.toUtc();
      final day =
          '${utc.year.toString().padLeft(4, '0')}-'
          '${utc.month.toString().padLeft(2, '0')}-'
          '${utc.day.toString().padLeft(2, '0')}';

      allDays.add(day);
      daysByKind.putIfAbsent(kind, () => <String>{}).add(day);
    }

    return JourneyEvidenceSummary(
      distinctDays: allDays.length,
      daysByKind: {
        for (final kind in JourneyEvidenceKind.values)
          kind: daysByKind[kind]?.length ?? 0,
      },
      recordsWithoutDates: missingDates,
      duplicateIds: duplicateIds,
    );
  }
}
