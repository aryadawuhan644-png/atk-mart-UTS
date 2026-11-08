// test/api/login_demo_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:atkmart_mobile/api/api_config.dart';
import 'package:atkmart_mobile/api/layanan_api.dart';
import 'package:atkmart_mobile/main.dart';

void main() {
  setUp(() {
    SessionPengguna.logout();
  });

  tearDown(() {
    SessionPengguna.logout();
  });

  group('Fitur Login Demo - Manajemen Sesi & Akun', () {
    test('Kondisi awal sebelum login: belum ada akun aktif', () {
      expect(SessionPengguna.isLoggedIn, isFalse);
      expect(SessionPengguna.currentAccount, isNull);
      expect(SessionPengguna.isPengelola, isFalse);
    });

    test('Login Pembeli 1: Mengatur token statis pembeli 1 dan role pembeli', () {
      SessionPengguna.login(DemoAccount.pembeli1);

      expect(SessionPengguna.isLoggedIn, isTrue);
      expect(SessionPengguna.currentAccount?.id, 'pembeli_1');
      expect(SessionPengguna.currentAccount?.nama, 'Pembeli 1');
      expect(SessionPengguna.isPengelola, isFalse);
      expect(ApiConfig.staticToken, 'token-pembeli-atk-mart-2026');
      expect(ApiConfig.activeRole, 'pembeli');

      final headers = ApiConfig.defaultHeaders();
      expect(headers['Authorization'], 'Bearer token-pembeli-atk-mart-2026');
    });

    test('Login Pembeli 2: Mengatur token statis pembeli 2 dan role pembeli', () {
      SessionPengguna.login(DemoAccount.pembeli2);

      expect(SessionPengguna.isLoggedIn, isTrue);
      expect(SessionPengguna.currentAccount?.id, 'pembeli_2');
      expect(SessionPengguna.currentAccount?.nama, 'Pembeli 2');
      expect(SessionPengguna.isPengelola, isFalse);
      expect(ApiConfig.staticToken, 'token-pembeli-2-atk-mart-2026');
      expect(ApiConfig.activeRole, 'pembeli');

      final headers = ApiConfig.defaultHeaders();
      expect(headers['Authorization'], 'Bearer token-pembeli-2-atk-mart-2026');
    });

    test('Logout: Membersihkan sesi dan token akun sebelumnya', () {
      // 1. Login Pembeli 2
      SessionPengguna.login(DemoAccount.pembeli2);
      expect(ApiConfig.staticToken, 'token-pembeli-2-atk-mart-2026');

      // 2. Logout
      SessionPengguna.logout();
      expect(SessionPengguna.isLoggedIn, isFalse);
      expect(SessionPengguna.currentAccount, isNull);
      expect(SessionPengguna.isPengelola, isFalse);

      // Token override kustom telah dihapus
      expect(ApiConfig.staticToken, isNot('token-pembeli-2-atk-mart-2026'));
    });

    test('Peralihan antar akun: Token berganti sempurna tanpa tertukar', () {
      // Login Pembeli 1
      SessionPengguna.login(DemoAccount.pembeli1);
      expect(ApiConfig.defaultHeaders()['Authorization'],
          'Bearer token-pembeli-atk-mart-2026');

      // Beralih ke Pembeli 2
      SessionPengguna.login(DemoAccount.pembeli2);
      expect(ApiConfig.defaultHeaders()['Authorization'],
          'Bearer token-pembeli-2-atk-mart-2026');

      // Beralih ke Pengelola
      SessionPengguna.login(DemoAccount.pengelola);
      expect(SessionPengguna.isPengelola, isTrue);
      expect(ApiConfig.defaultHeaders()['Authorization'],
          'Bearer token-pengelola-atk-mart-2026');
    });

    test('AlamatTersimpan ter-reset saat ganti akun atau logout', () {
      AlamatTersimpan.nama = 'Nama Pembeli 1';
      AlamatTersimpan.alamat = 'Jl. Mawar No. 1';
      AlamatTersimpan.kota = 'Kota Malang';

      SessionPengguna.login(DemoAccount.pembeli2);
      expect(AlamatTersimpan.nama, isNull);
      expect(AlamatTersimpan.alamat, isNull);
      expect(AlamatTersimpan.kota, isNull);
    });
  });

  group('Fitur Login Demo - Isolasi Request API LayananApi', () {
    test('Keranjang Pembeli 1 mengirim Authorization header Pembeli 1', () async {
      SessionPengguna.login(DemoAccount.pembeli1);

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/keranjang');
        expect(request.headers['Authorization'],
            'Bearer token-pembeli-atk-mart-2026');

        return http.Response(
          jsonEncode({
            'status': 'sukses',
            'code': '200',
            'message': 'Data keranjang Pembeli 1',
            'data': {'items': [], 'subtotal': 0},
          }),
          200,
        );
      });

      final api = LayananApi(client: mockClient);
      final res = await api.fetchKeranjang();
      expect(res.subtotal, 0);
    });

    test('Keranjang Pembeli 2 mengirim Authorization header Pembeli 2', () async {
      SessionPengguna.login(DemoAccount.pembeli2);

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/keranjang');
        expect(request.headers['Authorization'],
            'Bearer token-pembeli-2-atk-mart-2026');

        return http.Response(
          jsonEncode({
            'status': 'sukses',
            'code': '200',
            'message': 'Data keranjang Pembeli 2',
            'data': {'items': [], 'subtotal': 0},
          }),
          200,
        );
      });

      final api = LayananApi(client: mockClient);
      final res = await api.fetchKeranjang();
      expect(res.subtotal, 0);
    });

    test('Riwayat Pesanan Pembeli 1 mengirim Authorization header Pembeli 1', () async {
      SessionPengguna.login(DemoAccount.pembeli1);

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/pesanan');
        expect(request.headers['Authorization'],
            'Bearer token-pembeli-atk-mart-2026');

        return http.Response(
          jsonEncode({
            'status': 'sukses',
            'code': '200',
            'message': 'Riwayat pesanan Pembeli 1',
            'data': [],
          }),
          200,
        );
      });

      final api = LayananApi(client: mockClient);
      final orders = await api.fetchPesanan();
      expect(orders, isEmpty);
    });

    test('Riwayat Pesanan Pembeli 2 mengirim Authorization header Pembeli 2', () async {
      SessionPengguna.login(DemoAccount.pembeli2);

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/pesanan');
        expect(request.headers['Authorization'],
            'Bearer token-pembeli-2-atk-mart-2026');

        return http.Response(
          jsonEncode({
            'status': 'sukses',
            'code': '200',
            'message': 'Riwayat pesanan Pembeli 2',
            'data': [],
          }),
          200,
        );
      });

      final api = LayananApi(client: mockClient);
      final orders = await api.fetchPesanan();
      expect(orders, isEmpty);
    });
  });
}
