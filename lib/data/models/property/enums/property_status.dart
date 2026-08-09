enum PropertyStatus {
  rented('rented'),
  available('available');

  final String value;

  const PropertyStatus(this.value);

  static PropertyStatus fromValue(String? value) {
    return PropertyStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PropertyStatus.available,
    );
  }
}
