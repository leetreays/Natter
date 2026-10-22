import 'package:flutter_test/flutter_test.dart';
import 'package:natter/journey/journey_growth_interpretation.dart';
import 'package:natter/journey/journey_guidance_observation_summary.dart';
import 'package:natter/journey/journey_observation_period_comparison.dart';

void main() {
  const interpreter = JourneyGrowthInterpreter();

  JourneyGuidanceObservationSummary summary({
    required int active,
    int direct = 0,
    int guided = 0,
    int protected = 0,
    int unknown = 0,
  }) => JourneyGuidanceObservationSummary(
    activeDays: active,
    provisionalDirectDays: direct,
    guidanceReportedDays: guided,
    protectedDeliveryDays: protected,
    unverifiedDays: unknown,
  );

  test('reports descriptive changes without asserting growth', () {
    final result = interpreter.interpret(
      JourneyObservationPeriodComparison(
        earlier: summary(active: 3, direct: 1, guided: 2, protected: 1),
        later: summary(active: 4, direct: 3, guided: 1, protected: 1),
      ),
    );
    expect(result.hasComparableActivity, isTrue);
    expect(result.directDays, JourneyObservedChange.increased);
    expect(result.guidanceDays, JourneyObservedChange.decreased);
    expect(result.protectedDays, JourneyObservedChange.unchanged);
    expect(result.unverifiedDays, JourneyObservedChange.unchanged);
    expect(result.supportsGrowthConclusion, isFalse);
    expect(result.verifiesIndependence, isFalse);
    expect(result.supportsGraduationDecision, isFalse);
  });

  test('missing activity in either window is insufficient evidence', () {
    for (final comparison in [
      JourneyObservationPeriodComparison(
        earlier: summary(active: 0),
        later: summary(active: 2, direct: 2),
      ),
      JourneyObservationPeriodComparison(
        earlier: summary(active: 2, direct: 2),
        later: summary(active: 0),
      ),
    ]) {
      final result = interpreter.interpret(comparison);
      expect(result.hasComparableActivity, isFalse);
      expect(result.directDays, JourneyObservedChange.insufficientEvidence);
      expect(result.guidanceDays, JourneyObservedChange.insufficientEvidence);
      expect(result.protectedDays, JourneyObservedChange.insufficientEvidence);
      expect(result.unverifiedDays, JourneyObservedChange.insufficientEvidence);
    }
  });

  test('increased unverified days remain observations, not proof', () {
    final result = interpreter.interpret(
      JourneyObservationPeriodComparison(
        earlier: summary(active: 1, unknown: 1),
        later: summary(active: 2, unknown: 2),
      ),
    );
    expect(result.unverifiedDays, JourneyObservedChange.increased);
    expect(result.verifiesIndependence, isFalse);
  });
}
