import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0B3A40);
  static const secondary = Color(0xFF2E8B57);
  static const background = Color(0xFFF5F5F5);
  static const overcolor = Color.fromARGB(88, 0, 0, 0);
  static const textgray = Color.fromARGB(179, 255, 255, 255);
  static const textwhite = Color.fromARGB(255, 255, 255, 255);
  static const searchBarColor = Color.fromARGB(13, 0, 0, 0);
  static const graybg = Color.fromARGB(255, 210, 216, 221);

  static const darkBackground = Color(0xFF081416);
  static const darkSurface = Color(0xFF101B1E);
  static const darkSurfaceElevated = Color(0xFF162326);
  static const darkCard = Color(0xFF142023);
  static const darkBorder = Color(0xFF243437);
  static const darkPrimaryAccent = Color(0xFF73C895);
  static const darkTextPrimary = Color(0xFFEAF0ED);
  static const darkTextSecondary = Color(0xFF9EAEAA);
  static const darkMuted = Color(0xFF6F807C);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color appBackground(BuildContext context) {
    return isDark(context) ? darkBackground : const Color(0xFFF7FAF8);
  }

  static Color surface(BuildContext context) {
    return isDark(context) ? darkSurface : const Color(0xFFF7FAF8);
  }

  static Color elevatedSurface(BuildContext context) {
    return isDark(context) ? darkSurfaceElevated : Colors.white;
  }

  static Color card(BuildContext context) {
    return isDark(context) ? darkCard : Colors.white;
  }

  static Color border(BuildContext context) {
    return isDark(context) ? darkBorder : const Color(0xFFE5EEEA);
  }

  static Color softSurface(BuildContext context) {
    return isDark(context) ? darkSurfaceElevated : const Color(0xFFF2F6F4);
  }

  static Color searchSurface(BuildContext context) {
    return isDark(context) ? darkSurfaceElevated : searchBarColor;
  }

  static Color textPrimary(BuildContext context) {
    return isDark(context) ? darkTextPrimary : primary;
  }

  static Color textSecondary(BuildContext context) {
    return isDark(context) ? darkTextSecondary : const Color(0xFF63777B);
  }

  static Color pageTitle(BuildContext context) {
    return textPrimary(context);
  }

  static Color sectionTitle(BuildContext context) {
    return textSecondary(context);
  }

  static Color cardTitle(BuildContext context) {
    return textPrimary(context);
  }

  static Color bodyText(BuildContext context) {
    return textPrimary(context);
  }

  static Color subtitleText(BuildContext context) {
    return textSecondary(context);
  }

  static Color actionText(BuildContext context) {
    return accent(context);
  }

  static Color iconAccent(BuildContext context) {
    return accent(context);
  }

  static Color muted(BuildContext context) {
    return isDark(context) ? darkMuted : overcolor;
  }

  static Color accent(BuildContext context) {
    return isDark(context) ? darkPrimaryAccent : primary;
  }

  static Color success(BuildContext context) {
    return isDark(context) ? darkPrimaryAccent : secondary;
  }
}
