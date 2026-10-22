import 'package:flutter_test/flutter_test.dart';
import 'package:natter/journey/journey_context_evidence.dart';

void main() {
  const adapter = JourneyContextEvidenceAdapter();

  test('a reported rewrite is supported context, not proven growth', () {
    final observation = adapter.childSignal(
      childId: 'child-a',
      pathChildId: 'child-a',
      documentId: 'signal-a',
      data: {'context': 'rewrite_used', 'type': 'safetyCoach'},
    )!;

    expect(observation.kind, JourneyContextKind.rewriteReported);
    expect(observation.source, JourneyContextSource.childSignal);
    expect(observation.isSharedFriendshipContext, isFalse);
    expect(observation.verifiesIndependentBehaviour, isFalse);
    expect(observation.provesIndividualGrowth, isFalse);
    expect(observation.supportsGraduationDecision, isFalse);
  });

  test('a timer-expired pause is not treated as a voluntary choice', () {
    final observation = adapter.childSignal(
      childId: 'child-a',
      pathChildId: 'child-a',
      documentId: 'pause-a',
      data: {'context': 'pause_respected', 'type': 'pauseRespected'},
    )!;

    expect(observation.kind, JourneyContextKind.timedPauseElapsed);
    expect(observation.provesIndividualGrowth, isFalse);
  });

  test('a reported conversation recovery is not verified independence', () {
    final observation = adapter.childSignal(
      childId: 'child-a',
      pathChildId: 'child-a',
      documentId: 'recovery-a',
      data: {
        'context': 'conversation_recovered',
        'type': 'conversationRecovered',
      },
    )!;

    expect(observation.kind, JourneyContextKind.recoveryReported);
    expect(observation.verifiesIndependentBehaviour, isFalse);
  });

  test('child signal must match the supplied child path', () {
    expect(
      adapter.childSignal(
        childId: 'child-a',
        pathChildId: 'child-b',
        documentId: 'signal-a',
        data: {'context': 'rewrite_used', 'type': 'safetyCoach'},
      ),
      isNull,
    );

    expect(
      adapter.childSignal(
        childId: 'child-a',
        pathChildId: 'child-a',
        documentId: '',
        data: {'context': 'rewrite_used', 'type': 'safetyCoach'},
      ),
      isNull,
    );
  });

  test('unknown and mismatched signals are ignored', () {
    for (final data in [
      {'context': 'rewrite_used', 'type': 'pauseRespected'},
      {'context': 'claimed_independent', 'type': 'safetyCoach'},
      <String, dynamic>{},
    ]) {
      expect(
        adapter.childSignal(
          childId: 'child-a',
          pathChildId: 'child-a',
          documentId: 'signal-a',
          data: data,
        ),
        isNull,
      );
    }
  });

  test('friendship repair moments remain shared relationship context', () {
    for (final type in ['first_repair_moment', 'recovering_friendship']) {
      final observation = adapter.friendshipMoment(
        friendshipId: 'child-a_child-b',
        documentId: type,
        data: {'friendshipId': 'child-a_child-b', 'type': type},
      )!;

      expect(observation.source, JourneyContextSource.sharedFriendshipMoment);
      expect(observation.isSharedFriendshipContext, isTrue);
      expect(observation.verifiesIndependentBehaviour, isFalse);
      expect(observation.provesIndividualGrowth, isFalse);
      expect(observation.supportsGraduationDecision, isFalse);
    }
  });

  test('friendship records cannot be silently reassigned', () {
    expect(
      adapter.friendshipMoment(
        friendshipId: 'child-a_child-b',
        documentId: 'first_repair_moment',
        data: {
          'friendshipId': 'child-a_child-c',
          'type': 'first_repair_moment',
        },
      ),
      isNull,
    );

    expect(
      adapter.friendshipMoment(
        friendshipId: 'child-a_child-b',
        documentId: 'first_repair_moment',
        data: {
          'friendshipId': 'child-a_child-b',
          'type': 'recovering_friendship',
        },
      ),
      isNull,
    );
  });

  test(
    'unrelated friendship milestones are not individual repair evidence',
    () {
      expect(
        adapter.friendshipMoment(
          friendshipId: 'child-a_child-b',
          documentId: 'consistent_kindness',
          data: {
            'friendshipId': 'child-a_child-b',
            'type': 'consistent_kindness',
          },
        ),
        isNull,
      );
    },
  );
}
