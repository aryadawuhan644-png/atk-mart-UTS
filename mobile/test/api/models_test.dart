// test/api/models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:atkmart_mobile/api/models/product.dart';
import 'package:atkmart_mobile/api/models/order.dart';
import 'package:atkmart_mobile/api/models/checkout_request.dart';

void main() {
  group('Product.fromJson', () {
    test('parses all required fields correctly', () {
      final json = {
        'id': 1,
        'nama': 'Pensil 2B',
        'deskripsi': 'Pensil kualitas tinggi',
        'harga': 5000,
        'stok': 10,
        'gambar_url': 'http://example.com/pensil.png',
        'status': 'ready',
      };
      final p = Product.fromJson(json);
      expect(p.id, 1);
      expect(p.nama, 'Pensil 2B');
      expect(p.harga, 5000.0);
      expect(p.stok, 10);
      expect(p.status, 'ready');
    });

    test('handles null deskripsi and gambar_url gracefully', () {
      final json = {
        'id': 2,
        'nama': 'Pulpen',
        'harga': 3000,
        'stok': 5,
        'status': 'ready',
      };
      final p = Product.fromJson(json);
      expect(p.deskripsi, '');
      expect(p.gambarUrl, '');
    });
  });

  group('Order.fromJson', () {
    test('parses checkout response fields correctly', () {
      final json = {
        'pesanan_id': 42,
        'nomor_pesanan': 'ATK-20231105-00042',
        'status': 'menunggu_pembayaran',
        'subtotal': 150000,
        'ongkos_kirim': 10000,
        'total': 160000,
      };
      final order = Order.fromJson(json);
      expect(order.pesananId, 42);
      expect(order.nomorPesanan, 'ATK-20231105-00042');
      expect(order.status, 'menunggu_pembayaran');
      expect(order.total, 160000);
      expect(order.ongkosKirim, 10000);
    });
  });

  group('CheckoutRequest.toJson', () {
    test('produces the exact field names required by the backend', () {
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
      // Must NOT contain extra fields
      expect(json.length, 6);
    });
  });
}
