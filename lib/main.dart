import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const NatterApp());

/// Calm fade + tiny slide transition for peaceful navigation.
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

/// ===== Brand =====
class NatterBrand {
  static const blue = Color(0xFF3DA6F3);
  static const green = Color(0xFFA4D35A);
  static const yellow = Color(0xFFFBC02D);
  static const pink = Color(0xFFFF5DA2);

  static const navy = Color(0xFF06112E);
  static const radius = 24.0;

  /// Update this if you rename the file again.
  static const logoPath = 'assets/natter-logo-v2.png';
}

/// ===== App State (no backend; demo only) =====
enum AlertType { blockedWord, quietHours, contactRequest }

class AlertEvent {
  final AlertType type;
  final String message;
  final DateTime time;
  AlertEvent({required this.type, required this.message, DateTime? time})
      : time = time ?? DateTime.now();
}

class AppState extends ChangeNotifier {
  // Contacts
  final List<String> approvedContacts = ['Dad', 'Sam', 'Mia'];
  final List<String> pendingRequests = ['Ava', 'Leo'];

  // Rules
  bool quietHoursEnabled = true;
  TimeOfDay quietStart = const TimeOfDay(hour: 20, minute: 0); // 8:00pm
  TimeOfDay quietEnd = const TimeOfDay(hour: 7, minute: 0); // 7:00am

  // Alerts settings
  bool alertsBlockedWord = true;
  bool alertsContactRequest = true;
  bool alertsQuietHours = true;

  // Alerts feed (parents see this)
  final List<AlertEvent> alerts = [];

  // Promises / badge
  List<String> lastPromises = const [];
  String? lastName;
  NatterBadge? lastBadge;

  // --- helpers ---
  bool _isTimeInRange(TimeOfDay t, TimeOfDay start, TimeOfDay end) {
    int toMin(TimeOfDay x) => x.hour * 60 + x.minute;
    final tm = toMin(t);
    final sm = toMin(start);
    final em = toMin(end);

    // Same-day range
    if (sm < em) return tm >= sm && tm < em;

    // Overnight range (e.g. 20:00 -> 07:00)
    return tm >= sm || tm < em;
  }

  bool isQuietNow() {
    if (!quietHoursEnabled) return false;
    final now = TimeOfDay.fromDateTime(DateTime.now());
    return _isTimeInRange(now, quietStart, quietEnd);
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
    pendingRequests.remove(name);
    if (!approvedContacts.contains(name)) approvedContacts.add(name);
    notifyListeners();
  }

  void blockContact(String name) {
    pendingRequests.remove(name);
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
  }) {
    if (blockedWord != null) alertsBlockedWord = blockedWord;
    if (contactRequest != null) alertsContactRequest = contactRequest;
    if (quietHours != null) alertsQuietHours = quietHours;
    notifyListeners();
  }

  void recordRite({
    required String name,
    required List<String> promises,
  }) {
    lastName = name;
    lastPromises = List<String>.from(promises);
    lastBadge = badgeForPromises(promises.toSet());
    notifyListeners();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({super.key, required AppState notifier, required Widget child})
      : super(notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope?.notifier != null, 'AppStateScope not found');
    return scope!.notifier!;
  }
}

/// ===== App =====
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            behavior: SnackBarBehavior.floating,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.14),
            hintStyle: const TextStyle(color: Colors.white70),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
          dividerTheme: const DividerThemeData(color: Colors.white12, thickness: 1),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

/// Bright bubbly background with gradient + confetti dots.
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
    final rnd = Random(7); // deterministic
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

  const BrandScaffold({super.key, this.appBar, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
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
          )
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}

/// Reusable logo widget with visible fallback + debug print.
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
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

/// ===== Screens =====

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
                // Enlarged logo (per your request)
                const NatterLogo(height: 170),
                const SizedBox(height: 12),
                const Text(
                  'Playful, safe messaging for kids.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, height: 1.3),
                ),
                const SizedBox(height: 18),
                const BrandCard(
                  child: Text(
                    'Text-only chats • Kinder words • Parent controls',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16, height: 1.3),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, calmRoute(const RiteScreen())),
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
                    style: TextStyle(color: Colors.white, fontSize: 22, height: 1.25),
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
                    decoration: const InputDecoration(hintText: 'Enter your name'),
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

/// ===== Ceremony / Badge =====
class NatterBadge {
  final String title;
  final IconData icon;
  final Color color;

  const NatterBadge({required this.title, required this.icon, required this.color});
}

NatterBadge badgeForPromises(Set<String> promises) {
  return const NatterBadge(
    title: 'Promise Keeper',
    icon: Icons.shield_rounded,
    color: NatterBrand.yellow,
  );
}

class BadgeCard extends StatelessWidget {
  final String name;
  final NatterBadge badge;

  const BadgeCard({super.key, required this.name, required this.badge});

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
                  'Awarded to $name',
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

/// Promise screen + seal -> dialog ceremony (avoids grey-box overlay bugs).
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

  Future<void> _sealAndShowCeremony() async {
    final state = AppStateScope.of(context);
    final promises = selected.toList();

    state.recordRite(name: widget.name, promises: promises);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (_) {
        return _CeremonyDialog(
          name: widget.name,
          promises: promises,
          onClose: () => Navigator.of(context).pop(),
          onEnter: () {
            Navigator.of(context).pop(); // close dialog
            Navigator.pushReplacement(context, calmRoute(const ChatsScreen()));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = 3 - selected.length;
    final canContinue = selected.length >= 3;

    return BrandScaffold(
      appBar: AppBar(title: const BrandedAppBarTitle(title: 'Your promises')),
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
                  canContinue ? 'Nice. That’s your promise set.' : 'Choose $remaining more',
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
                    onPressed: canContinue ? _sealAndShowCeremony : null,
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

class _CeremonyDialog extends StatelessWidget {
  final String name;
  final List<String> promises;
  final VoidCallback onEnter;
  final VoidCallback onClose;

  const _CeremonyDialog({
    required this.name,
    required this.promises,
    required this.onEnter,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final badge = badgeForPromises(promises.toSet());

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          // Ceremony card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.68),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: CeremonialGraduation(
              name: name,
              promises: promises,
              badge: badge,
              onEnter: onEnter,
            ),
          ),

          // X close
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              tooltip: 'Close',
            ),
          ),
        ],
      ),
    );
  }
}

class CeremonialGraduation extends StatefulWidget {
  final String name;
  final List<String> promises;
  final NatterBadge badge;
  final VoidCallback onEnter;

  const CeremonialGraduation({
    super.key,
    required this.name,
    required this.promises,
    required this.badge,
    required this.onEnter,
  });

  @override
  State<CeremonialGraduation> createState() => _CeremonialGraduationState();
}

class _CeremonialGraduationState extends State<CeremonialGraduation> with TickerProviderStateMixin {
  late final AnimationController _reveal;
  late final Animation<double> _fade;
  late final Animation<double> _badgeDrop;

  late final AnimationController _breath;
  late final Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();

    _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fade = CurvedAnimation(parent: _reveal, curve: Curves.easeInOut);
    _badgeDrop = CurvedAnimation(parent: _reveal, curve: Curves.easeOutBack);

    _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _breathAnim = CurvedAnimation(parent: _breath, curve: Curves.easeInOut);

    _reveal.forward();
  }

  @override
  void dispose() {
    _reveal.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Breathing glow
          IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_fade, _breathAnim]),
              builder: (_, __) {
                final intensity = (0.70 + 0.30 * _breathAnim.value) * _fade.value;
                return Container(
                  width: 560,
                  height: 560,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        badge.color.withOpacity(0.20 * intensity),
                        NatterBrand.pink.withOpacity(0.10 * intensity),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.42, 0.78],
                    ),
                  ),
                );
              },
            ),
          ),

          // Twinkles
          IgnorePointer(
            child: Positioned.fill(
              child: CustomPaint(
                painter: _TwinklePainter(
                  strengthListenable: Listenable.merge([_fade, _breathAnim]),
                  strength: () => _fade.value * (0.7 + 0.3 * _breathAnim.value),
                ),
              ),
            ),
          ),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fade,
                  child: Text(
                    'Welcome to Natter',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.80),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                FadeTransition(
                  opacity: _fade,
                  child: Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                FadeTransition(
                  opacity: _fade,
                  child: Text(
                    'These are the promises you chose:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                FadeTransition(
                  opacity: _fade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: widget.promises.map((p) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withOpacity(0.22)),
                          ),
                          child: Text(
                            p,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 22),

                AnimatedBuilder(
                  animation: _badgeDrop,
                  builder: (_, __) {
                    final t = _badgeDrop.value;
                    return Transform.translate(
                      offset: Offset(0, (1 - t) * -18),
                      child: Opacity(
                        opacity: _fade.value,
                        child: BadgeCard(name: widget.name, badge: badge),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),

                FadeTransition(
                  opacity: _fade,
                  child: Text(
                    "You're officially in. 🌿",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: NatterBrand.green.withOpacity(0.95),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                FadeTransition(
                  opacity: _fade,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onEnter,
                      child: const Text('Enter Natter ✨'),
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

class _TwinklePainter extends CustomPainter {
  final Listenable strengthListenable;
  final double Function() strength;

  _TwinklePainter({required this.strengthListenable, required this.strength}) : super(repaint: strengthListenable);

  @override
  void paint(Canvas canvas, Size size) {
    final s = strength().clamp(0.0, 1.0);
    final rnd = Random(12);
    final paint = Paint()..color = Colors.white.withOpacity(0.14 * s);

    for (int i = 0; i < 28; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = (1.0 + rnd.nextDouble() * 2.4) * (0.7 + 0.3 * s);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TwinklePainter oldDelegate) => true;
}

/// ===== Chats / Chat =====

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    final chats = state.approvedContacts
        .map((name) => ChatPreview(
              name: name,
              last: name == 'Dad' ? 'Dinner at 6 😊' : 'Say hi 👋',
              unread: name == 'Dad' || name == 'Sam',
            ))
        .toList();

    final parentBadgeCount = state.pendingRequests.length + state.alerts.length;

    return BrandScaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Chats'),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context, calmRoute(const ParentHomeScreen())),
            child: Row(
              children: [
                const Text('Parent', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                if (parentBadgeCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: NatterBrand.yellow,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      parentBadgeCount.toString(),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: chats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final c = chats[i];
          return BrandCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: NatterBrand.yellow.withOpacity(0.35),
                child: Text(
                  c.name.substring(0, 1),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
              title: Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              subtitle: Text(
                c.last,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: c.unread
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: NatterBrand.green, borderRadius: BorderRadius.circular(99)),
                    )
                  : const Icon(Icons.chevron_right, color: Colors.white),
              onTap: () => Navigator.push(context, calmRoute(ChatScreen(contactName: c.name))),
            ),
          );
        },
      ),
    );
  }
}

class ChatPreview {
  final String name;
  final String last;
  final bool unread;

  const ChatPreview({required this.name, required this.last, required this.unread});
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

  bool _blockedWord(String text) {
    final lower = text.toLowerCase();
    return lower.contains('badword') || lower.contains('swear');
  }

  void _send() async {
    final state = AppStateScope.of(context);
    final text = controller.text.trim();
    if (text.isEmpty) return;

    // Quiet hours check
    if (state.isQuietNow()) {
      setState(() => feedback = "Quiet Hours are on — we’ll chat again later 🌙");
      controller.clear();

      if (state.alertsQuietHours) {
        state.addAlert(AlertEvent(
          type: AlertType.quietHours,
          message: 'Message attempt during Quiet Hours (to ${widget.contactName}).',
        ));
      }
      return;
    }

    // Bad word check
    if (_blockedWord(text)) {
      setState(() => feedback = "Oops—those words aren’t allowed on Natter.");
      controller.clear();

      if (state.alertsBlockedWord) {
        state.addAlert(AlertEvent(
          type: AlertType.blockedWord,
          message: 'Blocked-word attempt in chat with ${widget.contactName}.',
        ));
      }
      return;
    }

    setState(() {
      feedback = null;
      messages.insert(0, _Msg(fromMe: true, text: text));
    });
    controller.clear();

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => messages.insert(0, _Msg(fromMe: false, text: 'Nice! 😄')));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final quiet = state.isQuietNow();

    return BrandScaffold(
      appBar: AppBar(title: BrandedAppBarTitle(title: widget.contactName)),
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(14),
              itemCount: messages.length,
              itemBuilder: (_, i) => _Bubble(msg: messages[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(hintText: 'Type a message'),
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

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final ap = t.period == DayPeriod.am ? 'am' : 'pm';
    return '$h:$m$ap';
  }
}

class _Msg {
  final bool fromMe;
  final String text;
  _Msg({required this.fromMe, required this.text});
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final align = msg.fromMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = msg.fromMe ? NatterBrand.blue.withOpacity(0.95) : Colors.white.withOpacity(0.20);

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// ===== Parent screens =====

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final hasRite = state.lastName != null && state.lastPromises.isNotEmpty && state.lastBadge != null;

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
            child: const Text('Clear Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 6),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'At a glance',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatTile(label: 'Approved', value: state.approvedContacts.length.toString()),
                    _StatTile(label: 'Pending', value: state.pendingRequests.length.toString()),
                    _StatTile(label: 'Quiet Hours', value: state.quietHoursEnabled ? 'ON' : 'OFF'),
                    _StatTile(label: 'Alerts', value: state.alerts.length.toString()),
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
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${state.lastName} earned:',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  BadgeCard(name: state.lastName!, badge: state.lastBadge!),
                  const SizedBox(height: 12),
                  Text(
                    'Promises:',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: state.lastPromises
                        .map((p) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white.withOpacity(0.18)),
                              ),
                              child: Text(
                                p,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                              ),
                            ))
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
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, calmRoute(const ParentContactsScreen())),
                  style: ElevatedButton.styleFrom(backgroundColor: NatterBrand.green, foregroundColor: Colors.black),
                  child: Text('Contacts (${state.pendingRequests.length} pending)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, calmRoute(const ParentRulesScreen())),
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
                  'Recent Alerts (no message reading)',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                if (state.alerts.isEmpty)
                  Text(
                    'No alerts right now.',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700),
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
  const _StatTile({required this.label, required this.value});

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
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pending requests', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 10),
                if (state.pendingRequests.isEmpty)
                  Text('None right now.', style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700))
                else
                  ...state.pendingRequests.map((name) {
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
                            CircleAvatar(
                              backgroundColor: NatterBrand.yellow.withOpacity(0.35),
                              child: Text(name.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
                              child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
                              child: const Text('Block', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
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
                const Text('Approved contacts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: state.approvedContacts
                      .map((n) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white.withOpacity(0.16)),
                            ),
                            child: Text(n, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          ))
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
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quiet Hours', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: state.quietHoursEnabled,
                  onChanged: state.setQuietEnabled,
                  title: const Text('Enable Quiet Hours', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
                          final picked = await showTimePicker(context: context, initialTime: state.quietStart);
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
                          final picked = await showTimePicker(context: context, initialTime: state.quietEnd);
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
                const Text('Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: state.alertsBlockedWord,
                  onChanged: (v) => state.setAlerts(blockedWord: v),
                  title: const Text('Blocked-word attempts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  subtitle: Text('Parents get an alert when a message is blocked.', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                ),
                SwitchListTile(
                  value: state.alertsQuietHours,
                  onChanged: (v) => state.setAlerts(quietHours: v),
                  title: const Text('Quiet Hours attempts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  subtitle: Text('Parents get an alert if kids try to message during Quiet Hours.', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                ),
                SwitchListTile(
                  value: state.alertsContactRequest,
                  onChanged: (v) => state.setAlerts(contactRequest: v),
                  title: const Text('Contact events', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  subtitle: Text('Alerts when a request is approved/blocked (demo).', style: TextStyle(color: Colors.white.withOpacity(0.8))),
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

  const _TimeButton({required this.label, required this.time, required this.onPick});

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(txt, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }
}
