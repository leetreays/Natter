/// Read-only analysis of message activity for Journey.
///
/// An unflagged message is not automatically proof that no
/// coaching or intervention was needed before sending it.
///
/// This model deliberately does not read Firestore, award
/// growth stages, or perform any writes.
enum JourneyActivityStatus {
  flagged,
  unverified,
  verifiedIndependent,
}

class JourneyActivityRecord {
  const JourneyActivityRecord({
    required this.id,
    required this.occurredAt,
    required this.isFlagged,
    this.independenceVerified = false,
  });

  final String id;
  final DateTime? occurredAt;
  final bool isFlagged;

  /// Only true when an authoritative source explicitly verifies
  /// that the send required no intervention.
  ///
  /// Existing historical messages do not provide this guarantee.
  final bool independenceVerified;

  JourneyActivityStatus get status {
    if (isFlagged) return JourneyActivityStatus.flagged;
    if (independenceVerified) {
      return JourneyActivityStatus.verifiedIndependent;
    }
    return JourneyActivityStatus.unverified;
  }
}

class JourneyActivitySummary {
  const JourneyActivitySummary({
    required this.activeDays,
    required this.unverifiedDays,
    required this.verifiedIndependentDays,
    required this.flaggedDays,
    required this.missingTimestampRecords,
    required this.duplicateIds,
  });

  /// Distinct UTC calendar days, rather than message totals.
  final int activeDays;
  final int unverifiedDays;
  final int verifiedIndependentDays;
  final int flaggedDays;
  final int missingTimestampRecords;
  final int duplicateIds;
}

class JourneyActivityAnalyzer {
  const JourneyActivityAnalyzer();

  JourneyActivitySummary analyze(
    Iterable<JourneyActivityRecord> records,
  ) {
    final seenIds = <String>{};
    final active = <String>{};
    final unverified = <String>{};
    final verified = <String>{};
    final flagged = <String>{};

    var missingDates = 0;
    var duplicates = 0;

    for (final record in records) {
      if (!seenIds.add(record.id)) {
        duplicates++;
        continue;
      }

      final timestamp = record.occurredAt;
      if (timestamp == null) {
        missingDates++;
        continue;
      }

      final utc = timestamp.toUtc();
      final day =
          '${utc.year.toString().padLeft(4, '0')}-'
          '${utc.month.toString().padLeft(2, '0')}-'
          '${utc.day.toString().padLeft(2, '0')}';

      active.add(day);

      switch (record.status) {
        case JourneyActivityStatus.flagged:
          flagged.add(day);
        case JourneyActivityStatus.unverified:
          unverified.add(day);
        case JourneyActivityStatus.verifiedIndependent:
          verified.add(day);
      }
    }

    return JourneyActivitySummary(
      activeDays: active.length,
      unverifiedDays: unverified.length,
      verifiedIndependentDays: verified.length,
      flaggedDays: flagged.length,
      missingTimestampRecords: missingDates,
      duplicateIds: duplicates,
    );
  }
}
