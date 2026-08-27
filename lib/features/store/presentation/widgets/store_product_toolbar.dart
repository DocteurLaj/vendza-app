import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/shared/models/social_item.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/search/search_bar.dart';

class StoreProductToolbar extends StatelessWidget {
  const StoreProductToolbar({
    super.key,
    required this.socials,
    required this.isSearching,
    required this.searchFocusNode,
    required this.onSearchTap,
    this.searchController,
    this.onSearchChanged,
  });

  final List<SocialItem> socials;
  final bool isSearching;
  final FocusNode searchFocusNode;
  final VoidCallback onSearchTap;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return ResponsiveContent(
      maxWidth: AppBreakpoints.contentMaxWidth,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: SearchBarWidget(
              controller: searchController,
              focusNode: searchFocusNode,
              onTap: onSearchTap,
              onChanged: onSearchChanged,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return SizeTransition(
                axis: Axis.horizontal,
                sizeFactor: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: isSearching || socials.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    key: const ValueKey("store-social-icons"),
                    padding: const EdgeInsets.only(left: 18),
                    child: StoreToolbarSocialIcons(socials: socials),
                  ),
          ),
        ],
      ),
    );
  }
}

class StoreToolbarSocialIcons extends StatelessWidget {
  const StoreToolbarSocialIcons({super.key, required this.socials});

  final List<SocialItem> socials;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: socials.map((social) {
        final Widget icon = social.gradient != null
            ? ShaderMask(
                shaderCallback: (bounds) =>
                    social.gradient!.createShader(bounds),
                child: FaIcon(social.icon, color: Colors.white, size: 27),
              )
            : FaIcon(social.icon, color: social.color, size: 27);

        return Padding(padding: const EdgeInsets.only(left: 12), child: icon);
      }).toList(),
    );
  }
}
