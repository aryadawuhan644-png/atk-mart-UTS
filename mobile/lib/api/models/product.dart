// lib/api/models/product.dart
// Represents a product as returned by the Laravel API.

class Product {
  final int id;
  final String nama;
  final String deskripsi;
  final double harga;
  final int stok;
  final String gambarUrl;
  final String status; // ready, stok_habis, preorder, dll.

  Product({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.harga,
    required this.stok,
    required this.gambarUrl,
    required this.status,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        nama: json['nama'] as String,
        deskripsi: json['deskripsi'] as String? ?? '',
        harga: (json['harga'] as num).toDouble(),
        stok: json['stok'] as int,
        gambarUrl: json['gambar_url'] as String? ?? '',
        status: json['status'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'deskripsi': deskripsi,
        'harga': harga,
        'stok': stok,
        'gambar_url': gambarUrl,
        'status': status,
      };
}
