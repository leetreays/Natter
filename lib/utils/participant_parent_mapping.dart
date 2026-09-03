String? participantParentIdForChild({
  required Object? participantChildIds,
  required Object? participantParentIds,
  required String senderChildId,
}) {
  if (senderChildId.trim().isEmpty) {
    return null;
  }

  if (participantChildIds is! List || participantParentIds is! List) {
    return null;
  }

  final senderIndex = participantChildIds.indexWhere(
    (childId) => childId is String && childId == senderChildId,
  );

  if (senderIndex < 0 || senderIndex >= participantParentIds.length) {
    return null;
  }

  final parentId = participantParentIds[senderIndex];
  if (parentId is! String || parentId.trim().isEmpty) {
    return null;
  }

  return parentId;
}
