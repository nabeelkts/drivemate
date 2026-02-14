import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mds/constants/colors.dart';

/// Controls app-wide theme color and dark mode. Persists to GetStorage and notifies the app to rebuild.
class ThemeController extends GetxController {
  final GetStorage _box = GetStorage();
  static const String _themeColorKey = 'themeColor';
  static const String _isDarkModeKey = 'isDarkMode';

  final RxInt themeColorValue = (kPrimaryColor.value).obs;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeColor();
    _loadThemeMode();
  }

  void _loadThemeColor() {
    final stored = _box.read(_themeColorKey);
    if (stored != null) {
      themeColorValue.value = stored as int;
    }
  }

  void _loadThemeMode() {
    final isDark = _box.read(_isDarkModeKey);
    if (isDark == true) {
      themeMode.value = ThemeMode.dark;
    } else if (isDark == false) {
      themeMode.value = ThemeMode.light;
    }
  }

  Color get themeColor => Color(themeColorValue.value);

  /// Call this when the user picks a new theme color (e.g. from profile).
  void setThemeColor(Color color) {
    themeColorValue.value = color.value;
    _box.write(_themeColorKey, color.value);
  }

  /// Call this when the user toggles dark mode (e.g. from profile).
  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    _box.write(_isDarkModeKey, mode == ThemeMode.dark);
  }
}
