class PropertyFilterModel {
  final String? propertyType; // 'dorm', 'room', 'apartment', 'house'
  final double minPrice;
  final double maxPrice;
  final int? beds; // null means 'Any'
  final String? searchQuery;

  // Sentinel defaults — when the user hasn't touched the filter we show everything.
  static const double defaultMinPrice = 0;
  static const double defaultMaxPrice = 10000;

  const PropertyFilterModel({
    this.propertyType,
    this.minPrice = defaultMinPrice,
    this.maxPrice = defaultMaxPrice,
    this.beds,
    this.searchQuery,
  });

  PropertyFilterModel copyWith({
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    int? beds,
    String? searchQuery,
    bool clearPropertyType = false,
    bool clearBeds = false,
    bool clearSearchQuery = false,
  }) {
    return PropertyFilterModel(
      propertyType: clearPropertyType
          ? null
          : propertyType ?? this.propertyType,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      beds: clearBeds ? null : beds ?? this.beds,
      searchQuery: clearSearchQuery ? null : searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters {
    return propertyType != null ||
        minPrice != defaultMinPrice ||
        maxPrice != defaultMaxPrice ||
        beds != null;
  }

  PropertyFilterModel reset() {
    return const PropertyFilterModel();
  }
}
