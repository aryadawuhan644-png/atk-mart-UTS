// lib/api/models/order.dart
// Two different shapes are returned depending on the endpoint:
//   - POST /checkout      → {pesanan_id, nomor_pesanan, status, subtotal, ongkos_kirim, total}
//   - GET  /pesanan       → formatPesananSummary: {id, nomor_pesanan, status, subtotal, ongkos_kirim,
//                            total, nama_penerima, kurir?, wilayah?, metode_pembayaran?,
//                            jumlah_item, created_at}
//   - GET  /pesanan/{id}  → formatPesananDetail: same as above + items[], riwayat_status[]
//
// Order uses a unified model that can handle both by normalising 'id'/'pesanan_id'.

class OrderItem {
  final int id;
  final int? produkId;
  final String namaProduk;
  final int hargaNormal;
  final int hargaSatuan;
  final int jumlah;
  final int subtotal;
  final bool menungguStok;

  const OrderItem({
    required this.id,
    this.produkId,
    required this.namaProduk,
    required this.hargaNormal,
    required this.hargaSatuan,
    required this.jumlah,
    required this.subtotal,
    required this.menungguStok,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as int,
        produkId: json['produk_id'] as int?,
        namaProduk: json['nama_produk'] as String,
        hargaNormal: json['harga_normal'] as int,
        hargaSatuan: json['harga_satuan'] as int,
        jumlah: json['jumlah'] as int,
        subtotal: json['subtotal'] as int,
        menungguStok: json['menunggu_stok'] as bool,
      );
}

class StatusHistory {
  final int id;
  final String? statusLama;
  final String statusBaru;
  final String aktor;
  final String? catatan;
  final String? createdAt;

  const StatusHistory({
    required this.id,
    this.statusLama,
    required this.statusBaru,
    required this.aktor,
    this.catatan,
    this.createdAt,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) => StatusHistory(
        id: json['id'] as int,
        statusLama: json['status_lama'] as String?,
        statusBaru: json['status_baru'] as String,
        aktor: json['aktor'] as String,
        catatan: json['catatan'] as String?,
        createdAt: json['created_at'] as String?,
      );
}

class Order {
  /// Normalised from either 'id' (list/detail) or 'pesanan_id' (checkout)
  final int id;
  final String nomorPesanan;
  final String status;
  final int subtotal;
  final int ongkosKirim;
  final int total;

  // Additional fields present in list/detail responses (null for checkout)
  final String? namaPenerima;
  final String? alamat;
  final String? kota;
  final String? kurir;
  final String? wilayah;
  final String? metodePembayaran;
  final int? jumlahItem;
  final String? createdAt;

  // Only in detail response
  final List<OrderItem>? items;
  final List<StatusHistory>? riwayatStatus;

  const Order({
    required this.id,
    required this.nomorPesanan,
    required this.status,
    required this.subtotal,
    required this.ongkosKirim,
    required this.total,
    this.namaPenerima,
    this.alamat,
    this.kota,
    this.kurir,
    this.wilayah,
    this.metodePembayaran,
    this.jumlahItem,
    this.createdAt,
    this.items,
    this.riwayatStatus,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Normalise id: checkout/PATCH return 'pesanan_id', list/detail return 'id'
    final rawId = json['pesanan_id'] ?? json['id'];
    final int parsedId;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is num) {
      parsedId = rawId.toInt();
    } else {
      parsedId = int.tryParse(rawId?.toString() ?? '') ?? 0;
    }

    // kurir/wilayah/metode_pembayaran can be a string (summary) or a map (detail)
    String? resolveString(dynamic val) {
      if (val == null) return null;
      if (val is String) return val;
      if (val is Map) {
        final nama = val['nama'];
        if (nama != null && nama.toString().isNotEmpty) {
          return nama.toString();
        }
        final kode = val['kode'];
        if (kode != null && kode.toString().isNotEmpty) {
          return kode.toString();
        }
      }
      return val.toString();
    }

    // Normalise status: PATCH /pesanan/{id}/status returns 'status_baru'/'status_lama',
    // list/detail/checkout return 'status'
    final rawStatus = json['status'] ?? json['status_baru'] ?? json['status_lama'];
    final status = (rawStatus is String) ? rawStatus : (rawStatus?.toString() ?? '');

    return Order(
      id: parsedId,
      nomorPesanan: (json['nomor_pesanan'] as String?) ?? '',
      status: status,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      ongkosKirim: (json['ongkos_kirim'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      namaPenerima: json['nama_penerima'] as String?,
      alamat: json['alamat'] as String?,
      kota: json['kota'] as String?,
      kurir: resolveString(json['kurir']),
      wilayah: resolveString(json['wilayah']),
      metodePembayaran: resolveString(json['metode_pembayaran']),
      jumlahItem: (json['jumlah_item'] as num?)?.toInt(),
      createdAt: json['created_at'] as String?,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      riwayatStatus: json['riwayat_status'] != null
          ? (json['riwayat_status'] as List)
              .map((e) => StatusHistory.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomor_pesanan': nomorPesanan,
        'status': status,
        'subtotal': subtotal,
        'ongkos_kirim': ongkosKirim,
        'total': total,
      };
}
