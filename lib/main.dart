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

class NatterBrand {
  static const blue = Color(0xFF3DA6F3);
  static const green = Color(0xFFA4D35A);
  static const yellow = Color(0xFFFBC02D);
  static const pink = Color(0xFFFF5DA2);

  static const navy = Color(0xFF06112E);
  static const radius = 24.0;

  static const logoPath = 'assets/natter-logo-v2.png';
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

class NatterApp extends StatelessWidget {
  const NatterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light();

    return MaterialApp(
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
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
      body: BubblyBackground(
        child: SafeArea(child: child),
      ),
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
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(NatterBrand.radius),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 12),
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
                const NatterLogo(height: 120),
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

    await Future.delayed(const Duration(milliseconds: 650));
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
        color: Colors.white.withOpacity(0.10),
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

class PromiseScreen extends StatefulWidget {
  final String name;
  const PromiseScreen({super.key, required this.name});

  @override
  State<PromiseScreen> createState() => _PromiseScreenState();
}

class _PromiseScreenState extends State<PromiseScreen> with TickerProviderStateMixin {
  final options = const [
    'Be kind',
    'No secrets from adults',
    'If it feels weird, stop',
    'Ask before adding friends',
    'Keep it text-only',
    'Take breaks',
  ];

  final Set<String> selected = {};
  bool showGraduation = false;

  late final AnimationController fadeController;
  late final Animation<double> fadeAnim;

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    fadeAnim = CurvedAnimation(parent: fadeController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    fadeController.dispose();
    super.dispose();
  }

  Future<void> _graduate() async {
    setState(() => showGraduation = true);
    await fadeController.forward();
  }

  void _closeOverlay() {
    setState(() => showGraduation = false);
    fadeController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = 3 - selected.length;
    final canContinue = selected.length >= 3;

    return Scaffold(
      appBar: AppBar(title: const BrandedAppBarTitle(title: 'Your promises')),
      body: BubblyBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      children: [
                        BrandCard(
                          child: Column(
                            children: [
                              Text(
                                'Okay, ${widget.name} 😊',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pick 3 promises for your Natter life:',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

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

                        const SizedBox(height: 14),
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
                            onPressed: canContinue ? _graduate : null,
                            child: const Text('Seal My Promises ✨'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ✅ Overlay that ALWAYS renders (no Positioned.fill inside scroll content)
              if (showGraduation)
                Positioned.fill(
                  child: FadeTransition(
                    opacity: fadeAnim,
                    child: Material(
                      color: Colors.black.withOpacity(0.70),
                      child: SafeArea(
                        child: Stack(
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 760),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: CeremonialGraduation(
                                    name: widget.name,
                                    promises: selected.toList(),
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
                            Positioned(
                              top: 6,
                              right: 6,
                              child: IconButton(
                                tooltip: 'Close',
                                icon: const Icon(Icons.close_rounded, color: Colors.white),
                                onPressed: _closeOverlay,
                              ),
                            ),
                          ],
                        ),
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

/// ✅ This version uses fixed-size glow/twinkles so it never disappears on web.
class CeremonialGraduation extends StatefulWidget {
  final String name;
  final List<String> promises;
  final VoidCallback onEnter;

  const CeremonialGraduation({
    super.key,
    required this.name,
    required this.promises,
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

    _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
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
    final badge = badgeForPromises(widget.promises.toSet());

    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow + twinkles behind (FIXED SIZE)
        SizedBox(
          width: 560,
          height: 560,
          child: AnimatedBuilder(
            animation: Listenable.merge([_fade, _breathAnim]),
            builder: (_, __) {
              final intensity = (0.70 + 0.30 * _breathAnim.value) * _fade.value;
              return CustomPaint(
                painter: _GlowTwinklePainter(
                  badgeColor: badge.color,
                  strength: intensity.clamp(0.0, 1.0),
                ),
              );
            },
          ),
        ),

        // Foreground ceremony card
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.34), // was ~0.20 via BrandCard
    borderRadius: BorderRadius.circular(NatterBrand.radius),
    border: Border.all(color: Colors.white.withOpacity(0.28)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.22),
        blurRadius: 20,
        offset: const Offset(0, 14),
      ),
    ],
  ),
  padding: const EdgeInsets.all(18),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // ... keep the existing ceremony children exactly as-is
    ],
  ),
),
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _fade,
                  child: Text(
                    'Welcome to Natter',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
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
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _fade,
                  child: Text(
                    'These are your promises:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
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
                            color: Colors.white.withOpacity(0.10),
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

                const SizedBox(height: 18),

                AnimatedBuilder(
                  animation: _badgeDrop,
                  builder: (_, __) {
                    final t = _badgeDrop.value;
                    return Transform.translate(
                      offset: Offset(0, (1 - t) * -16),
                      child: Opacity(
                        opacity: _fade.value,
                        child: BadgeCard(name: widget.name, badge: badge),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

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

                const SizedBox(height: 18),

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
        ),
      ],
    );
  }
}

/// Paints a soft radial glow + subtle twinkles (fixed canvas size).
class _GlowTwinklePainter extends CustomPainter {
  final Color badgeColor;
  final double strength;

  _GlowTwinklePainter({required this.badgeColor, required this.strength});

  @override
  void paint(Canvas canvas, Size size) {
    final s = strength.clamp(0.0, 1.0);

    // Glow
    final center = Offset(size.width / 2, size.height / 2);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          badgeColor.withOpacity(0.20 * s),
          NatterBrand.pink.withOpacity(0.10 * s),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.80],
      ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide * 0.5));

    canvas.drawCircle(center, size.shortestSide * 0.5, glowPaint);

    // Twinkles
    final rnd = Random(12);
    final twinklePaint = Paint()..color = Colors.white.withOpacity(0.14 * s);

    for (int i = 0; i < 30; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = (1.0 + rnd.nextDouble() * 2.2) * (0.6 + 0.4 * s);
      canvas.drawCircle(Offset(dx, dy), r, twinklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowTwinklePainter oldDelegate) {
    return oldDelegate.strength != strength || oldDelegate.badgeColor != badgeColor;
  }
}

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const chats = <ChatPreview>[
      ChatPreview(name: 'Sam', last: 'See you after school!', unread: true),
      ChatPreview(name: 'Mia', last: 'Want to play later?', unread: false),
      ChatPreview(name: 'Dad', last: 'Dinner at 6 😊', unread: true),
    ];

    return BrandScaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Chats'),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context, calmRoute(const ParentScreen())),
            child: const Text('Parent', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
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
              title: Text(
                c.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
              ),
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
                      decoration: BoxDecoration(
                        color: NatterBrand.green,
                        borderRadius: BorderRadius.circular(99),
                      ),
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

  bool _blocked(String text) {
    final lower = text.toLowerCase();
    return lower.contains('badword') || lower.contains('swear');
  }

  void _send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    if (_blocked(text)) {
      setState(() => feedback = "Oops—those words aren’t allowed on Natter.");
      controller.clear();
      return;
    }

    setState(() {
      feedback = null;
      messages.insert(0, _Msg(fromMe: true, text: text));
    });
    controller.clear();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      messages.insert(0, _Msg(fromMe: false, text: 'Nice! 😄'));
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BrandScaffold(
      appBar: AppBar(title: BrandedAppBarTitle(title: widget.contactName)),
      child: Column(
        children: [
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

class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandScaffold(
      appBar: AppBar(title: const BrandedAppBarTitle(title: 'Parent Controls')),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BrandCard(
              child: Text(
                'This is a placeholder.\nNext we’ll add:\n• Approve contacts\n• Chat hours\n• Alerts (without reading messages)',
                style: TextStyle(color: Colors.white, fontSize: 16, height: 1.35, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}
