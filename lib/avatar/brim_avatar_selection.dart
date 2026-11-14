/// Local-only selection state for the Brim avatar feasibility prototype.
///
/// This intentionally has no Firebase dependency. It does not imply that
/// production-ready Brim artwork exists; artwork must pass a separate quality gate.
enum BrimColourway {
  violet('violet'),
  blue('blue'),
  mint('mint');

  const BrimColourway(this.id);
  final String id;
}

enum BrimExpression {
  gentle('gentle'),
  delighted('delighted');

  const BrimExpression(this.id);
  final String id;
}

enum BrimAccessory {
  none('none'),
  scarf('scarf'),
  satchel('satchel');

  const BrimAccessory(this.id);
  final String id;
}

/// A stable, reversible selection independent of the eventual rendering format.
///
/// All options are available immediately; no activity, behavioural or account
/// state is involved. This model is not persisted or publicly shared in the
/// feasibility prototype.
class BrimAvatarSelection {
  const BrimAvatarSelection({
    this.colourway = BrimColourway.violet,
    this.expression = BrimExpression.gentle,
    this.accessory = BrimAccessory.none,
  });

  final BrimColourway colourway;
  final BrimExpression expression;
  final BrimAccessory accessory;

  BrimAvatarSelection copyWith({
    BrimColourway? colourway,
    BrimExpression? expression,
    BrimAccessory? accessory,
  }) {
    return BrimAvatarSelection(
      colourway: colourway ?? this.colourway,
      expression: expression ?? this.expression,
      accessory: accessory ?? this.accessory,
    );
  }

  /// An artwork identifier, not an existing file path.
  ///
  /// The image renderer must map this key only to vetted, complete artwork
  /// or carefully rigged layers. No generic scarf/satchel PNG placement.
  String get artworkKey =>
      'brim_v1_${colourway.id}_${expression.id}_${accessory.id}';

  Map<String, String> toMap() => {
    'character': 'brim',
    'version': '1',
    'colourway': colourway.id,
    'expression': expression.id,
    'accessory': accessory.id,
  };

  static BrimAvatarSelection fromMap(Map<String, dynamic>? map) {
    if (map == null ||
        map['character'] != 'brim' ||
        map['version']?.toString() != '1') {
      return const BrimAvatarSelection();
    }

    T readChoice<T>(
      dynamic value,
      List<T> values,
      String Function(T) id,
      T fallback,
    ) {
      for (final choice in values) {
        if (id(choice) == value) return choice;
      }
      return fallback;
    }

    return BrimAvatarSelection(
      colourway: readChoice(
        map['colourway'],
        BrimColourway.values,
        (v) => v.id,
        BrimColourway.violet,
      ),
      expression: readChoice(
        map['expression'],
        BrimExpression.values,
        (v) => v.id,
        BrimExpression.gentle,
      ),
      accessory: readChoice(
        map['accessory'],
        BrimAccessory.values,
        (v) => v.id,
        BrimAccessory.none,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BrimAvatarSelection &&
      other.colourway == colourway &&
      other.expression == expression &&
      other.accessory == accessory;

  @override
  int get hashCode => Object.hash(colourway, expression, accessory);
}
