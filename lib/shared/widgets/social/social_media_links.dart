import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/shared/models/social_item.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

class SocialMediaLinks extends StatelessWidget {
  const SocialMediaLinks({
    super.key,
    required this.socials,
    this.title = "Nous suivre",
  });

  final List<SocialItem> socials;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (socials.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: socials.map((social) {
            final Widget icon = social.gradient != null
                ? ShaderMask(
                    shaderCallback: (bounds) =>
                        social.gradient!.createShader(bounds),
                    child: FaIcon(social.icon, color: Colors.white, size: 22),
                  )
                : FaIcon(social.icon, color: social.color, size: 22);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AppInteractive(
                onTap: social.url == null || social.url!.trim().isEmpty
                    ? null
                    : () async {
                        final uri = Uri.tryParse(social.url!.trim());
                        if (uri == null) return;

                        final opened = await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );

                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Impossible d'ouvrir ce lien"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                borderRadius: BorderRadius.circular(23),
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.softSurface(context),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: AppColors.isDark(context) ? 0.18 : 0.04,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: icon,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
