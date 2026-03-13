import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() => runApp(const NatterApp());

Route<T> calmRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class NatterBrand {
  static const blue = Color(0xFF3DA6F3);
  static const green = Color(0xFFA4D35A);
  static const yellow = Color(0xFFFBC02D);
  static const pink = Color(0xFFFF5DA2);
  static const purple = Color(0xFF9C6BFF);

  static const navy = Color(0xFF06112E);
  static const radius = 24.0;
  static const logoPath = 'assets/natter-logo-v2.png';
}

enum AlertType { blockedWord, quietHours, contactRequest, safetyCoach }

enum SafetyLevel { ok, coach, block }

class SafetyCheckResult {
  final SafetyLevel level;
  final String? reason;
  final String? suggestion;

  const SafetyCheckResult({
    required this.level,
    this.reason,
    this.suggestion,
  });

  const SafetyCheckResult.ok()
      : level = SafetyLevel.ok,
        reason = null,
        suggestion = null;
}

enum NatterLevel {
  promiseKeeper,
  trustedChatter,
  kindCommunicator,
  digitalCitizen,
}

extension NatterLevelInfo on NatterLevel {
  String get title {
    switch (this) {
      case NatterLevel.promiseKeeper:
        return 'Promise Keeper';
      case NatterLevel.trustedChatter:
        return 'Trusted Chatter';
      case NatterLevel.kindCommunicator:
        return 'Kind Communicator';
      case NatterLevel.digitalCitizen:
        return 'Digital Citizen';
    }
  }

  String get description {
    switch (this) {
      case NatterLevel.promiseKeeper:
        return "You've made your Natter promises.";
      case NatterLevel.trustedChatter:
        return "You're building good chat habits.";
      case NatterLevel.kindCommunicator:
        return "You're communicating thoughtfully.";
      case NatterLevel.digitalCitizen:
        return "You're ready for more independence online.";
    }
  }

  String get nextGoal {
    switch (this) {
      case NatterLevel.promiseKeeper:
        return 'Use kind rewriting once and build approved friendships.';
      case NatterLevel.trustedChatter:
        return 'Use kind rewriting 3 times to become a Kind Communicator.';
      case NatterLevel.kindCommunicator:
        return 'Keep showing thoughtful habits as new features arrive.';
      case NatterLevel.digitalCitizen:
        return 'You have reached the current top level.';
    }
  }

  int get progressTarget {
    switch (this) {
      case NatterLevel.promiseKeeper:
        return 1;
      case NatterLevel.trustedChatter:
        return 3;
      case NatterLevel.kindCommunicator:
        return 5;
      case NatterLevel.digitalCitizen:
        return 5;
    }
  }
}

class FriendDirectory {
  static const Map<String, String> codeToName = {
    'AVA-4821': 'Ava',
    'LEO-7314': 'Leo',
    'ZOE-1942': 'Zoe',
    'MAX-5508': 'Max',
  };

  static String? nameForCode(String code) {
    return codeToName[code.trim().toUpperCase()];
  }
}

class Friend {
  final String name;
  int friendshipPoints;

  Friend({
    required this.name,
    this.friendshipPoints = 0,
  });

  int get level {
    if (friendshipPoints >= 100) return 5;
    if (friendshipPoints >= 50) return 4;
    if (friendshipPoints >= 25) return 3;
    if (friendshipPoints >= 10) return 2;
    return 1;
  }

  String get stars => '⭐' * level;
}

class DailyQuest {
  final String title;
  final String description;
  final int target;
  final int rewardStars;
  final IconData icon;

  const DailyQuest({
    required this.title,
    required this.description,
    required this.target,
    required this.rewardStars,
    required this.icon,
  });
}

class FriendshipMoment {
  final String title;
  final String description;
  final IconData icon;
  final DateTime time;

  const FriendshipMoment({
    required this.title,
    required this.description,
    required this.icon,
    required this.time,
  });
}

class AlertEvent {
  final AlertType type;
  final String message;
  final DateTime time;

  AlertEvent({
    required this.type,
    required this.message,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

class NatterBadge {
  final String title;
  final IconData icon;
  final Color color;
  final String description;

  const NatterBadge({
    required this.title,
    required this.icon,
    required this.color,
    this.description = '',
  });
}

NatterBadge badgeForPromises(Set<String> promises) {
  return const NatterBadge(
    title: 'Promise Keeper',
    icon: Icons.shield_rounded,
    color: NatterBrand.yellow,
    description: 'Awarded for sealing your Natter promises.',
  );
}

class AvatarData {
  final int faceIndex;
  final int hairIndex;
  final int accessoryIndex;
  final Color skinColor;
  final Color hairColor;
  final Color shirtColor;

  const AvatarData({
    required this.faceIndex,
    required this.hairIndex,
    required this.accessoryIndex,
    required this.skinColor,
    required this.hairColor,
    required this.shirtColor,
  });

  AvatarData copyWith({
    int? faceIndex,
    int? hairIndex,
    int? accessoryIndex,
    Color? skinColor,
    Color? hairColor,
    Color? shirtColor,
  }) {
    return AvatarData(
      faceIndex: faceIndex ?? this.faceIndex,
      hairIndex: hairIndex ?? this.hairIndex,
      accessoryIndex: accessoryIndex ?? this.accessoryIndex,
      skinColor: skinColor ?? this.skinColor,
      hairColor: hairColor ?? this.hairColor,
      shirtColor: shirtColor ?? this.shirtColor,
    );
  }
}

class NatterReaction {
  static const List<String> allowed = ['👍', '❤️', '🌟', '🎉', '😂'];
}

class ConversationStarterOption {
  final String label;
  final String message;

  const ConversationStarterOption({
    required this.label,
    required this.message,
  });
}

class ConversationStarters {
  static List<ConversationStarterOption> forFriend(String friendName) {
    return [
      ConversationStarterOption(
        label: 'Ask $friendName what made them laugh today',
        message: 'What made you laugh today?',
      ),
      ConversationStarterOption(
        label: 'Tell $friendName something good about your day',
        message: 'Something good happened today!',
      ),
      ConversationStarterOption(
        label: 'Ask $friendName what game they like best',
        message: 'What game do you like best?',
      ),
      ConversationStarterOption(
        label: 'Ask $friendName what they did after school',
        message: 'What did you do after school?',
      ),
      ConversationStarterOption(
        label: 'Ask $friendName what their favourite snack is',
        message: 'What is your favourite snack?',
      ),
      ConversationStarterOption(
        label: 'Tell $friendName your favourite part of today',
        message: 'My favourite part of today was...',
      ),
      ConversationStarterOption(
        label: 'Ask $friendName what they would do with a superpower',
        message: 'What would you do if you had a superpower?',
      ),
      ConversationStarterOption(
        label: 'Ask $friendName which animal they would be',
        message: 'If you could be any animal, what would you be?',
      ),
    ];
  }
}

class ChatPreview {
  final String name;
  final String last;
  final bool unread;

  const ChatPreview({
    required this.name,
    required this.last,
    required this.unread,
  });
}

class AppState extends ChangeNotifier {
  final String myFriendCode = 'NAT-2048';
  final List<Friend> approvedContacts = [
    Friend(name: 'Dad', friendshipPoints: 40),
    Friend(name: 'Sam', friendshipPoints: 18),
    Friend(name: 'Mia', friendshipPoints: 8),
  ];
  final List<String> pendingRequests = ['Ava', 'Leo'];

  bool quietHoursEnabled = true;
  TimeOfDay quietStart = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay quietEnd = const TimeOfDay(hour: 7, minute: 0);

  // ===== Parent Peace Dashboard Counters =====
int positiveMessages = 0;
int blockedAttempts = 0;
int quietHoursAttempts = 0;
int coachPrompts = 0;
  
  bool alertsBlockedWord = true;
  bool alertsContactRequest = true;
  bool alertsQuietHours = true;
  bool alertsSafetyCoach = true;

  final List<AlertEvent> alerts = [];

  List<String> lastPromises = const [];
  String? lastName;
  NatterBadge? lastBadge;

  int kindnessRewrites = 0;
  int kindnessStreak = 0;
  int kindnessStars = 0;
  String? celebrationTitle;
  String? celebrationMessage;
  NatterLevel currentLevel = NatterLevel.promiseKeeper;

  DailyQuest dailyQuest = const DailyQuest(
    title: 'Kindness Quest',
    description: 'Send 3 positive messages today.',
    target: 3,
    rewardStars: 3,
    icon: Icons.auto_awesome_rounded,
  );
  int dailyQuestProgress = 0;
  bool dailyQuestCompleted = false;
  
  final List<NatterBadge> earnedBadges = [];

  final List<FriendshipMoment> friendshipMoments = [];
  
  int weeklyApprovedFriends = 0;
  int weeklyBlockedAttempts = 0;
  int weeklyQuietHoursAttempts = 0;
  int weeklyCoachPrompts = 0;
  int weeklyFriendRequests = 0;

  AvatarData avatar = const AvatarData(
    faceIndex: 0,
    hairIndex: 0,
    accessoryIndex: 0,
    skinColor: Color(0xFFF2C9A0),
    hairColor: Color(0xFF3E2723),
    shirtColor: NatterBrand.blue,
  );

  bool get canRequestFriends =>
      currentLevel.index >= NatterLevel.trustedChatter.index;

  bool get hasUnlockedKindnessCoach =>
      currentLevel.index >= NatterLevel.promiseKeeper.index;

  bool get hasUnlockedFriendRequests =>
      currentLevel.index >= NatterLevel.trustedChatter.index;

  bool get hasUnlockedAdvancedCommunication =>
      currentLevel.index >= NatterLevel.kindCommunicator.index;

  int get progressValue {
    switch (currentLevel) {
      case NatterLevel.promiseKeeper:
        return kindnessRewrites.clamp(0, 1);
      case NatterLevel.trustedChatter:
        return kindnessRewrites.clamp(0, 3);
      case NatterLevel.kindCommunicator:
        return kindnessRewrites.clamp(0, 5);
      case NatterLevel.digitalCitizen:
        return 5;
    }
  }

  double get progressPercent {
    final target = currentLevel.progressTarget;
    if (target == 0) return 1;
    return (progressValue / target).clamp(0, 1);
  }
  
int get kindnessScore {
    int score = 100;

    score -= weeklyBlockedAttempts * 12;
    score -= weeklyQuietHoursAttempts * 8;
    score -= weeklyCoachPrompts * 5;

    score += kindnessRewrites * 4;
    score += kindnessStreak * 2;

    if (score > 100) score = 100;
    if (score < 0) score = 0;

    return score;
  }

  String get peaceStatus {
    if (weeklyBlockedAttempts >= 2 || weeklyQuietHoursAttempts >= 3) {
      return 'Needs review';
    }
    if (weeklyCoachPrompts >= 2 || weeklyBlockedAttempts == 1) {
      return 'Mostly calm';
    }
    return 'Everything looks good';
  }

  Color get peaceColor {
    if (weeklyBlockedAttempts >= 2 || weeklyQuietHoursAttempts >= 3) {
      return NatterBrand.pink;
    }
    if (weeklyCoachPrompts >= 2 || weeklyBlockedAttempts == 1) {
      return NatterBrand.yellow;
    }
    return NatterBrand.green;
  }
  
  bool _isTimeInRange(TimeOfDay t, TimeOfDay start, TimeOfDay end) {
    int toMin(TimeOfDay x) => x.hour * 60 + x.minute;
    final tm = toMin(t);
    final sm = toMin(start);
    final em = toMin(end);

    if (sm < em) return tm >= sm && tm < em;
    return tm >= sm || tm < em;
  }

  bool isQuietNow() {
    if (!quietHoursEnabled) return false;
    final now = TimeOfDay.fromDateTime(DateTime.now());
    return _isTimeInRange(now, quietStart, quietEnd);
  }

  bool isApproved(String name) =>
      approvedContacts.any((c) => c.name.toLowerCase() == name.toLowerCase());
  
  bool isPending(String name) =>
      pendingRequests.any((p) => p.toLowerCase() == name.toLowerCase());

  Friend? getFriendByName(String name) {
    try {
      return approvedContacts.firstWhere(
        (f) => f.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  void addFriendshipPoints(String name, int points) {
  final friend = getFriendByName(name);
  if (friend == null) return;

  final beforeLevel = friend.level;
  friend.friendshipPoints += points;
  final afterLevel = friend.level;

  if (afterLevel > beforeLevel) {
    addFriendshipMoment(
      title: 'Friendship Level Up!',
      description: '💛 ${friend.name} is now Friendship Level $afterLevel.',
      icon: Icons.workspace_premium_rounded,
      celebrate: true,
    );
  }

  notifyListeners();
  }  
  void updateAvatar(AvatarData newAvatar) {
    avatar = newAvatar;
    notifyListeners();
  }

  void _checkDailyQuestProgress() {
    if (!dailyQuestCompleted && dailyQuestProgress >= dailyQuest.target) {
      dailyQuestCompleted = true;
      kindnessStars += dailyQuest.rewardStars;

      _awardBadge(
        const NatterBadge(
          title: 'Quest Finisher',
          icon: Icons.task_alt_rounded,
          color: NatterBrand.purple,
          description: 'Awarded for completing a daily quest.',
        ),
        celebrationTitleText: 'Daily Quest Complete!',
        celebrationMessageText:
            '✨ ${dailyQuest.title} complete!\n\nYou earned ${dailyQuest.rewardStars} bonus stars.',
      );
    }
  }

  void addFriendshipMoment({
    required String title,
    required String description,
    required IconData icon,
    bool celebrate = false,
  }) {
    friendshipMoments.insert(
      0,
      FriendshipMoment(
        title: title,
        description: description,
        icon: icon,
        time: DateTime.now(),
      ),
    );

    if (celebrate) {
      celebrationTitle = title;
      celebrationMessage = description;
    }

    notifyListeners();
  }

  void recordDailyQuestStep() {
    if (dailyQuestCompleted) return;
    dailyQuestProgress += 1;
    _checkDailyQuestProgress();
    notifyListeners();
  }

  void requestContact(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (isApproved(trimmed) || isPending(trimmed)) return;

    pendingRequests.insert(0, trimmed);
    weeklyFriendRequests += 1;

    if (alertsContactRequest) {
      addAlert(AlertEvent(
        type: AlertType.contactRequest,
        message: 'New contact request: $trimmed',
      ));
    }

    notifyListeners();
  }

  void addAlert(AlertEvent e) {
    alerts.insert(0, e);
    notifyListeners();
  }

  void clearAlerts() {
    alerts.clear();
    notifyListeners();
  }

  void approveContact(String name) {
    pendingRequests.removeWhere((p) => p.toLowerCase() == name.toLowerCase());
    if (!isApproved(name)) {
      approvedContacts.add(Friend(name: name, friendshipPoints: 0));
    }
    weeklyApprovedFriends += 1;
    evaluateProgress();
    notifyListeners();
  }

  void blockContact(String name) {
    pendingRequests.removeWhere((p) => p.toLowerCase() == name.toLowerCase());
    notifyListeners();
  }

  void setQuietEnabled(bool v) {
    quietHoursEnabled = v;
    notifyListeners();
  }

  void setQuietStart(TimeOfDay t) {
    quietStart = t;
    notifyListeners();
  }

  void setQuietEnd(TimeOfDay t) {
    quietEnd = t;
    notifyListeners();
  }

  void setAlerts({
    bool? blockedWord,
    bool? contactRequest,
    bool? quietHours,
    bool? safetyCoach,
  }) {
    if (blockedWord != null) alertsBlockedWord = blockedWord;
    if (contactRequest != null) alertsContactRequest = contactRequest;
    if (quietHours != null) alertsQuietHours = quietHours;
    if (safetyCoach != null) alertsSafetyCoach = safetyCoach;
    notifyListeners();
  }

  void recordBlockedAttempt() {
  blockedAttempts++;
  notifyListeners();
  }

  void recordQuietHoursAttempt() {
  quietHoursAttempts++;
  notifyListeners();
  }

  void recordCoachPrompt() {
  coachPrompts++;
  notifyListeners();
  }

  void recordRite({
    required String name,
    required List<String> promises,
  }) {
    lastName = name;
    lastPromises = List<String>.from(promises);
    lastBadge = badgeForPromises(promises.toSet());
    currentLevel = NatterLevel.promiseKeeper;
    kindnessRewrites = 0;
    kindnessStreak = 0;
    kindnessStars = 0;
    celebrationMessage = null;

    earnedBadges
      ..clear()
      ..add(lastBadge!);

    notifyListeners();
  }

  void dismissCelebration() {
    celebrationTitle = null;
    celebrationMessage = null;
    notifyListeners();
  }
  
  void _awardBadge(
    NatterBadge badge, {
    String? celebrationTitleText,
    String? celebrationMessageText,
  }) {
    final alreadyEarned = earnedBadges.any((b) => b.title == badge.title);
    if (alreadyEarned) return;

    earnedBadges.add(badge);

    if (celebrationTitleText != null || celebrationMessageText != null) {
      celebrationTitle = celebrationTitleText;
      celebrationMessage = celebrationMessageText;
    }
  }

  SafetyCheckResult checkMessageSafety(String text) {
    final lower = text.trim().toLowerCase();

    if (lower.isEmpty) {
      return const SafetyCheckResult.ok();
    }

    const blockedTerms = ['badword', 'swear'];

    for (final term in blockedTerms) {
      if (lower.contains(term)) {
        return const SafetyCheckResult(
          level: SafetyLevel.block,
          reason: 'That word is not allowed on Natter.',
          suggestion: 'Try saying it in a calmer or kinder way.',
        );
      }
    }

    const coachingPatterns = {
      "you're stupid": "I’m upset right now. Can we try again?",
      "you are stupid": "I’m upset right now. Can we try again?",
      "i hate you": "I’m really upset and need a minute.",
      "shut up": "Can we slow down for a second?",
      "go away": "I need some space right now.",
      "leave me alone": "I want a little quiet time right now.",
      "idiot": "That upset me. Can we talk kindly?",
      "dumb": "That didn’t feel good. Can we reset?",
      "mean": "That felt unkind. Can we start over?",
    };

    for (final entry in coachingPatterns.entries) {
      if (lower.contains(entry.key)) {
        return SafetyCheckResult(
          level: SafetyLevel.coach,
          reason: 'That message could hurt someone’s feelings.',
          suggestion: entry.value,
        );
      }
    }

    return const SafetyCheckResult.ok();
  }

  void _checkStreakMilestones() {
    if (kindnessStreak == 3) {
      _awardBadge(
        const NatterBadge(
          title: 'Kindness Spark',
          icon: Icons.auto_awesome_rounded,
          color: NatterBrand.yellow,
          description: 'Earned for a 3-message kindness streak.',
        ),
        celebrationTitleText: 'New Badge Unlocked!',
        celebrationMessageText:
            '🌟 Kindness Spark unlocked for a 3-message kindness streak.',
      );
    } else if (kindnessStreak == 5) {
      _awardBadge(
        const NatterBadge(
          title: 'Heart Starter',
          icon: Icons.favorite_rounded,
          color: NatterBrand.pink,
          description: 'Earned for a 5-message kindness streak.',
        ),
        celebrationTitleText: 'New Badge Unlocked!',
        celebrationMessageText:
            '💛 Heart Starter unlocked for a 5-message kindness streak.',
      );
    } else if (kindnessStreak == 10) {
      _awardBadge(
        const NatterBadge(
          title: 'Kindness Rocket',
          icon: Icons.rocket_launch_rounded,
          color: NatterBrand.green,
          description: 'Earned for a 10-message kindness streak.',
        ),
        celebrationTitleText: 'New Badge Unlocked!',
        celebrationMessageText:
            '🚀 Kindness Rocket unlocked for a 10-message kindness streak.',
      );
    }
  }

  void recordPositiveMessage() {
  positiveMessages++;
  kindnessStreak++;

  if (kindnessStreak == 3) {
    addFriendshipMoment(
      title: 'Friendship Moment',
      description: '⭐ You built a 3-message kindness streak.',
      icon: Icons.favorite_rounded,
      celebrate: true,
    );
  }

  notifyListeners();
  }

  void recordKindRewrite() {
  kindnessRewrites++;

  addAlert(AlertEvent(
    type: AlertType.safetyCoach,
    message: "A message was rewritten kindly.",
  ));

  if (kindnessRewrites == 1) {
    addFriendshipMoment(
      title: 'Friendship Moment',
      description: '🌱 You chose to rewrite a message kindly.',
      icon: Icons.auto_awesome_rounded,
      celebrate: true,
    );
  }

  evaluateProgress();
  notifyListeners();
  }

  void evaluateProgress() {
    var didLevelUp = false;

    if (currentLevel == NatterLevel.promiseKeeper) {
      if (approvedContacts.isNotEmpty && kindnessRewrites >= 1) {
        currentLevel = NatterLevel.trustedChatter;
        didLevelUp = true;

        _awardBadge(
          const NatterBadge(
            title: 'Trusted Chatter',
            icon: Icons.chat_bubble_rounded,
            color: NatterBrand.green,
            description: 'Unlocked after showing good early chat habits.',
          ),
          celebrationTitleText: 'Level Up!',
          celebrationMessageText:
              '🎉 You are now a Trusted Chatter.\n\nFriend requests are now unlocked.',
        );

        addAlert(AlertEvent(
          type: AlertType.safetyCoach,
          message: 'Level up: Trusted Chatter unlocked.',
        ));
      }
    }

    if (currentLevel == NatterLevel.trustedChatter) {
      if (kindnessRewrites >= 3) {
        currentLevel = NatterLevel.kindCommunicator;
        didLevelUp = true;

        _awardBadge(
          const NatterBadge(
            title: 'Kind Communicator',
            icon: Icons.workspace_premium_rounded,
            color: NatterBrand.pink,
            description: 'Unlocked after multiple kind rewrites.',
          ),
          celebrationTitleText: 'Level Up!',
          celebrationMessageText:
              '🏅 You are now a Kind Communicator.\n\nYou are building really thoughtful chat habits.',
        );

        addAlert(AlertEvent(
          type: AlertType.safetyCoach,
          message: 'Level up: Kind Communicator unlocked.',
        ));
      }
    }

    if (didLevelUp) {
      notifyListeners();
    }
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope?.notifier != null, 'AppStateScope not found');
    return scope!.notifier!;
  }
}

class NatterApp extends StatelessWidget {
  const NatterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light();
    final state = AppState();

    return AppStateScope(
      notifier: state,
      child: MaterialApp(
        title: 'Natter',
        debugShowCheckedModeBanner: false,
        theme: base.copyWith(
          scaffoldBackgroundColor: NatterBrand.navy,
          colorScheme: base.colorScheme.copyWith(
            primary: NatterBrand.blue,
            secondary: NatterBrand.green,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: Colors.black.withOpacity(0.85),
            contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            behavior: SnackBarBehavior.floating,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.14),
            hintStyle: const TextStyle(color: Colors.white70),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NatterBrand.radius),
              borderSide: BorderSide.none,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: NatterBrand.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          chipTheme: base.chipTheme.copyWith(
            backgroundColor: Colors.white,
            selectedColor: NatterBrand.yellow,
            labelStyle: const TextStyle(
              color: NatterBrand.navy,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: Colors.white12,
            thickness: 1,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class BubblyBackground extends StatelessWidget {
  final Widget child;
  const BubblyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2B7FFF),
                Color(0xFF133A8A),
                Color(0xFF06112E),
              ],
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _ConfettiPainter())),
        child,
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    final paints = [
      Paint()..color = NatterBrand.yellow.withOpacity(0.22),
      Paint()..color = NatterBrand.green.withOpacity(0.18),
      Paint()..color = NatterBrand.pink.withOpacity(0.16),
      Paint()..color = Colors.white.withOpacity(0.10),
    ];

    for (int i = 0; i < 70; i++) {
      final p = paints[rnd.nextInt(paints.length)];
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = 3 + rnd.nextDouble() * 10;
      canvas.drawCircle(Offset(dx, dy), r, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BrandScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget child;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const BrandScaffold({
    super.key,
    this.appBar,
    required this.child,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: BubblyBackground(child: SafeArea(child: child)),
    );
  }
}

class BrandCard extends StatelessWidget {
  final Widget child;
  const BrandCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(NatterBrand.radius),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}

class NatterLogo extends StatelessWidget {
  final double height;
  const NatterLogo({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Image.asset(
        NatterBrand.logoPath,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Failed to load logo: ${NatterBrand.logoPath}');
          debugPrint(error.toString());
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NatterBrand.yellow, width: 2),
            ),
            child: const Text(
              'Logo missing',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        },
      ),
    );
  }
}

class BrandedAppBarTitle extends StatelessWidget {
  final String title;
  const BrandedAppBarTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NatterLogo(height: 22),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

// ===== Screens =====
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandScaffold(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const NatterLogo(height: 170),
                const SizedBox(height: 12),
                const Text(
                  'Playful, safe messaging for kids.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),
                const BrandCard(
                  child: Text(
                    'Text-only chats • Kinder words • Parent controls',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.push(context, calmRoute(const RiteScreen())),
                    child: const Text('Begin ✨'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RiteScreen extends StatefulWidget {
  const RiteScreen({super.key});

  @override
  State<RiteScreen> createState() => _RiteScreenState();
}

class _RiteScreenState extends State<RiteScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type your name first 🙂')),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    Navigator.pushReplacement(context, calmRoute(PromiseScreen(name: name)));
  }

  @override
  Widget build(BuildContext context) {
    return BrandScaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Your first step'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: BrandCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Before you enter Natter…\nWhat should we call you?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter your name',
                    ),
                    onSubmitted: (_) => _continue(),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _continue,
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PromiseScreen extends StatefulWidget {
  final String name;
  const PromiseScreen({super.key, required this.name});

  @override
  State<PromiseScreen> createState() => _PromiseScreenState();
}

class _PromiseScreenState extends State<PromiseScreen> {
  final options = const [
    'Be kind',
    'No secrets from adults',
    'If it feels weird, stop',
    'Ask before adding friends',
    'Keep it text-only',
    'Take breaks',
  ];

  final Set<String> selected = {};

  void _seal() {
    final promises = selected.toList();

    AppStateScope.of(context).recordRite(
      name: widget.name,
      promises: promises,
    );

    Navigator.push(
      context,
      calmRoute(
        CeremonyScreen(
          name: widget.name,
          promises: promises,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = 3 - selected.length;
    final canContinue = selected.length >= 3;

    return BrandScaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Your promises'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                BrandCard(
                  child: Column(
                    children: [
                      Text(
                        'Okay, ${widget.name} 😊',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: NatterBrand.navy,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pick 3 promises for your Natter life:',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: options.map((t) {
                          final isOn = selected.contains(t);
                          return ChoiceChip(
                            label: Text(t),
                            selected: isOn,
                            onSelected: (_) {
                              setState(() {
                                if (isOn) {
                                  selected.remove(t);
                                } else {
                                  if (selected.length < 3) selected.add(t);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  canContinue
                      ? 'Nice. That’s your promise set.'
                      : 'Choose $remaining more',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canContinue ? _seal : null,
                    child: const Text('Seal My Promises ✨'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CeremonyScreen extends StatelessWidget {
  final String name;
  final List<String> promises;

  const CeremonyScreen({
    super.key,
    required this.name,
    required this.promises,
  });

  @override
  Widget build(BuildContext context) {
    final badge = badgeForPromises(promises.toSet());

    return BrandScaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Sealed'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: _SimpleCeremony(
                name: name,
                promises: promises,
                badge: badge,
                onEnter: () {
                  Navigator.pushReplacement(
                    context,
                    calmRoute(const ChatsScreen()),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleCeremony extends StatelessWidget {
  final String name;
  final List<String> promises;
  final NatterBadge badge;
  final VoidCallback onEnter;

  const _SimpleCeremony({
    required this.name,
    required this.promises,
    required this.badge,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 72,
            color: NatterBrand.yellow,
          ),
          const SizedBox(height: 10),
          Text(
            'Welcome to Natter',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Your promises:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...promises.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Text(
                  p,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          BadgeCard(name: name, badge: badge),
          const SizedBox(height: 18),
          Text(
            "You're officially in. 🌿",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: NatterBrand.green.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onEnter,
              child: const Text('Enter Natter ✨'),
            ),
          ),
        ],
      ),
    );
  }
}

class AvatarPreview extends StatelessWidget {
  final AvatarData avatar;
  final double size;

  const AvatarPreview({
    super.key,
    required this.avatar,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    final faceOptions = ['🙂', '😄', '😎', '🤩'];
    final hairOptions = ['🟫', '⬛', '🟨', '🟧'];
    final accessoryOptions = ['•', '🕶', '🎀', '🧢'];

    final face = faceOptions[avatar.faceIndex % faceOptions.length];
    final hair = hairOptions[avatar.hairIndex % hairOptions.length];
    final accessory =
        accessoryOptions[avatar.accessoryIndex % accessoryOptions.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: avatar.shirtColor.withOpacity(0.22),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.28), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.16,
            child: Text(
              hair,
              style: TextStyle(fontSize: size * 0.18),
            ),
          ),
          Text(
            face,
            style: TextStyle(fontSize: size * 0.38),
          ),
          if (accessory != '•')
            Positioned(
              bottom: size * 0.12,
              child: Text(
                accessory,
                style: TextStyle(fontSize: size * 0.16),
              ),
            ),
        ],
      ),
    );
  }
}

class AvatarBuilderScreen extends StatefulWidget {
  const AvatarBuilderScreen({super.key});

  @override
  State<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends State<AvatarBuilderScreen> {
  late AvatarData draft;

  final skinPalette = const [
    Color(0xFFF2C9A0),
    Color(0xFFD9A77C),
    Color(0xFFB97C5A),
    Color(0xFF8A5A44),
  ];

  final hairPalette = const [
    Color(0xFF3E2723),
    Color(0xFF1B1B1B),
    Color(0xFFD4A017),
    Color(0xFF8D6E63),
  ];

  final shirtPalette = const [
    NatterBrand.blue,
    NatterBrand.green,
    NatterBrand.pink,
    NatterBrand.purple,
    NatterBrand.yellow,
  ];

@override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = AppStateScope.of(context).avatar;
  }

  Widget _pickerButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.14),
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

  Widget _colorDot({
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withOpacity(0.24),
            width: selected ? 3 : 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return BrandScaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Avatar Builder'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BrandCard(
            child: Column(
              children: [
                AvatarPreview(avatar: draft, size: 130),
                const SizedBox(height: 14),
                const Text(
                  'Make your Natter character',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose the look that feels most like you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.84),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Face and style',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _pickerButton(
                      label: 'Face',
                      onTap: () {
                        setState(() {
                          draft = draft.copyWith(
                            faceIndex: draft.faceIndex + 1,
                          );
                        });
                      },
                    ),
                    _pickerButton(
                      label: 'Hair',
                      onTap: () {
                        setState(() {
                          draft = draft.copyWith(
                            hairIndex: draft.hairIndex + 1,
                          );
                        });
                      },
                    ),
                    _pickerButton(
                      label: 'Accessory',
                      onTap: () {
                        setState(() {
                          draft = draft.copyWith(
                            accessoryIndex: draft.accessoryIndex + 1,
                          );
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Skin tone',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
      const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: skinPalette.map((c) {
                    return _colorDot(
                      color: c,
                      selected: draft.skinColor == c,
                      onTap: () {
                        setState(() {
                          draft = draft.copyWith(skinColor: c);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Hair colour',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: hairPalette.map((c) {
                    return _colorDot(
                      color: c,
                      selected: draft.hairColor == c,
                      onTap: () {
                        setState(() {
                          draft = draft.copyWith(hairColor: c);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Shirt colour',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: shirtPalette.map((c) {
                    return _colorDot(
                      color: c,
                      selected: draft.shirtColor == c,
                      onTap: () {
                        setState(() {
                          draft = draft.copyWith(shirtColor: c);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                state.updateAvatar(draft);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Avatar saved! ✨'),
                  ),
                );
              },
              child: const Text('Save Avatar'),
            ),
          ),
        ],
      ),
    );
  }
}
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final displayName = state.lastName ?? 'Natter User';

    return BrandScaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BrandCard(
            child: Column(
              children: [
                AvatarPreview(avatar: state.avatar, size: 120),
                const SizedBox(height: 14),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.currentLevel.title,
                  style: const TextStyle(
                    color: NatterBrand.yellow,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.currentLevel.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.84),
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      calmRoute(const AvatarBuilderScreen()),
                    ),
                    child: const Text('Edit Avatar'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Progress'),
                const SizedBox(height: 14),
                _ProgressBarCard(state: state),
                const SizedBox(height: 14),
                Text(
                  'Next goal: ${state.currentLevel.nextGoal}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.84),
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Stats'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ProfileStatTile(
                      label: 'Stars',
                      value: state.kindnessStars.toString(),
                    ),
                    _ProfileStatTile(
                      label: 'Streak',
                      value: state.kindnessStreak.toString(),
                    ),
                    _ProfileStatTile(
                      label: 'Rewrites',
                      value: state.kindnessRewrites.toString(),
                    ),
                    _ProfileStatTile(
                      label: 'Friends',
                      value: state.approvedContacts.length.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Badges'),
                const SizedBox(height: 14),
                if (state.earnedBadges.isEmpty)
                  Text(
                    'No badges yet.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.84),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  ...state.earnedBadges.map(
                    (badge) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BadgeCard(
                        name: displayName,
                        badge: badge,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: NatterBrand.yellow,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Friendship Moments',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.friendshipMoments.isEmpty)
                  Text(
                    'No friendship moments yet.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.84),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  ...state.friendshipMoments.take(6).map(
                    (moment) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.16),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: NatterBrand.yellow.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: NatterBrand.yellow.withOpacity(0.45),
                                ),
                              ),
                              child: Icon(
                                moment.icon,
                                color: NatterBrand.yellow,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    moment.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    moment.description,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.84),
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 14),
          if (state.lastPromises.isNotEmpty)
            BrandCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('My Promises'),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: state.lastPromises.map((p) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Text(
                          p,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStatTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.84),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
  value,
  style: const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 24,
    height: 1.0,
  ),
),
        ],
      ),
    );
  }
}

class _ProgressBarCard extends StatelessWidget {
  final AppState state;

  const _ProgressBarCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final percent = state.progressPercent;
    final progressText =
        '${state.progressValue}/${state.currentLevel.progressTarget}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.currentLevel.title,
          style: const TextStyle(
            color: NatterBrand.yellow,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 14,
            backgroundColor: Colors.white.withOpacity(0.14),
            valueColor: const AlwaysStoppedAnimation<Color>(NatterBrand.green),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Progress: $progressText',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  Future<void> _addFriendDialog(BuildContext context) async {
    final state = AppStateScope.of(context);
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.72),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add a friend',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Enter their friend code. A parent will approve it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. AVA-4821',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.22),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final code = controller.text.trim().toUpperCase();
                          final friendName = FriendDirectory.nameForCode(code);

                          if (friendName == null) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'That friend code was not recognised.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (!state.canRequestFriends) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "You'll unlock friend requests soon as you keep chatting kindly.",
                                ),
                              ),
                            );
                            return;
                          }

                          if (state.isApproved(friendName)) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$friendName is already in your chats 🙂',
                                ),
                              ),
                            );
                            return;
                          }

                          if (state.isPending(friendName)) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$friendName is already waiting for approval ⏳',
                                ),
                              ),
                            );
                            return;
                          }

                          state.requestContact(friendName);

                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Request sent for $friendName! A parent will approve it.',
                              ),
                            ),
                          );
                        },
                        child: const Text('Request'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCelebrationCard(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(18),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.88),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
              boxShadow: [
                BoxShadow(
                  color: NatterBrand.yellow.withOpacity(0.20),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: NatterBrand.yellow.withOpacity(0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NatterBrand.yellow.withOpacity(0.45),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: NatterBrand.yellow,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Keep Going ✨'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _levelCard(AppState state) {
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
  children: [
    Icon(
      Icons.workspace_premium_rounded,
      color: NatterBrand.yellow,
      size: 22,
    ),
    SizedBox(width: 8),
    Text(
      'Your Natter Level',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 18,
      ),
    ),
  ],
),
          const SizedBox(height: 10),
          Text(
            state.currentLevel.title,
            style: const TextStyle(
              color: NatterBrand.yellow,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.currentLevel.description,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _ProgressBarCard(state: state),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kindness Streak',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.kindnessStreak} positive messages in a row 🔥',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.kindnessStreak < 3
                      ? 'Reach 3 for Kindness Spark.'
                      : state.kindnessStreak < 5
                          ? 'Reach 5 for Heart Starter.'
                          : state.kindnessStreak < 10
                              ? 'Reach 10 for Kindness Rocket.'
                              : 'Amazing streak — keep it going!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(BuildContext context, AppState state) {
    return BrandCard(
      child: Row(
        children: [
          AvatarPreview(avatar: state.avatar, size: 74),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.lastName ?? 'Your profile',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.kindnessStars} stars • ${state.kindnessStreak} streak',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.84),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              calmRoute(const ProfileScreen()),
            ),
            child: const Text('Profile'),
          ),
        ],
      ),
    );
  }

  Widget _dailyQuestCard(AppState state) {
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.dailyQuest.icon,
                color: NatterBrand.yellow,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Daily Quest',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            state.dailyQuest.title,
            style: const TextStyle(
              color: NatterBrand.yellow,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            state.dailyQuest.description,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value:
                  (state.dailyQuestProgress / state.dailyQuest.target).clamp(0, 1),
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.14),
              valueColor: AlwaysStoppedAnimation<Color>(
                state.dailyQuestCompleted
                    ? NatterBrand.green
                    : NatterBrand.yellow,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            state.dailyQuestCompleted
                ? 'Complete! +${state.dailyQuest.rewardStars} stars earned ✨'
                : 'Progress: ${state.dailyQuestProgress}/${state.dailyQuest.target}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.86),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _friendCodeCard(BuildContext context, AppState state) {
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your friend code',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.myFriendCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text:
                            'Add me on Natter with my friend code: ${state.myFriendCode}',
                      ),
                    );

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Friend code copied! Share it with a friend.',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NatterBrand.green,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Copy'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    final chats = state.approvedContacts
        .map(
          (friend) => ChatPreview(
            name: friend.name,
            last: friend.name == 'Dad' ? 'Dinner at 6 😊' : 'Say hi 👋',
            unread: friend.name == 'Dad' || friend.name == 'Sam',
          ),
        )
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final title = state.celebrationTitle;
      final message = state.celebrationMessage;

      if (title != null && message != null) {
        state.dismissCelebration();
        await _showCelebrationCard(
          context,
          title: title,
          message: message,
        );
      }
    });

    return BrandScaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Chats'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              calmRoute(const ProfileScreen()),
            ),
            icon: const Icon(Icons.account_circle_rounded),
            tooltip: 'My Profile',
          ),
          IconButton(
            onPressed: () => _addFriendDialog(context),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add Friend',
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              calmRoute(const ParentHomeScreen()),
            ),
            child: const Text(
              'Parent',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addFriendDialog(context),
        backgroundColor: NatterBrand.green,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add Friend',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _levelCard(state),
          const SizedBox(height: 12),
          _profileCard(context, state),
          const SizedBox(height: 12),
          _dailyQuestCard(state),
          const SizedBox(height: 12),
          _friendCodeCard(context, state),
          const SizedBox(height: 12),
          ...chats.map((c) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BrandCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: NatterBrand.yellow.withOpacity(0.35),
                    child: Text(
                      c.name.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  title: Builder(
                    builder: (context) {
                      final friend = state.getFriendByName(c.name);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (friend != null)
                            Text(
                              'Friendship ${friend.stars}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.78),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  subtitle: Text(
                    c.last,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: c.unread
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: NatterBrand.green,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        )
                      : const Icon(Icons.chevron_right, color: Colors.white),
                  onTap: () => Navigator.push(
                    context,
                    calmRoute(ChatScreen(contactName: c.name)),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
class ChatScreen extends StatefulWidget {
  final String contactName;
  const ChatScreen({super.key, required this.contactName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final List<_Msg> messages = [
    _Msg(fromMe: false, text: 'Hey! 👋'),
    _Msg(fromMe: false, text: 'Wanna chat?'),
  ];
  String? feedback;
  int _stallCounter = 0;
  Timer? _stallTimer;
  
  Future<bool> _showSafetyCoachDialog({
    required String suggestion,
    required String reason,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.80),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: NatterBrand.pink,
                  size: 42,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Try a kinder message',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.16)),
                  ),
                  child: Text(
                    suggestion,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.22),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          controller.text = suggestion;
                          controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: controller.text.length),
                          );
                          Navigator.pop(ctx, false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NatterBrand.green,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Rewrite'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Send anyway'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

Future<void> _pickReaction(int index) async {
    final msg = messages[index];
    if (msg.fromMe) return;

    final selected = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.82),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose a reaction',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: NatterReaction.allowed.map((emoji) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => Navigator.pop(ctx, emoji),
                      child: Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, '__remove__'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.22)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Remove reaction',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() {
      if (selected == '__remove__') {
        msg.reaction = null;
      } else if (msg.reaction == selected) {
        msg.reaction = null;
      } else {
        msg.reaction = selected;
      }
    });
  }

  Future<void> _pickStarter() async {
    final controllerText = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
  'Conversation Starter',
  style: TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 20,
  ),
),
const SizedBox(height: 8),
Text(
  'Try one with ${widget.contactName}.',
  textAlign: TextAlign.center,
  style: TextStyle(
    color: Colors.white.withOpacity(0.82),
    fontWeight: FontWeight.w700,
  ),
),
const SizedBox(height: 14),
                ...ConversationStarters.forFriend(widget.contactName).map((option) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      onTap: () => Navigator.pop(ctx, option.message),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.16),
                          ),
                        ),
                        child: Text(
                          option.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );

    if (controllerText != null) {
      controller.text = controllerText;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }
  }
  
void _showStallRescue() {
  showDialog(
    context: context,
    builder: (ctx) {
      final starters =
          ConversationStarters.forFriend(widget.contactName).take(3).toList();

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: NatterBrand.yellow,
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                "Need help continuing?",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 14),
              ...starters.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      controller.text = option.message;
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length),
                      );
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                      child: Text(
                        option.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
  
void _revealFlaggedMessage(_Msg msg) {
    setState(() {
      msg.isRevealed = true;
    });
  }

  void _hideFlaggedMessage(_Msg msg) {
    setState(() {
      msg.isHidden = true;
    });
  }

  void _blockAfterFlaggedMessage(_Msg msg) {
    final state = AppStateScope.of(context);

    state.blockContact(widget.contactName);
    state.addAlert(AlertEvent(
      type: AlertType.contactRequest,
      message: 'Contact blocked after flagged message: ${widget.contactName}',
    ));

    setState(() {
      msg.isHidden = true;
      feedback = '${widget.contactName} has been blocked.';
    });
  }

  void _startStallTimer() {
  _stallTimer?.cancel();

  _stallTimer = Timer(const Duration(seconds: 8), () {
    if (!mounted) return;
    _showStallRescue();
  });
  }
  
void _sendMessageNow(String text, {bool flagged = false}) {
  final state = AppStateScope.of(context);
_stallTimer?.cancel();
  
  state.recordPositiveMessage();
  state.addFriendshipPoints(widget.contactName, 2);

  setState(() {
    feedback = null;
    messages.insert(
      0,
      _Msg(
        fromMe: true,
        text: text,
        isFlagged: flagged,
      ),
    );
  });

  controller.clear();

  Future.delayed(const Duration(milliseconds: 650), () {
    if (!mounted) return;

    _stallCounter++;

    setState(() {
      messages.insert(
        0,
        _Msg(
          fromMe: false,
          text: flagged ? 'This message may be unkind.' : 'Nice! 😄',
          isFlagged: flagged,
        ),
      );
    });

    _startStallTimer();
  });

    if (_stallCounter >= 3) {
      _showStallRescue();
      _stallCounter = 0;
    }
  });
}
  
  void _send() async {
    final state = AppStateScope.of(context);
    final text = controller.text.trim();
    if (text.isEmpty) return;

    if (state.isQuietNow()) {
      setState(() {
        feedback = "Quiet Hours are on — we’ll chat again later 🌙";
      });
      controller.clear();

      if (state.alertsQuietHours) {
        state.recordQuietHoursAttempt();
        state.addAlert(AlertEvent(
          type: AlertType.quietHours,
          message:
              'Message attempt during Quiet Hours (to ${widget.contactName}).',
        ));
      }
      return;
    }

    final safety = state.checkMessageSafety(text);

    if (safety.level == SafetyLevel.block) {
      setState(() {
        feedback = safety.reason ?? "That word isn’t allowed on Natter.";
      });
      controller.clear();

      if (state.alertsBlockedWord) {
        state.recordBlockedAttempt();
        state.addAlert(AlertEvent(
          type: AlertType.blockedWord,
          message: 'Blocked-word attempt in chat with ${widget.contactName}.',
        ));
      }
      return;
    }

    if (safety.level == SafetyLevel.coach) {
      if (state.alertsSafetyCoach) {
        state.recordCoachPrompt();
        state.addAlert(AlertEvent(
          type: AlertType.safetyCoach,
          message:
              'Kindness coach triggered in chat with ${widget.contactName}.',
        ));
      }

      final sendAnyway = await _showSafetyCoachDialog(
        suggestion: safety.suggestion ?? 'Can we try that again kindly?',
        reason: safety.reason ?? 'That message could hurt someone’s feelings.',
      );

      if (!mounted) return;

      if (sendAnyway) {
  if (state.alertsSafetyCoach) {
    state.addAlert(AlertEvent(
      type: AlertType.safetyCoach,
      message:
          'A coached message was sent anyway to ${widget.contactName}.',
    ));

    state.addAlert(AlertEvent(
      type: AlertType.safetyCoach,
      message:
          '${widget.contactName} received a potentially unkind message.',
    ));
  }

  _sendMessageNow(text, flagged: true);
} else {
  state.recordKindRewrite();
  state.addFriendshipPoints(widget.contactName, 3);
  setState(() {
    feedback = 'Nice pause. Try rewriting your message kindly 💛';
  });
      }
      return;
    }

    _sendMessageNow(text);
  }

  @override
  void dispose() {
    _stallTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final ap = t.period == DayPeriod.am ? 'am' : 'pm';
    return '$h:$m$ap';
  }

  String? _kindnessStreakMessage(AppState state) {
    if (state.kindnessStreak >= 10) {
      return '🚀 Kindness Rocket! ${state.kindnessStreak} kind messages in a row';
    }
    if (state.kindnessStreak >= 5) {
      return '💛 Heart Starter! ${state.kindnessStreak} kind messages in a row';
    }
    if (state.kindnessStreak >= 3) {
      return '🔥 Kindness Streak: ${state.kindnessStreak}';
    }
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final quiet = state.isQuietNow();

    return BrandScaffold(
      appBar: AppBar(
        title: BrandedAppBarTitle(title: widget.contactName),
      ),
      child: Column(
        children: [
          if (quiet)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Quiet Hours are ON (${_formatTime(state.quietStart)}–${_formatTime(state.quietEnd)})',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (feedback != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                border: Border.all(color: NatterBrand.yellow, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                feedback!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          if (_kindnessStreakMessage(state) != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NatterBrand.yellow.withOpacity(0.14),
                border: Border.all(
                  color: NatterBrand.yellow.withOpacity(0.55),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: NatterBrand.yellow.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                _kindnessStreakMessage(state)!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(14),
              itemCount: messages.length,
              itemBuilder: (_, i) => _Bubble(
  msg: messages[i],
  onTap: () => _pickReaction(i),
  onReveal: () => _revealFlaggedMessage(messages[i]),
  onHide: () => _hideFlaggedMessage(messages[i]),
  onBlock: () => _blockAfterFlaggedMessage(messages[i]),
),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
  children: [
    IconButton(
      icon: const Icon(
        Icons.lightbulb_outline,
        color: NatterBrand.yellow,
      ),
      onPressed: _pickStarter,
      tooltip: "Conversation Starter",
    ),
    Expanded(
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          hintText: 'Type a message',
        ),
        onSubmitted: (_) => _send(),
      ),
    ),
    const SizedBox(width: 10),
    ElevatedButton(
      onPressed: _send,
      style: ElevatedButton.styleFrom(
        backgroundColor: NatterBrand.green,
        foregroundColor: Colors.black,
      ),
      child: const Text('Send'),
    ),
  ],
),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final bool fromMe;
  final String text;
  String? reaction;
  bool isFlagged;
  bool isRevealed;
  bool isHidden;

  _Msg({
    required this.fromMe,
    required this.text,
    this.reaction,
    this.isFlagged = false,
    this.isRevealed = false,
    this.isHidden = false,
  });
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  final VoidCallback? onTap;
  final VoidCallback? onReveal;
  final VoidCallback? onHide;
  final VoidCallback? onBlock;

  const _Bubble({
    required this.msg,
    this.onTap,
    this.onReveal,
    this.onHide,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final align =
        msg.fromMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = msg.fromMe
        ? NatterBrand.blue.withOpacity(0.95)
        : Colors.white.withOpacity(0.20);

    if (msg.isHidden) {
      return const SizedBox.shrink();
    }

    final showProtectedCard =
        !msg.fromMe && msg.isFlagged && !msg.isRevealed;

    return Align(
      alignment: align,
      child: Column(
        crossAxisAlignment:
            msg.fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showProtectedCard)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(14),
              constraints: const BoxConstraints(maxWidth: 520),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: NatterBrand.yellow, width: 1.6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

  Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: NatterBrand.yellow.withOpacity(0.18),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: NatterBrand.yellow.withOpacity(0.6)),
    ),
    child: const Text(
      'Protected delivery',
      style: TextStyle(
        color: NatterBrand.yellow,
        fontWeight: FontWeight.w900,
        fontSize: 12,
        letterSpacing: 0.4,
      ),
    ),
  ),

  const Text(
    'This message might not feel kind.',
  style: TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 16,
  ),
),
const SizedBox(height: 8),
Text(
  'You are in control. Choose what feels best for you.',
  style: TextStyle(
    color: Colors.white.withOpacity(0.85),
    fontWeight: FontWeight.w700,
    height: 1.3,
  ),
),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: onReveal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NatterBrand.yellow,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Read it'),
                      ),
                      OutlinedButton(
                        onPressed: onHide,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.24),
                          ),
                        ),
                        child: const Text(
                          'Not now',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: onBlock,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.24),
                          ),
                        ),
                        child: const Text(
                          'Block contact',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: msg.fromMe ? null : onTap,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: msg.isFlagged
                        ? NatterBrand.yellow.withOpacity(0.9)
                        : Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.isFlagged && !msg.fromMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Flagged message',
                          style: TextStyle(
                            color: NatterBrand.yellow.withOpacity(0.95),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Text(
                      msg.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (msg.reaction != null && !showProtectedCard)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Text(
                  msg.reaction!,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BadgeCard extends StatelessWidget {
  final String name;
  final NatterBadge badge;

  const BadgeCard({
    super.key,
    required this.name,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: badge.color.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: badge.color.withOpacity(0.20),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: badge.color.withOpacity(0.70)),
            ),
            child: Icon(badge.icon, color: badge.color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description.isEmpty
                      ? 'Awarded to $name'
                      : badge.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.80),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeaceIndicatorCard extends StatelessWidget {
  final AppState state;

  const _PeaceIndicatorCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: state.peaceColor.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: state.peaceColor.withOpacity(0.7),
                width: 3,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.favorite_rounded,
                color: state.peaceColor,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Parent Peace',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.peaceStatus,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: state.peaceColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A quick view of how things are going.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.84),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _KindnessScoreCard extends StatelessWidget {
  final AppState state;

  const _KindnessScoreCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kindness Score',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                state.kindnessScore.toString(),
                style: const TextStyle(
                  color: NatterBrand.yellow,
                  fontWeight: FontWeight.w900,
                  fontSize: 42,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  '/100',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: state.kindnessScore / 100,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.14),
              valueColor: AlwaysStoppedAnimation<Color>(
                state.kindnessScore >= 80
                    ? NatterBrand.green
                    : state.kindnessScore >= 50
                        ? NatterBrand.yellow
                        : NatterBrand.pink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Built from kindness rewrites, streaks, and safety events.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.84),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final hasRite = state.lastName != null &&
        state.lastPromises.isNotEmpty &&
        state.lastBadge != null;

    return BrandScaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Parent Controls'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => state.clearAlerts(),
            child: const Text(
              'Clear Alerts',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PeaceIndicatorCard(state: state),
          const SizedBox(height: 14),
          _KindnessScoreCard(state: state),
          const SizedBox(height: 14),
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'At a glance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatTile(
                      label: 'Approved',
                      value: state.approvedContacts.length.toString(),
                    ),
                    _StatTile(
                      label: 'Pending',
                      value: state.pendingRequests.length.toString(),
                    ),
                    _StatTile(
                      label: 'Quiet Hours',
                      value: state.quietHoursEnabled ? 'ON' : 'OFF',
                    ),
                    _StatTile(
                      label: 'Alerts',
                      value: state.alerts.length.toString(),
                    ),
                    _StatTile(
                      label: 'Level',
                      value: state.currentLevel.title,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (hasRite) ...[
            BrandCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rite of Passage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${state.lastName} earned:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  BadgeCard(
                    name: state.lastName!,
                    badge: state.lastBadge!,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Promises:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: state.lastPromises
                        .map(
                          (p) => Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: Text(
                              p,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Controls',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    calmRoute(const ParentContactsScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NatterBrand.green,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    'Contacts (${state.pendingRequests.length} pending)',
                  ),
                                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    calmRoute(const ParentRulesScreen()),
                  ),
                  child: const Text('Rules & Alerts'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Current level: ${state.currentLevel.title}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kind rewrites: ${state.kindnessRewrites}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kindness streak: ${state.kindnessStreak}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kindness stars: ${state.kindnessStars}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          BrandCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
  children: [
    Icon(
      Icons.favorite_rounded,
      color: NatterBrand.yellow,
      size: 22,
    ),
    SizedBox(width: 8),
    Text(
      'Parent Peace Dashboard',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 18,
      ),
    ),
  ],
),
      const SizedBox(height: 12),

      _StatTile(
        label: "Positive messages",
        value: state.positiveMessages.toString(),
      ),

      _StatTile(
        label: "Kindness rewrites",
        value: state.kindnessRewrites.toString(),
      ),

      _StatTile(
        label: "Blocked attempts",
        value: state.blockedAttempts.toString(),
      ),

      _StatTile(
        label: "Quiet Hours attempts",
        value: state.quietHoursAttempts.toString(),
      ),

      _StatTile(
        label: "Coach prompts",
        value: state.coachPrompts.toString(),
      ),
    ],
  ),
),
          const SizedBox(height: 14),
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
  children: [
    Icon(
      Icons.timeline_rounded,
      color: NatterBrand.yellow,
      size: 22,
    ),
    SizedBox(width: 8),
    Text(
      'Recent Activity (no message reading)',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    ),
  ],
),
                const SizedBox(height: 10),
                if (state.alerts.isEmpty)
                  Text(
                    'No recent concerns right now.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  ...state.alerts.take(6).map((a) => _AlertRow(event: a)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
  value,
  style: const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 24,
    height: 1.0,
  ),
),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final AlertEvent event;
  const _AlertRow({required this.event});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (event.type) {
      case AlertType.blockedWord:
        icon = Icons.block_rounded;
        color = NatterBrand.yellow;
        break;
      case AlertType.quietHours:
        icon = Icons.nights_stay_rounded;
        color = Colors.white;
        break;
      case AlertType.contactRequest:
        icon = Icons.person_add_alt_1_rounded;
        color = NatterBrand.green;
        break;
      case AlertType.safetyCoach:
        icon = Icons.favorite_rounded;
        color = NatterBrand.pink;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.45)),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                event.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParentContactsScreen extends StatelessWidget {
  const ParentContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return BrandScaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Contacts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pending requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                if (state.pendingRequests.isEmpty)
                  Text(
                    'None right now.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  ...state.pendingRequests.map((name) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.16),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  NatterBrand.yellow.withOpacity(0.35),
                              child: Text(
                                name.substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                state.approveContact(name);
                                if (state.alertsContactRequest) {
                                  state.addAlert(AlertEvent(
                                    type: AlertType.contactRequest,
                                    message: 'Approved contact: $name',
                                  ));
                                }
                              },
                              child: const Text(
                                'Approve',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                state.blockContact(name);
                                if (state.alertsContactRequest) {
                                  state.addAlert(AlertEvent(
                                    type: AlertType.contactRequest,
                                    message: 'Blocked contact request: $name',
                                  ));
                                }
                              },
                              child: const Text(
                                'Block',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Approved contacts',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: state.approvedContacts
    .map(
      (friend) => Container(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withOpacity(0.16),
          ),
        ),
        child: Text(
          friend.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    )
    .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ParentRulesScreen extends StatelessWidget {
  const ParentRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return BrandScaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Rules & Alerts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quiet Hours',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: state.quietHoursEnabled,
                  onChanged: state.setQuietEnabled,
                  title: const Text(
                    'Enable Quiet Hours',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'Kids can’t send messages during this time.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _TimeButton(
                        label: 'Start',
                        time: state.quietStart,
                        onPick: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: state.quietStart,
                          );
                          if (picked != null) state.setQuietStart(picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TimeButton(
                        label: 'End',
                        time: state.quietEnd,
                        onPick: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: state.quietEnd,
                          );
                          if (picked != null) state.setQuietEnd(picked);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: state.alertsBlockedWord,
                  onChanged: (v) => state.setAlerts(blockedWord: v),
                  title: const Text(
                    'Blocked-word attempts',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'Parents get an alert when a message is blocked.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                ),
                SwitchListTile(
                  value: state.alertsQuietHours,
                  onChanged: (v) => state.setAlerts(quietHours: v),
                  title: const Text(
                    'Quiet Hours attempts',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'Parents get an alert if kids try to message during Quiet Hours.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                ),
                SwitchListTile(
                  value: state.alertsContactRequest,
                  onChanged: (v) => state.setAlerts(contactRequest: v),
                  title: const Text(
                    'Contact events',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'Alerts when a request is made, approved, or blocked.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                ),
                SwitchListTile(
                  value: state.alertsSafetyCoach,
                  onChanged: (v) => state.setAlerts(safetyCoach: v),
                  title: const Text(
                    'Kindness coach prompts',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'Parents get a signal when Natter coaches a message, without seeing the message itself.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onPick;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final ap = time.period == DayPeriod.am ? 'am' : 'pm';
    final txt = '$h:$m$ap';

    return OutlinedButton(
      onPressed: onPick,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withOpacity(0.22)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            txt,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
       
