// test/api/kelola_pesanan_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:atkmart_mobile/api/api_config.dart';
import 'package:atkmart_mobile/api/layanan_api.dart';

void main() {
  setUp(() {
    ApiConfig.setCustomToken('token-pengelola-test');
  });

  tearDown(() {
    ApiConfig.clearCustomToken();
  });

  group('Paket B.1 - LayananApi Pengelola Pesanan', () {
    test('fetchPesananPengelola sends GET /pesanan with pengelola headers', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/pesanan');
        expect(request.headers['Authorization'], 'Bearer token-pengelola-test');

        return http.Response(
          jsonEncode({
            'status': 'sukses',
            'code': '200',
            'message': 'Riwayat pesanan berhasil diambil',
            'data': [
              {
                'id': 101,
                'nomor_pesanan': 'ATK-20261106-00101',
                'status': 'menunggu_konfirmasi',
                'subtotal': 50000,
                'ongkos_kirim': 7000,
                'total': 57000,
                'nama_penerima': 'Budi Santoso',
                'kurir': 'Kurir Toko',
                'wilayah': 'Lowokwaru',
                'metode_pembayaran': 'transfer_manual',
                'jumlah_item': 3,
                'created_at': '2026-11-06 14:00:00',
              }
            ],
          }),
          200,
        );
      });

      final api = LayananApi(client: mockClient);
      final orders = await api.fetchPesananPengelola();

      expect(orders.length, 1);
      expect(orders.first.nomorPesanan, 'ATK-20261106-00101');
      expect(orders.first.status, 'menunggu_konfirmasi');
      expect(orders.first.namaPenerima, 'Budi Santoso');
      expect(orders.first.total, 57000);
    });

    test('fetchPesananDetailPengelola sends GET /pesanan/{id} with pengelola headers', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/pesanan/101');
        expect(request.headers['Authorization'], 'Bearer token-pengelola-test');

        return http.Response(
          jsonEncode({
            'status': 'sukses',
            'code': '200',
            'message': 'Detail pesanan berhasil diambil',
            'data': {
              'id': 101,
              'nomor_pesanan': 'ATK-20261106-00101',
              'status': 'menunggu_konfirmasi',
              'nama_penerima': 'Budi Santoso',
              'alamat': 'Jl. Veteran No. 10',
              'kota': 'Kota Malang',
              'subtotal': 50000,
              'ongkos_kirim': 7000,
              'total': 57000,
              'items': [],
              'riwayat_status': [],
            },
          }),
          200,
        );
      });

      final api = LayananApi(client: mockClient);
      final detail = await api.fetchPesananDetailPengelola(101);

      expect(detail.id, 101);
      expect(detail.nomorPesanan, 'ATK-20261106-00101');
      expect(detail.status, 'menunggu_konfirmasi');
    });

    test('updateStatusPesananPengelola sends PATCH /pesanan/{id}/status with status dibayar', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/pesanan/101/status');
        expect(request.headers['Authorization'], 'Bearer token-pengelola-test');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['status'], 'dibayar');
        expect(body['catatan'], 'Pembayaran dikonfirmasi');

        return http.Response(
          jsonEncode({
            'status': 'sukses',
            'code': '200',
            'message': 'Status pesanan berhasil diperbarui',
            'data': {
              'id': 101,
              'nomor_pesanan': 'ATK-20261106-00101',
              'status': 'dibayar',
              'subtotal': 50000,
              'ongkos_kirim': 7000,
              'total': 57000,
            },
          }),
          200,
        );
      });

      final api = LayananApi(client: mockClient);
      final updated = await api.updateStatusPesananPengelola(
        id: 101,
        status: 'dibayar',
        catatan: 'Pembayaran dikonfirmasi',
      );

      expect(updated.id, 101);
      expect(updated.status, 'dibayar');
    });
  });
}
