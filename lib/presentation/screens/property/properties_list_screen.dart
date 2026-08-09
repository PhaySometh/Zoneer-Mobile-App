import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/providers/navigation_provider.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/property_filter_provider.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/properties_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/property/property_detail_page.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/property_card.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/search_filter_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic>? _activeFilters;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerType = ref.watch(
      propertyFilterProvider.select((filter) => filter.propertyType),
    );
    final hasProviderTypeFilter = providerType.toLowerCase() != 'any';
    final range =
        (_activeFilters?['priceRange'] as RangeValues?) ??
        const RangeValues(0, 10000);
    final minBeds = (_activeFilters?['beds'] as int?) ?? 1;
    final minBaths = (_activeFilters?['baths'] as int?) ?? 1;
    final selectedType = hasProviderTypeFilter
        ? providerType
        : (_activeFilters?['selectedType'] as String?);
    final queryType =
        selectedType != null && selectedType.toLowerCase() != 'any'
        ? selectedType
        : null;

    final propertiesAsync = ref.watch(
      searchPropertiesProvider((
        query: _searchQuery,
        type: queryType,
        minPrice: range.start,
        maxPrice: range.end,
        minBeds: minBeds,
        minBaths: minBaths,
      )),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 40,
        child: FloatingActionButton.extended(
          onPressed: () {
            ref.read(mapTabViewProvider.notifier).showMap();
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

      body: propertiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading properties: $error')),
        data: (filtered) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: const Color(0xFFF6F6F6),
                  floating: true,
                  snap: true,
                  elevation: 0,
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(
                      (_activeFilters != null || hasProviderTypeFilter)
                          ? 70
                          : 50,
                    ),
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFFF6F6F6),
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${filtered.length} Properties Found',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_activeFilters != null || hasProviderTypeFilter)
                            GestureDetector(
                              onTap: () => setState(() {
                                _activeFilters = null;
                                ref
                                    .read(propertyFilterProvider.notifier)
                                    .updatePropertyType('Any');
                              }),
                              child: const Padding(
                                padding: EdgeInsets.only(top: 4),
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
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Search properties...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey[600],
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                onPressed: _openFilterSheet,
                                icon: Icon(
                                  Icons.tune,
                                  color:
                                      (_activeFilters != null ||
                                          hasProviderTypeFilter)
                                      ? AppColors.primary
                                      : Colors.grey[700],
                                ),
                              ),
                              if (_activeFilters != null ||
                                  hasProviderTypeFilter)
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
                ),
              ];
            },
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No properties match your criteria.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.only(bottom: 5),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 15,
                                  childAspectRatio: 1.25,
                                ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final property = filtered[index];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PropertyDetailPage(id: property.id),
                                  ),
                                ),
                                child: PropertyCard(property: property),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => SearchFilterSheet(
        initialFilters:
            _activeFilters ??
            {'selectedType': ref.read(propertyFilterProvider).propertyType},
      ),
    );
    if (result != null) {
      setState(() => _activeFilters = result);
      ref
          .read(propertyFilterProvider.notifier)
          .updatePropertyType(result['selectedType'] as String?);
    }
  }
}
