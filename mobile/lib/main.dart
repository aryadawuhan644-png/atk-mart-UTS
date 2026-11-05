// lib/main.dart
// Entry point for ATK Mart mobile app.
// Uses only setState, Navigator, and callbacks (no Provider/Riverpod/Bloc).

import 'package:flutter/material.dart';

import 'api/api_config.dart';
import 'api/layanan_api.dart';
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
          backgroundColor: const Color(0xFF2E9E5B),
          duration: const Duration(seconds: 3),
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
