import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';

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
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(icon, color: AppColors.iconAccent(context)),
              )
            : Icon(icon, color: AppColors.iconAccent(context)),
      ),
    );
  }
}
