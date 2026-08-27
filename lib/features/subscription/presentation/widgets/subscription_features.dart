import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/subscription/data/models/subscription_model.dart';

class SubscriptionFeatures extends StatelessWidget {
  const SubscriptionFeatures({super.key, required this.selectedSub});

  final SubscriptionModel selectedSub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ce que vous obtenez :',
            style: AppTextStyles.sectionTitle(context).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...selectedSub.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check,
                    size: 18,
                    color: AppColors.iconAccent(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      softWrap: true,
                      style: AppTextStyles.body(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
