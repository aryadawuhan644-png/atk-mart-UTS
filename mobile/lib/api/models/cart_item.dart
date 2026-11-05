// lib/api/models/cart_item.dart
// Represents an item in the shopping cart.

class CartItem {
  final int id;
  final int produkId;
  final String namaProduk;
  final int jumlah;
  final double hargaSatuan;

  CartItem({
    required this.id,
    required this.produkId,
    required this.namaProduk,
    required this.jumlah,
    required this.hargaSatuan,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as int,
        produkId: json['produk_id'] as int,
        namaProduk: json['nama_produk'] as String,
        jumlah: json['jumlah'] as int,
        hargaSatuan: (json['harga_satuan'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'produk_id': produkId,
        'nama_produk': namaProduk,
        'jumlah': jumlah,
        'harga_satuan': hargaSatuan,
      };
}
