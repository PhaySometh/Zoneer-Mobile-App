import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedPropertiesNotifier extends Notifier<Set<String>> {
  static const _key = 'saved_property_ids';

  @override
  Set<String> build() {
    _loadSaved();
    return {};
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      final list = (jsonDecode(json) as List).cast<String>();
      state = Set<String>.from(list);
    }
  }

  Future<void> toggle(String id) async {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
    await _persist();
  }

  bool isSaved(String id) => state.contains(id);

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toList()));
  }
}

final savedPropertiesProvider =
    NotifierProvider<SavedPropertiesNotifier, Set<String>>(
  SavedPropertiesNotifier.new,
);
