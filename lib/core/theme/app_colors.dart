import 'package:flutter/material.dart';

/// Base Light Palette Constants
class AppColors {
  // Canvas & Surfaces
  static const Color background = Color(0xFFF9F8F6);       // Soft warm linen white
  static const Color surface = Color(0xFFFFFFFF);          // Crisp pure card surface
  static const Color surfaceSubtle = Color(0xFFF3F1EC);    // Gentle tinted background for pills/inputs

  // Borders & Dividers
  static const Color border = Color(0xFFE8E5DF);           // Ultra-soft card outline
  static const Color divider = Color(0xFFECEAE4);          // Minimal line divider

  // Typography
  static const Color textPrimary = Color(0xFF1E2022);      // Soft dark charcoal
  static const Color textSecondary = Color(0xFF6B7280);    // Calm slate gray for secondary info
  static const Color textTertiary = Color(0xFF9CA3AF);     // Light caption gray

  // Refined Subtle Accents
  static const Color accent = Color(0xFF2D6A4F);            // Muted culinary sage
  static const Color accentLight = Color(0xFFEDF4F0);       // Soft pastel sage tint
  static const Color snapAccent = Color(0xFF4A5568);        // Calm slate for photo snap CTA
  static const Color snapAccentLight = Color(0xFFF1F3F5);   // Slate highlight tint

  static const Color tagBg = Color(0xFFF2EFE9);             // Neutral warm pill background
  static const Color tagText = Color(0xFF4A4E54);           // Neutral pill text

  // Backward-compatible aliases for existing screens
  static const Color pureWhite = surface;
  static const Color creamWhite = background;
  static const Color backgroundLight = background;
  static const Color cardSurface = surface;
  static const Color deepTealGreen = accent;
  static const Color primaryOrange = accent;
  static const Color primaryOrangeDark = accent;
  static const Color primaryOrangeLight = accentLight;
  static const Color terracotta = accent;
  static const Color terracottaDark = accent;
  static const Color terracottaLight = accentLight;
  static const Color warmIvory = background;
  static const Color textBlack = textPrimary;
  static const Color darkCharcoal = textPrimary;
  static const Color textMuted = textSecondary;
  static const Color neutralGray = textSecondary;
  static const Color borderLight = border;
  static const Color dividerGray = divider;
  static const Color activeCoral = accent;
  static const Color softBlueGray = textSecondary;
  static const Color activeIconCircle = accentLight;
  static const Color greenSuccess = accent;
  static const Color amberGold = Color(0xFFB48A3C);
  static const Color errorRed = Color(0xFFC0392B);
  static const Color successGreen = accent;
  static const Color cardamomSage = accent;
  static const Color cardamomLight = accentLight;
  static const Color saffronGold = Color(0xFFB48A3C);
  static const Color saffronGoldLight = Color(0xFFFAF6EB);
  static const Color saffronLight = Color(0xFFFAF6EB);
  static const Color scanDark = Color(0xFF1E2022);
  static const Color scanCardDark = Color(0xFF2C2F33);
  static const Color calorieFire = Color(0xFFD97736);
  static const Color carbYellow = Color(0xFFB48A3C);
  static const Color fatPurple = Color(0xFF6B7280);

  // Dynamic Theme Helpers
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? DarkColors.background : background;
  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? DarkColors.surface : surface;
  static Color subtleBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? DarkColors.surfaceSubtle : surfaceSubtle;
  static Color cardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? DarkColors.border : border;
  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? DarkColors.textPrimary : textPrimary;
  static Color subtext(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? DarkColors.textSecondary : textSecondary;
}

/// Dark Theme Palette Constants
class DarkColors {
  static const Color background = Color(0xFF111315);
  static const Color surface = Color(0xFF1C1F24);
  static const Color surfaceSubtle = Color(0xFF252930);
  static const Color border = Color(0xFF2E333C);
  static const Color divider = Color(0xFF282D36);
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color tagBg = Color(0xFF262B32);
  static const Color tagText = Color(0xFFE2E8F0);
}
