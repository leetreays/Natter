import 'journey_guidance_observation_summary.dart';

/// Two disjoint UTC windows of client-reported message observations.
///
/// These summaries describe the available evidence only. They do not establish
/// independent behaviour, improvement, readiness, or graduation eligibility.
class JourneyObservationPeriodComparison {
  const JourneyObservationPeriodComparison({
    required this.earlier,
    required this.later,
  });

  final JourneyGuidanceObservationSummary earlier;
  final JourneyGuidanceObservationSummary later;
}

class JourneyObservationPeriodAnalyzer {
  const JourneyObservationPeriodAnalyzer();

  /// Windows are half-open: [start, end). All boundaries use UTC.
  ///
  /// Rejects overlapping, reversed or empty windows so one observation cannot
  /// be used as evidence for both periods. Never reads message content.
  JourneyObservationPeriodComparison compare({
    required String childId,
    required Iterable<JourneyGuidanceObservation> messages,
    required DateTime earlierStart,
    required DateTime earlierEnd,
    required DateTime laterStart,
    required DateTime laterEnd,
  }) {
    final a = earlierStart.toUtc().millisecondsSinceEpoch;
    final b = earlierEnd.toUtc().millisecondsSinceEpoch;
    final c = laterStart.toUtc().millisecondsSinceEpoch;
    final d = laterEnd.toUtc().millisecondsSinceEpoch;
    if (a >= b || b > c || c >= d) {
      throw ArgumentError('Periods must be nonempty, ordered and disjoint.');
    }

    final earlier = <JourneyGuidanceObservation>[];
    final later = <JourneyGuidanceObservation>[];
    for (final message in messages) {
      final value = message.data['createdAtMs'];
      if (value is! num || !value.isFinite || value <= 0) continue;
      final millis = value.toInt();
      if (millis >= a && millis < b) {
        earlier.add(message);
      } else if (millis >= c && millis < d) {
        later.add(message);
      }
    }

    const analyzer = JourneyGuidanceObservationAnalyzer();
    return JourneyObservationPeriodComparison(
      earlier: analyzer.analyze(childId, earlier),
      later: analyzer.analyze(childId, later),
    );
  }
}
