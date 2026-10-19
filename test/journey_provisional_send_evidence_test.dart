import 'package:flutter_test/flutter_test.dart';
import 'package:natter/journey/journey_provisional_send_evidence.dart';
import 'package:natter/journey/journey_message_adapter.dart';

void main() {
  JourneyProvisionalSendEvidence assess(
    String? route, {
    String? sender = 'child-a',
    String childId = 'child-a',
    bool flagged = false,
  }) {
    return JourneyProvisionalSendEvidence.fromMessage(
      childId: childId,
      data: {
        if (sender != null) 'senderUid': sender,
        if (route != null) 'journeySendRoute': route,
        'isFlagged': flagged,
      },
    );
  }

  test('direct send is provisional, never verified independence', () {
    final evidence = assess('direct_unflagged');
    expect(evidence.route, JourneySendRoute.directUnflagged);
    expect(evidence.isProvisionalDirectCandidate, isTrue);
    expect(evidence.independenceVerified, isFalse);
    expect(evidence.guidanceReported, isFalse);
  });

  test('coached retry retains guidance classification', () {
    final evidence = assess('direct_after_guidance');
    expect(evidence.route, JourneySendRoute.directAfterGuidance);
    expect(evidence.guidanceReported, isTrue);
    expect(evidence.isProvisionalDirectCandidate, isFalse);
    expect(evidence.independenceVerified, isFalse);
  });

  test('protected delivery cannot be independent', () {
    final evidence = assess('protected_delivery');
    expect(evidence.route, JourneySendRoute.protectedDelivery);
    expect(evidence.guidanceReported, isTrue);
    expect(evidence.independenceVerified, isFalse);
  });

  test('flagged message overrides a claimed direct route', () {
    final evidence = assess('direct_unflagged', flagged: true);
    expect(evidence.route, JourneySendRoute.protectedDelivery);
    expect(evidence.isProvisionalDirectCandidate, isFalse);
  });

  test('historical messages without route remain unverified', () {
    final evidence = assess(null);
    expect(evidence.route, JourneySendRoute.unverified);
    expect(evidence.isProvisionalDirectCandidate, isFalse);
    expect(evidence.independenceVerified, isFalse);
  });

  test('unknown and malformed routes remain unverified', () {
    for (final route in ['independent', 'verified', '', 'other']) {
      final evidence = assess(route);
      expect(evidence.route, JourneySendRoute.unverified);
      expect(evidence.isProvisionalDirectCandidate, isFalse);
    }
  });

  test('different sender cannot contribute child evidence', () {
    final evidence = assess('direct_unflagged', sender: 'child-b');
    expect(evidence.hasMessageIdentity, isFalse);
    expect(evidence.isProvisionalDirectCandidate, isFalse);
  });

  test('missing sender cannot contribute child evidence', () {
    final evidence = assess('direct_unflagged', sender: null);
    expect(evidence.hasMessageIdentity, isFalse);
    expect(evidence.independenceVerified, isFalse);
  });

  test('empty child ID cannot contribute child evidence', () {
    final evidence = assess('direct_unflagged', childId: '');
    expect(evidence.hasMessageIdentity, isFalse);
    expect(evidence.isProvisionalDirectCandidate, isFalse);
  });
}
