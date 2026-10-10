import 'package:flutter/material.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/core/services/gamification_service.dart';

class CookingStreakCard extends StatelessWidget {
  final GamificationState state;

  const CookingStreakCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate current milestone (e.g. 3, 7, 14, 30 days)
    final milestones = [3, 7, 14, 30, 60, 100];
    int nextMilestone = milestones.firstWhere((m) => m > state.currentStreak, orElse: () => 100);
    double milestoneProgress = (state.currentStreak / nextMilestone).clamp(0.0, 1.0);

    // Days of current week (Mon - Sun)
    final now = DateTime.now();
    // Monday of this week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Streak Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF332014) : const Color(0xFFFFF3EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${state.currentStreak}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            state.currentStreak == 1 ? 'Day Streak' : 'Days Streak',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE65100), // Vibrant Flame Orange
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Personal Best: ${state.longestStreak} days',
                        style: TextStyle(fontSize: 12, color: AppColors.subtext(context)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2E35) : AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder(context)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.military_tech_rounded, size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Text(
                      '${state.chefPoints} pts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekly Calendar Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final d = weekDays[i];
              final dateKey = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              final isCompleted = state.completedDates.contains(dateKey);
              final isToday = d.year == now.year && d.month == now.month && d.day == now.day;

              return Column(
                children: [
                  Text(
                    dayLabels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday ? const Color(0xFFE65100) : AppColors.subtext(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFE65100)
                          : isToday
                              ? (isDark ? const Color(0xFF2D2520) : const Color(0xFFFFECE0))
                              : (isDark ? const Color(0xFF1E2228) : AppColors.surfaceSubtle),
                      shape: BoxShape.circle,
                      border: isToday && !isCompleted
                          ? Border.all(color: const Color(0xFFE65100), width: 1.5)
                          : Border.all(color: AppColors.cardBorder(context)),
                    ),
                    alignment: Alignment.center,
                    child: isCompleted
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? const Color(0xFFE65100) : AppColors.subtext(context),
                            ),
                          ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),

          // Milestone Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Milestone: $nextMilestone Days 🔥',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text(context)),
              ),
              Text(
                '${state.currentStreak} / $nextMilestone',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.subtext(context)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: milestoneProgress,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF282D35) : AppColors.surfaceSubtle,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
            ),
          ),
        ],
      ),
    );
  }
}

class DailyChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final VoidCallback onAccept;

  const DailyChallengeCard({
    super.key,
    required this.challenge,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: challenge.isCompleted
              ? const Color(0xFF10B981)
              : challenge.isAccepted
                  ? const Color(0xFF3B82F6)
                  : AppColors.cardBorder(context),
          width: challenge.isCompleted || challenge.isAccepted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title & Points Reward
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(challenge.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    challenge.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: challenge.isCompleted
                      ? const Color(0xFFD1FAE5)
                      : (isDark ? const Color(0xFF232D3F) : const Color(0xFFEFF6FF)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      challenge.isCompleted ? Icons.check_circle : Icons.stars_rounded,
                      size: 14,
                      color: challenge.isCompleted ? const Color(0xFF059669) : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${challenge.rewardPoints} pts',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: challenge.isCompleted ? const Color(0xFF059669) : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            challenge.description,
            style: TextStyle(fontSize: 13, color: AppColors.subtext(context), height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            'Requirement: ${challenge.requirement}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 12),

          // Action State
          if (challenge.isCompleted) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Challenge Completed! +100 Points Awarded',
                    style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ] else if (challenge.isAccepted) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'In Progress • Cook any qualifying recipe today to complete',
                    style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Accepted', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.text(context),
                  foregroundColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('Accept Daily Challenge', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                onPressed: onAccept,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BadgesGridSection extends StatelessWidget {
  final List<BadgeItem> badges;

  const BadgesGridSection({super.key, required this.badges});

  void _showBadgeDetails(BuildContext context, BadgeItem badge) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: badge.isUnlocked ? const Color(0xFFFEF3C7) : AppColors.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              child: Text(badge.emoji, style: const TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 14),
            Text(
              badge.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badge.isUnlocked ? const Color(0xFFD1FAE5) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge.isUnlocked ? '✓ UNLOCKED' : '🔒 LOCKED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badge.isUnlocked ? const Color(0xFF047857) : const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Text(
                    'Requirement: ${badge.requirement}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Progress: ${badge.currentProgress} / ${badge.maxProgress}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unlockedCount = badges.where((b) => b.isUnlocked).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievement Badges 🏆',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
              Text(
                '$unlockedCount / ${badges.length} Unlocked',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.subtext(context)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Responsive Grid of Badges
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showBadgeDetails(context, badge),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: badge.isUnlocked
                        ? (isDark ? const Color(0xFF28241D) : const Color(0xFFFFFBEB))
                        : (isDark ? const Color(0xFF1E2228) : AppColors.surfaceSubtle),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: badge.isUnlocked
                          ? const Color(0xFFF59E0B) // Amber Gold
                          : AppColors.cardBorder(context),
                      width: badge.isUnlocked ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: badge.isUnlocked ? 1.0 : 0.4,
                            child: Text(badge.emoji, style: const TextStyle(fontSize: 28)),
                          ),
                          if (!badge.isUnlocked)
                            const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF9CA3AF)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        badge.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: badge.isUnlocked ? FontWeight.bold : FontWeight.w500,
                          color: badge.isUnlocked ? AppColors.text(context) : AppColors.subtext(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (badge.isUnlocked)
                        const Text(
                          'Unlocked ⭐',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        )
                      else
                        Text(
                          '${badge.currentProgress}/${badge.maxProgress}',
                          style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
