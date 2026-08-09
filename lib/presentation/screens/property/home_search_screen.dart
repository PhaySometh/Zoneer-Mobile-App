import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/providers/location_permission_provider.dart';
import 'package:zoneer_mobile/core/providers/navigation_provider.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/property_sections_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/property/property_detail_page.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/property_card.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/search_filter_sheet.dart';

enum SectionFilter { all, nearby, phnomPenh, siemReap }

extension SectionFilterX on SectionFilter {
  String get key => switch (this) {
        SectionFilter.all => 'all',
        SectionFilter.nearby => 'nearby',
        SectionFilter.phnomPenh => 'phnom_penh',
        SectionFilter.siemReap => 'siem_reap',
      };

  String get label => switch (this) {
        SectionFilter.all => 'All Properties',
        SectionFilter.nearby => 'Nearby',
        SectionFilter.phnomPenh => 'Phnom Penh',
        SectionFilter.siemReap => 'Siem Reap',
      };

  static SectionFilter fromKey(String key) => switch (key) {
        'nearby' => SectionFilter.nearby,
        'phnom_penh' => SectionFilter.phnomPenh,
        'siem_reap' => SectionFilter.siemReap,
        _ => SectionFilter.all,
      };
}

class HomeSearchScreen extends ConsumerStatefulWidget {
  final SectionFilter? initialSection;
  final String? initialType;

  const HomeSearchScreen({super.key, this.initialSection, this.initialType});

  @override
  ConsumerState<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends ConsumerState<HomeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic>? _activeFilters;

  // Tracks the current section — starts from initialSection, can be changed via filter
  late SectionFilter _currentSection;

  @override
  void initState() {
    super.initState();
    _currentSection = widget.initialSection ?? SectionFilter.all;
    final hasInitialFilter =
        (_currentSection != SectionFilter.all) || (widget.initialType != null);
    if (hasInitialFilter) {
      _activeFilters = {
        if (widget.initialType != null) 'selectedType': widget.initialType!,
        'section': _currentSection.key,
      };
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters => _activeFilters != null;

  List<_PropertyEntry> _applyFilters(List<_PropertyEntry> entries) {
    var result = entries;

    // Text query filter
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((e) {
        final name = e.property.name?.toLowerCase() ?? '';
        final address = e.property.address.toLowerCase();
        return name.contains(q) || address.contains(q);
      }).toList();
    }

    if (_activeFilters == null) return result;

    // Price range
    final range =
        (_activeFilters!['priceRange'] as RangeValues?) ??
        const RangeValues(0, 10000);
    result = result.where((e) {
      final price = e.property.price.toDouble();
      return price >= range.start && price <= range.end;
    }).toList();

    // Beds
    final minBeds = (_activeFilters!['beds'] as int?) ?? 1;
    result = result
        .where((e) => e.property.bedroom >= minBeds)
        .toList();

    // Baths
    final minBaths = (_activeFilters!['baths'] as int?) ?? 1;
    result = result
        .where((e) => e.property.bathroom >= minBaths)
        .toList();

    // Property type
    final type = (_activeFilters!['selectedType'] as String?) ?? 'Any';
    if (type.toLowerCase() != 'any' && type.isNotEmpty) {
      result = result
          .where(
            (e) =>
                e.property.type?.toLowerCase() == type.toLowerCase(),
          )
          .toList();
    }

    return result;
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => SearchFilterSheet(
        initialFilters: {
          ...?_activeFilters,
          'section': _currentSection.key,
        },
      ),
    );

    if (result != null) {
      setState(() {
        _activeFilters = result;
        _currentSection = SectionFilterX.fromKey(
          result['section'] as String? ?? 'all',
        );
      });
    }
  }

  Widget _buildResults(List<_PropertyEntry> filtered, double screenWidth) {
    if (filtered.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'No properties match your search.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final isMobile = screenWidth < 600;

    if (isMobile) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final entry = filtered[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyDetailPage(id: entry.property.id),
                  ),
                ),
                child: PropertyCard(
                  property: entry.property,
                  distanceMeters: entry.distanceMeters,
                  highlightQuery: _searchQuery.trim().isEmpty
                      ? null
                      : _searchQuery.trim(),
                ),
              ),
            );
          },
          childCount: filtered.length,
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 350 / 220,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = filtered[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailPage(id: entry.property.id),
              ),
            ),
            child: PropertyCard(
              property: entry.property,
              distanceMeters: entry.distanceMeters,
              highlightQuery: _searchQuery.trim().isEmpty
                  ? null
                  : _searchQuery.trim(),
            ),
          );
        },
        childCount: filtered.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationPermissionProvider);
    final hasLocation =
        locationState.hasPermission && locationState.userLocation != null;
    final userLocation = locationState.userLocation;
    final screenWidth = MediaQuery.of(context).size.width;

    AsyncValue<List<_PropertyEntry>> entriesAsync;

    if (_currentSection == SectionFilter.nearby) {
      if (!hasLocation || userLocation == null) {
        entriesAsync = const AsyncValue.data([]);
      } else {
        final activeType = (_activeFilters?['selectedType'] as String?) ?? '';
        final nearbyAsync = ref.watch(nearbyPropertiesSectionProvider((
          lat: userLocation.latitude,
          lng: userLocation.longitude,
          type: activeType.toLowerCase() == 'any' ? '' : activeType,
        )));
        entriesAsync = nearbyAsync.whenData(
          (list) => list
              .map((t) => _PropertyEntry(property: t.$1, distanceMeters: t.$2))
              .toList(),
        );
      }
    } else {
      final AsyncValue<List<PropertyModel>> propsAsync =
          switch (_currentSection) {
            SectionFilter.phnomPenh => ref.watch(phnomPenhAllProvider),
            SectionFilter.siemReap => ref.watch(siemReapAllProvider),
            _ => ref.watch(allPropertiesAllProvider),
          };
      entriesAsync = propsAsync.whenData(
        (list) => list.map((p) => _PropertyEntry(property: p)).toList(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 40,
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pop(context);
            ref.read(navigationProvider.notifier).changeTab(NavigationTab.map);
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.map, color: Colors.white, size: 18),
          label: const Text(
            'Map View',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          debugPrint('HomeSearchScreen error: $e');
          return const Center(
            child: Text(
              'Something went wrong. Please try again.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        },
        data: (allEntries) {
          final filtered = _applyFilters(allEntries);

          if (_currentSection == SectionFilter.nearby &&
              (!hasLocation || userLocation == null)) {
            return CustomScrollView(
              slivers: [
                _buildStickyHeader(0),
                const SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Enable location to see nearby properties.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final showChip = _currentSection != SectionFilter.all;

          return CustomScrollView(
            slivers: [
              _buildStickyHeader(filtered.length),
              if (showChip)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 8, 15, 0),
                    child: Row(
                      children: [
                        Chip(
                          label: Text(
                            _currentSection.label,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 80),
                sliver: _buildResults(filtered, screenWidth),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStickyHeader(int count) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFFF6F6F6),
      elevation: 0,
      titleSpacing: 15,
      title: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        shadowColor: Colors.black26,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name or location...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              // Filter button with active indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: _openFilterSheet,
                    icon: Icon(
                      Icons.tune,
                      color: _hasActiveFilters
                          ? AppColors.primary
                          : Colors.grey[700],
                    ),
                  ),
                  if (_hasActiveFilters)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(_hasActiveFilters ? 56 : 36),
        child: Container(
          width: double.infinity,
          color: const Color(0xFFF6F6F6),
          padding: const EdgeInsets.fromLTRB(15, 4, 15, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count Properties Found',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (_hasActiveFilters)
                GestureDetector(
                  onTap: () => setState(() {
                    _activeFilters = null;
                    _currentSection =
                        widget.initialSection ?? SectionFilter.all;
                  }),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'Clear filters',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyEntry {
  final PropertyModel property;
  final double? distanceMeters;

  _PropertyEntry({required this.property, this.distanceMeters});
}
