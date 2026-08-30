import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/features/profil/presantation/widget/avatar_widget.dart';
import 'package:vendza/features/profil/presantation/widget/list_option_profil.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final topColor = AppColors.isDark(context)
        ? AppColors.darkBackground
        : AppColors.primary;
    final middleColor = AppColors.isDark(context)
        ? AppColors.darkSurfaceElevated
        : const Color(0xFF0F4A4E);

    return Scaffold(
      backgroundColor: topColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, middleColor, topColor],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Profil",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ValueListenableBuilder(
                  valueListenable: currentUserStore,
                  builder: (context, user, _) {
                    return AvatarWidget(
                      name: user.name,
                      email: user.email,
                      urlimage: user.urlimage,
                      editable: false,
                    );
                  },
                ),
              ],
            ),
          ),
          ResponsiveContent(
            maxWidth: 720,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.58,
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(top: false, child: ListOptionProfil()),
            ),
          ),
        ],
      ),
    );
  }
}
