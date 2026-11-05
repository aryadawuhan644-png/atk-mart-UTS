// lib/api/models/kurir.dart
// Represents a courier option returned by the API.

class Kurir {
  final int id;
  final String nama;
  final double biaya;

  Kurir({required this.id, required this.nama, required this.biaya});

  factory Kurir.fromJson(Map<String, dynamic> json) => Kurir(
        id: json['id'] as int,
        nama: json['nama'] as String,
        biaya: (json['biaya'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'biaya': biaya,
      };
}
