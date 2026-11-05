// lib/api/api_config.dart
// Konfigurasi API Base URL dan Token Autentikasi.
// Mendukung runtime injection via --dart-define serta pembacaan konfigurasi lokal
// dari assets/config/env.json (yang di-ignore oleh Git) untuk kemudahan development.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ApiConfig {
  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _envStaticToken = String.fromEnvironment(
    'STATIC_TOKEN',
    defaultValue: '',
  );

  static String _localBaseUrl = '';
  static String _tokenPembeli = '';
  static String _tokenPengelola = '';
  static String _activeRole = 'pembeli';
  static String _overrideToken = '';

  /// Inisialisasi konfigurasi lokal dari asset env.json jika tersedia.
  /// Dipanggil saat bootstrap aplikasi di main().
  static Future<void> initLocalConfig() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/config/env.json');
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      _tokenPembeli = (data['token_pembeli'] as String?)?.trim() ?? '';
      _tokenPengelola = (data['token_pengelola'] as String?)?.trim() ?? '';
      _activeRole = (data['active_role'] as String?)?.trim() ?? 'pembeli';
      final baseUrl = (data['api_base_url'] as String?)?.trim() ?? '';
      if (baseUrl.isNotEmpty) {
        _localBaseUrl = baseUrl;
      }
    } catch (_) {
      // File env.json tidak tersedia (misal di CI/CD atau clean clone tanpa file lokal).
    }
  }

  /// Ubah role aktif secara dinamis ('pembeli' atau 'pengelola').
  static void setActiveRole(String role) {
    _activeRole = role;
  }

  /// Ambil role aktif saat ini.
  static String get activeRole => _activeRole;

  /// Atur token kustom secara manual (override sementara).
  static void setCustomToken(String token) {
    _overrideToken = token;
  }

  /// Reset override token.
  static void clearCustomToken() {
    _overrideToken = '';
  }

  /// Token statis aktif:
  /// 1. Override manual (setCustomToken)
  /// 2. Nilai dari --dart-define=STATIC_TOKEN
  /// 3. Token dari assets/config/env.json sesuai activeRole ('pengelola' atau 'pembeli')
  static String get staticToken {
    if (_overrideToken.isNotEmpty) return _overrideToken;
    if (_envStaticToken.isNotEmpty) return _envStaticToken;
    if (_activeRole == 'pengelola' && _tokenPengelola.isNotEmpty) {
      return _tokenPengelola;
    }
    if (_tokenPembeli.isNotEmpty) {
      return _tokenPembeli;
    }
    return '';
  }

  /// Base URL API:
  /// 1. Nilai dari --dart-define=API_BASE_URL
  /// 2. Nilai api_base_url dari assets/config/env.json
  /// 3. Default otomatis per-platform:
  ///    - Chrome/Web: http://127.0.0.1:8000/api
  ///    - Android Emulator: http://10.0.2.2:8000/api
  ///    - Windows/Desktop/lainnya: http://127.0.0.1:8000/api
  static String get baseUrl {
    if (_rawBaseUrl.isNotEmpty) return _rawBaseUrl;
    if (_localBaseUrl.isNotEmpty) return _localBaseUrl;

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
      case TargetPlatform.windows:
      default:
        return 'http://127.0.0.1:8000/api';
    }
  }

  /// Header default untuk seluruh panggilan REST API.
  static Map<String, String> defaultHeaders({Map<String, String>? extra}) {
    final token = staticToken;
    if (token.isEmpty) {
      throw StateError(
        'Token autentikasi belum dikonfigurasi. '
        'Pastikan assets/config/env.json terisi atau gunakan --dart-define=STATIC_TOKEN=...',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?extra,
    };
  }
}
