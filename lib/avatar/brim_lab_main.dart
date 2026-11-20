import 'dart:async';

import 'package:flutter/material.dart';
import '../main.dart'
    show
        NatterBrand,
        NatterChildBackground,
        NatterChildPrimaryButton,
        NatterChildSurface,
        NatterChildSurfaceStyle,
        NatterChildTheme;
import 'brim_avatar_selection.dart';
import 'brim_art_preview.dart';

// Preserve existing lab test imports; production screens should import the
// reusable widget directly from brim_art_preview.dart.
export 'brim_art_preview.dart' show BrimArtPreview;

/// An isolated feasibility lab, not an entry point in the production app.
///
/// Launch using:
/// flutter run -t lib/avatar/brim_lab_main.dart -d web-server
///
/// Do not make this a child-facing route or save anything to Firestore before
/// the actual character artwork passes the quality gate.
void main() => runApp(const BrimPrototypeApp());

class BrimPrototypeApp extends StatelessWidget {
  const BrimPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Natter • Brim Lab',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'NatterNunito',
        scaffoldBackgroundColor: NatterChildTheme.background,
        colorScheme: const ColorScheme.dark(
          primary: NatterBrand.blue,
          secondary: NatterBrand.green,
          surface: NatterChildTheme.surface,
        ),
      ),
      home: const BrimAvatarLabScreen(),
    );
  }
}

class BrimAvatarLabScreen extends StatefulWidget {
  const BrimAvatarLabScreen({super.key});

  @override
  State<BrimAvatarLabScreen> createState() => _BrimAvatarLabScreenState();
}

class _BrimAvatarLabScreenState extends State<BrimAvatarLabScreen> {
  BrimAvatarSelection _selection = const BrimAvatarSelection();
  bool _showPreviewOnlyFeedback = false;
  bool _candidateArtPrecacheStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_candidateArtPrecacheStarted) return;
    _candidateArtPrecacheStarted = true;

    // All 27 candidates are present after local artwork generation. Before
    // installation, unavailable assets still use the lab's honest placeholder.
    final candidateArtwork = <String>[
      for (final colour in const ['violet', 'blue', 'mint'])
        for (final expression in const ['gentle', 'playful', 'cheeky'])
          for (final accessory in const ['none', 'scarf', 'satchel'])
            'brim_v1_${colour}_${expression}_$accessory',
    ];

    for (final artworkKey in candidateArtwork) {
      unawaited(
        precacheImage(
          AssetImage('assets/avatar_prototype/$artworkKey.webp'),
          context,
          onError: (Object error, StackTrace? trace) {},
        ),
      );
    }
  }

  static const _colourNames = {
    BrimColourway.violet: 'Violet',
    BrimColourway.blue: 'Blue',
    BrimColourway.mint: 'Mint',
  };
  static const _colourSwatches = {
    BrimColourway.violet: NatterBrand.purple,
    BrimColourway.blue: NatterBrand.blue,
    BrimColourway.mint: Color(0xFF64D9BB),
  };
  static const _expressionNames = {
    BrimExpression.gentle: 'Friendly',
    BrimExpression.playful: 'Playful',
    BrimExpression.cheeky: 'Cheeky',
  };
  static const _accessoryNames = {
    BrimAccessory.none: 'None',
    BrimAccessory.scarf: 'Scarf',
    BrimAccessory.satchel: 'Satchel',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NatterChildTheme.background,
      body: Stack(
        children: [
          const Positioned.fill(child: NatterChildBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                NatterChildTheme.screenHorizontalPadding,
                12,
                NatterChildTheme.screenHorizontalPadding,
                NatterChildTheme.screenBottomPadding,
              ),
              children: [
                Row(
                  children: [
                    Image.asset(NatterBrand.logoPath, height: 34),
                    const Spacer(),
                    const Text(
                      'AVATAR LAB',
                      style: TextStyle(
                        color: NatterChildTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Make Brim your own',
                  style: NatterChildTheme.screenTitle,
                ),
                const SizedBox(height: 8),
                const Text(
                  'An early interactive test of Natter character choices.',
                  style: NatterChildTheme.screenSubtitle,
                ),
                const SizedBox(height: 20),
                NatterChildSurface(
                  style: NatterChildSurfaceStyle.hero,
                  child: Column(
                    children: [
                      const Text(
                        'Your character',
                        style: NatterChildTheme.sectionTitle,
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        label:
                            'Brim preview, ${_colourNames[_selection.colourway]}, '
                            '${_expressionNames[_selection.expression]}, '
                            '${_accessoryNames[_selection.accessory]}',
                        child: SizedBox(
                          width: double.infinity,
                          height: 232,
                          child: BrimArtPreview(
                            key: const Key('brim-hero'),
                            selection: _selection,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Chat icon preview',
                        style: NatterChildTheme.caption,
                      ),
                      const SizedBox(height: 8),
                      BrimArtPreview(
                        key: const Key('brim-chat-preview'),
                        selection: _selection,
                        compact: true,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Behind every character is a real person.',
                        style: NatterChildTheme.body,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _choiceSection(
                  title: 'Colour',
                  subtitle: 'Choose a look for Brim',
                  children: BrimColourway.values.map((colour) {
                    final selected = _selection.colourway == colour;
                    return _option(
                      key: Key('colour-${colour.id}'),
                      selected: selected,
                      label: _colourNames[colour]!,
                      icon: Icons.circle,
                      iconColor: _colourSwatches[colour]!,
                      onTap: () => setState(() {
                        _selection = _selection.copyWith(colourway: colour);
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _choiceSection(
                  title: 'Expression',
                  subtitle: 'Choose Brim’s expression',
                  children: BrimExpression.values.map((expression) {
                    return _option(
                      key: Key('expression-${expression.id}'),
                      selected: _selection.expression == expression,
                      label: _expressionNames[expression]!,
                      icon: switch (expression) {
                        BrimExpression.gentle =>
                          Icons.sentiment_satisfied_rounded,
                        BrimExpression.playful =>
                          Icons.sentiment_very_satisfied_rounded,
                        BrimExpression.cheeky => Icons.mood_rounded,
                      },
                      iconColor: NatterChildTheme.textPrimary,
                      onTap: () => setState(() {
                        _selection = _selection.copyWith(
                          expression: expression,
                        );
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _choiceSection(
                  title: 'Accessory',
                  subtitle: 'Choose an optional detail',
                  children: BrimAccessory.values.map((accessory) {
                    return _option(
                      key: Key('accessory-${accessory.id}'),
                      selected: _selection.accessory == accessory,
                      label: _accessoryNames[accessory]!,
                      icon: switch (accessory) {
                        BrimAccessory.none => Icons.close_rounded,
                        BrimAccessory.scarf => Icons.checkroom_rounded,
                        BrimAccessory.satchel => Icons.work_outline_rounded,
                      },
                      iconColor: NatterChildTheme.textPrimary,
                      onTap: () => setState(() {
                        _selection = _selection.copyWith(accessory: accessory);
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                NatterChildSurface(
                  style: NatterChildSurfaceStyle.quiet,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prototype status — no avatar is saved',
                        style: NatterChildTheme.bodyStrong,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Violet has nine reviewed combinations. Blue and Mint '
                        'are reference-based artwork trials, pending your visual '
                        'review of all expressions and accessories. Nothing is '
                        'saved to your account.',
                        style: NatterChildTheme.caption,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selection.artworkKey,
                        key: const Key('brim-state-key'),
                        style: NatterChildTheme.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                NatterChildPrimaryButton(
                  key: const Key('brim-preview-action'),
                  label: _showPreviewOnlyFeedback
                      ? 'Preview only — not saved'
                      : 'Try this look',
                  icon: _showPreviewOnlyFeedback
                      ? Icons.info_outline_rounded
                      : Icons.check_rounded,
                  onPressed: () {
                    // Keep feedback on the button itself, where the child taps.
                    // This isolated lab never saves to an account.
                    setState(() => _showPreviewOnlyFeedback = true);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceSection({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return NatterChildSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: NatterChildTheme.sectionTitle),
          const SizedBox(height: 3),
          Text(subtitle, style: NatterChildTheme.caption),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }

  Widget _option({
    required Key key,
    required bool selected,
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minWidth: 82, minHeight: 80),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? NatterChildTheme.connect.withValues(alpha: 0.15)
                  : NatterChildTheme.surfaceQuiet,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? NatterChildTheme.connect
                    : NatterChildTheme.borderStrong,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 26),
                const SizedBox(height: 8),
                Text(label, style: NatterChildTheme.bodyStrong),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
