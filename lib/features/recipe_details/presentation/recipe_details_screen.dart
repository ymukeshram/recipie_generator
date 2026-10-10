import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/core/services/saved_recipes_service.dart';
import 'package:rasoiai/shared/models/recipe.dart';
import 'package:rasoiai/shared/models/mock_recipes.dart';
import 'package:rasoiai/shared/widgets/recipe_card.dart';
import 'package:rasoiai/core/services/gamification_service.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final String recipeId;
  final Recipe? recipeExtra;

  const RecipeDetailsScreen({
    super.key,
    required this.recipeId,
    this.recipeExtra,
  });

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  late Recipe _recipe;
  late int _servings;
  bool _isSaved = false;
  bool _isFavorite = false;
  final Set<int> _checkedIngredients = {};

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipeExtra ?? mockRecipes.first;
    _servings = _recipe.servings;
    _isSaved = savedRecipesService.isSaved(_recipe.id);
    _isFavorite = savedRecipesService.isFavorite(_recipe.id);
  }

  double _getScaledQuantity(double originalQty) {
    if (_recipe.servings == 0) return originalQty;
    final ratio = _servings / _recipe.servings;
    final scaled = originalQty * ratio;
    // Sensible rounding for kitchen usage
    if (scaled < 1.0) {
      return double.parse(scaled.toStringAsFixed(2));
    }
    return double.parse(scaled.toStringAsFixed(1));
  }

  void _copyRecipeToClipboard() {
    final buffer = StringBuffer();
    buffer.writeln('${_recipe.dishName} (${_recipe.cuisine})');
    buffer.writeln('Servings: $_servings | Time: ${_recipe.totalTimeMinutes} mins\n');
    buffer.writeln('--- Ingredients ---');
    for (var ing in _recipe.ingredients) {
      buffer.writeln('• ${_getScaledQuantity(ing.quantity)} ${ing.unit} ${ing.name}');
    }
    buffer.writeln('\n--- Instructions ---');
    for (var step in _recipe.instructions) {
      buffer.writeln('${step.stepNumber}. ${step.instruction}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recipe copied to clipboard!'),
        backgroundColor: AppColors.terracotta,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _recipe.dishName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _recipe.imageUrl != null && _recipe.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _recipe.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _buildHeaderPlaceholder(),
                        )
                      : _buildHeaderPlaceholder(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () async {
                  await savedRecipesService.toggleFavorite(_recipe.id);
                  setState(() => _isFavorite = !_isFavorite);
                },
              ),
              IconButton(
                icon: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
                onPressed: () async {
                  final nowSaved = await savedRecipesService.toggleSave(_recipe.copyWith(servings: _servings));
                  setState(() => _isSaved = nowSaved);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(nowSaved ? 'Recipe saved to your cookbook!' : 'Recipe removed from saved'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white),
                onPressed: _copyRecipeToClipboard,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      VegNonVegIndicator.fromRecipe(_recipe, size: 16),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _recipe.cuisine,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _recipe.mealCategory,
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Est. ₹${(_recipe.costEstimateInr / (_recipe.servings > 0 ? _recipe.servings : 2)).round()}/serv',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text(
                    _recipe.description,
                    style: const TextStyle(fontSize: 14, color: AppColors.darkCharcoal, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Overview Info Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn(Icons.timer_outlined, 'Prep', '${_recipe.prepTimeMinutes}m'),
                        _buildInfoColumn(Icons.soup_kitchen_outlined, 'Cook', '${_recipe.cookTimeMinutes}m'),
                        _buildInfoColumn(Icons.schedule, 'Total', '${_recipe.totalTimeMinutes}m'),
                        _buildInfoColumn(Icons.bolt, 'Level', _recipe.difficulty),
                        _buildInfoColumn(Icons.local_fire_department, 'Spice', _recipe.spiceLevel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ingredients Section with Interactive Servings Scaler
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ingredients', style: Theme.of(context).textTheme.titleLarge),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.dividerGray),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              visualDensity: VisualDensity.compact,
                              onPressed: _servings > 1 ? () => setState(() => _servings--) : null,
                            ),
                            Text(
                              '$_servings Servings',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              visualDensity: VisualDensity.compact,
                              onPressed: _servings < 16 ? () => setState(() => _servings++) : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap items as you prepare them in your kitchen:',
                    style: TextStyle(fontSize: 12, color: AppColors.neutralGray),
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recipe.ingredients.length,
                    itemBuilder: (context, index) {
                      final ing = _recipe.ingredients[index];
                      final isChecked = _checkedIngredients.contains(index);
                      final scaledQty = _getScaledQuantity(ing.quantity);

                      return CheckboxListTile(
                        value: isChecked,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.terracotta,
                        title: Text(
                          ing.name,
                          style: TextStyle(
                            decoration: isChecked ? TextDecoration.lineThrough : null,
                            color: isChecked ? AppColors.neutralGray : AppColors.darkCharcoal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warmIvory,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.dividerGray),
                          ),
                          child: Text(
                            '$scaledQty ${ing.unit}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _checkedIngredients.add(index);
                            } else {
                              _checkedIngredients.remove(index);
                            }
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Cooking Instructions (Readable step by step, no timers/TTS)
                  Text('Cooking Instructions', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recipe.instructions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final step = _recipe.instructions[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.dividerGray.withOpacity(0.6)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.terracotta,
                              child: Text(
                                '${step.stepNumber}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step.instruction,
                                style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.darkCharcoal),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Nutrition Info
                  if (_recipe.nutrition != null) ...[
                    Text('Nutrition Estimates (Per Serving)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutrient('Calories', '${_recipe.nutrition!.calories} kcal'),
                          _buildNutrient('Protein', '${_recipe.nutrition!.proteinG}g'),
                          _buildNutrient('Carbs', '${_recipe.nutrition!.carbsG}g'),
                          _buildNutrient('Fat', '${_recipe.nutrition!.fatG}g'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32), // Forest Culinary Green
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    label: const Text('I Cooked This Recipe! 🍳', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await gamificationService.markRecipeCompleted(_recipe);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 Completed "${_recipe.dishName}"! +50 Chef Points & Streak Updated.'),
                            backgroundColor: const Color(0xFF2E7D32),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronGold),
                    icon: const Icon(Icons.tune),
                    label: const Text('Customize this Recipe with AI'),
                    onPressed: () {
                      context.push('/recipe/${_recipe.id}/customize', extra: _recipe);
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.terracotta),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.neutralGray)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNutrient(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.terracottaDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.neutralGray)),
      ],
    );
  }

  Widget _buildHeaderPlaceholder() {
    String emoji = '🍲';
    Color bgGradientStart = const Color(0xFFFBF4EB);
    Color bgGradientEnd = const Color(0xFFF1E4D3);

    final cuisineLower = _recipe.cuisine.toLowerCase();
    final dishLower = _recipe.dishName.toLowerCase();

    if (dishLower.contains('fries') || dishLower.contains('potato') || dishLower.contains('finger chips') || dishLower.contains('snack')) {
      emoji = '🍟';
      bgGradientStart = const Color(0xFFFDF6EE);
      bgGradientEnd = const Color(0xFFF8E7D4);
    } else if (dishLower.contains('burger') || dishLower.contains('sandwich')) {
      emoji = '🍔';
      bgGradientStart = const Color(0xFFFDF6EE);
      bgGradientEnd = const Color(0xFFF8E7D4);
    } else if (dishLower.contains('pizza')) {
      emoji = '🍕';
      bgGradientStart = const Color(0xFFFCF1E6);
      bgGradientEnd = const Color(0xFFF6DFC8);
    } else if (dishLower.contains('pasta') || dishLower.contains('noodle') || dishLower.contains('maggi')) {
      emoji = '🍝';
      bgGradientStart = const Color(0xFFFCF6E8);
      bgGradientEnd = const Color(0xFFF7EAC9);
    } else if (cuisineLower.contains('south') || dishLower.contains('rasam') || dishLower.contains('sambar') || dishLower.contains('idli') || dishLower.contains('vada')) {
      emoji = '🥣';
      bgGradientStart = const Color(0xFFEBF5EE);
      bgGradientEnd = const Color(0xFFD7EADC);
    } else if (dishLower.contains('paneer') || cuisineLower.contains('north') || dishLower.contains('masala')) {
      emoji = '🥘';
      bgGradientStart = const Color(0xFFFCF1E6);
      bgGradientEnd = const Color(0xFFF6DFC8);
    } else if (dishLower.contains('biryani') || dishLower.contains('pulao') || dishLower.contains('rice')) {
      emoji = '🍚';
      bgGradientStart = const Color(0xFFFBF7EA);
      bgGradientEnd = const Color(0xFFF4E8CA);
    } else if (dishLower.contains('dosa') || dishLower.contains('roti') || dishLower.contains('paratha')) {
      emoji = '🥞';
      bgGradientStart = const Color(0xFFFAF2E8);
      bgGradientEnd = const Color(0xFFEFE1D0);
    } else if (dishLower.contains('dal') || dishLower.contains('chole')) {
      emoji = '🫕';
      bgGradientStart = const Color(0xFFFCF6E8);
      bgGradientEnd = const Color(0xFFF7EAC9);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgGradientStart, bgGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.25,
              child: const Text('🌿  🌶️  🧄  🧅  🍋', style: TextStyle(fontSize: 22, letterSpacing: 8)),
            ),
            const SizedBox(height: 8),
            Text(emoji, style: const TextStyle(fontSize: 64)),
          ],
        ),
      ),
    );
  }
}
