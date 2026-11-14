import 'package:flutter_test/flutter_test.dart';
import 'package:natter/avatar/brim_avatar_selection.dart';

void main() {
  test('default choice is a calm Brim without an accessory', () {
    const selection = BrimAvatarSelection();
    expect(selection.colourway, BrimColourway.violet);
    expect(selection.expression, BrimExpression.gentle);
    expect(selection.accessory, BrimAccessory.none);
  });

  test('every supported combination has a distinct stable artwork key', () {
    final keys = <String>{};
    for (final colour in BrimColourway.values) {
      for (final expression in BrimExpression.values) {
        for (final accessory in BrimAccessory.values) {
          final selection = BrimAvatarSelection(
            colourway: colour,
            expression: expression,
            accessory: accessory,
          );
          expect(keys.add(selection.artworkKey), isTrue);
        }
      }
    }
    expect(keys, hasLength(18));
  });

  test('editing a choice preserves the other selections', () {
    const initial = BrimAvatarSelection(
      colourway: BrimColourway.mint,
      expression: BrimExpression.gentle,
      accessory: BrimAccessory.scarf,
    );

    final changed = initial.copyWith(expression: BrimExpression.delighted);
    expect(changed.colourway, BrimColourway.mint);
    expect(changed.accessory, BrimAccessory.scarf);
    expect(changed.expression, BrimExpression.delighted);
    expect(initial.expression, BrimExpression.gentle);
  });

  test('choice serialises and restores without losing customisation', () {
    const initial = BrimAvatarSelection(
      colourway: BrimColourway.blue,
      expression: BrimExpression.delighted,
      accessory: BrimAccessory.satchel,
    );
    expect(BrimAvatarSelection.fromMap(initial.toMap()), initial);
  });

  test('unexpected or legacy data safely falls back', () {
    expect(
      BrimAvatarSelection.fromMap(null),
      const BrimAvatarSelection(),
    );
    expect(
      BrimAvatarSelection.fromMap({'character': 'owl'}),
      const BrimAvatarSelection(),
    );
    expect(
      BrimAvatarSelection.fromMap({
        'character': 'brim',
        'version': 1,
        'colourway': 'unknown',
        'expression': 'delighted',
        'accessory': 'invalid',
      }),
      const BrimAvatarSelection(
        expression: BrimExpression.delighted,
      ),
    );
  });
}
