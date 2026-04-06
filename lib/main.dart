import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<User> ensureSignedIn() async {
  final auth = FirebaseAuth.instance;
  final current = auth.currentUser;
  if (current != null) return current;

  final cred = await auth.signInAnonymously();
  return cred.user!;
}

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options:
DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NatterApp());
}

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

class FriendProfile {
  final String name;
  final String code;

  const FriendProfile(this.name, this.code);
}

class FriendDirectory {
  static const List<FriendProfile> profiles = [
    FriendProfile('Ava', 'AVA-4821'),
    FriendProfile('Leo', 'LEO-7314'),
    FriendProfile('Zoe', 'ZOE-1942'),
    FriendProfile('Max', 'MAX-5508'),
  ];

  static String? nameForCode(String code) {
    try {
      return profiles
          .firstWhere((p) => p.code == code.trim().toUpperCase())
          .name;
    } catch (_) {
      return null;
    }
  }
}

class Friend {
  final String name;
  final String schoolName;
  final String yearGroup;

  int friendshipPoints;

  String activeQuestTitle;
  int activeQuestProgress;
  int activeQuestTarget;
  int activeQuestReward;

  DateTime? lastQuestCelebratedAt;

  List<String> friendshipMoments = [];

  Friend({
    required this.name,
    this.schoolName = 'North Borough Junior School',
    this.yearGroup = 'Year 4',
    this.friendshipPoints = 0,
    this.activeQuestTitle = '',
    this.activeQuestProgress = 0,
    this.activeQuestTarget = 3,
    this.activeQuestReward = 15,
  });

  void ensureQuestTitle() {
  if (activeQuestTitle.isEmpty) {
    activeQuestTitle = 'Send 3 kind messages to $name';
  }
  }

  int get level {
    if (friendshipPoints >= 100) return 5;
    if (friendshipPoints >= 50) return 4;
    if (friendshipPoints >= 25) return 3;
    if (friendshipPoints >= 10) return 2;
    return 1;
  }

  String get stars => '⭐' * level;

  String get friendshipStage {
  if (friendshipPoints >= 100) return '🌟 Legendary Friendship';
  if (friendshipPoints >= 50) return '🌳 Strong Friendship';
  if (friendshipPoints >= 10) return '🌿 Growing Friendship';
  return '🌱 New Friendship';
  }

  double get meterPercent {
    final currentLevel = level;

    if (currentLevel == 5) return 1.0;

    int levelStart;
    int levelEnd;

    switch (currentLevel) {
      case 1:
        levelStart = 0;
        levelEnd = 10;
        break;
      case 2:
        levelStart = 10;
        levelEnd = 25;
        break;
      case 3:
        levelStart = 25;
        levelEnd = 50;
        break;
      case 4:
        levelStart = 50;
        levelEnd = 100;
        break;
      default:
        levelStart = 0;
        levelEnd = 100;
    }

    return ((friendshipPoints - levelStart) / (levelEnd - levelStart))
        .clamp(0.0, 1.0);
  }
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

class ChildSession {
  final String parentId;
  final String childId;
  final String childName;
  final String childAvatar;

  const ChildSession({
    required this.parentId,
    required this.childId,
    required this.childName,
    required this.childAvatar,
  });

  ChildSession copyWith({
    String? parentId,
    String? childId,
    String? childName,
    String? childAvatar,
  }) {
    return ChildSession(
      parentId: parentId ?? this.parentId,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      childAvatar: childAvatar ?? this.childAvatar,
    );
  }

  Map<String, String> toPrefsMap() {
    return {
      'device_mode': 'child',
      'child_parent_id': parentId,
      'child_id': childId,
      'child_name': childName,
      'child_avatar': childAvatar,
    };
  }

  static ChildSession? fromPrefs(SharedPreferences prefs) {
    final mode = prefs.getString('device_mode');
    if (mode != 'child') return null;

    final parentId = prefs.getString('child_parent_id');
    final childId = prefs.getString('child_id');
    final childName = prefs.getString('child_name');
    final childAvatar = prefs.getString('child_avatar') ?? 'owl';

    if (parentId == null || childId == null || childName == null) {
      return null;
    }

    return ChildSession(
      parentId: parentId,
      childId: childId,
      childName: childName,
      childAvatar: childAvatar,
    );
  }
}

class ChildContactRequest {
  final String id;
  final String name;
  final String status;
  final String targetParentId;
  final String targetChildId;
  final String targetFriendCode;

  final String requesterParentId;
  final String requesterChildId;
  final String requesterFriendCode;
  final String requesterName;

  const ChildContactRequest({
    required this.id,
    required this.name,
    required this.status,
    required this.targetParentId,
    required this.targetChildId,
    required this.targetFriendCode,
    required this.requesterParentId,
    required this.requesterChildId,
    required this.requesterFriendCode,
    required this.requesterName,
  });

  factory ChildContactRequest.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return ChildContactRequest(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      targetParentId: (data['targetParentId'] ?? '').toString(),
      targetChildId: (data['targetChildId'] ?? '').toString(),
      targetFriendCode: (data['targetFriendCode'] ?? '').toString(),
      requesterParentId: (data['requesterParentId'] ?? '').toString(),
      requesterChildId: (data['requesterChildId'] ?? '').toString(),
      requesterFriendCode: (data['requesterFriendCode'] ?? '').toString(),
      requesterName: (data['requesterName'] ?? '').toString(),
    );
  }
}

class ParentChildProfile {
  final String childId;
  final String name;
  final String avatar;
  final String accessCode;
  final bool linkedDevice;

  const ParentChildProfile({
    required this.childId,
    required this.name,
    required this.avatar,
    required this.accessCode,
    required this.linkedDevice,
  });

  factory ParentChildProfile.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return ParentChildProfile(
      childId: doc.id,
      name: (data['name'] ?? '').toString(),
      avatar: (data['avatar'] ?? 'owl').toString(),
      accessCode: (data['accessCode'] ?? '').toString(),
      linkedDevice: data['linkedDevice'] == true,
    );
  }
}

class ApprovedChildContact {
  final String id;
  final String name;
  final String friendCode;
  final String targetParentId;
  final String targetChildId;
  final bool isNew;

  const ApprovedChildContact({
    required this.id,
    required this.name,
    required this.friendCode,
    required this.targetParentId,
    required this.targetChildId,
    required this.isNew,
  });

  factory ApprovedChildContact.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return ApprovedChildContact(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      friendCode: (data['friendCode'] ?? '').toString(),
      targetParentId: (data['targetParentId'] ?? '').toString(),
      targetChildId: (data['targetChildId'] ?? '').toString(),
      isNew: data['isNew'] == true,
    );
  }
}

class AppState extends ChangeNotifier {
  String? activeChildFriendCode;
  final List<Friend> approvedContacts = [
    Friend(name: 'Dad', friendshipPoints: 40)
  ..friendshipMoments.add('⭐ You became friends'),
    Friend(name: 'Sam', friendshipPoints: 18)
  ..friendshipMoments.add('⭐ You became friends'),
    Friend(name: 'Mia', friendshipPoints: 8)
  ..friendshipMoments.add('⭐ You became friends'),
  ];
  final List<String> pendingRequests = ['Ava', 'Leo'];
  
  List<Friend> get sameSchoolFriends {
  return approvedContacts
      .where((f) => f.schoolName == schoolName)
      .toList();
}

String get myFriendCode => activeChildFriendCode ?? 'NAT-0000';

  ChildSession? _childSession;

  ChildSession? get childSession => _childSession;

  bool get hasActiveChildSession => _childSession != null;

  bool get isChildDeviceMode => _childSession != null;

  String? get activeChildId => _childSession?.childId;
  String? get activeParentId => _childSession?.parentId;
  String? get activeChildName => _childSession?.childName;
  String? get activeChildAvatar => _childSession?.childAvatar;

  String get effectiveChildName =>
      _childSession?.childName.trim().isNotEmpty == true
          ? _childSession!.childName
          : (lastName?.trim().isNotEmpty == true ? lastName! : 'Friend');

  String get effectiveChildAvatar =>
      _childSession?.childAvatar.trim().isNotEmpty == true
          ? _childSession!.childAvatar
          : 'owl';

String generateChildFriendCode(String childName) {
  final cleaned = childName
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z]'), '');

  final prefix = cleaned.isEmpty
      ? 'NAT'
      : cleaned.length >= 3
          ? cleaned.substring(0, 3)
          : cleaned.padRight(3, 'X');

  final random = Random();
  final number = 1000 + random.nextInt(9000);

  return '$prefix-$number';
}

String generateChildAccessCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random();

  return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
}

Future<Map<String, String>?> findChildByAccessCode(String rawCode) async {
  final code = rawCode.trim().toUpperCase();
  if (code.isEmpty) return null;

  final lookupDoc = await FirebaseFirestore.instance
      .collection('child_access_codes')
      .doc(code)
      .get();

  if (!lookupDoc.exists) return null;

  final data = lookupDoc.data()!;

  return {
    'parentId': (data['parentId'] ?? '').toString(),
    'childId': (data['childId'] ?? '').toString(),
    'childName': (data['childName'] ?? '').toString(),
    'avatar': (data['avatar'] ?? 'owl').toString(),
    'friendCode': (data['friendCode'] ?? '').toString(),
  };
}

Future<Map<String, String>?> findChildByFriendCode(String rawCode) async {
  final code = rawCode.trim().toUpperCase();
  if (code.isEmpty) return null;

  final doc = await FirebaseFirestore.instance
      .collection('child_friend_codes')
      .doc(code)
      .get();

  if (!doc.exists) return null;

  final data = doc.data()!;
  return {
    'parentId': (data['parentId'] ?? '').toString(),
    'childId': (data['childId'] ?? '').toString(),
    'name': (data['childName'] ?? '').toString(),
    'friendCode': (data['friendCode'] ?? '').toString(),
  };
}

Stream<List<ParentChildProfile>> parentChildrenStream() async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield [];
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('parents')
      .doc(user.uid)
      .collection('children')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => ParentChildProfile.fromDoc(doc))
            .toList(),
      );
}

CollectionReference<Map<String, dynamic>> parentChildContactRequestsRef({
  required String parentId,
  required String childId,
}) {
  return FirebaseFirestore.instance
      .collection('parents')
      .doc(parentId)
      .collection('children')
      .doc(childId)
      .collection('contact_requests');
}

Stream<List<ChildContactRequest>> childContactRequestsStream({
  required String parentId,
  required String childId,
  String? status,
}) async* {
  Query<Map<String, dynamic>> query = parentChildContactRequestsRef(
    parentId: parentId,
    childId: childId,
  ).orderBy('createdAt', descending: true);

  if (status != null) {
    query = query.where('status', isEqualTo: status);
  }

  yield* query.snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => ChildContactRequest.fromDoc(doc))
            .toList(),
      );
}

Stream<List<ChildContactRequest>> activeChildContactRequestsStream({
  String? status,
}) async* {
  if (!hasActiveChildSession) {
    yield [];
    return;
  }

  yield* childContactRequestsStream(
    parentId: activeParentId!,
    childId: activeChildId!,
    status: status,
  );
}

CollectionReference<Map<String, dynamic>> parentChildApprovedContactsRef({
  required String parentId,
  required String childId,
}) {
  return FirebaseFirestore.instance
      .collection('parents')
      .doc(parentId)
      .collection('children')
      .doc(childId)
      .collection('approved_contacts');
}

CollectionReference<Map<String, dynamic>> activeChildApprovedContactsRef() {
  if (!hasActiveChildSession) {
    throw Exception('No active child session found.');
  }

  return parentChildApprovedContactsRef(
    parentId: activeParentId!,
    childId: activeChildId!,
  );
}

Stream<List<ApprovedChildContact>> activeChildApprovedContactsStream() async* {
  if (!hasActiveChildSession) {
    yield [];
    return;
  }

  yield* activeChildApprovedContactsRef()
      .orderBy('approvedAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => ApprovedChildContact.fromDoc(doc))
            .toList(),
      );
}

Future<void> markApprovedContactAsSeen(String contactId) async {
  if (!hasActiveChildSession) return;

  await activeChildApprovedContactsRef().doc(contactId).set({
    'isNew': false,
  }, SetOptions(merge: true));
}

Future<void> saveChildOnboardingState() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('has_seen_chirp_welcome', hasSeenChirpWelcome);
  await prefs.setBool('has_sent_first_message', hasSentFirstMessage);
  await prefs.setBool('has_seen_first_reply', hasSeenFirstReply);
  await prefs.setBool('has_seen_add_friend_prompt', hasSeenAddFriendPrompt);
  await prefs.setBool('has_seen_add_friend_success', hasSeenAddFriendSuccess);
  await prefs.setInt('onboarding_step', onboardingStep);
}

Future<void> hydrateChildOnboardingState() async {
  final prefs = await SharedPreferences.getInstance();
  hasSeenChirpWelcome = prefs.getBool('has_seen_chirp_welcome') ?? false;
  hasSentFirstMessage = prefs.getBool('has_sent_first_message') ?? false;
  hasSeenFirstReply = prefs.getBool('has_seen_first_reply') ?? false;
  hasSeenAddFriendPrompt = prefs.getBool('has_seen_add_friend_prompt') ?? false;
  hasSeenAddFriendSuccess = prefs.getBool('has_seen_add_friend_success') ?? false;
  onboardingStep = prefs.getInt('onboarding_step') ?? 0;
}

Future<void> clearChildOnboardingState() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('has_seen_chirp_welcome');
  await prefs.remove('has_sent_first_message');
  await prefs.remove('has_seen_first_reply');
  await prefs.remove('has_seen_add_friend_prompt');
  await prefs.remove('has_seen_add_friend_success');
  await prefs.remove('onboarding_step');

  hasSeenChirpWelcome = false;
  hasSentFirstMessage = false;
  hasSeenFirstReply = false;
  hasSeenAddFriendPrompt = false;
  hasSeenAddFriendSuccess = false;
  onboardingStep = 0;
}

Future<void> rememberChildDevice({
  required String parentId,
  required String childId,
  required String childName,
  required String childAvatar,
  required String childFriendCode,
}) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString('device_mode', 'child');

  final session = ChildSession(
    parentId: parentId,
    childId: childId,
    childName: childName,
    childAvatar: childAvatar,
  );

  final map = session.toPrefsMap();
  for (final entry in map.entries) {
    await prefs.setString(entry.key, entry.value);
  }

  await prefs.setString('child_friend_code', childFriendCode);

  _childSession = session;
  activeChildFriendCode = childFriendCode;
  notifyListeners();
}

Future<void> hydrateRememberedChildSession() async {
  final prefs = await SharedPreferences.getInstance();
  _childSession = ChildSession.fromPrefs(prefs);
  activeChildFriendCode = await getRememberedChildFriendCode();
  await hydrateChildOnboardingState();
  notifyListeners();
}

Future<void> clearChildSession() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove('device_mode');
  await prefs.remove('child_parent_id');
  await prefs.remove('child_id');
  await prefs.remove('child_name');
  await prefs.remove('child_avatar');
  await prefs.remove('child_friend_code');

  _childSession = null;
  activeChildFriendCode = null;
  await clearChildOnboardingState();
  notifyListeners();
}

Future<ChildSession?> getRememberedChildSession() async {
  final prefs = await SharedPreferences.getInstance();
  return ChildSession.fromPrefs(prefs);
}

Future<void> unlinkActiveChildDevice() async {
  if (!hasActiveChildSession) {
    throw Exception('No active child session found.');
  }

  await FirebaseFirestore.instance
      .collection('parents')
      .doc(activeParentId!)
      .collection('children')
      .doc(activeChildId!)
      .set({
    'linkedDevice': false,
    'linkedAuthUid': null,
  }, SetOptions(merge: true));
}

Future<void> rememberParentDevice() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('device_mode', 'parent');
}

Future<String?> getDeviceMode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('device_mode');
}

Future<String?> getRememberedChildName() async {
  final session = await getRememberedChildSession();
  return session?.childName;
}

Future<String?> getRememberedChildId() async {
  final session = await getRememberedChildSession();
  return session?.childId;
}

Future<String?> getRememberedParentId() async {
  final session = await getRememberedChildSession();
  return session?.parentId;
}

Future<String?> getRememberedChildAvatar() async {
  final session = await getRememberedChildSession();
  return session?.childAvatar;
}

Future<void> clearRememberedDeviceMode() async {
  await clearChildSession();
}

Future<String?> getRememberedChildFriendCode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('child_friend_code');
}

  String? lastQuestCelebrationFriend;
  String? lastQuestCelebrationTitle;

  List<String> get digitalReadinessStrengths {
  final strengths = <String>[];

  if (positiveMessages >= 10) {
    strengths.add('💛 Kind communication');
  }
  if (kindnessRewrites >= 3) {
    strengths.add('🌱 Thoughtful message choices');
  }
  if (completedSharedQuests >= 3) {
    strengths.add('🤝 Friendship building');
  }
  if (conversationStartersUsed >= 3) {
    strengths.add('💬 Confident conversation');
  }
  if (alertsBlockedWord) {
    strengths.add('🛡 Safe communication support');
  }

  if (strengths.isEmpty) {
    strengths.add('🌟 Early digital confidence');
  }

  return strengths;
  }

List<Friend> get sameYearFriends {
  return approvedContacts
      .where((f) =>
          f.schoolName == schoolName &&
          f.yearGroup == yearGroup)
      .toList();
}

  List<String> get suggestedFriendNames {
  return FriendDirectory.profiles
      .map((profile) => profile.name)
      .where((name) =>
          !isApproved(name) &&
          !isPending(name))
      .take(3)
      .toList();
  }

  final List<String> dailySparks = [
  "Ask someone what made them smile today 😊",
  "Send a kind message to a friend 💛",
  "Tell someone something you appreciate about them 🌟",
  "Check in on a friend you haven’t spoken to today 👋",
  "Say thank you to someone 🙏",
];

String get todaySpark {
  final index = DateTime.now().day % dailySparks.length;
  return dailySparks[index];
}
  
  String schoolName = "North Borough Junior School";
String yearGroup = "Year 4";

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

  bool isGraduated = false;
  bool readyForGraduation = false;

  bool hasSeenChirpWelcome = false;
  bool hasSentFirstMessage = false;
  bool hasSeenFirstReply = false;
  bool hasSeenAddFriendPrompt = false;
  bool hasSeenAddFriendSuccess = false;

  bool hasSeenParentOnboarding = false;

  int onboardingStep = 0;
// 0 = brand new
// 1 = sent first message
// 2 = saw first reply
// 3 = saw add-friend prompt
// 4 = sent first friend request

  bool get isInOnboarding => onboardingStep < 4;
  
  int conversationStartersUsed = 0;
  int completedSharedQuests = 0;
  
  DateTime? digitalCitizenUnlockedAt;

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

  bool get canRequestFriends => true;

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

  void progressFriendQuest(String name, {int amount = 1}) {
  final friend = getFriendByName(name);
  if (friend == null) return;

  friend.ensureQuestTitle();

  if (friend.activeQuestProgress >= friend.activeQuestTarget) return;

  friend.activeQuestProgress += amount;

  if (friend.activeQuestProgress >= friend.activeQuestTarget) {
    friend.activeQuestProgress = friend.activeQuestTarget;
    lastQuestCelebrationFriend = friend.name;
    lastQuestCelebrationTitle = friend.activeQuestTitle;

    addFriendshipPoints(name, friend.activeQuestReward);
    completedSharedQuests += 1;

    friend.friendshipMoments.add('🏆 You completed a quest together');

    final now = DateTime.now();

    final shouldCelebrate =
        friend.lastQuestCelebratedAt == null ||
        now.difference(friend.lastQuestCelebratedAt!).inSeconds > 30;

    if (shouldCelebrate) {
      addFriendshipMoment(
        title: 'Quest Complete!',
        description: '🌟 You completed a shared quest with ${friend.name}.',
        icon: Icons.task_alt_rounded,
        celebrate: friend.friendshipPoints >= 25,
      );

      friend.lastQuestCelebratedAt = now;
    }

    if (friend.activeQuestTitle.contains('Send')) {
      friend.activeQuestTitle =
          'Use 2 conversation starters with ${friend.name}';
      friend.activeQuestProgress = 0;
      friend.activeQuestTarget = 2;
      friend.activeQuestReward = 10;
    } else {
      friend.activeQuestTitle =
          'Send 3 kind messages to ${friend.name}';
      friend.activeQuestProgress = 0;
      friend.activeQuestTarget = 3;
      friend.activeQuestReward = 10;
    }
  }

  evaluateGraduationReadiness();
  notifyListeners();
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

Future<void> requestContact({
  required String targetName,
  required String targetParentId,
  required String targetChildId,
  required String targetFriendCode,
}) async {
  final trimmed = targetName.trim();
  if (trimmed.isEmpty) return;
  if (isApproved(trimmed) || isPending(trimmed)) return;

  pendingRequests.insert(0, trimmed);
  weeklyFriendRequests += 1;

  if (hasActiveChildSession) {
    await parentChildContactRequestsRef(
      parentId: targetParentId,
      childId: targetChildId,
    ).add({
      'name': effectiveChildName,
      'status': 'pending',

      'targetParentId': targetParentId,
      'targetChildId': targetChildId,
      'targetFriendCode': targetFriendCode,

      'requesterParentId': activeParentId,
      'requesterChildId': activeChildId,
      'requesterFriendCode': myFriendCode,
      'requesterName': effectiveChildName,

      'createdAt': FieldValue.serverTimestamp(),
    });
  }

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

Future<void> approveContactForChild({
  required String parentId,
  required String childId,
  required ChildContactRequest request,
}) async {
  await parentChildContactRequestsRef(
    parentId: parentId,
    childId: childId,
  ).doc(request.id).set({
    'name': request.name,
    'status': 'approved',
    'targetParentId': request.targetParentId,
    'targetChildId': request.targetChildId,
    'targetFriendCode': request.targetFriendCode,
    'requesterParentId': request.requesterParentId,
    'requesterChildId': request.requesterChildId,
    'requesterFriendCode': request.requesterFriendCode,
    'requesterName': request.requesterName,
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  final approvedChildDoc = await FirebaseFirestore.instance
      .collection('parents')
      .doc(parentId)
      .collection('children')
      .doc(childId)
      .get();

  final approvedChildData = approvedChildDoc.data() ?? {};
  final approvedChildName = (approvedChildData['name'] ?? '').toString();
  final approvedChildFriendCode =
      (approvedChildData['friendCode'] ?? '').toString();

  await parentChildApprovedContactsRef(
    parentId: parentId,
    childId: childId,
  ).doc(request.requesterChildId).set({
    'name': request.requesterName,
    'friendCode': request.requesterFriendCode,
    'targetParentId': request.requesterParentId,
    'targetChildId': request.requesterChildId,
    'approvedAt': FieldValue.serverTimestamp(),
    'isNew': true,
  }, SetOptions(merge: true));

  await parentChildApprovedContactsRef(
    parentId: request.requesterParentId,
    childId: request.requesterChildId,
  ).doc(childId).set({
    'name': approvedChildName,
    'friendCode': approvedChildFriendCode,
    'targetParentId': parentId,
    'targetChildId': childId,
    'approvedAt': FieldValue.serverTimestamp(),
    'isNew': true,
  }, SetOptions(merge: true));
}

Future<void> blockContactForChild({
  required String parentId,
  required String childId,
  required ChildContactRequest request,
}) async {
  await parentChildContactRequestsRef(
    parentId: parentId,
    childId: childId,
  ).doc(request.id).set({
    'name': request.name,
    'status': 'blocked',
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
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

  Future<void> recordRite({
  required String name,
  required List<String> promises,
}) async {
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

  approvedContacts.removeWhere((f) => f.name == 'Ava');
  approvedContacts.insert(0, Friend(name: 'Ava', friendshipPoints: 0));

  hasSeenChirpWelcome = false;
  hasSentFirstMessage = false;
  hasSeenFirstReply = false;
  hasSeenAddFriendPrompt = false;
  hasSeenAddFriendSuccess = false;
  onboardingStep = 0;

  final user = await ensureSignedIn();

  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'uid': user.uid,
    'name': name,
    'promises': promises,
    'createdAt': FieldValue.serverTimestamp(),
  });

  notifyListeners();
}

String chatIdForFriend(String friendName) {
  return friendName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

DocumentReference<Map<String, dynamic>> childDocRef() {
  final session = childSession;
  if (session == null) {
    throw Exception('No active child session found.');
  }

  return FirebaseFirestore.instance
      .collection('parents')
      .doc(session.parentId)
      .collection('children')
      .doc(session.childId);
}

CollectionReference<Map<String, dynamic>> childChatsRef() {
  return childDocRef().collection('chats');
}

DocumentReference<Map<String, dynamic>> childChatRef(String friendName) {
  return childChatsRef().doc(chatIdForFriend(friendName));
}

CollectionReference<Map<String, dynamic>> childMessagesRef(String friendName) {
  return childChatRef(friendName).collection('messages');
}

Future<void> revealFlaggedMessage({
  required String friendName,
  required String messageId,
}) async {
  if (!hasActiveChildSession) return;

  await childMessagesRef(friendName).doc(messageId).set({
    'receiverAction': 'read',
    'receiverActionAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<void> hideFlaggedMessage({
  required String friendName,
  required String messageId,
}) async {
  if (!hasActiveChildSession) return;

  await childMessagesRef(friendName).doc(messageId).set({
    'receiverAction': 'not_now',
    'receiverActionAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<void> blockAfterFlaggedMessage({
  required String friendName,
  required String messageId,
}) async {
  if (!hasActiveChildSession) return;

  await childMessagesRef(friendName).doc(messageId).set({
    'receiverAction': 'blocked',
    'receiverActionAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  addAlert(AlertEvent(
    type: AlertType.contactRequest,
    message: 'Contact blocked after flagged message: $friendName',
  ));
}

  Stream<Map<String, dynamic>?> chatSummaryStream(String friendName) async* {
  if (!hasActiveChildSession) {
    yield null;
    return;
  }

  yield* childChatRef(friendName)
      .snapshots()
      .map((doc) => doc.data());
}

Future<String> currentUid() async {
  final user = await ensureSignedIn();
  return user.uid;
}

Stream<List<Map<String, dynamic>>> messageStream(String friendName) async* {
  if (!hasActiveChildSession) {
    yield [];
    return;
  }

  yield* childMessagesRef(friendName)
      .orderBy('createdAt')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList());
}

Future<void> addFakeReply({
  required String friendName,
  required String text,
}) async {
  if (!hasActiveChildSession) return;

  final chatId = chatIdForFriend(friendName);
  final chatRef = childChatRef(friendName);

  await chatRef.set({
    'friendName': friendName,
    'updatedAt': FieldValue.serverTimestamp(),
    'lastMessage': text,
    'lastSenderUid': 'friend_$chatId',
    'childId': activeChildId,
    'parentId': activeParentId,
  }, SetOptions(merge: true));

  await childMessagesRef(friendName).add({
    'text': text,
    'senderUid': 'friend_$chatId',
    'createdAt': FieldValue.serverTimestamp(),
    'isFlagged': false,
  });
}

Future<void> sendMessageToChat({
  required String friendName,
  required String text,
  bool isFlagged = false,
}) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;

  if (!hasActiveChildSession) {
    throw Exception('No active child session found.');
  }

  final chatRef = childChatRef(friendName);

  await chatRef.set({
    'friendName': friendName,
    'updatedAt': FieldValue.serverTimestamp(),
    'lastMessage': trimmed,
    'lastSenderUid': activeChildId,
    'childId': activeChildId,
    'parentId': activeParentId,
  }, SetOptions(merge: true));

  await childMessagesRef(friendName).add({
    'text': trimmed,
    'senderUid': activeChildId,
    'createdAt': FieldValue.serverTimestamp(),
    'isFlagged': isFlagged,
    'receiverAction': isFlagged ? 'protected' : null,
    'receiverActionAt': null,
  });
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

  final didLevelUp = evaluateProgress();

  if (!didLevelUp) {
    evaluateGraduationReadiness();
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

  final didLevelUp = evaluateProgress();

  if (!didLevelUp) {
    evaluateGraduationReadiness();
  }

  notifyListeners();
}

  void ensureFriendQuests() {
  for (final friend in approvedContacts) {
    friend.ensureQuestTitle();
  }
  }

bool evaluateProgress() {
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

  if (currentLevel == NatterLevel.kindCommunicator) {
    if (positiveMessages >= 3 &&
        kindnessRewrites >= 1 &&
        completedSharedQuests >= 1 &&
        conversationStartersUsed >= 1) {
      currentLevel = NatterLevel.digitalCitizen;
      digitalCitizenUnlockedAt = DateTime.now();
      didLevelUp = true;

      Future.delayed(const Duration(seconds: 2), () {
        evaluateGraduationReadiness();
        notifyListeners();
      });

      _awardBadge(
        const NatterBadge(
          title: 'Digital Citizen',
          icon: Icons.shield_rounded,
          color: NatterBrand.yellow,
          description:
              'Unlocked by showing strong digital communication habits.',
        ),
        celebrationTitleText: 'Level Up!',
        celebrationMessageText:
            '🛡 You are now a Digital Citizen.\n\nYou are showing strong online habits.',
      );

      addAlert(AlertEvent(
        type: AlertType.safetyCoach,
        message: 'Level up: Digital Citizen unlocked.',
      ));
    }
  }

  if (didLevelUp) {
    notifyListeners();
  }

  return didLevelUp;
}
  
void recordConversationStarterUse() {
  conversationStartersUsed += 1;
  evaluateGraduationReadiness();
  notifyListeners();
}

void evaluateGraduationReadiness() {
  if (isGraduated) return;

  if (currentLevel == NatterLevel.digitalCitizen &&
    digitalCitizenUnlockedAt != null) {
  final secondsSinceUnlock =
      DateTime.now().difference(digitalCitizenUnlockedAt!).inSeconds;

  if (secondsSinceUnlock < 2) return;
  }

  final hasMetRequirements =
    positiveMessages >= 5 &&
    kindnessRewrites >= 2 &&
    completedSharedQuests >= 2 &&
    conversationStartersUsed >= 2 &&
    currentLevel == NatterLevel.digitalCitizen;

  if (hasMetRequirements && !readyForGraduation) {
    readyForGraduation = true;
    celebrationTitle = 'You’re Ready!';
    celebrationMessage =
        '🎓 You have shown kind communication, strong friendships, and safe online habits.\n\nIt’s time to begin your graduation.';
    notifyListeners();
  }
}

void completeGraduation() {
  if (isGraduated) return;

  isGraduated = true;
  readyForGraduation = false;

  _awardBadge(
    const NatterBadge(
      title: 'Natter Graduate',
      icon: Icons.school_rounded,
      color: NatterBrand.yellow,
      description: 'Awarded for completing the Natter journey.',
    ),
    celebrationTitleText: 'Graduation Complete!',
    celebrationMessageText:
        '🎓 You completed the Natter journey and earned your Graduate badge.',
  );

  addAlert(AlertEvent(
    type: AlertType.safetyCoach,
    message: 'Graduation completed: Natter Graduate unlocked.',
  ));

  notifyListeners();
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

  int coachedMessagesSentAnyway = 0;

  int get kindnessScore {
  int score = 100;

  score -= blockedAttempts * 15;
  score -= coachedMessagesSentAnyway * 10;
  score -= quietHoursAttempts * 5;

  if (score < 0) score = 0;
  if (score > 100) score = 100;

  return score;
  }

  Future<User> signUpParent({
  required String email,
  required String password,
  required String displayName,
}) async {
  final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );

  final user = cred.user!;
  await user.updateDisplayName(displayName.trim());

  await FirebaseFirestore.instance.collection('parents').doc(user.uid).set({
    'email': user.email,
    'displayName': displayName.trim(),
    'createdAt': FieldValue.serverTimestamp(),
    'role': 'parent',
  });

  await rememberParentDevice();

  notifyListeners();
  return user;
}

Future<User> signInParent({
  required String email,
  required String password,
}) async {
  final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );

  await rememberParentDevice();

  notifyListeners();
  return cred.user!;
}

Future<void> signOutCurrentUser() async {
  await FirebaseAuth.instance.signOut();
  await clearRememberedDeviceMode();
}

User? currentAuthUser() {
  return FirebaseAuth.instance.currentUser;
}

Future<String> createChildProfile({
  required String name,
  String avatar = 'owl',
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('No signed-in parent found.');
  }

  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    throw Exception('Please enter a child name.');
  }

  final accessCode = generateChildAccessCode();

  final friendCode = generateChildFriendCode(trimmedName);

  final childRef = await FirebaseFirestore.instance
      .collection('parents')
      .doc(user.uid)
      .collection('children')
      .add({
    'name': trimmedName,
    'avatar': avatar,
    'createdAt': FieldValue.serverTimestamp(),
    'role': 'child',
    'accessCode': accessCode,
    'friendCode': friendCode,
    'parentId': user.uid,
    'linkedDevice': false,
    'linkedAuthUid': null,
  });

await FirebaseFirestore.instance
    .collection('child_access_codes')
    .doc(accessCode)
    .set({
  'parentId': user.uid,
  'childId': childRef.id,
  'childName': trimmedName,
  'avatar': avatar,
  'friendCode': friendCode,
  'createdAt': FieldValue.serverTimestamp(),
});

    await FirebaseFirestore.instance
      .collection('child_friend_codes')
      .doc(friendCode)
      .set({
    'parentId': user.uid,
    'childId': childRef.id,
    'childName': trimmedName,
    'friendCode': friendCode,
    'createdAt': FieldValue.serverTimestamp(),
  });

  notifyListeners();
  return accessCode;
}

  void recordCoachedMessageSentAnyway() {
  coachedMessagesSentAnyway += 1;
  notifyListeners();
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
        home: const StartupRouterScreen(),
      ),
    );
  }
}

class BubblyBackground extends StatelessWidget {
  final Widget child;
  const BubblyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Color(0xFF133A8A),
      child: child,
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF4A556F),
        borderRadius: BorderRadius.circular(NatterBrand.radius),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
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
class StartupRouterScreen extends StatefulWidget {
  const StartupRouterScreen({super.key});

  @override
  State<StartupRouterScreen> createState() => _StartupRouterScreenState();
}

class _StartupRouterScreenState extends State<StartupRouterScreen> {
  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _route();
  });
}

  Future<void> _route() async {
    final state = AppStateScope.of(context);
    final mode = await state.getDeviceMode();

    if (!mounted) return;

    if (mode == 'parent') {
      Navigator.pushReplacement(
        context,
        calmRoute(const ParentHomeScreen()),
      );
      return;
    }

    if (mode == 'child') {
  await state.hydrateRememberedChildSession();

  if (!mounted) return;

  if (!state.hasActiveChildSession) {
    Navigator.pushReplacement(
      context,
      calmRoute(const GatewayScreen()),
    );
    return;
  }

  Navigator.pushReplacement(
    context,
    calmRoute(const ChatsScreen()),
  );
  return;
}

    Navigator.pushReplacement(
      context,
      calmRoute(const GatewayScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class GatewayScreen extends StatelessWidget {
  const GatewayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ParentBrandScaffold(
      child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                const SizedBox(height: 18),
                Center(
                  child: Image.asset(
                    'assets/natter-logo-v2.png',
                    height: 96,
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Welcome to Natter',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A calm, safe place for children to grow in confidence — with trusted parent oversight.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose your space',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Parents can set up accounts, manage safety settings and review progress. Children enter their own friendly Natter space.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        calmRoute(const ParentAuthScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0B80BB),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'I’m a Parent',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        calmRoute(const ChildAccessCodeScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.7)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Child Space',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'This choice will become automatic later, based on the device and account in use.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class ChirpWelcomeScreen extends StatelessWidget {
  final String childName;

  const ChirpWelcomeScreen({
    super.key,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    return ParentBrandScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/chirp_welcome.png',
                  height: 140,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Hi $childName 👋',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "I'm Chirp. Welcome to Natter.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "This is your space to chat, learn and grow kindly 💛",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    calmRoute(const ChatsScreen()),
                    (_) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NatterBrand.green,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Enter your space',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParentAuthScreen extends StatefulWidget {
  const ParentAuthScreen({super.key});

  @override
  State<ParentAuthScreen> createState() => _ParentAuthScreenState();
}

class _ParentAuthScreenState extends State<ParentAuthScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = AppStateScope.of(context);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        if (name.isEmpty) {
          throw Exception('Please enter your name.');
        }

        await state.signUpParent(
          email: email,
          password: password,
          displayName: name,
        );
      } else {
        await state.signInParent(
          email: email,
          password: password,
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        calmRoute(const ParentHomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Authentication failed.';
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ParentBrandScaffold(
      child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.24),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                        const Text(
                      'Parent Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isSignUp
                          ? 'Create your parent account to manage safety, setup and child progress.'
                          : 'Sign in to your parent account.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isSignUp) ...[
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _fieldDecoration('Your name'),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _fieldDecoration('Email address'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDecoration('Password'),
                    ),
                    const SizedBox(height: 18),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0B80BB),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          _loading
                              ? 'Please wait...'
                              : (_isSignUp
                                  ? 'Create Parent Account'
                                  : 'Sign In'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _error = null;
                              });
                            },
                      child: Text(
                        _isSignUp
                            ? 'Already have a parent account? Sign in'
                            : 'Need a parent account? Create one',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
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

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    final greetingName =
        (displayName != null && displayName.isNotEmpty) ? displayName : 'Parent';

    return ParentBrandScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parent Home',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Signed in as ${user?.email ?? 'unknown email'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await AppStateScope.of(context).signOutCurrentUser();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        calmRoute(const GatewayScreen()),
                        (_) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $greetingName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your parent account is now active. From here, you will be able to create child profiles, manage safety settings and oversee progress with confidence.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              StreamBuilder<List<ParentChildProfile>>(
                stream: AppStateScope.of(context).parentChildrenStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: Text(
                        'Could not load children: ${snapshot.error}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final children = snapshot.data ?? [];

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.10),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your children',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (children.isEmpty)
                          const Text(
                            'No child profiles yet.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          )
                        else
                          ...children.map((child) {
                            return MouseRegion(
  cursor: SystemMouseCursors.click,
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          calmRoute(
            ParentChildDetailScreen(child: child),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.14),
              child: Text(
                child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Avatar: ${child.avatar}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: ${child.accessCode}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    child.linkedDevice
                        ? 'Device linked'
                        : 'Waiting for child device',
                    style: TextStyle(
                      color: child.linkedDevice
                          ? NatterBrand.green
                          : Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    ),
  ),
);
                      
                          }),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next steps',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '• Create child profiles\n'
                      '• Set quiet hours and approvals\n'
                      '• Review alerts and progress\n'
                      '• Separate parent and child spaces cleanly',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      calmRoute(const CreateChildProfileScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NatterBrand.green,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Create Child Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      calmRoute(const ParentDashboardScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0B80BB),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Open Parent Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      calmRoute(const GatewayScreen()),
                      (_) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.7)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Back to Welcome Screen',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParentChildDetailScreen extends StatelessWidget {
  final ParentChildProfile child;

  const ParentChildDetailScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ParentBrandScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          child.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white.withOpacity(0.14),
                      child: Text(
                        child.name.isNotEmpty
                            ? child.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      child.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      child.linkedDevice
                          ? 'This child has linked a device.'
                          : 'This child has not linked a device yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: child.linkedDevice
                            ? NatterBrand.green
                            : Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Child details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Avatar: ${child.avatar}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Access code: ${child.accessCode}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Device status: ${child.linkedDevice ? 'Linked' : 'Not linked'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 18),

StreamBuilder<List<ChildContactRequest>>(
  stream: AppStateScope.of(context).childContactRequestsStream(
    parentId: FirebaseAuth.instance.currentUser!.uid,
    childId: child.childId,
    status: 'pending',
  ),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.16),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        child: Text(
          'Could not load requests: ${snapshot.error}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.16),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final requests = snapshot.data ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending requests',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (requests.isEmpty)
            const Text(
              'No pending requests.',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...requests.map((request) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.requesterName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await AppStateScope.of(context).approveContactForChild(
                          parentId: FirebaseAuth.instance.currentUser!.uid,
                          childId: child.childId,
                          request: request,
                        );
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
                      onPressed: () async {
                        await AppStateScope.of(context).blockContactForChild(
                          parentId: FirebaseAuth.instance.currentUser!.uid,
                          childId: child.childId,
                          request: request,
                        );
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
              );
            }),
        ],
      ),
    );
  },
),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coming soon',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'This screen will become the child-specific parent control area for approvals, safety settings, and progress.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
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

class ChildAccessCodeScreen extends StatefulWidget {
  const ChildAccessCodeScreen({super.key});

  @override
  State<ChildAccessCodeScreen> createState() => _ChildAccessCodeScreenState();
}

class _ChildAccessCodeScreenState extends State<ChildAccessCodeScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
  final state = AppStateScope.of(context);

  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    setState(() {
      _error = 'Signing in...';
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && !currentUser.isAnonymous) {
      await FirebaseAuth.instance.signOut();
    }

    final childUser = await ensureSignedIn();

    setState(() {
      _error = 'Looking up code...';
    });

    final result = await state.findChildByAccessCode(_codeController.text);

    if (result == null) {
      throw Exception('That code was not recognised.');
    }

    setState(() {
      _error = 'Remembering child...';
    });

    await state.rememberChildDevice(
      parentId: result['parentId']!,
      childId: result['childId']!,
      childName: result['childName']!,
      childAvatar: result['avatar'] ?? 'owl',
      childFriendCode: result['friendCode'] ?? '',
    );

    setState(() {
      _error = 'Linking device...';
    });

    await FirebaseFirestore.instance
        .collection('parents')
        .doc(result['parentId']!)
        .collection('children')
        .doc(result['childId']!)
        .set({
      'linkedDevice': true,
      'linkedAuthUid': childUser.uid,
    }, SetOptions(merge: true));

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      calmRoute(
        const ChatsScreen(),
      ),
      (_) => false,
    );
  } catch (e) {
    setState(() {
      _error = e.toString().replaceFirst('Exception: ', '');
    });
  } finally {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
}

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ParentBrandScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Child Access',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter your code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Ask your parent for your Natter access code and enter it here.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                      decoration: _fieldDecoration('Access code'),
                    ),
                    const SizedBox(height: 18),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      onPressed: _loading ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NatterBrand.green,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _loading ? 'Checking...' : 'Continue',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ParentSpaceBackground extends StatelessWidget {
  final Widget child;

  const ParentSpaceBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF041A2F),
            Color(0xFF0B2E4A),
            Color(0xFF0A4A73),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 110,
            left: 40,
            child: _bubble(10, const Color(0x66C96CB3)),
          ),
          Positioned(
            top: 140,
            left: 90,
            child: _bubble(18, const Color(0x44C96CB3)),
          ),
          Positioned(
            top: 170,
            left: 140,
            child: _bubble(14, const Color(0x55E7C15A)),
          ),
          Positioned(
            top: 220,
            right: 60,
            child: _bubble(26, const Color(0x334D86B8)),
          ),
          Positioned(
            bottom: 180,
            left: 36,
            child: _bubble(22, const Color(0x44C96CB3)),
          ),
          Positioned(
            bottom: 130,
            left: 120,
            child: _bubble(30, const Color(0x55C96CB3)),
          ),
          Positioned(
            bottom: 80,
            right: 30,
            child: _bubble(28, const Color(0x335D6F8A)),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }

  static Widget _bubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class CreateChildProfileScreen extends StatefulWidget {
  const CreateChildProfileScreen({super.key});

  @override
  State<CreateChildProfileScreen> createState() =>
      _CreateChildProfileScreenState();
}

class _CreateChildProfileScreenState extends State<CreateChildProfileScreen> {
  final _nameController = TextEditingController();

  bool _loading = false;
  String? _error;
  String _selectedAvatar = 'owl';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = AppStateScope.of(context);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final accessCode = await state.createChildProfile(
  name: _nameController.text,
  avatar: _selectedAvatar,
);

if (!mounted) return;

await showDialog(
  context: context,
  builder: (context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF10283A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      title: const Text(
        'Child profile created',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Give this access code to your child:',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            child: Text(
              accessCode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Your child can enter this code on their device to open their Natter space.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Done',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  },
);

if (!mounted) return;
Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 1.2),
      ),
    );
  }

  Widget _avatarChoice(String value, String label, IconData icon) {
    final selected = _selectedAvatar == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAvatar = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withOpacity(0.16)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? Colors.white : Colors.white.withOpacity(0.10),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ParentBrandScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Create Child Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: SizedBox.expand(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.22),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add a child',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Create a child profile to begin setting up their Natter experience.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('Child name'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Choose an avatar style',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _avatarChoice('owl', 'Owl', Icons.flutter_dash),
                      const SizedBox(width: 10),
                      _avatarChoice('star', 'Star', Icons.star_rounded),
                      const SizedBox(width: 10),
                      _avatarChoice('rocket', 'Rocket', Icons.rocket_launch),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NatterBrand.green,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      _loading ? 'Saving...' : 'Create Child Profile',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
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
                const NatterLogo(height: 220),
                const SizedBox(height: 12),
                const Text(
  'Your first place to chat and grow 🌱',
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
    'Make friends. Send kind messages. Build your confidence.',
    textAlign: TextAlign.center,
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
  ),
),
                const SizedBox(height: 18),
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () {
      final state = AppStateScope.of(context);

      Navigator.push(
        context,
        calmRoute(
          PromiseScreen(
            name: state.effectiveChildName,
          ),
        ),
      );
    },
    child: const Text('Enter Natter ✨'),
  ),
),
const SizedBox(height: 12),
TextButton(
  onPressed: () async {
    await AppStateScope.of(context).clearRememberedDeviceMode();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      calmRoute(const GatewayScreen()),
      (_) => false,
    );
  },
  child: const Text(
    'Reset this device',
    style: TextStyle(
      color: Colors.white70,
      fontWeight: FontWeight.w700,
    ),
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

class _PromiseScreenState extends State<PromiseScreen>
    with TickerProviderStateMixin {
  final options = const [
    'Be kind',
    'No secrets from adults',
    'If it feels weird, stop',
    'Ask before adding friends',
    'Keep it text-only',
    'Take breaks',
  ];

  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
void initState() {
  super.initState();

  _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.9,
    upperBound: 1.1,
  )..repeat(reverse: true);

  _glowController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  _glowAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
    CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ),
  );
}
  
  @override
void dispose() {
  _pulseController.dispose();   // existing (chips glow)
  _glowController.dispose();    // new (button glow)
  super.dispose();
}

  final Set<String> selected = {};

  bool justCompletedPromiseSet = false;

  Future<void> _seal() async {
  final promises = selected.toList();

  print('SEAL tapped');
  print('Name: ${widget.name}');
  print('Promises: $promises');

  try {
    print('About to call recordRite');

    await AppStateScope.of(context).recordRite(
      name: widget.name,
      promises: promises,
    );

    print('recordRite completed successfully');

    if (!mounted) return;

    Navigator.push(
      context,
      calmRoute(
        CeremonyScreen(
          name: widget.name,
          promises: promises,
        ),
      ),
    );
  } catch (e, st) {
    print('SEAL ERROR: $e');
    print(st);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not save your promises: $e'),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final remaining = 3 - selected.length;
    final canContinue = selected.length >= 3;
    final isLocked = selected.length >= 3;

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

          return ScaleTransition(
            scale: isOn ? _pulseController : const AlwaysStoppedAnimation(1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: isOn
                    ? [
                        BoxShadow(
                          color: NatterBrand.yellow.withOpacity(0.35),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: ChoiceChip(
                label: Text(
                  t,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isOn
                        ? Colors.black
                        : (isLocked
                            ? Colors.black.withOpacity(0.45)
                            : NatterBrand.navy),
                  ),
                ),
                selected: isOn,
                showCheckmark: false,
                elevation: isOn ? 6 : 0,
                shadowColor: NatterBrand.yellow.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                labelPadding: EdgeInsets.zero,
                backgroundColor: isLocked && !isOn
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.9),
                selectedColor: NatterBrand.yellow,
                side: BorderSide(
                  color: isOn
                      ? NatterBrand.yellow
                      : (isLocked
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.25)),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (_) {
                  setState(() {
                    final beforeCount = selected.length;

                    if (isOn) {
                      selected.remove(t);
                      justCompletedPromiseSet = false;
                    } else if (!isLocked) {
                      selected.add(t);

                      if (beforeCount == 2 && selected.length == 3) {
                        justCompletedPromiseSet = true;

                        Future.delayed(const Duration(milliseconds: 900), () {
                          if (!mounted) return;
                          setState(() {
                            justCompletedPromiseSet = false;
                          });
                        });
                      }
                    }
                  });
                },
              ),
            ),
          );
        }).toList(),
      ),
    ),
  ),
),
const SizedBox(height: 10),
AnimatedSwitcher(
  duration: const Duration(milliseconds: 250),
  child: Text(
    justCompletedPromiseSet
        ? '✨ Beautiful choice. Your promise set is complete.'
        : canContinue
            ? 'Your promise set is complete ✨'
            : 'Choose $remaining more',
    key: ValueKey(
      justCompletedPromiseSet
          ? 'justCompleted'
          : canContinue
              ? 'complete'
              : 'remaining',
    ),
    style: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
    textAlign: TextAlign.center,
  ),
),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AnimatedBuilder(
  animation: _glowAnimation,
  builder: (context, child) {
    final scale = canContinue ? _glowAnimation.value : 1.0;

    return Transform.scale(
      scale: scale,
      child: child,
    );
  },
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      boxShadow: canContinue
          ? [
              BoxShadow(
                color: NatterBrand.green.withOpacity(0.45),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ]
          : [],
    ),
    child: ElevatedButton(
      onPressed: canContinue ? _seal : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            canContinue ? NatterBrand.green : Colors.grey.shade700,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: const Text(
        'Seal My Promises ✨',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    ),
  ),
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

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return BrandScaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Journey'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const ChatsScreen()._levelCard(state),
          const SizedBox(height: 12),
          const ChatsScreen()._profileCard(context, state),
          const SizedBox(height: 12),
          const ChatsScreen()._dailyQuestCard(state),
          const SizedBox(height: 12),
          const ChatsScreen()._friendCodeCard(context, state),
          const SizedBox(height: 80),
        ],
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

class GraduationScreen extends StatelessWidget {
  const GraduationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: NatterBrand.blue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 80,
                color: NatterBrand.yellow,
              ),
              const SizedBox(height: 24),

              const Text(
                'You are ready to graduate',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'You have shown kindness, built friendships, and learned how to communicate safely online.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    calmRoute(const GraduationCeremonyScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NatterBrand.yellow,
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'Begin Graduation',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GraduationCeremonyScreen extends StatefulWidget {
  const GraduationCeremonyScreen({super.key});

  @override
  State<GraduationCeremonyScreen> createState() =>
      _GraduationCeremonyScreenState();
}

class _GraduationCeremonyScreenState
    extends State<GraduationCeremonyScreen> {
  double opacity = 0;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: NatterBrand.blue,
      body: SafeArea(
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 800),
            opacity: opacity,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 90,
                    color: NatterBrand.yellow,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Congratulations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You are now a Natter Graduate 🎓',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You have shown kindness, patience, and strong digital communication skills.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      state.completeGraduation();

                      Navigator.pushAndRemoveUntil(
                        context,
                        calmRoute(const ChatsScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NatterBrand.yellow,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      'Finish',
                      style: TextStyle(fontWeight: FontWeight.w900),
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

class DigitalReadinessReportScreen extends StatelessWidget {
  const DigitalReadinessReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return BrandScaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Digital Readiness'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      color: NatterBrand.yellow,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.isGraduated
                            ? 'Natter Graduate'
                            : 'Digital Readiness Journey',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  state.isGraduated
                      ? '${state.lastName ?? 'Your child'} has successfully completed the Natter journey.'
                      : '${state.lastName ?? 'Your child'} is developing strong digital communication habits.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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
                  'Strengths Shown',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                ...state.digitalReadinessStrengths.map(
                  (strength) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      strength,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
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
                const Text(
                  'Progress Highlights',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '💛 Positive messages: ${state.positiveMessages}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '🌱 Kindness rewrites: ${state.kindnessRewrites}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '🤝 Shared quests completed: ${state.completedSharedQuests}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '💬 Conversation starters used: ${state.conversationStartersUsed}',
                  style: const TextStyle(
                    color: Colors.white,
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
                  'What This Means',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  state.isGraduated
                      ? 'Your child has demonstrated kind communication, safe message choices, and the ability to build positive digital friendships.'
                      : 'Your child is building the skills needed to communicate kindly, handle messages safely, and grow positive online friendships.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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
    final displayName = state.effectiveChildName;

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
          if (state.isGraduated) ...[
  const SizedBox(height: 14),
  BrandCard(
    child: Row(
      children: [
        const Icon(
          Icons.school_rounded,
          color: NatterBrand.yellow,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Natter Graduate 🎓',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ),
      ],
    ),
  ),
],
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
    final suggestions = FriendDirectory.profiles;

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
              'Add a friend by code or pick a suggestion. A parent will approve it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Suggested friends',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions.map<Widget>((profile) {
                  return ActionChip(
                    backgroundColor: NatterBrand.blue.withOpacity(0.6),
                    label: Text(
                      '${profile.name} (${profile.code})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    avatar: CircleAvatar(
                      backgroundColor: NatterBrand.yellow,
                      child: Text(
                        profile.name.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    onPressed: () {
                      controller.text = profile.code;
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
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
                    onPressed: () async {
                      final code = controller.text.trim().toUpperCase();
                      final friendResult = await state.findChildByFriendCode(code);
                      final friendName = friendResult?['name'];

                        if (friendResult == null || friendName == null || friendName.isEmpty) {
    Navigator.pop(ctx);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('That friend code was not recognised.'),
      ),
    );
    return;
  }

  if (friendResult['childId'] == state.activeChildId) {
    Navigator.pop(ctx);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('That is your own friend code.'),
      ),
    );
    return;
  }

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

                      await state.requestContact(
  targetName: friendName,
  targetParentId: friendResult['parentId']!,
  targetChildId: friendResult['childId']!,
  targetFriendCode: friendResult['friendCode']!,
);
Navigator.pop(ctx);

if (!state.hasSeenAddFriendSuccess) {
  state.hasSeenAddFriendSuccess = true;
  state.onboardingStep = 4;
  await state.saveChildOnboardingState();
  state.notifyListeners();
}

if (!context.mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      '$friendName is now waiting for parent approval ⏳',
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
                  state.effectiveChildName,
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
              value: (state.dailyQuestProgress / state.dailyQuest.target).clamp(0, 1),
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
          const Row(
            children: [
              Icon(
                Icons.qr_code_rounded,
                color: NatterBrand.yellow,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Your friend code',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
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
  final schoolFriends = state.sameSchoolFriends;
  final yearFriends = state.sameYearFriends;
  final chats = state.approvedContacts
      .map((f) => ChatPreview(
            name: f.name,
            last: 'No messages yet',
            unread: false,
          ))
      .toList();

    return BrandScaffold(
    appBar: AppBar(
  backgroundColor: Colors.transparent,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  scrolledUnderElevation: 0,
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
            calmRoute(const JourneyScreen()),
          ),
          child: const Text(
            'Journey',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            calmRoute(
              state.hasSeenParentOnboarding
                  ? ParentDashboardScreen()
                  : ParentOnboardingScreen(),
            ),
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
  floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      child: RepaintBoundary(
  child: ListView(
    physics: const ClampingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
    children: [
            if (!state.hasSentFirstMessage && state.isInOnboarding) ...[
              BrandCard(
                child: Row(
                  children: [
                    Image.asset(
                      'assets/chirp_prompt.png',
                      height: 56,
                      width: 56,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chirp says: Try saying hello to Ava 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            BrandCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Spark',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.todaySpark,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        state.recordConversationStarterUse();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nice start! 🌟'),
                          ),
                        );
                      },
                      child: const Text(
                        'Try it',
                        style: TextStyle(
                          color: NatterBrand.yellow,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _friendCodeCard(context, state),
            const SizedBox(height: 12),

            StreamBuilder<List<ChildContactRequest>>(
  stream: state.activeChildContactRequestsStream(status: 'pending'),
  builder: (context, snapshot) {
    final pending = snapshot.data ?? [];

    if (pending.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ...pending.map((request) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BrandCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.transparent,
                    child: Icon(
                      Icons.hourglass_top_rounded,
                      color: NatterBrand.yellow,
                    ),
                  ),
                ),
                title: Text(
                  request.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: const Text(
                  'Waiting for parent approval',
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white70,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  },
),

            StreamBuilder<List<ApprovedChildContact>>(
  stream: state.activeChildApprovedContactsStream(),
  builder: (context, snapshot) {
    final approved = snapshot.data ?? [];

    if (approved.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ...approved.map((contact) {
          final hasGlow = contact.isNew;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BrandCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: hasGlow
                        ? [
                            BoxShadow(
                              color: NatterBrand.green.withOpacity(0.45),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: hasGlow
                        ? NatterBrand.green.withOpacity(0.25)
                        : NatterBrand.yellow.withOpacity(0.35),
                    child: Text(
                      contact.name.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  contact.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  hasGlow
                      ? 'Newly approved friend'
                      : 'Ready to chat',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
                onTap: () async {
                  await state.markApprovedContactAsSeen(contact.id);

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    calmRoute(ChatScreen(contactName: contact.name)),
                  );
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  },
),

            if (schoolFriends.isNotEmpty) ...[
              BrandCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your School Circle',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${schoolFriends.length} friends from your school',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${yearFriends.length} from your year group',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

...chats.map((c) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            calmRoute(ChatScreen(contactName: c.name)),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2D4D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: NatterBrand.yellow.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  c.name.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Friendship preview',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shared Quest: 0/3',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}).toList(),

                        const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () async {
  try {
    await AppStateScope.of(context).clearRememberedDeviceMode();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      calmRoute(const GatewayScreen()),
      (_) => false,
    );
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not reset this device: $e'),
      ),
    );
  }
},
                child: const Text(
                  'Reset this device',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
              
class _FriendshipQuestCard extends StatelessWidget {
  final Friend friend;

  const _FriendshipQuestCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          calmRoute(FriendshipJourneyScreen(friend: friend)),
        );
      },
      child: BrandCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${friend.name} ${friend.stars}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    friend.friendshipStage,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
  borderRadius: BorderRadius.circular(999),
  child: TweenAnimationBuilder<double>(
    tween: Tween<double>(
      begin: 0,
      end: friend.meterPercent,
    ),
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeOutCubic,
    builder: (context, value, _) {
      return LinearProgressIndicator(
        value: value,
        minHeight: 10,
        backgroundColor: Colors.white.withOpacity(0.14),
        valueColor: const AlwaysStoppedAnimation<Color>(
          NatterBrand.green,
        ),
      );
    },
  ),
),
                  const SizedBox(height: 10),
                  Text(
                    'Quest progress: ${friend.activeQuestProgress}/${friend.activeQuestTarget}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.84),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FriendshipJourneyScreen extends StatelessWidget {
  final Friend friend;

  const FriendshipJourneyScreen({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return BrandScaffold(
      appBar: AppBar(
        title: BrandedAppBarTitle(title: '${friend.name} Journey'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${friend.name} ${friend.stars}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  friend.friendshipStage,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Friendship Meter',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.84),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: friend.meterPercent,
                    minHeight: 12,
                    backgroundColor: Colors.white.withOpacity(0.14),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      NatterBrand.green,
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
                const Text(
                  'Friendship Moments',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                if (friend.friendshipMoments.isEmpty)
                  Text(
                    'No friendship moments yet.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  ...friend.friendshipMoments.reversed.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.14),
                          ),
                        ),
                        child: Text(
                          m,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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

class _GraduationPoint extends StatelessWidget {
  final String text;

  const _GraduationPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
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
  final ScrollController _scrollController = ScrollController();
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

    final state = AppStateScope.of(context);
    state.recordConversationStarterUse();
    
    final friend = state.getFriendByName(widget.contactName);

    if (friend != null &&
        friend.activeQuestTitle.contains('Use a conversation starter')) {
      state.progressFriendQuest(widget.contactName);
    }
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

bool _didInitialChatScroll = false;

void _scrollToBottom({bool animated = true}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_scrollController.hasClients) return;

    final target = _scrollController.position.maxScrollExtent;

    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  });
}

  void _startStallTimer() {
  _stallTimer?.cancel();

  _stallTimer = Timer(const Duration(seconds: 20), () {
    if (!mounted) return;
    _showStallRescue();
  });
  }
  
Future<void> _sendMessageNow(String text, {bool flagged = false}) async {
  final state = AppStateScope.of(context);
  _stallTimer?.cancel();

  final isFirstMessage = !state.hasSentFirstMessage;
  if (isFirstMessage) {
    state.hasSentFirstMessage = true;
    state.onboardingStep = 1;
    await state.saveChildOnboardingState();
    state.notifyListeners();
  }

  state.recordPositiveMessage();
  state.addFriendshipPoints(widget.contactName, 2);

  final friend = state.getFriendByName(widget.contactName);
  if (friend != null && friend.activeQuestTitle.contains('Send')) {
    state.progressFriendQuest(widget.contactName);
  }

  friend?.friendshipMoments.add('💛 You sent a kind message');

  if (friend != null &&
      friend.activeQuestTitle.contains('Send') &&
      friend.activeQuestProgress == friend.activeQuestTarget - 1) {
    setState(() {
      feedback = '🌟 Almost there! One more to complete your quest.';
    });
  }

  if (state.lastQuestCelebrationFriend == widget.contactName) {
    setState(() {
      feedback =
          '🎉 Quest Complete! You and ${widget.contactName} completed a shared quest.';
    });

    state.lastQuestCelebrationFriend = null;
  }

  setState(() {
    feedback = null;
  });

  await state.sendMessageToChat(
  friendName: widget.contactName,
  text: text,
  isFlagged: flagged,
);

  controller.clear();

  _scrollToBottom();

  if (isFirstMessage && state.isInOnboarding) {
    state.hasSeenFirstReply = true;
    state.onboardingStep = 2;
    await state.saveChildOnboardingState();
    state.notifyListeners();

    await showDialog(
      context: context,
      builder: (dialogContext) => ChirpDialogCard(
        imagePath: 'assets/chirp_reply.png',
        message: 'Nice start — you sent your first message 💛\nThat’s how friendships begin.',
        buttonText: 'Continue',
        onPressed: () {
          Navigator.pop(dialogContext);
        },
      ),
    );

    if (!mounted) return;

    if (!state.hasSeenAddFriendPrompt) {
      state.hasSeenAddFriendPrompt = true;
      state.onboardingStep = 3;
      await state.saveChildOnboardingState();
      state.notifyListeners();

      await const ChatsScreen()._addFriendDialog(context);
    }
  }
  _startStallTimer();
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
  state.recordCoachedMessageSentAnyway();

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

  await _sendMessageNow(text, flagged: true);
} else {
  state.recordKindRewrite();
  state.addFriendshipPoints(widget.contactName, 3);
  setState(() {
    feedback = 'Nice pause. Try rewriting your message kindly 💛';
  });
      }
      return;
    }

    await _sendMessageNow(text);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    final friend = state.getFriendByName(widget.contactName);

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
          if (friend != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _FriendshipQuestCard(friend: friend),
            ),
         Expanded(
  child: StreamBuilder<List<Map<String, dynamic>>>(
    stream: AppStateScope.of(context).messageStream(widget.contactName),
    builder: (context, snapshot) {
  if (snapshot.hasError) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Chat error: ${snapshot.error}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  final firestoreMessages = snapshot.data ?? [];

      if (firestoreMessages.isNotEmpty && !_didInitialChatScroll) {
  _didInitialChatScroll = true;
  _scrollToBottom(animated: false);
}

            return ListView.builder(
        controller: _scrollController,
        reverse: false,
        padding: const EdgeInsets.all(14),
        itemCount: firestoreMessages.length,
        itemBuilder: (_, i) {
          final data = firestoreMessages[i];
          final state = AppStateScope.of(context);
          final messageId = (data['id'] ?? '') as String;
          final isMe = data['senderUid'] == state.activeChildId;
          final isFlagged = data['isFlagged'] == true;
          final text = (data['text'] ?? '') as String;
          final receiverAction = (data['receiverAction'] ?? '') as String;

          final msg = _Msg(
            fromMe: isMe,
            text: text,
            isFlagged: isFlagged,
            isRevealed: receiverAction == 'read',
            isHidden:
                receiverAction == 'not_now' || receiverAction == 'blocked',
          );

          return _Bubble(
            msg: msg,
            onTap: () {},
            onReveal: () async {
              await state.revealFlaggedMessage(
                friendName: widget.contactName,
                messageId: messageId,
              );
            },
            onHide: () async {
              await state.hideFlaggedMessage(
                friendName: widget.contactName,
                messageId: messageId,
              );
            },
            onBlock: () async {
              await state.blockAfterFlaggedMessage(
                friendName: widget.contactName,
                messageId: messageId,
              );
              state.blockContact(widget.contactName);

              if (!mounted) return;

              setState(() {
                feedback = '${widget.contactName} has been blocked.';
              });
            },
          );
        },
      );
    },
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
  final bool isSystem;

  _Msg({
    required this.fromMe,
    required this.text,
    this.reaction,
    this.isFlagged = false,
    this.isRevealed = false,
    this.isHidden = false,
    this.isSystem = false,
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
    
    if (msg.isSystem) {
  return Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: NatterBrand.yellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: NatterBrand.yellow.withOpacity(0.35),
        ),
      ),
      child: Text(
        msg.text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
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

class ParentBrandScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget child;

  const ParentBrandScaffold({
    super.key,
    this.appBar,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: ParentSpaceBackground(
        child: child,
      ),
    );
  }
}

class ParentOnboardingScreen extends StatefulWidget {
  const ParentOnboardingScreen({super.key});

  @override
  State<ParentOnboardingScreen> createState() =>
      _ParentOnboardingScreenState();
}

class _ParentOnboardingScreenState extends State<ParentOnboardingScreen> {
  int step = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    final pages = [
      const _ParentIntroCard(
        title: 'Welcome to Natter',
        body:
            'Natter helps children learn kind, safe communication before they move into wider digital spaces.',
        imagePath: 'assets/owliver_hello.png',
      ),
      const _ParentIntroCard(
        title: 'What you control',
        body:
            'You approve friends, set quiet hours, and receive gentle insight into how your child is building positive digital habits.',
        imagePath: 'assets/owliver_teaching.png',
      ),
      const _ParentIntroCard(
        title: 'How it works',
        body:
            'Your child chats in a supported space. Natter encourages kindness, helps with tricky messages, and celebrates healthy communication.',
        imagePath: 'assets/owliver_thinking.png',
      ),
    ];

    final isLast = step == pages.length - 1;

    return BrandScaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Parent Introduction'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: pages[step],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == step
                        ? NatterBrand.yellow
                        : Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          step -= 1;
                        });
                      },
                      child: const Text('Back'),
                    ),
                  ),
                if (step > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (isLast) {
                        state.hasSeenParentOnboarding = true;

                        Navigator.pushReplacement(
                          context,
                          calmRoute(const ParentDashboardScreen()),
                        );
                      } else {
                        setState(() {
                          step += 1;
                        });
                      }
                    },
                    child: Text(
                      isLast ? 'Open Parent Controls' : 'Next',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentIntroCard extends StatelessWidget {
  final String title;
  final String body;
  final String imagePath;

  const _ParentIntroCard({
    required this.title,
    required this.body,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            height: 300,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final hasRite = state.lastName != null &&
        state.lastPromises.isNotEmpty &&
        state.lastBadge != null;

    return ParentBrandScaffold(
      appBar: AppBar(
  backgroundColor: Colors.transparent,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  scrolledUnderElevation: 0,
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
                    if (state.isGraduated)
  const SizedBox(height: 6),
if (state.isGraduated)
  const Text(
    'Graduation status: Complete 🎓',
    style: TextStyle(
      color: NatterBrand.yellow,
      fontWeight: FontWeight.w900,
    ),
  ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
BrandCard(
  child: Row(
    children: [
      const Icon(
        Icons.description_rounded,
        color: NatterBrand.yellow,
        size: 26,
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Text(
          'View Digital Readiness Report',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      TextButton(
        onPressed: () {
          Navigator.push(
            context,
            calmRoute(const DigitalReadinessReportScreen()),
          );
        },
        child: const Text(
          'Open',
          style: TextStyle(
            color: NatterBrand.yellow,
            fontWeight: FontWeight.w900,
          ),
        ),
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

class ChirpDialogCard extends StatelessWidget {
  final String imagePath;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const ChirpDialogCard({
    super.key,
    required this.imagePath,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.78),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imagePath,
              height: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
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
       
