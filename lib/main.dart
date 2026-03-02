import 'package:flutter/material.dart';

void main() => runApp(const NatterApp());

class NatterApp extends StatelessWidget {
  const NatterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Natter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Natter',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'A digital rite of passage.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiteScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Begin', style: TextStyle(fontSize: 18)),
            ),
          ],
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

    // playful pacing
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PromiseScreen(name: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Before you enter Natter,\n\nWhat should we call you?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: 'Enter your name'),
                onSubmitted: (_) => _continue(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _continue,
                child: const Text('Continue'),
              ),
            ],
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
    final canContinue = selected.length >= 3;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Okay, ${widget.name} 😊\nPick 3 promises for your Natter life:',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
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
              canContinue
                  ? 'Nice. That’s your promise set.'
                  : 'Choose ${3 - selected.length} more',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: canContinue
                  ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatsScreen()),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              ),
              child: const Text('I promise'),
            ),
            const SizedBox(height: 16),
          ],
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ParentScreen()),
              );
            },
            child: const Text('Parent', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: ListView.separated(
        itemCount: chats.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final c = chats[i];
          return ListTile(
            title: Text(c['name']!),
            subtitle: Text(c['last']!, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(contactName: c['name']!),
                ),
              );
            },
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
    // Demo filter (we'll improve later)
    final lower = text.toLowerCase();
    return lower.contains('badword') || lower.contains('swear');
  }

  void _send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    if (_blocked(text)) {
      setState(() {
        feedback = "That message wasn’t sent because it breaks the chat rules.";
      });
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.contactName)),
      body: Column(
        children: [
          if (feedback != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(feedback!, textAlign: TextAlign.center),
            ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (_, i) => ListTile(
                title: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade300,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(messages[i]),
                  ),
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
                    decoration: const InputDecoration(hintText: 'Type a message'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _send, child: const Text('Send')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Controls')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This is a placeholder.\nNext we’ll add:\n• Approve contacts\n• Chat hours\n• Alerts (without reading messages)',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            )
          ],
        ),
      ),
    );
  }
}