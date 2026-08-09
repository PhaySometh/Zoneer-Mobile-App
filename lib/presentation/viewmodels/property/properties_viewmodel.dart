import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';
import 'package:zoneer_mobile/data/repositories/property/property_repository.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/property_filter_provider.dart';

typedef SearchPropertiesParams = ({
  String query,
  String? type,
  double minPrice,
  double maxPrice,
  int minBeds,
  int minBaths,
});

class LandlordPropertiesNotifier extends AsyncNotifier<List<PropertyModel>> {
  final String landlordId;

  LandlordPropertiesNotifier(this.landlordId);

  @override
  Future<List<PropertyModel>> build() async {
    return ref
        .read(propertyRepositoryProvider)
        .getPropertiesByLandlordId(landlordId);
  }

  /// Prepends [property] to the list immediately (no network round-trip).
  void prependProperty(PropertyModel property) {
    final current = state.value;
    if (current != null) {
      state = AsyncData([property, ...current]);
    }
  }

  /// Removes the property with [id] from the list immediately.
  void removeProperty(String id) {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.where((p) => p.id != id).toList());
    }
  }
}

final landlordPropertiesProvider = AsyncNotifierProvider.family<
    LandlordPropertiesNotifier,
    List<PropertyModel>,
    String>(
  (landlordId) => LandlordPropertiesNotifier(landlordId),
);

final mapPropertiesProvider = FutureProvider<List<PropertyModel>>((ref) async {
  final filter = ref.watch(propertyFilterProvider);
  return ref
      .read(propertyRepositoryProvider)
      .getMapProperties(filter: filter, limit: 200);
});

final searchPropertiesProvider =
    FutureProvider.family<List<PropertyModel>, SearchPropertiesParams>((
      ref,
      params,
    ) async {
      return ref
          .read(propertyRepositoryProvider)
          .searchVerifiedProperties(
            query: params.query,
            minPrice: params.minPrice,
            maxPrice: params.maxPrice,
            minBeds: params.minBeds,
            minBaths: params.minBaths,
            type: params.type,
            limit: 200,
          );
    });

final propertyViewModelProvider = FutureProvider.family<PropertyModel, String>((
  ref,
  id,
) async {
  return ref
      .read(propertyRepositoryProvider)
      .getPropertyById(id);
});
