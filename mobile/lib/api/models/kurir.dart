// lib/api/models/kurir.dart
// Matches KurirController response for GET /kurir (without wilayah_id query).
// data: {kurir:[{id,nama,deskripsi}], wilayah:[{id,nama,kota}], tarif:[{id,kurir_id,wilayah_id,tarif}]}
// When called with ?wilayah_id=X:
// data: {wilayah:{...}, kurir:[{kurir_id,nama,deskripsi,tarif}]}

class KurirItem {
  final int id;
  final String nama;
  final String? deskripsi;

  const KurirItem({required this.id, required this.nama, this.deskripsi});

  factory KurirItem.fromJson(Map<String, dynamic> json) => KurirItem(
        id: (json['id'] ?? json['kurir_id']) as int,
        nama: json['nama'] as String,
        deskripsi: json['deskripsi'] as String?,
      );
}

class WilayahItem {
  final int id;
  final String nama;
  final String kota;

  const WilayahItem({required this.id, required this.nama, required this.kota});

  factory WilayahItem.fromJson(Map<String, dynamic> json) => WilayahItem(
        id: json['id'] as int,
        nama: json['nama'] as String,
        kota: json['kota'] as String,
      );
}

class TarifItem {
  final int id;
  final int kurirId;
  final int wilayahId;
  final int tarif;

  const TarifItem({
    required this.id,
    required this.kurirId,
    required this.wilayahId,
    required this.tarif,
  });

  factory TarifItem.fromJson(Map<String, dynamic> json) => TarifItem(
        id: json['id'] as int,
        kurirId: json['kurir_id'] as int,
        wilayahId: json['wilayah_id'] as int,
        tarif: json['tarif'] as int,
      );
}

/// Full response from GET /kurir (no wilayah_id filter)
class KurirData {
  final List<KurirItem> kurir;
  final List<WilayahItem> wilayah;
  final List<TarifItem> tarif;

  const KurirData({
    required this.kurir,
    required this.wilayah,
    required this.tarif,
  });

  factory KurirData.fromJson(Map<String, dynamic> json) => KurirData(
        kurir: (json['kurir'] as List)
            .map((e) => KurirItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        wilayah: (json['wilayah'] as List)
            .map((e) => WilayahItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        tarif: (json['tarif'] as List)
            .map((e) => TarifItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Partial response when GET /kurir?wilayah_id=X
class KurirByWilayahData {
  final WilayahItem wilayah;
  final List<KurirByWilayahItem> kurir;

  const KurirByWilayahData({required this.wilayah, required this.kurir});

  factory KurirByWilayahData.fromJson(Map<String, dynamic> json) =>
      KurirByWilayahData(
        wilayah: WilayahItem.fromJson(json['wilayah'] as Map<String, dynamic>),
        kurir: (json['kurir'] as List)
            .map((e) =>
                KurirByWilayahItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class KurirByWilayahItem {
  final int kurirId;
  final String nama;
  final String? deskripsi;
  final int tarif;

  const KurirByWilayahItem({
    required this.kurirId,
    required this.nama,
    this.deskripsi,
    required this.tarif,
  });

  factory KurirByWilayahItem.fromJson(Map<String, dynamic> json) =>
      KurirByWilayahItem(
        kurirId: json['kurir_id'] as int,
        nama: json['nama'] as String,
        deskripsi: json['deskripsi'] as String?,
        tarif: json['tarif'] as int,
      );
}
