import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/core/networking/api_client.dart';
import 'package:rasoiai/core/services/user_session.dart';
import 'package:rasoiai/core/services/theme_service.dart';
import 'package:rasoiai/core/services/gamification_service.dart';
import 'package:rasoiai/features/profile/presentation/widgets/gamification_widgets.dart';
import 'package:rasoiai/shared/widgets/theme_toggle_button.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _storage = FlutterSecureStorage();

  String _dietaryPreference = 'Vegetarian';
  String _spiceTolerance = 'Medium';
  int _typicalCookingTime = 40;
  int _budgetPerMeal = 200;

  final List<String> _allergies = ['Peanuts', 'Dairy', 'Gluten', 'Mustard', 'Soy', 'Shellfish'];
  final Set<String> _selectedAllergies = {'Mustard'};

  final List<String> _preferredCuisines = [
    'North Indian',
    'South Indian',
    'Punjabi',
    'Gujarati',
    'Maharashtrian',
    'Bengali',
  ];
  final Set<String> _selectedCuisines = {'North Indian', 'South Indian'};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    gamificationService.newlyUnlockedBadgeNotifier.addListener(_onBadgeUnlocked);
    gamificationService.streakCelebrationNotifier.addListener(_onStreakCelebration);
  }

  @override
  void dispose() {
    gamificationService.newlyUnlockedBadgeNotifier.removeListener(_onBadgeUnlocked);
    gamificationService.streakCelebrationNotifier.removeListener(_onStreakCelebration);
    super.dispose();
  }

  void _onBadgeUnlocked() {
    final badge = gamificationService.newlyUnlockedBadgeNotifier.value;
    if (badge == null || !mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉 BADGE UNLOCKED! 🎉', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFD97706))),
            const SizedBox(height: 14),
            Text(badge.emoji, style: const TextStyle(fontSize: 54)),
            const SizedBox(height: 10),
            Text(badge.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            Text(badge.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(8)),
              child: const Text('+150 Chef Points Earned', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857), fontSize: 12)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.text(context), foregroundColor: Colors.white),
            onPressed: () {
              gamificationService.newlyUnlockedBadgeNotifier.value = null;
              Navigator.pop(ctx);
            },
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  void _onStreakCelebration() {
    final msg = gamificationService.streakCelebrationNotifier.value;
    if (msg == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFE65100),
        behavior: SnackBarBehavior.floating,
      ),
    );
    gamificationService.streakCelebrationNotifier.value = null;
  }

  Future<void> _loadPreferences() async {
    try {
      final savedDiet = await _storage.read(key: 'rasoiai_selected_diet');
      if (savedDiet != null && savedDiet.isNotEmpty) {
        _dietaryPreference = savedDiet;
      }
      final savedCuisines = await _storage.read(key: 'rasoiai_custom_cuisines');
      if (savedCuisines != null && savedCuisines.isNotEmpty) {
        for (var c in savedCuisines.split(',')) {
          final trimmed = c.trim();
          if (trimmed.isNotEmpty && !_preferredCuisines.contains(trimmed)) {
            _preferredCuisines.add(trimmed);
          }
        }
      }
      final savedSelCuisines = await _storage.read(key: 'rasoiai_selected_cuisines');
      if (savedSelCuisines != null && savedSelCuisines.isNotEmpty) {
        _selectedCuisines.clear();
        _selectedCuisines.addAll(savedSelCuisines.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
      }

      final savedAllergies = await _storage.read(key: 'rasoiai_custom_allergies');
      if (savedAllergies != null && savedAllergies.isNotEmpty) {
        for (var a in savedAllergies.split(',')) {
          final trimmed = a.trim();
          if (trimmed.isNotEmpty && !_allergies.contains(trimmed)) {
            _allergies.add(trimmed);
          }
        }
      }
      final savedSelAllergies = await _storage.read(key: 'rasoiai_selected_allergies');
      if (savedSelAllergies != null && savedSelAllergies.isNotEmpty) {
        _selectedAllergies.clear();
        _selectedAllergies.addAll(savedSelAllergies.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _persistPreferences() async {
    try {
      await _storage.write(key: 'rasoiai_selected_diet', value: _dietaryPreference);
      await _storage.write(key: 'rasoiai_custom_cuisines', value: _preferredCuisines.join(','));
      await _storage.write(key: 'rasoiai_selected_cuisines', value: _selectedCuisines.join(','));
      await _storage.write(key: 'rasoiai_custom_allergies', value: _allergies.join(','));
      await _storage.write(key: 'rasoiai_selected_allergies', value: _selectedAllergies.join(','));
    } catch (_) {}
  }

  void _showAddCuisineDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu_rounded, color: AppColors.accent, size: 20),
            SizedBox(width: 8),
            Text('Add Regional Cuisine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter an authentic regional cuisine (e.g. Chettinad, Goan, Awadhi, Kashmiri, Hyderabadi):',
              style: TextStyle(fontSize: 12, color: AppColors.neutralGray),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Chettinad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.soup_kitchen_outlined, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  if (!_preferredCuisines.contains(text)) {
                    _preferredCuisines.add(text);
                  }
                  _selectedCuisines.add(text);
                });
                _persistPreferences();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added and selected "$text" cuisine!'),
                    backgroundColor: AppColors.accent,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddAllergyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 20),
            SizedBox(width: 8),
            Text('Add Allergy / Exclusion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter an ingredient to strictly exclude (e.g. Mushrooms, Cashews, Sesame, Onion/Garlic):',
              style: TextStyle(fontSize: 12, color: AppColors.neutralGray),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Mushrooms',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.block_rounded, size: 20, color: AppColors.errorRed),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed, foregroundColor: Colors.white),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  if (!_allergies.contains(text)) {
                    _allergies.add(text);
                  }
                  _selectedAllergies.add(text);
                });
                _persistPreferences();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added exclusion for "$text"!'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _savePreferences() {
    _persistPreferences();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences saved successfully!'),
        backgroundColor: AppColors.terracotta,
      ),
    );
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: ApiClient.baseUrl);
    bool isTesting = false;
    String? testResult;
    bool? isSuccess;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.settings_ethernet_rounded, color: AppColors.terracotta, size: 22),
              SizedBox(width: 8),
              Text('AI Backend Connection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your laptop IP or Cloud URL:\n• Home Wi-Fi: http://192.168.1.43:8000/api/v1\n• Mobile Hotspot: http://<hotspot-ip>:8000/api/v1\n• Cloud: https://your-server.onrender.com/api/v1',
                style: TextStyle(fontSize: 12, color: AppColors.neutralGray, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'http://192.168.1.43:8000/api/v1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wifi_rounded, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    onPressed: isTesting
                        ? null
                        : () async {
                            setDialogState(() {
                              isTesting = true;
                              testResult = null;
                            });
                            final ok = await apiClient.testConnection(controller.text.trim());
                            setDialogState(() {
                              isTesting = false;
                              isSuccess = ok;
                              testResult = ok ? '✓ Online & Healthy' : '✗ Offline / Unreachable';
                            });
                          },
                    icon: isTesting
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.network_check_rounded, size: 14),
                    label: const Text('Test Connection', style: TextStyle(fontSize: 11)),
                  ),
                  if (testResult != null)
                    Text(
                      testResult!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSuccess == true ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final target = controller.text.trim();
                if (target.isNotEmpty) {
                  await apiClient.updateServerUrl(target);
                  if (mounted) setState(() {});
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Server connected: ${ApiClient.baseUrl}'),
                      backgroundColor: AppColors.terracotta,
                    ),
                  );
                }
              },
              child: const Text('Save & Connect'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditChefDialog() {
    final nameController = TextEditingController(text: UserSession.userName);
    final emailController = TextEditingController(text: UserSession.userEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_outlined, color: AppColors.terracotta, size: 20),
            SizedBox(width: 8),
            Text('Edit Chef Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Chef Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();
              if (newName.isNotEmpty) {
                await UserSession.setSession(
                  name: newName,
                  email: newEmail.isNotEmpty ? newEmail : UserSession.userEmail,
                );
                if (mounted) setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chef profile updated!'),
                    backgroundColor: AppColors.terracotta,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          'Profile & Preferences',
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: Icon(Icons.history, color: AppColors.text(context)),
            tooltip: 'Recipe History',
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chef Profile Section
              Text(
                'Chef',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isDark ? const Color(0xFF1E2E25) : AppColors.accentLight,
                      child: const Text('👨‍🍳', style: TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            UserSession.userName,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.text(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            UserSession.userEmail,
                            style: TextStyle(color: AppColors.subtext(context), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        side: BorderSide(color: AppColors.cardBorder(context)),
                        foregroundColor: AppColors.text(context),
                      ),
                      onPressed: _showEditChefDialog,
                      child: const Text('Edit', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Gamification Section: Cooking Streaks, Daily Challenges, Achievement Badges
              ValueListenableBuilder<GamificationState?>(
                valueListenable: gamificationService.stateNotifier,
                builder: (context, gState, _) {
                  if (gState == null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CookingStreakCard(state: gState),
                      const SizedBox(height: 14),
                      DailyChallengeCard(
                        challenge: gState.dailyChallenge,
                        onAccept: () async {
                          await gamificationService.acceptTodayChallenge();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎯 Challenge Accepted! Cook any qualifying dish today to complete.'),
                                backgroundColor: AppColors.accent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      BadgesGridSection(badges: gState.badges),
                      const SizedBox(height: 14),
                    ],
                  );
                },
              ),

              // Server Connection Setting Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder(context)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_tethering_rounded, color: AppColors.terracotta, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Backend Connection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
                          const SizedBox(height: 1),
                          Text(
                            ApiClient.baseUrl,
                            style: TextStyle(fontSize: 11, color: AppColors.subtext(context)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                      onPressed: _showServerConfigDialog,
                      child: const Text('Change IP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.terracotta)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // App Appearance & Dark Mode Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder(context)),
                ),
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeService.themeModeNotifier,
                  builder: (context, mode, _) {
                    final currentIsDark = mode == ThemeMode.dark;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              currentIsDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: currentIsDark ? const Color(0xFFFBBF24) : AppColors.accent,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
                                const SizedBox(height: 1),
                                Text(
                                  currentIsDark ? 'Dark theme enabled' : 'Clean light theme enabled',
                                  style: TextStyle(fontSize: 11, color: AppColors.subtext(context)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: currentIsDark,
                          activeColor: AppColors.accent,
                          onChanged: (_) => themeService.toggleTheme(),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              Text('Culinary Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
              const SizedBox(height: 4),
              Text(
                'These preferences will automatically configure every AI-generated recipe.',
                style: TextStyle(color: AppColors.subtext(context), fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Diet Preference
              Text('Dietary Choice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['Vegetarian', 'Vegan', 'Eggetarian', 'Non-Vegetarian'].map((diet) {
                  final isSelected = _dietaryPreference == diet;
                  return ChoiceChip(
                    showCheckmark: false,
                    avatar: isSelected
                        ? const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white)
                        : null,
                    label: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(diet),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.cardBg(context),
                    side: BorderSide(
                      color: isSelected ? AppColors.accent : AppColors.cardBorder(context),
                      width: 1,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (val) {
                      setState(() => _dietaryPreference = diet);
                      _storage.write(key: 'rasoiai_selected_diet', value: diet);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Preferred Cuisines
              Text('Preferred Regional Cuisines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._preferredCuisines.map((c) {
                    final isSelected = _selectedCuisines.contains(c);
                    return FilterChip(
                      showCheckmark: false,
                      avatar: isSelected
                          ? const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white)
                          : null,
                      label: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(c),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.accent,
                      backgroundColor: AppColors.cardBg(context),
                      side: BorderSide(
                        color: isSelected ? AppColors.accent : AppColors.cardBorder(context),
                        width: 1,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.text(context),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedCuisines.add(c);
                          } else {
                            _selectedCuisines.remove(c);
                          }
                        });
                        _persistPreferences();
                      },
                    );
                  }),
                  ActionChip(
                    avatar: Icon(Icons.add, size: 16, color: isDark ? const Color(0xFF6EE7B7) : AppColors.accent),
                    label: Text(
                      'Add',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF6EE7B7) : AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    backgroundColor: isDark ? const Color(0xFF1B382B) : AppColors.accentLight,
                    side: BorderSide(color: isDark ? const Color(0xFF2D6A4F) : AppColors.accent, width: 1),
                    onPressed: _showAddCuisineDialog,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Food Allergies & Exclusions
              Text(
                'Allergies & Exclusions (Strict Exclusion)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? const Color(0xFFF87171) : AppColors.errorRed,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._allergies.map((all) {
                    final isSelected = _selectedAllergies.contains(all);
                    return FilterChip(
                      showCheckmark: false,
                      avatar: isSelected
                          ? Icon(Icons.cancel_rounded, size: 16, color: isDark ? Colors.white : AppColors.errorRed)
                          : null,
                      label: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(all),
                      ),
                      selected: isSelected,
                      selectedColor: isDark ? const Color(0xFF5C1D1D) : Colors.red.shade100,
                      backgroundColor: AppColors.cardBg(context),
                      side: BorderSide(
                        color: isSelected ? AppColors.errorRed : AppColors.cardBorder(context),
                        width: 1,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? (isDark ? Colors.white : AppColors.errorRed) : AppColors.text(context),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedAllergies.add(all);
                          } else {
                            _selectedAllergies.remove(all);
                          }
                        });
                        _persistPreferences();
                      },
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16, color: AppColors.errorRed),
                    label: const Text('Add', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold, fontSize: 13)),
                    backgroundColor: isDark ? const Color(0xFF3B1212) : const Color(0xFFFFEBEE),
                    side: const BorderSide(color: AppColors.errorRed, width: 1),
                    onPressed: _showAddAllergyDialog,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Spice & Time Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Spice Tolerance', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  DropdownButton<String>(
                    value: _spiceTolerance,
                    dropdownColor: AppColors.cardBg(context),
                    style: TextStyle(color: AppColors.text(context), fontSize: 14),
                    items: ['Mild', 'Medium', 'Spicy', 'Extra Spicy']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => _spiceTolerance = val!),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text('Typical Cooking Time: $_typicalCookingTime mins', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
              Slider(
                value: _typicalCookingTime.toDouble(),
                min: 15,
                max: 90,
                divisions: 5,
                activeColor: AppColors.accent,
                label: '$_typicalCookingTime mins',
                onChanged: (v) => setState(() => _typicalCookingTime = v.toInt()),
              ),

              Text('Target Budget Per Meal: ₹$_budgetPerMeal', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
              Slider(
                value: _budgetPerMeal.toDouble(),
                min: 50,
                max: 500,
                divisions: 9,
                activeColor: AppColors.saffronGold,
                label: '₹$_budgetPerMeal',
                onChanged: (v) => setState(() => _budgetPerMeal = v.toInt()),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Culinary Preferences'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: AppColors.errorRed),
                label: const Text('Sign Out', style: TextStyle(color: AppColors.errorRed)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.errorRed)),
                onPressed: () => context.go('/login'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

