/// Identifies the source and scope of existing Journey context records.
///
/// These are client-writable observations, not independently verified evidence
/// of a child's skill, independence, or graduation readiness.
enum JourneyContextSource { childSignal, sharedFriendshipMoment }

enum JourneyContextKind {
  rewriteReported,
  timedPauseElapsed,
  recoveryReported,
  firstSharedRepairMoment,
  sharedFriendshipRecovering,
}

class JourneyContextObservation {
  const JourneyContextObservation({
    required this.documentId,
    required this.source,
    required this.kind,
  });

  final String documentId;
  final JourneyContextSource source;
  final JourneyContextKind kind;

  bool get isSharedFriendshipContext =>
      source == JourneyContextSource.sharedFriendshipMoment;

  bool get verifiesIndependentBehaviour => false;
  bool get provesIndividualGrowth => false;
  bool get supportsGraduationDecision => false;
}

/// Classifies only known, content-free metadata and preserves provenance.
///
/// The caller supplies the parent/child or friendship path identifier. These
/// methods do not access Firestore and cannot authenticate their inputs.
class JourneyContextEvidenceAdapter {
  const JourneyContextEvidenceAdapter();

  JourneyContextObservation? childSignal({
    required String childId,
    required String pathChildId,
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    if (childId.isEmpty ||
        pathChildId != childId ||
        documentId.trim().isEmpty) {
      return null;
    }

    final context = data['context'];
    final type = data['type'];
    final kind = switch ((context, type)) {
      ('rewrite_used', 'safetyCoach') => JourneyContextKind.rewriteReported,
      ('pause_respected', 'pauseRespected') =>
        JourneyContextKind.timedPauseElapsed,
      ('conversation_recovered', 'conversationRecovered') =>
        JourneyContextKind.recoveryReported,
      _ => null,
    };
    if (kind == null) return null;

    return JourneyContextObservation(
      documentId: documentId,
      source: JourneyContextSource.childSignal,
      kind: kind,
    );
  }

  /// Read from the friendship_moments collection only; the mirrored
  /// conversation meaningful_moments document must not be counted again.
  ///
  /// Friendship moments describe shared relationship state, never a single
  /// child's proven repair action. Their stored metadata is client-writable.
  JourneyContextObservation? friendshipMoment({
    required String friendshipId,
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    if (friendshipId.isEmpty ||
        documentId.trim().isEmpty ||
        data['friendshipId'] != friendshipId ||
        data['type'] != documentId) {
      return null;
    }

    final kind = switch (documentId) {
      'first_repair_moment' => JourneyContextKind.firstSharedRepairMoment,
      'recovering_friendship' => JourneyContextKind.sharedFriendshipRecovering,
      _ => null,
    };
    if (kind == null) return null;

    return JourneyContextObservation(
      documentId: documentId,
      source: JourneyContextSource.sharedFriendshipMoment,
      kind: kind,
    );
  }
}
