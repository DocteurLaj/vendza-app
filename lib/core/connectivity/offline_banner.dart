import 'package:flutter/material.dart';
import 'package:vendza/core/connectivity/network_status.dart';
import 'package:vendza/core/constants/colors.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkStatus.isOffline,
      builder: (context, offline, _) {
        if (!offline) return const SizedBox.shrink();
        return Material(
          color: AppColors.accent(context),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 18,
                    color: AppColors.isDark(context)
                        ? AppColors.darkBackground
                        : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Hors connexion. Certaines actions sont indisponibles.",
                      style: TextStyle(
                        color: AppColors.isDark(context)
                            ? AppColors.darkBackground
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
