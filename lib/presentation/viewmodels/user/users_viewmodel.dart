import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/data/models/user/user_model.dart';
import 'package:zoneer_mobile/data/repositories/user_repository.dart';

class UsersViewModel extends AsyncNotifier<List<UserModel>> {
  @override
  Future<List<UserModel>> build() {
    return ref.read(userRepositoryProvider).getUsers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(
      () => ref.read(userRepositoryProvider).getUsers(),
    );
  }
}

final usersViewModelProvider =
    AsyncNotifierProvider<UsersViewModel, List<UserModel>>(
  UsersViewModel.new,
);
