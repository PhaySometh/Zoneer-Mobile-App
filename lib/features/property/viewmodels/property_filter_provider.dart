import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/features/property/models/property_filter_model.dart';

final propertyFilterProvider =
    NotifierProvider<PropertyFilterNotifier, PropertyFilterModel>(() {
      return PropertyFilterNotifier();
    });

class PropertyFilterNotifier extends Notifier<PropertyFilterModel> {
  @override
  PropertyFilterModel build() => const PropertyFilterModel();

  void setFilter(PropertyFilterModel filter) {
    state = filter;
  }

  void updatePropertyType(String? type) {
    final normalized = (type == null || type.trim().isEmpty)
        ? 'Any'
        : type.trim();
    state = state.copyWith(propertyType: normalized);
  }

  void updatePriceRange(double min, double max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
  }

  void updateBeds(int? beds) {
    state = state.copyWith(beds: beds, clearBeds: beds == null);
  }

  void updateSearchQuery(String? query) {
    state = state.copyWith(
      searchQuery: query,
      clearSearchQuery: query == null || query.isEmpty,
    );
  }

  void reset() {
    state = state.reset();
  }
}
