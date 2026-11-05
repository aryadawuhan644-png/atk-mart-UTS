// lib/api/models/checkout_request.dart
// Represents the payload sent to the checkout endpoint.

class CheckoutRequest {
  final String namaPenerima;
  final String alamat;
  final String kota;
  final int wilayahId;
  final int kurirId;
  final String metodePembayaran;

  CheckoutRequest({
    required this.namaPenerima,
    required this.alamat,
    required this.kota,
    required this.wilayahId,
    required this.kurirId,
    required this.metodePembayaran,
  });

  Map<String, dynamic> toJson() => {
        'nama_penerima': namaPenerima,
        'alamat': alamat,
        'kota': kota,
        'wilayah_id': wilayahId,
        'kurir_id': kurirId,
        'metode_pembayaran': metodePembayaran,
      };
}
