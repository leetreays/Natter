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
  final TextEditingController _controller =
      TextEditingController();

  final FocusNode _focusNode = FocusNode();

  String _lastCompletedCode = '';

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(_handleFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();

    _controller.dispose();

    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String _normaliseCode(String value) {
    return value
        .toUpperCase()
        .replaceAll(
          RegExp(r'[^A-Z0-9]'),
          '',
        )
        .characters
        .take(widget.length)
        .toString();
  }

  void _handleChanged(String rawValue) {
    final normalised = _normaliseCode(rawValue);

    if (_controller.text != normalised) {
      _controller.value = TextEditingValue(
        text: normalised,
        selection: TextSelection.collapsed(
          offset: normalised.length,
        ),
      );
    }

    widget.onChanged(normalised);

    if (normalised.length == widget.length) {
      if (_lastCompletedCode != normalised) {
        _lastCompletedCode = normalised;
        widget.onCompleted?.call();
      }
    } else {
      _lastCompletedCode = '';
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _requestFocus() {
    _focusNode.requestFocus();

    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const preferredCellWidth = 50.0;
        const cellHeight = 58.0;
        const preferredGap = 8.0;

        final maxAvailableWidth = constraints.maxWidth;

        final preferredTotalWidth =
            (preferredCellWidth * widget.length) +
                (preferredGap * (widget.length - 1));

        final availableWidth = math.min(
          preferredTotalWidth,
          maxAvailableWidth,
        );

        final responsiveGap = maxAvailableWidth < 350
            ? 5.0
            : preferredGap;

        final totalGap =
            responsiveGap * (widget.length - 1);

        final cellWidth = math.min(
          preferredCellWidth,
          (availableWidth - totalGap) / widget.length,
        );

        final totalWidth =
            (cellWidth * widget.length) + totalGap;

        return Semantics(
          label: 'Natter access code',
          textField: true,
          value: _controller.text,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _requestFocus,
            child: SizedBox(
              width: totalWidth,
              height: cellHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _controller,
                        _focusNode,
                      ]),
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _NatterCodePainter(
                            code: _controller.text,
                            length: widget.length,
                            cellWidth: cellWidth,
                            cellHeight: cellHeight,
                            gap: responsiveGap,
                            focused: _focusNode.hasFocus,
                          ),
                        );
                      },
                    ),
                  ),

                  // One real input field handles typing, paste,
                  // selection and backspace. It remains visually
                  // hidden while the painter displays the code.
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 1,
                    height: 1,
                    child: Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        keyboardType: TextInputType.text,
                        textCapitalization:
                            TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                        smartDashesType:
                            SmartDashesType.disabled,
                        smartQuotesType:
                            SmartQuotesType.disabled,
                        maxLength: widget.length,
                        maxLengthEnforcement:
                            MaxLengthEnforcement.enforced,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]'),
                          ),
                          UpperCaseTextFormatter(),
                          LengthLimitingTextInputFormatter(
                            widget.length,
                          ),
                        ],
                        decoration:
                            const InputDecoration.collapsed(
                          hintText: '',
                        ),
                        onChanged: _handleChanged,
                        onSubmitted: (_) {
                          if (_controller.text.length ==
                              widget.length) {
                            _focusNode.unfocus();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NatterCodePainter extends CustomPainter {
  const _NatterCodePainter({
    required this.code,
    required this.length,
    required this.cellWidth,
    required this.cellHeight,
    required this.gap,
    required this.focused,
  });

  final String code;
  final int length;
  final double cellWidth;
  final double cellHeight;
  final double gap;
  final bool focused;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 17.0;

    final activeIndex = code.length < length
        ? code.length
        : length - 1;

    for (var index = 0; index < length; index++) {
      final left = index * (cellWidth + gap);

      final rect = Rect.fromLTWH(
        left,
        0,
        cellWidth,
        cellHeight,
      );

      final roundedRect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(radius),
      );

      final completed = index < code.length;

      final active =
          focused && index == activeIndex;

      final fillColour = active
          ? Colors.white.withValues(alpha: 0.16)
          : completed
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.07);

      final borderColour = active
          ? const Color(0xFF3DA6F3)
          : completed
              ? Colors.white.withValues(alpha: 0.46)
              : Colors.white.withValues(alpha: 0.20);

      if (active) {
        final glowPaint = Paint()
          ..color = const Color(0xFF3DA6F3)
              .withValues(alpha: 0.14)
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            10,
          );

        canvas.drawRRect(
          roundedRect.inflate(2),
          glowPaint,
        );
      }

      final fillPaint = Paint()
        ..color = fillColour;

      canvas.drawRRect(
        roundedRect,
        fillPaint,
      );

      final borderPaint = Paint()
        ..color = borderColour
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 1.8 : 1.1;

      canvas.drawRRect(
        roundedRect,
        borderPaint,
      );

      if (completed) {
        final character = code[index];

        final textPainter = TextPainter(
          text: TextSpan(
            text: character,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(
            minWidth: 0,
            maxWidth: cellWidth,
          );

        final textOffset = Offset(
          left + ((cellWidth - textPainter.width) / 2),
          (cellHeight - textPainter.height) / 2,
        );

        textPainter.paint(
          canvas,
          textOffset,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _NatterCodePainter oldDelegate,
  ) {
    return oldDelegate.code != code ||
        oldDelegate.length != length ||
        oldDelegate.cellWidth != cellWidth ||
        oldDelegate.cellHeight != cellHeight ||
        oldDelegate.gap != gap ||
        oldDelegate.focused != focused;
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
