import 'package:flutter_test/flutter_test.dart';
import 'package:natter/friendship_moment_notice.dart';

void main() {
  test('only upward stage changes create invitations', () {
    expect(isUpwardFriendshipStageChange('seedling', 'growing'), isTrue);
    expect(isUpwardFriendshipStageChange('growing', 'trusted'), isTrue);
    expect(isUpwardFriendshipStageChange('strong', 'growing'), isFalse);
    expect(isUpwardFriendshipStageChange('strong', 'strong'), isFalse);
    expect(isUpwardFriendshipStageChange('unknown', 'trusted'), isFalse);
  });

  test('successive moments have distinct versions', () {
    expect(nextFriendshipMomentVersion(<String, dynamic>{}), 1);
    expect(nextFriendshipMomentVersion({
      'friendshipMoment': {'version': 3},
    }), 4);
  });

  test('a saved moment waits independently for each child', () {
    final notice = FriendshipMomentNotice.fromConversationData({
      'friendshipStageChanged': false,
      'friendshipMoment': {
        'version': 2,
        'previousStage': 'growing',
        'stage': 'strong',
        'acknowledgedByChildIds': <String>['child-a'],
      },
    });
    expect(notice, isNotNull);
    expect(notice!.isPendingFor('child-a'), isFalse);
    expect(notice.isPendingFor('child-b'), isTrue);
    expect(notice.isPendingFor(null), isFalse);
  });

  test('malformed or downward events do not render', () {
    expect(FriendshipMomentNotice.fromConversationData({}), isNull);
    expect(FriendshipMomentNotice.fromConversationData({
      'friendshipMoment': {
        'version': 1,
        'previousStage': 'trusted',
        'stage': 'growing',
        'acknowledgedByChildIds': <String>[],
      },
    }), isNull);
  });

  test('every growth milestone has a permanent journey record type', () {
    expect(meaningfulMomentTypeForFriendshipStage('seedling'), isNull);
    expect(
      meaningfulMomentTypeForFriendshipStage('growing'),
      'friendship_growing',
    );
    expect(meaningfulMomentTypeForFriendshipStage('strong'), 'growing_trust');
    expect(
      meaningfulMomentTypeForFriendshipStage('trusted'),
      'trusted_friendship',
    );
    expect(
      meaningfulMomentTypeForFriendshipStage('flourishing'),
      'friendship_flourishing',
    );
  });

  test('an acknowledged milestone can be repaired without a new invitation', () {
    final notice = FriendshipMomentNotice.fromConversationData({
      'friendshipMoment': {
        'version': 1,
        'previousStage': 'seedling',
        'stage': 'growing',
        'acknowledgedByChildIds': <String>['child-a', 'child-b'],
      },
    });
    expect(notice, isNotNull);
    expect(needsFriendshipMomentHistory(notice, null), isTrue);
    expect(needsFriendshipMomentHistory(notice, 0), isTrue);
    expect(needsFriendshipMomentHistory(notice, 1), isFalse);
    expect(needsFriendshipMomentHistory(notice, 2), isFalse);
    expect(needsFriendshipMomentHistory(null, null), isFalse);
  });

}
