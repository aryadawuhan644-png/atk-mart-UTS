import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminPreferences {
  static const _themeModeKey = 'admin_theme_mode';
  static const _notificationsKey = 'admin_notifications_enabled';
  static const _profileNameKey = 'admin_profile_name';
  static const _profileImageKey = 'admin_profile_image';

  static SharedPreferences? _preferences;
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.light,
  );
  static bool _notificationsEnabled = true;

  static Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    themeMode.value = _preferences?.getString(_themeModeKey) == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
    _notificationsEnabled = _preferences?.getBool(_notificationsKey) ?? true;
  }

  static bool get notificationsEnabled => _notificationsEnabled;
  static String? get profileName => _preferences?.getString(_profileNameKey);
  static Uint8List? get profileImage {
    final image = _preferences?.getString(_profileImageKey);
    return image == null || image.isEmpty ? null : base64Decode(image);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    await _preferences?.setString(
      _themeModeKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
    themeMode.value = mode;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _preferences?.setBool(_notificationsKey, enabled);
    _notificationsEnabled = enabled;
  }

  static Future<void> saveProfile({
    required String name,
    required Uint8List? image,
  }) async {
    if (_preferences != null) {
      await _preferences!.setString(_profileNameKey, name);
      if (image == null) {
        await _preferences!.remove(_profileImageKey);
      } else {
        await _preferences!.setString(_profileImageKey, base64Encode(image));
      }
    }
  }
}
