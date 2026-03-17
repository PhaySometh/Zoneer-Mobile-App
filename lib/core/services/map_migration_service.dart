import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/features/property/models/property_model.dart';
import 'package:zoneer_mobile/features/property/repositories/property_repository.dart';

/// Service to handle map-related migrations and utilities
class MapMigrationService {
  final PropertyRepository _repository;

  MapMigrationService(this._repository);

  /// Add random Cambodia coordinates to all properties missing them
  /// This is a one-time migration to enable map display for existing properties
  Future<int> addCoordinatesToExistingProperties() async {
    try {
      // Query only records that still miss coordinates.
      final propertiesNeedingCoordinates = await _repository
          .getPropertiesMissingCoordinates();

      if (propertiesNeedingCoordinates.isEmpty) {
        return 0;
      }

      // Update each property with random Cambodia coordinates
      final updatedProperties = <PropertyModel>[];
      for (final property in propertiesNeedingCoordinates) {
        final coordinates = _getRandomCambodiaCoordinates();
        final updatedProperty = property.copyWith(
          latitude: coordinates['latitude'],
          longitude: coordinates['longitude'],
        );
        updatedProperties.add(updatedProperty);
      }

      // Batch update all properties
      await _repository.batchUpdateProperties(updatedProperties);

      return updatedProperties.length;
    } catch (e) {
      debugPrint('Error adding coordinates to properties: $e');
      return 0;
    }
  }

  /// Generate random coordinates in Cambodia
  /// Returns realistic coordinates from major cities and regions
  Map<String, double> _getRandomCambodiaCoordinates() {
    final random = Random();
    final locationIndex = random.nextInt(_cambodiaLocations.length);
    return _cambodiaLocations[locationIndex];
  }

  /// Collection of realistic Cambodia location coordinates
  /// Covers major cities and popular rental areas
  static final List<Map<String, double>> _cambodiaLocations = [
    // Phnom Penh Area (Multiple zones)
    {'latitude': 11.5564, 'longitude': 104.9282}, // Central Phnom Penh
    {'latitude': 11.5449, 'longitude': 104.8922}, // Toul Kork
    {'latitude': 11.5786, 'longitude': 104.9019}, // Toul Sleng
    {'latitude': 11.5741, 'longitude': 104.9216}, // Daun Penh
    {'latitude': 11.5332, 'longitude': 104.9147}, // Chamkar Mon
    {'latitude': 11.5897, 'longitude': 104.9154}, // Russey Keo
    {'latitude': 11.5519, 'longitude': 104.9375}, // BKK1
    {'latitude': 11.5489, 'longitude': 104.9311}, // BKK2
    {'latitude': 11.5454, 'longitude': 104.9251}, // BKK3
    {'latitude': 11.5625, 'longitude': 104.9340}, // Riverside
    {'latitude': 11.5611, 'longitude': 104.8931}, // Sen Sok
    {'latitude': 11.5983, 'longitude': 104.8845}, // Chroy Changvar
    // Siem Reap Area
    {'latitude': 13.3671, 'longitude': 103.8448}, // Siem Reap City
    {'latitude': 13.4125, 'longitude': 103.8670}, // Near Angkor Wat
    {'latitude': 13.3543, 'longitude': 103.8561}, // Old Market Area
    {'latitude': 13.3622, 'longitude': 103.8593}, // Pub Street Area
    // Sihanoukville Area
    {'latitude': 10.6090, 'longitude': 103.5290}, // Sihanoukville City
    {'latitude': 10.6276, 'longitude': 103.5097}, // Ochheuteal Beach
    {'latitude': 10.6354, 'longitude': 103.5014}, // Serendipity Beach
    {'latitude': 10.5987, 'longitude': 103.5442}, // Victory Beach
    // Battambang Area
    {'latitude': 13.0957, 'longitude': 103.2022}, // Battambang City
    {'latitude': 13.1023, 'longitude': 103.1987}, // Battambang Central
    // Kampot Area
    {'latitude': 10.6104, 'longitude': 104.1817}, // Kampot City
    {'latitude': 10.6245, 'longitude': 104.1765}, // Kampot Riverside
    // Kep Area
    {'latitude': 10.4833, 'longitude': 104.3167}, // Kep City
    // Kampong Cham Area
    {'latitude': 12.0045, 'longitude': 105.4603}, // Kampong Cham City
    // Kampong Speu Area
    {'latitude': 11.4533, 'longitude': 104.5211}, // Kampong Speu City
    // Pursat Area
    {'latitude': 12.5388, 'longitude': 103.9192}, // Pursat City
  ];
}

/// Provider for map migration service
final mapMigrationServiceProvider = Provider<MapMigrationService>((ref) {
  final repository = ref.watch(propertyRepositoryProvider);
  return MapMigrationService(repository);
});
