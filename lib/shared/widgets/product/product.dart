import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';

class ProductWidget extends StatelessWidget {
  const ProductWidget({
    super.key,
    required this.name,
    required this.price,
    required this.imageurl,
  });

  final String name;
  final String price;
  final String imageurl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🔥 IMPORTANT
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.softSurface(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.image, size: 40, color: AppColors.muted(context)),
          ),

          const SizedBox(height: 8),

          Text(
            name, // 🔥 UTILISE TES DONNÉES
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardTitle(context),
          ),

          const SizedBox(height: 4),

          Text(
            "\$$price", // 🔥 UTILISE TES DONNÉES
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.success(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
