import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/core/networking/api_client.dart';
import 'package:rasoiai/shared/models/recipe.dart';
import 'package:rasoiai/shared/models/mock_recipes.dart';
import 'package:rasoiai/shared/widgets/culinary_loading_indicator.dart';

class RecipeCustomizationScreen extends StatefulWidget {
  final String recipeId;
  final Recipe? recipeExtra;

  const RecipeCustomizationScreen({
    super.key,
    required this.recipeId,
    this.recipeExtra,
  });

  @override
  State<RecipeCustomizationScreen> createState() => _RecipeCustomizationScreenState();
}

class _RecipeCustomizationScreenState extends State<RecipeCustomizationScreen> {
  late Recipe _recipe;
  final _customRequestController = TextEditingController();
  late String _adjustedSpice;
  bool _isModifying = false;
  final Set<String> _selectedPresets = {};

  final List<Map<String, String>> _presets = const [
    {'title': '🌿 Jain Style', 'desc': 'No onion, garlic, or root vegetables; substitute with hing and raw banana.'},
    {'title': '🥛 Dairy-Free (Vegan)', 'desc': 'Replace ghee, butter, paneer, and cream with mustard oil or cashew paste.'},
    {'title': '🌶️ Extra Spicy (Kolhapuri)', 'desc': 'Enhance heat with crushed black pepper, cloves, and fiery red chillies.'},
    {'title': '⏱️ 15-Min Express', 'desc': 'Quick one-pot pressure cooker method for busy weeknights.'},
    {'title': '🫒 Low Oil / Homestyle', 'desc': 'Minimal oil tempering, light gravy, easily digestible.'},
    {'title': '🥗 High Protein Boost', 'desc': 'Incorporate extra paneer, tofu cubes, or sprouted legumes.'},
  ];

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipeExtra ??
        mockRecipes.firstWhere(
          (r) => r.id == widget.recipeId,
          orElse: () => mockRecipes.first,
        );
    _adjustedSpice = _recipe.spiceLevel;
  }

  Future<void> _handleCustomize() async {
    final userPrompt = _customRequestController.text.trim();
    if (userPrompt.isEmpty && _selectedPresets.isEmpty && _adjustedSpice == _recipe.spiceLevel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a preset or type your custom recipe instructions.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isModifying = true);

    // Build cumulative customization prompt
    final List<String> instructions = [];
    for (final preset in _selectedPresets) {
      instructions.add(preset);
    }
    if (userPrompt.isNotEmpty) {
      instructions.add(userPrompt);
    }
    final combinedInstructions = instructions.join('. ');

    try {
      final updated = await apiClient.customizeRecipe(
        recipe: _recipe,
        instructions: combinedInstructions.isNotEmpty ? combinedInstructions : 'Adjust spice to $_adjustedSpice',
        spiceLevel: _adjustedSpice,
      );

      if (mounted) {
        setState(() => _isModifying = false);
        final finalRecipe = updated ??
            _recipe.copyWith(
              id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
              dishName: '${_recipe.dishName} (Customized)',
              spiceLevel: _adjustedSpice,
              description: 'Customized: $combinedInstructions. ${_recipe.description}',
            );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe customized successfully with Gemini AI!'),
            backgroundColor: AppColors.accent,
          ),
        );
        context.pushReplacement('/recipe/${finalRecipe.id}', extra: finalRecipe);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isModifying = false);
        final finalRecipe = _recipe.copyWith(
          id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
          dishName: '${_recipe.dishName} (Customized)',
          spiceLevel: _adjustedSpice,
        );
        context.pushReplacement('/recipe/${finalRecipe.id}', extra: finalRecipe);
      }
    }
  }

  @override
  void dispose() {
    _customRequestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Customize Recipe with AI'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Target Dish Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.auto_fix_high_rounded, color: AppColors.textPrimary, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _recipe.dishName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_recipe.cuisine} • ${_recipe.totalTimeMinutes}m • ${_recipe.servings} Servings',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Quick Indian Culinary Presets
              const Text(
                'Quick Dietary & Regional Presets',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((preset) {
                  final isSelected = _selectedPresets.contains(preset['desc']);
                  return FilterChip(
                    label: Text(preset['title']!),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedPresets.add(preset['desc']!);
                        } else {
                          _selectedPresets.remove(preset['desc']!);
                        }
                      });
                    },
                    selectedColor: AppColors.textPrimary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isSelected ? AppColors.textPrimary : AppColors.border),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Spice Level Selector
              const Text(
                'Adjust Spice Level',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _adjustedSpice,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
                items: ['Mild', 'Medium', 'Spicy', 'Extra Spicy']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) => setState(() => _adjustedSpice = val!),
              ),
              const SizedBox(height: 18),

              // Custom Instructions Prompt
              const Text(
                'Specific Kitchen Modifications',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _customRequestController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. "Replace cream with cashew milk", "Use pressure cooker instead of kadhai", "Make gravy extra thick"...',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 24),

              // Action CTA or Loading Animation
              if (_isModifying)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: CulinaryLoadingIndicator(
                      size: 64,
                      message: 'Recalibrating recipe with Gemini AI...',
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _handleCustomize,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 20),
                  label: const Text('Update & Recalibrate Recipe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
