import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rasoiai/core/theme/app_colors.dart';

/// Smooth rotating vegetables loading indicator with cycling Indian culinary ingredients.
class CulinaryLoadingIndicator extends StatefulWidget {
  final double size;
  final String? message;

  const CulinaryLoadingIndicator({
    super.key,
    this.size = 64.0,
    this.message,
  });

  @override
  State<CulinaryLoadingIndicator> createState() => _CulinaryLoadingIndicatorState();
}

class _CulinaryLoadingIndicatorState extends State<CulinaryLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  int _currentVeggieIndex = 0;

  // Indian kitchen fresh ingredient emojis cycling smoothly
  final List<String> _ingredients = ['🍅', '🧄', '🧅', '🥕', '🥔', '🌶️', '🌿', '🍋'];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _rotationController.addListener(() {
      final newIndex = (_rotationController.value * _ingredients.length).floor() % _ingredients.length;
      if (newIndex != _currentVeggieIndex) {
        setState(() {
          _currentVeggieIndex = newIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Smooth orbiting track with floating vegetable orbit
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Orbiting baby carrot/leaf on the edge
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentLight,
                              border: Border.all(color: AppColors.accent, width: 1.2),
                            ),
                            child: const Center(
                              child: Text('🌿', style: TextStyle(fontSize: 8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Center pulsating vegetable badge
            Container(
              width: widget.size * 0.68,
              height: widget.size * 0.68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Text(
                    _ingredients[_currentVeggieIndex],
                    key: ValueKey<int>(_currentVeggieIndex),
                    style: TextStyle(fontSize: widget.size * 0.36),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.message!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
