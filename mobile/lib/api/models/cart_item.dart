// lib/api/models/cart_item.dart
// Matches KeranjangController::formatKeranjang() response.
// GET /keranjang returns: {"data": {"items": [...], "subtotal": int, "ongkos_kirim"?: int, "total"?: int}}
// Each item: {id, produk_id, nama, jumlah, harga_satuan, subtotal}

class CartItem {
  final int id;
  final int produkId;
  final String nama;         // backend uses 'nama' not 'nama_produk'
  final int jumlah;
  final int hargaSatuan;
  final int subtotal;

  const CartItem({
    required this.id,
    required this.produkId,
    required this.nama,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as int,
        produkId: json['produk_id'] as int,
        nama: json['nama'] as String,
        jumlah: json['jumlah'] as int,
        hargaSatuan: json['harga_satuan'] as int,
        subtotal: json['subtotal'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'produk_id': produkId,
        'nama': nama,
        'jumlah': jumlah,
        'harga_satuan': hargaSatuan,
        'subtotal': subtotal,
      };
}

/// Wraps the full GET /keranjang data payload.
class KeranjangData {
  final List<CartItem> items;
  final int subtotal;
  final int? ongkosKirim;
  final int? total;

  const KeranjangData({
    required this.items,
    required this.subtotal,
    this.ongkosKirim,
    this.total,
  });

  factory KeranjangData.fromJson(Map<String, dynamic> json) => KeranjangData(
        items: (json['items'] as List)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: json['subtotal'] as int,
        ongkosKirim: json['ongkos_kirim'] as int?,
        total: json['total'] as int?,
      );
}
