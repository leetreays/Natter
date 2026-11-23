import 'dart:async';

import 'package:flutter/material.dart';
import '../main.dart' show NatterBrand, NatterChildBackground;

void main() => runApp(const ZeevPrototypeApp());

/// Isolated Zeev artwork trial. This deliberately does not modify a child's
/// profile, write to Firestore, or affect any production avatar selection.
class ZeevPrototypeApp extends StatelessWidget {
  const ZeevPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Natter • Zeev Lab',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'NatterNunito',
      scaffoldBackgroundColor: const Color(0xFF071A39),
    ),
    home: const ZeevAvatarLabScreen(),
  );
}

enum ZeevExpression { friendly, playful, cheeky }
enum ZeevAccessory { none, scarf, satchel }

class ZeevAvatarLabScreen extends StatefulWidget {
  const ZeevAvatarLabScreen({super.key});

  @override
  State<ZeevAvatarLabScreen> createState() => _ZeevAvatarLabScreenState();
}

class _ZeevAvatarLabScreenState extends State<ZeevAvatarLabScreen> {
  ZeevExpression expression = ZeevExpression.friendly;
  ZeevAccessory accessory = ZeevAccessory.none;
  bool _precacheStarted = false;

  String get artworkKey =>
      'zeev_v1_blue_${expression.name}_${accessory.name}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precacheStarted) return;
    _precacheStarted = true;
    for (final face in ZeevExpression.values) {
      for (final item in ZeevAccessory.values) {
        unawaited(
          precacheImage(
            AssetImage(
              'assets/avatar_prototype/zeev_v1_blue_${face.name}_${item.name}.webp',
            ),
            context,
            onError: (Object error, StackTrace? stackTrace) {},
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081934),
      body: Stack(
        children: [
          const Positioned.fill(child: NatterChildBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
              children: [
                Row(
                  children: [
                    Image.asset(NatterBrand.logoPath, height: 34),
                    const Spacer(),
                    const Text(
                      'AVATAR LAB',
                      style: TextStyle(
                        color: Color(0xFFBCCBE5),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Make Zeev your own',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Blue artwork trial • three expressions and three accessories.',
                  style: TextStyle(
                    color: Color(0xFFBCD1E9),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  key: const Key('zeev-hero'),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xD91B395E),
                    border: Border.all(color: const Color(0xFF426389)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your character',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ZeevArtPreview(
                        key: const Key('zeev-hero-preview'),
                        artworkKey: artworkKey,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Chat icon preview',
                        style: TextStyle(color: Color(0xFFB9CEE7)),
                      ),
                      const SizedBox(height: 9),
                      ZeevArtPreview(
                        key: const Key('zeev-chat-preview'),
                        artworkKey: artworkKey,
                        compact: true,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Behind every character is a real person.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _section(
                  'Colour',
                  'Blue is the approved master colourway.',
                  [
                    _option(
                      label: 'Blue',
                      keyName: 'zeev-colour-blue',
                      selected: true,
                      onTap: () {},
                      glyph: Icons.water_drop_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _section(
                  'Expression',
                  'Choose Zeev’s expression',
                  [
                    for (final face in ZeevExpression.values)
                      _option(
                        label: _label(face.name),
                        keyName: 'zeev-expression-${face.name}',
                        selected: expression == face,
                        glyph: switch (face) {
                          ZeevExpression.friendly => Icons.sentiment_satisfied_rounded,
                          ZeevExpression.playful => Icons.sentiment_very_satisfied_rounded,
                          ZeevExpression.cheeky => Icons.mood_rounded,
                        },
                        onTap: () => setState(() => expression = face),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _section(
                  'Accessory',
                  'Choose an optional extra',
                  [
                    for (final item in ZeevAccessory.values)
                      _option(
                        label: _label(item.name),
                        keyName: 'zeev-accessory-${item.name}',
                        selected: accessory == item,
                        glyph: switch (item) {
                          ZeevAccessory.none => Icons.block_rounded,
                          ZeevAccessory.scarf => Icons.checkroom_rounded,
                          ZeevAccessory.satchel => Icons.work_outline_rounded,
                        },
                        onTap: () => setState(() => accessory = item),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xDD132843),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preview only — not saved',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Zeev Blue is a local artwork test. Nothing here '
                        'changes a child’s account or their friendships.',
                        style: TextStyle(color: Color(0xFFBED0E6)),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        artworkKey,
                        key: const Key('zeev-state-key'),
                        style: const TextStyle(
                          color: Color(0xFF89D8FF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _label(String name) =>
      name[0].toUpperCase() + name.substring(1);

  Widget _section(String title, String subtitle, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xDE112642),
        border: Border.all(color: const Color(0xFF344969)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFFB8C8E0)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final child in children)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: child,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _option({
    required String label,
    required String keyName,
    required bool selected,
    required VoidCallback onTap,
    required IconData glyph,
  }) {
    return Material(
      color: selected ? const Color(0xFF234768) : const Color(0xFF101E35),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key(keyName),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? const Color(0xFF48B7FF) : const Color(0xFF40506D),
              width: selected ? 2.4 : 1.1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(glyph, color: const Color(0xFFD9EEFF), size: 25),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reuses complete 512px WebP art, not an on-device accessory stack.
/// This is the first avatar whose head points viewer-left, so its compact
/// crop is different to Brim's. Never crossfade whole images when switching.
class ZeevArtPreview extends StatelessWidget {
  const ZeevArtPreview({
    super.key,
    required this.artworkKey,
    this.compact = false,
  });

  final String artworkKey;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final assetPath = 'assets/avatar_prototype/$artworkKey.webp';
    final image = Image.asset(
      assetPath,
      key: ValueKey(artworkKey),
      height: compact ? 48 : 220,
      width: compact ? 48 : 220,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Icon(
          Icons.image_outlined,
          color: const Color(0xFF56B8FF),
          size: compact ? 16 : 48,
        ),
      ),
    );
    if (compact) {
      return Center(
        child: Container(
          width: 48,
          height: 48,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF112947),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF459CCF)),
          ),
          child: Transform.scale(
            scale: 2.25,
            alignment: const Alignment(-0.44, -0.55),
            child: image,
          ),
        ),
      );
    }
    return SizedBox(height: 220, child: Center(child: image));
  }
}
