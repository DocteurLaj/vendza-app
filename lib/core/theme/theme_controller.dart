import 'package:flutter/material.dart';

class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system);

  void setMode(ThemeMode mode) {
    if (value == mode) return;
    value = mode;
  }
}

final ThemeModeController themeModeController = ThemeModeController();

String themeModeLabel(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => "Systeme",
    ThemeMode.light => "Clair",
    ThemeMode.dark => "Sombre",
  };
}
