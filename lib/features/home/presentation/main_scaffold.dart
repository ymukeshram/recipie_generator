import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rasoiai/core/theme/app_colors.dart';

/// Phone-tailored bottom bar with dedicated direct-access Camera Snap action.
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/generate/photo')) return 2;
    if (location.startsWith('/generate')) return 1;
    if (location.startsWith('/profile')) return 3;
    if (location.startsWith('/saved')) return 4;
    if (location.startsWith('/home') || location.startsWith('/recipe')) return 0;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/generate'); // Text generation form
        break;
      case 2:
        context.go('/generate/photo'); // Direct Camera Snap screen
        break;
      case 3:
        context.go('/profile'); // User Profile & Gamification
        break;
      case 4:
        context.go('/saved'); // Saved & favorites
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          border: Border(
            top: BorderSide(color: AppColors.cardBorder(context), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTab(
                  context: context,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: selectedIndex == 0,
                  onTap: () => _onItemTapped(0, context),
                ),
                _buildTab(
                  context: context,
                  icon: Icons.edit_note_outlined,
                  activeIcon: Icons.edit_note_rounded,
                  label: 'Generate',
                  isSelected: selectedIndex == 1,
                  onTap: () => _onItemTapped(1, context),
                ),

                // Dedicated Direct Camera Snap Action
                _buildCameraTab(
                  context: context,
                  isSelected: selectedIndex == 2,
                  onTap: () => _onItemTapped(2, context),
                ),

                _buildTab(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: selectedIndex == 3,
                  onTap: () => _onItemTapped(3, context),
                ),
                _buildTab(
                  context: context,
                  icon: Icons.bookmark_border_rounded,
                  activeIcon: Icons.bookmark_rounded,
                  label: 'Saved',
                  isSelected: selectedIndex == 4,
                  onTap: () => _onItemTapped(4, context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? AppColors.text(context) : AppColors.subtext(context),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.text(context) : AppColors.subtext(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraTab({
    required BuildContext context,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.accent : AppColors.textPrimary)
                    : (isDark ? const Color(0xFF262A32) : AppColors.surfaceSubtle),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.photo_camera_outlined,
                size: 20,
                color: isSelected ? Colors.white : AppColors.text(context),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Snap',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.text(context) : AppColors.subtext(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
