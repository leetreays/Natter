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
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final node in _focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

    void _notifyChanged() {
    final code = _controllers
        .map((c) => c.text)
        .join();

    widget.onChanged(code);

    if (code.length == widget.length) {
      widget.onCompleted?.call();
    }
  }

    @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: List.generate(
        widget.length,
        (index) => _buildCell(index),
      ),
    );
  }

    Widget _buildCell(int index) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 46,
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          maxLength: 1,
          textCapitalization:
              TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter
                .allow(RegExp(r'[a-zA-Z0-9]')),
            UpperCaseTextFormatter(),
          ],
          decoration: const InputDecoration(
            counterText: '',
          ),
          onChanged: (value) {
            if (value.isNotEmpty &&
                index < widget.length - 1) {
              _focusNodes[index + 1].requestFocus();
            }

            _notifyChanged();
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
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
    );
  }
}