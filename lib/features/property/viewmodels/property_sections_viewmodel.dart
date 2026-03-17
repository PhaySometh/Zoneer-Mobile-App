import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:zoneer_mobile/core/providers/location_permission_provider.dart';
import 'package:zoneer_mobile/features/property/models/property_model.dart';
import 'package:zoneer_mobile/features/property/providers/home_category_provider.dart';
import 'package:zoneer_mobile/features/property/viewmodels/visible_properties_provider.dart';

enum PropertySection {
  nearby,
  featured,
  phnompenh,
  siemreap,
  all,
}

final propertySectionProvider = Provider.family<AsyncValue<List<PropertyModel>>, PropertySection>((ref, section) {
  final propertiesAsync = ref.watch(visiblePropertiesProvider);
  final locationState = ref.watch(locationPermissionProvider);
  final selectedCategory = ref.watch(homeCategoryProvider);

  return propertiesAsync.whenData((allProperties) {
    // Apply home category filter across all sections
    final properties = selectedCategory == null
        ? allProperties
        : allProperties.where((p) {
            if (p.propertyType != null) {
              return p.propertyType!.toLowerCase() ==
                  selectedCategory.toLowerCase();
            }
            // Legacy fallback: keyword match
            final haystack =
                '${p.address} ${p.description ?? ''} ${p.name ?? ''}'
                    .toLowerCase();
            return haystack.contains(selectedCategory.toLowerCase());
          }).toList();
    switch (section) {
      case PropertySection.nearby:
        final userLocation = locationState.userLocation;
        if (userLocation == null) {
          return [];
        }
        // Filter within 15 km and sort by distance
        const dist = Distance();
        final nearby = properties
            .where((p) => p.latitude != null && p.longitude != null)
            .map((p) {
              final km = dist.as(
                LengthUnit.Kilometer,
                userLocation,
                LatLng(p.latitude!, p.longitude!),
              );
              return (property: p, km: km);
            })
            .where((e) => e.km <= 15)
            .toList()
          ..sort((a, b) => a.km.compareTo(b.km));
        return nearby.map((e) => e.property).toList();

      case PropertySection.featured:
        return properties.where((p) => p.bedroom >= 1).toList();

      case PropertySection.phnompenh:
        return properties
            .where((p) => p.address.toLowerCase().contains('phnom penh'))
            .toList();

      case PropertySection.siemreap:
        return properties
            .where((p) =>
                p.address.toLowerCase().contains('siem reap') ||
                p.address.toLowerCase().contains('siemreap'))
            .toList();

      case PropertySection.all:
        return properties;
    }
  });
});
