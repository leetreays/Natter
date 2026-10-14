import 'package:flutter_test/flutter_test.dart';
import 'package:natter/journey/journey_guidance_session.dart';

void main() {
  test('new session defaults to direct unflagged', () {
    final session = JourneyGuidanceSession();
    expect(session.guidanceSeen, isFalse);
    expect(session.routeForAttempt(protectedDelivery: false),
        'direct_unflagged');
  });

  test('coaching is retained for a subsequent direct attempt', () {
    final session = JourneyGuidanceSession()..recordGuidance();
    expect(session.routeForAttempt(protectedDelivery: false),
        'direct_after_guidance');
  });

  test('blocked attempt followed by rewrite stays guided', () {
    final session = JourneyGuidanceSession()..recordGuidance();
    expect(session.routeForAttempt(protectedDelivery: false),
        'direct_after_guidance');
  });

  test('protected delivery overrides any direct route', () {
    final session = JourneyGuidanceSession();
    expect(session.routeForAttempt(protectedDelivery: true),
        'protected_delivery');
    session.recordGuidance();
    expect(session.routeForAttempt(protectedDelivery: true),
        'protected_delivery');
  });

  test('failed delivery retains guidance for retry', () {
    final session = JourneyGuidanceSession()..recordGuidance();
    session.completeAttempt(delivered: false);
    expect(session.guidanceSeen, isTrue);
    expect(session.routeForAttempt(protectedDelivery: false),
        'direct_after_guidance');
  });

  test('successful delivery resets the session', () {
    final session = JourneyGuidanceSession()..recordGuidance();
    session.completeAttempt(delivered: true);
    expect(session.guidanceSeen, isFalse);
    expect(session.routeForAttempt(protectedDelivery: false),
        'direct_unflagged');
  });

  test('classification alone does not clear guidance', () {
    final session = JourneyGuidanceSession()..recordGuidance();
    session.routeForAttempt(protectedDelivery: false);
    session.routeForAttempt(protectedDelivery: true);
    expect(session.guidanceSeen, isTrue);
  });

  test('repeated guidance does not change classification', () {
    final session = JourneyGuidanceSession()
      ..recordGuidance()
      ..recordGuidance();
    expect(session.routeForAttempt(protectedDelivery: false),
        'direct_after_guidance');
  });
}
