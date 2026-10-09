import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rasoiai/shared/models/recipe.dart';
import 'package:rasoiai/shared/models/mock_recipes.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'rasoiai_recipe_history_v1';

  final ValueNotifier<List<Recipe>> historyNotifier = ValueNotifier<List<Recipe>>([]);
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final list = decoded.map((item) => Recipe.fromJson(item as Map<String, dynamic>)).toList();
        historyNotifier.value = list;
      } else {
        // Initial seed with curated dishes so user has sample generation history
        final initial = mockRecipes.take(3).toList();
        historyNotifier.value = initial;
        await _persist(initial);
      }
    } catch (e) {
      debugPrint('Error initializing HistoryService: $e');
      historyNotifier.value = mockRecipes.take(3).toList();
    }
    _initialized = true;
  }

  Future<void> addRecipe(Recipe recipe) async {
    final list = List<Recipe>.from(historyNotifier.value);
    // Remove if already exists to push to front
    list.removeWhere((r) => r.id == recipe.id || r.dishName.toLowerCase() == recipe.dishName.toLowerCase());
    list.insert(0, recipe);

    // Keep max 50 recent recipes
    if (list.length > 50) {
      list.removeRange(50, list.length);
    }

    historyNotifier.value = list;
    await _persist(list);
  }

  Future<void> removeRecipe(String recipeId) async {
    final list = List<Recipe>.from(historyNotifier.value);
    list.removeWhere((r) => r.id == recipeId);
    historyNotifier.value = list;
    await _persist(list);
  }

  Future<void> clearHistory() async {
    historyNotifier.value = [];
    try {
      await _storage.delete(key: _storageKey);
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  Future<void> _persist(List<Recipe> list) async {
    try {
      final encoded = jsonEncode(list.map((r) => r.toJson()).toList());
      await _storage.write(key: _storageKey, value: encoded);
    } catch (e) {
      debugPrint('Error persisting recipe history: $e');
    }
  }
}

final historyService = HistoryService();
