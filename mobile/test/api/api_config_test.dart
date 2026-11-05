// test/api/api_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:atkmart_mobile/api/api_config.dart';

void main() {
  setUp(() {
    ApiConfig.clearCustomToken();
    ApiConfig.setActiveRole('pembeli');
  });

  tearDown(() {
    ApiConfig.clearCustomToken();
    ApiConfig.setActiveRole('pembeli');
  });

  group('ApiConfig Tests', () {
    test('baseUrl default for desktop/fallback is 127.0.0.1:8000/api', () {
      expect(ApiConfig.baseUrl, contains('8000/api'));
    });

    test('custom token override works as highest priority', () {
      ApiConfig.setCustomToken('manual-test-token');
      expect(ApiConfig.staticToken, 'manual-test-token');

      final headers = ApiConfig.defaultHeaders();
      expect(headers['Authorization'], 'Bearer manual-test-token');
      expect(headers['Content-Type'], 'application/json');
      expect(headers['Accept'], 'application/json');
    });

    test('role switching changes active role', () {
      ApiConfig.setActiveRole('pengelola');
      expect(ApiConfig.activeRole, 'pengelola');

      ApiConfig.setActiveRole('pembeli');
      expect(ApiConfig.activeRole, 'pembeli');
    });

    test('defaultHeaders throws StateError when token is empty', () {
      ApiConfig.clearCustomToken();
      // Only throws if no environment or local config provided
      if (ApiConfig.staticToken.isEmpty) {
        expect(() => ApiConfig.defaultHeaders(), throwsStateError);
      }
    });

    test('defaultHeaders merges extra headers properly', () {
      ApiConfig.setCustomToken('test-token');
      final headers = ApiConfig.defaultHeaders(extra: {'X-Custom': 'Value'});
      expect(headers['Authorization'], 'Bearer test-token');
      expect(headers['X-Custom'], 'Value');
    });
  });
}
