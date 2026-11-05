// lib/api/models/product.dart
// Matches ProdukController::formatProduk() response exactly.

class HargaGrosirTier {
  final int minKuantitas;
  final int hargaSatuan;

  const HargaGrosirTier({required this.minKuantitas, required this.hargaSatuan});

  factory HargaGrosirTier.fromJson(Map<String, dynamic> json) => HargaGrosirTier(
        minKuantitas: json['min_kuantitas'] as int,
        hargaSatuan: json['harga_satuan'] as int,
      );

  Map<String, dynamic> toJson() => {
        'min_kuantitas': minKuantitas,
        'harga_satuan': hargaSatuan,
      };
}

class Product {
  final int id;
  final String nama;
  final int harga;
  final String kategori;
  final int stok;
  final bool tersedia;
  final String? deskripsi;
  final bool preOrder;
  final String? estimasiTersedia;
  final List<HargaGrosirTier> hargaGrosir;

  const Product({
    required this.id,
    required this.nama,
    required this.harga,
    required this.kategori,
    required this.stok,
    required this.tersedia,
    this.deskripsi,
    required this.preOrder,
    this.estimasiTersedia,
    required this.hargaGrosir,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        nama: json['nama'] as String,
        harga: json['harga'] as int,
        kategori: json['kategori'] as String,
        stok: json['stok'] as int,
        tersedia: json['tersedia'] as bool,
        deskripsi: json['deskripsi'] as String?,
        preOrder: json['pre_order'] as bool,
        estimasiTersedia: json['estimasi_tersedia'] as String?,
        hargaGrosir: (json['harga_grosir'] as List? ?? [])
            .map((e) => HargaGrosirTier.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'harga': harga,
        'kategori': kategori,
        'stok': stok,
        'tersedia': tersedia,
        'deskripsi': deskripsi,
        'pre_order': preOrder,
        'estimasi_tersedia': estimasiTersedia,
        'harga_grosir': hargaGrosir.map((e) => e.toJson()).toList(),
      };
}
