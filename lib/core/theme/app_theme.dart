import 'package:flutter/material.dart';
import 'package:vendza/core/constants/app_interaction_tokens.dart';
import 'package:vendza/core/constants/colors.dart';

class AppTheme {
  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.background,
      onSurface: AppColors.primary,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.darkPrimaryAccent,
      brightness: Brightness.dark,
      primary: AppColors.darkPrimaryAccent,
      secondary: AppColors.darkPrimaryAccent,
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkTextPrimary,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimaryAccent : AppColors.primary;
    final overlayColor = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.pressed)) {
        return accent.withValues(
          alpha: AppInteractionTokens.pressedOverlayAlpha,
        );
      }
      if (states.contains(WidgetState.hovered)) {
        return accent.withValues(alpha: AppInteractionTokens.hoverOverlayAlpha);
      }
      return null;
    });

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,

      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        fontFamily: "Poppins",
        bodyColor: isDark ? AppColors.darkTextPrimary : AppColors.primary,
        displayColor: isDark ? AppColors.darkTextPrimary : AppColors.primary,
      ),

      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
          animationDuration: AppInteractionTokens.duration,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ).copyWith(overlayColor: overlayColor),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          animationDuration: AppInteractionTokens.duration,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).copyWith(overlayColor: overlayColor),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          animationDuration: AppInteractionTokens.duration,
        ).copyWith(overlayColor: overlayColor),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: accent,
          animationDuration: AppInteractionTokens.duration,
        ).copyWith(overlayColor: overlayColor),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5EEEA),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark
            ? AppColors.darkPrimaryAccent
            : AppColors.primary,
        foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
      ),

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.primary,
        titleTextStyle: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
          fontFamily: "Poppins",
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        selectedItemColor: isDark
            ? AppColors.darkPrimaryAccent
            : AppColors.primary,
        unselectedItemColor: isDark ? AppColors.darkMuted : AppColors.overcolor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        selectedIconTheme: IconThemeData(
          color: isDark ? AppColors.darkPrimaryAccent : AppColors.primary,
        ),
        unselectedIconTheme: IconThemeData(
          color: isDark ? AppColors.darkMuted : AppColors.overcolor,
        ),
        selectedLabelTextStyle: TextStyle(
          color: isDark ? AppColors.darkPrimaryAccent : AppColors.primary,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        unselectedLabelTextStyle: TextStyle(
          color: isDark ? AppColors.darkMuted : AppColors.overcolor,
          fontFamily: 'Poppins',
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.searchBarColor,
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkMuted : Colors.grey.shade600,
        ),
        border: InputBorder.none,
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkBorder : const Color(0xFFE5EEEA),
      ),
    );
  }
}
