import 'package:flutter/material.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/shared/widgets/input/input_simple.dart';

class FormFieldWidget extends StatelessWidget {
  const FormFieldWidget({
    super.key,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label(context)),
        const SizedBox(height: 8),
        InputSimple(
          hintText: hint,
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
