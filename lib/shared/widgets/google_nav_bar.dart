import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/core/providers/navigation_provider.dart';
import 'package:zoneer_mobile/presentation/screens/property/property_detail_page.dart';
import 'package:zoneer_mobile/data/models/notification/notification_model.dart';
import 'package:zoneer_mobile/presentation/viewmodels/notification/notification_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/notification/widgets/floating_banner.dart';
import 'package:zoneer_mobile/presentation/screens/notification/widgets/in_app_notification_banner.dart';
import 'package:zoneer_mobile/presentation/screens/property/home_view.dart';
import 'package:zoneer_mobile/presentation/screens/property/properties_list_screen.dart';
import 'package:zoneer_mobile/presentation/screens/property/property_map_page.dart';
import 'package:zoneer_mobile/presentation/viewmodels/messaging/messaging_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/messaging/conversation_list_screen.dart';
import 'package:zoneer_mobile/presentation/screens/user/tenant/tenant_profile_setting.dart';
import 'package:zoneer_mobile/presentation/screens/wishlist/wishlist_view.dart';

class GoogleNavBar extends ConsumerStatefulWidget {
  const GoogleNavBar({super.key});

  @override
  ConsumerState<GoogleNavBar> createState() => _GoogleNavBarState();
}

class _GoogleNavBarState extends ConsumerState<GoogleNavBar>
    with TickerProviderStateMixin {
  late AnimationController _homeController;
  late AnimationController _wishlistController;
  late AnimationController _mapController;
  late AnimationController _messagesController;
  late AnimationController _profileController;

  RealtimeChannel? _notificationChannel;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleInitialDeepLink());
    _homeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _wishlistController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _mapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _messagesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _profileController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Listen for deep links arriving while app is running.
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (err) => debugPrint('Deep link error: $err'),
    );

    // Subscribe to real-time notification inserts for the current user.
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeNotifications());
  }

  Future<void> _handleInitialDeepLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) _handleDeepLink(uri);
    } catch (error, stackTrace) {
      debugPrint('Failed to handle initial deep link: $error');
      debugPrint(stackTrace.toString());
    }
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'zoneer') return;
    if (uri.host == 'property') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      if (id != null && id.isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PropertyDetailPage(id: id)),
        );
      }
    }
  }

  void _subscribeNotifications() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _notificationChannel = Supabase.instance.client
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (!mounted) return;
            try {
              final notification = NotificationModel.fromJson(payload.newRecord);
              // Append to in-memory list so badge + notification screen update.
              ref
                  .read(notificationsViewModelProvider.notifier)
                  .prependNotification(notification);
              // Show floating banner on top of whatever screen is active.
              showFloatingBanner(
                context,
                title: notification.title,
                message: notification.message,
              );
            } catch (_) {
              // Malformed payload — ignore silently.
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    _homeController.dispose();
    _wishlistController.dispose();
    _mapController.dispose();
    _messagesController.dispose();
    _profileController.dispose();
    if (_notificationChannel != null) {
      Supabase.instance.client.removeChannel(_notificationChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationProvider);
    final mode = ref.watch(mapTabViewProvider);
    final hasAnyUnread = ref.watch(hasAnyUnreadProvider);

    final List<Widget> widgetOptions = [
      const HomeView(),
      const WishlistView(),
      mode == MapTabView.search
          ? const SearchScreen()
          : const PropertyMapPage(),
      const ConversationListScreen(),
      const TenantProfileSetting(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(index: selectedIndex, children: widgetOptions),
          const InAppNotificationBanner(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withValues(alpha: .1),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: AppColors.primaryLight.withValues(alpha: 0.2),
              hoverColor: AppColors.greyLight,
              gap: 8,
              activeColor: AppColors.primary,
              iconSize: 24,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              duration: Duration(milliseconds: 400),
              tabBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
              color: AppColors.secondary,
              tabs: [
                GButton(
                  icon: Icons.home,
                  leading: selectedIndex == 0
                      ? ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Lottie.asset(
                              'assets/icons/system-solid-41-home-hover-pinch.json',
                              controller: _homeController,
                              fit: BoxFit.contain,
                              onLoaded: (composition) {
                                _homeController.duration = composition.duration;
                              },
                            ),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                AppColors.secondary,
                                BlendMode.srcIn,
                              ),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Lottie.asset(
                                  'assets/icons/system-solid-41-home-hover-pinch.json',
                                  controller: _homeController,
                                  fit: BoxFit.contain,
                                  onLoaded: (composition) {
                                    _homeController.duration =
                                        composition.duration;
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Home',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                  text: selectedIndex == 0 ? 'Home' : '',
                ),
                GButton(
                  icon: Icons.bookmark,
                  leading: selectedIndex == 1
                      ? ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Lottie.asset(
                              'assets/icons/system-solid-20-bookmark-hover-bookmark-1.json',
                              controller: _wishlistController,
                              fit: BoxFit.contain,
                              onLoaded: (composition) {
                                _wishlistController.duration =
                                    composition.duration;
                              },
                            ),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                AppColors.secondary,
                                BlendMode.srcIn,
                              ),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Lottie.asset(
                                  'assets/icons/system-solid-20-bookmark-hover-bookmark-1.json',
                                  controller: _wishlistController,
                                  fit: BoxFit.contain,
                                  onLoaded: (composition) {
                                    _wishlistController.duration =
                                        composition.duration;
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Wishlist',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                  text: selectedIndex == 1 ? 'Wishlist' : '',
                ),
                GButton(
                  icon: Icons.map,
                  leading: selectedIndex == 2
                      ? ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Lottie.asset(
                              'assets/icons/droppin.json',
                              controller: _mapController,
                              fit: BoxFit.contain,
                              onLoaded: (composition) {
                                _mapController.duration = composition.duration;
                              },
                            ),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                AppColors.secondary,
                                BlendMode.srcIn,
                              ),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Lottie.asset(
                                  'assets/icons/droppin.json',
                                  controller: _mapController,
                                  fit: BoxFit.contain,
                                  onLoaded: (composition) {
                                    _mapController.duration =
                                        composition.duration;
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Map',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                  text: selectedIndex == 2 ? 'Map' : '',
                ),
                GButton(
                  icon: Icons.chat_bubble_outline,
                  leading: selectedIndex == NavigationTab.messages
                      ? Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                AppColors.primary,
                                BlendMode.srcIn,
                              ),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Lottie.asset(
                                  'assets/icons/system-solid-47-chat-hover-chat.json',
                                  controller: _messagesController,
                                  fit: BoxFit.contain,
                                  onLoaded: (composition) {
                                    _messagesController.duration =
                                        composition.duration;
                                  },
                                ),
                              ),
                            ),
                            if (hasAnyUnread)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    AppColors.secondary,
                                    BlendMode.srcIn,
                                  ),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Lottie.asset(
                                      'assets/icons/system-solid-47-chat-hover-chat.json',
                                      controller: _messagesController,
                                      fit: BoxFit.contain,
                                      onLoaded: (composition) {
                                        _messagesController.duration =
                                            composition.duration;
                                      },
                                    ),
                                  ),
                                ),
                                if (hasAnyUnread)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Messages',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                  text: selectedIndex == NavigationTab.messages ? 'Messages' : '',
                ),
                GButton(
                  icon: Icons.person,
                  leading: selectedIndex == NavigationTab.profile
                      ? ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Lottie.asset(
                              'assets/icons/system-solid-8-account-hover-pinch.json',
                              controller: _profileController,
                              fit: BoxFit.contain,
                              onLoaded: (composition) {
                                _profileController.duration =
                                    composition.duration;
                              },
                            ),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                AppColors.secondary,
                                BlendMode.srcIn,
                              ),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Lottie.asset(
                                  'assets/icons/system-solid-8-account-hover-pinch.json',
                                  controller: _profileController,
                                  fit: BoxFit.contain,
                                  onLoaded: (composition) {
                                    _profileController.duration =
                                        composition.duration;
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                  text: selectedIndex == NavigationTab.profile ? 'Profile' : '',
                ),
              ],
              selectedIndex: selectedIndex,
              onTabChange: (index) {
                ref.read(navigationProvider.notifier).changeTab(index);
                // Play animation for selected tab
                if (index == NavigationTab.map) {
                  ref.read(mapTabViewProvider.notifier).showMap();
                }

                switch (index) {
                  case 0:
                    _homeController.forward(from: 0);
                    break;
                  case 1:
                    _wishlistController.forward(from: 0);
                    break;
                  case 2:
                    _mapController.forward(from: 0);
                    break;
                  case 3:
                    _messagesController.forward(from: 0);
                    break;
                  case 4:
                    _profileController.forward(from: 0);
                    break;
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
