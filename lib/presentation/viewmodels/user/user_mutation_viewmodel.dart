import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/data/models/user/user_model.dart';
import 'package:zoneer_mobile/data/repositories/user_repository.dart';
import 'users_viewmodel.dart';

class UserMutationViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create(UserModel user) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await ref.read(userRepositoryProvider).createUser(user);
      ref.invalidate(usersViewModelProvider);
    });
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await ref.read(userRepositoryProvider).deleteUser(id);
      ref.invalidate(usersViewModelProvider);
    });
  }
}

final userMutationViewModelProvider =
    AsyncNotifierProvider<UserMutationViewModel, void>(
      UserMutationViewModel.new,
    );
