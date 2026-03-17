import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lottie/lottie.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/core/providers/navigation_provider.dart';
import 'package:zoneer_mobile/features/property/views/home_view.dart';
import 'package:zoneer_mobile/features/property/views/property_map_page.dart';
import 'package:zoneer_mobile/features/user/views/tenant/tenant_profile_setting.dart';
import 'package:zoneer_mobile/features/wishlist/views/wishlist_view.dart';

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
  late AnimationController _profileController;

  @override
  void initState() {
    super.initState();
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
    _profileController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _homeController.dispose();
    _wishlistController.dispose();
    _mapController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationProvider);
    final List<Widget> widgetOptions = [
      const HomeView(),
      const WishlistView(),
      const PropertyMapPage(),
      const TenantProfileSetting(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: selectedIndex, children: widgetOptions),
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
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  icon: Icons.person,
                  leading: selectedIndex == 3
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
                  text: selectedIndex == 3 ? 'Profile' : '',
                ),
              ],
              selectedIndex: selectedIndex,
              onTabChange: (index) {
                ref.read(navigationProvider.notifier).changeTab(index);
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
