import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NatterCodeInput extends StatefulWidget {
  const NatterCodeInput({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.onCompleted,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;

  @override
  State<NatterCodeInput> createState() =>
      _NatterCodeInputState();
}

class _NatterCodeInputState
    extends State<NatterCodeInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  String _lastCompletedCode = '';

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );

    _focusNodes = List.generate(
      widget.length,
      (_) => FocusNode(),
    );

    for (final focusNode in _focusNodes) {
      focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes) {
      focusNode
        ..removeListener(_handleFocusChanged)
        ..dispose();
    }

    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String _normalise(String value) {
    return value
        .toUpperCase()
        .replaceAll(
          RegExp(r'[^A-Z0-9]'),
          '',
        );
  }

  String get _currentCode {
    return _controllers
        .map((controller) => controller.text)
        .join();
  }

  void _notifyChanged() {
    final code = _currentCode;

    widget.onChanged(code);

    if (code.length == widget.length) {
      if (_lastCompletedCode != code) {
        _lastCompletedCode = code;
        widget.onCompleted?.call();
      }
    } else {
      _lastCompletedCode = '';
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _placeCursorAtEnd(int index) {
    final controller = _controllers[index];

    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  void _moveToCell(int index) {
    if (index < 0 || index >= widget.length) return;

    _focusNodes[index].requestFocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _placeCursorAtEnd(index);
    });
  }

  void _handleChanged(
    int index,
    String rawValue,
  ) {
    final value = _normalise(rawValue);

    // The current character has been deleted.
    // Move focus to the preceding box ready for another deletion.
    if (value.isEmpty) {
      _controllers[index].clear();

      if (index > 0) {
        _moveToCell(index - 1);
      }

      _notifyChanged();
      return;
    }

    // Supports pasting a complete or partial code.
    if (value.length > 1) {
      _distributeCharacters(
        startIndex: index,
        value: value,
      );
      return;
    }

    if (_controllers[index].text != value) {
      _controllers[index].value = TextEditingValue(
        text: value,
        selection: const TextSelection.collapsed(
          offset: 1,
        ),
      );
    }

    if (index < widget.length - 1) {
      _moveToCell(index + 1);
    } else {
      _focusNodes[index].unfocus();
    }

    _notifyChanged();
  }

  void _distributeCharacters({
    required int startIndex,
    required String value,
  }) {
    final characters = _normalise(value).split('');

    var destinationIndex = startIndex;

    for (final character in characters) {
      if (destinationIndex >= widget.length) break;

      _controllers[destinationIndex].value =
          TextEditingValue(
        text: character,
        selection: const TextSelection.collapsed(
          offset: 1,
        ),
      );

      destinationIndex++;
    }

    if (destinationIndex < widget.length) {
      _moveToCell(destinationIndex);
    } else {
      _focusNodes.last.unfocus();
    }

    _notifyChanged();
  }

  KeyEventResult _handleKeyEvent(
    int index,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent &&
        event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey !=
        LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }

    // A populated field is handled normally by TextField.
    // Its onChanged callback then moves focus backwards.
    if (_controllers[index].text.isNotEmpty) {
      return KeyEventResult.ignored;
    }

    // Backspace in an already empty field:
    // move backwards and remove the previous character.
    if (index > 0) {
      final previousIndex = index - 1;

      _controllers[previousIndex].clear();
      _moveToCell(previousIndex);
      _notifyChanged();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const preferredCellWidth = 50.0;
        const preferredCellHeight = 56.0;
        const gap = 7.0;

        final totalGap =
            gap * (widget.length - 1);

        final availableCellWidth =
            (constraints.maxWidth - totalGap) /
                widget.length;

        final cellWidth = math.min(
          preferredCellWidth,
          availableCellWidth,
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.length,
            (index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == widget.length - 1
                      ? 0
                      : gap,
                ),
                child: _buildCell(
                  index: index,
                  width: cellWidth,
                  height: preferredCellHeight,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCell({
    required int index,
    required double width,
    required double height,
  }) {
    final focused = _focusNodes[index].hasFocus;
    final completed =
        _controllers[index].text.isNotEmpty;

    final borderColour = focused
        ? const Color(0xFF3DA6F3)
        : completed
            ? Colors.white.withValues(alpha: 0.42)
            : Colors.white.withValues(alpha: 0.20);

    final fillColour = focused
        ? Colors.white.withValues(alpha: 0.16)
        : completed
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.07);

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) {
        return _handleKeyEvent(index, event);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: fillColour,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: borderColour,
            width: focused ? 1.8 : 1.1,
          ),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: const Color(0xFF3DA6F3)
                        .withValues(alpha: 0.16),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          autofocus: index == 0,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          textCapitalization:
              TextCapitalization.characters,
          keyboardType: TextInputType.text,
          textInputAction:
              index == widget.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: 0,
          ),
          cursorColor: Colors.white,
          cursorHeight: 24,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[a-zA-Z0-9]'),
            ),
            UpperCaseTextFormatter(),
          ],
          decoration: const InputDecoration(
            counterText: '',
            isDense: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () {
            _placeCursorAtEnd(index);
          },
          onChanged: (value) {
            _handleChanged(index, value);
          },
          onSubmitted: (_) {
            if (index < widget.length - 1) {
              _moveToCell(index + 1);
            }
          },
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upperCaseText =
        newValue.text.toUpperCase();

    return TextEditingValue(
      text: upperCaseText,
      selection: TextSelection.collapsed(
        offset: upperCaseText.length,
      ),
      composing: TextRange.empty,
    );
  }
}
