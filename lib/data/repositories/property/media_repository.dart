import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/services/supabase_service.dart';
import 'package:zoneer_mobile/data/models/property/media_model.dart';

class MediaRepository {
  final SupabaseService _supabase;

  MediaRepository(this._supabase);

  Future<List<MediaModel>> getMediaByPropertyId(String propertyId) async {
    final response = await _supabase.from('media').select().eq('property_id', propertyId);
    return (response as List).map((e) => MediaModel.fromJson(e)).toList();
  }
}

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return MediaRepository(supabase);
});