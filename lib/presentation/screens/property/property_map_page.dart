import 'package:flutter/material.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/core/utils/app_config.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoneer_mobile/core/providers/location_permission_provider.dart';
import 'package:zoneer_mobile/core/services/map_migration_service.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';
import 'package:zoneer_mobile/presentation/screens/property/providers/map_focus_provider.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/properties_viewmodel.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/property_filter_provider.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/property_map_controls.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/property_map_detail_sheet.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/property_map_marker.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/property_price_pin.dart';
import 'package:zoneer_mobile/core/providers/navigation_provider.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/search_filter_sheet.dart';
import 'package:zoneer_mobile/shared/widgets/location_permission_dialog.dart';

class PropertyMapPage extends ConsumerStatefulWidget {
  const PropertyMapPage({super.key});

  @override
  ConsumerState<PropertyMapPage> createState() => _PropertyMapPageState();
}

class _PropertyMapPageState extends ConsumerState<PropertyMapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  PropertyModel? _selectedProperty;

  /// Property whose thumbnail callout is visible (price-pin mode only).
  PropertyModel? _calloutProperty;

  // Map style
  bool _isSatellite = false;

  double _currentZoom = 12;

  static const LatLng _initialCenter = LatLng(11.5564, 104.9282);
  static const String _mapStyleKey = 'map_style_satellite';

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _runCoordinateMigration();
  }

  Future<void> _loadMapStyle() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _isSatellite = prefs.getBool(_mapStyleKey) ?? false);
    }
  }

  Future<void> _toggleMapStyle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isSatellite = !_isSatellite);
    await prefs.setBool(_mapStyleKey, _isSatellite);
  }

  Future<void> _runCoordinateMigration() async {
    const migrationKey = 'map_coordinates_migration_done';
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(migrationKey) ?? false) return;

      final migrationService = ref.read(mapMigrationServiceProvider);
      final updatedCount = await migrationService
          .addCoordinatesToExistingProperties();
      await prefs.setBool(migrationKey, true);

      if (updatedCount > 0) {
        ref.invalidate(mapPropertiesProvider);
      }
    } catch (e) {
      debugPrint('Map coordinate migration error: $e');
    }
  }

  void _onMarkerTapped(PropertyModel property, List<PropertyModel> all) {
    setState(() => _selectedProperty = property);

    // Pan map to the selected marker (Google Maps behavior)
    if (property.latitude != null && property.longitude != null) {
      _mapController.move(
        LatLng(property.latitude!, property.longitude!),
        _currentZoom < 14 ? 14.0 : _currentZoom,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PropertyMapDetailSheet(
        selectedProperty: property,
        allProperties: all,
        onPropertySelected: (p) {
          setState(() => _selectedProperty = p);
          if (p.latitude != null && p.longitude != null) {
            _mapController.move(LatLng(p.latitude!, p.longitude!), 14);
          }
        },
      ),
    ).whenComplete(
      () => setState(() {
        _selectedProperty = null;
        _calloutProperty = null;
      }),
    );
  }

  Future<void> _showFilterSheet() async {
    final current = ref.read(propertyFilterProvider);
    final Map<String, dynamic>? result =
        await showModalBottomSheet<Map<String, dynamic>?>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => SearchFilterSheet(
            initialFilters: {
              'priceRange': RangeValues(current.minPrice, current.maxPrice),
              'beds': current.beds ?? 1,
              'selectedType': current.propertyType,
            },
          ),
        );

    if (!mounted || result == null) return;

    final range = result['priceRange'] as RangeValues?;
    final beds = result['beds'] as int?;
    final selectedType = result['selectedType'] as String?;

    ref
        .read(propertyFilterProvider.notifier)
        .setFilter(
          current.copyWith(
            minPrice: range?.start,
            maxPrice: range?.end,
            beds: beds,
            clearBeds: beds == null,
            propertyType: selectedType,
            clearPropertyType:
                selectedType == null || selectedType.trim().isEmpty,
          ),
        );
  }

  // ── Marker builders ────────────────────────────────────────────────

  /// Thumbnail card markers shown when zoomed in (zoom ≥ 12).
  List<Marker> _buildThumbnailMarkers(List<PropertyModel> properties) {
    // Sort selected marker to end so it renders on top of others
    final sorted = properties
        .where((p) => p.latitude != null && p.longitude != null)
        .toList();
    if (_selectedProperty != null) {
      final idx = sorted.indexWhere((p) => p.id == _selectedProperty!.id);
      if (idx != -1) sorted.add(sorted.removeAt(idx));
    }
    return [
      for (final property in sorted)
        Marker(
          // Fixed size always — anchor never repositions on selection.
          // Visual size change is handled by AnimatedScale inside the widget.
          width: 125.0,
          height: 128.0,
          point: LatLng(property.latitude!, property.longitude!),
          alignment: Alignment.topCenter,
          child: PropertyMapMarker(
            property: property,
            isSelected: _selectedProperty?.id == property.id,
            onTap: () => _onMarkerTapped(property, properties),
          ),
        ),
    ];
  }

  /// Price-pill markers shown when zoomed out (zoom < 12).
  /// The selected property is skipped here — its callout marker replaces it.
  List<Marker> _buildPricePinMarkers(List<PropertyModel> properties) {
    return [
      for (final property in properties)
        if (property.latitude != null &&
            property.longitude != null &&
            _calloutProperty?.id != property.id)
          Marker(
            width: 80.0,
            height: 44.0,
            point: LatLng(property.latitude!, property.longitude!),
            alignment: Alignment.topCenter,
            child: PropertyPricePin(
              property: property,
              isSelected: false,
              onTap: () {
                setState(() => _calloutProperty = property);
                _mapController.move(
                  LatLng(property.latitude!, property.longitude!),
                  _currentZoom,
                );
              },
            ),
          ),
    ];
  }

  /// Single callout card shown above the tapped price pin.
  /// Uses the same thumbnail-card widget so the arrow points down to the pin.
  Marker _buildCalloutMarker(PropertyModel property, List<PropertyModel> all) {
    return Marker(
      width: 125.0,
      height: 128.0,
      point: LatLng(property.latitude!, property.longitude!),
      alignment: Alignment.topCenter,
      child: PropertyMapMarker(
        property: property,
        isSelected: true,
        onTap: () {
          setState(() => _calloutProperty = null);
          _onMarkerTapped(property, all);
        },
      ),
    );
  }

  /// Blue dot for the user's current location — always visible.
  Marker _buildUserLocationMarker(LatLng location) {
    return Marker(
      width: 24,
      height: 24,
      point: location,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(mapPropertiesProvider);
    final filter = ref.watch(propertyFilterProvider);
    final permissionState = ref.watch(locationPermissionProvider);

    ref.listen<LatLng?>(mapFocusProvider, (_, next) {
      if (next != null) {
        _mapController.move(next, 16);
        ref.read(mapFocusProvider.notifier).clear();
      }
    });

    final filteredProperties = propertiesAsync.asData?.value ?? [];
    final userLocation = permissionState.userLocation;
    final usePricePins = _currentZoom < 12;

    final tileUrl = _isSatellite
        ? AppConfig.mapboxSatelliteUrl
        : AppConfig.mapboxTileUrl;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 12,
              minZoom: 5,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (tapPosition, point) {
                if (_calloutProperty != null) {
                  setState(() => _calloutProperty = null);
                }
              },
              onPositionChanged: (camera, hasGesture) {
                final wasZoomedOut = _currentZoom < 12;
                final isZoomedOut = camera.zoom < 12;

                if (wasZoomedOut != isZoomedOut) {
                  setState(() {
                    _currentZoom = camera.zoom;
                    // Dismiss callout when zooming into thumbnail-card mode
                    if (!isZoomedOut) _calloutProperty = null;
                  });
                } else {
                  _currentZoom = camera.zoom;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.zoneer.mobile',
              ),

              // ── Property markers: price pins or thumbnail cards ──
              if (usePricePins)
                MarkerLayer(markers: _buildPricePinMarkers(filteredProperties))
              else
                MarkerLayer(
                  markers: _buildThumbnailMarkers(filteredProperties),
                ),

              // ── Callout popup (price-pin mode only) ──────────────
              if (usePricePins && _calloutProperty != null)
                MarkerLayer(
                  markers: [
                    _buildCalloutMarker(_calloutProperty!, filteredProperties),
                  ],
                ),

              // ── User location dot (always visible) ───────────────
              if (userLocation != null)
                MarkerLayer(markers: [_buildUserLocationMarker(userLocation)]),
            ],
          ),

          // ── Loading indicator (non-blocking) ─────────────────
          if (propertiesAsync.isLoading)
            const Positioned(
              bottom: 110,
              left: 0,
              right: 0,
              child: Center(child: CircularProgressIndicator()),
            ),

          // ── Error banner ─────────────────────────────────────
          if (propertiesAsync.hasError)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              child: Material(
                borderRadius: BorderRadius.circular(12),
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Failed to load properties',
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(mapPropertiesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Top search & filter bar ───────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Material(
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
                    // Back to search list view
                    IconButton(
                      onPressed: () =>
                          ref.read(mapTabViewProvider.notifier).showSearch(),
                      icon: Icon(
                        Icons.format_list_bulleted,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Back to Search',
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => ref
                            .read(propertyFilterProvider.notifier)
                            .updateSearchQuery(value),
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
                          onPressed: _showFilterSheet,
                          icon: Icon(
                            Icons.tune,
                            color: filter.hasActiveFilters
                                ? AppColors.primary
                                : Colors.grey[700],
                          ),
                        ),
                        if (filter.hasActiveFilters)
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

          // ── "X properties found" pill ─────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 76,
            left: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(filteredProperties.length),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${filteredProperties.length} properties found',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          // ── Right-side FAB controls ───────────────────────────
          // Only visible when map tab is active — prevents flash during logout
          if (ref.watch(navigationProvider) == NavigationTab.map)
          Positioned(
            right: 16,
            bottom: 24,
            child: PropertyMapControls(
              onMyLocation: () async {
                if (userLocation != null) {
                  _mapController.move(userLocation, 15);
                } else {
                  final granted = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const LocationPermissionDialog(),
                  );
                  final loc = ref.read(locationPermissionProvider).userLocation;
                  if (granted == true && loc != null) {
                    _mapController.move(loc, 15);
                  }
                }
              },
            ),
          ),

          // ── Map style toggle ──────────────────────────────────
          if (ref.watch(navigationProvider) == NavigationTab.map)
          Positioned(
            right: 16,
            bottom: 84,
            child: FloatingActionButton.small(
              heroTag: 'mapStyle',
              onPressed: _toggleMapStyle,
              backgroundColor: Colors.white,
              child: Icon(
                _isSatellite ? Icons.satellite_alt : Icons.map,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
