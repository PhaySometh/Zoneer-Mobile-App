enum Role {
  tenant('tenant'),
  landlord('landlord');

  final String value;

  const Role(this.value);

  static Role fromValue(String? value) {
    return Role.values.firstWhere((e) => e.value == value);
  }
}
