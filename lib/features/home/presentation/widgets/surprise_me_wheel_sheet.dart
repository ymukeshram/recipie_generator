import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/core/networking/api_client.dart';
import 'package:rasoiai/core/services/saved_recipes_service.dart';
import 'package:rasoiai/shared/models/recipe.dart';
import 'package:rasoiai/shared/models/mock_recipes.dart';

class WheelSegment {
  final String label;
  final String emoji;
  final Color color;
  final String categoryKey;
  final String cuisineHint;

  const WheelSegment({
    required this.label,
    required this.emoji,
    required this.color,
    required this.categoryKey,
    required this.cuisineHint,
  });
}

final List<WheelSegment> wheelSegments = const [
  WheelSegment(
    label: 'North Indian',
    emoji: '🥘',
    color: Color(0xFFD97736), // Terracotta
    categoryKey: 'Dinner',
    cuisineHint: 'North Indian',
  ),
  WheelSegment(
    label: 'South Indian',
    emoji: '🥣',
    color: Color(0xFF2D6A4F), // Cardamom Green
    categoryKey: 'Breakfast',
    cuisineHint: 'South Indian',
  ),
  WheelSegment(
    label: 'Indo-Chinese',
    emoji: '🥢',
    color: Color(0xFFDC2626), // Chilli Red
    categoryKey: 'Snacks',
    cuisineHint: 'Indo-Chinese',
  ),
  WheelSegment(
    label: 'Street Food',
    emoji: '🍢',
    color: Color(0xFFD97706), // Saffron Amber
    categoryKey: 'Snacks',
    cuisineHint: 'Indian Street Food',
  ),
  WheelSegment(
    label: 'Healthy Meals',
    emoji: '🥗',
    color: Color(0xFF059669), // Emerald Mint
    categoryKey: 'Dinner',
    cuisineHint: 'Healthy Sattvik',
  ),
  WheelSegment(
    label: 'High-Protein',
    emoji: '💪',
    color: Color(0xFFB45309), // Warm Bronze
    categoryKey: 'Lunch',
    cuisineHint: 'High Protein Indian',
  ),
  WheelSegment(
    label: 'Quick Meals',
    emoji: '⏱️',
    color: Color(0xFFEAB308), // Turmeric Yellow
    categoryKey: 'Breakfast',
    cuisineHint: 'Quick Homestyle',
  ),
  WheelSegment(
    label: 'Desserts',
    emoji: '🍨',
    color: Color(0xFFDB2777), // Rose Pink
    categoryKey: 'Dessert',
    cuisineHint: 'Indian Mithai Dessert',
  ),
  WheelSegment(
    label: 'Italian Fusion',
    emoji: '🍕',
    color: Color(0xFFEA580C), // Fiery Orange
    categoryKey: 'Dinner',
    cuisineHint: 'Desi Italian Fusion',
  ),
  WheelSegment(
    label: 'Random Surprise',
    emoji: '🎲',
    color: Color(0xFF6366F1), // Indigo Royal
    categoryKey: 'Surprise',
    cuisineHint: 'Chef Special Surprise',
  ),
];

class SurpriseMeWheelSheet extends StatefulWidget {
  const SurpriseMeWheelSheet({super.key});

  @override
  State<SurpriseMeWheelSheet> createState() => _SurpriseMeWheelSheetState();
}

class _SurpriseMeWheelSheetState extends State<SurpriseMeWheelSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _wheelController;
  late Animation<double> _wheelAnimation;

  double _currentAngle = 0.0;
  bool _isSpinning = false;
  bool _isGeneratingRecipe = false;
  WheelSegment? _selectedSegment;
  Recipe? _generatedRecipe;
  bool _isSaved = false;

  static const _storage = FlutterSecureStorage();
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  void _spinTheWheel() {
    if (_isSpinning || _isGeneratingRecipe) return;

    setState(() {
      _isSpinning = true;
      _isGeneratingRecipe = true;
      _generatedRecipe = null;
      _selectedSegment = null;
    });

    // 1. Pick a random target segment
    final targetIndex = _random.nextInt(wheelSegments.length);
    final targetSegment = wheelSegments[targetIndex];

    // 2. Compute exact target rotation angle so target segment lands at 12 o'clock (top pointer)
    final segmentAngle = (2 * math.pi) / wheelSegments.length;
    final centerAngle = targetIndex * segmentAngle + (segmentAngle / 2);

    // Pointer is at -pi/2 (12 o'clock).
    final rotations = 4 + _random.nextInt(2); // 4 to 5 smooth rotations
    final targetRotation = (rotations * 2 * math.pi) + (-math.pi / 2 - centerAngle);

    final startAngle = _currentAngle % (2 * math.pi);
    // Ensure rotation is strictly positive and forward
    final endAngle = startAngle + (rotations * 2 * math.pi) + (targetRotation - startAngle) % (2 * math.pi);

    _wheelAnimation = Tween<double>(begin: startAngle, end: endAngle).animate(
      CurvedAnimation(parent: _wheelController, curve: Curves.easeOutCubic),
    );

    // Concurrently prefetch recipe while the wheel is spinning for instant result reveal
    final recipeFuture = _fetchRecipeForSegment(targetSegment);

    _wheelController.reset();
    _wheelController.forward().then((_) async {
      _currentAngle = endAngle;
      if (mounted) {
        setState(() {
          _isSpinning = false;
          _selectedSegment = targetSegment;
        });
        await recipeFuture;
      }
    });
  }

  Future<void> _fetchRecipeForSegment(WheelSegment segment) async {
    Recipe? recipe;

    // Read user's dietary and culinary preferences from storage
    String userDietPref = 'Vegetarian';
    try {
      final savedDiet = await _storage.read(key: 'rasoiai_selected_diet');
      if (savedDiet != null && savedDiet.isNotEmpty) {
        userDietPref = savedDiet;
      }
    } catch (_) {}

    final bool isNonVeg = userDietPref == 'Non-Vegetarian';
    final bool isEggetarian = userDietPref == 'Eggetarian';

    // Get list of already saved dishes so we NEVER recommend them again
    final savedDishes = savedRecipesService.savedRecipesNotifier.value;
    final savedNames = savedDishes.map((r) => r.dishName.trim().toLowerCase()).toSet();
    final savedIds = savedDishes.map((r) => r.id).toSet();

    String targetCuisine = segment.cuisineHint;
    String targetCategory = segment.categoryKey;
    String promptText = 'Surprise me with an authentic, beloved ${segment.label} Indian recipe.';
    String dietPref = userDietPref;
    int maxTime = 35;

    switch (segment.label) {
      case 'High-Protein':
        targetCuisine = isNonVeg ? 'North Indian' : 'North Indian';
        targetCategory = 'Lunch';
        dietPref = isNonVeg ? 'Non-Vegetarian' : (isEggetarian ? 'Eggetarian' : 'High Protein');
        promptText = isNonVeg
            ? 'Authentic high-protein Indian recipe featuring chicken, mutton, fish, or eggs (at least 28g protein per serving).'
            : 'Authentic high-protein Indian recipe rich in protein (at least 20g protein per serving) such as paneer, soya, dal, or chana.';
        break;
      case 'Healthy Meals':
        targetCategory = 'Dinner';
        dietPref = isNonVeg ? 'Non-Vegetarian' : 'Low Calorie';
        maxTime = 30;
        promptText = isNonVeg
            ? 'Healthy, grilled or light Indian meal with lean chicken, fish, or egg whites under 350 calories.'
            : 'Healthy, light, and nutritious Indian meal under 320 calories with wholesome greens and fiber.';
        break;
      case 'Quick Meals':
        targetCategory = 'Breakfast';
        maxTime = 20;
        promptText = (isNonVeg || isEggetarian)
            ? 'Delicious quick Indian meal with eggs or shredded chicken that can be prepared in under 18 minutes (like Egg Bhurji or Anda Paratha).'
            : 'Delicious quick Indian meal that can be prepared in under 18 minutes.';
        break;
      case 'Desserts':
        targetCategory = 'Dessert';
        targetCuisine = 'Indian Dessert';
        dietPref = 'Vegetarian';
        promptText = 'Classic Indian sweet or dessert like Gulab Jamun, Kheer, or Gajar Halwa.';
        break;
      case 'Street Food':
        targetCategory = 'Snacks';
        targetCuisine = 'Street Food';
        promptText = isNonVeg
            ? 'Iconic Indian street food snack like Kolkata Chicken Roll, Chicken Momos, or Keema Pav.'
            : 'Iconic Indian street food snack like Pav Bhaji, Chaat, or Samosa.';
        break;
      case 'Italian Fusion':
        targetCuisine = 'Italian Fusion';
        promptText = isNonVeg
            ? 'Indian-Italian fusion dish like Butter Chicken Pizza, Chicken Tikka Pasta, or Kheema Lasagna.'
            : 'Indian-Italian fusion dish like Paneer Tikka Naan Pizza or Makhani Pasta.';
        break;
      case 'Indo-Chinese':
        targetCuisine = 'Indo-Chinese';
        promptText = isNonVeg
            ? 'Spicy and tangy Indo-Chinese recipe like Chilli Chicken, Chicken Manchurian, or Egg Fried Rice.'
            : 'Spicy and tangy Indo-Chinese recipe like Veg Manchurian or Chilli Paneer.';
        break;
      case 'South Indian':
        targetCuisine = 'South Indian';
        promptText = isNonVeg
            ? 'Traditional authentic South Indian delicacy like Chettinad Pepper Chicken, Meen Curry, or Kozhi Roast.'
            : 'Traditional authentic South Indian delicacy like Masala Dosa, Idli Sambar, or Uttapam.';
        break;
      case 'North Indian':
        targetCuisine = 'North Indian';
        promptText = isNonVeg
            ? 'Rich North Indian delicacy like Butter Chicken, Chicken Korma, Rogan Josh, or Tariwali Chicken.'
            : 'Rich North Indian delicacy like Paneer Butter Masala, Dal Makhani, or Chole.';
        break;
      case 'Random Surprise':
        promptText = isNonVeg
            ? 'Chef special signature Indian delicacy featuring succulent meat or poultry.'
            : 'Chef special signature Indian delicacy.';
        break;
    }

    // Add explicit exclusion instructions to AI prompt so it never returns saved dishes
    if (savedNames.isNotEmpty) {
      final excludeListStr = savedDishes.take(8).map((r) => r.dishName).join(', ');
      promptText += ' Strictly do NOT recommend any of these dishes already known/saved: $excludeListStr.';
    }

    // 1. Try real AI backend generation with generous 15-second timeout for accuracy
    try {
      recipe = await apiClient.generateRecipe(
        dishName: '',
        cuisine: targetCuisine,
        mealCategory: targetCategory,
        prompt: promptText,
        servings: 2,
        maxTimeMinutes: maxTime,
        dietaryPreference: dietPref,
      ).timeout(const Duration(seconds: 15));

      // If AI accidentally generated an already saved dish, discard and use fallback
      if (recipe != null && (savedNames.contains(recipe.dishName.trim().toLowerCase()) || savedIds.contains(recipe.id))) {
        recipe = null;
      }
    } catch (_) {}

    // 2. Strict, 100% accurate fallback matching by category, dietary preference, and deduplication
    if (recipe == null) {
      final List<Recipe> matching = mockRecipes.where((r) {
        // Must NOT be in user's saved/liked list
        if (savedIds.contains(r.id) || savedNames.contains(r.dishName.trim().toLowerCase())) {
          return false;
        }

        final label = segment.label.toLowerCase();
        final dish = r.dishName.toLowerCase();
        final cuisine = r.cuisine.toLowerCase();
        final tags = r.dietaryTags.map((t) => t.toLowerCase()).toList();

        // Check non-veg vs veg compatibility
        if (isNonVeg) {
          final isDishNonVeg = tags.contains('non-vegetarian') || dish.contains('chicken') || dish.contains('mutton') || dish.contains('egg');
          // For North/South Indian, Protein, Street Food, prioritize non-veg if available
          if ((label.contains('north') || label.contains('south') || label.contains('protein')) && !isDishNonVeg) {
            // Check if there are non-veg matching options before rejecting
            final hasNonVegOption = mockRecipes.any((other) =>
                other.dietaryTags.map((t) => t.toLowerCase()).contains('non-vegetarian') &&
                !savedIds.contains(other.id) &&
                !savedNames.contains(other.dishName.trim().toLowerCase()));
            if (hasNonVegOption) return false;
          }
        } else if (!isEggetarian) {
          // Pure Vegetarian / Vegan: strictly exclude non-veg and eggetarian
          if (tags.contains('non-vegetarian') || tags.contains('eggetarian') || dish.contains('chicken') || dish.contains('egg')) {
            return false;
          }
        }

        if (label.contains('protein')) {
          return tags.any((t) => t.contains('protein')) || ((r.nutrition?.proteinG ?? 0) >= 14.0);
        } else if (label.contains('healthy')) {
          return tags.any((t) => t.contains('healthy') || t.contains('fiber')) || ((r.nutrition?.calories ?? 999) <= 300);
        } else if (label.contains('dessert')) {
          return r.mealCategory.toLowerCase() == 'dessert' || tags.contains('dessert');
        } else if (label.contains('street')) {
          return cuisine.contains('street') || tags.any((t) => t.contains('street'));
        } else if (label.contains('italian')) {
          return cuisine.contains('italian') || tags.contains('fusion');
        } else if (label.contains('chinese')) {
          return cuisine.contains('chinese') || dish.contains('manchurian');
        } else if (label.contains('south')) {
          return cuisine.contains('south');
        } else if (label.contains('north')) {
          return cuisine.contains('north');
        } else if (label.contains('quick')) {
          return r.totalTimeMinutes <= 25 || tags.any((t) => t.contains('quick'));
        }
        return true;
      }).toList();

      if (matching.isNotEmpty) {
        recipe = matching[_random.nextInt(matching.length)];
      } else {
        // Fallback to any mock recipe not in saved recipes
        final unsavedMocks = mockRecipes.where((r) => !savedIds.contains(r.id) && !savedNames.contains(r.dishName.trim().toLowerCase())).toList();
        if (unsavedMocks.isNotEmpty) {
          recipe = unsavedMocks[_random.nextInt(unsavedMocks.length)];
        } else {
          recipe = mockRecipes[_random.nextInt(mockRecipes.length)];
        }
      }
    }

    if (mounted) {
      setState(() {
        _generatedRecipe = recipe;
        _isGeneratingRecipe = false;
        _isSaved = recipe != null ? savedRecipesService.isSaved(recipe.id) : false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF332014) : const Color(0xFFFFF3EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('🎡', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Surprise Me Wheel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text(context),
                          ),
                        ),
                        Text(
                          'Spin to discover what to cook next',
                          style: TextStyle(fontSize: 12, color: AppColors.subtext(context)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.subtext(context),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // Wheel Area & Result Showcase
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // Spinning Wheel Display
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated Wheel
                        AnimatedBuilder(
                          animation: _wheelController,
                          builder: (context, child) {
                            final angle = _isSpinning ? _wheelAnimation.value : _currentAngle;
                            return Transform.rotate(
                              angle: angle,
                              child: child,
                            );
                          },
                          child: CustomPaint(
                            size: const Size(270, 270),
                            painter: _WheelPainter(segments: wheelSegments),
                          ),
                        ),

                        // Center Hub
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFD97706), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🎲', style: TextStyle(fontSize: 20)),
                          ),
                        ),

                        // Fixed Top Pointer Arrow (Points down at winning wedge at 12 o'clock)
                        Positioned(
                          top: 0,
                          child: CustomPaint(
                            size: const Size(26, 26),
                            painter: _PointerPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Spin Action Button
                  if (!_isSpinning && !_isGeneratingRecipe && _generatedRecipe == null)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.text(context),
                          foregroundColor: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.rotate_right_rounded, size: 22),
                        label: const Text(
                          'Spin the Wheel 🎡',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _spinTheWheel,
                      ),
                    ),

                  // Spinning Status Indicator
                  if (_isSpinning)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2016) : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDBA74)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEA580C)),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Spinning the culinary wheel...',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC2410C)),
                          ),
                        ],
                      ),
                    ),

                  // Recipe Generation Loading with Chef Avatar
                  if (_isGeneratingRecipe)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF231D19), const Color(0xFF1B1A1E)]
                              : [const Color(0xFFFFF7ED), const Color(0xFFFEF3C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.4) : const Color(0xFFFDBA74),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD97706).withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Chef Avatar Badge
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEA580C), Color(0xFFD97706)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Text('👨‍🍳', style: TextStyle(fontSize: 30)),
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(_selectedSegment?.emoji ?? '✨', style: const TextStyle(fontSize: 14)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Master Chef at Work',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('🔥', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Curating authentic ${_selectedSegment?.label ?? "specialty"} recipe according to your culinary taste...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF78350F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Result Card
                  if (_generatedRecipe != null && !_isGeneratingRecipe) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tag & Category
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '🎉 Wheel Selected: ${_selectedSegment?.label ?? _generatedRecipe!.cuisine}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  _isSaved ? Icons.favorite : Icons.favorite_border,
                                  color: _isSaved ? Colors.red : AppColors.subtext(context),
                                  size: 22,
                                ),
                                onPressed: () async {
                                  final nowSaved = await savedRecipesService.toggleSave(_generatedRecipe!);
                                  setState(() => _isSaved = nowSaved);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(nowSaved ? 'Recipe saved to bookmarks!' : 'Recipe removed from bookmarks.'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Dish Name & Time
                          Text(
                            _generatedRecipe!.dishName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _generatedRecipe!.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: AppColors.subtext(context), height: 1.3),
                          ),
                          const SizedBox(height: 10),

                          // Metadata Chips
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 14, color: AppColors.subtext(context)),
                              const SizedBox(width: 4),
                              Text('${_generatedRecipe!.totalTimeMinutes} mins', style: TextStyle(fontSize: 12, color: AppColors.subtext(context))),
                              const SizedBox(width: 12),
                              Icon(Icons.bar_chart, size: 14, color: AppColors.subtext(context)),
                              const SizedBox(width: 4),
                              Text(_generatedRecipe!.difficulty, style: TextStyle(fontSize: 12, color: AppColors.subtext(context))),
                              const SizedBox(width: 12),
                              Text('Est. ₹${_generatedRecipe!.costEstimateInr.round()}/serv', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Action Buttons: View Full Recipe & Spin Again
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.restaurant_menu, size: 18),
                                  label: const Text('View Full Recipe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.push('/recipe/${_generatedRecipe!.id}', extra: _generatedRecipe);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Spin Again', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: _spinTheWheel,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<WheelSegment> segments;

  _WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / segments.length;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle;
      paint.color = segments[i].color;

      // Draw segment wedge
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw white divider line
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      // Draw Label and Emoji
      canvas.save();
      canvas.translate(center.dx, center.dy);
      final textAngle = startAngle + (segmentAngle / 2);
      canvas.rotate(textAngle);

      final textSpan = TextSpan(
        text: '${segments[i].emoji} ${segments[i].label}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: radius * 0.75);

      textPainter.paint(canvas, Offset(radius * 0.28, -textPainter.height / 2));
      canvas.restore();
    }

    // Outer Rim
    final rimPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawCircle(center, radius - 2, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDC2626) // Vivid Ruby Pointer
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path()
      ..moveTo(size.width / 2, size.height) // Tip pointing downwards into the wheel
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);

    // Golden border on pointer
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
