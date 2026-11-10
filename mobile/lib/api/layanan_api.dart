// lib/api/layanan_api.dart
// Full implementation of the 14 Laravel API endpoints for ATK Mart.
// Web-compatible: no dart:io imports.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api_config.dart';
import 'models/cart_item.dart';
import 'models/checkout_request.dart';
import 'models/kurir.dart';
import 'models/order.dart';
import 'models/product.dart';

// ---------------------------------------------------------------------------
// Custom exception hierarchy
// ---------------------------------------------------------------------------

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([super.message = 'Tidak dapat terhubung ke server ATK Mart. Periksa koneksi internet Anda.']);
}

class RequestTimeoutException extends ApiException {
  const RequestTimeoutException([super.message = 'Permintaan ke server melebihi batas waktu (15 detik). Silakan coba lagi.']);
}

class ValidationException extends ApiException {
  final Map<String, dynamic> errors;
  const ValidationException(super.message, this.errors);
}

class ConflictException extends ApiException {
  const ConflictException(super.message);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Sesi tidak sah. Token autentikasi tidak valid atau belum diatur.']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Akses ditolak: Anda tidak memiliki wewenang untuk tindakan ini.']);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Data yang diminta tidak ditemukan di server (404).']);
}

class ServerException extends ApiException {
  const ServerException([super.message = 'Terjadi kendala pada server (500). Silakan coba beberapa saat lagi.']);
}

// ---------------------------------------------------------------------------
// Laravel standard JSON envelope parser
// ---------------------------------------------------------------------------

class _LaravelResponse {
  final String status;
  final String code;
  final String message;
  final dynamic data;
  final Map<String, dynamic>? errors;

  const _LaravelResponse({
    required this.status,
    required this.code,
    required this.message,
    required this.data,
    this.errors,
  });

  factory _LaravelResponse.parse(String body, [int fallbackStatusCode = 0]) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return _LaravelResponse(
        status: json['status'] as String? ?? '',
        code: json['code']?.toString() ?? '$fallbackStatusCode',
        message: json['message'] as String? ?? '',
        data: json['data'],
        errors: json['errors'] is Map ? (json['errors'] as Map).cast<String, dynamic>() : null,
      );
    } catch (_) {
      return _LaravelResponse(
        status: 'gagal',
        code: '$fallbackStatusCode',
        message: fallbackStatusCode == 500
            ? 'Terjadi kendala pada server (500). Silakan coba beberapa saat lagi.'
            : (fallbackStatusCode == 404
                ? 'Data yang diminta tidak ditemukan (404).'
                : 'Respon dari server tidak valid.'),
        data: null,
      );
    }
  }

  bool get isSuccess => status == 'sukses';
}

// ---------------------------------------------------------------------------
// Core API service
// ---------------------------------------------------------------------------

class LayananApi {
  static http.Client? _mockClient;

  /// Injeksi mock client untuk keperluan automated testing.
  static void setMockClient(http.Client? client) {
    _mockClient = client;
  }

  static http.Client? get mockClient => _mockClient;

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 15);

  http.Client get client => _client;

  LayananApi({http.Client? client})
      : _client = client ?? _mockClient ?? http.Client();

  // --- Helpers ---------------------------------------------------------------

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ApiConfig.baseUrl;
    if (base.isEmpty) {
      throw StateError('API_BASE_URL not provided via --dart-define');
    }
    final uri = Uri.parse('$base$path');
    return query != null && query.isNotEmpty
        ? uri.replace(queryParameters: query)
        : uri;
  }

  /// Execute [fn], parse the Laravel envelope, return [data] via [parser].
  Future<T> _request<T>(
    Future<http.Response> Function() fn,
    T Function(dynamic data) parser, {
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? _timeout;
    http.Response response;
    try {
      response = await fn().timeout(effectiveTimeout);
    } on TimeoutException {
      final sec = effectiveTimeout.inSeconds;
      throw RequestTimeoutException(
          'Permintaan ke server melebihi batas waktu ($sec detik). Silakan coba lagi.');
    } catch (_) {
      throw const NetworkException(
          'Tidak dapat terhubung ke server ATK Mart. Periksa koneksi internet Anda.');
    }

    final env = _LaravelResponse.parse(response.body, response.statusCode);
    final httpCode = int.tryParse(env.code) ?? response.statusCode;

    if (env.isSuccess) {
      return parser(env.data);
    }

    switch (httpCode) {
      case 401:
        throw UnauthorizedException(
            env.message.isNotEmpty ? env.message : 'Sesi tidak sah. Token autentikasi tidak valid atau belum diatur.');
      case 403:
        throw ForbiddenException(
            env.message.isNotEmpty ? env.message : 'Akses ditolak: Anda tidak memiliki wewenang untuk tindakan ini.');
      case 404:
        throw NotFoundException(
            env.message.isNotEmpty ? env.message : 'Data yang diminta tidak ditemukan di server (404).');
      case 409:
        throw ConflictException(env.message);
      case 422:
        throw ValidationException(env.message, env.errors ?? {});
      case 500:
        throw const ServerException(
            'Terjadi kendala pada server (500). Silakan coba beberapa saat lagi.');
      default:
        throw ApiException(
            env.message.isNotEmpty ? env.message : 'Terjadi kendala dengan kode status $httpCode');
    }
  }

  // ---------------------------------------------------------------------------
  // 1. GET /produk
  // Response: data is List of formatProduk objects.
  // ---------------------------------------------------------------------------
  Future<List<Product>> fetchProduk({String? cari, String? kategori}) async {
    final query = <String, String>{};
    if (cari != null && cari.isNotEmpty) query['cari'] = cari;
    if (kategori != null && kategori.isNotEmpty) query['kategori'] = kategori;

    return _request(
      () => _client.get(
          _uri('/produk', query), headers: ApiConfig.defaultHeaders()),
      (data) => (data as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. GET /produk/{id}
  // ---------------------------------------------------------------------------
  Future<Product> fetchProdukDetail(int id) => _request(
        () => _client.get(
            _uri('/produk/$id'), headers: ApiConfig.defaultHeaders()),
        (data) => Product.fromJson(data as Map<String, dynamic>),
      );

  // ---------------------------------------------------------------------------
  // 3. POST /produk (pengelola only)
  // payload: {nama, harga, kategori, stok, tersedia?, deskripsi?,
  //           pre_order?, estimasi_tersedia?, harga_grosir?[]}
  // Mendukung multipart/form-data saat mengunggah gambar produk baru.
  // ---------------------------------------------------------------------------
  Future<Product> createProduk(
    Map<String, dynamic> payload, {
    XFile? gambarFile,
    List<int>? gambarBytes,
    String? gambarNama,
  }) {
    if (gambarFile != null || (gambarBytes != null && gambarBytes.isNotEmpty)) {
      return _sendMultipartProduk(
        method: 'POST',
        uri: _uri('/produk'),
        payload: payload,
        gambarFile: gambarFile,
        gambarBytes: gambarBytes,
        gambarNama: gambarNama,
      );
    }

    return _request(
      () => _client.post(
        _uri('/produk'),
        headers: ApiConfig.pengelolaHeaders(),
        body: jsonEncode(payload),
      ),
      (data) => Product.fromJson(data as Map<String, dynamic>),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. PUT /produk/{id} (pengelola only)
  // Mendukung multipart/form-data via method spoofing _method=PUT saat unggah gambar baru.
  // Jika gambar tidak diganti (gambarFile & gambarBytes null), pertahankan gambar lama.
  // ---------------------------------------------------------------------------
  Future<Product> updateProduk(
    int id,
    Map<String, dynamic> payload, {
    XFile? gambarFile,
    List<int>? gambarBytes,
    String? gambarNama,
  }) {
    if (gambarFile != null || (gambarBytes != null && gambarBytes.isNotEmpty)) {
      return _sendMultipartProduk(
        method: 'PUT',
        uri: _uri('/produk/$id'),
        payload: payload,
        gambarFile: gambarFile,
        gambarBytes: gambarBytes,
        gambarNama: gambarNama,
      );
    }

    return _request(
      () => _client.put(
        _uri('/produk/$id'),
        headers: ApiConfig.pengelolaHeaders(),
        body: jsonEncode(payload),
      ),
      (data) => Product.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Kirim data produk via multipart/form-data (misal saat menyertakan berkas gambar).
  /// Untuk mode edit (PUT), memanfaatkan method spoofing _method=PUT dan header
  /// X-HTTP-Method-Override karena backend Laravel tidak mem-parsing multipart pada HTTP PUT native.
  /// Header Authorization pengelola tetap disertakan, dan Content-Type dibiarkan diatur
  /// otomatis oleh http.MultipartRequest (bukan application/json).
  Future<Product> _sendMultipartProduk({
    required String method,
    required Uri uri,
    required Map<String, dynamic> payload,
    XFile? gambarFile,
    List<int>? gambarBytes,
    String? gambarNama,
  }) async {
    final request = http.MultipartRequest('POST', uri);

    final token = ApiConfig.tokenPengelola;
    if (token.isEmpty) {
      throw StateError(
        'Token pengelola belum dikonfigurasi. '
        'Pastikan assets/config/env.json terisi atau gunakan --dart-define=STATIC_TOKEN=...',
      );
    }

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    if (method.toUpperCase() == 'PUT') {
      request.fields['_method'] = 'PUT';
      request.headers['X-HTTP-Method-Override'] = 'PUT';
    }

    payload.forEach((key, value) {
      if (key == 'harga_grosir') {
        if (value is List) {
          for (var i = 0; i < value.length; i++) {
            final tier = value[i];
            if (tier is Map) {
              final minKuantitas = tier['min_kuantitas'];
              final hargaSatuan = tier['harga_satuan'];
              if (minKuantitas != null) {
                request.fields['harga_grosir[$i][min_kuantitas]'] =
                    minKuantitas.toString();
              }
              if (hargaSatuan != null) {
                request.fields['harga_grosir[$i][harga_satuan]'] =
                    hargaSatuan.toString();
              }
            }
          }
        }
      } else if (key == 'gambar') {
        // Abaikan field gambar berbasis string URL jika ada
      } else if (value != null) {
        if (value is bool) {
          request.fields[key] = value ? '1' : '0';
        } else {
          request.fields[key] = value.toString();
        }
      }
    });

    if (gambarBytes != null && gambarBytes.isNotEmpty) {
      final name = (gambarNama != null && gambarNama.isNotEmpty)
          ? gambarNama
          : 'produk.jpg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'gambar',
          gambarBytes,
          filename: name,
        ),
      );
    } else if (gambarFile != null) {
      final bytes = await gambarFile.readAsBytes();
      final name = gambarFile.name.isNotEmpty ? gambarFile.name : 'produk.jpg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'gambar',
          bytes,
          filename: name,
        ),
      );
    }

    return _request(
      () async {
        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      },
      (data) => Product.fromJson(data as Map<String, dynamic>),
      timeout: const Duration(seconds: 60),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. DELETE /produk/{id} (pengelola only)
  // Returns 200 on success; 409 if product has active orders.
  // ---------------------------------------------------------------------------
  Future<void> deleteProduk(int id) => _request<void>(
        () => _client.delete(
            _uri('/produk/$id'), headers: ApiConfig.pengelolaHeaders()),
        (_) {},
      );

  // ---------------------------------------------------------------------------
  // 6. GET /kurir
  // Without query: data = {kurir:[], wilayah:[], tarif:[]}
  // With ?wilayah_id=X: data = {wilayah:{...}, kurir:[{kurir_id,nama,deskripsi,tarif}]}
  // ---------------------------------------------------------------------------
  Future<KurirData> fetchKurir() => _request(
        () => _client.get(
            _uri('/kurir'), headers: ApiConfig.defaultHeaders()),
        (data) => KurirData.fromJson(data as Map<String, dynamic>),
      );

  Future<KurirByWilayahData> fetchKurirByWilayah(int wilayahId) => _request(
        () => _client.get(
          _uri('/kurir', {'wilayah_id': wilayahId.toString()}),
          headers: ApiConfig.defaultHeaders(),
        ),
        (data) => KurirByWilayahData.fromJson(data as Map<String, dynamic>),
      );

  // ---------------------------------------------------------------------------
  // 7. GET /keranjang (pembeli only)
  // Response: data = {items:[], subtotal:int, ongkos_kirim?:int, total?:int}
  // Mendukung parameter opsional kurir_id, wilayah_id, dan item_ids untuk kalkulasi tarif server
  // ---------------------------------------------------------------------------
  Future<KeranjangData> fetchKeranjang({int? kurirId, int? wilayahId, List<int>? itemIds}) {
    final query = <String, String>{};
    if (kurirId != null) query['kurir_id'] = kurirId.toString();
    if (wilayahId != null) query['wilayah_id'] = wilayahId.toString();
    if (itemIds != null && itemIds.isNotEmpty) query['item_ids'] = itemIds.join(',');

    return _request(
      () => _client.get(
          _uri('/keranjang', query.isNotEmpty ? query : null),
          headers: ApiConfig.defaultHeaders()),
      (data) => KeranjangData.fromJson(data as Map<String, dynamic>),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. POST /keranjang (pembeli only)
  // payload: {produk_id, jumlah}
  // ---------------------------------------------------------------------------
  Future<void> addKeranjang({required int produkId, required int jumlah}) =>
      _request<void>(
        () => _client.post(
          _uri('/keranjang'),
          headers: ApiConfig.defaultHeaders(),
          body: jsonEncode({'produk_id': produkId, 'jumlah': jumlah}),
        ),
        (_) {},
      );

  // ---------------------------------------------------------------------------
  // 9. PUT /keranjang/{id} (pembeli only)
  // payload: {jumlah}
  // ---------------------------------------------------------------------------
  Future<void> updateKeranjang({required int id, required int jumlah}) =>
      _request<void>(
        () => _client.put(
          _uri('/keranjang/$id'),
          headers: ApiConfig.defaultHeaders(),
          body: jsonEncode({'jumlah': jumlah}),
        ),
        (_) {},
      );

  // ---------------------------------------------------------------------------
  // 10. DELETE /keranjang/{id} (pembeli only)
  // ---------------------------------------------------------------------------
  Future<void> deleteKeranjang(int id) => _request<void>(
        () => _client.delete(
            _uri('/keranjang/$id'), headers: ApiConfig.defaultHeaders()),
        (_) {},
      );

  // ---------------------------------------------------------------------------
  // 11. POST /checkout (pembeli only)
  // Header: X-Kunci-Idempoten = idempotencyKey
  // payload: CheckoutRequest (nama_penerima, alamat, kota, wilayah_id, kurir_id, metode_pembayaran)
  // Response 201 (new) or 200 (idempotent repeat): data = {pesanan_id, nomor_pesanan, status, subtotal, ongkos_kirim, total}
  // Response 409 (different payload): throws ConflictException
  // Response 422 (validation): throws ValidationException
  // ---------------------------------------------------------------------------
  Future<Order> checkout({
    required CheckoutRequest request,
    required String idempotencyKey,
  }) =>
      _request(
        () => _client.post(
          _uri('/checkout'),
          headers: ApiConfig.defaultHeaders(
              extra: {'X-Kunci-Idempoten': idempotencyKey}),
          body: jsonEncode(request.toJson()),
        ),
        (data) => Order.fromJson(data as Map<String, dynamic>),
      );

  // ---------------------------------------------------------------------------
  // 12. GET /pesanan
  // Response: data is List of formatPesananSummary objects.
  // ---------------------------------------------------------------------------
  Future<List<Order>> fetchPesanan() => _request(
        () => _client.get(
            _uri('/pesanan'), headers: ApiConfig.defaultHeaders()),
        (data) => (data as List)
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// 12b. GET /pesanan (pengelola - melihat seluruh pesanan pelanggan)
  Future<List<Order>> fetchPesananPengelola() => _request(
        () => _client.get(
            _uri('/pesanan'), headers: ApiConfig.pengelolaHeaders()),
        (data) => (data as List)
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // ---------------------------------------------------------------------------
  // 13. GET /pesanan/{id}
  // Response: data = formatPesananDetail (includes items & riwayat_status).
  // ---------------------------------------------------------------------------
  Future<Order> fetchPesananDetail(int id) => _request(
        () => _client.get(
            _uri('/pesanan/$id'), headers: ApiConfig.defaultHeaders()),
        (data) => Order.fromJson(data as Map<String, dynamic>),
      );

  /// 13b. GET /pesanan/{id} (pengelola)
  Future<Order> fetchPesananDetailPengelola(int id) => _request(
        () => _client.get(
            _uri('/pesanan/$id'), headers: ApiConfig.pengelolaHeaders()),
        (data) => Order.fromJson(data as Map<String, dynamic>),
      );

  // ---------------------------------------------------------------------------
  // 14. PATCH /pesanan/{id}/status
  // payload: {status: "new_status"}
  // Response: data = formatPesananSummary of updated order.
  // ---------------------------------------------------------------------------
  Future<Order> updateStatusPesanan({
    required int id,
    required String status,
    String? catatan,
  }) =>
      _request(
        () => _client.patch(
          _uri('/pesanan/$id/status'),
          headers: ApiConfig.defaultHeaders(),
          body: jsonEncode({
            'status': status,
            'catatan': ?catatan,
          }),
        ),
        (data) => Order.fromJson(data as Map<String, dynamic>),
      );

  /// 14b. PATCH /pesanan/{id}/status (pengelola - konfirmasi pembayaran & status lain)
  Future<Order> updateStatusPesananPengelola({
    required int id,
    required String status,
    String? catatan,
  }) =>
      _request(
        () => _client.patch(
          _uri('/pesanan/$id/status'),
          headers: ApiConfig.pengelolaHeaders(),
          body: jsonEncode({
            'status': status,
            'catatan': ?catatan,
          }),
        ),
        (data) => Order.fromJson(data as Map<String, dynamic>),
      );
}
