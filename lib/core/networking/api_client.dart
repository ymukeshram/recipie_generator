import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rasoiai/shared/models/recipe.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'rasoiai_backend_url';

  late final Dio _dio;
  
  static String customServerUrl = 'https://recipie-generator-qwj4.onrender.com/api/v1';

  static String get baseUrl => customServerUrl;

  static String formatServerUrl(String url) {
    String formatted = url.trim();
    if (formatted.isEmpty) return customServerUrl;

    final isCloudDomain = formatted.contains('.onrender.com') ||
        formatted.contains('.railway.app') ||
        formatted.contains('.koyeb.app') ||
        RegExp(r'\.[a-zA-Z]{2,}(/|$)').hasMatch(formatted);

    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      if (isCloudDomain) {
        formatted = 'https://$formatted';
      } else {
        formatted = 'http://$formatted';
      }
    }

    if (!formatted.startsWith('https://') && !isCloudDomain && !RegExp(r':\d+').hasMatch(formatted)) {
      formatted = '$formatted:8000';
    }

    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }

    if (!formatted.endsWith('/api/v1')) {
      formatted = '$formatted/api/v1';
    }
    return formatted;
  }

  static Future<void> loadSavedUrl() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved != null && saved.trim().isNotEmpty) {
        customServerUrl = formatServerUrl(saved);
        _instance._dio.options.baseUrl = customServerUrl;
      }
    } catch (_) {}
  }

  Future<void> updateServerUrl(String url) async {
    customServerUrl = formatServerUrl(url);
    _dio.options.baseUrl = customServerUrl;
    try {
      await _storage.write(key: _storageKey, value: customServerUrl);
    } catch (_) {}
  }

  Future<bool> testConnection([String? candidateUrl]) async {
    try {
      final target = candidateUrl != null && candidateUrl.trim().isNotEmpty
          ? formatServerUrl(candidateUrl)
          : baseUrl;
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final res = await dio.get('$target/health');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  Future<Recipe?> generateRecipe({
    required String dishName,
    List<String> ingredients = const [],
    List<String> excludedIngredients = const [],
    String? prompt,
    String cuisine = 'North Indian',
    String mealCategory = 'Dinner',
    int servings = 2,
    int maxTimeMinutes = 30,
    int budgetInr = 200,
    String spiceLevel = 'Medium',
    String dietaryPreference = 'Vegetarian',
  }) async {
    try {
      final response = await _dio.post(
        '/recipes/generate',
        data: {
          'dish_name': dishName.isEmpty ? null : dishName,
          'available_ingredients': ingredients,
          'excluded_ingredients': excludedIngredients,
          'prompt': prompt,
          'cuisine': cuisine,
          'meal_category': mealCategory,
          'servings': servings,
          'max_time_minutes': maxTimeMinutes,
          'budget_inr': budgetInr,
          'spice_level': spiceLevel,
          'dietary_preference': dietaryPreference,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return Recipe.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {
      // In case backend is offline, callers handle graceful fallback
    }
    return null;
  }

  Future<Map<String, dynamic>?> analyzeDishImage(List<int> imageBytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: filename,
        ),
      });

      final response = await _dio.post(
        '/recipes/analyze-image',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Recipe?> customizeRecipe({
    required Recipe recipe,
    required String instructions,
    String? spiceLevel,
    String? dietaryPreference,
    int? maxTimeMinutes,
  }) async {
    try {
      final response = await _dio.post(
        '/recipes/customize',
        data: {
          'recipe': recipe.toJson(),
          'instructions': instructions,
          'spice_level': spiceLevel,
          'dietary_preference': dietaryPreference,
          'max_time_minutes': maxTimeMinutes,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return Recipe.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<List<Recipe>> getCuratedRecipes({String? cuisine}) async {
    try {
      final response = await _dio.get(
        '/recipes/curated',
        queryParameters: cuisine != null ? {'cuisine': cuisine} : null,
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}

final apiClient = ApiClient();
