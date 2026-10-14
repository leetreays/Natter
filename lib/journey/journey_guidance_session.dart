/// Tracks whether guidance was encountered during the current composition
/// session. This class performs no I/O and does not award Journey growth.
class JourneyGuidanceSession {
  bool _guidanceSeen = false;

  bool get guidanceSeen => _guidanceSeen;

  /// Call when a blocked, coached, or Protected Delivery assessment occurs.
  void recordGuidance() => _guidanceSeen = true;

  /// Classifies the attempted send without changing session state.
  /// A protected message is never considered independent.
  String routeForAttempt({required bool protectedDelivery}) {
    if (protectedDelivery) return 'protected_delivery';
    return _guidanceSeen ? 'direct_after_guidance' : 'direct_unflagged';
  }

  /// A failed send retains the prior guidance history for retry.
  /// A successful send closes the composition session.
  void completeAttempt({required bool delivered}) {
    if (delivered) _guidanceSeen = false;
  }
}
