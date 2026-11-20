import 'package:flutter/material.dart';

import '../main.dart' show NatterChildTheme;
import 'brim_avatar_selection.dart';

/// Reusable Brim renderer shared by the isolated lab and future identity UI.
///
/// It displays complete, vetted WebP illustrations with the same 48px crop
/// and instant-switch behaviour that passed on-device visual review.
/// It does not save data, fetch Firestore, or change other users' identity.
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
      // Crop the same complete artwork to prioritise facial recognition at 48px.
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
          scale: 1.55,
          alignment: const Alignment(0.7, -0.72),
          child: Image.asset(
            assetPath,
            key: ValueKey(selection.artworkKey),
            width: dimension,
            height: dimension,
            fit: BoxFit.contain,
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
