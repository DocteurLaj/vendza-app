import 'package:flutter/material.dart';
import 'package:vendza/shared/widgets/input/app_input_decoration.dart';

class InputSimple extends StatelessWidget {
  const InputSimple({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: AppInputDecoration.field(context, hintText: hintText),
    );
  }
}
