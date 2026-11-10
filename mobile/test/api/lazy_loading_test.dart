import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:atkmart_mobile/api/api_config.dart';
import 'package:atkmart_mobile/api/layanan_api.dart';

void main() {
  setUp(() {
    ApiConfig.setCustomToken('token-test');
    ApiConfig.setActiveRole('pembeli');
  });

  tearDown(() {
    ApiConfig.clearCustomToken();
    ApiConfig.setActiveRole('pembeli');
  });

  test(
    'fetchProdukPaginated mengirim filter dan membaca metadata halaman',
    () async {
      final requests = <http.Request>[];
      final api = LayananApi(
        client: MockClient((request) async {
          requests.add(request);
          final page = int.parse(request.url.queryParameters['page']!);
          return http.Response(
            jsonEncode({
              'status': 'sukses',
              'code': '200',
              'message': 'Daftar produk berhasil diambil',
              'data': [
                {
                  'id': page,
                  'nama': 'Produk halaman $page',
                  'harga': 1000,
                  'kategori': 'Alat Tulis',
                  'stok': 5,
                  'tersedia': true,
                  'deskripsi': null,
                  'pre_order': false,
                  'estimasi_tersedia': null,
                  'gambar': null,
                  'harga_grosir': [],
                },
              ],
              'current_page': page,
              'per_page': 10,
              'total': 20,
              'last_page': 2,
              'has_more_pages': page < 2,
            }),
            200,
          );
        }),
      );

      final firstPage = await api.fetchProdukPaginated(
        page: 1,
        perPage: 10,
        cari: 'buku',
        kategori: 'Alat Tulis',
      );
      final secondPage = await api.fetchProdukPaginated(
        page: 2,
        perPage: 10,
        cari: 'buku',
        kategori: 'Alat Tulis',
      );

      expect(requests, hasLength(2));
      expect(
        requests.map((request) => request.url.queryParameters['page']).toList(),
        ['1', '2'],
      );
      for (final request in requests) {
        expect(request.url.queryParameters['per_page'], '10');
        expect(request.url.queryParameters['cari'], 'buku');
        expect(request.url.queryParameters['kategori'], 'Alat Tulis');
      }
      expect(firstPage.currentPage, 1);
      expect(firstPage.products.single.id, 1);
      expect(firstPage.hasMorePages, isTrue);
      expect(secondPage.currentPage, 2);
      expect(secondPage.products.single.id, 2);
      expect(secondPage.hasMorePages, isFalse);
    },
  );
}
