import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natter/avatar/brim_lab_main.dart';

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
  });

  testWidgets('prototype action explicitly does not save account state', (
    tester,
  ) async {
    await tester.pumpWidget(const BrimPrototypeApp());

    await tester.scrollUntilVisible(find.text('Try this look'), 180);
    await tester.tap(find.text('Try this look'));
    // SnackBars are enqueued on tap and animate into the Scaffold.
    // One pump can happen before their content is inserted/visible.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Prototype only — your Natter avatar has not changed.'),
      findsOneWidget,
    );
  });
}
