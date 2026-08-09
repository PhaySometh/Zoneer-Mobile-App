import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';
import 'package:zoneer_mobile/data/repositories/property/property_repository.dart';

/// Selected category filter on the home screen.
/// Empty string means "All" (no type filter applied).
final selectedHomeCategoryProvider =
    NotifierProvider<_SelectedHomeCategoryNotifier, String>(
  _SelectedHomeCategoryNotifier.new,
);

class _SelectedHomeCategoryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

/// All verified properties (optionally filtered by type).
final allPropertiesSectionProvider =
    FutureProvider.family<List<PropertyModel>, String>((ref, type) async {
  final repo = ref.read(propertyRepositoryProvider);
  return repo.getVerifiedPropertiesSection(
    limit: 20,
    type: type.isEmpty ? null : type,
  );
});

/// Properties in Phnom Penh (optionally filtered by type).
final phnomPenhSectionProvider =
    FutureProvider.family<List<PropertyModel>, String>((ref, type) async {
  final repo = ref.read(propertyRepositoryProvider);
  return repo.getVerifiedPropertiesSection(
    limit: 20,
    addressContains: 'Phnom Penh',
    type: type.isEmpty ? null : type,
  );
});

/// Properties in Siem Reap (optionally filtered by type).
final siemReapSectionProvider =
    FutureProvider.family<List<PropertyModel>, String>((ref, type) async {
  final repo = ref.read(propertyRepositoryProvider);
  return repo.getVerifiedPropertiesSection(
    limit: 20,
    addressContains: 'Siem Reap',
    type: type.isEmpty ? null : type,
  );
});

/// All verified properties for HomeSearchScreen (no type filter, large limit).
final allPropertiesAllProvider = FutureProvider<List<PropertyModel>>((ref) async {
  return ref
      .read(propertyRepositoryProvider)
      .getVerifiedPropertiesSection(limit: 200);
});

/// Phnom Penh properties for HomeSearchScreen (no type filter, large limit).
final phnomPenhAllProvider = FutureProvider<List<PropertyModel>>((ref) async {
  return ref
      .read(propertyRepositoryProvider)
      .getVerifiedPropertiesSection(limit: 200, addressContains: 'Phnom Penh');
});

/// Siem Reap properties for HomeSearchScreen (no type filter, large limit).
final siemReapAllProvider = FutureProvider<List<PropertyModel>>((ref) async {
  return ref
      .read(propertyRepositoryProvider)
      .getVerifiedPropertiesSection(limit: 200, addressContains: 'Siem Reap');
});

/// Nearby properties within 20 km, sorted by distance.
/// Returns a list of (PropertyModel, distanceMeters) tuples.
final nearbyPropertiesSectionProvider = FutureProvider.family<
    List<(PropertyModel, double)>,
    ({double lat, double lng, String type})>((ref, args) async {
  final repo = ref.read(propertyRepositoryProvider);
  return repo.getNearbyProperties(
    userLat: args.lat,
    userLng: args.lng,
    radiusKm: 20.0,
    type: args.type.isEmpty ? null : args.type,
  );
});
