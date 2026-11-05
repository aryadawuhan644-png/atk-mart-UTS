// lib/main.dart
// Entry point for ATK Mart mobile app.
// Uses only setState, Navigator, and callbacks (no Provider/Riverpod/Bloc).

import 'package:flutter/material.dart';

import 'api/api_config.dart';
import 'api/layanan_api.dart';
import 'package:uuid/uuid.dart';

import 'api/models/cart_item.dart';
import 'api/models/checkout_request.dart';
import 'api/models/kurir.dart';
import 'api/models/order.dart';
import 'api/models/product.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initLocalConfig();
  runApp(const AtkMartApp());
}

class AtkMartApp extends StatelessWidget {
  const AtkMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ATK Mart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6BFF)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      ),
      home: const ProdukListPage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Format mata uang Rupiah standar Indonesia
// ---------------------------------------------------------------------------
String _formatRupiah(int nominal) {
  final str = nominal.toString();
  final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  return 'Rp ${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
}

// ---------------------------------------------------------------------------
// Halaman Katalog Produk (ProdukListPage)
// ---------------------------------------------------------------------------
class ProdukListPage extends StatefulWidget {
  const ProdukListPage({super.key});

  @override
  State<ProdukListPage> createState() => _ProdukListPageState();
}

class _ProdukListPageState extends State<ProdukListPage> {
  final LayananApi _api = LayananApi();
  late Future<List<Product>> _futureProduk;

  final TextEditingController _searchController = TextEditingController();
  String _selectedKategori = 'Semua';

  static const List<String> _kategoriList = [
    'Semua',
    'Alat Tulis',
    'Buku & Perlengkapan Belajar',
  ];

  @override
  void initState() {
    super.initState();
    _futureProduk = _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Memanggil API server-side dengan query 'cari' dan filter 'kategori'
  Future<List<Product>> _fetchData() {
    final query = _searchController.text.trim();
    final cariParam = query.isNotEmpty ? query : null;
    final kategoriParam =
        _selectedKategori != 'Semua' ? _selectedKategori : null;

    return _api.fetchProduk(
      cari: cariParam,
      kategori: kategoriParam,
    );
  }

  void _onSearchOrFilterChanged() {
    setState(() {
      _futureProduk = _fetchData();
    });
  }

  void _reload() {
    setState(() {
      _futureProduk = _fetchData();
    });
  }

  String _formatErrorMessage(Object error) {
    final str = error.toString();
    if (str.contains('SocketException') ||
        str.contains('NetworkException') ||
        str.contains('Failed host lookup') ||
        str.contains('ClientException')) {
      return 'Gagal terhubung ke server ATK Mart.\nPastikan backend Laravel berjalan di http://127.0.0.1:8000.';
    }
    if (str.contains('RequestTimeoutException') || str.contains('15s')) {
      return 'Permintaan ke server melebihi batas waktu (15 detik). Silakan coba lagi.';
    }
    if (str.contains('Token autentikasi belum dikonfigurasi')) {
      return 'Token autentikasi belum diatur. Pastikan file assets/config/env.json sudah diisi.';
    }
    if (str.contains('ApiException')) {
      return str.replaceAll('ApiException:', '').trim();
    }
    return 'Terjadi kendala saat memuat katalog: $error';
  }

  Widget _buildStatusBadge(Product p) {
    if (!p.tersedia) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Tidak Tersedia',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }
    if (p.preOrder) {
      final estimasi = (p.estimasiTersedia != null &&
              p.estimasiTersedia!.isNotEmpty)
          ? ' · Tiba: ${p.estimasiTersedia}'
          : '';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3D6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE0A32E), width: 0.8),
        ),
        child: Text(
          'Pre-Order$estimasi',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF946200),
          ),
        ),
      );
    }
    if (p.stok == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE14B4B), width: 0.8),
        ),
        child: const Text(
          'Stok Habis',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFFB42323),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF8EE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Stok: ${p.stok}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2E9E5B),
        ),
      ),
    );
  }

  Widget _buildGrosirPill(Product p) {
    if (p.hargaGrosir.isEmpty) return const SizedBox.shrink();
    final minTier = p.hargaGrosir.reduce(
      (a, b) => a.minKuantitas < b.minKuantitas ? a : b,
    );
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFBDD3FF), width: 0.8),
      ),
      child: Text(
        'Grosir: ≥${minTier.minKuantitas} pcs @${_formatRupiah(minTier.hargaSatuan)}',
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF2F6BFF),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButton(Product p) {
    final bool canBuy = p.tersedia && (p.preOrder || p.stok > 0);

    if (!canBuy) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          !p.tersedia ? 'Tidak Tersedia' : 'Stok Habis',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: p.preOrder ? const Color(0xFFE0A32E) : const Color(0xFF0D0D12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            p.preOrder ? Icons.schedule : Icons.add_shopping_cart,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            p.preOrder ? 'Pre-Order' : 'Beli',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Katalog ATK Mart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Riwayat Pesanan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RiwayatPesananPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Keranjang Belanja',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KeranjangPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Bilah Pencarian
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari alat tulis, buku, pulpen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        tooltip: 'Hapus teks',
                        onPressed: () {
                          _searchController.clear();
                          _onSearchOrFilterChanged();
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, size: 20),
                      tooltip: 'Cari',
                      onPressed: _onSearchOrFilterChanged,
                    ),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE6E6EC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE6E6EC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF2F6BFF), width: 1.5),
                ),
              ),
              onSubmitted: (_) => _onSearchOrFilterChanged(),
              onChanged: (_) {
                setState(() {});
              },
            ),
          ),

          // 2. Filter Kategori Horisontal (Server-Side)
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _kategoriList.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final kat = _kategoriList[i];
                final isSelected = _selectedKategori == kat;
                return ChoiceChip(
                  label: Text(kat),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2F6BFF),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : const Color(0xFF15151A),
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF2F6BFF)
                        : const Color(0xFFE6E6EC),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  showCheckmark: false,
                  onSelected: (selected) {
                    if (selected && _selectedKategori != kat) {
                      setState(() {
                        _selectedKategori = kat;
                        _futureProduk = _fetchData();
                      });
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // 3. Daftar Produk (FutureBuilder)
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _futureProduk,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Color(0xFFE14B4B)),
                          const SizedBox(height: 12),
                          Text(
                            _formatErrorMessage(snapshot.error!),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF15151A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F6BFF),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                            onPressed: _reload,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final produkList = snapshot.data ?? [];
                if (produkList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.isNotEmpty ||
                                    _selectedKategori != 'Semua'
                                ? 'Tidak ada produk yang sesuai dengan pencarian atau filter.'
                                : 'Belum ada produk yang tersedia di katalog.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty ||
                              _selectedKategori != 'Semua') ...[
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _selectedKategori = 'Semua';
                                  _futureProduk = _fetchData();
                                });
                              },
                              child: const Text('Reset Filter & Pencarian'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 20),
                  itemCount: produkList.length,
                  itemBuilder: (context, index) {
                    final produk = produkList[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0.8,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(
                            color: Color(0xFFE6E6EC), width: 0.8),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProdukDetailPage(produk: produk),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      produk.nama,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15151A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusBadge(produk),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                produk.kategori,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A8A93),
                                ),
                              ),
                              if (produk.deskripsi != null &&
                                  produk.deskripsi!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  produk.deskripsi!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatRupiah(produk.harga),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF15151A),
                                        ),
                                      ),
                                      _buildGrosirPill(produk),
                                    ],
                                  ),
                                  _buildActionButton(produk),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman Detail Produk (ProdukDetailPage)
// Mengambil data real-time via GET /api/produk/{id}
// ---------------------------------------------------------------------------
class ProdukDetailPage extends StatefulWidget {
  final Product produk;
  const ProdukDetailPage({required this.produk, super.key});

  @override
  State<ProdukDetailPage> createState() => _ProdukDetailPageState();
}

class _ProdukDetailPageState extends State<ProdukDetailPage> {
  final LayananApi _api = LayananApi();
  late Future<Product> _futureDetail;
  int _jumlah = 1;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _futureDetail = _api.fetchProdukDetail(widget.produk.id);
  }

  void _reload() {
    setState(() {
      _futureDetail = _api.fetchProdukDetail(widget.produk.id);
    });
  }

  /// Menghitung harga satuan efektif berdasarkan kuantitas stepper
  int _hitungHargaSatuan(Product p, int qty) {
    if (p.hargaGrosir.isEmpty) return p.harga;
    final tiers =
        p.hargaGrosir.where((tier) => tier.minKuantitas <= qty).toList();
    if (tiers.isEmpty) return p.harga;
    tiers.sort((a, b) => b.minKuantitas.compareTo(a.minKuantitas));
    return tiers.first.hargaSatuan;
  }

  /// Kirim penambahan item ke server melalui POST /api/keranjang
  Future<void> _tambahKeKeranjang(Product product) async {
    if (_isAddingToCart) return;

    setState(() {
      _isAddingToCart = true;
    });

    try {
      await _api.addKeranjang(
        produkId: product.id,
        jumlah: _jumlah,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$_jumlah unit "${product.nama}" berhasil dimasukkan ke keranjang.',
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Keranjang',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KeranjangPage()),
              );
            },
          ),
          backgroundColor: const Color(0xFF2E9E5B),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(e.message)),
            ],
          ),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ValidationException catch (e) {
      if (!mounted) return;
      final errorMsg = e.errors.values
          .expand((item) => item is List ? item : [item])
          .join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg.isNotEmpty ? errorMsg : e.message),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on RequestTimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Permintaan ke server melebihi batas waktu (15 detik). Silakan coba lagi.'),
          backgroundColor: Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal terhubung ke server: ${e.message}'),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  Widget _buildDetailBadge(Product p) {
    if (!p.tersedia) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Tidak Tersedia',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
      );
    }
    if (p.preOrder) {
      final estimasi = (p.estimasiTersedia != null &&
              p.estimasiTersedia!.isNotEmpty)
          ? ' · Tiba: ${p.estimasiTersedia}'
          : '';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3D6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0A32E), width: 0.8),
        ),
        child: Text(
          'Pre-Order$estimasi',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF946200),
          ),
        ),
      );
    }
    if (p.stok == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE14B4B), width: 0.8),
        ),
        child: const Text(
          'Stok Habis',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFB42323),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF8EE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Stok Tersedia: ${p.stok} unit',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2E9E5B),
        ),
      ),
    );
  }

  Widget _buildAttributeBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6EC)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2F6BFF)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A93)),
              ),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15151A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.produk.nama),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Keranjang Belanja',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KeranjangPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Product>(
        future: _futureDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Color(0xFFE14B4B)),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal mengambil rincian produk:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF15151A)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F6BFF),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      onPressed: _reload,
                    ),
                  ],
                ),
              ),
            );
          }

          final product = snapshot.data;
          if (product == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 56, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Produk tidak ditemukan di server.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kembali ke Katalog'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Aturan bisnis ketersediaan pemesanan
          final bool canOrder =
              product.tersedia && (product.preOrder || product.stok > 0);
          final int maxBeli = product.preOrder ? 9999 : product.stok;

          final int hargaSatuan = _hitungHargaSatuan(product, _jumlah);
          final int subtotal = hargaSatuan * _jumlah;
          final bool isGrosirActive =
              product.hargaGrosir.isNotEmpty && hargaSatuan < product.harga;

          return Column(
            children: [
              // Konten Detail yang Dapat Digulir
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama & Badge Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.nama,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15151A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildDetailBadge(product),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Kartu Harga Utama
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE6E6EC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Harga Satuan Normal',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF8A8A93)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatRupiah(product.harga),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2F6BFF),
                              ),
                            ),
                            if (isGrosirActive) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF0FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Harga Grosir Aktif: ${_formatRupiah(hargaSatuan)} / pcs untuk $_jumlah item',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2F6BFF),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Grid Atribut Khas Domain
                      Row(
                        children: [
                          Expanded(
                            child: _buildAttributeBox(
                              'Kategori',
                              product.kategori,
                              Icons.category_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAttributeBox(
                              'Stok Fisik',
                              '${product.stok} unit',
                              Icons.inventory_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAttributeBox(
                              'Pre-Order',
                              product.preOrder ? 'Ya' : 'Tidak',
                              Icons.schedule_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAttributeBox(
                              'Status Produk',
                              product.tersedia ? 'Tersedia' : 'Dinonaktifkan',
                              Icons.check_circle_outline,
                            ),
                          ),
                        ],
                      ),

                      // Deskripsi Produk
                      const SizedBox(height: 16),
                      const Text(
                        'Deskripsi Produk',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE6E6EC)),
                        ),
                        child: Text(
                          product.deskripsi != null &&
                                  product.deskripsi!.isNotEmpty
                              ? product.deskripsi!
                              : 'Tidak ada deskripsi untuk produk ini.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF15151A),
                            height: 1.4,
                          ),
                        ),
                      ),

                      // Tabel Tingkat Harga Grosir (jika tersedia)
                      if (product.hargaGrosir.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Tingkat Harga Grosir (Server)',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE6E6EC)),
                          ),
                          child: Column(
                            children: product.hargaGrosir.map((tier) {
                              final bool tierReached =
                                  _jumlah >= tier.minKuantitas;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: tierReached
                                      ? const Color(0xFFF0F5FF)
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                        color: Colors.grey.shade200),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          tierReached
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          size: 16,
                                          color: tierReached
                                              ? const Color(0xFF2F6BFF)
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Beli minimal ${tier.minKuantitas} unit',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: tierReached
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: const Color(0xFF15151A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${_formatRupiah(tier.hargaSatuan)} / unit',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: tierReached
                                            ? const Color(0xFF2F6BFF)
                                            : const Color(0xFF15151A),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bagian Bawah: Quantity Stepper & Tombol Tambah ke Keranjang
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x0D000000),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Baris Quantity Stepper & Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Quantity Stepper
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE6E6EC)),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: (!canOrder || _jumlah <= 1)
                                      ? null
                                      : () {
                                          setState(() {
                                            _jumlah--;
                                          });
                                        },
                                ),
                                Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 36),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$_jumlah',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: (!canOrder || _jumlah >= maxBeli)
                                      ? null
                                      : () {
                                          setState(() {
                                            _jumlah++;
                                          });
                                        },
                                ),
                              ],
                            ),
                          ),

                          // Subtotal Hitungan Real-Time
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Estimasi Subtotal',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF8A8A93)),
                              ),
                              Text(
                                _formatRupiah(subtotal),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15151A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Tombol Tambah ke Keranjang
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !canOrder
                                ? Colors.grey.shade400
                                : (product.preOrder
                                    ? const Color(0xFFE0A32E)
                                    : const Color(0xFF0D0D12)),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: (!canOrder || _isAddingToCart)
                              ? null
                              : () => _tambahKeKeranjang(product),
                          child: _isAddingToCart
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      product.preOrder
                                          ? Icons.schedule
                                          : Icons.add_shopping_cart,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      !product.tersedia
                                          ? 'Produk Tidak Tersedia'
                                          : (product.stok == 0 &&
                                                  !product.preOrder
                                              ? 'Stok Habis'
                                              : (product.preOrder
                                                  ? 'Pesan Pre-Order Sekarang'
                                                  : 'Tambah ke Keranjang')),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Halaman Keranjang Belanja (KeranjangPage) - Tahap 4
// ---------------------------------------------------------------------------
class KeranjangPage extends StatefulWidget {
  const KeranjangPage({super.key});

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  final LayananApi _api = LayananApi();
  late Future<KeranjangData> _futureKeranjang;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _futureKeranjang = _api.fetchKeranjang();
  }

  void _reload() {
    setState(() {
      _futureKeranjang = _api.fetchKeranjang();
    });
  }

  String _formatErrorMessage(Object error) {
    final str = error.toString();
    if (str.contains('SocketException') ||
        str.contains('NetworkException') ||
        str.contains('Failed host lookup') ||
        str.contains('ClientException')) {
      return 'Gagal terhubung ke server ATK Mart.\nPastikan backend Laravel berjalan di http://127.0.0.1:8000.';
    }
    if (str.contains('RequestTimeoutException') || str.contains('15s')) {
      return 'Permintaan ke server melebihi batas waktu (15 detik). Silakan coba lagi.';
    }
    if (str.contains('ApiException')) {
      return str.replaceAll('ApiException:', '').trim();
    }
    return 'Terjadi kendala saat memuat keranjang: $error';
  }

  Future<void> _updateItemQty(CartItem item, int newQty) async {
    if (_isProcessing) return;
    if (newQty <= 0) {
      await _confirmDeleteItem(item);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _api.updateKeranjang(id: item.id, jumlah: newQty);
      _reload();
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ValidationException catch (e) {
      if (!mounted) return;
      final msg = e.errors.values
          .expand((i) => i is List ? i : [i])
          .join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isNotEmpty ? msg : e.message),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on RequestTimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan ubah kuantitas timeout. Coba lagi.'),
          backgroundColor: Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui kuantitas: $e'),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteItem(CartItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text(
          'Hapus "${item.nama}" dari keranjang belanja?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE14B4B),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _api.deleteKeranjang(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item.nama}" telah dihapus dari keranjang.'),
          backgroundColor: const Color(0xFF2E9E5B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus produk: $e'),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Belanja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _isProcessing ? null : _reload,
          ),
        ],
      ),
      body: FutureBuilder<KeranjangData>(
        future: _futureKeranjang,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Color(0xFFE14B4B)),
                    const SizedBox(height: 12),
                    Text(
                      _formatErrorMessage(snapshot.error!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF15151A)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F6BFF),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      onPressed: _reload,
                    ),
                  ],
                ),
              ),
            );
          }

          final cartData = snapshot.data;
          final items = cartData?.items ?? [];

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'Keranjang belanja Anda masih kosong.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15151A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pilih perlengkapan kantor atau alat tulis impian Anda sekarang.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F6BFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Mulai Belanja'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Daftar Item Keranjang
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0.8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                            color: Color(0xFFE6E6EC), width: 0.8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nama,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF15151A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Harga satuan: ${_formatRupiah(item.hargaSatuan)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20, color: Color(0xFFE14B4B)),
                                  tooltip: 'Hapus item',
                                  onPressed: _isProcessing
                                      ? null
                                      : () => _confirmDeleteItem(item),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                // Stepper Kuantitas
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFE6E6EC)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          item.jumlah <= 1
                                              ? Icons.delete_outline
                                              : Icons.remove,
                                          size: 16,
                                          color: item.jumlah <= 1
                                              ? const Color(0xFFE14B4B)
                                              : Colors.black87,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 32, minHeight: 32),
                                        onPressed: _isProcessing
                                            ? null
                                            : () => _updateItemQty(
                                                item, item.jumlah - 1),
                                      ),
                                      Container(
                                        constraints: const BoxConstraints(
                                            minWidth: 32),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${item.jumlah}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add,
                                            size: 16),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 32, minHeight: 32),
                                        onPressed: _isProcessing
                                            ? null
                                            : () => _updateItemQty(
                                                item, item.jumlah + 1),
                                      ),
                                    ],
                                  ),
                                ),

                                // Subtotal per item
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Subtotal',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600),
                                    ),
                                    Text(
                                      _formatRupiah(item.subtotal),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15151A),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bagian Bawah: Total & Lanjut ke Checkout
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Subtotal Server',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A8A93),
                                ),
                              ),
                              Text(
                                _formatRupiah(cartData!.subtotal),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2F6BFF),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D0D12),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: const Text(
                              'Lanjut ke Checkout',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _isProcessing
                                ? null
                                : () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const CheckoutPage(),
                                      ),
                                    );
                                    _reload();
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman Checkout (CheckoutPage) - Tahap 5
// ---------------------------------------------------------------------------
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final LayananApi _api = LayananApi();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _kotaController =
      TextEditingController(text: 'Kota Malang');

  late final String _idempotencyKey;

  late Future<KurirData> _futureKurir;
  WilayahItem? _selectedWilayah;
  KurirItem? _selectedKurir;
  String _metodePembayaran = 'tunai_di_tempat';

  KeranjangData? _ringkasanKeranjang;
  bool _isLoadingSummary = false;
  bool _isSubmitting = false;
  String? _errorSummary;

  @override
  void initState() {
    super.initState();
    // Idempotency key diinisialisasi sekali dan tidak diganti saat retry timeout
    _idempotencyKey = const Uuid().v4();
    _futureKurir = _api.fetchKurir();
    _fetchRingkasanServer();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _kotaController.dispose();
    super.dispose();
  }

  /// Meminta server menghitung ongkos kirim dan total resmi
  Future<void> _fetchRingkasanServer() async {
    setState(() {
      _isLoadingSummary = true;
      _errorSummary = null;
    });

    try {
      final summary = await _api.fetchKeranjang(
        kurirId: _selectedKurir?.id,
        wilayahId: _selectedWilayah?.id,
      );
      if (!mounted) return;
      setState(() {
        _ringkasanKeranjang = summary;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorSummary = 'Gagal memuat rincian biaya dari server: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSummary = false;
        });
      }
    }
  }

  Future<void> _submitCheckout() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedWilayah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih wilayah pengiriman.'),
          backgroundColor: Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedKurir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kurir pengiriman.'),
          backgroundColor: Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_ringkasanKeranjang == null || _ringkasanKeranjang!.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang belanja kosong. Tidak dapat melakukan checkout.'),
          backgroundColor: Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = CheckoutRequest(
        namaPenerima: _namaController.text.trim(),
        alamat: _alamatController.text.trim(),
        kota: _kotaController.text.trim(),
        wilayahId: _selectedWilayah!.id,
        kurirId: _selectedKurir!.id,
        metodePembayaran: _metodePembayaran,
      );

      final order = await _api.checkout(
        request: request,
        idempotencyKey: _idempotencyKey,
      );

      if (!mounted) return;

      // Navigasi ke Halaman Konfirmasi Pesanan
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => KonfirmasiPesananPage(order: order),
        ),
      );
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(e.message)),
            ],
          ),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ValidationException catch (e) {
      if (!mounted) return;
      final msg = e.errors.values
          .expand((item) => item is List ? item : [item])
          .join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isNotEmpty ? msg : e.message),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on RequestTimeoutException {
      if (!mounted) return;
      // Jangan regenerate _idempotencyKey saat timeout retry!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Koneksi melebihi batas waktu (15 detik). Tekan tombol Checkout kembali untuk memeriksa status transaksi Anda.'),
          backgroundColor: Color(0xFFE14B4B),
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal terhubung ke server: ${e.message}'),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat memproses checkout: $e'),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Pesanan'),
      ),
      body: FutureBuilder<KurirData>(
        future: _futureKurir,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Color(0xFFE14B4B)),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat opsi kurir dan wilayah:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF15151A)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _futureKurir = _api.fetchKurir();
                        });
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final kurirData = snapshot.data!;
          final wilayahList = kurirData.wilayah;
          final kurirList = kurirData.kurir;

          return Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Informasi Penerima
                        const Text(
                          'Informasi Penerima & Alamat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15151A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFE6E6EC), width: 0.8),
                          ),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _namaController,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Lengkap Penerima *',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Nama penerima wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _alamatController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Alamat Lengkap Pengiriman *',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Alamat pengiriman wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _kotaController,
                                decoration: const InputDecoration(
                                  labelText: 'Kota Tujuan *',
                                  helperText:
                                      'Pengiriman ATK Mart saat ini khusus area Kota Malang',
                                  prefixIcon: Icon(Icons.location_city_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Kota tujuan wajib diisi';
                                  }
                                  if (!val.toLowerCase().contains('malang')) {
                                    return 'Pengiriman hanya melayani area Kota Malang';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Section 2: Kurir & Wilayah Pengiriman
                        const Text(
                          'Pengiriman & Wilayah (Malang)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15151A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFE6E6EC), width: 0.8),
                          ),
                          child: Column(
                            children: [
                              DropdownButtonFormField<WilayahItem>(
                                initialValue: _selectedWilayah,
                                decoration: const InputDecoration(
                                  labelText: 'Pilih Wilayah / Kecamatan *',
                                  prefixIcon: Icon(Icons.map_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                items: wilayahList.map((w) {
                                  return DropdownMenuItem<WilayahItem>(
                                    value: w,
                                    child: Text('${w.nama} (${w.kota})'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedWilayah = val;
                                  });
                                  _fetchRingkasanServer();
                                },
                                validator: (val) =>
                                    val == null ? 'Wilayah wajib dipilih' : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<KurirItem>(
                                initialValue: _selectedKurir,
                                decoration: const InputDecoration(
                                  labelText: 'Pilih Layanan Kurir *',
                                  prefixIcon: Icon(Icons.local_shipping_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                items: kurirList.map((k) {
                                  return DropdownMenuItem<KurirItem>(
                                    value: k,
                                    child: Text(
                                      k.deskripsi != null &&
                                              k.deskripsi!.isNotEmpty
                                          ? '${k.nama} (${k.deskripsi})'
                                          : k.nama,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedKurir = val;
                                  });
                                  _fetchRingkasanServer();
                                },
                                validator: (val) =>
                                    val == null ? 'Kurir wajib dipilih' : null,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Section 3: Metode Pembayaran
                        const Text(
                          'Metode Pembayaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15151A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFE6E6EC), width: 0.8),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _metodePembayaran = 'tunai_di_tempat';
                                  });
                                },
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _metodePembayaran == 'tunai_di_tempat'
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: _metodePembayaran == 'tunai_di_tempat'
                                            ? const Color(0xFF2F6BFF)
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Tunai di Tempat (COD)',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Bayar langsung secara tunai saat barang diantarkan kurir',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF8A8A93)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _metodePembayaran = 'transfer_manual';
                                  });
                                },
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _metodePembayaran == 'transfer_manual'
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: _metodePembayaran == 'transfer_manual'
                                            ? const Color(0xFF2F6BFF)
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Transfer Bank Manual',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Transfer ke rekening toko dan konfirmasi pembayaran',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF8A8A93)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Section 4: Ringkasan Biaya Server
                        const Text(
                          'Rincian Pembayaran (Dihitung Server)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15151A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFE6E6EC), width: 0.8),
                          ),
                          child: _isLoadingSummary
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _errorSummary != null
                                  ? Text(
                                      _errorSummary!,
                                      style: const TextStyle(
                                          color: Color(0xFFE14B4B),
                                          fontSize: 13),
                                    )
                                  : Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Subtotal Produk',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF8A8A93))),
                                            Text(
                                              _formatRupiah(
                                                  _ringkasanKeranjang?.subtotal ??
                                                      0),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF15151A),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Ongkos Kirim',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF8A8A93))),
                                            Text(
                                              _ringkasanKeranjang?.ongkosKirim !=
                                                      null
                                                  ? _formatRupiah(
                                                      _ringkasanKeranjang!
                                                          .ongkosKirim!)
                                                  : (_selectedWilayah != null &&
                                                          _selectedKurir !=
                                                              null
                                                      ? 'Memuat...'
                                                      : 'Pilih kurir & wilayah'),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _ringkasanKeranjang
                                                            ?.ongkosKirim !=
                                                        null
                                                    ? const Color(0xFF15151A)
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 20),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total Tagihan',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF15151A),
                                              ),
                                            ),
                                            Text(
                                              _formatRupiah(
                                                _ringkasanKeranjang?.total ??
                                                    _ringkasanKeranjang
                                                        ?.subtotal ??
                                                    0,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2F6BFF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tombol Buat Pesanan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 10,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D0D12),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submitCheckout,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Buat Pesanan Sekarang',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman Konfirmasi Pesanan (KonfirmasiPesananPage) - Pasca Checkout
// ---------------------------------------------------------------------------
class KonfirmasiPesananPage extends StatelessWidget {
  final Order order;
  const KonfirmasiPesananPage({required this.order, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Berhasil'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF8EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2E9E5B),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Terima Kasih!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15151A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pesanan Anda telah berhasil dibuat dan diteruskan ke pihak toko.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),

              // Rincian Kartu Pesanan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFE6E6EC), width: 0.8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nomor Pesanan',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF8A8A93)),
                        ),
                        SelectableText(
                          order.nomorPesanan,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2F6BFF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status Pesanan',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF8A8A93)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3D6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFFE0A32E), width: 0.8),
                          ),
                          child: Text(
                            order.status.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF946200),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal Produk',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF8A8A93)),
                        ),
                        Text(
                          _formatRupiah(order.subtotal),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ongkos Kirim',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF8A8A93)),
                        ),
                        Text(
                          _formatRupiah(order.ongkosKirim),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15151A),
                          ),
                        ),
                        Text(
                          _formatRupiah(order.total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2F6BFF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D0D12),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_outlined),
                  label: const Text(
                    'Lihat Rincian Pesanan Ini',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RincianPesananPage(
                          pesananId: order.id,
                          nomorPesanan: order.nomorPesanan,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2F6BFF),
                    side: const BorderSide(color: Color(0xFF2F6BFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text(
                    'Buka Riwayat Pesanan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiwayatPesananPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton.icon(
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text(
                    'Kembali ke Katalog Produk',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Helper Badge Status Pesanan
// ---------------------------------------------------------------------------
Widget _buildOrderStatusBadge(String status) {
  Color bg;
  Color border;
  Color text;
  String label = status.replaceAll('_', ' ').toUpperCase();

  switch (status.toLowerCase()) {
    case 'menunggu_konfirmasi':
      bg = const Color(0xFFFFF3D6);
      border = const Color(0xFFE0A32E);
      text = const Color(0xFF946200);
      label = 'MENUNGGU KONFIRMASI';
      break;
    case 'diproses':
      bg = const Color(0xFFEAF0FF);
      border = const Color(0xFF2F6BFF);
      text = const Color(0xFF2F6BFF);
      label = 'DIPROSES';
      break;
    case 'dikirim':
      bg = const Color(0xFFF2E7FE);
      border = const Color(0xFF9C27B0);
      text = const Color(0xFF7B1FA2);
      label = 'DIKIRIM';
      break;
    case 'selesai':
      bg = const Color(0xFFEBF8EE);
      border = const Color(0xFF2E9E5B);
      text = const Color(0xFF2E9E5B);
      label = 'SELESAI';
      break;
    case 'dibatalkan':
      bg = const Color(0xFFFFEBEB);
      border = const Color(0xFFE14B4B);
      text = const Color(0xFFB42323);
      label = 'DIBATALKAN';
      break;
    default:
      bg = Colors.grey.shade100;
      border = Colors.grey.shade400;
      text = Colors.grey.shade800;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: border, width: 0.8),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: text,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Halaman Riwayat Pesanan (RiwayatPesananPage) - Tahap 6
// GET /api/pesanan
// ---------------------------------------------------------------------------
class RiwayatPesananPage extends StatefulWidget {
  const RiwayatPesananPage({super.key});

  @override
  State<RiwayatPesananPage> createState() => _RiwayatPesananPageState();
}

class _RiwayatPesananPageState extends State<RiwayatPesananPage> {
  final LayananApi _api = LayananApi();
  late Future<List<Order>> _futurePesanan;

  @override
  void initState() {
    super.initState();
    _futurePesanan = _api.fetchPesanan();
  }

  void _reload() {
    setState(() {
      _futurePesanan = _api.fetchPesanan();
    });
  }

  String _formatErrorMessage(Object error) {
    final str = error.toString();
    if (str.contains('SocketException') ||
        str.contains('NetworkException') ||
        str.contains('Failed host lookup') ||
        str.contains('ClientException')) {
      return 'Gagal terhubung ke server ATK Mart.\nPastikan backend Laravel berjalan di http://127.0.0.1:8000.';
    }
    if (str.contains('RequestTimeoutException') || str.contains('15s')) {
      return 'Permintaan ke server melebihi batas waktu (15 detik). Silakan coba lagi.';
    }
    if (str.contains('ApiException')) {
      return str.replaceAll('ApiException:', '').trim();
    }
    return 'Terjadi kendala saat memuat riwayat pesanan: $error';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: _futurePesanan,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Color(0xFFE14B4B)),
                    const SizedBox(height: 12),
                    Text(
                      _formatErrorMessage(snapshot.error!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF15151A)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F6BFF),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      onPressed: _reload,
                    ),
                  ],
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum Ada Riwayat Pesanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15151A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pesanan yang Anda buat akan tercatat dan ditampilkan di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F6BFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Mulai Belanja'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                color: Colors.white,
                elevation: 0.8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(
                      color: Color(0xFFE6E6EC), width: 0.8),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RincianPesananPage(
                          pesananId: order.id,
                          nomorPesanan: order.nomorPesanan,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Baris 1: Nomor Pesanan & Badge Status
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.nomorPesanan,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15151A),
                                    ),
                                  ),
                                  if (order.createdAt != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      order.createdAt!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildOrderStatusBadge(order.status),
                          ],
                        ),

                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Baris 2: Rincian Singkat (Jumlah Item, Kurir, Total)
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if (order.jumlahItem != null)
                                  Text(
                                    '${order.jumlahItem} Produk dibeli',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                if (order.kurir != null)
                                  Text(
                                    'Kurir: ${order.kurir}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Total Tagihan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8A8A93),
                                  ),
                                ),
                                Text(
                                  _formatRupiah(order.total),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2F6BFF),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Tombol Lihat Rincian Kecil
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lihat Rincian',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman Rincian Pesanan (RincianPesananPage) - Tahap 6
// GET /api/pesanan/{id}
// ---------------------------------------------------------------------------
class RincianPesananPage extends StatefulWidget {
  final int pesananId;
  final String nomorPesanan;

  const RincianPesananPage({
    required this.pesananId,
    required this.nomorPesanan,
    super.key,
  });

  @override
  State<RincianPesananPage> createState() => _RincianPesananPageState();
}

class _RincianPesananPageState extends State<RincianPesananPage> {
  final LayananApi _api = LayananApi();
  late Future<Order> _futureDetail;

  @override
  void initState() {
    super.initState();
    _futureDetail = _api.fetchPesananDetail(widget.pesananId);
  }

  void _reload() {
    setState(() {
      _futureDetail = _api.fetchPesananDetail(widget.pesananId);
    });
  }

  String _formatErrorMessage(Object error) {
    final str = error.toString();
    if (str.contains('SocketException') ||
        str.contains('NetworkException') ||
        str.contains('Failed host lookup') ||
        str.contains('ClientException')) {
      return 'Gagal terhubung ke server ATK Mart.\nPastikan backend Laravel berjalan di http://127.0.0.1:8000.';
    }
    if (str.contains('RequestTimeoutException') || str.contains('15s')) {
      return 'Permintaan ke server melebihi batas waktu (15 detik). Silakan coba lagi.';
    }
    if (str.contains('404')) {
      return 'Pesanan dengan ID #${widget.pesananId} tidak ditemukan di server.';
    }
    if (str.contains('403')) {
      return 'Akses ditolak: Anda tidak memiliki wewenang untuk melihat pesanan ini.';
    }
    if (str.contains('ApiException')) {
      return str.replaceAll('ApiException:', '').trim();
    }
    return 'Terjadi kendala saat memuat rincian pesanan: $error';
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E6EC), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2F6BFF)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15151A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nomorPesanan),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<Order>(
        future: _futureDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Color(0xFFE14B4B)),
                    const SizedBox(height: 12),
                    Text(
                      _formatErrorMessage(snapshot.error!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF15151A)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F6BFF),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      onPressed: _reload,
                    ),
                  ],
                ),
              ),
            );
          }

          final order = snapshot.data;
          if (order == null) {
            return const Center(
              child: Text('Data pesanan tidak tersedia.'),
            );
          }

          final items = order.items ?? [];
          final histories = order.riwayatStatus ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Kartu Ringkasan Status
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFE6E6EC), width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status Pesanan',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8A8A93),
                            ),
                          ),
                          _buildOrderStatusBadge(order.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nomor Pesanan',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8A8A93),
                            ),
                          ),
                          SelectableText(
                            order.nomorPesanan,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2F6BFF),
                            ),
                          ),
                        ],
                      ),
                      if (order.createdAt != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Waktu Pemesanan',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A8A93),
                              ),
                            ),
                            Text(
                              order.createdAt!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF15151A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Kartu Daftar Produk (Snapshot Harga & Item)
                _buildSectionCard(
                  title: 'Daftar Produk (${items.length} macam)',
                  icon: Icons.inventory_2_outlined,
                  child: Column(
                    children: items.map((item) {
                      final hasDiscount =
                          item.hargaSatuan < item.hargaNormal;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade100,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.namaProduk,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15151A),
                                    ),
                                  ),
                                  if (item.menungguStok) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3D6),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        border: Border.all(
                                            color:
                                                const Color(0xFFE0A32E),
                                            width: 0.6),
                                      ),
                                      child: const Text(
                                        'Pre-Order (Menunggu Stok)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF946200),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${item.jumlah} × ${_formatRupiah(item.hargaSatuan)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      if (hasDiscount) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatRupiah(item.hargaNormal),
                                          style: TextStyle(
                                            fontSize: 11,
                                            decoration: TextDecoration
                                                .lineThrough,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatRupiah(item.subtotal),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15151A),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Kartu Informasi Pengiriman
                _buildSectionCard(
                  title: 'Informasi Pengiriman',
                  icon: Icons.local_shipping_outlined,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Text(
                              'Penerima',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A8A93),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              order.namaPenerima ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF15151A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Text(
                              'Alamat Lengkap',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A8A93),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              order.alamat ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF15151A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Text(
                              'Wilayah / Kota',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A8A93),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              [
                                if (order.wilayah != null &&
                                    order.wilayah!.isNotEmpty)
                                  order.wilayah,
                                if (order.kota != null &&
                                    order.kota!.isNotEmpty)
                                  order.kota,
                              ].join(', '),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF15151A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Text(
                              'Layanan Kurir',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A8A93),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              order.kurir ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF15151A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Kartu Rincian Pembayaran
                _buildSectionCard(
                  title: 'Rincian Pembayaran',
                  icon: Icons.receipt_outlined,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Metode Pembayaran',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8A8A93),
                            ),
                          ),
                          Text(
                            (order.metodePembayaran ?? '-')
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF15151A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal Produk',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8A8A93),
                            ),
                          ),
                          Text(
                            _formatRupiah(order.subtotal),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF15151A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ongkos Kirim',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8A8A93),
                            ),
                          ),
                          Text(
                            _formatRupiah(order.ongkosKirim),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF15151A),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15151A),
                            ),
                          ),
                          Text(
                            _formatRupiah(order.total),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2F6BFF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 5. Kartu Riwayat Status (Perubahan Status)
                if (histories.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Riwayat Status Transaksi',
                    icon: Icons.timeline_outlined,
                    child: Column(
                      children: histories.map((h) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2F6BFF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          h.statusBaru
                                              .replaceAll('_', ' ')
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF15151A),
                                          ),
                                        ),
                                        if (h.createdAt != null)
                                          Text(
                                            h.createdAt!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Aktor: ${h.aktor}${h.catatan != null && h.catatan!.isNotEmpty ? ' (${h.catatan})' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
