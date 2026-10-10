import 'dart:math' as math;
import 'package:flutter/material.dart';
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

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
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
    // When wheel rotates by totalAngle, target segment center aligns with -pi/2
    final rotations = 5 + _random.nextInt(3); // 5 to 7 full rotations
    final targetRotation = (rotations * 2 * math.pi) + (-math.pi / 2 - centerAngle);

    final startAngle = _currentAngle % (2 * math.pi);
    // Ensure rotation is strictly positive and forward
    final endAngle = startAngle + (rotations * 2 * math.pi) + (targetRotation - startAngle) % (2 * math.pi);

    _wheelAnimation = Tween<double>(begin: startAngle, end: endAngle).animate(
      CurvedAnimation(parent: _wheelController, curve: Curves.easeOutCubic),
    );

    _wheelController.reset();
    _wheelController.forward().then((_) {
      _currentAngle = endAngle;
      setState(() {
        _isSpinning = false;
        _selectedSegment = targetSegment;
      });
      _fetchRecipeForSegment(targetSegment);
    });
  }

  Future<void> _fetchRecipeForSegment(WheelSegment segment) async {
    setState(() => _isGeneratingRecipe = true);

    Recipe? recipe;

    // 1. Try real backend API generation
    try {
      recipe = await apiClient.generateRecipe(
        dishName: '',
        cuisine: segment.cuisineHint,
        mealCategory: segment.categoryKey,
        prompt: 'Surprise me with an authentic, beloved ${segment.label} recipe.',
        servings: 2,
        maxTimeMinutes: segment.label.contains('Quick') ? 20 : 35,
      );
    } catch (_) {}

    // 2. Reliable Curated Fallback
    if (recipe == null) {
      final matching = mockRecipes.where((r) {
        final query = segment.cuisineHint.toLowerCase();
        return r.cuisine.toLowerCase().contains(query) ||
            r.mealCategory.toLowerCase().contains(segment.categoryKey.toLowerCase());
      }).toList();

      if (matching.isNotEmpty) {
        recipe = matching[_random.nextInt(matching.length)];
      } else {
        recipe = mockRecipes[_random.nextInt(mockRecipes.length)];
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

                  // Recipe Generation Loading
                  if (_isGeneratingRecipe)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2835) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        children: [
                          Text(_selectedSegment?.emoji ?? '🍲', style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected: ${_selectedSegment?.label ?? "Mystery Dish"}!',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'RasoiAI is crafting your recipe...',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF16A34A)),
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
