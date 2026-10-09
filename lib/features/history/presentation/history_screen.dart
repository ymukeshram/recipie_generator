import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/core/services/history_service.dart';
import 'package:rasoiai/shared/models/recipe.dart';
import 'package:rasoiai/shared/widgets/theme_toggle_button.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Generation History'),
        actions: [
          const ThemeToggleButton(),
          ValueListenableBuilder<List<Recipe>>(
            valueListenable: historyService.historyNotifier,
            builder: (context, history, _) {
              if (history.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Clear All History',
                onPressed: () => _confirmClearHistory(context),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Recipe>>(
        valueListenable: historyService.historyNotifier,
        builder: (context, history, _) {
          if (history.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? DarkColors.surfaceSubtle : AppColors.accentLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history_toggle_off,
                        size: 56,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Recipe History Yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Every authentic Indian recipe you generate using AI prompts or photo snaps will be saved here automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.subtext(context),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate Your First Recipe'),
                      onPressed: () => context.go('/generate'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = history[index];
              final isVeg = item.dietaryTags.any((t) =>
                  t.toLowerCase().contains('veg') && !t.toLowerCase().contains('non'));

              return Dismissible(
                key: Key('${item.id}_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) {
                  historyService.removeRecipe(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed "${item.dishName}" from history'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push('/recipe/${item.id}', extra: item),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.cardBorder(context),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Dish Thumbnail or Icon
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item.imageUrl != null && item.imageUrl!.startsWith('http')
                              ? Image.network(
                                  item.imageUrl!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _fallbackIcon(isDark),
                                )
                              : _fallbackIcon(isDark),
                        ),
                        const SizedBox(width: 14),
                        // Title and details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Veg/Non-Veg indicator dot
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isVeg ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isVeg ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.dishName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.text(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.cuisine} • ${item.totalTimeMinutes}m • Est. ₹${item.costEstimateInr.round()}/serv',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.subtext(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? DarkColors.surfaceSubtle : AppColors.surfaceSubtle,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.spiceLevel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.amber.shade300 : AppColors.amberGold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${item.servings} Servings',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.subtext(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.subtext(context),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _fallbackIcon(bool isDark) {
    return Container(
      width: 60,
      height: 60,
      color: isDark ? DarkColors.surfaceSubtle : AppColors.accentLight,
      child: const Icon(Icons.restaurant_menu, color: AppColors.accent, size: 28),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Recipe History?'),
        content: const Text('This will delete all previously generated recipes from your local history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            onPressed: () {
              historyService.clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
