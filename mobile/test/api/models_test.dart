// test/api/models_test.dart
// Unit tests for model parsing – no backend required.

import 'package:flutter_test/flutter_test.dart';
import 'package:atkmart_mobile/api/models/product.dart';
import 'package:atkmart_mobile/api/models/order.dart';
import 'package:atkmart_mobile/api/models/checkout_request.dart';
import 'package:atkmart_mobile/api/models/cart_item.dart';
import 'package:atkmart_mobile/api/models/kurir.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Product
  // ---------------------------------------------------------------------------
  group('Product.fromJson', () {
    test('parses all fields from ProdukController::formatProduk response', () {
      final json = {
        'id': 1,
        'nama': 'Pensil 2B',
        'harga': 5000,
        'kategori': 'Alat Tulis',
        'stok': 10,
        'tersedia': true,
        'deskripsi': 'Pensil kualitas tinggi',
        'pre_order': false,
        'estimasi_tersedia': null,
        'harga_grosir': [
          {'min_kuantitas': 10, 'harga_satuan': 4500},
        ],
      };
      final p = Product.fromJson(json);
      expect(p.id, 1);
      expect(p.nama, 'Pensil 2B');
      expect(p.harga, 5000);
      expect(p.kategori, 'Alat Tulis');
      expect(p.tersedia, isTrue);
      expect(p.preOrder, isFalse);
      expect(p.hargaGrosir.length, 1);
      expect(p.hargaGrosir.first.minKuantitas, 10);
      expect(p.hargaGrosir.first.hargaSatuan, 4500);
    });

    test('handles null optional fields gracefully', () {
      final json = {
        'id': 2,
        'nama': 'Pulpen',
        'harga': 3000,
        'kategori': 'Alat Tulis',
        'stok': 5,
        'tersedia': true,
        'deskripsi': null,
        'pre_order': false,
        'estimasi_tersedia': null,
        'harga_grosir': [],
      };
      final p = Product.fromJson(json);
      expect(p.deskripsi, isNull);
      expect(p.estimasiTersedia, isNull);
      expect(p.hargaGrosir, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // CartItem & KeranjangData
  // ---------------------------------------------------------------------------
  group('KeranjangData.fromJson', () {
    test('parses GET /keranjang response structure correctly', () {
      final json = {
        'items': [
          {
            'id': 1,
            'produk_id': 5,
            'nama': 'Penghapus',
            'jumlah': 2,
            'harga_satuan': 2000,
            'subtotal': 4000,
          }
        ],
        'subtotal': 4000,
        'ongkos_kirim': 10000,
        'total': 14000,
      };
      final k = KeranjangData.fromJson(json);
      expect(k.items.length, 1);
      expect(k.items.first.nama, 'Penghapus');
      expect(k.items.first.hargaSatuan, 2000);
      expect(k.subtotal, 4000);
      expect(k.ongkosKirim, 10000);
      expect(k.total, 14000);
    });

    test('handles missing optional ongkos_kirim and total', () {
      final json = {
        'items': [],
        'subtotal': 0,
      };
      final k = KeranjangData.fromJson(json);
      expect(k.items, isEmpty);
      expect(k.ongkosKirim, isNull);
      expect(k.total, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Order – checkout response (pesanan_id key)
  // ---------------------------------------------------------------------------
  group('Order.fromJson', () {
    test('parses checkout response (pesanan_id key)', () {
      final json = {
        'pesanan_id': 42,
        'nomor_pesanan': 'ATK-20231105-00042',
        'status': 'menunggu_pembayaran',
        'subtotal': 150000,
        'ongkos_kirim': 10000,
        'total': 160000,
      };
      final o = Order.fromJson(json);
      expect(o.id, 42);
      expect(o.nomorPesanan, 'ATK-20231105-00042');
      expect(o.total, 160000);
    });

    test('parses list/detail response (id key with extra fields)', () {
      final json = {
        'id': 7,
        'nomor_pesanan': 'ATK-20231101-00007',
        'status': 'selesai',
        'nama_penerima': 'Budi',
        'kurir': 'JNE',
        'wilayah': 'Blimbing',
        'metode_pembayaran': 'OVO',
        'jumlah_item': 3,
        'created_at': '2023-11-01 10:00:00',
        'subtotal': 90000,
        'ongkos_kirim': 8000,
        'total': 98000,
      };
      final o = Order.fromJson(json);
      expect(o.id, 7);
      expect(o.kurir, 'JNE');
      expect(o.jumlahItem, 3);
    });

    test('parses kurir/wilayah as nested map (detail response)', () {
      final json = {
        'id': 8,
        'nomor_pesanan': 'ATK-20231102-00008',
        'status': 'selesai',
        'subtotal': 50000,
        'ongkos_kirim': 5000,
        'total': 55000,
        'kurir': {'id': 2, 'nama': 'J&T'},
        'wilayah': {'id': 1, 'nama': 'Blimbing', 'kota': 'Kota Malang'},
        'metode_pembayaran': {'id': 1, 'kode': 'OVO', 'nama': 'OVO'},
      };
      final o = Order.fromJson(json);
      expect(o.kurir, 'J&T');
      expect(o.wilayah, 'Blimbing');
      expect(o.metodePembayaran, 'OVO');
    });
  });

  // ---------------------------------------------------------------------------
  // CheckoutRequest
  // ---------------------------------------------------------------------------
  group('CheckoutRequest.toJson', () {
    test('produces exact field names required by CheckoutController', () {
      final req = CheckoutRequest(
        namaPenerima: 'Budi Santoso',
        alamat: 'Jl. Merdeka 10',
        kota: 'Kota Malang',
        wilayahId: 3,
        kurirId: 2,
        metodePembayaran: 'OVO',
      );
      final json = req.toJson();
      expect(json['nama_penerima'], 'Budi Santoso');
      expect(json['alamat'], 'Jl. Merdeka 10');
      expect(json['kota'], 'Kota Malang');
      expect(json['wilayah_id'], 3);
      expect(json['kurir_id'], 2);
      expect(json['metode_pembayaran'], 'OVO');
      expect(json.length, 6);
    });
  });

  // ---------------------------------------------------------------------------
  // KurirData
  // ---------------------------------------------------------------------------
  group('KurirData.fromJson', () {
    test('parses GET /kurir response (no filter)', () {
      final json = {
        'kurir': [
          {'id': 1, 'nama': 'JNE', 'deskripsi': null},
        ],
        'wilayah': [
          {'id': 1, 'nama': 'Blimbing', 'kota': 'Kota Malang'},
        ],
        'tarif': [
          {'id': 1, 'kurir_id': 1, 'wilayah_id': 1, 'tarif': 8000},
        ],
      };
      final k = KurirData.fromJson(json);
      expect(k.kurir.length, 1);
      expect(k.kurir.first.nama, 'JNE');
      expect(k.wilayah.first.kota, 'Kota Malang');
      expect(k.tarif.first.tarif, 8000);
    });
  });
}
