import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/features/property/models/property_model.dart';
import 'package:zoneer_mobile/features/property/viewmodels/my_properties_provider.dart';
import 'package:zoneer_mobile/features/property/viewmodels/properties_viewmodel.dart';
import 'package:zoneer_mobile/shared/models/enums/verify_status.dart';

/// Combines the global verified-properties list with the current user's own
/// pending properties so that:
/// - Tenants see only admin-verified listings (no change).
/// - Landlords also see their own pending/rejected listings so a newly
///   uploaded property is immediately visible to its owner — marked with
///   [PropertyModel.verifyStatus] != verified for badge rendering.
final visiblePropertiesProvider =
    Provider<AsyncValue<List<PropertyModel>>>((ref) {
  final verified = ref.watch(propertiesViewModelProvider);
  final myProperties = ref.watch(myPropertiesProvider);

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return verified;

  return verified.whenData((verifiedList) {
    final myList = myProperties.asData?.value ?? [];
    final verifiedIds = verifiedList.map((p) => p.id).toSet();

    // Add user's own properties that are NOT yet in the verified list.
    // This includes pending and rejected — the owner can still see them.
    final ownPending = myList
        .where((p) =>
            p.verifyStatus != VerifyStatus.verified &&
            !verifiedIds.contains(p.id))
        .toList();

    return [...verifiedList, ...ownPending];
  });
});
