import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';

class VendzaContextImage extends StatelessWidget {
  const VendzaContextImage({
    super.key,
    required this.imageUrl,
    required this.icon,
    this.size = 48,
  });

  final String? imageUrl;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Container(
        width: size,
        height: size,
        color: AppColors.accent(context).withValues(alpha: 0.10),
        child: url.startsWith('http')
            ? SmartImage(
                path: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: Icon(icon, color: AppColors.iconAccent(context)),
              )
            : Icon(icon, color: AppColors.iconAccent(context)),
      ),
    );
  }
}
