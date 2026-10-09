class RecipeIngredient {
  final String name;
  final double quantity;
  final String unit;
  final String? notes;

  const RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    this.notes,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'notes': notes,
  };
}

class RecipeStep {
  final int stepNumber;
  final String instruction;

  const RecipeStep({
    required this.stepNumber,
    required this.instruction,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      stepNumber: json['step_number'] as int? ?? 1,
      instruction: json['instruction'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'step_number': stepNumber,
    'instruction': instruction,
  };
}

class NutritionInfo {
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  const NutritionInfo({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: json['calories'] as int? ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0.0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fat_g': fatG,
    'fiber_g': fiberG,
  };
}

class Recipe {
  final String id;
  final String dishName;
  final String description;
  final String cuisine;
  final String mealCategory;
  final String? imageUrl;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int totalTimeMinutes;
  final int servings;
  final String difficulty;
  final String spiceLevel;
  final List<RecipeIngredient> ingredients;
  final List<String> equipment;
  final List<RecipeStep> instructions;
  final double costEstimateInr;
  final NutritionInfo? nutrition;
  final List<String> dietaryTags;
  final List<String> allergyWarnings;
  final bool isCurated;
  final bool isSaved;
  final bool isFavorite;

  const Recipe({
    required this.id,
    required this.dishName,
    required this.description,
    required this.cuisine,
    required this.mealCategory,
    this.imageUrl,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.totalTimeMinutes,
    required this.servings,
    required this.difficulty,
    required this.spiceLevel,
    required this.ingredients,
    required this.equipment,
    required this.instructions,
    required this.costEstimateInr,
    this.nutrition,
    required this.dietaryTags,
    required this.allergyWarnings,
    this.isCurated = false,
    this.isSaved = false,
    this.isFavorite = false,
  });

  Recipe copyWith({
    String? id,
    String? dishName,
    String? description,
    String? cuisine,
    String? mealCategory,
    String? imageUrl,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? totalTimeMinutes,
    int? servings,
    String? difficulty,
    String? spiceLevel,
    List<RecipeIngredient>? ingredients,
    List<String>? equipment,
    List<RecipeStep>? instructions,
    double? costEstimateInr,
    NutritionInfo? nutrition,
    List<String>? dietaryTags,
    List<String>? allergyWarnings,
    bool? isCurated,
    bool? isSaved,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      dishName: dishName ?? this.dishName,
      description: description ?? this.description,
      cuisine: cuisine ?? this.cuisine,
      mealCategory: mealCategory ?? this.mealCategory,
      imageUrl: imageUrl ?? this.imageUrl,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      totalTimeMinutes: totalTimeMinutes ?? this.totalTimeMinutes,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      ingredients: ingredients ?? this.ingredients,
      equipment: equipment ?? this.equipment,
      instructions: instructions ?? this.instructions,
      costEstimateInr: costEstimateInr ?? this.costEstimateInr,
      nutrition: nutrition ?? this.nutrition,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      allergyWarnings: allergyWarnings ?? this.allergyWarnings,
      isCurated: isCurated ?? this.isCurated,
      isSaved: isSaved ?? this.isSaved,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String? ?? '',
      dishName: json['dish_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? '',
      mealCategory: json['meal_category'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      prepTimeMinutes: json['prep_time_minutes'] as int? ?? 15,
      cookTimeMinutes: json['cook_time_minutes'] as int? ?? 25,
      totalTimeMinutes: json['total_time_minutes'] as int? ?? 40,
      servings: json['servings'] as int? ?? 2,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      spiceLevel: json['spice_level'] as String? ?? 'Medium',
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      equipment: (json['equipment'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      costEstimateInr: (json['cost_estimate_inr'] as num?)?.toDouble() ?? 150.0,
      nutrition: json['nutrition'] != null
          ? NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>)
          : null,
      dietaryTags: (json['dietary_tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      allergyWarnings: (json['allergy_warnings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isCurated: json['is_curated'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dish_name': dishName,
    'description': description,
    'cuisine': cuisine,
    'meal_category': mealCategory,
    'image_url': imageUrl,
    'prep_time_minutes': prepTimeMinutes,
    'cook_time_minutes': cookTimeMinutes,
    'total_time_minutes': totalTimeMinutes,
    'servings': servings,
    'difficulty': difficulty,
    'spice_level': spiceLevel,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'equipment': equipment,
    'instructions': instructions.map((e) => e.toJson()).toList(),
    'cost_estimate_inr': costEstimateInr,
    'nutrition': nutrition?.toJson(),
    'dietary_tags': dietaryTags,
    'allergy_warnings': allergyWarnings,
    'is_curated': isCurated,
    'is_saved': isSaved,
    'is_favorite': isFavorite,
  };
}
