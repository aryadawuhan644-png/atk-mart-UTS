// lib/api/models/order.dart
// Model representing an order (pesanan) response from Laravel.

class Order {
  final int pesananId;
  final String nomorPesanan;
  final String status;
  final int subtotal;
  final int ongkosKirim;
  final int total;

  Order({
    required this.pesananId,
    required this.nomorPesanan,
    required this.status,
    required this.subtotal,
    required this.ongkosKirim,
    required this.total,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        pesananId: json['pesanan_id'] as int,
        nomorPesanan: json['nomor_pesanan'] as String,
        status: json['status'] as String,
        subtotal: json['subtotal'] as int,
        ongkosKirim: json['ongkos_kirim'] as int,
        total: json['total'] as int,
      );

  Map<String, dynamic> toJson() => {
        'pesanan_id': pesananId,
        'nomor_pesanan': nomorPesanan,
        'status': status,
        'subtotal': subtotal,
        'ongkos_kirim': ongkosKirim,
        'total': total,
      };
}
