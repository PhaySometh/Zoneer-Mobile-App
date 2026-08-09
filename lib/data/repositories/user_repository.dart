import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/services/supabase_service.dart';
import 'package:zoneer_mobile/data/models/user/user_model.dart';

class UserRepository {
  final SupabaseService _supabase;

  UserRepository(this._supabase);

  Future<List<UserModel>> getUsers() async {
    final response = await _supabase.from('users').select();
    return (response as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<UserModel> getUserById(String id) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', id)
        .single();
    return UserModel.fromJson(response);
  }

  Future<void> createUser(UserModel user) async {
    await _supabase.from('users').insert(user.toJson()).select();
  }

  Future<void> deleteUser(String id) async {
    await _supabase.from('users').delete().eq('id', id);
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return UserRepository(supabase);
});
