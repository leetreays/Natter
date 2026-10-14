import 'journey_activity_evidence.dart';

/// Interprets existing message metadata for Journey.
/// No Firestore access, message text, writes or growth awards.
enum JourneySendRoute {
  directUnflagged,
  directAfterGuidance,
  protectedDelivery,
  unverified,
}

class JourneyMessageAdapter {
  const JourneyMessageAdapter();

  JourneySendRoute routeOf(Map<String, dynamic> data) {
    if (data['isFlagged'] == true) {
      return JourneySendRoute.protectedDelivery;
    }

    switch (data['journeySendRoute']) {
      case 'direct_unflagged':
        return JourneySendRoute.directUnflagged;
      case 'direct_after_guidance':
        return JourneySendRoute.directAfterGuidance;
      case 'protected_delivery':
        return JourneySendRoute.protectedDelivery;
      default:
        return JourneySendRoute.unverified;
    }
  }

  /// Returns null for messages not authored by this child.
  /// Missing identity is never treated as a match.
  JourneyActivityRecord? activityFor({
    required String messageId,
    required String childId,
    required Map<String, dynamic> data,
  }) {
    if (childId.isEmpty || data['senderUid'] != childId) {
      return null;
    }

    final route = routeOf(data);
    final timestamp = data['createdAtMs'];
    final occurredAt = timestamp is num && timestamp > 0
        ? DateTime.fromMillisecondsSinceEpoch(timestamp.toInt(), isUtc: true)
        : null;

    return JourneyActivityRecord(
      id: messageId,
      occurredAt: occurredAt,
      isFlagged: route == JourneySendRoute.protectedDelivery,
      // A direct send is provisional evidence only.
      // The current metadata does not verify independence.
      independenceVerified: false,
    );
  }
}
