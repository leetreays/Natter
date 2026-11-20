import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natter/avatar/brim_avatar_selection.dart';

/// A build-level regression check: the 27 approved images must actually be
/// packaged by Flutter, not merely represented by valid selection keys.
///
/// This intentionally reads the asset bundle rather than the filesystem,
/// making it useful on a fresh checkout and in CI without Python/Pillow.
void main() {
  testWidgets('Flutter packages all 27 approved Brim WebP assets', (
    tester,
  ) async {
    final loadedKeys = <String>{};

    for (final colour in BrimColourway.values) {
      for (final expression in BrimExpression.values) {
        for (final accessory in BrimAccessory.values) {
          final selection = BrimAvatarSelection(
            colourway: colour,
            expression: expression,
            accessory: accessory,
          );
          final path =
              'assets/avatar_prototype/${selection.artworkKey}.webp';
          expect(loadedKeys.add(path), isTrue, reason: 'Duplicate: $path');

          final ByteData data = await rootBundle.load(path);
          expect(data.lengthInBytes, greaterThan(1000), reason: path);
          final bytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
          expect(
            String.fromCharCodes(bytes.sublist(0, 4)),
            'RIFF',
            reason: path,
          );
          expect(
            String.fromCharCodes(bytes.sublist(8, 12)),
            'WEBP',
            reason: path,
          );
          expect(
            data.getUint32(4, Endian.little),
            bytes.length - 8,
            reason: 'RIFF length mismatch: $path',
          );
        }
      }
    }
    expect(loadedKeys, hasLength(27));
  });
}
