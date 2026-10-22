import 'journey_message_adapter.dart';

/// Read-only, client-reported communication observations grouped by UTC day.
///
/// This is descriptive metadata, not a score, a readiness judgement, or
/// authoritative evidence of independence. No message content is inspected.
class JourneyGuidanceObservationSummary {
  const JourneyGuidanceObservationSummary({
    required this.activeDays,
    required this.provisionalDirectDays,
    required this.guidanceReportedDays,
    required this.protectedDeliveryDays,
    required this.unverifiedDays,
  });

  final int activeDays;
  final int provisionalDirectDays;
  final int guidanceReportedDays;
  final int protectedDeliveryDays;
  final int unverifiedDays;
}

class JourneyGuidanceObservation {
  const JourneyGuidanceObservation(this.id, this.data);

  final String id;
  final Map<String, dynamic> data;
}

class JourneyGuidanceObservationAnalyzer {
  const JourneyGuidanceObservationAnalyzer();

  JourneyGuidanceObservationSummary analyze(
    String childId,
    Iterable<JourneyGuidanceObservation> messages,
  ) {
    final seenIds = <String>{};
    final active = <String>{};
    final direct = <String>{};
    final guided = <String>{};
    final protected = <String>{};
    final unknown = <String>{};
    const adapter = JourneyMessageAdapter();

    for (final message in messages) {
      if (message.id.isEmpty || !seenIds.add(message.id)) continue;
      final data = message.data;
      if (childId.isEmpty || data['senderUid'] != childId) continue;

      final timestamp = data['createdAtMs'];
      if (timestamp is! num || !timestamp.isFinite || timestamp <= 0) {
        continue;
      }
      final date = DateTime.fromMillisecondsSinceEpoch(
        timestamp.toInt(),
        isUtc: true,
      );
      final day =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      active.add(day);
      switch (adapter.routeOf(data)) {
        case JourneySendRoute.directUnflagged:
          direct.add(day);
        case JourneySendRoute.directAfterGuidance:
          guided.add(day);
        case JourneySendRoute.protectedDelivery:
          guided.add(day);
          protected.add(day);
        case JourneySendRoute.unverified:
          unknown.add(day);
      }
    }

    return JourneyGuidanceObservationSummary(
      activeDays: active.length,
      provisionalDirectDays: direct.length,
      guidanceReportedDays: guided.length,
      protectedDeliveryDays: protected.length,
      unverifiedDays: unknown.length,
    );
  }
}
