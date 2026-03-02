import 'package:flutter/material.dart';

void main() => runApp(const NatterApp());

class NatterBrand {
  static const blue = Color(0xFF3DA6F3);
  static const green = Color(0xFFA4D35A);
  static const yellow = Color(0xFFFBC02D);
  static const pink = Color(0xFFFF6FB1);

  static const dark = Color(0xFF071029);
  static const card = Color(0xFF0E1B3B);

  static const radius = 22.0;
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
        scaffoldBackgroundColor: NatterBrand.dark,
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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: NatterBrand.green,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NatterBrand.radius),
            ),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.10),
          hintStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NatterBrand.radius),
            borderSide: BorderSide.none,
          ),
        ),
        dividerTheme: const DividerThemeData(color: Colors.white12, thickness: 1),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.black.withOpacity(0.85),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: Colors.white.withOpacity(0.10),
          selectedColor: NatterBrand.yellow.withOpacity(0.25),
          labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class GradientScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  const GradientScaffold({super.key, required this.child, this.appBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1C4A),
              Color(0xFF071029),
              Color(0xFF132B6E),
            ],
          ),
        ),
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(NatterBrand.radius),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 110,
                  child: Image.asset(
                    'assets/natter-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Playful, safe messaging for kids.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, height: 1.3),
                ),
                const SizedBox(height: 20),
                const BrandCard(
                  child: Text(
                    'Text-only chats • Kinder words • Parent controls',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.3),
                  ),
                ),
                const SizedBox(height: 22),
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

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PromiseScreen(name: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Your first step'),
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
                    style: const TextStyle(color: Colors.white, fontSize: 18),
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

    return GradientScaffold(
      appBar: AppBar(title: const Text('Your promises')),
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
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pick 3 promises for your Natter life:',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
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
    final chats = const [
      {'name': 'Sam', 'last': 'See you after school!'},
      {'name': 'Mia', 'last': 'Want to play later?'},
      {'name': 'Dad', 'last': 'Dinner at 6 😊'},
    ];

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentScreen()));
            },
            child: const Text('Parent', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: chats.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final c = chats[i];
          return BrandCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                c['name']!,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                c['last']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(contactName: c['name']!)),
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
  final List<String> messages = [];
  String? feedback;

  bool _blocked(String text) {
    final lower = text.toLowerCase();
    return lower.contains('badword') || lower.contains('swear');
  }

  void _send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    if (_blocked(text)) {
      setState(() => feedback = "Oops—those words aren’t allowed on Natter.");
      controller.clear();
      return;
    }

    setState(() {
      feedback = null;
      messages.insert(0, text);
    });
    controller.clear();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: Text(widget.contactName)),
      child: Column(
        children: [
          if (feedback != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                border: Border.all(color: NatterBrand.yellow),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                feedback!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: messages.length,
              itemBuilder: (_, i) => Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: NatterBrand.blue.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(messages[i], style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(hintText: 'Type a message'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _send,
                  style: ElevatedButton.styleFrom(backgroundColor: NatterBrand.green),
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

class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Parent Controls')),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrandCard(
              child: const Text(
                'This is a placeholder.\nNext we’ll add:\n• Approve contacts\n• Chat hours\n• Alerts (without reading messages)',
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.35),
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
