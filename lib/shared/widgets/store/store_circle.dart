import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/shared/widgets/carousel/animated_circular_ring.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';

class StoreWidgetCircle extends StatelessWidget {
  const StoreWidgetCircle({
    super.key,
    required this.name,
    required this.imageurl,
  });

  final String name;
  final String imageurl;

  @override
  Widget build(BuildContext context) {
    final imagePath = imageurl.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedCircularRing(
          size: 84,
          child: Container(
            color: AppColors.card(context),
            alignment: Alignment.center,
            child: imagePath.isEmpty
                ? Icon(
                    Icons.store,
                    size: 40,
                    color: AppColors.iconAccent(context),
                  )
                : SizedBox.expand(
                    child: SmartImage(path: imagePath, fit: BoxFit.cover),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 84,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label(context),
          ),
        ),
      ],
    );
  }
}
