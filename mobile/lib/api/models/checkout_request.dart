// lib/api/models/checkout_request.dart
// Represents the payload sent to the checkout endpoint.

class CheckoutRequest {
  final String namaPenerima;
  final String alamat;
  final String kota;
  final int wilayahId;
  final int kurirId;
  final String metodePembayaran;
  final List<int>? itemIds;

  CheckoutRequest({
    required this.namaPenerima,
    required this.alamat,
    required this.kota,
    required this.wilayahId,
    required this.kurirId,
    required this.metodePembayaran,
    this.itemIds,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'nama_penerima': namaPenerima,
      'alamat': alamat,
      'kota': kota,
      'wilayah_id': wilayahId,
      'kurir_id': kurirId,
      'metode_pembayaran': metodePembayaran,
    };
    if (itemIds != null && itemIds!.isNotEmpty) {
      map['item_ids'] = itemIds;
    }
    return map;
  }
}
