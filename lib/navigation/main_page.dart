import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/core/connectivity/offline_banner.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/deep_link/deep_link_service.dart';
import 'package:vendza/core/session/notifications_enabled_store.dart';
import 'package:vendza/features/home/presantation/pages/home.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/data/services/notification_store.dart';
import 'package:vendza/features/notification/presantation/pages/notification_page.dart';
import 'package:vendza/features/profil/presantation/pages/profile_page.dart';
import 'package:vendza/features/store/presentation/pages/my_store_page.dart';

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

const _navItems = [
  _NavItem(icon: Symbols.home, label: 'Home'),
  _NavItem(icon: Symbols.store, label: 'Store'),
  _NavItem(icon: Symbols.notifications, label: 'Notifications'),
  _NavItem(icon: Symbols.person, label: 'Profile'),
];

const _notificationNavIndex = 2;
const _homeNavIndex = 0;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int index = 0;
  bool _railExtended = true;
  Timer? _catalogPollTimer;
  bool _isForeground = true;

  final pages = [HomePage(), MyStorePage(), NotificationPage(), ProfilePage()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.markNavigationReady();
      _syncCatalogPolling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _catalogPollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      unawaited(catalogRepository.softRefreshCatalog());
    }
    _syncCatalogPolling();
  }

  void _setIndex(int nextIndex) {
    if (index == nextIndex) return;
    setState(() => index = nextIndex);
    _syncCatalogPolling();
  }

  void _syncCatalogPolling() {
    final shouldPoll = _isForeground && index == _homeNavIndex;
    if (!shouldPoll) {
      _catalogPollTimer?.cancel();
      _catalogPollTimer = null;
      return;
    }

    _catalogPollTimer ??= Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(catalogRepository.softRefreshCatalog());
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = AppBreakpoints.useNavigationRail(constraints.maxWidth);

        return Scaffold(
          body: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: Row(
                  children: [
                    if (useRail)
                      ValueListenableBuilder<bool>(
                        valueListenable: notificationsEnabledStore,
                        builder: (context, notificationsEnabled, _) {
                          return ValueListenableBuilder<List<NotificationModel>>(
                            valueListenable: notificationStore,
                            builder: (context, notifications, _) {
                              final unreadCount = notificationsEnabled
                                  ? unreadNotificationCount(notifications)
                                  : 0;

                              return _buildNavigationRail(
                                context: context,
                                unreadCount: unreadCount,
                              );
                            },
                          );
                        },
                      ),
                    if (useRail)
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AppColors.border(context),
                      ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: KeyedSubtree(
                          key: ValueKey(index),
                          child: pages[index],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: useRail
              ? null
              : ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: notificationsEnabledStore,
                    builder: (context, notificationsEnabled, _) {
                      return ValueListenableBuilder<List<NotificationModel>>(
                        valueListenable: notificationStore,
                        builder: (context, notifications, _) {
                          final unreadCount = notificationsEnabled
                              ? unreadNotificationCount(notifications)
                              : 0;

                          return _buildBottomNavigationBar(
                            context: context,
                            unreadCount: unreadCount,
                          );
                        },
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildNavigationRail({
    required BuildContext context,
    required int unreadCount,
  }) {
    return NavigationRail(
      extended: _railExtended,
      minWidth: 72,
      minExtendedWidth: 220,
      selectedIndex: index,
      onDestinationSelected: _setIndex,
      backgroundColor: AppColors.elevatedSurface(context),
      selectedIconTheme: IconThemeData(color: AppColors.accent(context)),
      unselectedIconTheme: IconThemeData(color: AppColors.muted(context)),
      selectedLabelTextStyle: TextStyle(
        color: AppColors.accent(context),
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
      unselectedLabelTextStyle: TextStyle(
        color: AppColors.muted(context),
        fontFamily: 'Poppins',
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: IconButton(
              tooltip: _railExtended ? 'Réduire' : 'Étendre',
              icon: Icon(
                _railExtended ? Symbols.chevron_left : Symbols.chevron_right,
              ),
              color: AppColors.muted(context),
              onPressed: () => setState(() => _railExtended = !_railExtended),
            ),
          ),
        ),
      ),
      destinations: [
        for (var i = 0; i < _navItems.length; i++)
          NavigationRailDestination(
            icon: i == _notificationNavIndex
                ? _NotificationNavIcon(unreadCount: unreadCount)
                : Icon(_navItems[i].icon),
            label: Text(_navItems[i].label),
          ),
      ],
    );
  }

  Widget _buildBottomNavigationBar({
    required BuildContext context,
    required int unreadCount,
  }) {
    return BottomNavigationBar(
      currentIndex: index,
      onTap: _setIndex,
      selectedItemColor: AppColors.accent(context),
      unselectedItemColor: AppColors.muted(context),
      backgroundColor: AppColors.elevatedSurface(context),
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: [
        for (var i = 0; i < _navItems.length; i++)
          BottomNavigationBarItem(
            icon: i == _notificationNavIndex
                ? _NotificationNavIcon(unreadCount: unreadCount)
                : Icon(_navItems[i].icon),
            label: _navItems[i].label,
          ),
      ],
    );
  }
}

class _NotificationNavIcon extends StatelessWidget {
  const _NotificationNavIcon({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final displayCount = unreadCount > 99 ? '99+' : '$unreadCount';
    final isDark = AppColors.isDark(context);

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(Symbols.notifications),
          Positioned(
            right: -6,
            top: -4,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInCubic,
              child: unreadCount <= 0
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey(displayCount),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE74747),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          width: 1.4,
                        ),
                      ),
                      child: Text(
                        displayCount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
