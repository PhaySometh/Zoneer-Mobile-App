import 'dart:typed_data';
import 'package:zoneer_mobile/features/property/viewmodels/my_properties_provider.dart';
import 'package:zoneer_mobile/features/property/viewmodels/properties_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/features/property/models/property_model.dart';
import 'package:zoneer_mobile/features/property/repositories/property_repository.dart';

/// Holds data for one photo slot (either new bytes or an existing URL).
typedef PhotoData = ({Uint8List? bytes, String? ext, String? existingUrl});

class UploadPropertyViewModel extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> submit({
    // Thumbnail – index 0 of the photo list
    required Uint8List? thumbnailBytes,
    required String? thumbnailExt,
    required String? existingThumbnailUrl,
    // Additional photos (indices 1–9)
    required List<PhotoData> additionalPhotos,
    // Existing URLs the user removed — will be deleted from storage
    required List<String> removedImageUrls,
    // The property being edited, or null when creating
    required PropertyModel? existingProperty,
    // Basic fields
    required String? name,
    required double price,
    required int bedroom,
    required int bathroom,
    required double squareArea,
    required String address,
    required double latitude,
    required double longitude,
    required String? description,
    // Amenities
    required Map<String, dynamic>? propertyFeatures,
    required Map<String, dynamic>? securityFeatures,
    required Map<String, dynamic>? badgeOptions,
    required String? propertyType,
  }) async {
    final locationUrl = 'https://www.google.com/maps?q=$latitude,$longitude';
    final propertiesNotifier =
        ref.read(propertiesViewModelProvider.notifier);

    // --- Optimistic update for edits only ---
    // For NEW properties, we skip the optimistic-add to the global verified list
    // because new properties require admin verification and would immediately
    // disappear when refreshProperties() runs. Instead, we add them directly
    // to myPropertiesProvider so the owner can see them right away with a
    // "pending" badge (via visiblePropertiesProvider).
    if (existingProperty != null) {
      propertiesNotifier.optimisticallyUpdate(
        existingProperty.copyWith(
          name: name,
          clearName: name == null || name.isEmpty,
          price: price,
          bedroom: bedroom,
          bathroom: bathroom,
          squareArea: squareArea,
          address: address,
          locationUrl: locationUrl,
          latitude: latitude,
          longitude: longitude,
          description: description,
          thumbnail: existingThumbnailUrl ?? existingProperty.thumbnail,
          propertyFeatures: propertyFeatures,
          securityFeatures: securityFeatures,
          badgeOptions: badgeOptions,
          propertyType: propertyType,
        ),
      );
    }

    state = true;
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final repo = ref.read(propertyRepositoryProvider);

      // --- Upload thumbnail ---
      String thumbnailUrl = existingThumbnailUrl ?? '';
      if (thumbnailBytes != null) {
        thumbnailUrl = await repo.uploadImage(
          thumbnailBytes,
          thumbnailExt ?? 'jpg',
          userId,
          index: 0,
        );
      }

      // --- Upload any new additional images ---
      final additionalUrls = <String>[];
      for (var i = 0; i < additionalPhotos.length; i++) {
        final photo = additionalPhotos[i];
        if (photo.bytes != null) {
          final url = await repo.uploadImage(
            photo.bytes!,
            photo.ext ?? 'jpg',
            userId,
            index: i + 1,
          );
          additionalUrls.add(url);
        } else if (photo.existingUrl != null) {
          additionalUrls.add(photo.existingUrl!);
        }
      }

      // --- Persist property ---
      final String propertyId;
      if (existingProperty != null) {
        await repo.updateProperty(
          PropertyModel(
            id: existingProperty.id,
            name: name?.isNotEmpty == true ? name : null,
            price: price,
            bedroom: bedroom,
            bathroom: bathroom,
            squareArea: squareArea,
            address: address,
            locationUrl: locationUrl,
            latitude: latitude,
            longitude: longitude,
            description: description,
            thumbnail: thumbnailUrl,
            landlordId: userId,
            verifyStatus: existingProperty.verifyStatus,
            propertyStatus: existingProperty.propertyStatus,
            propertyFeatures: propertyFeatures,
            securityFeatures: securityFeatures,
            badgeOptions: badgeOptions,
            propertyType: propertyType,
          ),
        );
        propertyId = existingProperty.id;
      } else {
        // createProperty doesn't return the ID, so fetch after insert
        await repo.createProperty(
          PropertyModel(
            id: '',
            name: name?.isNotEmpty == true ? name : null,
            price: price,
            bedroom: bedroom,
            bathroom: bathroom,
            squareArea: squareArea,
            address: address,
            locationUrl: locationUrl,
            latitude: latitude,
            longitude: longitude,
            description: description,
            thumbnail: thumbnailUrl,
            landlordId: userId,
            propertyFeatures: propertyFeatures,
            securityFeatures: securityFeatures,
            badgeOptions: badgeOptions,
            propertyType: propertyType,
          ),
        );
        // Fetch the newly created property to get its ID
        final created = await repo.getPropertiesByLandlordId(userId);
        propertyId = created
            .where((p) => p.thumbnail == thumbnailUrl)
            .first
            .id;
      }

      // --- Manage property_media records ---
      if (existingProperty != null) {
        // Replace all existing media
        await repo.deletePropertyMediasByPropertyId(propertyId);
      }
      if (additionalUrls.isNotEmpty) {
        await repo.insertPropertyMedias(propertyId, additionalUrls);
      }

      // --- Delete removed files from storage ---
      if (removedImageUrls.isNotEmpty) {
        await repo.deleteStorageImages(removedImageUrls);
      }

      // --- Sync home screen with real server data ---
      // Replaces the optimistic item (fake ID) with the real record from
      // Supabase — no loading flash, guaranteed to appear on mobile.
      await propertiesNotifier.refreshProperties();

      // Also refresh "My Properties" so the landlord sees the new/updated item
      // in their own list (works regardless of verify_status).
      await ref.read(myPropertiesProvider.notifier).refresh();
    } finally {
      state = false;
    }
  }
}

final uploadPropertyViewModelProvider =
    NotifierProvider<UploadPropertyViewModel, bool>(
  UploadPropertyViewModel.new,
);
