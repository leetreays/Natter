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
}
