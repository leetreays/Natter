import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const NatterApp());

class NatterBrand {
  static const blue = Color(0xFF3DA6F3);
  static const green = Color(0xFFA4D35A);
  static const yellow = Color(0xFFFBC02D);
  static const pink = Color(0xFFFF5DA2);

  static const navy = Color(0xFF06112E);
  static const radius = 24.0;
}

class ChatPreview {
  final String name;
  final String last;
  final bool unread;

  const ChatPreview({required this.name, required this.last, required this.unread});
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
                Color(0xFF2B7FFF), // pop blue
                Color(0xFF133A8A), // bright deep blue
                Color(0xFF06112E), // navy
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

class BrandedAppBarTitle extends StatelessWidget {
  final String title;
  const BrandedAppBarTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 22,
          width: 22,
          child: Image.asset('assets/natter-logo.png', fit: BoxFit.contain),
        ),
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
                SizedBox(
                  height: 120,
                  child: Image.asset('assets/natter-logo.png', fit: BoxFit.contain),
                ),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RiteScreen()),
                      );
                    },
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PromiseScreen(name: name)),
    );
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
                    child: ElevatedButton(onPressed: _continue, child: const Text('Continue')),
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
            constraints: const BoxConstraints(maxWidth: 700),
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
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
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
                const Spacer(),
                Text(
                  canContinue ? 'Nice. That’s your promise set.' : 'Choose $remaining more',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canContinue
                        ? () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const ChatsScreen()),
                            );
                          }
                        : null,
                    child: const Text('I promise 🤝'),
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
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentScreen()));
            },
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(contactName: c.name)),
                );
              },
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
