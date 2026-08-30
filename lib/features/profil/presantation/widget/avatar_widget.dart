import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/media/app_image_picker.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/features/profil/data/model/user_model.dart';
import 'package:vendza/features/profil/data/services/profile_api_service.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';

class AvatarWidget extends StatefulWidget {
  const AvatarWidget({
    super.key,
    required this.name,
    required this.email,
    required this.urlimage,
    this.editable = false,
    this.showIdentity = true,
    this.showEditLabel = true,
    this.radius = 54,
    this.profileApi,
    this.imagePicker,
  });

  final String name;
  final String email;
  final String urlimage;
  final bool editable;
  final bool showIdentity;
  final bool showEditLabel;
  final double radius;
  final ProfileApiService? profileApi;
  final Future<String?> Function(BuildContext context, {required String title})?
  imagePicker;

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> {
  bool _uploading = false;

  UserModel get _user => currentUserStore.value;

  Future<void> _changePhoto() async {
    if (_uploading || !widget.editable) return;

    final picker = widget.imagePicker ?? pickAppImage;
    final localPath = await picker(context, title: 'Modifier la photo');
    if (!mounted || localPath == null || localPath.trim().isEmpty) return;

    setState(() => _uploading = true);
    final previousUrl = sanitizeAvatarUrl(_user.urlimage);
    try {
      final profileApi = widget.profileApi ?? ProfileApiService();
      final savedUrl = await profileApi.savePickedAvatar(localPath);
      await SmartImage.evict(previousUrl);
      applyCurrentUserAvatar(savedUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil mise à jour')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'Impossible de mettre à jour la photo de profil.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final imageUrl = sanitizeAvatarUrl(widget.urlimage);
    final radius = widget.radius;
    final identityColor = widget.showIdentity
        ? Colors.white
        : AppColors.textPrimary(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.editable && !_uploading ? _changePhoto : null,
          child: SizedBox(
            width: (radius + 8) * 2,
            height: (radius + 8) * 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.showIdentity
                        ? Colors.white.withValues(alpha: 0.16)
                        : AppColors.softSurface(context),
                    border: Border.all(
                      color: widget.showIdentity
                          ? Colors.white.withValues(alpha: 0.3)
                          : AppColors.border(context),
                    ),
                  ),
                  child: _UserAvatarImage(
                    key: ValueKey(imageUrl),
                    imageUrl: imageUrl,
                    initials: user.initials,
                    radius: radius,
                    compact: !widget.showIdentity,
                  ),
                ),
                if (_uploading)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      ),
                    ),
                  ),
                if (widget.editable)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: IgnorePointer(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accent(context),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.showIdentity
                                ? Colors.white
                                : AppColors.card(context),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: 16,
                          color: widget.showIdentity
                              ? Colors.white
                              : AppColors.card(context),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.showEditLabel && widget.editable) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _uploading ? null : _changePhoto,
            child: Text(
              'Modifier la photo',
              style: TextStyle(
                color: widget.showIdentity
                    ? Colors.white.withValues(alpha: 0.92)
                    : AppColors.accent(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (widget.showIdentity) ...[
          const SizedBox(height: 12),
          Text(
            widget.name,
            style: TextStyle(
              color: identityColor,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.email,
            style: TextStyle(
              color: identityColor.withValues(alpha: 0.76),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class UserAvatarImage extends StatelessWidget {
  const UserAvatarImage({
    super.key,
    required this.imageUrl,
    required this.initials,
    this.radius = 30,
  });

  final String imageUrl;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return _UserAvatarImage(
      imageUrl: sanitizeAvatarUrl(imageUrl),
      initials: initials,
      radius: radius,
      compact: true,
    );
  }
}

class _UserAvatarImage extends StatelessWidget {
  const _UserAvatarImage({
    super.key,
    required this.imageUrl,
    required this.initials,
    required this.radius,
    required this.compact,
  });

  final String imageUrl;
  final String initials;
  final double radius;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fallback = _AvatarFallback(
      initials: initials,
      radius: radius,
      compact: compact,
    );

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: imageUrl.isEmpty
            ? fallback
            : SmartImage(
                path: imageUrl,
                fit: BoxFit.cover,
                errorWidget: fallback,
              ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.initials,
    required this.radius,
    required this.compact,
  });

  final String initials;
  final double radius;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: compact ? AppColors.softSurface(context) : AppColors.graybg,
      child: Center(
        child: Text(
          initials.trim().isEmpty ? '?' : initials,
          style: TextStyle(
            color: AppColors.accent(context),
            fontSize: radius * 0.9,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}
