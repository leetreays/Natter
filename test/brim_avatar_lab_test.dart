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
    // "Cheerful" is the truthful user-facing label for the subtle wider
    // smile. Internal asset IDs remain 'delighted' during this lab.
    expect(find.text('Cheerful'), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsNWidgets(2));
    final hero = find.descendant(
      of: find.byKey(const Key('brim-hero')),
      matching: find.byType(AnimatedSwitcher),
    );
    final iconPreview = find.descendant(
      of: find.byKey(const Key('brim-chat-preview')),
      matching: find.byType(AnimatedSwitcher),
    );
    expect(tester.widget<AnimatedSwitcher>(hero).duration,
        const Duration(milliseconds: 280));
    expect(tester.widget<AnimatedSwitcher>(iconPreview).duration,
        const Duration(milliseconds: 280));
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
