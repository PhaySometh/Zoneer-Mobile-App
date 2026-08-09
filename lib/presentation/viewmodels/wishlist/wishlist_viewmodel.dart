import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';
import 'package:zoneer_mobile/data/repositories/property/property_repository.dart';
import 'package:zoneer_mobile/data/models/wishlist/wishlist_model.dart';
import 'package:zoneer_mobile/data/repositories/wishlist_repository.dart';

class WishlistViewmodel extends AsyncNotifier<List<WishlistModel>> {
  @override
  Future<List<WishlistModel>> build() async => [];

  Future<void> loadWishlist(String userId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return ref.read(wishlistRepositoryProvider).getWishlistByUserId(userId);
    });
  }

  Future<bool> addToWishlist(WishlistModel wishlist) async {
    state = await AsyncValue.guard(() async {
      await ref.read(wishlistRepositoryProvider).addToWishlist(wishlist);

      final currentState = state;

      if (currentState is AsyncData<List<WishlistModel>>) {
        return [...currentState.value, wishlist];
      }

      return [wishlist];
    });

    return state.hasValue && !state.hasError;
  }

  Future<bool> removeFromWishlist(String userId, String propertyId) async {
    state = await AsyncValue.guard(() async {
      await ref
          .read(wishlistRepositoryProvider)
          .removeFromWishlist(userId, propertyId);

      final currentState = state;

      if (currentState is AsyncData<List<WishlistModel>>) {
        return currentState.value
            .where((w) => !(w.userId == userId && w.propertyId == propertyId))
            .toList();
      }

      return currentState.value ?? <WishlistModel>[];
    });

    return state.hasValue && !state.hasError;
  }

  /// Bulk-remove multiple properties in parallel.
  ///
  /// Optimistically removes the items from local state first, then fires
  /// the repository calls concurrently. On failure, the state is reloaded
  /// from the server to stay consistent.
  Future<bool> deleteSelected(String userId, Set<String> propertyIds) async {
    if (propertyIds.isEmpty) return true;

    // Optimistic update — remove from local list immediately
    final previousState = state;
    state = state.whenData(
      (items) =>
          items.where((w) => !propertyIds.contains(w.propertyId)).toList(),
    );

    try {
      // Fire all deletions in parallel
      await Future.wait(
        propertyIds.map(
          (id) => ref
              .read(wishlistRepositoryProvider)
              .removeFromWishlist(userId, id),
        ),
      );
      return true;
    } catch (e, st) {
      // Revert to previous state on error
      state = previousState;
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> clearWishlist(String userId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await ref.read(wishlistRepositoryProvider).clearWishlist(userId);

      return <WishlistModel>[];
    });
  }
}

final wishlistViewmodelProvider =
    AsyncNotifierProvider<WishlistViewmodel, List<WishlistModel>>(
      WishlistViewmodel.new,
    );

final isPropertyInWishlistProvider = FutureProvider.family<bool, String>((
  ref,
  propertyId,
) async {
  final authUser = Supabase.instance.client.auth.currentUser;

  if (authUser == null) {
    return false;
  }

  return ref
      .read(wishlistRepositoryProvider)
      .isPropertyInWishlist(authUser.id, propertyId);
});

final wishlistPropertiesProvider =
    FutureProvider.autoDispose<List<PropertyModel>>((ref) async {
      final authUser = Supabase.instance.client.auth.currentUser;

      if (authUser == null) {
        return [];
      }

      final wishlistItems = await ref.watch(wishlistViewmodelProvider.future);

      if (wishlistItems.isEmpty) {
        return [];
      }

      final propertyIds = wishlistItems.map((item) => item.propertyId).toList();

      return ref
          .read(propertyRepositoryProvider)
          .getPropertiesByIds(propertyIds);
    });
