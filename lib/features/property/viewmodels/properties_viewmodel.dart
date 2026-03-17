import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/features/property/models/property_model.dart';
import 'package:zoneer_mobile/features/property/repositories/property_repository.dart';
import 'package:zoneer_mobile/features/property/viewmodels/property_filter_provider.dart';

typedef SearchPropertiesParams = ({
  String query,
  String? type,
  double minPrice,
  double maxPrice,
  int minBeds,
  int minBaths,
});

final landlordPropertiesProvider =
    FutureProvider.family<List<PropertyModel>, String>((ref, landlordId) async {
      return ref
          .read(propertyRepositoryProvider)
          .getPropertiesByLandlordId(landlordId);
    });

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
  final property = await ref
      .read(propertyRepositoryProvider)
      .getPropertyById(id);

  return property;
});
