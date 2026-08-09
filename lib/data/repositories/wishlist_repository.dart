import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/services/supabase_service.dart';
import 'package:zoneer_mobile/data/models/wishlist/wishlist_model.dart';

class WishlistRepository {
  final SupabaseService _supabase;

  WishlistRepository(this._supabase);

  Future<List<WishlistModel>> getWishlistByUserId(String userId) async {
    final response = await _supabase
        .from('wishlists')
        .select()
        .eq('user_id', userId);
    return (response as List).map((e) => WishlistModel.fromJson(e)).toList();
  }

  Future<void> removeFromWishlist(String userId, String propertyId) async {
    await _supabase
        .from('wishlists')
        .delete()
        .eq('user_id', userId)
        .eq('property_id', propertyId);
  }

  Future<void> addToWishlist(WishlistModel wishlist) async {
    await _supabase.from('wishlists').insert(wishlist.toJson());
  }

  Future<void> clearWishlist(String userId) async {
    await _supabase.from('wishlists').delete().eq('user_id', userId);
  }

  Future<bool> isPropertyInWishlist(String userId, String propertyId) async {
    final response = await _supabase
        .from('wishlists')
        .select('property_id')
        .eq('user_id', userId)
        .eq('property_id', propertyId)
        .maybeSingle();

    return response != null;
  }
}

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return WishlistRepository(supabase);
});
