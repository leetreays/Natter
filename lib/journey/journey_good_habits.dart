import 'journey_activity_evidence.dart';

enum JourneyDayEvidence { independentActivity, mixed, unverified, flaggedOnly }

class JourneyGoodHabitsSummary {
  const JourneyGoodHabitsSummary({
    required this.activeDays,
    required this.independentActivityDays,
    required this.mixedDays,
    required this.unverifiedDays,
    required this.flaggedOnlyDays,
  });

  final int activeDays;
  final int independentActivityDays;
  final int mixedDays;
  final int unverifiedDays;
  final int flaggedOnlyDays;
}

class JourneyGoodHabitsAnalyzer {
  const JourneyGoodHabitsAnalyzer();

  JourneyGoodHabitsSummary analyze(Iterable<JourneyActivityRecord> records) {
    final days = <String, Set<JourneyActivityStatus>>{};
    final seenIds = <String>{};

    for (final record in records) {
      if (!seenIds.add(record.id)) continue;

      final timestamp = record.occurredAt;
      if (timestamp == null) continue;

      final utc = timestamp.toUtc();
      final day =
          '${utc.year.toString().padLeft(4, '0')}-'
          '${utc.month.toString().padLeft(2, '0')}-'
          '${utc.day.toString().padLeft(2, '0')}';

      days.putIfAbsent(day, () => <JourneyActivityStatus>{}).add(record.status);
    }

    var independent = 0;
    var mixed = 0;
    var unverified = 0;
    var flaggedOnly = 0;

    for (final statuses in days.values) {
      final hasIndependent = statuses.contains(
        JourneyActivityStatus.verifiedIndependent,
      );
      final hasFlagged = statuses.contains(JourneyActivityStatus.flagged);
      final hasUnverified = statuses.contains(JourneyActivityStatus.unverified);

      if (hasIndependent && !hasFlagged && !hasUnverified) {
        independent++;
      } else if (hasIndependent && (hasFlagged || hasUnverified)) {
        mixed++;
      } else if (hasUnverified) {
        unverified++;
      } else {
        flaggedOnly++;
      }
    }

    return JourneyGoodHabitsSummary(
      activeDays: days.length,
      independentActivityDays: independent,
      mixedDays: mixed,
      unverifiedDays: unverified,
      flaggedOnlyDays: flaggedOnly,
    );
  }
}
