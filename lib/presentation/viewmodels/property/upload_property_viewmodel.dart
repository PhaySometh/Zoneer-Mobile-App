import 'dart:typed_data';
import 'package:zoneer_mobile/data/models/notification/enums/notification_type.dart';
import 'package:zoneer_mobile/data/models/notification/notification_model.dart';
import 'package:zoneer_mobile/presentation/viewmodels/notification/notification_viewmodel.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/property_sections_viewmodel.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/properties_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/data/models/property/enums/property_status.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';
import 'package:zoneer_mobile/data/repositories/property/property_repository.dart';

/// Holds data for one photo slot (either new bytes or an existing URL).
typedef PhotoData = ({Uint8List? bytes, String? ext, String? mimeType, String? existingUrl});

class UploadPropertyViewModel extends Notifier<bool> {
  @override
  bool build() => false;

  Future<String> submit({
    // Thumbnail – index 0 of the photo list
    required Uint8List? thumbnailBytes,
    required String? thumbnailExt,
    required String? thumbnailMimeType,
    required String? existingThumbnailUrl,
    // Additional photos (indices 1–9)
    required List<PhotoData> additionalPhotos,
    // Existing URLs the user removed — will be deleted from storage
    required List<String> removedImageUrls,
    // The property being edited, or null when creating
    required PropertyModel? existingProperty,
    // Basic fields
    required double price,
    required int bedroom,
    required int bathroom,
    required double squareArea,
    required String address,
    required double latitude,
    required double longitude,
    required String description,
    required String type,
    required String name,
    // Amenities
    required Map<String, dynamic>? propertyFeatures,
    required Map<String, dynamic>? securityFeatures,
    required Map<String, dynamic>? badgeOptions,
    // Status (only set when editing)
    PropertyStatus? propertyStatus,
  }) async {
    final locationUrl = 'https://www.google.com/maps?q=$latitude,$longitude';

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
          contentType: thumbnailMimeType ?? 'image/jpeg',
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
            contentType: photo.mimeType ?? 'image/jpeg',
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
            type: type,
            name: name,
            landlordId: userId,
            verifyStatus: existingProperty.verifyStatus,
            propertyStatus: propertyStatus ?? existingProperty.propertyStatus,
            propertyFeatures: propertyFeatures,
            securityFeatures: securityFeatures,
            badgeOptions: badgeOptions,
          ),
        );
        propertyId = existingProperty.id;
      } else {
        final createdProperty = await repo.createProperty(
          PropertyModel(
            id: '',
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
            type: type,
            name: name,
            landlordId: userId,
            propertyFeatures: propertyFeatures,
            securityFeatures: securityFeatures,
            badgeOptions: badgeOptions,
          ),
        );
        propertyId = createdProperty.id;

        // Instantly add the new property to the landlord list — no reload needed.
        ref
            .read(landlordPropertiesProvider(userId).notifier)
            .prependProperty(createdProperty);

        // Notify user the newly created property is under review.
        var helper = NotificationHelper.upload;
        final newNotification = NotificationModel(
          userId: userId,
          title: helper.title,
          message: helper.message,
          type: NotificationType.propertyVerification,
          metadata: {'property_id': propertyId},
        );
        await ref
            .read(notificationsViewModelProvider.notifier)
            .createNotification(newNotification);
        // Banner is triggered by the upload screen after dialog is dismissed.
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

      // For edit: reload landlord list to reflect changes (create case handled
      // instantly above via prependProperty).
      if (existingProperty != null) {
        ref.invalidate(landlordPropertiesProvider(userId));
      }
      // Refresh public-facing property queries.
      ref.invalidate(mapPropertiesProvider);
      ref.invalidate(allPropertiesSectionProvider);
      ref.invalidate(phnomPenhSectionProvider);
      ref.invalidate(siemReapSectionProvider);
      ref.invalidate(nearbyPropertiesSectionProvider);
      return propertyId;
    } finally {
      state = false;
    }
  }
}

final uploadPropertyViewModelProvider =
    NotifierProvider<UploadPropertyViewModel, bool>(
      UploadPropertyViewModel.new,
    );
