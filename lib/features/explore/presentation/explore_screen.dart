import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/shared/models/recipe.dart';
import 'package:rasoiai/shared/models/mock_recipes.dart';
import 'package:rasoiai/shared/widgets/recipe_card.dart';
import 'package:rasoiai/shared/widgets/theme_toggle_button.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCuisine = 'All';

  final List<String> _cuisines = const [
    'All',
    'North Indian',
    'South Indian',
    'Punjabi',
    'Gujarati',
    'Maharashtrian',
    'Bengali',
  ];

  List<Recipe> get _filteredRecipes {
    return mockRecipes.where((r) {
      final matchesSearch = _searchController.text.isEmpty ||
          r.dishName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          r.description.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesCuisine = _selectedCuisine == 'All' || r.cuisine == _selectedCuisine;
      return matchesSearch && matchesCuisine;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredRecipes;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          'Explore Indian Recipes',
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppColors.text(context), fontSize: 14),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search dishes (e.g. Paneer, Biryani, Dosa)',
                    hintStyle: TextStyle(color: AppColors.subtext(context), fontSize: 14),
                    filled: true,
                    fillColor: AppColors.cardBg(context),
                    prefixIcon: Icon(Icons.search, color: AppColors.subtext(context), size: 20),
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

              // Horizontal Cuisine Filter Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: _cuisines.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final c = _cuisines[index];
                    final isSelected = _selectedCuisine == c;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCuisine = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : AppColors.cardBg(context),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? AppColors.accent : AppColors.cardBorder(context),
                          ),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.text(context),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Recipe Feed (Clean, Snug, No Empty Gaps)
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔍', style: TextStyle(fontSize: 42)),
                            const SizedBox(height: 12),
                            Text(
                              'No Indian recipes found matching filters',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try clearing your search or switching regional cuisine.',
                              style: TextStyle(color: AppColors.subtext(context), fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _selectedCuisine = 'All';
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.cardBorder(context)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Reset Filters', style: TextStyle(color: AppColors.text(context))),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final recipe = results[index];
                          return RecipeCard(
                            recipe: recipe,
                            showSavedIcon: true,
                            onTap: () => context.push('/recipe/${recipe.id}', extra: recipe),
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
