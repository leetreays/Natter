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
    await tester.scrollUntilVisible(find.byKey(const Key('expression-delighted')), 140);
    // Preserve the existing artwork ID, but show a more accurate name.
    expect(find.text('Cheerful'), findsOneWidget);
    await tester.tap(find.byKey(const Key('expression-delighted')));
    await tester.pump();
    await tester.scrollUntilVisible(find.byKey(const Key('accessory-scarf')), 140);
    await tester.tap(find.byKey(const Key('accessory-scarf')));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const Key('brim-state-key')),
      150,
    );
    expect(find.text('brim_v1_blue_delighted_scarf'), findsOneWidget);
  });

  testWidgets('expression crossfades in the hero and chat preview', (
    tester,
  ) async {
    const gentle = BrimAvatarSelection();
    final cheerful = gentle.copyWith(expression: BrimExpression.delighted);

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
    expect(find.byType(AnimatedSwitcher), findsNWidgets(2));

    for (final widget in tester.widgetList<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    )) {
      expect(widget.duration, const Duration(milliseconds: 280));
    }

    await tester.pumpWidget(previews(cheerful));
    await tester.pump();

    // The two complete illustrations overlap during the 280ms fade;
    // this doesn't interpolate facial geometry or require new assets.
    expect(
      find.byKey(const ValueKey(BrimExpression.gentle)),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const ValueKey(BrimExpression.delighted)),
      findsNWidgets(2),
    );

    await tester.pump(const Duration(milliseconds: 320));
    expect(
      find.byKey(const ValueKey(BrimExpression.gentle)),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey(BrimExpression.delighted)),
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
