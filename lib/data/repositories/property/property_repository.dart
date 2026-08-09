import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/services/supabase_service.dart';
import 'package:zoneer_mobile/data/models/property/property_filter_model.dart';
import 'package:zoneer_mobile/data/models/property/media_model.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';
import 'package:zoneer_mobile/shared/models/enums/verify_status.dart';

class PropertyRepository {
  final SupabaseService _supabase;

  PropertyRepository(this._supabase);

  Future<PropertyModel> getPropertyById(String id) async {
    final response = await _supabase
        .from('properties')
        .select()
        .eq('id', id)
        .single();
    return PropertyModel.fromJson(response);
  }

  Future<List<PropertyModel>> getPropertiesByLandlordId(
    String landlordId,
  ) async {
    final response = await _supabase
        .from('properties')
        .select()
        .eq('landlord_id', landlordId);
    return (response as List).map((e) => PropertyModel.fromJson(e)).toList();
  }

  Future<List<PropertyModel>> getPropertiesMissingCoordinates({
    int limit = 500,
  }) async {
    final response = await _supabase
        .from('properties')
        .select()
        .or('latitude.is.null,longitude.is.null')
        .limit(limit);

    return (response as List).map((e) => PropertyModel.fromJson(e)).toList();
  }

  Future<List<PropertyModel>> getVerifiedPropertiesSection({
    int limit = 20,
    int? minBedroom,
    int? minBathroom,
    String? addressContains,
    String? type,
  }) async {
    var query = _supabase
        .from('properties')
        .select()
        .eq('verify_status', VerifyStatus.verified.value);

    if (minBedroom != null) {
      query = query.gte('bedroom', minBedroom);
    }
    if (minBathroom != null) {
      query = query.gte('bathroom', minBathroom);
    }
    if (addressContains != null && addressContains.trim().isNotEmpty) {
      query = query.ilike('address', '%${addressContains.trim()}%');
    }
    if (type != null && type.trim().isNotEmpty) {
      query = query.eq('type', type.trim());
    }

    final response = await query.limit(limit);
    return (response as List).map((e) => PropertyModel.fromJson(e)).toList();
  }

  /// Returns properties within [radiusKm] of the given coordinates,
  /// sorted by ascending distance. Each entry is (PropertyModel, distanceMeters).
  Future<List<(PropertyModel, double)>> getNearbyProperties({
    required double userLat,
    required double userLng,
    double radiusKm = 20.0,
    String? type,
    int fetchLimit = 300,
  }) async {
    var query = _supabase
        .from('properties')
        .select()
        .eq('verify_status', VerifyStatus.verified.value)
        .not('latitude', 'is', null)
        .not('longitude', 'is', null);

    if (type != null && type.trim().isNotEmpty) {
      query = query.eq('type', type.trim());
    }

    final response = await query.limit(fetchLimit);
    final all = (response as List).map((e) => PropertyModel.fromJson(e)).toList();

    final nearby = <(PropertyModel, double)>[];
    for (final p in all) {
      if (p.latitude == null || p.longitude == null) continue;
      final distanceMeters = Geolocator.distanceBetween(
        userLat,
        userLng,
        p.latitude!,
        p.longitude!,
      );
      if (distanceMeters <= radiusKm * 1000) {
        nearby.add((p, distanceMeters));
      }
    }
    nearby.sort((a, b) => a.$2.compareTo(b.$2));
    return nearby;
  }

  Future<List<PropertyModel>> getMapProperties({
    required PropertyFilterModel filter,
    int limit = 200,
  }) async {
    var query = _supabase
        .from('properties')
        .select()
        .eq('verify_status', VerifyStatus.verified.value)
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)
        .gte('price', filter.minPrice)
        .lte('price', filter.maxPrice);

    if (filter.beds != null) {
      query = filter.beds == 5
          ? query.gte('bedroom', 5)
          : query.eq('bedroom', filter.beds!);
    }

    final normalizedType = filter.propertyType.trim().toLowerCase();
    if (normalizedType.isNotEmpty && normalizedType != 'any') {
      query = query.eq('type', filter.propertyType.trim());
    }

    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = filter.searchQuery!.trim();
      query = query.or('address.ilike.%$q%,description.ilike.%$q%');
    }

    final response = await query.limit(limit);
    return (response as List).map((e) => PropertyModel.fromJson(e)).toList();
  }

  Future<List<PropertyModel>> searchVerifiedProperties({
    String? query,
    double? minPrice,
    double? maxPrice,
    int? minBeds,
    int? minBaths,
    String? type,
    int limit = 200,
  }) async {
    var request = _supabase
        .from('properties')
        .select(
          'id, name, price, bedroom, bathroom, square_area, address, thumbnail_url',
        )
        .eq('verify_status', VerifyStatus.verified.value);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();
      request = request.or('name.ilike.%$q%,address.ilike.%$q%,description.ilike.%$q%');
    }
    if (minPrice != null) {
      request = request.gte('price', minPrice);
    }
    if (maxPrice != null) {
      request = request.lte('price', maxPrice);
    }
    if (minBeds != null) {
      request = request.gte('bedroom', minBeds);
    }
    if (minBaths != null) {
      request = request.gte('bathroom', minBaths);
    }
    if (type != null &&
        type.trim().isNotEmpty &&
        type.trim().toLowerCase() != 'any') {
      request = request.eq('type', type.trim());
    }

    final response = await request.limit(limit);
    return (response as List).map((e) => PropertyModel.fromJson(e)).toList();
  }

  Future<PropertyModel> createProperty(PropertyModel property) async {
    final response = await _supabase
        .from('properties')
        .insert(property.toJson())
        .select()
        .single();

    return PropertyModel.fromJson(response);
  }

  Future<void> updateProperty(PropertyModel property) async {
    await _supabase
        .from('properties')
        .update(property.toJson())
        .eq('id', property.id);
  }

  Future<void> deleteProperty(String id) async {
    await _supabase.from('properties').delete().eq('id', id);
  }

  Future<String> uploadThumbnail(Uint8List bytes, String ext, String userId) =>
      uploadImage(bytes, ext, userId);

  /// Uploads a single image to storage and returns the public URL.
  /// [index] is appended to the filename to prevent collisions when uploading
  /// multiple images in the same millisecond.
  Future<String> uploadImage(
    Uint8List bytes,
    String ext,
    String userId, {
    int index = 0,
    String? contentType,
  }) async {
    final fileName =
        'properties/$userId/${DateTime.now().millisecondsSinceEpoch}_$index.$ext';
    const bucketName = 'properties_image';
    await _supabase.storage
        .from(bucketName)
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType ?? 'image/jpeg',
          ),
        );
    return _supabase.storage.from(bucketName).getPublicUrl(fileName);
  }

  Future<List<MediaModel>> getPropertyMedias(String propertyId) async {
    final response = await _supabase
        .from('media')
        .select()
        .eq('property_id', propertyId);
    return (response as List).map((e) => MediaModel.fromJson(e)).toList();
  }

  Future<void> insertPropertyMedias(
    String propertyId,
    List<String> urls,
  ) async {
    if (urls.isEmpty) return;
    await _supabase
        .from('media')
        .insert(
          urls.map((url) => {'url': url, 'property_id': propertyId}).toList(),
        );
  }

  Future<void> deletePropertyMediasByPropertyId(String propertyId) async {
    await _supabase.from('media').delete().eq('property_id', propertyId);
  }

  /// Deletes image files from Supabase Storage given their public URLs.
  Future<void> deleteStorageImages(List<String> publicUrls) async {
    const bucketName = 'properties_image';
    const marker = '$bucketName/';
    final paths = publicUrls
        .map((url) {
          final idx = url.indexOf(marker);
          return idx == -1 ? null : url.substring(idx + marker.length);
        })
        .whereType<String>()
        .toList();
    if (paths.isEmpty) return;
    await _supabase.storage.from(bucketName).remove(paths);
  }

  Future<List<PropertyModel>> getPropertiesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final response = await _supabase
        .from('properties')
        .select()
        .inFilter('id', ids);
    return (response as List).map((e) => PropertyModel.fromJson(e)).toList();
  }

  /// Batch update properties with new data (for migrations)
  Future<void> batchUpdateProperties(List<PropertyModel> properties) async {
    for (final property in properties) {
      await updateProperty(property);
    }
  }
}

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return PropertyRepository(supabase);
});
