import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/core/services/saved_recipes_service.dart';
import 'package:rasoiai/shared/models/recipe.dart';
import 'package:rasoiai/shared/widgets/recipe_card.dart';
import 'package:rasoiai/shared/widgets/theme_toggle_button.dart';

class SavedRecipesScreen extends StatefulWidget {
  const SavedRecipesScreen({super.key});

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  bool _showFavoritesOnly = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          'Saved Recipes',
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _showFavoritesOnly ? AppColors.errorRed : AppColors.text(context),
            ),
            tooltip: _showFavoritesOnly ? 'Show All Saved' : 'Filter Favorites Only',
            onPressed: () {
              setState(() => _showFavoritesOnly = !_showFavoritesOnly);
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppColors.text(context), fontSize: 14),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search your saved recipes...',
                    hintStyle: TextStyle(color: AppColors.subtext(context), fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: AppColors.subtext(context), size: 20),
                    filled: true,
                    fillColor: AppColors.cardBg(context),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18, color: AppColors.subtext(context)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cardBorder(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cardBorder(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<List<Recipe>>(
                  valueListenable: savedRecipesService.savedRecipesNotifier,
                  builder: (context, allSaved, _) {
                    final query = _searchController.text.trim().toLowerCase();
                    final filtered = allSaved.where((r) {
                      if (_showFavoritesOnly && !r.isFavorite) return false;
                      if (query.isNotEmpty) {
                        final inName = r.dishName.toLowerCase().contains(query);
                        final inCuisine = r.cuisine.toLowerCase().contains(query);
                        return inName || inCuisine;
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('📖', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                _showFavoritesOnly
                                    ? 'No favorite recipes marked yet'
                                    : (allSaved.isEmpty ? 'No saved recipes yet' : 'No matching recipes found'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: AppColors.text(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _showFavoritesOnly
                                    ? 'Tap the heart icon on any recipe to add it to your favorites.'
                                    : 'Save recipes from Home, Explore, or Generate with AI to access them offline anytime.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.subtext(context), fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.go('/explore'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Explore Dishes to Save'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final recipe = filtered[index];
                        return RecipeCard(
                          recipe: recipe,
                          showSavedIcon: true,
                          onFavoriteTap: () => savedRecipesService.toggleFavorite(recipe.id),
                          onTap: () => context.push('/recipe/${recipe.id}', extra: recipe),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
