/// A durable, child-controlled invitation; never a visible friendship score.
const friendshipStageOrder = <String>[
  'seedling',
  'growing',
  'strong',
  'trusted',
  'flourishing',
];

bool isUpwardFriendshipStageChange(String previousStage, String newStage) {
  final before = friendshipStageOrder.indexOf(previousStage);
  final after = friendshipStageOrder.indexOf(newStage);
  return before >= 0 && after > before;
}

int nextFriendshipMomentVersion(Map<String, dynamic> conversationData) {
  final previous = conversationData['friendshipMoment'];
  if (previous is Map && previous['version'] is int) {
    final version = previous['version'] as int;
    if (version > 0) return version + 1;
  }
  return 1;
}

class FriendshipMomentNotice {
  const FriendshipMomentNotice({
    required this.version,
    required this.previousStage,
    required this.stage,
    required this.acknowledgedByChildIds,
  });

  final int version;
  final String previousStage;
  final String stage;
  final List<String> acknowledgedByChildIds;

  bool isPendingFor(String? childId) =>
      childId != null &&
      childId.isNotEmpty &&
      !acknowledgedByChildIds.contains(childId);

  static FriendshipMomentNotice? fromConversationData(
    Map<String, dynamic>? conversationData,
  ) {
    final raw = conversationData?['friendshipMoment'];
    if (raw is! Map) return null;

    final version = raw['version'];
    final previousStage = raw['previousStage'];
    final stage = raw['stage'];
    final seen = raw['acknowledgedByChildIds'];

    if (version is! int ||
        version < 1 ||
        previousStage is! String ||
        stage is! String ||
        !isUpwardFriendshipStageChange(previousStage, stage) ||
        seen is! List ||
        !seen.every((value) => value is String)) {
      return null;
    }

    return FriendshipMomentNotice(
      version: version,
      previousStage: previousStage,
      stage: stage,
      acknowledgedByChildIds: List<String>.from(seen),
    );
  }
}
