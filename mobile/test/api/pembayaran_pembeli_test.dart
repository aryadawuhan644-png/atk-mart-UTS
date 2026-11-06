// test/api/pembayaran_pembeli_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:atkmart_mobile/api/api_config.dart';
import 'package:atkmart_mobile/api/layanan_api.dart';
import 'package:atkmart_mobile/api/models/order.dart';

void main() {
  setUp(() {
    ApiConfig.setCustomToken('token-pembeli-test');
    ApiConfig.setActiveRole('pembeli');
  });

  tearDown(() {
    ApiConfig.clearCustomToken();
    ApiConfig.setActiveRole('pembeli');
  });

  group('Paket B.2 - Regression Test: Order.fromJson Null Safety', () {
    test('Order.fromJson parses actual Laravel PATCH response (status_baru, no subtotal/total)', () {
      // Shape aktual kembalian PesananController::updateStatus:
      // data: {pesanan_id: 101, nomor_pesanan: '...', status_lama: '...', status_baru: '...'}
      // Sebelumnya menyebabkan TypeError: null is not a subtype of type String karena 'status' tidak ada.
      final laravelPatchResponse = {
        'pesanan_id': 101,
        'nomor_pesanan': 'ATK-20261106-00101',
        'status_lama': 'menunggu_pembayaran',
        'status_baru': 'menunggu_konfirmasi',
      };

      final order = Order.fromJson(laravelPatchResponse);
      expect(order.id, 101);
      expect(order.nomorPesanan, 'ATK-20261106-00101');
      expect(order.status, 'menunggu_konfirmasi');
      expect(order.subtotal, 0);
      expect(order.ongkosKirim, 0);
      expect(order.total, 0);
      expect(order.metodePembayaran, isNull);
    });

    test('Order.fromJson handles all null fields gracefully without TypeError', () {
      final minimalJson = {
        'id': 102,
        'nomor_pesanan': null,
        'status': null,
        'subtotal': null,
        'ongkos_kirim': null,
        'total': null,
        'nama_penerima': null,
        'alamat': null,
        'kota': null,
        'kurir': null,
        'wilayah': null,
        'metode_pembayaran': null,
        'jumlah_item': null,
        'created_at': null,
        'items': null,
        'riwayat_status': null,
      };

      final order = Order.fromJson(minimalJson);
      expect(order.id, 102);
      expect(order.nomorPesanan, '');
      expect(order.status, '');
      expect(order.subtotal, 0);
      expect(order.ongkosKirim, 0);
      expect(order.total, 0);
      expect(order.metodePembayaran, isNull);
    });

    test('Order.fromJson resolves metode_pembayaran from Map (detail response) and String (summary)', () {
      // Detail response format (nested Map)
      final detailJson = {
        'id': 103,
        'nomor_pesanan': 'ATK-001',
        'status': 'menunggu_pembayaran',
        'subtotal': 10000,
        'ongkos_kirim': 5000,
        'total': 15000,
        'metode_pembayaran': {
          'id': 2,
          'kode': 'transfer_manual',
          'nama': 'Transfer Bank Manual',
        },
      };

      final orderDetail = Order.fromJson(detailJson);
      expect(orderDetail.metodePembayaran, 'Transfer Bank Manual');

      // Summary response format (String)
      final summaryJson = {
        'id': 104,
        'nomor_pesanan': 'ATK-002',
        'status': 'menunggu_pembayaran',
        'subtotal': 10000,
        'ongkos_kirim': 5000,
        'total': 15000,
        'metode_pembayaran': 'Tunai di Tempat (COD)',
      };

      final orderSummary = Order.fromJson(summaryJson);
      expect(orderSummary.metodePembayaran, 'Tunai di Tempat (COD)');
    });
  });

  group('Paket B.2 - Aturan Visibilitas Tombol "Saya Sudah Bayar"', () {
    bool canShowSayaSudahBayar({
      required bool isPengelola,
      required String status,
      required String? metodePembayaran,
    }) {
      final rawMetode = (metodePembayaran ?? '').toLowerCase();
      final isCod = rawMetode.contains('cod') || rawMetode.contains('tunai');
      final isTransfer = !isCod &&
          (rawMetode.contains('transfer') ||
              rawMetode.contains('manual') ||
              rawMetode.contains('bank'));

      return !isPengelola && status == 'menunggu_pembayaran' && isTransfer;
    }

    test('TAMPIL untuk pembeli, status menunggu_pembayaran, dan metode transfer manual', () {
      expect(
        canShowSayaSudahBayar(
          isPengelola: false,
          status: 'menunggu_pembayaran',
          metodePembayaran: 'Transfer Bank Manual',
        ),
        isTrue,
      );

      expect(
        canShowSayaSudahBayar(
          isPengelola: false,
          status: 'menunggu_pembayaran',
          metodePembayaran: 'transfer_manual',
        ),
        isTrue,
      );
    });

    test('TIDAK TAMPIL untuk metode pembayaran COD', () {
      expect(
        canShowSayaSudahBayar(
          isPengelola: false,
          status: 'menunggu_pembayaran',
          metodePembayaran: 'Tunai di Tempat (COD)',
        ),
        isFalse,
      );

      expect(
        canShowSayaSudahBayar(
          isPengelola: false,
          status: 'menunggu_pembayaran',
          metodePembayaran: 'tunai_di_tempat',
        ),
        isFalse,
      );
    });

    test('TIDAK TAMPIL untuk status selain menunggu_pembayaran (menunggu_konfirmasi, dibayar, dll)', () {
      // Setelah tombol berhasil ditekan dan server mengembalikan status menunggu_konfirmasi:
      expect(
        canShowSayaSudahBayar(
          isPengelola: false,
          status: 'menunggu_konfirmasi',
          metodePembayaran: 'Transfer Bank Manual',
        ),
        isFalse,
      );

      expect(
        canShowSayaSudahBayar(
          isPengelola: false,
          status: 'dibayar',
          metodePembayaran: 'Transfer Bank Manual',
        ),
        isFalse,
      );

      expect(
        canShowSayaSudahBayar(
          isPengelola: false,
          status: 'dibatalkan',
          metodePembayaran: 'Transfer Bank Manual',
        ),
        isFalse,
      );
    });

    test('TIDAK TAMPIL pada mode pengelola / admin', () {
      expect(
        canShowSayaSudahBayar(
          isPengelola: true,
          status: 'menunggu_pembayaran',
          metodePembayaran: 'Transfer Bank Manual',
        ),
        isFalse,
      );
    });

    test('TETAP TAMPIL setelah reload jika status di server masih menunggu_pembayaran', () {
      // Simulasi halaman direload/disegarkan saat status belum berubah di server
      final currentServerStatus = 'menunggu_pembayaran';
      final currentServerMethod = 'Transfer Bank Manual';

      expect(
        canShowSayaSudahBayar(
          isPengelola: false,
          status: currentServerStatus,
          metodePembayaran: currentServerMethod,
        ),
        isTrue,
      );
    });
  });

  group('Paket B.2 - API Update Status Pembeli (LayananApi)', () {
    test('updateStatusPesanan uses buyer token, sends menunggu_konfirmasi, and handles Laravel response', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/pesanan/101/status');
        // Verifikasi token pembeli digunakan
        expect(request.headers['Authorization'], 'Bearer token-pembeli-test');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['status'], 'menunggu_konfirmasi');
        expect(body['catatan'], 'Pembeli mengonfirmasi pembayaran telah ditransfer');

        // Response nyata Laravel PATCH /api/pesanan/{id}/status
        return http.Response(
          jsonEncode({
            'status': 'sukses',
            'code': '200',
            'message': 'Status pesanan berhasil diperbarui',
            'data': {
              'pesanan_id': 101,
              'nomor_pesanan': 'ATK-20261106-00101',
              'status_lama': 'menunggu_pembayaran',
              'status_baru': 'menunggu_konfirmasi',
            },
          }),
          200,
        );
      });

      final api = LayananApi(client: mockClient);
      final updated = await api.updateStatusPesanan(
        id: 101,
        status: 'menunggu_konfirmasi',
        catatan: 'Pembeli mengonfirmasi pembayaran telah ditransfer',
      );

      // Verifikasi parsing berhasil tanpa TypeError
      expect(updated.id, 101);
      expect(updated.nomorPesanan, 'ATK-20261106-00101');
      expect(updated.status, 'menunggu_konfirmasi');
    });

    test('updateStatusPesanan melemparkan ConflictException saat status ilegal (409)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'gagal',
            'code': '409',
            'message': 'Transisi status dari dibayar ke menunggu_konfirmasi tidak diizinkan',
            'data': null,
          }),
          409,
        );
      });

      final api = LayananApi(client: mockClient);
      expect(
        () => api.updateStatusPesanan(id: 101, status: 'menunggu_konfirmasi'),
        throwsA(isA<ConflictException>()),
      );
    });

    test('updateStatusPesanan melemparkan ForbiddenException saat akses ditolak (403)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'gagal',
            'code': '403',
            'message': 'Role pembeli tidak memiliki wewenang untuk mengubah status ke dibayar',
            'data': null,
          }),
          403,
        );
      });

      final api = LayananApi(client: mockClient);
      expect(
        () => api.updateStatusPesanan(id: 101, status: 'dibayar'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
