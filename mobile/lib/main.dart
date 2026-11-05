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
    // Sesuai aturan PRD BR-01..BR-03:
    // tersedia=false -> tidak boleh dibeli
    // preOrder=true -> tetap boleh dibeli walau stok=0
    // non-preOrder & stok=0 -> stok habis, tidak boleh dibeli
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
// Product detail page (placeholder)
// ---------------------------------------------------------------------------
class ProdukDetailPage extends StatelessWidget {
  final Product produk;
  const ProdukDetailPage({required this.produk, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(produk.nama)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(produk.nama,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Kategori: ${produk.kategori}'),
            Text('Harga: ${_formatRupiah(produk.harga)}'),
            Text('Stok: ${produk.stok}'),
            if (produk.deskripsi != null) ...[
              const SizedBox(height: 8),
              Text(produk.deskripsi!),
            ],
            if (produk.hargaGrosir.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Harga Grosir:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...produk.hargaGrosir.map(
                (tier) => Text(
                    '  ≥ ${tier.minKuantitas} pcs → ${_formatRupiah(tier.hargaSatuan)}/pcs'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
