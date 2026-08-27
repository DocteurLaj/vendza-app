import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';

class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    this.child,
    this.children,
  });

  final String? title;
  final Widget? child;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title!.isNotEmpty)
            Text(title!, style: AppTextStyles.sectionLabel(context)),
          const SizedBox(height: 10),

          ?child,
          ...?children,
        ],
      ),
    );
  }
}
