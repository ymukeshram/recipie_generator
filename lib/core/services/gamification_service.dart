import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rasoiai/shared/models/recipe.dart';

class BadgeItem {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String requirement;
  final int maxProgress;
  int currentProgress;
  bool isUnlocked;
  String? unlockedDate;

  BadgeItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.requirement,
    required this.maxProgress,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.unlockedDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'description': description,
    'requirement': requirement,
    'maxProgress': maxProgress,
    'currentProgress': currentProgress,
    'isUnlocked': isUnlocked,
    'unlockedDate': unlockedDate,
  };

  factory BadgeItem.fromJson(Map<String, dynamic> json) => BadgeItem(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String,
    description: json['description'] as String,
    requirement: json['requirement'] as String,
    maxProgress: (json['maxProgress'] as num?)?.toInt() ?? 1,
    currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
    isUnlocked: json['isUnlocked'] as bool? ?? false,
    unlockedDate: json['unlockedDate'] as String?,
  );
}

class DailyChallenge {
  final String id;
  final String dateKey; // YYYY-MM-DD
  final String title;
  final String emoji;
  final String description;
  final String requirement;
  final int rewardPoints;
  bool isAccepted;
  bool isCompleted;
  double progress;

  DailyChallenge({
    required this.id,
    required this.dateKey,
    required this.title,
    required this.emoji,
    required this.description,
    required this.requirement,
    required this.rewardPoints,
    this.isAccepted = false,
    this.isCompleted = false,
    this.progress = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dateKey': dateKey,
    'title': title,
    'emoji': emoji,
    'description': description,
    'requirement': requirement,
    'rewardPoints': rewardPoints,
    'isAccepted': isAccepted,
    'isCompleted': isCompleted,
    'progress': progress,
  };

  factory DailyChallenge.fromJson(Map<String, dynamic> json) => DailyChallenge(
    id: json['id'] as String,
    dateKey: json['dateKey'] as String,
    title: json['title'] as String,
    emoji: json['emoji'] as String,
    description: json['description'] as String,
    requirement: json['requirement'] as String,
    rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 100,
    isAccepted: json['isAccepted'] as bool? ?? false,
    isCompleted: json['isCompleted'] as bool? ?? false,
    progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
  );
}

class GamificationState {
  int currentStreak;
  int longestStreak;
  String? lastCookedDate;
  Set<String> completedDates; // YYYY-MM-DD
  int totalRecipesCooked;
  int chefPoints;
  Set<String> cookedCuisines;
  int completedChallengesCount;
  List<BadgeItem> badges;
  DailyChallenge dailyChallenge;

  GamificationState({
    required this.currentStreak,
    required this.longestStreak,
    this.lastCookedDate,
    required this.completedDates,
    required this.totalRecipesCooked,
    required this.chefPoints,
    required this.cookedCuisines,
    required this.completedChallengesCount,
    required this.badges,
    required this.dailyChallenge,
  });

  factory GamificationState.initial() => GamificationState(
    currentStreak: 1,
    longestStreak: 1,
    lastCookedDate: null,
    completedDates: {},
    totalRecipesCooked: 1,
    chefPoints: 120,
    cookedCuisines: {'North Indian'},
    completedChallengesCount: 0,
    badges: GamificationService.defaultBadges.map((b) => BadgeItem(
      id: b.id,
      name: b.name,
      emoji: b.emoji,
      description: b.description,
      requirement: b.requirement,
      currentProgress: b.currentProgress,
      maxProgress: b.maxProgress,
      isUnlocked: b.isUnlocked,
    )).toList(),
    dailyChallenge: GamificationService.challengeTemplates.first,
  );
}

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'rasoiai_gamification_v2';

  final ValueNotifier<GamificationState?> stateNotifier = ValueNotifier<GamificationState?>(null);
  final ValueNotifier<BadgeItem?> newlyUnlockedBadgeNotifier = ValueNotifier<BadgeItem?>(null);
  final ValueNotifier<String?> streakCelebrationNotifier = ValueNotifier<String?>(null);

  bool _initialized = false;

  static final List<BadgeItem> defaultBadges = [
    BadgeItem(
      id: 'egg_master',
      name: 'Egg Master',
      emoji: '🥚',
      description: 'Master authentic Indian egg dishes and bhurjis.',
      requirement: 'Complete 3 egg recipes',
      maxProgress: 3,
    ),
    BadgeItem(
      id: 'spice_master',
      name: 'Spice Master',
      emoji: '🌶️',
      description: 'Cook bold, fiery curries and spiced tadkas.',
      requirement: 'Complete 3 Spicy / Fiery recipes',
      maxProgress: 3,
    ),
    BadgeItem(
      id: 'budget_boss',
      name: 'Budget Boss',
      emoji: '💰',
      description: 'Cook delicious meals under budget constraints.',
      requirement: 'Cook 3 recipes under ₹120/serv',
      maxProgress: 3,
    ),
    BadgeItem(
      id: 'healthy_hero',
      name: 'Healthy Hero',
      emoji: '🥗',
      description: 'Prepare wholesome, high-protein or low-calorie dishes.',
      requirement: 'Cook 3 healthy or low-cal meals',
      maxProgress: 3,
    ),
    BadgeItem(
      id: 'fridge_saver',
      name: 'Fridge Saver',
      emoji: '🧊',
      description: 'Turn fridge leftovers and odd vegetables into tasty meals.',
      requirement: 'Cook 3 leftover-based meals',
      maxProgress: 3,
    ),
    BadgeItem(
      id: 'cuisine_explorer',
      name: 'Cuisine Explorer',
      emoji: '🗺️',
      description: 'Explore multiple diverse regional Indian cuisines.',
      requirement: 'Cook dishes from 3 distinct cuisines',
      maxProgress: 3,
    ),
    BadgeItem(
      id: 'master_chef',
      name: 'Master Chef',
      emoji: '👨‍🍳',
      description: 'Dedicated culinary expert who cooks regularly.',
      requirement: 'Complete 10 total recipes',
      maxProgress: 10,
    ),
    BadgeItem(
      id: 'streak_champion',
      name: 'Streak Champion',
      emoji: '🔥',
      description: 'Keep the kitchen fire burning all week long.',
      requirement: 'Reach a 7-day cooking streak',
      maxProgress: 7,
    ),
    BadgeItem(
      id: 'challenge_champion',
      name: 'Challenge Champion',
      emoji: '🎯',
      description: 'Tackle and complete multiple daily culinary challenges.',
      requirement: 'Complete 5 Daily Challenges',
      maxProgress: 5,
    ),
  ];

  static final List<DailyChallenge> challengeTemplates = [
    DailyChallenge(
      id: '15_min_chef',
      dateKey: '',
      title: '15-Minute Chef',
      emoji: '⏱️',
      description: 'Cook any quick, comforting Indian dish in under 25 minutes.',
      requirement: 'Cook a recipe with prep + cook time ≤ 25 mins',
      rewardPoints: 100,
    ),
    DailyChallenge(
      id: 'three_ingredient',
      dateKey: '',
      title: 'Three-Ingredient Challenge',
      emoji: '🧂',
      description: 'Prepare a minimalist dish with 5 or fewer core ingredients.',
      requirement: 'Cook a recipe with 5 or fewer ingredients',
      rewardPoints: 100,
    ),
    DailyChallenge(
      id: 'fridge_saver_challenge',
      dateKey: '',
      title: 'Fridge Saver Challenge',
      emoji: '🧊',
      description: 'Use whatever is left in your fridge to whip up a fresh meal.',
      requirement: 'Generate & cook a recipe using available fridge items',
      rewardPoints: 100,
    ),
    DailyChallenge(
      id: 'spice_adventure',
      dateKey: '',
      title: 'Spice Adventure',
      emoji: '🌶️',
      description: 'Embrace the heat! Cook a dish with Medium or Spicy flavor profile.',
      requirement: 'Cook any Medium or Spicy regional recipe',
      rewardPoints: 100,
    ),
    DailyChallenge(
      id: 'healthy_choice',
      dateKey: '',
      title: 'Healthy Choice',
      emoji: '🥗',
      description: 'Cook a nutritious dish under 380 calories or marked High Protein.',
      requirement: 'Cook a healthy meal with ≤ 380 kcal or High Protein',
      rewardPoints: 100,
    ),
    DailyChallenge(
      id: 'cuisine_explorer_challenge',
      dateKey: '',
      title: 'Cuisine Explorer',
      emoji: '🗺️',
      description: 'Try a dish from outside your primary cooking region.',
      requirement: 'Cook a dish from a new regional cuisine',
      rewardPoints: 100,
    ),
  ];

  static String _todayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _yesterdayDateKey() {
    final yest = DateTime.now().subtract(const Duration(days: 1));
    return '${yest.year}-${yest.month.toString().padLeft(2, '0')}-${yest.day.toString().padLeft(2, '0')}';
  }

  DailyChallenge _generateChallengeForToday(String todayKey) {
    // Deterministic selection based on day of year
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final template = challengeTemplates[dayOfYear % challengeTemplates.length];
    return DailyChallenge(
      id: '${template.id}_$todayKey',
      dateKey: todayKey,
      title: template.title,
      emoji: template.emoji,
      description: template.description,
      requirement: template.requirement,
      rewardPoints: template.rewardPoints,
      isAccepted: false,
      isCompleted: false,
      progress: 0.0,
    );
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      final todayKey = _todayDateKey();

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        final badgesList = (data['badges'] as List? ?? [])
            .map((b) => BadgeItem.fromJson(b as Map<String, dynamic>))
            .toList();

        // Ensure all default badges exist in the loaded badges
        for (final def in defaultBadges) {
          if (!badgesList.any((b) => b.id == def.id)) {
            badgesList.add(def);
          }
        }

        DailyChallenge dailyCh;
        if (data['dailyChallenge'] != null && data['dailyChallenge']['dateKey'] == todayKey) {
          dailyCh = DailyChallenge.fromJson(data['dailyChallenge'] as Map<String, dynamic>);
        } else {
          dailyCh = _generateChallengeForToday(todayKey);
        }

        int currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;
        final longestStreak = (data['longestStreak'] as num?)?.toInt() ?? 0;
        final lastCooked = data['lastCookedDate'] as String?;
        final completedDates = (data['completedDates'] as List? ?? []).map((e) => e.toString()).toSet();
        final cookedCuisines = (data['cookedCuisines'] as List? ?? []).map((e) => e.toString()).toSet();

        // Check if streak broke (more than 1 day missed)
        if (lastCooked != null && lastCooked != todayKey && lastCooked != _yesterdayDateKey()) {
          currentStreak = 0;
        }

        stateNotifier.value = GamificationState(
          currentStreak: currentStreak,
          longestStreak: longestStreak,
          lastCookedDate: lastCooked,
          completedDates: completedDates,
          totalRecipesCooked: (data['totalRecipesCooked'] as num?)?.toInt() ?? 0,
          chefPoints: (data['chefPoints'] as num?)?.toInt() ?? 100,
          cookedCuisines: cookedCuisines,
          completedChallengesCount: (data['completedChallengesCount'] as num?)?.toInt() ?? 0,
          badges: badgesList,
          dailyChallenge: dailyCh,
        );
      } else {
        // Seed first-time state with engaging initial values
        final todayKey = _todayDateKey();
        final yestKey = _yesterdayDateKey();
        final initialDates = {yestKey};
        final dailyCh = _generateChallengeForToday(todayKey);

        stateNotifier.value = GamificationState(
          currentStreak: 1, // Start user off with a friendly 1-day active streak
          longestStreak: 1,
          lastCookedDate: yestKey,
          completedDates: initialDates,
          totalRecipesCooked: 1,
          chefPoints: 120,
          cookedCuisines: {'North Indian'},
          completedChallengesCount: 0,
          badges: defaultBadges,
          dailyChallenge: dailyCh,
        );
        await _persist();
      }
    } catch (e) {
      debugPrint('Error initializing GamificationService: $e');
      final todayKey = _todayDateKey();
      stateNotifier.value = GamificationState(
        currentStreak: 1,
        longestStreak: 1,
        completedDates: {},
        totalRecipesCooked: 0,
        chefPoints: 100,
        cookedCuisines: {},
        completedChallengesCount: 0,
        badges: defaultBadges,
        dailyChallenge: _generateChallengeForToday(todayKey),
      );
    }
    _initialized = true;
  }

  Future<void> acceptTodayChallenge() async {
    final state = stateNotifier.value;
    if (state == null) return;
    state.dailyChallenge.isAccepted = true;
    stateNotifier.value = state;
    await _persist();
  }

  Future<void> markRecipeCompleted(Recipe recipe) async {
    final state = stateNotifier.value;
    if (state == null) return;

    final todayKey = _todayDateKey();
    final yestKey = _yesterdayDateKey();

    // 1. Streak Calculation
    bool streakIncreased = false;
    if (state.lastCookedDate == yestKey) {
      state.currentStreak += 1;
      streakIncreased = true;
    } else if (state.lastCookedDate == todayKey) {
      // Already cooked today: streak count is preserved, total count increments
    } else {
      // Missed one or more days: resets to 1
      state.currentStreak = 1;
      streakIncreased = true;
    }

    if (state.currentStreak > state.longestStreak) {
      state.longestStreak = state.currentStreak;
    }
    state.lastCookedDate = todayKey;
    state.completedDates.add(todayKey);
    state.totalRecipesCooked += 1;
    state.chefPoints += 50; // +50 points per cooked recipe
    state.cookedCuisines.add(recipe.cuisine);

    if (streakIncreased) {
      streakCelebrationNotifier.value = '🔥 Cooking Streak: ${state.currentStreak} Days!';
    }

    // 2. Badge Progression
    for (final badge in state.badges) {
      if (badge.isUnlocked) continue;
      bool progressMade = false;

      switch (badge.id) {
        case 'egg_master':
          final isEgg = recipe.dishName.toLowerCase().contains('egg') ||
              recipe.dishName.toLowerCase().contains('bhurji') ||
              recipe.dietaryTags.any((t) => t.toLowerCase().contains('egg'));
          if (isEgg) {
            badge.currentProgress += 1;
            progressMade = true;
          }
          break;
        case 'spice_master':
          if (recipe.spiceLevel == 'Spicy' || recipe.spiceLevel.contains('Fiery') || recipe.spiceLevel == 'Extra Spicy') {
            badge.currentProgress += 1;
            progressMade = true;
          }
          break;
        case 'budget_boss':
          if (recipe.costEstimateInr <= 120.0) {
            badge.currentProgress += 1;
            progressMade = true;
          }
          break;
        case 'healthy_hero':
          final cal = recipe.nutrition?.calories ?? 400;
          final isHealthy = cal <= 350 || recipe.dietaryTags.any((t) => t.toLowerCase().contains('protein') || t.toLowerCase().contains('healthy'));
          if (isHealthy) {
            badge.currentProgress += 1;
            progressMade = true;
          }
          break;
        case 'fridge_saver':
          badge.currentProgress += 1;
          progressMade = true;
          break;
        case 'cuisine_explorer':
          badge.currentProgress = state.cookedCuisines.length;
          progressMade = true;
          break;
        case 'master_chef':
          badge.currentProgress = state.totalRecipesCooked;
          progressMade = true;
          break;
        case 'streak_champion':
          badge.currentProgress = state.currentStreak;
          progressMade = true;
          break;
        case 'challenge_champion':
          badge.currentProgress = state.completedChallengesCount;
          progressMade = true;
          break;
      }

      if (badge.currentProgress >= badge.maxProgress) {
        badge.currentProgress = badge.maxProgress;
        badge.isUnlocked = true;
        badge.unlockedDate = todayKey;
        state.chefPoints += 150; // +150 points for badge achievement
        newlyUnlockedBadgeNotifier.value = badge;
      }
    }

    // 3. Daily Challenge Evaluation
    final ch = state.dailyChallenge;
    if (ch.isAccepted && !ch.isCompleted) {
      bool eligible = false;
      if (ch.id.contains('15_min_chef')) {
        eligible = recipe.totalTimeMinutes <= 25;
      } else if (ch.id.contains('three_ingredient')) {
        eligible = recipe.ingredients.length <= 6;
      } else if (ch.id.contains('fridge_saver')) {
        eligible = true;
      } else if (ch.id.contains('spice_adventure')) {
        eligible = recipe.spiceLevel == 'Medium' || recipe.spiceLevel == 'Spicy' || recipe.spiceLevel.contains('Fiery');
      } else if (ch.id.contains('healthy_choice')) {
        final cal = recipe.nutrition?.calories ?? 450;
        eligible = cal <= 380 || recipe.dietaryTags.any((t) => t.toLowerCase().contains('protein'));
      } else if (ch.id.contains('cuisine_explorer')) {
        eligible = true;
      }

      if (eligible) {
        ch.isCompleted = true;
        ch.progress = 1.0;
        state.chefPoints += ch.rewardPoints;
        state.completedChallengesCount += 1;

        // Challenge champion badge progress
        final chalBadge = state.badges.firstWhere((b) => b.id == 'challenge_champion', orElse: () => state.badges.first);
        if (!chalBadge.isUnlocked) {
          chalBadge.currentProgress = state.completedChallengesCount;
          if (chalBadge.currentProgress >= chalBadge.maxProgress) {
            chalBadge.isUnlocked = true;
            chalBadge.unlockedDate = todayKey;
            state.chefPoints += 150;
            newlyUnlockedBadgeNotifier.value = chalBadge;
          }
        }
      }
    }

    stateNotifier.value = state;
    await _persist();
  }

  Future<void> _persist() async {
    final state = stateNotifier.value;
    if (state == null) return;
    try {
      final map = {
        'currentStreak': state.currentStreak,
        'longestStreak': state.longestStreak,
        'lastCookedDate': state.lastCookedDate,
        'completedDates': state.completedDates.toList(),
        'totalRecipesCooked': state.totalRecipesCooked,
        'chefPoints': state.chefPoints,
        'cookedCuisines': state.cookedCuisines.toList(),
        'completedChallengesCount': state.completedChallengesCount,
        'badges': state.badges.map((b) => b.toJson()).toList(),
        'dailyChallenge': state.dailyChallenge.toJson(),
      };
      await _storage.write(key: _storageKey, value: jsonEncode(map));
    } catch (e) {
      debugPrint('Error saving GamificationState: $e');
    }
  }
}

final gamificationService = GamificationService();
