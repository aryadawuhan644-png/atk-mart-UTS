// lib/main.dart
// Entry point for ATK Mart mobile app.
// Uses only setState, Navigator, and callbacks (no Provider/Riverpod/Bloc).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'admin_preferences.dart';
import 'admin_profile_settings.dart';
import 'api/api_config.dart';
import 'api/layanan_api.dart';

import 'package:uuid/uuid.dart';

import 'api/models/cart_item.dart';
import 'api/models/checkout_request.dart';
import 'api/models/kurir.dart';
import 'api/models/order.dart';
import 'api/models/product.dart';
import 'core/motion.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initLocalConfig();
  await AdminPreferences.initialize();
  runApp(const AtkMartApp());
}

// ---------------------------------------------------------------------------
// Model & Sesi Akun Demo
// ---------------------------------------------------------------------------
class DemoAccount {
  final String id;
  final String nama;
  final String subNama;
  final String email;
  final String token;
  final String role; // 'pembeli' or 'pengelola'
  final String deskripsi;
  final IconData icon;
  final Color color;

  String get namaPelanggan {
    final idx = subNama.indexOf('(');
    if (idx != -1) return subNama.substring(0, idx).trim();
    return subNama;
  }

  String get idPelanggan {
    final start = subNama.indexOf('(');
    final end = subNama.indexOf(')');
    if (start != -1 && end != -1 && end > start) {
      return subNama.substring(start + 1, end).trim();
    }
    final match = RegExp(r'#\d+').firstMatch(subNama);
    if (match != null) return match.group(0)!;
    return id;
  }

  const DemoAccount({
    required this.id,
    required this.nama,
    required this.subNama,
    required this.email,
    required this.token,
    required this.role,
    required this.deskripsi,
    required this.icon,
    required this.color,
  });

  static const DemoAccount pembeli1 = DemoAccount(
    id: 'pembeli_1',
    nama: 'Pembeli 1',
    subNama: 'Pelanggan Demo Utama (ID #1)',
    email: 'pembeli1@atkmart.id',
    token: ApiConfig.tokenPembeli1Statis,
    role: 'pembeli',
    deskripsi: 'Akun pelanggan utama untuk keranjang belanja, checkout, dan riwayat pesanan mandiri.',
    icon: Icons.person_rounded,
    color: Color(0xFF2F6BFF),
  );

  static const DemoAccount pembeli2 = DemoAccount(
    id: 'pembeli_2',
    nama: 'Pembeli 2',
    subNama: 'Pelanggan Demo Kedua (ID #2)',
    email: 'pembeli2@atkmart.id',
    token: ApiConfig.tokenPembeli2Statis,
    role: 'pembeli',
    deskripsi: 'Akun pelanggan terpisah total untuk membuktikan isolasi data keranjang & pesanan antar pelanggan.',
    icon: Icons.person_outline_rounded,
    color: Color(0xFF8E44AD),
  );

  static const DemoAccount pengelola = DemoAccount(
    id: 'pengelola',
    nama: 'Pengelola Toko',
    subNama: 'Administrator ATK Mart',
    email: 'admin@atkmart.id',
    token: ApiConfig.tokenPengelolaStatis,
    role: 'pengelola',
    deskripsi: 'Akses penuh untuk konfirmasi stok, verifikasi pembayaran/COD, dan kelola katalog produk.',
    icon: Icons.admin_panel_settings_rounded,
    color: Color(0xFFD97706),
  );

  static const List<DemoAccount> buyers = [pembeli1, pembeli2];
}

class SessionPengguna {
  static DemoAccount? _currentAccount;

  static DemoAccount? get currentAccount => _currentAccount;
  static bool get isLoggedIn => _currentAccount != null;
  static bool get isPengelola => _currentAccount?.role == 'pengelola';

  static void login(DemoAccount account) {
    _currentAccount = account;
    ApiConfig.setDemoSession(token: account.token, role: account.role);
    AlamatTersimpan.reset();
    if (account.role == 'pembeli') {
      StateKeranjang.refresh();
    } else {
      StateKeranjang.reset();
    }
  }

  static void logout() {
    _currentAccount = null;
    ApiConfig.clearDemoSession();
    AlamatTersimpan.reset();
    StateKeranjang.reset();
  }
}

// ---------------------------------------------------------------------------
// Halaman Login Demo
// ---------------------------------------------------------------------------
class LoginDemoPage extends StatefulWidget {
  const LoginDemoPage({super.key});

  @override
  State<LoginDemoPage> createState() => _LoginDemoPageState();
}

class _LoginDemoPageState extends State<LoginDemoPage> {
  String? _selectedAccountId;

  void _pilihAkun(DemoAccount account) async {
    setState(() => _selectedAccountId = account.id);
    await Future.delayed(const Duration(milliseconds: 120));
    SessionPengguna.login(account);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => account.role == 'pengelola'
            ? const AdminDashboardPage()
            : const PembeliShellPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // Logo & Badge Demo
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF172554),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF172554).withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'ATK Mart',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Color(0xFF172554),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_person_outlined,
                        size: 13,
                        color: Color(0xFF2563EB),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'MODE DEMO PENGUJIAN',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Akun Demo Pembeli',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172554),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih akun untuk menguji isolasi data keranjang, checkout, dan riwayat pesanan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),

              // Kartu Akun Pembeli 1
              _buildAccountCard(
                context,
                account: DemoAccount.pembeli1,
                badgeLabel: 'PELANGGAN UTAMA',
                bulletPoints: const [
                  'ID Pelanggan #1 di server Laravel',
                  'Memiliki keranjang & riwayat pesanan mandiri',
                  'Simulasi pembayaran Transfer Bank & COD',
                ],
              ),
              const SizedBox(height: 14),

              // Kartu Akun Pembeli 2
              _buildAccountCard(
                context,
                account: DemoAccount.pembeli2,
                badgeLabel: 'PELANGGAN KEDUA',
                bulletPoints: const [
                  'ID Pelanggan #2 di server Laravel',
                  'Isolasi penuh: data tidak tercampur dengan Pembeli 1',
                  'Keranjang dan transaksi terpisah seutuhnya',
                ],
              ),
              const SizedBox(height: 20),

              // Opsi Akses Pengelola (Opsional untuk testing Paket B)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mode Pengelola Toko',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF172554),
                            ),
                          ),
                          Text(
                            'Kelola pesanan masuk & produk katalog',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD97706),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _pilihAkun(DemoAccount.pengelola),
                      child: const Text(
                        'Masuk Admin',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Footer Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 15,
                      color: Color(0xFF6B7280),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mode demo menggunakan header Bearer Token statis sesuai aturan backend Laravel. Data tetap terisolasi di sisi server.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context, {
    required DemoAccount account,
    required String badgeLabel,
    required List<String> bulletPoints,
  }) {
    final isLoading = _selectedAccountId == account.id;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: account.color.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: account.color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : () => _pilihAkun(account),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: account.color.withValues(alpha: 0.12),
                      child: Icon(account.icon, size: 22, color: account.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                account.nama,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF172554),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: account.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badgeLabel,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: account.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            account.subNama,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Token Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.key_rounded,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          account.token,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Bullets
                ...bulletPoints.map(
                  (pt) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: account.color,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            pt,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: account.color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login_rounded, size: 16),
                    label: Text(
                      'Masuk sebagai ${account.nama}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: isLoading ? null : () => _pilihAkun(account),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AtkMartApp extends StatelessWidget {
  const AtkMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AdminPreferences.themeMode,
      builder: (context, themeMode, _) => MaterialApp(
        title: 'ATK Mart',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF60A5FA),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF111827),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            iconTheme: IconThemeData(color: Colors.white),
          ),
        ),
        themeMode: themeMode,
        home: SessionPengguna.isLoggedIn
            ? (SessionPengguna.isPengelola
                  ? const AdminDashboardPage()
                  : const PembeliShellPage())
            : const LoginDemoPage(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard Utama Pengelola / Admin (AdminDashboardPage)
// Khusus operasional toko: hanya menampilkan Kelola Produk dan Kelola Pesanan.
// ---------------------------------------------------------------------------
class AdminDashboardPage extends StatefulWidget {
  final LayananApi? api;
  final bool loadStats;
  const AdminDashboardPage({super.key, this.api, this.loadStats = true});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final LayananApi _api = widget.api ?? LayananApi();
  int _countPesananMasuk = 0;
  int _countProduk = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.loadStats) {
      _fetchStats();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchStats() async {
    try {
      final ordersFuture = _api.fetchPesananPengelola();
      final produkFuture = _api.fetchProduk();
      final results = await Future.wait([ordersFuture, produkFuture]);
      if (mounted) {
        setState(() {
          _countPesananMasuk = (results[0] as List<Order>).length;
          _countProduk = (results[1] as List<Product>).length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openAdminSettings(DemoAccount account) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProfileSettingsPage(
          initialName: account.nama,
          email: account.email,
          onLogout: () => _confirmLogout(context),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _confirmLogout(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Mode Pengelola'),
        content: const Text(
          'Keluar dari sesi Pengelola Toko dan kembali ke halaman Login Demo?',
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
            child: const Text('Keluar'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        SessionPengguna.logout();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginDemoPage()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = SessionPengguna.currentAccount ?? DemoAccount.pengelola;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Dashboard Pengelola',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchStats();
            },
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined),
            tooltip: 'Profil & Pengaturan',
            onPressed: () => _openAdminSettings(account),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar / Ganti Akun',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Identitas Pengelola
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.outlineVariant, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF172554).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFFEF3C7),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 28,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AdminPreferences.profileName ?? account.nama,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          account.subNama,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(
                        color: Color(0xFFFECACA),
                        width: 1,
                      ),
                      backgroundColor: const Color(0xFFFEF2F2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.logout, size: 14),
                    label: const Text(
                      'Keluar',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Menu Operasional Toko',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172554),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kelola katalog barang dan pantau seluruh transaksi pesanan masuk.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            // Menu 1: Kelola Produk
            _buildAdminMenuCard(
              context,
              title: 'Kelola Produk',
              subtitle: 'Tambah produk baru, ubah harga satuan & grosir, sesuaikan stok ATK, dan konfigurasi ketersediaan pre-order.',
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFFD97706),
              countLabel: _isLoading ? null : '$_countProduk Produk Terdaftar',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KelolaProdukPage()),
                ).then((_) => _fetchStats());
              },
            ),
            const SizedBox(height: 16),

            // Menu 2: Kelola Pesanan
            _buildAdminMenuCard(
              context,
              title: 'Kelola Pesanan',
              subtitle: 'Konfirmasi stok pre-order, verifikasi pembayaran/COD, dan perbarui tahapan proses pesanan masuk.',
              icon: Icons.assignment_rounded,
              color: const Color(0xFF2563EB),
              countLabel: _isLoading
                  ? null
                  : '$_countPesananMasuk Pesanan Masuk',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KelolaPesananPage()),
                ).then((_) => _fetchStats());
              },
            ),
            const SizedBox(height: 24),

            _buildAdminMenuCard(
              context,
              title: 'Profil & Pengaturan',
              subtitle:
                  'Kelola profil admin, tema, notifikasi, dan informasi akun.',
              icon: Icons.manage_accounts_rounded,
              color: const Color(0xFF0F766E),
              onTap: () => _openAdminSettings(account),
            ),
            const SizedBox(height: 24),

            // Info Box Admin
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: Color(0xFF1D4ED8),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mode Pengelola: Akses administratif menggunakan token pengelola. Seluruh aksi konfirmasi pembayaran dan perubahan stok langsung tersinkronisasi ke server Laravel.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E40AF),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? countLabel,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172554).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                      if (countLabel != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          countLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12.5, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
// Format pesan kesalahan yang ramah pengguna dan bebas exception mentah
// ---------------------------------------------------------------------------
String formatAppErrorMessage(Object error) {
  if (error is NetworkException) {
    return 'Gagal terhubung ke server ATK Mart Aoen.\nPastikan backend Laravel berjalan dan koneksi internet aktif.';
  }
  if (error is RequestTimeoutException) {
    return 'Permintaan ke server melebihi batas waktu (15 detik). Silakan coba lagi.';
  }
  if (error is UnauthorizedException) {
    return 'Sesi tidak sah. Token autentikasi tidak valid atau belum diatur.';
  }
  if (error is ForbiddenException) {
    return 'Akses ditolak: Anda tidak memiliki wewenang untuk tindakan ini.';
  }
  if (error is NotFoundException) {
    return 'Data yang diminta tidak ditemukan di server (404).';
  }
  if (error is ServerException) {
    return 'Terjadi kendala pada server (500). Silakan coba beberapa saat lagi.';
  }
  if (error is ConflictException) {
    final msg = error.message.trim();
    if (msg.toLowerCase().contains('stok')) {
      return 'Stok produk tidak mencukupi untuk memenuhi pesanan Anda.';
    }
    if (msg.toLowerCase().contains('transisi status')) {
      return 'Status pesanan tidak dapat diubah pada tahap ini.';
    }
    return msg.isNotEmpty
        ? msg
        : 'Terjadi konflik data pada pesanan atau stok.';
  }
  if (error is ValidationException) {
    if (error.errors.isNotEmpty) {
      final detail = error.errors.values
          .expand((item) => item is List ? item : [item])
          .join('\n');
      return detail.isNotEmpty ? detail : error.message;
    }
    return error.message.isNotEmpty
        ? error.message
        : 'Data yang dimasukkan tidak valid. Mohon periksa kembali formulir.';
  }
  if (error is ApiException) {
    final clean = error.message.replaceAll('ApiException:', '').trim();
    return clean.isNotEmpty ? clean : 'Terjadi kesalahan pada layanan API.';
  }

  final str = error.toString();
  if (str.contains('SocketException') ||
      str.contains('NetworkException') ||
      str.contains('Failed host lookup') ||
      str.contains('ClientException') ||
      str.contains('Connection refused')) {
    return 'Gagal terhubung ke server ATK Mart.\nPastikan backend Laravel berjalan di http://127.0.0.1:8000.';
  }
  if (str.contains('RequestTimeoutException') ||
      str.contains('TimeoutException') ||
      str.contains('15s')) {
    return 'Permintaan ke server melebihi batas waktu (15 detik). Silakan coba lagi.';
  }
  if (str.contains('401') || str.contains('Unauthorized')) {
    return 'Sesi tidak sah. Token autentikasi tidak valid atau belum diatur.';
  }
  if (str.contains('403') || str.contains('Forbidden')) {
    return 'Akses ditolak: Anda tidak memiliki wewenang untuk tindakan ini.';
  }
  if (str.contains('404')) {
    return 'Data yang diminta tidak ditemukan di server (404).';
  }
  if (str.contains('500') || str.contains('ServerException')) {
    return 'Terjadi kendala pada server (500). Silakan coba beberapa saat lagi.';
  }
  if (str.contains('Token autentikasi belum dikonfigurasi') ||
      str.contains('Token pengelola belum dikonfigurasi')) {
    return 'Token autentikasi belum diatur. Pastikan file konfigurasi token sudah diisi.';
  }

  final cleaned = str
      .replaceAll(
        RegExp(
          r'^(Exception|Error|ApiException|ServerException|ClientException):\s*',
        ),
        '',
      )
      .trim();

  if (cleaned.contains('FormatException') ||
      cleaned.contains('TypeError') ||
      cleaned.contains('NoSuchMethodError') ||
      cleaned.contains('Null check operator') ||
      cleaned.isEmpty) {
    return 'Terjadi kendala saat memproses permintaan. Silakan coba beberapa saat lagi.';
  }

  return cleaned;
}

/// Notifier global untuk sinkronisasi pembaruan data & gambar produk secara instan
/// antara tampilan pengelola/admin dan pembeli.
final ValueNotifier<int> produkUpdateNotifier = ValueNotifier<int>(0);

/// Resolusi URL gambar produk dari API lokal/remote.
/// Menangani path relatif, pemetaan localhost/127.0.0.1/10.0.2.2 ke host dan port
/// aktif ApiConfig.baseUrl (misal 127.0.0.1:8000), serta nilai null/kosong.
String? resolveImageUrl(String? rawUrl) {
  if (rawUrl == null || rawUrl.trim().isEmpty) return null;
  final trimmed = rawUrl.trim();
  try {
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final targetScheme = baseUri.scheme.isNotEmpty ? baseUri.scheme : 'http';
    final targetHost = baseUri.host.isNotEmpty ? baseUri.host : '127.0.0.1';
    final targetPort = baseUri.hasPort
        ? baseUri.port
        : (targetHost == '127.0.0.1' ||
                  targetHost == 'localhost' ||
                  targetHost == '10.0.2.2'
              ? 8000
              : null);

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final imgUri = Uri.parse(trimmed);
      final isBackendPath =
          imgUri.path.contains('/api/produk/') ||
          imgUri.path.startsWith('/storage/');
      final isLocalOrPrivate =
          imgUri.host == 'localhost' ||
          imgUri.host == '127.0.0.1' ||
          imgUri.host == '10.0.2.2' ||
          imgUri.host.startsWith('192.168.') ||
          imgUri.host.startsWith('172.') ||
          imgUri.host.startsWith('10.') ||
          imgUri.host == targetHost;

      if (isBackendPath || isLocalOrPrivate) {
        return imgUri
            .replace(scheme: targetScheme, host: targetHost, port: targetPort)
            .toString();
      }
      return trimmed;
    }

    // Path relatif dari server (misal: /storage/produk/abc.jpg)
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    final authority = targetPort != null
        ? '$targetHost:$targetPort'
        : targetHost;
    return '$targetScheme://$authority$path';
  } catch (_) {
    return trimmed;
  }
}

/// Widget untuk menampilkan gambar produk dari URL dengan placeholder otomatis
/// jika gambar belum tersedia atau gagal dimuat dari server.
class ProdukImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final IconData placeholderIcon;
  final String? heroTag;

  const ProdukImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.inventory_2_outlined,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);
    final resolved = resolveImageUrl(imageUrl);

    Widget placeholder() {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F7),
          borderRadius: radius,
          border: Border.all(color: const Color(0xFFE6E6EC), width: 0.8),
        ),
        alignment: Alignment.center,
        child: Icon(
          placeholderIcon,
          size: (height != null && height! < 70) ? 24 : 36,
          color: const Color(0xFF8A8A93),
        ),
      );
    }

    Widget content;
    if (resolved == null || resolved.isEmpty) {
      content = placeholder();
    } else {
      content = ValueListenableBuilder<int>(
        valueListenable: produkUpdateNotifier,
        builder: (context, tick, _) {
          final cacheKey = tick > 0 ? '$resolved?v=$tick' : resolved;
          return ClipRRect(
            borderRadius: radius,
            child: Image.network(
              cacheKey,
              key: ValueKey(cacheKey),
              width: width,
              height: height,
              fit: fit,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return placeholder();
              },
              errorBuilder: (context, error, stackTrace) => placeholder(),
            ),
          );
        },
      );
    }

    if (heroTag != null && !MotionConstants.animationsDisabled(context)) {
      return Hero(
        tag: heroTag!,
        child: Material(color: Colors.transparent, child: content),
      );
    }

    return content;
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  final VoidCallback? onTap;
  final bool isAdded;
  final int? originalPrice;

  const ProductCard({
    required this.product,
    required this.onAdd,
    this.onTap,
    this.isAdded = false,
    this.originalPrice,
    super.key,
  });

  bool get _canBuy =>
      product.tersedia && (product.preOrder || product.stok > 0);

  @override
  Widget build(BuildContext context) {
    final isDiscounted =
        originalPrice != null && originalPrice! > product.harga;
    final isLowStock =
        product.tersedia &&
        !product.preOrder &&
        product.stok > 0 &&
        product.stok <= 3;

    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.grey[200],
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProdukImageWidget(
                      imageUrl: product.gambar,
                      borderRadius: BorderRadius.circular(8),
                      heroTag: 'product-img-${product.id}',
                    ),
                    if (isLowStock || !_canBuy)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _ProductStatusBadge(
                          label: !_canBuy
                              ? (product.tersedia
                                    ? 'Stok Habis'
                                    : 'Tidak Tersedia')
                              : 'Sisa ${product.stok}',
                          color: const Color(0xFFEF4444),
                        ),
                      )
                    else if (product.preOrder)
                      const Positioned(
                        top: 8,
                        left: 8,
                        child: _ProductStatusBadge(
                          label: 'Pre-Order',
                          color: Color(0xFFD97706),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.kategori,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.nama,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF172554),
                ),
              ),
              const SizedBox(height: 8),
              if (isDiscounted)
                Text(
                  _formatRupiah(originalPrice!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                _formatRupiah(product.harga),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172554),
                ),
              ),
              if (product.hargaGrosir.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _wholesalePriceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _canBuy ? onAdd : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: isAdded
                        ? const Color(0xFF059669)
                        : const Color(0xFF172554),
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _canBuy
                            ? (isAdded
                                  ? Icons.check_rounded
                                  : Icons.add_shopping_cart_rounded)
                            : Icons.remove_shopping_cart_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _canBuy ? 'Tambah ke Keranjang' : 'Stok Habis',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }

  String get _wholesalePriceLabel {
    final tier = product.hargaGrosir.reduce(
      (a, b) => a.minKuantitas < b.minKuantitas ? a : b,
    );
    return 'Grosir mulai ${tier.minKuantitas} pcs';
  }
}

class _ProductStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ProductStatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shell Navigasi Pembeli (PembeliShellPage)
// Menyatukan Katalog, Pesanan Saya, dan Riwayat dalam bottom bar.
// Akses keranjang tersedia melalui ikon di AppBar tiap halaman.
// ---------------------------------------------------------------------------
class PembeliShellPage extends StatefulWidget {
  const PembeliShellPage({super.key});

  @override
  State<PembeliShellPage> createState() => _PembeliShellPageState();
}

class _PembeliShellPageState extends State<PembeliShellPage> {
  int _currentIndex = 0;
  final Set<int> _visited = {0};
  final List<int> _refreshTicks = [0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    StateKeranjang.refresh();
  }

  void _onDestinationSelected(int index) {
    setState(() {
      if (index == _currentIndex) {
        // Tap ulang tab aktif berfungsi sebagai muat ulang data.
        _refreshTicks[index]++;
      }
      _currentIndex = index;
      _visited.add(index);
    });
  }

  Widget _buildTab(int index) {
    if (!_visited.contains(index)) {
      return const SizedBox.shrink();
    }
    final key = ValueKey('pembeli-tab-$index-${_refreshTicks[index]}');
    switch (index) {
      case 0:
        return ProdukListPage(key: key);
      case 1:
        return PesananSayaPage(key: key, embedded: true);
      case 2:
        return RiwayatPesananPage(key: key, embedded: true);
      case 3:
        return ProfilPembeliPage(key: key);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(4, _buildTab),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0xFF172554).withValues(alpha: 0.08),
        elevation: 8,
        indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Katalog',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman Profil Pembeli (ProfilPembeliPage) - Tab "Profil"
// ---------------------------------------------------------------------------
class ProfilPembeliPage extends StatelessWidget {
  const ProfilPembeliPage({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti Akun'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dan kembali ke halaman pemilihan akun demo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE14B4B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              SessionPengguna.logout();
              AlamatTersimpan.reset();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginDemoPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('Ya, Ganti Akun'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = SessionPengguna.currentAccount;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Profil',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: account == null
          ? const Center(child: Text('Akun tidak ditemukan.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: account.color.withValues(alpha: 0.12),
                    child: Icon(account.icon, size: 42, color: account.color),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          account.nama,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172554),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: account.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: account.color.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          account.role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: account.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.subNama,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: account.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                                color: account.color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nama Pelanggan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    account.namaPelanggan,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF172554),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(
                            height: 1,
                            thickness: 0.8,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: account.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.tag_rounded,
                                size: 18,
                                color: account.color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ID Pelanggan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    account.idPelanggan,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF172554),
                                    ),
                                  ),
                                ],
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
                        backgroundColor: const Color(0xFFFFF5F5),
                        foregroundColor: const Color(0xFFE14B4B),
                        elevation: 0,
                        side: const BorderSide(
                          color: Color(0xFFFFCCCC),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text(
                        'Ganti Akun',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _confirmLogout(context),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
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
  final ScrollController _produkScrollController = ScrollController();
  final List<Product> _produkHalamanBerikutnya = <Product>[];
  final Set<String> _halamanDiminta = <String>{};
  int _currentPage = 0;
  int _lastPage = 1;
  int _queryVersion = 0;
  bool _hasMorePages = false;
  bool _isLoadingMore = false;
  Object? _loadMoreError;

  final TextEditingController _searchController = TextEditingController();
  String _selectedKategori = 'Semua';
  String _selectedSort = 'Default';

  static const List<String> _kategoriList = [
    'Semua',
    'Alat Tulis',
    'Buku & Perlengkapan Belajar',
  ];

  static const List<String> _sortOptions = [
    'Default',
    'Harga Termurah',
    'Harga Termahal',
  ];

  final Set<int> _animatingAddedProductIds = <int>{};
  bool _isReloading = false;

  Future<void> _handleReload() async {
    if (_isReloading) return;
    setState(() => _isReloading = true);
    _reload();
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) {
      setState(() => _isReloading = false);
    }
  }

  Future<void> _beliProduk(Product p) async {
    final bool canBuy = p.tersedia && (p.preOrder || p.stok > 0);
    if (!canBuy) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !p.tersedia
                ? 'Produk "${p.nama}" saat ini tidak tersedia.'
                : 'Stok "${p.nama}" sudah habis.',
          ),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _animatingAddedProductIds.add(p.id);
    });

    try {
      await _api.addKeranjang(produkId: p.id, jumlah: 1);
      StateKeranjang.increment(1);
      StateKeranjang.lastAddedProdukId = p.id;

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: false,
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF34D399),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${p.nama} ditambahkan ke keranjang',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Lihat',
            textColor: const Color(0xFF60A5FA),
            onPressed: () {
              AppNav.push(context, const KeranjangPage());
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatAppErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      await Future.delayed(MotionConstants.cartSuccess);
      if (mounted) {
        setState(() {
          _animatingAddedProductIds.remove(p.id);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _produkScrollController.addListener(_onProdukScroll);
    _futureProduk = _fetchData();
    produkUpdateNotifier.addListener(_reload);
  }

  @override
  void dispose() {
    _queryVersion++;
    produkUpdateNotifier.removeListener(_reload);
    _searchController.dispose();
    _produkScrollController
      ..removeListener(_onProdukScroll)
      ..dispose();
    super.dispose();
  }

  /// Memanggil API server-side dengan query 'cari' dan filter 'kategori'
  Future<List<Product>> _fetchData() {
    final requestVersion = ++_queryVersion;
    _produkHalamanBerikutnya.clear();
    _halamanDiminta.clear();
    _currentPage = 0;
    _lastPage = 1;
    _hasMorePages = false;
    _isLoadingMore = false;
    _loadMoreError = null;

    final query = _searchController.text.trim();
    final cariParam = query.isNotEmpty ? query : null;
    final kategoriParam = _selectedKategori != 'Semua'
        ? _selectedKategori
        : null;

    return _api
        .fetchProdukPaginated(
          page: 1,
          perPage: 10,
          cari: cariParam,
          kategori: kategoriParam,
        )
        .then((result) {
          if (requestVersion == _queryVersion) {
            _currentPage = result.currentPage;
            _lastPage = result.lastPage;
            _hasMorePages = result.hasMorePages;
          }
          return result.products;
        });
  }

  void _onProdukScroll() {
    if (_produkScrollController.hasClients &&
        _produkScrollController.position.extentAfter < 300) {
      _loadNextProdukPage();
    }
  }

  Future<void> _loadNextProdukPage() async {
    if (_isLoadingMore || !_hasMorePages || _currentPage >= _lastPage) {
      return;
    }

    final requestVersion = _queryVersion;
    final page = _currentPage + 1;
    final requestKey = '$requestVersion:$page';
    if (!_halamanDiminta.add(requestKey)) return;

    final query = _searchController.text.trim();
    final cariParam = query.isNotEmpty ? query : null;
    final kategoriParam = _selectedKategori != 'Semua'
        ? _selectedKategori
        : null;
    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      final result = await _api.fetchProdukPaginated(
        page: page,
        perPage: 10,
        cari: cariParam,
        kategori: kategoriParam,
      );
      if (!mounted || requestVersion != _queryVersion) return;

      setState(() {
        _produkHalamanBerikutnya.addAll(result.products);
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _hasMorePages = result.hasMorePages;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _produkScrollController.hasClients &&
            _produkScrollController.position.extentAfter < 300) {
          _loadNextProdukPage();
        }
      });
    } catch (error) {
      if (!mounted || requestVersion != _queryVersion) return;
      setState(() => _loadMoreError = error);
    } finally {
      _halamanDiminta.remove(requestKey);
      if (mounted && requestVersion == _queryVersion) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onSearchOrFilterChanged() {
    setState(() {
      _futureProduk = _fetchData();
    });
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _futureProduk = _fetchData();
      });
    }
  }

  String _formatErrorMessage(Object error) => formatAppErrorMessage(error);

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
            icon: const AnimatedCartBadgeIcon(),
            tooltip: 'Keranjang',
            onPressed: () {
              AppNav.push(context, const KeranjangPage());
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
                hintStyle: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                        tooltip: 'Hapus teks',
                        onPressed: () {
                          _searchController.clear();
                          _onSearchOrFilterChanged();
                        },
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: Color(0xFF2563EB),
                      ),
                      tooltip: 'Cari',
                      onPressed: _onSearchOrFilterChanged,
                    ),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (_) => _onSearchOrFilterChanged(),
              onChanged: (_) => _onSearchOrFilterChanged(),
            ),
          ),

          // 2. Filter Kategori Horisontal (Server-Side)
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _kategoriList.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final kat = _kategoriList[i];
                final isSelected = _selectedKategori == kat;
                return PressableScale(
                  enableHaptic: true,
                  onPressed: () {
                    if (_selectedKategori != kat) {
                      setState(() {
                        _selectedKategori = kat;
                        _futureProduk = _fetchData();
                      });
                    }
                  },
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.2 : 0.8,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.22),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        kat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // 3. Pilihan Pengurutan Produk Berdasarkan Harga
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.swap_vert_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Urutkan:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSort,
                      isDense: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Color(0xFF2563EB),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF172554),
                      ),
                      items: _sortOptions.map((opt) {
                        return DropdownMenuItem<String>(
                          value: opt,
                          child: Text(opt),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null && val != _selectedSort) {
                          setState(() {
                            _selectedSort = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // 4. Daftar Produk (FutureBuilder)
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _futureProduk,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ProductListSkeleton();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                            builder: (context, val, child) => Opacity(
                              opacity: val,
                              child: Transform.scale(
                                scale: 0.85 + 0.15 * val,
                                child: child,
                              ),
                            ),
                            child: const Icon(
                              Icons.cloud_off_rounded,
                              size: 54,
                              color: Color(0xFFE14B4B),
                            ),
                          ),
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
                          PressableScale(
                            enableHaptic: true,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2F6BFF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                minimumSize: const Size(120, 48),
                              ),
                              icon: _isReloading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.refresh, size: 18),
                              label: Text(
                                _isReloading ? 'Mencoba...' : 'Coba Lagi',
                              ),
                              onPressed: _isReloading ? null : _handleReload,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final rawList = snapshot.data ?? [];
                if (rawList.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted &&
                        _produkScrollController.hasClients &&
                        _produkScrollController.position.extentAfter < 300) {
                      _loadNextProdukPage();
                    }
                  });
                }
                if (rawList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 56,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.isNotEmpty ||
                                    _selectedKategori != 'Semua'
                                ? 'Tidak ada produk yang sesuai dengan pencarian atau filter.'
                                : 'Belum ada produk yang tersedia di katalog.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty ||
                              _selectedKategori != 'Semua' ||
                              _selectedSort != 'Default') ...[
                            const SizedBox(height: 12),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(
                                  color: Color(0xFFBFDBFE),
                                ),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _selectedKategori = 'Semua';
                                  _selectedSort = 'Default';
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

                // Salin list produk agar data sumber asli tidak termutasi
                final List<Product> produkList = [
                  ...rawList,
                  ..._produkHalamanBerikutnya,
                ];
                if (_selectedSort == 'Harga Termurah') {
                  produkList.sort((a, b) => a.harga.compareTo(b.harga));
                } else if (_selectedSort == 'Harga Termahal') {
                  produkList.sort((a, b) => b.harga.compareTo(a.harga));
                }

                return RefreshIndicator(
                  color: const Color(0xFF2563EB),
                  backgroundColor: Colors.white,
                  onRefresh: () async => _reload(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = (constraints.maxWidth / 190)
                          .floor()
                          .clamp(2, 4);
                      final contentWidth = constraints.maxWidth - 32;
                      final tileWidth =
                          (contentWidth - 12 * (crossAxisCount - 1)) /
                          crossAxisCount;

                      return GridView.builder(
                        controller: _produkScrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: tileWidth + 190,
                        ),
                        itemCount:
                            produkList.length +
                            (_isLoadingMore || _loadMoreError != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= produkList.length) {
                            if (_loadMoreError != null) {
                              return Center(
                                child: TextButton.icon(
                                  onPressed: _loadNextProdukPage,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Coba muat lagi'),
                                ),
                              );
                            }
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2563EB),
                              ),
                            );
                          }

                          final produk = produkList[index];
                          return StaggeredListItem(
                            index: index,
                            child: ProductCard(
                              product: produk,
                              isAdded: _animatingAddedProductIds.contains(
                                produk.id,
                              ),
                              onAdd: () => _beliProduk(produk),
                              onTap: () async {
                                await AppNav.push(
                                  context,
                                  ProdukDetailPage(produk: produk),
                                );
                                if (mounted) _reload();
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
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
  bool _isBuyingNow = false;

  @override
  void initState() {
    super.initState();
    _futureDetail = _api.fetchProdukDetail(widget.produk.id);
    produkUpdateNotifier.addListener(_reload);
  }

  @override
  void dispose() {
    produkUpdateNotifier.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _futureDetail = _api.fetchProdukDetail(widget.produk.id);
      });
    }
  }

  /// Menghitung harga satuan efektif berdasarkan kuantitas stepper
  int _hitungHargaSatuan(Product p, int qty) {
    if (p.hargaGrosir.isEmpty) return p.harga;
    final tiers = p.hargaGrosir
        .where((tier) => tier.minKuantitas <= qty)
        .toList();
    if (tiers.isEmpty) return p.harga;
    tiers.sort((a, b) => b.minKuantitas.compareTo(a.minKuantitas));
    return tiers.first.hargaSatuan;
  }

  /// Kirim penambahan item ke server melalui POST /api/keranjang
  Future<void> _tambahKeKeranjang(Product product) async {
    if (_isAddingToCart || _isBuyingNow) return;

    setState(() {
      _isAddingToCart = true;
    });

    try {
      await _api.addKeranjang(produkId: product.id, jumlah: _jumlah);

      if (!mounted) return;
      StateKeranjang.increment(_jumlah);
      StateKeranjang.lastAddedProdukId = product.id;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: false,
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF34D399),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$_jumlah unit "${product.nama}" berhasil dimasukkan ke keranjang.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Lihat',
            textColor: const Color(0xFF60A5FA),
            onPressed: () {
              AppNav.push(context, const KeranjangPage());
            },
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(formatAppErrorMessage(e))),
            ],
          ),
          backgroundColor: const Color(0xFFE14B4B),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ValidationException catch (e) {
      if (!mounted) return;
      final errorMsg = e.errors.values
          .expand((item) => item is List ? item : [item])
          .join(', ');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg.isNotEmpty ? errorMsg : formatAppErrorMessage(e),
          ),
          backgroundColor: const Color(0xFFE14B4B),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on RequestTimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permintaan ke server melebihi batas waktu (15 detik). Silakan coba lagi.',
          ),
          backgroundColor: Color(0xFFE14B4B),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatAppErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatAppErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          duration: const Duration(seconds: 3),
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

  /// Beli sekarang: Masukkan item ke keranjang dan langsung menuju checkout produk tersebut
  Future<void> _beliSekarang(Product product) async {
    if (_isAddingToCart || _isBuyingNow) return;

    setState(() {
      _isBuyingNow = true;
    });

    try {
      await _api.addKeranjang(produkId: product.id, jumlah: _jumlah);
      StateKeranjang.lastAddedProdukId = product.id;

      final cartData = await _api.fetchKeranjang();
      final matchingItem = cartData.items.firstWhere(
        (i) => i.produkId == product.id,
        orElse: () => cartData.items.last,
      );

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutPage(selectedItemIds: [matchingItem.id]),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatAppErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBuyingNow = false;
        });
      }
    }
  }

  Widget _buildDetailBadge(Product p) {
    if (!p.tersedia) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Tidak Tersedia',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }
    if (p.preOrder) {
      final estimasi =
          (p.estimasiTersedia != null && p.estimasiTersedia!.isNotEmpty)
          ? ' · Tiba: ${p.estimasiTersedia}'
          : '';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
        ),
        child: Text(
          'Pre-Order$estimasi',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD97706),
          ),
        ),
      );
    }
    if (p.stok == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
        ),
        child: const Text(
          'Stok Habis',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFDC2626),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Stok Tersedia: ${p.stok} unit',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF059669),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172554),
                ),
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
            icon: const AnimatedCartBadgeIcon(),
            tooltip: 'Keranjang Belanja',
            onPressed: () {
              AppNav.push(context, const KeranjangPage());
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
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color(0xFFE14B4B),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formatAppErrorMessage(snapshot.error!),
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

          final product = snapshot.data;
          if (product == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 56,
                      color: Colors.grey,
                    ),
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
                      // Gambar Produk
                      Center(
                        child: ProdukImageWidget(
                          imageUrl: product.gambar,
                          width: double.infinity,
                          height: 220,
                          borderRadius: BorderRadius.circular(14),
                          fit: BoxFit.cover,
                          heroTag: 'product-img-${product.id}',
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                color: Color(0xFF172554),
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
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Harga Satuan Normal',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatRupiah(product.harga),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            if (isGrosirActive) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Harga Grosir Aktif: ${_formatRupiah(hargaSatuan)} / pcs untuk $_jumlah item',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172554),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          product.deskripsi != null &&
                                  product.deskripsi!.isNotEmpty
                              ? product.deskripsi!
                              : 'Tidak ada deskripsi untuk produk ini.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF334155),
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172554),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: product.hargaGrosir.map((tier) {
                              final bool tierReached =
                                  _jumlah >= tier.minKuantitas;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: tierReached
                                      ? const Color(0xFFEFF6FF)
                                      : Colors.transparent,
                                  border: const Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFF1F5F9),
                                    ),
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
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Beli minimal ${tier.minKuantitas} unit',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: tierReached
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: const Color(0xFF172554),
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
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFF172554),
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
                      color: const Color(0xFF172554).withValues(alpha: 0.06),
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
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
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
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$_jumlah',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF172554),
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
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                _formatRupiah(subtotal),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Baris Tombol Aksi: Tambah ke Keranjang & Beli Sekarang
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: PressableScale(
                                enabled:
                                    canOrder &&
                                    !_isAddingToCart &&
                                    !_isBuyingNow,
                                enableHaptic: true,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: !canOrder
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF172554),
                                    side: BorderSide(
                                      color: !canOrder
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF172554),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed:
                                      (!canOrder ||
                                          _isAddingToCart ||
                                          _isBuyingNow)
                                      ? null
                                      : () => _tambahKeKeranjang(product),
                                  icon: _isAddingToCart
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          product.preOrder
                                              ? Icons.schedule
                                              : Icons.add_shopping_cart,
                                          size: 18,
                                        ),
                                  label: Text(
                                    product.preOrder
                                        ? 'Keranjang PO'
                                        : 'Keranjang',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: PressableScale(
                                enabled:
                                    canOrder &&
                                    !_isAddingToCart &&
                                    !_isBuyingNow,
                                enableHaptic: true,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: !canOrder
                                        ? const Color(0xFF94A3B8)
                                        : (product.preOrder
                                              ? const Color(0xFFD97706)
                                              : const Color(0xFF2563EB)),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed:
                                      (!canOrder ||
                                          _isAddingToCart ||
                                          _isBuyingNow)
                                      ? null
                                      : () => _beliSekarang(product),
                                  icon: _isBuyingNow
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Icon(Icons.flash_on, size: 18),
                                  label: Text(
                                    product.preOrder
                                        ? 'Beli PO'
                                        : 'Beli Sekarang',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
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
// Halaman Keranjang Belanja (KeranjangPage) - Tahap 4
// ---------------------------------------------------------------------------
class KeranjangPage extends StatefulWidget {
  final bool embedded;
  const KeranjangPage({super.key, this.embedded = false});

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  final LayananApi _api = LayananApi();
  late Future<KeranjangData> _futureKeranjang;
  bool _isProcessing = false;
  Set<int>? _selectedItemIds;
  int? _appliedLastAddedProdukId;

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

  /// Menaruh produk terakhir yang ditambahkan di paling atas daftar.
  List<CartItem> _susunItems(List<CartItem> items) {
    final lastAdded = StateKeranjang.lastAddedProdukId;
    if (lastAdded == null) return items;
    final sorted = List<CartItem>.from(items);
    sorted.sort((a, b) {
      final aBaru = a.produkId == lastAdded;
      final bBaru = b.produkId == lastAdded;
      if (aBaru == bBaru) return a.id.compareTo(b.id);
      return aBaru ? -1 : 1;
    });
    return sorted;
  }

  String _formatErrorMessage(Object error) => formatAppErrorMessage(error);

  Future<void> _updateItemQty(CartItem item, int newQty) async {
    if (_isProcessing) return;
    if (newQty <= 0) {
      if (await _confirmDeleteItem(item)) _reload();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _api.updateKeranjang(id: item.id, jumlah: newQty);
      final quantityChange = newQty - item.jumlah;
      if (quantityChange > 0) {
        StateKeranjang.increment(quantityChange);
      } else {
        StateKeranjang.decrement(-quantityChange);
      }
      _reload();
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatAppErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ValidationException catch (e) {
      if (!mounted) return;
      final msg = e.errors.values.expand((i) => i is List ? i : [i]).join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isNotEmpty ? msg : formatAppErrorMessage(e)),
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
          content: Text(formatAppErrorMessage(e)),
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

  Future<bool> _confirmDeleteItem(CartItem item) async {
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

    if (confirmed != true) return false;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _api.deleteKeranjang(item.id);
      StateKeranjang.decrement(item.jumlah);
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item.nama}" telah dihapus dari keranjang.'),
          backgroundColor: const Color(0xFF2E9E5B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatAppErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
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
        automaticallyImplyLeading: !widget.embedded,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Keranjang Belanja',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (SessionPengguna.currentAccount != null)
              Text(
                'Akun: ${SessionPengguna.currentAccount!.nama}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A93)),
              ),
          ],
        ),
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
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color(0xFFE14B4B),
                    ),
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
                        backgroundColor: const Color(0xFF2563EB),
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
          final items = _susunItems(cartData?.items ?? []);

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: const Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Keranjang belanja Anda masih kosong.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172554),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pilih perlengkapan kantor atau alat tulis impian Anda sekarang.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
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

          // Sinkronisasi pilihan item: hanya produk terakhir yang ditambahkan
          // yang tercentang secara default.
          final itemIds = items.map((e) => e.id).toSet();
          final lastAdded = StateKeranjang.lastAddedProdukId;
          if (_selectedItemIds == null ||
              lastAdded != _appliedLastAddedProdukId) {
            _selectedItemIds = lastAdded == null
                ? <int>{}
                : items
                      .where((i) => i.produkId == lastAdded)
                      .map((i) => i.id)
                      .toSet();
            _appliedLastAddedProdukId = lastAdded;
          } else {
            _selectedItemIds = _selectedItemIds!.intersection(itemIds);
          }

          final selectedItems = items
              .where((i) => _selectedItemIds!.contains(i.id))
              .toList();
          final int selectedSubtotal = selectedItems.fold(
            0,
            (sum, i) => sum + i.subtotal,
          );
          final bool isAllSelected =
              items.isNotEmpty && _selectedItemIds!.length == items.length;
          final bool canCheckout = !_isProcessing && selectedItems.isNotEmpty;

          return Column(
            children: [
              // 1. Bilah Kontrol "Pilih Semua"
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isAllSelected,
                      activeColor: const Color(0xFF2563EB),
                      tristate: _selectedItemIds!.isNotEmpty && !isAllSelected,
                      onChanged: _isProcessing
                          ? null
                          : (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedItemIds = Set.from(itemIds);
                                } else {
                                  _selectedItemIds = <int>{};
                                }
                              });
                            },
                    ),
                    Text(
                      'Pilih Semua (${_selectedItemIds!.length}/${items.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172554),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Daftar Item Keranjang dengan Checkbox
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isChecked = _selectedItemIds!.contains(item.id);

                    return Dismissible(
                      key: ValueKey(item.produkId),
                      direction: _isProcessing
                          ? DismissDirection.none
                          : DismissDirection.endToStart,
                      confirmDismiss: (_) => _confirmDeleteItem(item),
                      onDismissed: (_) => _reload(),
                      background: const SizedBox.shrink(),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Hapus',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      child: Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isChecked
                                ? const Color(0xFF2563EB).withValues(alpha: 0.6)
                                : const Color(0xFFE2E8F0),
                            width: isChecked ? 1.2 : 0.8,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: isChecked,
                                    activeColor: const Color(0xFF2563EB),
                                    onChanged: _isProcessing
                                        ? null
                                        : (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedItemIds!.add(item.id);
                                              } else {
                                                _selectedItemIds!.remove(
                                                  item.id,
                                                );
                                              }
                                            });
                                          },
                                  ),
                                  const SizedBox(width: 4),
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
                                            color: Color(0xFF172554),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Harga satuan: ${_formatRupiah(item.hargaSatuan)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Color(0xFFDC2626),
                                    ),
                                    tooltip: 'Hapus item',
                                    onPressed: _isProcessing
                                        ? null
                                        : () async {
                                            if (await _confirmDeleteItem(
                                              item,
                                            )) {
                                              _reload();
                                            }
                                          },
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 16,
                                color: Color(0xFFF1F5F9),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Stepper Kuantitas
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
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
                                                ? const Color(0xFFDC2626)
                                                : const Color(0xFF172554),
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          onPressed: _isProcessing
                                              ? null
                                              : () => _updateItemQty(
                                                  item,
                                                  item.jumlah - 1,
                                                ),
                                        ),
                                        Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${item.jumlah}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF172554),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add,
                                            size: 16,
                                            color: Color(0xFF172554),
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          onPressed: _isProcessing
                                              ? null
                                              : () => _updateItemQty(
                                                  item,
                                                  item.jumlah + 1,
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Subtotal per item
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Subtotal',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        _formatRupiah(item.subtotal),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF172554),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 3. Bagian Bawah: Subtotal Terpilih & Lanjut ke Checkout
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF172554).withValues(alpha: 0.06),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Subtotal (${selectedItems.length} terpilih)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                _formatRupiah(selectedSubtotal),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canCheckout
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF94A3B8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: Text(
                              'Checkout (${selectedItems.length})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: canCheckout
                                ? () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CheckoutPage(
                                          selectedItemIds: _selectedItemIds!
                                              .toList(),
                                        ),
                                      ),
                                    );
                                    _reload();
                                  }
                                : null,
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
// Penyimpanan Informasi Checkout Terakhir
// ---------------------------------------------------------------------------
class AlamatTersimpan {
  static String? nama;
  static String? alamat;
  static String? kota;

  static void reset() {
    nama = null;
    alamat = null;
    kota = null;
  }
}

// ---------------------------------------------------------------------------
// Halaman Checkout (CheckoutPage) - Tahap 5
// ---------------------------------------------------------------------------
class CheckoutPage extends StatefulWidget {
  final List<int>? selectedItemIds;
  const CheckoutPage({super.key, this.selectedItemIds});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final LayananApi _api = LayananApi();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _kotaController = TextEditingController(
    text: 'Kota Malang',
  );

  late final String _idempotencyKey;

  late Future<KurirData> _futureKurir;
  WilayahItem? _selectedWilayah;
  KurirItem? _selectedKurir;
  String _metodePembayaran = 'tunai_di_tempat';

  KeranjangData? _ringkasanKeranjang;
  bool _isLoadingSummary = false;
  bool _isSubmitting = false;
  String? _errorSummary;
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    // Auto-fill alamat tersimpan jika tersedia
    if (AlamatTersimpan.nama != null && AlamatTersimpan.nama!.isNotEmpty) {
      _namaController.text = AlamatTersimpan.nama!;
    } else if (SessionPengguna.currentAccount != null) {
      _namaController.text = SessionPengguna.currentAccount!.nama;
    }
    if (AlamatTersimpan.alamat != null && AlamatTersimpan.alamat!.isNotEmpty) {
      _alamatController.text = AlamatTersimpan.alamat!;
    }
    if (AlamatTersimpan.kota != null && AlamatTersimpan.kota!.isNotEmpty) {
      _kotaController.text = AlamatTersimpan.kota!;
    }

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
        itemIds: widget.selectedItemIds,
      );
      if (!mounted) return;
      setState(() {
        _ringkasanKeranjang = summary;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorSummary = formatAppErrorMessage(e);
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
          content: Text(
            'Keranjang belanja kosong. Tidak dapat melakukan checkout.',
          ),
          backgroundColor: Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _fieldErrors.clear();
    });

    try {
      final request = CheckoutRequest(
        namaPenerima: _namaController.text.trim(),
        alamat: _alamatController.text.trim(),
        kota: _kotaController.text.trim(),
        wilayahId: _selectedWilayah!.id,
        kurirId: _selectedKurir!.id,
        metodePembayaran: _metodePembayaran,
        itemIds: widget.selectedItemIds,
      );

      final order = await _api.checkout(
        request: request,
        idempotencyKey: _idempotencyKey,
      );

      // Simpan alamat untuk checkout berikutnya
      AlamatTersimpan.nama = _namaController.text.trim();
      AlamatTersimpan.alamat = _alamatController.text.trim();
      AlamatTersimpan.kota = _kotaController.text.trim();

      if (!mounted) return;

      // Navigasi langsung ke rincian pesanan dengan akses pembayaran jelas (poin 9)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RincianPesananPage(
            pesananId: order.id,
            nomorPesanan: order.nomorPesanan,
          ),
        ),
      );
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(formatAppErrorMessage(e))),
            ],
          ),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _fieldErrors = e.errors.map((key, val) {
          if (val is List && val.isNotEmpty) {
            return MapEntry(key, val.first.toString());
          }
          return MapEntry(key, val.toString());
        });
      });
      final msg = e.errors.values
          .expand((item) => item is List ? item : [item])
          .join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.isNotEmpty ? 'Validasi gagal: $msg' : formatAppErrorMessage(e),
          ),
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
            'Koneksi melebihi batas waktu (15 detik). Tekan tombol Checkout kembali untuk memeriksa status transaksi Anda.',
          ),
          backgroundColor: Color(0xFFE14B4B),
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatAppErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatAppErrorMessage(e)),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Checkout Pesanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (SessionPengguna.currentAccount != null)
              Text(
                'Akun: ${SessionPengguna.currentAccount!.nama}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A93)),
              ),
          ],
        ),
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
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color(0xFFE14B4B),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat opsi kurir dan wilayah:\n${formatAppErrorMessage(snapshot.error!)}',
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
                      onPressed: () {
                        setState(() {
                          _futureKurir = _api.fetchKurir();
                        });
                      },
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
                            color: Color(0xFF172554),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _namaController,
                                decoration: InputDecoration(
                                  labelText: 'Nama Lengkap Penerima *',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: const OutlineInputBorder(),
                                  errorText: _fieldErrors['nama_penerima'],
                                ),
                                onChanged: (_) {
                                  if (_fieldErrors.containsKey(
                                    'nama_penerima',
                                  )) {
                                    setState(
                                      () =>
                                          _fieldErrors.remove('nama_penerima'),
                                    );
                                  }
                                },
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
                                decoration: InputDecoration(
                                  labelText: 'Alamat Lengkap Pengiriman *',
                                  prefixIcon: const Icon(
                                    Icons.location_on_outlined,
                                  ),
                                  border: const OutlineInputBorder(),
                                  errorText: _fieldErrors['alamat'],
                                ),
                                onChanged: (_) {
                                  if (_fieldErrors.containsKey('alamat')) {
                                    setState(
                                      () => _fieldErrors.remove('alamat'),
                                    );
                                  }
                                },
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
                                decoration: InputDecoration(
                                  labelText: 'Kota Tujuan *',
                                  helperText: 'Pengiriman ATK Mart saat ini khusus area Kota Malang',
                                  prefixIcon: const Icon(
                                    Icons.location_city_outlined,
                                  ),
                                  border: const OutlineInputBorder(),
                                  errorText: _fieldErrors['kota'],
                                ),
                                onChanged: (_) {
                                  if (_fieldErrors.containsKey('kota')) {
                                    setState(() => _fieldErrors.remove('kota'));
                                  }
                                },
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
                            color: Color(0xFF172554),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            children: [
                              DropdownButtonFormField<WilayahItem>(
                                isExpanded: true,
                                initialValue: _selectedWilayah,
                                decoration: InputDecoration(
                                  labelText: 'Pilih Wilayah / Kecamatan *',
                                  prefixIcon: const Icon(Icons.map_outlined),
                                  border: const OutlineInputBorder(),
                                  errorText: _fieldErrors['wilayah_id'],
                                ),
                                items: wilayahList.map((w) {
                                  final isSukun = w.nama.toLowerCase().contains(
                                    'sukun',
                                  );
                                  return DropdownMenuItem<WilayahItem>(
                                    value: w,
                                    child: Text(
                                      isSukun
                                          ? '${w.nama} (${w.kota}) - Asal Toko'
                                          : '${w.nama} (${w.kota})',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedWilayah = val;
                                    if (_fieldErrors.containsKey(
                                      'wilayah_id',
                                    )) {
                                      _fieldErrors.remove('wilayah_id');
                                    }
                                  });
                                  _fetchRingkasanServer();
                                },
                                validator: (val) => val == null
                                    ? 'Wilayah wajib dipilih'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<KurirItem>(
                                isExpanded: true,
                                initialValue: _selectedKurir,
                                decoration: InputDecoration(
                                  labelText: 'Pilih Layanan Kurir *',
                                  prefixIcon: const Icon(
                                    Icons.local_shipping_outlined,
                                  ),
                                  border: const OutlineInputBorder(),
                                  errorText: _fieldErrors['kurir_id'],
                                ),
                                items: kurirList.map((k) {
                                  return DropdownMenuItem<KurirItem>(
                                    value: k,
                                    child: Text(
                                      k.deskripsi != null &&
                                              k.deskripsi!.isNotEmpty
                                          ? '${k.nama} (${k.deskripsi})'
                                          : k.nama,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedKurir = val;
                                    if (_fieldErrors.containsKey('kurir_id')) {
                                      _fieldErrors.remove('kurir_id');
                                    }
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
                            color: Color(0xFF172554),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _metodePembayaran = 'tunai_di_tempat';
                                  });
                                },
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _metodePembayaran == 'tunai_di_tempat'
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color:
                                            _metodePembayaran ==
                                                'tunai_di_tempat'
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Tunai di Tempat (COD)',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF172554),
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Bayar langsung secara tunai saat barang diantarkan kurir',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _metodePembayaran = 'transfer_manual';
                                  });
                                },
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _metodePembayaran == 'transfer_manual'
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color:
                                            _metodePembayaran ==
                                                'transfer_manual'
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Transfer Bank Manual',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF172554),
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Transfer ke rekening toko dan konfirmasi pembayaran',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                              ),
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
                            color: Color(0xFF172554),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: _isLoadingSummary
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _errorSummary != null
                              ? Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F0),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE14B4B)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _errorSummary!,
                                        style: const TextStyle(
                                          color: Color(0xFFE14B4B),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                        onPressed: _fetchRingkasanServer,
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 16,
                                        ),
                                        label: const Text('Hitung Ulang'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF2F6BFF,
                                          ),
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Subtotal Produk',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        Text(
                                          _formatRupiah(
                                            _ringkasanKeranjang?.subtotal ?? 0,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF172554),
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
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        Text(
                                          _ringkasanKeranjang?.ongkosKirim !=
                                                  null
                                              ? _formatRupiah(
                                                  _ringkasanKeranjang!
                                                      .ongkosKirim!,
                                                )
                                              : (_selectedWilayah != null &&
                                                        _selectedKurir != null
                                                    ? 'Memuat...'
                                                    : 'Pilih kurir & wilayah'),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _ringkasanKeranjang
                                                        ?.ongkosKirim !=
                                                    null
                                                ? const Color(0xFF172554)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(
                                      height: 20,
                                      color: Color(0xFFF1F5F9),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total Tagihan',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF172554),
                                          ),
                                        ),
                                        Text(
                                          _formatRupiah(
                                            _ringkasanKeranjang?.total ??
                                                _ringkasanKeranjang?.subtotal ??
                                                0,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF172554).withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
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
                          backgroundColor: const Color(0xFF2563EB),
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
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF059669),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Terima Kasih!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172554),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pesanan Anda telah berhasil dibuat dan diteruskan ke pihak toko.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),

              // Rincian Kartu Pesanan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            color: Color(0xFF2563EB),
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
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFFDE68A),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            order.status.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal Produk',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          _formatRupiah(order.subtotal),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF172554),
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
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          _formatRupiah(order.ongkosKirim),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF172554),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172554),
                          ),
                        ),
                        Text(
                          _formatRupiah(order.total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
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
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_outlined),
                  label: const Text(
                    'Lihat Rincian Pesanan Ini',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                    foregroundColor: const Color(0xFF172554),
                    side: const BorderSide(color: Color(0xFF172554)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text(
                    'Buka Pesanan Saya (Aktif)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PesananSayaPage(),
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
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                  ),
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text(
                    'Kembali ke Katalog Produk',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
    case 'menunggu_stok':
      bg = const Color(0xFFFEF3C7);
      border = const Color(0xFFFDE68A);
      text = const Color(0xFFD97706);
      label = 'MENUNGGU STOK';
      break;
    case 'menunggu_pembayaran':
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFCD34D);
      text = const Color(0xFFB45309);
      label = 'MENUNGGU PEMBAYARAN';
      break;
    case 'menunggu_konfirmasi':
      bg = const Color(0xFFFEF3C7);
      border = const Color(0xFFFDE68A);
      text = const Color(0xFFD97706);
      label = 'MENUNGGU KONFIRMASI';
      break;
    case 'dibayar':
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFBFDBFE);
      text = const Color(0xFF1D4ED8);
      label = 'DIBAYAR';
      break;
    case 'diproses':
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFF93C5FD);
      text = const Color(0xFF2563EB);
      label = 'DIPROSES';
      break;
    case 'dikirim':
      bg = const Color(0xFFFAF5FF);
      border = const Color(0xFFE9D5FF);
      text = const Color(0xFF7E22CE);
      label = 'DIKIRIM';
      break;
    case 'selesai':
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFFA7F3D0);
      text = const Color(0xFF059669);
      label = 'SELESAI';
      break;
    case 'dibatalkan':
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      text = const Color(0xFFDC2626);
      label = 'DIBATALKAN';
      break;
    default:
      bg = const Color(0xFFF1F5F9);
      border = const Color(0xFFE2E8F0);
      text = const Color(0xFF64748B);
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
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
    ),
  );
}

// ---------------------------------------------------------------------------
// Halaman Pesanan Saya (PesananSayaPage) - Khusus Pesanan Aktif / Berjalan
// Menampilkan seluruh pesanan yang belum selesai (status != 'selesai')
// ---------------------------------------------------------------------------
class PesananSayaPage extends StatefulWidget {
  final bool embedded;
  const PesananSayaPage({super.key, this.embedded = false});

  @override
  State<PesananSayaPage> createState() => _PesananSayaPageState();
}

class _PesananSayaPageState extends State<PesananSayaPage> {
  final LayananApi _api = LayananApi();
  late Future<List<Order>> _futurePesanan;
  String _filterStatus = 'semua';

  @override
  void initState() {
    super.initState();
    _loadPesanan();
  }

  void _loadPesanan() {
    _futurePesanan = _api.fetchPesanan();
  }

  void _reload() {
    setState(() {
      _loadPesanan();
    });
  }

  String _formatErrorMessage(Object error) => formatAppErrorMessage(error);

  String _getStatusHint(String status, String? metode) {
    final isTransfer =
        (metode ?? '').toLowerCase().contains('transfer') ||
        (metode ?? '').toLowerCase().contains('manual');

    switch (status.toLowerCase()) {
      case 'menunggu_stok':
        return 'Pre-order: Menunggu konfirmasi ketersediaan stok produk dari toko.';
      case 'menunggu_pembayaran':
        return isTransfer
            ? 'Menunggu transfer bank. Buka rincian untuk simulasi ATM & lapor bayar.'
            : 'Menunggu proses konfirmasi pesanan COD.';
      case 'menunggu_konfirmasi':
        return 'Pembayaran/pesanan sedang diverifikasi oleh pengelola toko.';
      case 'dibayar':
        return 'Pembayaran terverifikasi. Pesanan akan segera diproses oleh toko.';
      case 'diproses':
        return 'Pesanan sedang disiapkan dan dikemas oleh toko.';
      case 'dikirim':
        return 'Pesanan sedang dalam pengiriman ke alamat Anda.';
      default:
        return 'Pesanan aktif sedang diproses dalam alur sistem.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pesanan Saya',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (SessionPengguna.currentAccount != null)
              Text(
                'Akun: ${SessionPengguna.currentAccount!.nama}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A93)),
              ),
          ],
        ),
        actions: [
          if (!widget.embedded)
            IconButton(
              icon: const Icon(Icons.history_rounded),
              tooltip: 'Riwayat Selesai',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiwayatPesananPage()),
                );
              },
            ),
          IconButton(
            icon: const AnimatedCartBadgeIcon(),
            tooltip: 'Keranjang',
            onPressed: () {
              AppNav.push(context, const KeranjangPage());
            },
          ),
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
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color(0xFFE14B4B),
                    ),
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

          final allOrders = snapshot.data ?? [];
          // Aturan: Hanya pesanan aktif/belum selesai (status != 'selesai')
          final activeOrders = allOrders
              .where((o) => o.status != 'selesai')
              .toList();

          if (activeOrders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 64,
                      color: const Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tidak Ada Pesanan Aktif',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172554),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Seluruh pesanan Anda telah selesai atau Anda belum membuat pesanan baru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF172554),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          icon: const Icon(Icons.history_rounded),
                          label: const Text('Riwayat Selesai'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RiwayatPesananPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.storefront_outlined),
                          label: const Text('Mulai Belanja'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          final filteredOrders = _filterStatus == 'semua'
              ? activeOrders
              : activeOrders.where((o) => o.status == _filterStatus).toList();

          return Column(
            children: [
              // Filter status chip bar
              Container(
                color: Colors.white,
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _buildChip('Semua Aktif', 'semua', activeOrders.length),
                      _buildChip(
                        'Menunggu Pembayaran',
                        'menunggu_pembayaran',
                        activeOrders
                            .where((o) => o.status == 'menunggu_pembayaran')
                            .length,
                      ),
                      _buildChip(
                        'Menunggu Konfirmasi',
                        'menunggu_konfirmasi',
                        activeOrders
                            .where((o) => o.status == 'menunggu_konfirmasi')
                            .length,
                      ),
                      _buildChip(
                        'Menunggu Stok',
                        'menunggu_stok',
                        activeOrders
                            .where((o) => o.status == 'menunggu_stok')
                            .length,
                      ),
                      _buildChip(
                        'Diproses',
                        'diproses',
                        activeOrders
                            .where((o) => o.status == 'diproses')
                            .length,
                      ),
                      _buildChip(
                        'Dikirim',
                        'dikirim',
                        activeOrders.where((o) => o.status == 'dikirim').length,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              Expanded(
                child: filteredOrders.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada pesanan aktif.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          final hint = _getStatusHint(
                            order.status,
                            order.metodePembayaran,
                          );

                          return Card(
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 0.8,
                              ),
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
                                ).then((_) => _reload());
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                  color: Color(0xFF172554),
                                                ),
                                              ),
                                              if (order.createdAt != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  order.createdAt!,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
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

                                    const SizedBox(height: 10),
                                    // Hint Status Banner
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            size: 14,
                                            color: Color(0xFF2563EB),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              hint,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFF1F5F9),
                                    ),
                                    const SizedBox(height: 10),

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
                                                '${order.jumlahItem} Produk dipesan',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            if (order.kurir != null)
                                              Text(
                                                'Kurir: ${order.kurir}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                              ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'Total Tagihan',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                            Text(
                                              _formatRupiah(order.total),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Tombol Aksi Langsung ke Detail
                                    SizedBox(
                                      width: double.infinity,
                                      height: 38,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF2563EB,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFBFDBFE),
                                            width: 1,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Lihat Detail & Lacak Pesanan',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  RincianPesananPage(
                                                    pesananId: order.id,
                                                    nomorPesanan:
                                                        order.nomorPesanan,
                                                  ),
                                            ),
                                          ).then((_) => _reload());
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        selectedColor: const Color(0xFF2563EB),
        backgroundColor: const Color(0xFFF1F5F9),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11.5,
        ),
        onSelected: (_) {
          setState(() {
            _filterStatus = value;
          });
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman Riwayat Pesanan Selesai (RiwayatPesananPage) - Tahap 6
// Khusus menampilkan pesanan yang telah selesai (status == 'selesai')
// ---------------------------------------------------------------------------
class RiwayatPesananPage extends StatefulWidget {
  final bool embedded;
  const RiwayatPesananPage({super.key, this.embedded = false});

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

  String _formatErrorMessage(Object error) => formatAppErrorMessage(error);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Pesanan (Selesai)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (SessionPengguna.currentAccount != null)
              Text(
                'Akun: ${SessionPengguna.currentAccount!.nama}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A93)),
              ),
          ],
        ),
        actions: [
          if (!widget.embedded)
            IconButton(
              icon: const Icon(Icons.local_shipping_outlined),
              tooltip: 'Pesanan Saya (Aktif)',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PesananSayaPage()),
                );
              },
            ),
          IconButton(
            icon: const AnimatedCartBadgeIcon(),
            tooltip: 'Keranjang',
            onPressed: () {
              AppNav.push(context, const KeranjangPage());
            },
          ),
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
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color(0xFFE14B4B),
                    ),
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
                        backgroundColor: const Color(0xFF2563EB),
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

          final allOrders = snapshot.data ?? [];
          // Khusus pesanan berstatus selesai (status == 'selesai')
          final orders = allOrders.where((o) => o.status == 'selesai').toList();

          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: const Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum Ada Pesanan Selesai',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172554),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pesanan yang telah berhasil diterima dan diselesaikan akan tercatat di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.local_shipping_outlined),
                          label: const Text('Lihat Pesanan Aktif'),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PesananSayaPage(),
                              ),
                            );
                          },
                        ),
                      ],
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
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.nomorPesanan,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF172554),
                                    ),
                                  ),
                                  if (order.createdAt != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      order.createdAt!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
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
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),

                        // Baris 2: Rincian Singkat (Jumlah Item, Kurir, Total)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (order.jumlahItem != null)
                                  Text(
                                    '${order.jumlahItem} Produk dibeli',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                if (order.kurir != null)
                                  Text(
                                    'Kurir: ${order.kurir}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
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
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  _formatRupiah(order.total),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
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
                            children: const [
                              Text(
                                'Lihat Rincian',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Color(0xFF2563EB),
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
  final bool isPengelola;

  const RincianPesananPage({
    required this.pesananId,
    required this.nomorPesanan,
    this.isPengelola = false,
    super.key,
  });

  @override
  State<RincianPesananPage> createState() => _RincianPesananPageState();
}

class _RincianPesananPageState extends State<RincianPesananPage> {
  final LayananApi _api = LayananApi();
  late Future<Order> _futureDetail;
  bool _isConfirmingPayment = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    _futureDetail = widget.isPengelola
        ? _api.fetchPesananDetailPengelola(widget.pesananId)
        : _api.fetchPesananDetail(widget.pesananId);
  }

  void _reload() {
    setState(() {
      _loadDetail();
    });
  }

  Future<void> _updateStatusPengelola(
    Order order,
    String statusBaru,
    String label,
    String catatanDefault,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: Text(
          'Apakah Anda yakin ingin memperbarui status pesanan "${order.nomorPesanan}" ke "$statusBaru"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E9E5B),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isConfirmingPayment = true);

    try {
      await _api.updateStatusPesananPengelola(
        id: order.id,
        status: statusBaru,
        catatan: catatanDefault,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status pesanan ${order.nomorPesanan} berhasil diubah ke "$statusBaru".',
          ),
          backgroundColor: const Color(0xFF2E9E5B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formatErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirmingPayment = false);
      }
    }
  }

  Future<void> _konfirmasiPembayaran(Order order) async {
    await _updateStatusPengelola(
      order,
      'dibayar',
      'Konfirmasi Pembayaran',
      'Pembayaran dikonfirmasi oleh pengelola',
    );
  }

  Future<void> _konfirmasiBarangSampai(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Barang Sampai'),
        content: Text(
          'Apakah Anda sudah menerima seluruh pesanan "${order.nomorPesanan}" dengan kondisi baik dan lengkap?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Belum'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E9E5B),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Barang Sudah Sampai'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isConfirmingPayment = true);

    try {
      await _api.updateStatusPesanan(
        id: order.id,
        status: 'selesai',
        catatan: 'Barang telah diterima oleh pembeli',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terima kasih! Pesanan telah selesai.'),
          backgroundColor: Color(0xFF2E9E5B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formatErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirmingPayment = false);
      }
    }
  }

  void _tampilkanSimulasiAtm(Order order) {
    final vaNumber = '8806${order.id.toString().padLeft(6, '0')}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F6BFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Color(0xFF2F6BFF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bank ATK Mart Virtual Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Simulasi Pembayaran ATM & Internet Banking',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8A8A93)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E6EC)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nomor Virtual Account',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A8A93),
                        ),
                      ),
                      SelectableText(
                        vaNumber,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F6BFF),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Tagihan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A8A93),
                        ),
                      ),
                      Text(
                        _formatRupiah(order.total),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15151A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Petunjuk Pembayaran ATM Bank ATK Mart:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildAtmStep(
              '1',
              'Masukkan kartu ATM dan 6 digit PIN Bank ATK Mart Anda.',
            ),
            _buildAtmStep(
              '2',
              'Pilih menu Pembayaran / Transfer > Virtual Account.',
            ),
            _buildAtmStep('3', 'Masukkan nomor Virtual Account: $vaNumber.'),
            _buildAtmStep(
              '4',
              'Periksa nominal tagihan ${_formatRupiah(order.total)} dan tekan Benar.',
            ),
            _buildAtmStep(
              '5',
              'Simpan struk transaksi ATM sebagai bukti pembayaran.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E9E5B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Konfirmasi Pembayaran Selesai',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _laporkanSudahBayar(order);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtmStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF0FF),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F6BFF),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF15151A)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _laporkanSudahBayar(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: Text(
          'Apakah Anda sudah melakukan transfer sebesar ${_formatRupiah(order.total)} '
          'untuk pesanan "${order.nomorPesanan}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Belum'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F6BFF),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Sudah Bayar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isConfirmingPayment = true);

    try {
      await _api.updateStatusPesanan(
        id: order.id,
        status: 'menunggu_konfirmasi',
        catatan: 'Pembeli mengonfirmasi pembayaran telah ditransfer',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Konfirmasi pembayaran berhasil dikirim! Menunggu verifikasi dari pengelola toko.',
          ),
          backgroundColor: Color(0xFF2E9E5B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formatErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirmingPayment = false);
      }
    }
  }

  String _formatErrorMessage(Object error) => formatAppErrorMessage(error);

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
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172554),
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
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color(0xFFE14B4B),
                    ),
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

          final order = snapshot.data;
          if (order == null) {
            return const Center(child: Text('Data pesanan tidak tersedia.'));
          }

          final items = order.items ?? [];
          final histories = order.riwayatStatus ?? [];

          final content = SingleChildScrollView(
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
                      color: const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status Pesanan',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          _buildOrderStatusBadge(order.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nomor Pesanan',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          SelectableText(
                            order.nomorPesanan,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      if (order.createdAt != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      if (order.status == 'menunggu_stok') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFD591)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.hourglass_top,
                                size: 20,
                                color: Color(0xFFD46B08),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pesanan pre-order ini sedang menunggu ketersediaan stok dari toko sebelum pembayaran atau pemrosesan.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF873800),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                      final hasDiscount = item.hargaSatuan < item.hargaNormal;
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3D6),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(0xFFE0A32E),
                                          width: 0.6,
                                        ),
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
                                            decoration:
                                                TextDecoration.lineThrough,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF172554),
                            ),
                          ),
                          Text(
                            _formatRupiah(order.total),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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

                const SizedBox(height: 16),
              ],
            ),
          );

          final stickyAction = _buildStickyBottomAction(order);

          return Column(
            children: [
              Expanded(child: content),
              if (stickyAction != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF172554).withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(top: false, child: stickyAction),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget? _buildStickyBottomAction(Order order) {
    final rawMetode = (order.metodePembayaran ?? '').toLowerCase();
    final isCod = rawMetode.contains('cod') || rawMetode.contains('tunai');
    final isTransfer =
        !isCod &&
        (rawMetode.contains('transfer') ||
            rawMetode.contains('manual') ||
            rawMetode.contains('bank'));

    // Sisi Pengelola Toko
    if (widget.isPengelola) {
      if (order.status == 'menunggu_stok') {
        final targetStatus = isCod
            ? 'menunggu_konfirmasi'
            : 'menunggu_pembayaran';
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0A32E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isConfirmingPayment
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.inventory_outlined),
            label: const Text(
              'Konfirmasi Stok Tersedia',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: _isConfirmingPayment
                ? null
                : () => _updateStatusPengelola(
                    order,
                    targetStatus,
                    'Konfirmasi Stok Tersedia',
                    'Stok fisik telah tersedia dan dialokasikan untuk pesanan',
                  ),
          ),
        );
      }

      if (order.status == 'menunggu_konfirmasi') {
        if (isCod) {
          return SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E9E5B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isConfirmingPayment
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text(
                'Konfirmasi Pesanan COD (Diproses)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: _isConfirmingPayment
                  ? null
                  : () => _updateStatusPengelola(
                      order,
                      'diproses',
                      'Konfirmasi Pesanan COD',
                      'Pesanan COD dikonfirmasi dan mulai diproses',
                    ),
            ),
          );
        } else {
          return SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E9E5B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isConfirmingPayment
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.verified_outlined),
              label: const Text(
                'Konfirmasi Pembayaran (Dibayar)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: _isConfirmingPayment
                  ? null
                  : () => _konfirmasiPembayaran(order),
            ),
          );
        }
      }

      if (order.status == 'dibayar') {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F6BFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isConfirmingPayment
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.schedule_send_outlined),
            label: const Text(
              'Mulai Proses Pesanan (Diproses)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: _isConfirmingPayment
                ? null
                : () => _updateStatusPengelola(
                    order,
                    'diproses',
                    'Proses Pesanan',
                    'Pesanan sedang disiapkan di toko',
                  ),
          ),
        );
      }

      if (order.status == 'diproses') {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B1FA2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isConfirmingPayment
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.local_shipping_outlined),
            label: const Text(
              'Kirim Pesanan (Dikirim)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: _isConfirmingPayment
                ? null
                : () => _updateStatusPengelola(
                    order,
                    'dikirim',
                    'Kirim Pesanan',
                    'Pesanan sedang dalam pengiriman kurir',
                  ),
          ),
        );
      }

      if (order.status == 'dikirim') {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E9E5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isConfirmingPayment
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.task_alt),
            label: const Text(
              'Selesaikan Pesanan (Selesai)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: _isConfirmingPayment
                ? null
                : () => _updateStatusPengelola(
                    order,
                    'selesai',
                    'Selesaikan Pesanan',
                    'Pesanan telah diterima dan transaksi selesai',
                  ),
          ),
        );
      }

      return null;
    }

    // Sisi Pembeli
    if (order.status == 'menunggu_pembayaran' && isTransfer) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F6BFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.account_balance, size: 18),
                label: const Text(
                  'Simulasi ATM',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: _isConfirmingPayment
                    ? null
                    : () => _tampilkanSimulasiAtm(order),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E9E5B),
                  side: const BorderSide(color: Color(0xFF2E9E5B), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isConfirmingPayment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Color(0xFF2E9E5B),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: const Text(
                  'Saya Sudah Bayar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: _isConfirmingPayment
                    ? null
                    : () => _laporkanSudahBayar(order),
              ),
            ),
          ),
        ],
      );
    }

    if (order.status == 'dikirim') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E9E5B),
            foregroundColor: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: _isConfirmingPayment
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.thumb_up_alt_outlined),
          label: const Text(
            'Barang Sudah Sampai',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          onPressed: _isConfirmingPayment
              ? null
              : () => _konfirmasiBarangSampai(order),
        ),
      );
    }

    return null;
  }
}

// ===========================================================================
// PAKET 3 — KELOLA PRODUK (Pengelola/Admin)
// ===========================================================================

// ---------------------------------------------------------------------------
// KelolaProdukPage: Daftar Produk Versi Pengelola
// GET /api/produk (semua produk); POST, PUT, DELETE /api/produk
// ---------------------------------------------------------------------------
class KelolaProdukPage extends StatefulWidget {
  const KelolaProdukPage({super.key});

  @override
  State<KelolaProdukPage> createState() => _KelolaProdukPageState();
}

class _KelolaProdukPageState extends State<KelolaProdukPage> {
  final LayananApi _api = LayananApi();
  late Future<List<Product>> _futureProduk;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _futureProduk = _api.fetchProduk();
    produkUpdateNotifier.addListener(_reload);
  }

  @override
  void dispose() {
    produkUpdateNotifier.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _futureProduk = _api.fetchProduk();
      });
    }
  }

  String _formatErrorMessage(Object error) => formatAppErrorMessage(error);

  Future<void> _hapusProduk(Product produk) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text(
          'Yakin ingin menghapus "${produk.nama}"?\n\n'
          'Produk yang masih terkait dengan pesanan aktif tidak dapat dihapus.',
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

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await _api.deleteProduk(produk.id);
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      produkUpdateNotifier.value++;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${produk.nama}" berhasil dihapus.'),
          backgroundColor: const Color(0xFF2E9E5B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatAppErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _bukaFormProduk({Product? produk}) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormProdukPage(produk: produk)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Kelola Pesanan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KelolaPesananPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _isDeleting ? null : _reload,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isDeleting ? null : () => _bukaFormProduk(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
        backgroundColor: const Color(0xFF2F6BFF),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Product>>(
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
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color(0xFFE14B4B),
                    ),
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
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum Ada Produk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15151A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tekan tombol "+ Tambah Produk" untuk menambahkan produk pertama.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: produkList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final p = produkList[index];
                return Card(
                  color: Colors.white,
                  elevation: 0.8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: Color(0xFFE6E6EC),
                      width: 0.8,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProdukImageWidget(
                          imageUrl: p.gambar,
                          width: 72,
                          height: 72,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Baris atas: Nama + badge status
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.nama,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF15151A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          p.kategori,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF8A8A93),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildProdukStatusBadge(p),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Baris tengah: Harga, Stok
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatRupiah(p.harga),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2F6BFF),
                                          ),
                                        ),
                                        Text(
                                          'Stok: ${p.stok} unit',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        if (p.hargaGrosir.isNotEmpty)
                                          Text(
                                            'Grosir: ${p.hargaGrosir.length} tier',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF2F6BFF),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Tombol aksi
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                          color: Color(0xFF2F6BFF),
                                        ),
                                        tooltip: 'Edit Produk',
                                        onPressed: _isDeleting
                                            ? null
                                            : () => _bukaFormProduk(produk: p),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: Color(0xFFE14B4B),
                                        ),
                                        tooltip: 'Hapus Produk',
                                        onPressed: _isDeleting
                                            ? null
                                            : () => _hapusProduk(p),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProdukStatusBadge(Product p) {
    if (!p.tersedia) {
      return _adminBadge(
        'Tidak Tersedia',
        const Color(0xFFF5F5F7),
        Colors.grey.shade400,
        Colors.grey.shade700,
      );
    }
    if (p.preOrder) {
      return _adminBadge(
        'Preorder',
        const Color(0xFFFFF3D6),
        const Color(0xFFE0A32E),
        const Color(0xFF946200),
      );
    }
    if (p.stok == 0) {
      return _adminBadge(
        'Stok Habis',
        const Color(0xFFFFEBEB),
        const Color(0xFFE14B4B),
        const Color(0xFFB42323),
      );
    }
    return _adminBadge(
      'Tersedia',
      const Color(0xFFEBF8EE),
      const Color(0xFF2E9E5B),
      const Color(0xFF2E9E5B),
    );
  }

  Widget _adminBadge(
    String label,
    Color bg,
    Color borderColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FormProdukPage: Form Tambah / Edit Produk
// POST /api/produk (tambah) | PUT /api/produk/{id} (edit)
// ---------------------------------------------------------------------------
class FormProdukPage extends StatefulWidget {
  /// Jika null, mode Tambah; jika berisi data, mode Edit.
  final Product? produk;

  const FormProdukPage({this.produk, super.key});

  @override
  State<FormProdukPage> createState() => _FormProdukPageState();
}

class _FormProdukPageState extends State<FormProdukPage> {
  final LayananApi _api = LayananApi();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaCtrl;
  late final TextEditingController _hargaCtrl;
  late final TextEditingController _stokCtrl;
  late final TextEditingController _deskripsiCtrl;
  late final TextEditingController _estimasiCtrl;

  String _selectedKategori = 'Alat Tulis';
  bool _tersedia = true;
  bool _preOrder = false;

  // Daftar tier harga grosir yang bisa ditambah/hapus
  final List<Map<String, TextEditingController>> _grosirTiers = [];

  // Gambar produk (image_picker)
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSubmitting = false;
  bool _isDeletingGambar = false;
  bool _gambarDihapus = false;
  Map<String, String> _fieldErrors = {};

  static const List<String> _kategoriOptions = [
    'Alat Tulis',
    'Buku & Perlengkapan Belajar',
  ];

  bool get _isEditMode => widget.produk != null;

  String get _selectedImageSizeLabel {
    if (_selectedImageBytes == null) return '';
    final bytes = _selectedImageBytes!.lengthInBytes;
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / 1024).round()} KB';
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (bytes.lengthInBytes > 2 * 1024 * 1024) {
          final sizeMb = (bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(
            2,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ukuran foto ($sizeMb MB) melebihi batas maksimal 2 MB. Silakan pilih gambar lain.',
              ),
              backgroundColor: const Color(0xFFE14B4B),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        setState(() {
          _selectedImageFile = picked;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar dari galeri: $e'),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageBytes = null;
    });
  }

  Future<void> _hapusGambarProduk() async {
    if (_isDeletingGambar || widget.produk == null) return;

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus gambar ini?'),
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

    if (konfirmasi != true || !mounted) return;

    setState(() => _isDeletingGambar = true);

    try {
      await _api.hapusGambarProduk(widget.produk!.id);
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      produkUpdateNotifier.value++;
      if (!mounted) return;
      setState(() {
        _gambarDihapus = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gambar produk berhasil dihapus.'),
          backgroundColor: Color(0xFF2E9E5B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatAppErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeletingGambar = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.produk;
    _namaCtrl = TextEditingController(text: p?.nama ?? '');
    _hargaCtrl = TextEditingController(text: p != null ? '${p.harga}' : '');
    _stokCtrl = TextEditingController(text: p != null ? '${p.stok}' : '');
    _deskripsiCtrl = TextEditingController(text: p?.deskripsi ?? '');
    _estimasiCtrl = TextEditingController(text: p?.estimasiTersedia ?? '');

    if (p != null) {
      _selectedKategori = p.kategori;
      _tersedia = p.tersedia;
      _preOrder = p.preOrder;
      // Pre-fill grosir tiers
      for (final tier in p.hargaGrosir) {
        _grosirTiers.add({
          'min': TextEditingController(text: '${tier.minKuantitas}'),
          'harga': TextEditingController(text: '${tier.hargaSatuan}'),
        });
      }
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _hargaCtrl.dispose();
    _stokCtrl.dispose();
    _deskripsiCtrl.dispose();
    _estimasiCtrl.dispose();
    for (final t in _grosirTiers) {
      t['min']!.dispose();
      t['harga']!.dispose();
    }
    super.dispose();
  }

  void _tambahTierGrosir() {
    setState(() {
      _grosirTiers.add({
        'min': TextEditingController(),
        'harga': TextEditingController(),
      });
    });
  }

  void _hapusTierGrosir(int index) {
    setState(() {
      _grosirTiers[index]['min']!.dispose();
      _grosirTiers[index]['harga']!.dispose();
      _grosirTiers.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    // Validasi tier grosir
    for (int i = 0; i < _grosirTiers.length; i++) {
      final minText = _grosirTiers[i]['min']!.text.trim();
      final hargaText = _grosirTiers[i]['harga']!.text.trim();
      if (minText.isEmpty || hargaText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tier grosir ke-${i + 1}: min kuantitas dan harga wajib diisi.',
            ),
            backgroundColor: const Color(0xFFE14B4B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final minVal = int.tryParse(minText);
      final hargaVal = int.tryParse(hargaText);
      if (minVal == null || minVal < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tier grosir ke-${i + 1}: min kuantitas harus angka >= 2.',
            ),
            backgroundColor: const Color(0xFFE14B4B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (hargaVal == null || hargaVal < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tier grosir ke-${i + 1}: harga satuan harus angka >= 1.',
            ),
            backgroundColor: const Color(0xFFE14B4B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _fieldErrors.clear();
    });

    final hargaGrosirPayload = _grosirTiers.map((t) {
      return {
        'min_kuantitas': int.parse(t['min']!.text.trim()),
        'harga_satuan': int.parse(t['harga']!.text.trim()),
      };
    }).toList();

    final payload = <String, dynamic>{
      'nama': _namaCtrl.text.trim(),
      'harga': int.parse(_hargaCtrl.text.trim()),
      'kategori': _selectedKategori,
      'stok': int.parse(_stokCtrl.text.trim()),
      'tersedia': _tersedia,
      'deskripsi': _deskripsiCtrl.text.trim().isEmpty
          ? null
          : _deskripsiCtrl.text.trim(),
      'pre_order': _preOrder,
      'estimasi_tersedia': (!_preOrder || _estimasiCtrl.text.trim().isEmpty)
          ? null
          : _estimasiCtrl.text.trim(),
      'harga_grosir': hargaGrosirPayload,
    };

    try {
      if (_isEditMode) {
        await _api.updateProduk(
          widget.produk!.id,
          payload,
          gambarFile: _selectedImageFile,
          gambarBytes: _selectedImageBytes,
        );
      } else {
        await _api.createProduk(
          payload,
          gambarFile: _selectedImageFile,
          gambarBytes: _selectedImageBytes,
        );
      }

      // Bersihkan cache gambar & picu pembaruan instan ke seluruh tampilan (admin & pembeli)
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      produkUpdateNotifier.value++;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Produk "${payload['nama']}" berhasil diperbarui.'
                : 'Produk "${payload['nama']}" berhasil ditambahkan.',
          ),
          backgroundColor: const Color(0xFF2E9E5B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _fieldErrors = e.errors.map((key, val) {
          if (val is List && val.isNotEmpty) {
            return MapEntry(key, val.first.toString());
          }
          return MapEntry(key, val.toString());
        });
      });
      final msg = e.errors.values
          .expand((item) => item is List ? item : [item])
          .join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.isNotEmpty ? 'Validasi gagal: $msg' : formatAppErrorMessage(e),
          ),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on RequestTimeoutException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan produk: ${e.message}'),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatAppErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatAppErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Produk' : 'Tambah Produk'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Section: Foto Produk ===
              _buildImageSection(),
              const SizedBox(height: 16),

              // === Section: Informasi Dasar ===
              _sectionTitle('Informasi Dasar', Icons.inventory_outlined),
              const SizedBox(height: 10),
              _sectionCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _namaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama Produk *',
                        hintText: 'Contoh: Pensil 2B Faber-Castell',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.label_outlined),
                        errorText: _fieldErrors['nama'],
                      ),
                      onChanged: (_) {
                        if (_fieldErrors.containsKey('nama')) {
                          setState(() => _fieldErrors.remove('nama'));
                        }
                      },
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama produk wajib diisi';
                        }
                        if (val.trim().length > 255) {
                          return 'Nama produk maksimal 255 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedKategori,
                      decoration: InputDecoration(
                        labelText: 'Kategori *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.category_outlined),
                        errorText: _fieldErrors['kategori'],
                      ),
                      items: _kategoriOptions.map((k) {
                        return DropdownMenuItem(value: k, child: Text(k));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedKategori = val;
                            if (_fieldErrors.containsKey('kategori')) {
                              _fieldErrors.remove('kategori');
                            }
                          });
                        }
                      },
                      validator: (val) =>
                          val == null ? 'Kategori wajib dipilih' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deskripsiCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi (opsional)',
                        hintText: 'Deskripsi singkat produk...',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                        errorText: _fieldErrors['deskripsi'],
                      ),
                      onChanged: (_) {
                        if (_fieldErrors.containsKey('deskripsi')) {
                          setState(() => _fieldErrors.remove('deskripsi'));
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // === Section: Harga & Stok ===
              _sectionTitle('Harga & Stok', Icons.price_change_outlined),
              const SizedBox(height: 10),
              _sectionCard(
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hargaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga Normal (Rp) *',
                          hintText: '5000',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.attach_money),
                          errorText: _fieldErrors['harga'],
                        ),
                        onChanged: (_) {
                          if (_fieldErrors.containsKey('harga')) {
                            setState(() => _fieldErrors.remove('harga'));
                          }
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Harga wajib diisi';
                          }
                          final v = int.tryParse(val.trim());
                          if (v == null || v < 1) {
                            return 'Harga harus angka >= 1';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stokCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Stok (unit) *',
                          hintText: '0',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                          errorText: _fieldErrors['stok'],
                        ),
                        onChanged: (_) {
                          if (_fieldErrors.containsKey('stok')) {
                            setState(() => _fieldErrors.remove('stok'));
                          }
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Stok wajib diisi';
                          }
                          final v = int.tryParse(val.trim());
                          if (v == null || v < 0) {
                            return 'Stok harus angka >= 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // === Section: Status Produk ===
              _sectionTitle('Status & Ketersediaan', Icons.toggle_on_outlined),
              const SizedBox(height: 10),
              _sectionCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Produk Tersedia / Aktif',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _tersedia
                            ? 'Produk ini tampil dan bisa dibeli pelanggan'
                            : 'Produk ini disembunyikan dari pelanggan',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _tersedia,
                      activeThumbColor: const Color(0xFF2F6BFF),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _tersedia = val),
                    ),
                    const Divider(height: 8),
                    SwitchListTile(
                      title: const Text(
                        'Mode Pre-Order',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _preOrder
                            ? 'Pelanggan bisa memesan meski stok 0'
                            : 'Hanya bisa dibeli jika stok tersedia',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _preOrder,
                      activeThumbColor: const Color(0xFFE0A32E),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _preOrder = val),
                    ),
                    if (_preOrder) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _estimasiCtrl,
                        decoration: InputDecoration(
                          labelText: 'Estimasi Tanggal Tersedia (opsional)',
                          hintText: 'Contoh: 2026-12-31',
                          helperText: 'Format: YYYY-MM-DD',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          errorText: _fieldErrors['estimasi_tersedia'],
                        ),
                        onChanged: (_) {
                          if (_fieldErrors.containsKey('estimasi_tersedia')) {
                            setState(
                              () => _fieldErrors.remove('estimasi_tersedia'),
                            );
                          }
                        },
                        validator: (val) {
                          if (!_preOrder || val == null || val.trim().isEmpty) {
                            return null;
                          }
                          final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                          if (!dateRegex.hasMatch(val.trim())) {
                            return 'Format tanggal tidak valid (YYYY-MM-DD)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // === Section: Harga Grosir ===
              Row(
                children: [
                  Expanded(
                    child: _sectionTitle(
                      'Harga Grosir (opsional)',
                      Icons.discount_outlined,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isSubmitting ? null : _tambahTierGrosir,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah Tier'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_grosirTiers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE6E6EC),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Belum ada tier grosir.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

              ..._grosirTiers.asMap().entries.map((entry) {
                final i = entry.key;
                final tier = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFBDD3FF),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: tier['min'],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Min Qty Tier ${i + 1}',
                            hintText: 'misal: 10',
                            helperText: 'minimal 2',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: tier['harga'],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Harga Satuan Tier ${i + 1}',
                            hintText: 'misal: 4500',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Color(0xFFE14B4B),
                        ),
                        tooltip: 'Hapus tier ini',
                        onPressed: _isSubmitting
                            ? null
                            : () => _hapusTierGrosir(i),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // === Indikator Progres Simpan/Unggah ===
              if (_isSubmitting) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedImageBytes != null
                              ? 'Sedang mengunggah foto & menyimpan data produk (maks. 60 dtk)...'
                              : 'Sedang menyimpan data produk...',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // === Tombol Submit ===
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D0D12),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isEditMode
                                  ? 'Menyimpan Perubahan...'
                                  : 'Menambahkan Produk...',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isEditMode
                                  ? Icons.save_outlined
                                  : Icons.add_circle_outline,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEditMode
                                  ? 'Simpan Perubahan'
                                  : 'Tambahkan Produk',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final bool hasNewImage = _selectedImageBytes != null;
    final bool hasExistingImage =
        _isEditMode &&
        !_gambarDihapus &&
        widget.produk?.gambar != null &&
        widget.produk!.gambar!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Foto Produk', Icons.photo_camera_back_outlined),
        const SizedBox(height: 10),
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasNewImage) ...[
                // Preview gambar baru yang dipilih dari galeri
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Image.memory(
                        _selectedImageBytes!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E9E5B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _selectedImageSizeLabel.isNotEmpty
                                ? 'Gambar Baru ($_selectedImageSizeLabel)'
                                : 'Gambar Baru Dipilih',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: const Text('Ganti Gambar Lain'),
                        onPressed: _isSubmitting ? null : _pickImage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFE14B4B),
                      ),
                      tooltip: 'Batalkan pilihan gambar ini',
                      onPressed: _isSubmitting ? null : _clearSelectedImage,
                    ),
                  ],
                ),
              ] else if (hasExistingImage) ...[
                // Preview gambar lama yang tersimpan di server
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      ProdukImageWidget(
                        imageUrl: widget.produk!.gambar,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xBF0D0D12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Gambar Saat Ini',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jika tidak diganti, gambar ini akan tetap dipertahankan.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Ganti Gambar dari Galeri'),
                        onPressed: (_isSubmitting || _isDeletingGambar)
                            ? null
                            : _pickImage,
                      ),
                    ),
                    if (SessionPengguna.isPengelola) ...[
                      const SizedBox(width: 8),
                      _isDeletingGambar
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Color(0xFFE14B4B),
                                  ),
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Color(0xFFE14B4B),
                              ),
                              tooltip: 'Hapus gambar',
                              onPressed: _isSubmitting ? null : _hapusGambarProduk,
                            ),
                    ],
                  ],
                ),
              ] else ...[
                // Belum ada gambar
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFD0D5DD),
                      style: BorderStyle.solid,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada gambar produk',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Format JPG, PNG, atau WEBP (maks. 2MB)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F6BFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Pilih Gambar dari Galeri'),
                    onPressed: _isSubmitting ? null : _pickImage,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
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
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE6E6EC), width: 0.8),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

// ===========================================================================
// PAKET B.1 — KELOLA PESANAN ADMIN & KONFIRMASI PEMBAYARAN
// GET /api/pesanan (seluruh pesanan via header pengelola)
// PATCH /api/pesanan/{id}/status (konfirmasi status 'dibayar' oleh pengelola)
// ===========================================================================

class KelolaPesananPage extends StatefulWidget {
  const KelolaPesananPage({super.key});

  @override
  State<KelolaPesananPage> createState() => _KelolaPesananPageState();
}

class _KelolaPesananPageState extends State<KelolaPesananPage> {
  final LayananApi _api = LayananApi();
  late Future<List<Order>> _futurePesanan;
  String _selectedStatus = 'semua';
  int? _updatingOrderId;

  @override
  void initState() {
    super.initState();
    _loadPesanan();
  }

  void _loadPesanan() {
    _futurePesanan = _api.fetchPesananPengelola();
  }

  void _reload() {
    setState(() {
      _loadPesanan();
    });
  }

  String _formatErrorMessage(Object error) => formatAppErrorMessage(error);

  Future<void> _updateStatusPesanan(
    Order order,
    String statusBaru,
    String label,
    String catatan,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: Text(
          'Konfirmasi untuk memperbarui pesanan "${order.nomorPesanan}" ke status "$statusBaru"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E9E5B),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _updatingOrderId = order.id);

    try {
      await _api.updateStatusPesananPengelola(
        id: order.id,
        status: statusBaru,
        catatan: catatan,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status pesanan ${order.nomorPesanan} berhasil diubah ke "$statusBaru".',
          ),
          backgroundColor: const Color(0xFF2E9E5B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formatErrorMessage(e)),
          backgroundColor: const Color(0xFFE14B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingOrderId = null);
      }
    }
  }

  Future<void> _konfirmasiPembayaran(Order order) async {
    await _updateStatusPesanan(
      order,
      'dibayar',
      'Konfirmasi Pembayaran',
      'Pembayaran dikonfirmasi oleh pengelola',
    );
  }

  List<Order> _applyFilter(List<Order> orders) {
    if (_selectedStatus == 'semua') return orders;
    return orders.where((o) => o.status == _selectedStatus).toList();
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        selectedColor: const Color(0xFF2F6BFF),
        backgroundColor: const Color(0xFFEDEDF2),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF15151A),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (_) {
          setState(() {
            _selectedStatus = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pesanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Kelola Produk',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KelolaProdukPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _updatingOrderId != null ? null : _reload,
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
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color(0xFFE14B4B),
                    ),
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

          final allOrders = snapshot.data ?? [];
          if (allOrders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Color(0xFF8A8A93),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum Ada Pesanan Masuk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15151A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seluruh pesanan dari pembeli akan tercatat di halaman ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF8A8A93)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Segarkan'),
                      onPressed: _reload,
                    ),
                  ],
                ),
              ),
            );
          }

          final filteredOrders = _applyFilter(allOrders);

          // Hitung jumlah per status untuk filter bar
          final countSemua = allOrders.length;
          final countMenungguStok = allOrders
              .where((o) => o.status == 'menunggu_stok')
              .length;
          final countMenungguKonfirmasi = allOrders
              .where((o) => o.status == 'menunggu_konfirmasi')
              .length;
          final countMenungguPembayaran = allOrders
              .where((o) => o.status == 'menunggu_pembayaran')
              .length;
          final countDibayar = allOrders
              .where((o) => o.status == 'dibayar')
              .length;
          final countDiproses = allOrders
              .where((o) => o.status == 'diproses')
              .length;
          final countDikirim = allOrders
              .where((o) => o.status == 'dikirim')
              .length;
          final countSelesai = allOrders
              .where((o) => o.status == 'selesai')
              .length;
          final countDibatalkan = allOrders
              .where((o) => o.status == 'dibatalkan')
              .length;

          return Column(
            children: [
              // 1. Bilah Filter Status
              Container(
                color: Colors.white,
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', 'semua', countSemua),
                      _buildFilterChip(
                        'Menunggu Stok',
                        'menunggu_stok',
                        countMenungguStok,
                      ),
                      _buildFilterChip(
                        'Menunggu Konfirmasi',
                        'menunggu_konfirmasi',
                        countMenungguKonfirmasi,
                      ),
                      _buildFilterChip(
                        'Menunggu Pembayaran',
                        'menunggu_pembayaran',
                        countMenungguPembayaran,
                      ),
                      _buildFilterChip('Dibayar', 'dibayar', countDibayar),
                      _buildFilterChip('Diproses', 'diproses', countDiproses),
                      _buildFilterChip('Dikirim', 'dikirim', countDikirim),
                      _buildFilterChip('Selesai', 'selesai', countSelesai),
                      _buildFilterChip(
                        'Dibatalkan',
                        'dibatalkan',
                        countDibatalkan,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE6E6EC)),

              // 2. Daftar Kartu Pesanan
              Expanded(
                child: filteredOrders.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada pesanan dengan status "$_selectedStatus".',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8A8A93),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          final isMenungguKonfirmasi =
                              order.status == 'menunggu_konfirmasi';
                          final isProcessingThis = _updatingOrderId == order.id;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isMenungguKonfirmasi
                                    ? const Color(0xFFE0A32E)
                                          .withValues(alpha: 0.6)
                                    : const Color(0xFFE6E6EC),
                                width: isMenungguKonfirmasi ? 1.4 : 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RincianPesananPage(
                                        pesananId: order.id,
                                        nomorPesanan: order.nomorPesanan,
                                        isPengelola: true,
                                      ),
                                    ),
                                  );
                                  _reload();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Baris 1: Nomor Pesanan & Badge Status
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              order.nomorPesanan,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF15151A),
                                              ),
                                            ),
                                          ),
                                          _buildOrderStatusBadge(order.status),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Baris 2: Data Pembeli & Tanggal
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline,
                                            size: 16,
                                            color: Color(0xFF8A8A93),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            order.namaPenerima ?? 'Pembeli',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF15151A),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (order.createdAt != null) ...[
                                            const Icon(
                                              Icons.access_time,
                                              size: 14,
                                              color: Color(0xFF8A8A93),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              order.createdAt!,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF8A8A93),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Baris 3: Metode Pembayaran & Total
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.payment_outlined,
                                            size: 16,
                                            color: Color(0xFF8A8A93),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            (order.metodePembayaran ?? '-')
                                                .replaceAll('_', ' ')
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF8A8A93),
                                            ),
                                          ),
                                          const Spacer(),
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

                                      // Baris 4: Aksi Khusus Pengelola
                                      if (isMenungguKonfirmasi) ...[
                                        const SizedBox(height: 14),
                                        const Divider(
                                          height: 1,
                                          color: Color(0xFFE6E6EC),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF2E9E5B,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                icon: isProcessingThis
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation(
                                                                Colors.white,
                                                              ),
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons
                                                            .check_circle_outline,
                                                        size: 18,
                                                      ),
                                                label: Text(
                                                  isProcessingThis
                                                      ? 'Memproses...'
                                                      : 'Konfirmasi Pembayaran',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                onPressed: isProcessingThis
                                                    ? null
                                                    : () =>
                                                          _konfirmasiPembayaran(
                                                            order,
                                                          ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(
                                                  0xFF2F6BFF,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                      horizontal: 14,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              onPressed: () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        RincianPesananPage(
                                                          pesananId: order.id,
                                                          nomorPesanan: order
                                                              .nomorPesanan,
                                                          isPengelola: true,
                                                        ),
                                                  ),
                                                );
                                                _reload();
                                              },
                                              child: const Text(
                                                'Detail',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
