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

    // Pre-decode the only TWO candidate illustrations currently installed.
    // Without this, the first switch can briefly show an empty preview.
    // Do not attempt to fetch the 16 unfinished combinations.
    for (final accessory in const ['none', 'scarf']) {
      unawaited(
        precacheImage(
          AssetImage('assets/avatar_prototype/brim_v1_violet_gentle_$accessory.webp'),
          context,
          // Early lab runs do not necessarily have the binary art installed.
          // In that case the existing placeholder remains the source of truth.
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
    BrimExpression.gentle: 'Gentle',
    BrimExpression.delighted: 'Delighted',
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
                      icon: expression == BrimExpression.gentle
                          ? Icons.sentiment_satisfied_rounded
                          : Icons.sentiment_very_satisfied_rounded,
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
                        'Violet + Gentle has two test illustrations: None '
                        'and Scarf. Other combinations still need artwork. '
                        'These previews are not saved to your account.',
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

/// Every preview is requested as a *complete* matching piece of artwork.
///
/// This is intentionally not a Flutter Stack of a scarf and a base creature.
/// An artist will approve fitted complete illustrations or a layered rig
/// before any images are added. Until then the preview exposes the gap.
class BrimArtPreview extends StatelessWidget {
  const BrimArtPreview({
    super.key,
    required this.selection,
    this.compact = false,
  });

  final BrimAvatarSelection selection;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dimension = compact ? 48.0 : 220.0;
    final assetPath = 'assets/avatar_prototype/${selection.artworkKey}.webp';

    if (compact) {
      // A chat icon needs a recognisable face rather than a tiny full body.
      // Crop the SAME complete artwork: no loose scarf/accessory overlays.
      return Container(
        width: dimension,
        height: dimension,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: NatterChildTheme.surfaceQuiet,
          border: Border.all(
            color: NatterChildTheme.connect.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Transform.scale(
          // At 48px, prioritise recognition of the face while allowing
          // a little room for the horns and the scarf. Keep the same
          // anchor for the accessory/no-accessory illustrations.
          scale: 1.55,
          alignment: const Alignment(0.7, -0.72),
          child: Image.asset(
            assetPath,
            // Preserve the Image element when artwork changes: this lets
            // gaplessPlayback keep the old frame until the new one is ready.
            width: dimension,
            height: dimension,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: NatterChildTheme.connect,
                size: 12,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: dimension,
      child: Image.asset(
        assetPath,
        key: ValueKey(selection.artworkKey),
        width: dimension,
        height: dimension,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Container(
          width: dimension,
          height: dimension,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: NatterChildTheme.surfaceQuiet.withValues(alpha: 0.55),
            border: Border.all(color: NatterChildTheme.borderStrong),
          ),
          alignment: Alignment.center,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                color: NatterChildTheme.connect,
                size: 44,
              ),
              SizedBox(height: 12),
              Text(
                'Approved Brim artwork pending',
                style: NatterChildTheme.bodyStrong,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
