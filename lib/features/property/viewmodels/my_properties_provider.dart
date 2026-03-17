import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/features/property/models/property_model.dart';
import 'package:zoneer_mobile/features/property/repositories/property_repository.dart';

/// Isolated provider for the current user's own property listings.
///
/// This is intentionally separate from [propertiesViewModelProvider] so that
/// navigating to "My Properties" never clobbers the global verified-properties
/// list that Home and Map pages depend on.
class MyPropertiesNotifier extends AsyncNotifier<List<PropertyModel>> {
  @override
  Future<List<PropertyModel>> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    return ref
        .read(propertyRepositoryProvider)
        .getPropertiesByLandlordId(userId);
  }

  Future<void> refresh() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final fresh = await ref
          .read(propertyRepositoryProvider)
          .getPropertiesByLandlordId(userId);
      state = AsyncValue.data(fresh);
    } catch (_) {
      // Keep existing state on failure
    }
  }

  void removeFromState(String id) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncValue.data(current.where((p) => p.id != id).toList());
  }
}

final myPropertiesProvider =
    AsyncNotifierProvider<MyPropertiesNotifier, List<PropertyModel>>(
  MyPropertiesNotifier.new,
);
