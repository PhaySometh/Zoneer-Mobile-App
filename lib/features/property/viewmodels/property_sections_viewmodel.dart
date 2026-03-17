import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/features/property/models/property_model.dart';
import 'package:zoneer_mobile/features/property/repositories/property_repository.dart';

enum PropertySection { room, condo, apartment, house }

final propertySectionProvider =
    FutureProvider.family<List<PropertyModel>, PropertySection>((
      ref,
      section,
    ) async {
      final repo = ref.read(propertyRepositoryProvider);
      switch (section) {
        case PropertySection.room:
          return repo.getVerifiedPropertiesSection(limit: 20, minBathroom: 1);
        case PropertySection.condo:
          return repo.getVerifiedPropertiesSection(limit: 20, minBedroom: 1);
        case PropertySection.apartment:
          return repo.getVerifiedPropertiesSection(
            limit: 20,
            addressContains: 'Phnom Penh',
          );
        case PropertySection.house:
          return repo.getVerifiedPropertiesSection(
            limit: 20,
            addressContains: 'Siem Reap',
          );
      }
    });
