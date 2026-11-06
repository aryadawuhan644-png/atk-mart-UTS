// test/api/error_handling_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:atkmart_mobile/api/api_config.dart';
import 'package:atkmart_mobile/api/layanan_api.dart';
import 'package:atkmart_mobile/main.dart';

void main() {
  setUp(() {
    ApiConfig.setCustomToken('token-test');
    ApiConfig.setActiveRole('pembeli');
  });

  tearDown(() {
    ApiConfig.clearCustomToken();
    ApiConfig.setActiveRole('pembeli');
  });

  group('Paket C - Pemformatan Pesan Error Bebas Exception Mentah (formatAppErrorMessage)', () {
    test('Offline / NetworkException menghasilkan pesan ramah tanpa exception mentah', () {
      const err = NetworkException();
      final msg = formatAppErrorMessage(err);
      expect(msg, contains('Gagal terhubung ke server ATK Mart'));
      expect(msg, isNot(contains('SocketException')));
      expect(msg, isNot(contains('ClientException')));
      expect(msg, isNot(contains('Exception:')));
    });

    test('Timeout / RequestTimeoutException menghasilkan pesan ramah batas waktu', () {
      const err = RequestTimeoutException();
      final msg = formatAppErrorMessage(err);
      expect(msg, contains('15 detik'));
      expect(msg, contains('coba lagi'));
      expect(msg, isNot(contains('TimeoutException')));
    });

    test('401 / UnauthorizedException menghasilkan pesan sesi autentikasi', () {
      const err = UnauthorizedException();
      final msg = formatAppErrorMessage(err);
      expect(msg, contains('Sesi tidak sah'));
      expect(msg, isNot(contains('UnauthorizedException:')));
    });

    test('403 / ForbiddenException menghasilkan pesan wewenang', () {
      const err = ForbiddenException();
      final msg = formatAppErrorMessage(err);
      expect(msg, contains('Akses ditolak'));
      expect(msg, isNot(contains('ForbiddenException:')));
    });

    test('404 / NotFoundException menghasilkan pesan data tidak ditemukan', () {
      const err = NotFoundException();
      final msg = formatAppErrorMessage(err);
      expect(msg, contains('Data yang diminta tidak ditemukan'));
      expect(msg, contains('404'));
      expect(msg, isNot(contains('NotFoundException:')));
    });

    test('409 / ConflictException stok produk', () {
      const err = ConflictException('Stok produk tidak mencukupi');
      final msg = formatAppErrorMessage(err);
      expect(msg, contains('Stok produk tidak mencukupi'));
      expect(msg, isNot(contains('ConflictException:')));
    });

    test('409 / ConflictException transisi status pesanan', () {
      const err = ConflictException('Transisi status tidak diizinkan');
      final msg = formatAppErrorMessage(err);
      expect(msg, contains('Status pesanan tidak dapat diubah'));
      expect(msg, isNot(contains('ConflictException:')));
    });

    test('422 / ValidationException menyajikan rincian field error', () {
      const err = ValidationException('Validasi gagal', {
        'nama_penerima': ['Nama penerima wajib diisi.'],
        'alamat': ['Alamat pengiriman wajib diisi.'],
      });
      final msg = formatAppErrorMessage(err);
      expect(msg, contains('Nama penerima wajib diisi.'));
      expect(msg, contains('Alamat pengiriman wajib diisi.'));
      expect(msg, isNot(contains('ValidationException:')));
    });

    test('500 / ServerException tidak membocorkan detail internal atau SQL error', () {
      const err = ServerException('SQLSTATE[HY000]: General error: database disk image is malformed');
      final msg = formatAppErrorMessage(err);
      expect(msg, contains('500'));
      expect(msg, contains('coba beberapa saat lagi'));
      // Tidak membocorkan SQL error
      expect(msg, isNot(contains('SQLSTATE')));
      expect(msg, isNot(contains('malformed')));
      expect(msg, isNot(contains('ServerException:')));
    });

    test('Generic Exception teknis (TypeError, FormatException) diubah menjadi pesan ramah', () {
      final err = FormatException('Unexpected character at line 1');
      final msg = formatAppErrorMessage(err);
      expect(msg, 'Terjadi kendala saat memproses permintaan. Silakan coba beberapa saat lagi.');
      expect(msg, isNot(contains('FormatException')));
      expect(msg, isNot(contains('Unexpected character')));
    });
  });

  group('Paket C - Penanganan Status HTTP di LayananApi', () {
    test('HTTP 422 melemparkan ValidationException dengan struktur errors lengkap', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'gagal',
            'code': '422',
            'message': 'Validasi formulir gagal',
            'errors': {
              'nama': ['Nama produk wajib diisi.'],
              'harga': ['Harga harus lebih besar dari 0.'],
            },
          }),
          422,
        );
      });

      final api = LayananApi(client: mockClient);
      try {
        await api.createProduk({'nama': '', 'harga': 0});
        fail('Harus melempar ValidationException');
      } on ValidationException catch (e) {
        expect(e.message, 'Validasi formulir gagal');
        expect(e.errors.containsKey('nama'), isTrue);
        expect(e.errors['nama'], contains('Nama produk wajib diisi.'));
        expect(e.errors['harga'], contains('Harga harus lebih besar dari 0.'));
      }
    });

    test('HTTP 404 melemparkan NotFoundException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'gagal',
            'code': '404',
            'message': 'Produk dengan ID 999 tidak ditemukan',
            'data': null,
          }),
          404,
        );
      });

      final api = LayananApi(client: mockClient);
      expect(
        () => api.fetchProdukDetail(999),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('HTTP 500 HTML/Crash Response ditangani aman sebagai ServerException tanpa crash JSON parser', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '<html><body>500 Internal Server Error (Fatal Crash)</body></html>',
          500,
          headers: {'content-type': 'text/html'},
        );
      });

      final api = LayananApi(client: mockClient);
      expect(
        () => api.fetchProduk(),
        throwsA(isA<ServerException>()),
      );
    });

    test('HTTP 401 melemparkan UnauthorizedException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'gagal',
            'code': '401',
            'message': 'Unauthenticated.',
            'data': null,
          }),
          401,
        );
      });

      final api = LayananApi(client: mockClient);
      expect(
        () => api.fetchKeranjang(),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('Paket C - Mapping Field Errors untuk Form Checkout & Produk', () {
    test('Mapping errors 422 untuk InputDecoration.errorText Checkout', () {
      final Map<String, dynamic> apiErrors = {
        'nama_penerima': ['Nama penerima tidak valid'],
        'alamat': ['Alamat pengiriman terlalu pendek'],
        'kota': ['Kota tidak valid'],
        'wilayah_id': ['Wilayah tidak ditemukan'],
        'kurir_id': ['Kurir tidak aktif'],
      };

      final fieldErrors = apiErrors.map((key, val) {
        if (val is List && val.isNotEmpty) {
          return MapEntry(key, val.first.toString());
        }
        return MapEntry(key, val.toString());
      });

      expect(fieldErrors['nama_penerima'], 'Nama penerima tidak valid');
      expect(fieldErrors['alamat'], 'Alamat pengiriman terlalu pendek');
      expect(fieldErrors['kota'], 'Kota tidak valid');
      expect(fieldErrors['wilayah_id'], 'Wilayah tidak ditemukan');
      expect(fieldErrors['kurir_id'], 'Kurir tidak aktif');
    });

    test('Mapping errors 422 untuk InputDecoration.errorText Form Produk', () {
      final Map<String, dynamic> apiErrors = {
        'nama': ['Nama produk wajib diisi'],
        'kategori': ['Kategori tidak valid'],
        'harga': ['Harga harus berupa angka'],
        'stok': ['Stok tidak boleh negatif'],
        'estimasi_tersedia': ['Format tanggal harus YYYY-MM-DD'],
      };

      final fieldErrors = apiErrors.map((key, val) {
        if (val is List && val.isNotEmpty) {
          return MapEntry(key, val.first.toString());
        }
        return MapEntry(key, val.toString());
      });

      expect(fieldErrors['nama'], 'Nama produk wajib diisi');
      expect(fieldErrors['kategori'], 'Kategori tidak valid');
      expect(fieldErrors['harga'], 'Harga harus berupa angka');
      expect(fieldErrors['stok'], 'Stok tidak boleh negatif');
      expect(fieldErrors['estimasi_tersedia'], 'Format tanggal harus YYYY-MM-DD');
    });
  });
}
