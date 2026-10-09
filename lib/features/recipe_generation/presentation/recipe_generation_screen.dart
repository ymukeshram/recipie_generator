import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/core/networking/api_client.dart';
import 'package:rasoiai/shared/widgets/culinary_loading_indicator.dart';
import 'package:rasoiai/shared/widgets/theme_toggle_button.dart';
import 'package:rasoiai/core/services/history_service.dart';

class RecipeGenerationScreen extends StatefulWidget {
  const RecipeGenerationScreen({super.key});

  @override
  State<RecipeGenerationScreen> createState() => _RecipeGenerationScreenState();
}

class _RecipeGenerationScreenState extends State<RecipeGenerationScreen> {
  final _dishNameController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _excludedIngredientsController = TextEditingController();
  final _requestPromptController = TextEditingController();

  String _cuisine = 'North Indian';
  String _mealCategory = 'Dinner';
  int _servings = 2;
  int _maxTimeMinutes = 30;
  int _budgetInr = 150;
  String _spiceLevel = 'Medium';
  String _dietaryPreference = 'Vegetarian';
  bool _isLoading = false;

  final Set<String> _selectedQuickPrompts = {};

  final List<String> _cuisines = [
    'North Indian',
    'South Indian',
    'Punjabi',
    'Gujarati',
    'Maharashtrian',
    'Bengali',
    'Any Indian Regional',
  ];

  final List<String> _mealCategories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks & Street Food',
    'Dessert',
  ];

  final List<String> _spiceLevels = ['Mild', 'Medium', 'Spicy', 'Extra Spicy (Fiery)'];
  final List<String> _dietOptions = ['Vegetarian', 'Vegan', 'Eggetarian', 'Non-Vegetarian'];

  void _toggleQuickPrompt(_QuickPromptItem item, bool selected) {
    setState(() {
      if (selected) {
        _selectedQuickPrompts.add(item.title);
        switch (item.title) {
          case 'Leftovers in fridge':
            if (!_ingredientsController.text.contains('Leftover')) {
              _ingredientsController.text = _ingredientsController.text.isEmpty
                  ? 'Leftover cooked rice, vegetables from fridge, curd, spices'
                  : '${_ingredientsController.text}, leftover vegetables';
            }
            break;
          case 'Under 20 mins':
            _maxTimeMinutes = 20;
            break;
          case 'No Onion/Garlic':
            if (!_excludedIngredientsController.text.contains('Onion')) {
              _excludedIngredientsController.text = _excludedIngredientsController.text.isEmpty
                  ? 'Onion, Garlic'
                  : '${_excludedIngredientsController.text}, Onion, Garlic';
            }
            break;
          case 'High Protein':
            if (!_requestPromptController.text.contains('High protein')) {
              _requestPromptController.text = _requestPromptController.text.isEmpty
                  ? 'High protein nutritious fitness meal (e.g. paneer, soya, dal)'
                  : '${_requestPromptController.text}, high protein';
            }
            break;
          case 'Quick Homestyle':
            if (!_requestPromptController.text.contains('Homestyle')) {
              _requestPromptController.text = _requestPromptController.text.isEmpty
                  ? 'Simple ghar jaisa homestyle comfort food'
                  : '${_requestPromptController.text}, homestyle';
            }
            break;
          case 'Late Night Snack':
            _mealCategory = 'Snacks & Street Food';
            if (!_requestPromptController.text.contains('Late night')) {
              _requestPromptController.text = _requestPromptController.text.isEmpty
                  ? 'Quick late night snack ready fast'
                  : '${_requestPromptController.text}, quick snack';
            }
            break;
        }
      } else {
        _selectedQuickPrompts.remove(item.title);
        if (item.title == 'Under 20 mins' && _maxTimeMinutes == 20) {
          _maxTimeMinutes = 30;
        }
      }
    });
  }

  Future<void> _handleGenerate() async {
    if (_dishNameController.text.trim().isEmpty &&
        _ingredientsController.text.trim().isEmpty &&
        _requestPromptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least a dish name, available ingredients, or cooking prompt.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final recipe = await apiClient.generateRecipe(
        dishName: _dishNameController.text.trim(),
        ingredients: _ingredientsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        excludedIngredients: _excludedIngredientsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        prompt: _requestPromptController.text.trim().isNotEmpty
            ? _requestPromptController.text.trim()
            : null,
        cuisine: _cuisine,
        mealCategory: _mealCategory,
        servings: _servings,
        maxTimeMinutes: _maxTimeMinutes,
        budgetInr: _budgetInr,
        spiceLevel: _spiceLevel,
        dietaryPreference: _dietaryPreference,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (recipe != null) {
          historyService.addRecipe(recipe);
          context.push('/recipe/${recipe.id}', extra: recipe);
        } else {
          context.push('/recipe/generated-1');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        context.push('/recipe/generated-1');
      }
    }
  }

  @override
  void dispose() {
    _dishNameController.dispose();
    _ingredientsController.dispose();
    _excludedIngredientsController.dispose();
    _requestPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recipe Generation'),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Generate from Photo',
            onPressed: () => context.push('/generate/photo'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quick Input Expectations: Tag Chips to reduce cognitive load
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Prompts & Ideas',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap any tag to instantly configure your recipe request',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickPrompts.map((item) {
                      final isSelected = _selectedQuickPrompts.contains(item.title);
                      return FilterChip(
                        selected: isSelected,
                        avatar: Text(item.emoji, style: const TextStyle(fontSize: 13)),
                        label: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.textPrimary,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: isSelected ? AppColors.textPrimary : AppColors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        onSelected: (selected) => _toggleQuickPrompt(item, selected),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Dish Name Input
              const Text(
                'Dish Name or Cooking Idea',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _dishNameController,
                decoration: InputDecoration(
                  hintText: 'e.g., Dal Tadka, Aloo Paratha, Chicken Curry...',
                  prefixIcon: const Icon(Icons.restaurant_menu_rounded, color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 16),

              // Available Ingredients
              const Text(
                'Available Ingredients in Kitchen',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _ingredientsController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g., Rice, curd, mustard seeds, curry leaves, ginger...',
                  prefixIcon: const Icon(Icons.kitchen_outlined, color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 16),

              // Specific Request
              const Text(
                'Specific Prompt or Instructions',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _requestPromptController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g., "Authentic dhaba style, low oil, ready in under 25 mins"',
                  prefixIcon: const Icon(Icons.auto_awesome, color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 20),

              // Parameters Section
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),
              const Text(
                'Parameters & Indian Preferences',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Regional Cuisine', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _cuisine,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                          items: _cuisines
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) => setState(() => _cuisine = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Meal Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _mealCategory,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                          items: _mealCategories
                              .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) => setState(() => _mealCategory = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Diet Preference', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _dietaryPreference,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                          items: _dietOptions
                              .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) => setState(() => _dietaryPreference = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Spice Level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _spiceLevel,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                          items: _spiceLevels
                              .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) => setState(() => _spiceLevel = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Servings adjustment
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Servings: $_servings People', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.textPrimary),
                          onPressed: _servings > 1 ? () => setState(() => _servings--) : null,
                        ),
                        Text('$_servings', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.textPrimary),
                          onPressed: _servings < 12 ? () => setState(() => _servings++) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Sliders
              Text('Maximum Cooking Time: $_maxTimeMinutes mins', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              Slider(
                value: _maxTimeMinutes.toDouble(),
                min: 15,
                max: 120,
                divisions: 7,
                activeColor: AppColors.textPrimary,
                inactiveColor: AppColors.border,
                label: '$_maxTimeMinutes mins',
                onChanged: (v) => setState(() => _maxTimeMinutes = v.toInt()),
              ),

              Text('Budget Constraint: ₹$_budgetInr', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              Slider(
                value: _budgetInr.toDouble(),
                min: 50,
                max: 1000,
                divisions: 19,
                activeColor: AppColors.textPrimary,
                inactiveColor: AppColors.border,
                label: '₹$_budgetInr',
                onChanged: (v) => setState(() => _budgetInr = v.toInt()),
              ),

              const SizedBox(height: 20),

              // Loading animation or Generate CTA
              if (_isLoading)
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
                      message: 'Crafting authentic Indian recipe...',
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _handleGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  label: const Text('Generate Recipe', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  ),
    );
  }
}

class _QuickPromptItem {
  final String title;
  final String emoji;
  final String description;

  const _QuickPromptItem({
    required this.title,
    required this.emoji,
    required this.description,
  });
}

final List<_QuickPromptItem> _quickPrompts = const [
  _QuickPromptItem(title: 'Leftovers in fridge', emoji: '🧊', description: 'Make the best meal from fridge leftovers'),
  _QuickPromptItem(title: 'Under 20 mins', emoji: '⏱️', description: 'Fast, hassle-free recipe ready in 20 minutes'),
  _QuickPromptItem(title: 'No Onion/Garlic', emoji: '🌿', description: 'Pure Sattvik / Jain homestyle dish'),
  _QuickPromptItem(title: 'High Protein', emoji: '💪', description: 'Protein-packed fitness meal'),
  _QuickPromptItem(title: 'Quick Homestyle', emoji: '🍛', description: 'Simple comforting ghar ka swaad'),
  _QuickPromptItem(title: 'Late Night Snack', emoji: '🌙', description: 'Quick midnight craving or street-style snack'),
];
