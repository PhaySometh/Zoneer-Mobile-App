import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/data/models/user/user_model.dart';
import 'package:zoneer_mobile/data/repositories/user_repository.dart';
import 'package:zoneer_mobile/shared/models/enums/verify_status.dart';

final authUser = Supabase.instance.client.auth.currentUser;

final userByIdProvider =
    FutureProvider.family<UserModel, String>((ref, id) {
  return ref.read(userRepositoryProvider).getUserById(id);
});

/// Like [userByIdProvider] but auto-creates a profile row for new OAuth users
/// who exist in auth.users but not in the public users table (PGRST116).
final userProfileOrCreateProvider =
    FutureProvider.family<UserModel, String>((ref, id) async {
  final repo = ref.read(userRepositoryProvider);
  try {
    return await repo.getUserById(id);
  } on PostgrestException catch (e) {
    if (e.code == 'PGRST116') {
      final authUser = Supabase.instance.client.auth.currentUser!;
      final meta = authUser.userMetadata ?? {};
      final newUser = UserModel(
        id: authUser.id,
        fullname: meta['full_name'] as String? ?? meta['name'] as String? ?? '',
        email: authUser.email ?? '',
        role: 'tenant',
        verifyStatus: VerifyStatus.defaultStatus,
        profileUrl: meta['avatar_url'] as String?,
      );
      await repo.createUser(newUser);
      return newUser;
    }
    rethrow;
  }
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});
