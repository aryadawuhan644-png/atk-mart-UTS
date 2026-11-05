// lib/api/layanan_api.dart
// Full implementation of the 14 Laravel API endpoints for ATK Mart.
// Web-compatible: no dart:io imports.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

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
  String toString() => 'ApiException: $message';
}

class NetworkException extends ApiException {
  const NetworkException(super.message);
}

class RequestTimeoutException extends ApiException {
  const RequestTimeoutException(super.message);
}

class ValidationException extends ApiException {
  final Map<String, dynamic> errors;
  const ValidationException(super.message, this.errors);
}

class ConflictException extends ApiException {
  const ConflictException(super.message);
}

class ServerException extends ApiException {
  const ServerException(super.message);
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

  factory _LaravelResponse.parse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return _LaravelResponse(
      status: json['status'] as String? ?? '',
      code: json['code'] as String? ?? '0',
      message: json['message'] as String? ?? '',
      data: json['data'],
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }

  bool get isSuccess => status == 'sukses';
}

// ---------------------------------------------------------------------------
// Core API service
// ---------------------------------------------------------------------------

class LayananApi {
  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 15);

  LayananApi({http.Client? client}) : _client = client ?? http.Client();

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

  /// Execute [fn], parse the Laravel envelope, and return [data] via [parser].
  /// Throws typed [ApiException] subclasses on failure.
  Future<T> _request<T>(
    Future<http.Response> Function() fn,
    T Function(dynamic data) parser,
  ) async {
    http.Response response;
    try {
      response = await fn().timeout(_timeout);
    } on TimeoutException {
      throw const RequestTimeoutException('Request ke server melebihi batas waktu (15s)');
    } catch (e) {
      // Catches SocketException, ClientException, etc.
      throw NetworkException('Tidak dapat terhubung ke server: $e');
    }

    final env = _LaravelResponse.parse(response.body);
    final httpCode = int.tryParse(env.code) ?? response.statusCode;

    if (env.isSuccess) {
      return parser(env.data);
    }

    switch (httpCode) {
      case 401:
        throw ApiException('Tidak diotorisasi: ${env.message}');
      case 409:
        throw ConflictException(env.message);
      case 422:
        throw ValidationException(env.message, env.errors ?? {});
      case 500:
        throw ServerException(env.message);
      default:
        throw ApiException('Error $httpCode: ${env.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // 1. GET /produk
  // ---------------------------------------------------------------------------
  Future<List<Product>> fetchProduk({String? cari, String? kategori}) async {
    final query = <String, String>{};
    if (cari != null && cari.isNotEmpty) query['cari'] = cari;
    if (kategori != null && kategori.isNotEmpty) query['kategori'] = kategori;

    return _request(
      () => _client.get(_uri('/produk', query), headers: ApiConfig.defaultHeaders()),
      (data) => (data as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. GET /produk/{id}
  // ---------------------------------------------------------------------------
  Future<Product> fetchProdukDetail(int id) => _request(
        () => _client.get(_uri('/produk/$id'), headers: ApiConfig.defaultHeaders()),
        (data) => Product.fromJson(data as Map<String, dynamic>),
      );

  // ---------------------------------------------------------------------------
  // 3. POST /produk  (pengelola only)
  // ---------------------------------------------------------------------------
  Future<Product> createProduk(Map<String, dynamic> payload) => _request(
        () => _client.post(
          _uri('/produk'),
          headers: ApiConfig.defaultHeaders(),
          body: jsonEncode(payload),
        ),
        (data) => Product.fromJson(data as Map<String, dynamic>),
      );

  // ---------------------------------------------------------------------------
  // 4. PUT /produk/{id}  (pengelola only)
  // ---------------------------------------------------------------------------
  Future<Product> updateProduk(int id, Map<String, dynamic> payload) => _request(
        () => _client.put(
          _uri('/produk/$id'),
          headers: ApiConfig.defaultHeaders(),
          body: jsonEncode(payload),
        ),
        (data) => Product.fromJson(data as Map<String, dynamic>),
      );

  // ---------------------------------------------------------------------------
  // 5. DELETE /produk/{id}  (pengelola only)
  // ---------------------------------------------------------------------------
  Future<void> deleteProduk(int id) => _request<void>(
        () => _client.delete(_uri('/produk/$id'), headers: ApiConfig.defaultHeaders()),
        (_) {},
      );

  // ---------------------------------------------------------------------------
  // 6. GET /kurir
  // ---------------------------------------------------------------------------
  Future<List<Kurir>> fetchKurir() => _request(
        () => _client.get(_uri('/kurir'), headers: ApiConfig.defaultHeaders()),
        (data) => (data as List)
            .map((e) => Kurir.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // ---------------------------------------------------------------------------
  // 7. GET /keranjang  (pembeli only)
  // ---------------------------------------------------------------------------
  Future<List<CartItem>> fetchKeranjang() => _request(
        () => _client.get(_uri('/keranjang'), headers: ApiConfig.defaultHeaders()),
        (data) => (data as List)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // ---------------------------------------------------------------------------
  // 8. POST /keranjang  (pembeli only)
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
  // 9. PUT /keranjang/{id}  (pembeli only)
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
  // 10. DELETE /keranjang/{id}  (pembeli only)
  // ---------------------------------------------------------------------------
  Future<void> deleteKeranjang(int id) => _request<void>(
        () => _client.delete(
            _uri('/keranjang/$id'), headers: ApiConfig.defaultHeaders()),
        (_) {},
      );

  // ---------------------------------------------------------------------------
  // 11. POST /checkout  (pembeli only)
  // Idempotency key MUST be sent as the HTTP header X-Kunci-Idempoten.
  // Backend returns 200 (old order) or 201 (new order) on sukses,
  // 409 on duplicate key with different payload.
  // ---------------------------------------------------------------------------
  Future<Order> checkout({
    required CheckoutRequest request,
    required String idempotencyKey,
  }) =>
      _request(
        () => _client.post(
          _uri('/checkout'),
          headers: ApiConfig.defaultHeaders(
            extra: {'X-Kunci-Idempoten': idempotencyKey},
          ),
          body: jsonEncode(request.toJson()),
        ),
        (data) => Order.fromJson(data as Map<String, dynamic>),
      );

  // ---------------------------------------------------------------------------
  // 12. GET /pesanan
  // ---------------------------------------------------------------------------
  Future<List<Order>> fetchPesanan() => _request(
        () => _client.get(_uri('/pesanan'), headers: ApiConfig.defaultHeaders()),
        (data) => (data as List)
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // ---------------------------------------------------------------------------
  // 13. GET /pesanan/{id}
  // ---------------------------------------------------------------------------
  Future<Order> fetchPesananDetail(int id) => _request(
        () => _client.get(
            _uri('/pesanan/$id'), headers: ApiConfig.defaultHeaders()),
        (data) => Order.fromJson(data as Map<String, dynamic>),
      );

  // ---------------------------------------------------------------------------
  // 14. PATCH /pesanan/{id}/status
  // ---------------------------------------------------------------------------
  Future<Order> updateStatusPesanan({
    required int id,
    required String status,
  }) =>
      _request(
        () => _client.patch(
          _uri('/pesanan/$id/status'),
          headers: ApiConfig.defaultHeaders(),
          body: jsonEncode({'status': status}),
        ),
        (data) => Order.fromJson(data as Map<String, dynamic>),
      );
}
