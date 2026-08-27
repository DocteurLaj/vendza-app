import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';

class TextIntro extends StatelessWidget {
  const TextIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Choisissez votre abonnement et profitez d’avantages exclusifs adaptés à vos besoins.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '🔥 Profitez des tarifs promotionnels avant le retour aux prix normaux !',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.isDark(context)
                  ? AppColors.accent(context)
                  : Colors.amber.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
