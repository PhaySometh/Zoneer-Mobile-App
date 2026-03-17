import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the currently selected category on the Home screen.
/// null = show all categories (no filter applied).
final homeCategoryProvider = NotifierProvider<HomeCategoryNotifier, String?>(
  HomeCategoryNotifier.new,
);

class HomeCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? category) => state = category;
}
