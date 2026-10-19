/// Privacy-preserving, provisional observations about a message send.
///
/// These values describe what the client reported. They are not proof of
/// independence and must never be used alone to award Journey readiness.
enum JourneyObservedSendRoute {
  directUnflagged,
  directAfterGuidance,
  protectedDelivery,
  unverified,
}

class JourneyProvisionalSendEvidence {
  const JourneyProvisionalSendEvidence({
    required this.route,
    required this.hasMessageIdentity,
  });

  final JourneyObservedSendRoute route;
  final bool hasMessageIdentity;

  /// Client-side observations cannot authoritatively verify independence.
  bool get independenceVerified => false;

  /// Whether the reported route says that Natter guidance was encountered.
  /// Unknown and historical routes must not be interpreted as guidance-free.
  bool get guidanceReported =>
      route == JourneyObservedSendRoute.directAfterGuidance ||
      route == JourneyObservedSendRoute.protectedDelivery;

  /// An unflagged direct send is only a *candidate* for future verification.
  bool get isProvisionalDirectCandidate =>
      hasMessageIdentity && route == JourneyObservedSendRoute.directUnflagged;

  static JourneyProvisionalSendEvidence fromMessage({
    required String childId,
    required Map<String, dynamic> data,
  }) {
    final ownsMessage = childId.isNotEmpty && data['senderUid'] == childId;
    if (!ownsMessage) {
      return const JourneyProvisionalSendEvidence(
        route: JourneyObservedSendRoute.unverified,
        hasMessageIdentity: false,
      );
    }

    // Flagging takes precedence over any self-reported direct-send route.
    if (data['isFlagged'] == true) {
      return const JourneyProvisionalSendEvidence(
        route: JourneyObservedSendRoute.protectedDelivery,
        hasMessageIdentity: true,
      );
    }

    final route = switch (data['journeySendRoute']) {
      'direct_unflagged' => JourneyObservedSendRoute.directUnflagged,
      'direct_after_guidance' => JourneyObservedSendRoute.directAfterGuidance,
      'protected_delivery' => JourneyObservedSendRoute.protectedDelivery,
      _ => JourneyObservedSendRoute.unverified,
    };

    return JourneyProvisionalSendEvidence(
      route: route,
      hasMessageIdentity: true,
    );
  }
}
