import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natter/avatar/zeev_lab_main.dart';

void main() {
  testWidgets('Zeev lab displays the Blue Friendly default without persistence', (
    tester,
  ) async {
    await tester.pumpWidget(const ZeevPrototypeApp());

    expect(find.text('Make Zeev your own'), findsOneWidget);
    expect(find.byKey(const Key('zeev-hero-preview')), findsOneWidget);
    expect(find.byKey(const Key('zeev-chat-preview')), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('zeev-state-key')),
      180,
    );
    expect(find.text('zeev_v1_blue_friendly_none'), findsOneWidget);
    expect(find.text('Preview only — not saved'), findsOneWidget);
  });

  testWidgets('Zeev expressions and accessories switch without image crossfades', (
    tester,
  ) async {
    await tester.pumpWidget(const ZeevPrototypeApp());

    final playful = find.byKey(const Key('zeev-expression-playful'));
    await tester.scrollUntilVisible(playful, 150);
    await tester.tap(playful);
    await tester.pump();

    final scarf = find.byKey(const Key('zeev-accessory-scarf'));
    await tester.scrollUntilVisible(scarf, 150);
    await tester.tap(scarf);
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const Key('zeev-state-key')),
      150,
    );
    expect(find.text('zeev_v1_blue_playful_scarf'), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsNothing);

    // The live state key is the reliable assertion while the scrollable
    // preview may be offscreen and lazily removed from the widget tree.
    final cheeky = find.byKey(const Key('zeev-expression-cheeky'));
    await tester.scrollUntilVisible(cheeky, 150);
    await tester.tap(cheeky);
    await tester.pump();

    final satchel = find.byKey(const Key('zeev-accessory-satchel'));
    await tester.scrollUntilVisible(satchel, 150);
    await tester.tap(satchel);
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('zeev-state-key')),
      150,
    );
    expect(find.text('zeev_v1_blue_cheeky_satchel'), findsOneWidget);
  });

  testWidgets('both Zeev artwork previews switch as complete images', (
    tester,
  ) async {
    Widget previews(String artworkKey) => MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            ZeevArtPreview(artworkKey: artworkKey),
            ZeevArtPreview(artworkKey: artworkKey, compact: true),
          ],
        ),
      ),
    );
    await tester.pumpWidget(previews('zeev_v1_blue_friendly_none'));
    expect(find.byType(AnimatedSwitcher), findsNothing);
    expect(
      find.byKey(const ValueKey('zeev_v1_blue_friendly_none')),
      findsNWidgets(2),
    );

    await tester.pumpWidget(previews('zeev_v1_blue_cheeky_satchel'));
    expect(find.byType(AnimatedSwitcher), findsNothing);
    expect(
      find.byKey(const ValueKey('zeev_v1_blue_friendly_none')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('zeev_v1_blue_cheeky_satchel')),
      findsNWidgets(2),
    );
  });

  testWidgets('all nine Blue Zeev WebPs are included in Flutter bundle', (
    tester,
  ) async {
    var count = 0;
    for (final face in ZeevExpression.values) {
      for (final accessory in ZeevAccessory.values) {
        final path =
            'assets/avatar_prototype/zeev_v1_blue_${face.name}_${accessory.name}.webp';
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
        count++;
      }
    }
    expect(count, 9);
  });
}
