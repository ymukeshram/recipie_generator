import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/shared/models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final bool showSavedIcon;
  final VoidCallback? onFavoriteTap;
  final double? width;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.showSavedIcon = false,
    this.onFavoriteTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image with Minimalist Floating Tag
            Stack(
              children: [
                recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: recipe.imageUrl!,
                        height: 125,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      recipe.cuisine,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (showSavedIcon)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      radius: 14,
                      child: IconButton(
                        iconSize: 14,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          recipe.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: recipe.isFavorite ? AppColors.errorRed : AppColors.textSecondary,
                        ),
                        onPressed: onFavoriteTap,
                      ),
                    ),
                  ),
              ],
            ),

            // Recipe Information (Clean, Readable with Indian Dietary Indicator)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      VegNonVegIndicator.fromRecipe(recipe, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          recipe.dishName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Dietary Pill & Servings
                  Row(
                    children: [
                      if (recipe.dietaryTags.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            recipe.dietaryTags.first,
                            style: const TextStyle(
                              color: AppColors.tagText,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (recipe.dietaryTags.isNotEmpty) const SizedBox(width: 6),
                      Text(
                        '${recipe.servings} ${recipe.servings == 1 ? 'serv' : 'servings'}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Time, Difficulty & Explicit Estimated Cooking Cost per Serving
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            '${recipe.totalTimeMinutes}m',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '•  ${recipe.difficulty}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Est. ₹${(recipe.costEstimateInr / (recipe.servings > 0 ? recipe.servings : 2)).round()}/serv',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    String emoji = '🍲';
    Color bgGradientStart = const Color(0xFFFBF4EB);
    Color bgGradientEnd = const Color(0xFFF1E4D3);

    final cuisineLower = recipe.cuisine.toLowerCase();
    final dishLower = recipe.dishName.toLowerCase();

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
      height: 125,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgGradientStart, bgGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle culinary spices background motif
          Opacity(
            opacity: 0.18,
            child: const Text(
              '🌿  🌶️  🧄  🧅  🍋',
              style: TextStyle(fontSize: 18, letterSpacing: 6),
            ),
          ),
          // Center authentic dish illustration badge
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 38)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  recipe.dishName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Standard Indian dietary classification indicator (Veg green dot, Non-veg red dot, Egg orange dot)
class VegNonVegIndicator extends StatelessWidget {
  final bool isVeg;
  final bool isEgg;
  final double size;

  const VegNonVegIndicator({
    super.key,
    required this.isVeg,
    this.isEgg = false,
    this.size = 14,
  });

  factory VegNonVegIndicator.fromRecipe(Recipe recipe, {double size = 14}) {
    final tags = recipe.dietaryTags.map((t) => t.toLowerCase().trim()).toList();
    final name = recipe.dishName.toLowerCase().trim();

    // 1. Explicit vegetarian check (if tagged Vegetarian, Vegan, Sattvik, Jain)
    final isExplicitVeg = tags.any((t) =>
        (t == 'vegetarian' || t == 'vegan' || t.contains('sattvik') || t.contains('jain') || t.contains('pure veg')) &&
        !t.contains('non'));

    // 2. Strict word-boundary regex for Non-Veg and Egg to avoid false matches (e.g. "kanda" != "anda")
    final nonVegWordRegex = RegExp(
      r'\b(chicken|mutton|fish|prawn|prawns|meat|keema|kheema|gosht|pork|beef|crab|lamb|shrimp|non-veg|non-vegetarian)\b',
      caseSensitive: false,
    );
    final eggWordRegex = RegExp(
      r'\b(egg|anda|ande|omlette|omelette|bhurji)\b',
      caseSensitive: false,
    );

    // If explicit vegetarian, always treat as Veg
    if (isExplicitVeg) {
      return VegNonVegIndicator(isVeg: true, isEgg: false, size: size);
    }

    final isNonVeg = tags.contains('non-vegetarian') ||
        tags.contains('non veg') ||
        nonVegWordRegex.hasMatch(name);

    final isEgg = !isNonVeg && (
        tags.contains('eggetarian') ||
        tags.contains('egg') ||
        eggWordRegex.hasMatch(name)
    );

    return VegNonVegIndicator(
      isVeg: !isNonVeg && !isEgg,
      isEgg: isEgg,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = isVeg
        ? const Color(0xFF2E7D32)
        : (isEgg ? const Color(0xFFE65100) : const Color(0xFFC62828));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.45,
        height: size * 0.45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
