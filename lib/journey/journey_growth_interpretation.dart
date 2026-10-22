import 'journey_observation_period_comparison.dart';

/// A descriptive change between two windows, never an independence judgement.
enum JourneyObservedChange { increased, decreased, unchanged, insufficientEvidence }

/// Read-only interpretation of client-reported Journey observations.
///
/// These labels are not scores, evidence of improved behaviour, or readiness
/// decisions. In particular, a rise in direct days is not verified independence.
class JourneyGrowthInterpretation {
  const JourneyGrowthInterpretation({
    required this.directDays,
    required this.guidanceDays,
    required this.protectedDays,
    required this.unverifiedDays,
    required this.hasComparableActivity,
  });

  final JourneyObservedChange directDays;
  final JourneyObservedChange guidanceDays;
  final JourneyObservedChange protectedDays;
  final JourneyObservedChange unverifiedDays;

  /// Both periods contain observed activity; this does not establish that
  /// observation coverage, opportunity or message volume is comparable.
  final bool hasComparableActivity;

  bool get supportsGrowthConclusion => false;
  bool get verifiesIndependence => false;
  bool get supportsGraduationDecision => false;
}

class JourneyGrowthInterpreter {
  const JourneyGrowthInterpreter();

  JourneyGrowthInterpretation interpret(
    JourneyObservationPeriodComparison comparison,
  ) {
    final earlier = comparison.earlier;
    final later = comparison.later;
    final hasActivity = earlier.activeDays > 0 && later.activeDays > 0;

    JourneyObservedChange change(int before, int after) {
      if (!hasActivity) return JourneyObservedChange.insufficientEvidence;
      if (after > before) return JourneyObservedChange.increased;
      if (after < before) return JourneyObservedChange.decreased;
      return JourneyObservedChange.unchanged;
    }

    return JourneyGrowthInterpretation(
      directDays: change(
        earlier.provisionalDirectDays,
        later.provisionalDirectDays,
      ),
      guidanceDays: change(
        earlier.guidanceReportedDays,
        later.guidanceReportedDays,
      ),
      protectedDays: change(
        earlier.protectedDeliveryDays,
        later.protectedDeliveryDays,
      ),
      unverifiedDays: change(
        earlier.unverifiedDays,
        later.unverifiedDays,
      ),
      hasComparableActivity: hasActivity,
    );
  }
}
