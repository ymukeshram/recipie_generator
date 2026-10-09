import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/core/services/saved_recipes_service.dart';
import 'package:rasoiai/shared/models/mock_recipes.dart';
import 'package:rasoiai/shared/widgets/recipe_card.dart';
import 'package:rasoiai/shared/widgets/hero_dish_showcase.dart';
import 'package:rasoiai/shared/widgets/theme_toggle_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCuisine = 'All';

  final List<String> _cuisines = const [
    'All',
    'North Indian',
    'South Indian',
    'Punjabi',
    'Gujarati',
    'Maharashtrian',
    'Bengali',
    'Breakfast',
    'Street Food',
    'Desserts',
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Dynamic Chef's Daily Pick that changes daily
    final heroIndex = (DateTime.now().year * 365 + DateTime.now().day) % mockRecipes.length;
    final heroRecipe = mockRecipes[heroIndex];

    // 2. Reduce Card Redundancy: Deduplicate Hero Dish from the lists below
    final nonHeroRecipes = mockRecipes.where((r) => r.id != heroRecipe.id).toList();

    // 3. Dynamic Interactive Filtering based on selected cuisine pill
    final filteredDishes = nonHeroRecipes.where((r) {
      if (_selectedCuisine == 'All') return true;
      final query = _selectedCuisine.toLowerCase();
      final inCuisine = r.cuisine.toLowerCase().contains(query);
      final inCategory = r.mealCategory.toLowerCase().contains(query);
      final inTags = r.dietaryTags.any((t) => t.toLowerCase().contains(query));
      return inCuisine || inCategory || inTags;
    }).toList();

    final carouselDishes = filteredDishes.isNotEmpty ? filteredDishes : nonHeroRecipes;
    final recommendedDishes = filteredDishes.isNotEmpty
        ? filteredDishes.reversed.toList()
        : nonHeroRecipes.reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Clean Mobile App Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RasoiAI',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Your Indian Cooking Assistant',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const ThemeToggleButton(),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => context.go('/profile'),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Center(
                              child: Icon(Icons.person_outline_rounded, size: 20, color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Dynamic Daily Hero Dish (No redundancy with feed below)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: HeroDishShowcase(
                  title: heroRecipe.dishName,
                  subtitle: heroRecipe.description,
                  tag: 'Chef’s Daily Pick • ${heroRecipe.cuisine}',
                  imageUrl: heroRecipe.imageUrl ??
                      'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?auto=format&fit=crop&w=800&q=80',
                  onTap: () {
                    context.push('/recipe/${heroRecipe.id}', extra: heroRecipe);
                  },
                ),
              ),
            ),

            // DUAL EXPLICIT ACTION BUTTONS: Recipe Generation & Photo Dish Capture
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Button 1: Dedicated Recipe Generation
                    InkWell(
                      onTap: () => context.go('/generate'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.auto_awesome, color: AppColors.textPrimary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Generate a Recipe',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Enter dish name, pantry items, or dietary preferences',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Button 2: Dedicated Photo Dish Capture
                    InkWell(
                      onTap: () => context.push('/generate/photo'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.camera_alt_outlined, color: AppColors.textPrimary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Identify from Photograph',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Take or upload a picture to get an authentic recipe',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Regional Cuisines Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Regional Cuisines',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    if (_selectedCuisine != 'All')
                      GestureDetector(
                        onTap: () => setState(() => _selectedCuisine = 'All'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Reset Filter', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              SizedBox(width: 3),
                              Icon(Icons.close_rounded, size: 12, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: _cuisines.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cuisine = _cuisines[index];
                    final isSelected = cuisine == _selectedCuisine;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCuisine = cuisine;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.textPrimary : AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? AppColors.textPrimary : AppColors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          cuisine,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Popular Indian Dishes with Dynamic Filter Feedback
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCuisine == 'All' ? 'Popular Indian Dishes' : '$_selectedCuisine Specialties',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/explore'),
                      child: const Text(
                        'See all',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal Recipe Carousel
            SliverToBoxAdapter(
              child: SizedBox(
                height: 232,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: carouselDishes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final recipe = carouselDishes[index];
                    return RecipeCard(
                      recipe: recipe,
                      width: 205,
                      onTap: () => context.push('/recipe/${recipe.id}', extra: recipe),
                    );
                  },
                ),
              ),
            ),

            // Curated Recommendations Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCuisine == 'All' ? 'Recommended for You' : 'More $_selectedCuisine Recipes',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/explore'),
                      child: const Text(
                        'See all',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Vertical Feed with Safe Bottom Inset
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final recipe = recommendedDishes[index % recommendedDishes.length];
                    final isSaved = savedRecipesService.isSaved(recipe.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: RecipeCard(
                        recipe: recipe.copyWith(isFavorite: isSaved),
                        showSavedIcon: true,
                        onFavoriteTap: () async {
                          await savedRecipesService.toggleSave(recipe);
                          setState(() {});
                        },
                        onTap: () => context.push('/recipe/${recipe.id}', extra: recipe),
                      ),
                    );
                  },
                  childCount: recommendedDishes.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
