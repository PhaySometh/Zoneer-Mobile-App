import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/providers/location_permission_provider.dart';
import 'package:zoneer_mobile/core/services/auth_service.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/property_sections_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/property/home_search_screen.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/banner.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/home_header.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/home_properties_category.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/home_property_section.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 0 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 0 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(allPropertiesSectionProvider);
    ref.invalidate(phnomPenhSectionProvider);
    ref.invalidate(siemReapSectionProvider);
    ref.invalidate(nearbyPropertiesSectionProvider);
  }

  void _navigateToSection(String title, String sectionKey) {
    final filter = switch (sectionKey) {
      'nearby' => SectionFilter.nearby,
      'phnom_penh' => SectionFilter.phnomPenh,
      'siem_reap' => SectionFilter.siemReap,
      _ => SectionFilter.all,
    };
    final selectedType = ref.read(selectedHomeCategoryProvider);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeSearchScreen(
          initialSection: filter,
          initialType: selectedType.isEmpty ? null : selectedType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final locationState = ref.watch(locationPermissionProvider);
    final hasLocation = locationState.hasPermission && locationState.userLocation != null;
    final userLocation = locationState.userLocation;
    final selectedType = ref.watch(selectedHomeCategoryProvider);

    final topPadding = MediaQuery.of(context).padding.top;
    // Collapsed: statusBar + topPad(12) + locationRow(32) + searchBar(55) + botPad(12) + buffer(4)
    final collapsedH = topPadding + 90;
    // Expanded (auth): collapsed content + gap(10) + banner(155) + buffer(8)
    final expandedH = isAuthenticated ? topPadding + 230 : collapsedH;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
        slivers: [
          SliverAppBar(
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final isCollapsed = constraints.maxHeight <= collapsedH + 20;
                return ClipRRect(
                  child: HomeHeader(isCollapsed: isCollapsed),
                );
              },
            ),
            pinned: true,
            expandedHeight: expandedH,
            collapsedHeight: collapsedH,
            elevation: _isScrolled ? 4 : 0,
            shadowColor: Colors.black26,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Banner for non-authenticated users
                if (!isAuthenticated)
                  BannerZoneer(
                    onBrowseNow: () => _navigateToSection('All Properties', 'all'),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                const HomePropertiesCategory(),
                const SizedBox(height: 10),

                // Nearby section — only when location permission is granted
                if (hasLocation && userLocation != null)
                  HomePropertySection(
                    title: 'Nearby',
                    emptyMessage: 'No properties found within 20 km\nof your location.',
                    onSeeAll: () => _navigateToSection('Nearby', 'nearby'),
                    nearbyAsync: ref.watch(
                      nearbyPropertiesSectionProvider((
                        lat: userLocation.latitude,
                        lng: userLocation.longitude,
                        type: selectedType,
                      )),
                    ),
                  ),

                // All Properties
                HomePropertySection(
                  title: 'All Properties',
                  emptyMessage: 'No properties available right now.',
                  onSeeAll: () => _navigateToSection('All Properties', 'all'),
                  propertiesAsync: ref.watch(
                    allPropertiesSectionProvider(selectedType),
                  ),
                ),

                // Phnom Penh
                HomePropertySection(
                  title: 'Phnom Penh',
                  emptyMessage: 'No properties found in\nPhnom Penh yet.',
                  onSeeAll: () => _navigateToSection('Phnom Penh', 'phnom_penh'),
                  propertiesAsync: ref.watch(
                    phnomPenhSectionProvider(selectedType),
                  ),
                ),

                // Siem Reap
                HomePropertySection(
                  title: 'Siem Reap',
                  emptyMessage: 'No properties found in\nSiem Reap yet.',
                  onSeeAll: () => _navigateToSection('Siem Reap', 'siem_reap'),
                  propertiesAsync: ref.watch(
                    siemReapSectionProvider(selectedType),
                  ),
                ),
              ]),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
