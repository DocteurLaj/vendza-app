import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';

class VendzaPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const VendzaPageHeader.root({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
  }) : showBack = false;

  const VendzaPageHeader.back({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
  }) : showBack = true;

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool showBack;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 82 : 96);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.appBackground(context);
    final fg = foregroundColor ?? AppColors.textPrimary(context);
    final accent = AppColors.accent(context);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: preferredSize.height,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _HeaderIconButton(
          icon: showBack ? Icons.arrow_back_ios_new_rounded : icon,
          tooltip: showBack ? 'Retour' : title,
          onPressed: showBack ? () => Navigator.maybePop(context) : null,
        ),
      ),
      titleSpacing: 10,
      title: Row(
        children: [
          if (showBack) ...[
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.16)),
              ),
              child: Icon(icon, color: AppColors.iconAccent(context), size: 21),
            ),
            const SizedBox(width: 20),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageTitle(context).copyWith(
                    color: fg,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 12.5,
                      height: 1.18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: _spacedActions(actions),
    );
  }

  List<Widget>? _spacedActions(List<Widget>? source) {
    if (source == null || source.isEmpty) return null;
    return [
      const SizedBox(width: 8),
      ...source.map(
        (action) => Padding(
          padding: const EdgeInsets.only(left: 4, right: 6),
          child: Center(child: action),
        ),
      ),
      const SizedBox(width: 10),
    ];
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);
    final child = SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: Container(
          key: const Key('vendza_header_leading_button_surface'),
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.card(context),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppColors.isDark(context) ? 0.12 : 0.025,
                ),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: accent, size: 18),
        ),
      ),
    );

    if (onPressed == null) {
      return Tooltip(message: tooltip, child: child);
    }
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }
}
