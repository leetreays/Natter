import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natter/avatar/brim_lab_main.dart';
import 'package:natter/avatar/brim_avatar_selection.dart';
import 'package:natter/main.dart' show NatterChildPrimaryButton;

void main() {
  testWidgets('Brim lab opens using Natter child UI with safe default choice', (
    tester,
  ) async {
    await tester.pumpWidget(const BrimPrototypeApp());

    expect(find.text('Make Brim your own'), findsOneWidget);
    expect(find.byKey(const Key('brim-hero')), findsOneWidget);
    expect(find.byKey(const Key('brim-chat-preview')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('brim-state-key')),
      180,
    );
    expect(find.text('brim_v1_violet_gentle_none'), findsOneWidget);
    expect(find.text('Prototype status — no avatar is saved'), findsOneWidget);
  });

  testWidgets('child can switch colour, expression, and accessory', (
    tester,
  ) async {
    await tester.pumpWidget(const BrimPrototypeApp());

    await tester.scrollUntilVisible(find.byKey(const Key('colour-blue')), 140);
    await tester.tap(find.byKey(const Key('colour-blue')));
    await tester.pump();
    await tester.scrollUntilVisible(find.byKey(const Key('expression-playful')), 140);
    expect(find.text('Playful'), findsOneWidget);
    await tester.tap(find.byKey(const Key('expression-playful')));
    await tester.pump();
    await tester.scrollUntilVisible(find.byKey(const Key('accessory-scarf')), 140);
    await tester.tap(find.byKey(const Key('accessory-scarf')));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const Key('brim-state-key')),
      150,
    );
    expect(find.text('brim_v1_blue_playful_scarf'), findsOneWidget);
  });

  testWidgets('expression switches instantly in both previews', (
    tester,
  ) async {
    const gentle = BrimAvatarSelection();
    final playful = gentle.copyWith(expression: BrimExpression.playful);
    final cheeky = gentle.copyWith(expression: BrimExpression.cheeky);

    Widget previews(BrimAvatarSelection selection) => MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            BrimArtPreview(selection: selection),
            BrimArtPreview(selection: selection, compact: true),
          ],
        ),
      ),
    );

    await tester.pumpWidget(previews(gentle));
    expect(find.byType(AnimatedSwitcher), findsNothing);
    expect(
      find.byKey(const ValueKey('brim_v1_violet_gentle_none')),
      findsNWidgets(2),
    );

    await tester.pumpWidget(previews(playful));
    expect(find.byType(AnimatedSwitcher), findsNothing);
    expect(
      find.byKey(const ValueKey('brim_v1_violet_gentle_none')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('brim_v1_violet_playful_none')),
      findsNWidgets(2),
    );

    await tester.pumpWidget(previews(cheeky));
    expect(find.byType(AnimatedSwitcher), findsNothing);
    expect(
      find.byKey(const ValueKey('brim_v1_violet_playful_none')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('brim_v1_violet_cheeky_none')),
      findsNWidgets(2),
    );
  });

  testWidgets('prototype action gives persistent no-save feedback', (
    tester,
  ) async {
    await tester.pumpWidget(const BrimPrototypeApp());

    final action = find.byKey(const Key('brim-preview-action'));
    await tester.scrollUntilVisible(action, 180);
    // The button sits at the end of a scrollable screen. Align it well
    // within the viewport rather than tapping text at the viewport edge.
    await Scrollable.ensureVisible(
      tester.element(action),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pump();

    expect(find.text('Preview only — not saved'), findsNothing);
    expect(tester.widget<NatterChildPrimaryButton>(action).enabled, isTrue);
    await tester.tap(action);
    await tester.pump();

    // The feedback belongs to the existing button rather than an ephemeral
    // SnackBar; the lab has no Firestore/account persistence to trigger.
    expect(find.text('Try this look'), findsNothing);
    expect(find.text('Preview only — not saved'), findsOneWidget);
  });
}
