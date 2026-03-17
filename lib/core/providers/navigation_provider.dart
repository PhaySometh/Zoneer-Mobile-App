import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage the selected navigation tab index
///
/// This allows any widget in the app to read or change the current tab
/// Usage:
/// - Read: `ref.watch(navigationProvider)`
/// - Update: `ref.read(navigationProvider.notifier).changeTab(newIndex)`
final navigationProvider = NotifierProvider<NavigationNotifier, int>(
  NavigationNotifier.new,
);

/// Navigation notifier to manage tab state
class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0; // Initial state is home tab (index 0)

  void changeTab(int index) {
    state = index;
  }
}

/// Navigation tab indices for type safety
class NavigationTab {
  static const int home = 0;
  static const int wishlist = 1;
  static const int map = 2;
  static const int profile = 3;
}

