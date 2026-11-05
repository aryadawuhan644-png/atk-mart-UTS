// lib/api/api_config.dart
// Configuration for API base URL and static token.
// Values are injected at build/run time via --dart-define.
// No fallback values are provided – the app must be started with proper definitions.

import 'package:flutter/foundation.dart';

class ApiConfig {
  // Example launch commands:
  // flutter run -d chrome --dart-define=API_BASE_URL=https://example.com/api --dart-define=STATIC_TOKEN=your-token
  // flutter run -d android --dart-define=STATIC_TOKEN=your-token   (base URL defaults to Android emulator)

  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String staticToken = String.fromEnvironment(
    'STATIC_TOKEN',
    defaultValue: '',
  );

  /// Resolve base URL based on environment variables and platform.
  static String get baseUrl {
    if (_rawBaseUrl.isNotEmpty) return _rawBaseUrl;
    // Platform‑specific defaults when no env var is provided.
    if (kIsWeb) {
      return 'http://localhost:8000/api'; // Web dev server
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator accesses host machine via 10.0.2.2
        return 'http://10.0.2.2:8000/api';
      case TargetPlatform.windows:
        return 'http://127.0.0.1:8000/api';
      default:
        // Fallback for other platforms (iOS, macOS, Linux)
        return 'http://127.0.0.1:8000/api';
    }
  }

  /// Base headers used for all requests.
  /// Extra headers can be merged via the [extra] map.
  static Map<String, String> defaultHeaders({Map<String, String>? extra}) {
    if (staticToken.isEmpty) {
      // Throw early so developers notice missing token configuration.
      throw StateError('STATIC_TOKEN not provided via --dart-define');
    }
    return {
      'Authorization': 'Bearer $staticToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?extra,
    };
  }
}
