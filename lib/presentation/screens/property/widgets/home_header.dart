import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';
import 'package:zoneer_mobile/core/services/auth_service.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/core/providers/service_provider.dart';
import 'package:zoneer_mobile/core/providers/location_permission_provider.dart';
import 'package:zoneer_mobile/presentation/screens/notification/notification_screen.dart';
import 'package:zoneer_mobile/presentation/viewmodels/notification/notification_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/property/home_search_screen.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/banner.dart';
import 'package:zoneer_mobile/core/providers/navigation_provider.dart';
import 'package:zoneer_mobile/presentation/viewmodels/user/user_provider.dart';
import 'package:zoneer_mobile/shared/widgets/location_permission_dialog.dart';
import 'package:zoneer_mobile/shared/widgets/search_bar.dart';

class HomeHeader extends ConsumerStatefulWidget {
  const HomeHeader({super.key, required this.isCollapsed});
  final bool isCollapsed;

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<HomeHeader>
    with TickerProviderStateMixin {
  late AnimationController _notificationController;
  late AnimationController _accountController;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _notificationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _accountController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _notificationController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _handleLocationRequest() async {
    final permissionState = ref.read(locationPermissionProvider);

    // If already has permission, just get city from current location
    if (permissionState.hasPermission && permissionState.userLocation != null) {
      setState(() => _isLoadingLocation = true);
      try {
        // Get city from the cached location in permission provider
        final locationService = ref.read(locationServiceProvider);
        final city = await locationService.getCityFromCoordinates(
          permissionState.userLocation!.latitude,
          permissionState.userLocation!.longitude,
        );

        if (city != null && mounted) {
          ref.read(currentCityProvider.notifier).updateCity(city);
        } else if (mounted) {
          // Fallback to fetching fresh location
          await ref.read(locationPermissionProvider.notifier).refreshLocation();
          final updatedState = ref.read(locationPermissionProvider);

          if (updatedState.userLocation != null) {
            final newCity = await locationService.getCityFromCoordinates(
              updatedState.userLocation!.latitude,
              updatedState.userLocation!.longitude,
            );
            if (newCity != null) {
              ref.read(currentCityProvider.notifier).updateCity(newCity);
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
      }
      return;
    }

    // Show custom permission dialog
    final granted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocationPermissionDialog(),
    );

    if (granted == true && mounted) {
      setState(() => _isLoadingLocation = true);
      try {
        // After permission granted, get location and reverse geocode
        final updatedState = ref.read(locationPermissionProvider);

        if (updatedState.userLocation != null) {
          final locationService = ref.read(locationServiceProvider);
          final city = await locationService.getCityFromCoordinates(
            updatedState.userLocation!.latitude,
            updatedState.userLocation!.longitude,
          );

          if (city != null && mounted) {
            ref.read(currentCityProvider.notifier).updateCity(city);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
      }
    }
  }

  Future<void> _autoUpdateCityFromLocation(LatLng location) async {
    final currentCity = ref.read(currentCityProvider);
    if (currentCity != 'Current Location') return;

    try {
      final locationService = ref.read(locationServiceProvider);
      final city = await locationService.getCityFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (city != null && mounted) {
        ref.read(currentCityProvider.notifier).updateCity(city);
      }
    } catch (_) {
      // Silent failure — user can still tap to retry
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCity = ref.watch(currentCityProvider);

    ref.listen<LocationPermissionState>(locationPermissionProvider, (
      previous,
      next,
    ) {
      final hadLocation = previous?.userLocation != null;
      final hasLocation = next.userLocation != null;

      if (!hadLocation && hasLocation && !_isLoadingLocation) {
        _autoUpdateCityFromLocation(next.userLocation!);
      }
    });
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final user = ref.watch(authServiceProvider).currentUser;

    // Uploaded profile image takes priority over Google OAuth avatar
    final googleAvatar = user?.userMetadata?['avatar_url'] as String?;
    final dbUser = user != null
        ? ref.watch(userProfileOrCreateProvider(user.id)).asData?.value
        : null;
    final avatar = (dbUser?.profileUrl?.isNotEmpty == true)
        ? dbUser!.profileUrl!
        : googleAvatar;

    return Container(
      decoration: BoxDecoration(
        color: isAuthenticated ? AppColors.primary : AppColors.white,

        borderRadius: isAuthenticated
            ? BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              )
            : BorderRadius.circular(0),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, widget.isCollapsed ? 12 : 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _isLoadingLocation
                              ? null
                              : _handleLocationRequest,
                          child: SvgPicture.asset(
                            'assets/icons/map-pin-house.svg',
                            width: 32,
                            height: 32,
                            colorFilter: isAuthenticated
                                ? const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: GestureDetector(
                            onTap: _isLoadingLocation
                                ? null
                                : _handleLocationRequest,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isAuthenticated
                                    ? Colors.white24
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: _isLoadingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: AppColors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      currentCity,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: isAuthenticated
                                  ? AppColors.white
                                  : Colors.transparent,
                              side: BorderSide(
                                color: isAuthenticated
                                    ? Colors.white24
                                    : AppColors.greyLight,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            icon: Lottie.asset(
                              'assets/icons/system-solid-46-notification-bell-hover-bell.json',
                              controller: _notificationController,
                              width: 28,
                              height: 28,
                              onLoaded: (composition) {
                                _notificationController.duration =
                                    composition.duration;
                              },
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationScreen(),
                                ),
                              );
                            },
                          ),
                          // Unread dot badge
                          Builder(
                            builder: (ctx) {
                              final notifications = ref
                                  .watch(notificationsViewModelProvider)
                                  .value;
                              final hasUnread = notifications != null &&
                                  notifications.any((n) => !n.isRead);
                              if (!hasUnread) return const SizedBox.shrink();
                              return Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      if (isAuthenticated) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => ref
                              .read(navigationProvider.notifier)
                              .changeTab(NavigationTab.profile),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: avatar != null
                                ? NetworkImage(avatar)
                                : null,
                            backgroundColor: Colors.white24,
                            child: avatar == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              isAuthenticated ? const SizedBox(height: 10) : SizedBox.shrink(),
            
              const SearchBarApp(),

              (isAuthenticated && !widget.isCollapsed)
                  ? BannerZoneer(
                      onBrowseNow: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeSearchScreen(
                            initialSection: SectionFilter.all,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
