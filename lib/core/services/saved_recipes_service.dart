import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rasoiai/shared/models/recipe.dart';
import 'package:rasoiai/shared/models/mock_recipes.dart';

class SavedRecipesService {
  static final SavedRecipesService _instance = SavedRecipesService._internal();
  factory SavedRecipesService() => _instance;
  SavedRecipesService._internal();

  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'rasoiai_saved_recipes_v1';

  final ValueNotifier<List<Recipe>> savedRecipesNotifier = ValueNotifier<List<Recipe>>([]);
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final list = decoded.map((item) => Recipe.fromJson(item as Map<String, dynamic>)).toList();
        savedRecipesNotifier.value = list;
      } else {
        // Seed with initial curated recipes so user sees them on initial run
        final initial = mockRecipes.map((r) => r.copyWith(isSaved: true)).toList();
        savedRecipesNotifier.value = initial;
        await _persist(initial);
      }
    } catch (e) {
      debugPrint('Error initializing SavedRecipesService: $e');
      savedRecipesNotifier.value = mockRecipes.map((r) => r.copyWith(isSaved: true)).toList();
    }
    _initialized = true;
  }

  bool isSaved(String recipeId) {
    return savedRecipesNotifier.value.any((r) => r.id == recipeId);
  }

  bool isFavorite(String recipeId) {
    final matches = savedRecipesNotifier.value.where((r) => r.id == recipeId);
    return matches.isNotEmpty && matches.first.isFavorite;
  }

  Future<bool> toggleSave(Recipe recipe) async {
    final list = List<Recipe>.from(savedRecipesNotifier.value);
    final index = list.indexWhere((r) => r.id == recipe.id || r.dishName.toLowerCase() == recipe.dishName.toLowerCase());

    bool nowSaved = false;
    if (index >= 0) {
      list.removeAt(index);
      nowSaved = false;
    } else {
      list.insert(0, recipe.copyWith(isSaved: true));
      nowSaved = true;
    }

    savedRecipesNotifier.value = list;
    await _persist(list);
    return nowSaved;
  }

  Future<void> toggleFavorite(String recipeId) async {
    final list = List<Recipe>.from(savedRecipesNotifier.value);
    final index = list.indexWhere((r) => r.id == recipeId);
    if (index >= 0) {
      final updated = list[index].copyWith(isFavorite: !list[index].isFavorite);
      list[index] = updated;
      savedRecipesNotifier.value = list;
      await _persist(list);
    }
  }

  Future<void> _persist(List<Recipe> list) async {
    try {
      final encoded = jsonEncode(list.map((r) => r.toJson()).toList());
      await _storage.write(key: _storageKey, value: encoded);
    } catch (e) {
      debugPrint('Error persisting saved recipes: $e');
    }
  }
}

final savedRecipesService = SavedRecipesService();
