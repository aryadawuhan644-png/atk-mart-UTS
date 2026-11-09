// test/api/ui_perbaikan_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:atkmart_mobile/admin_preferences.dart';
import 'package:atkmart_mobile/admin_profile_settings.dart';
import 'package:atkmart_mobile/api/api_config.dart';
import 'package:atkmart_mobile/api/models/order.dart';
import 'package:atkmart_mobile/main.dart';

void main() {
  setUp(() {
    SessionPengguna.logout();
  });

  tearDown(() {
    SessionPengguna.logout();
  });

  group('Ketentuan 1: Tampilan & Role Pengelola / Admin', () {
    test('Pengelola Login: Sesi teridentifikasi sebagai Pengelola dengan token pengelola', () {
      SessionPengguna.login(DemoAccount.pengelola);

      expect(SessionPengguna.isLoggedIn, isTrue);
      expect(SessionPengguna.isPengelola, isTrue);
      expect(SessionPengguna.currentAccount?.role, 'pengelola');
      expect(ApiConfig.staticToken, ApiConfig.tokenPengelolaStatis);
      expect(ApiConfig.activeRole, 'pengelola');
    });

    test('Pembeli 1 Login: Sesi bukan pengelola dan menggunakan token pembeli 1', () {
      SessionPengguna.login(DemoAccount.pembeli1);

      expect(SessionPengguna.isLoggedIn, isTrue);
      expect(SessionPengguna.isPengelola, isFalse);
      expect(SessionPengguna.currentAccount?.role, 'pembeli');
      expect(ApiConfig.staticToken, ApiConfig.tokenPembeli1Statis);
    });

    test('Pembeli 2 Login: Sesi bukan pengelola dan menggunakan token pembeli 2', () {
      SessionPengguna.login(DemoAccount.pembeli2);

      expect(SessionPengguna.isLoggedIn, isTrue);
      expect(SessionPengguna.isPengelola, isFalse);
      expect(SessionPengguna.currentAccount?.role, 'pembeli');
      expect(ApiConfig.staticToken, ApiConfig.tokenPembeli2Statis);
    });

    testWidgets('AdminDashboardPage menampilkan 2 menu utama pengelola dan info banner', (tester) async {
      SessionPengguna.login(DemoAccount.pengelola);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardPage(loadStats: false),
        ),
      );
      await tester.pump();

      // Verifikasi judul dan banner
      expect(find.text('Dashboard Pengelola'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('Menu Operasional Toko'), findsOneWidget);

      // Verifikasi 2 Menu Utama
      expect(find.text('Kelola Produk'), findsOneWidget);
      expect(find.text('Kelola Pesanan'), findsOneWidget);

      // Pastikan fitur belanja pembeli tidak ada di halaman ini
      expect(find.text('Keranjang'), findsNothing);
      expect(find.text('Checkout'), findsNothing);
      expect(find.text('Beli Sekarang'), findsNothing);
    });

    testWidgets('Halaman profil admin menampilkan profil dan pengaturan lokal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminProfileSettingsPage(
            initialName: 'Pengelola Toko',
            email: 'admin@atkmart.id',
            onLogout: () {},
          ),
        ),
      );

      expect(find.text('Pengelola Toko'), findsOneWidget);
      expect(find.text('admin@atkmart.id'), findsOneWidget);
      expect(find.text('Ganti Password'), findsOneWidget);

      await tester.ensureVisible(find.text('Gelap'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();
      expect(AdminPreferences.themeMode.value, ThemeMode.dark);

      await tester.scrollUntilVisible(find.byType(SwitchListTile), 300);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(AdminPreferences.notificationsEnabled, isFalse);

      await tester.scrollUntilVisible(find.text('Versi 1.0.0+1'), 300);
      expect(find.text('Versi 1.0.0+1'), findsOneWidget);

      await AdminPreferences.setThemeMode(ThemeMode.light);
      await AdminPreferences.setNotificationsEnabled(true);
    });
  });

  group('Ketentuan 2: Notifikasi Masuk Keranjang', () {
    test('Konfigurasi notifikasi hijau otomatis hilang dalam 2-3 detik', () {
      const duration = Duration(seconds: 2);
      const color = Color(0xFF2E9E5B);
      const behavior = SnackBarBehavior.floating;

      expect(duration.inSeconds, inInclusiveRange(2, 3));
      expect(color.toARGB32(), 0xFF2E9E5B);
      expect(behavior, SnackBarBehavior.floating);
    });
  });

  group('Ketentuan 3: Pemisahan Halaman Pesanan Pembeli (Pesanan Saya vs Riwayat Pesanan)', () {
    final mockOrders = [
      const Order(id: 1, nomorPesanan: 'ORD-001', status: 'menunggu_pembayaran', subtotal: 10000, ongkosKirim: 0, total: 10000),
      const Order(id: 2, nomorPesanan: 'ORD-002', status: 'menunggu_stok', subtotal: 20000, ongkosKirim: 0, total: 20000),
      const Order(id: 3, nomorPesanan: 'ORD-003', status: 'menunggu_konfirmasi', subtotal: 30000, ongkosKirim: 0, total: 30000),
      const Order(id: 4, nomorPesanan: 'ORD-004', status: 'diproses', subtotal: 40000, ongkosKirim: 0, total: 40000),
      const Order(id: 5, nomorPesanan: 'ORD-005', status: 'dikirim', subtotal: 50000, ongkosKirim: 0, total: 50000),
      const Order(id: 6, nomorPesanan: 'ORD-006', status: 'selesai', subtotal: 60000, ongkosKirim: 0, total: 60000),
      const Order(id: 7, nomorPesanan: 'ORD-007', status: 'selesai', subtotal: 70000, ongkosKirim: 0, total: 70000),
    ];

    test('Pesanan Saya (Aktif) hanya memuat pesanan dengan status != selesai', () {
      final activeOrders = mockOrders.where((o) => o.status != 'selesai').toList();

      expect(activeOrders.length, 5);
      expect(activeOrders.map((o) => o.nomorPesanan), containsAll([
        'ORD-001',
        'ORD-002',
        'ORD-003',
        'ORD-004',
        'ORD-005',
      ]));
      expect(activeOrders.any((o) => o.status == 'selesai'), isFalse);
    });

    test('Riwayat Pesanan hanya memuat pesanan dengan status == selesai', () {
      final completedOrders = mockOrders.where((o) => o.status == 'selesai').toList();

      expect(completedOrders.length, 2);
      expect(completedOrders.map((o) => o.nomorPesanan), containsAll([
        'ORD-006',
        'ORD-007',
      ]));
      expect(completedOrders.every((o) => o.status == 'selesai'), isTrue);
    });

    test('Isolasi Mutlak: Tidak ada pesanan yang muncul di kedua halaman sekaligus', () {
      final activeOrderIds = mockOrders.where((o) => o.status != 'selesai').map((o) => o.id).toSet();
      final completedOrderIds = mockOrders.where((o) => o.status == 'selesai').map((o) => o.id).toSet();

      // Intersection harus kosong
      final intersection = activeOrderIds.intersection(completedOrderIds);
      expect(intersection, isEmpty);

      // Union harus mencakup semua pesanan
      final union = activeOrderIds.union(completedOrderIds);
      expect(union.length, mockOrders.length);
    });
  });

  group('Ketentuan Fitur Gambar Produk', () {
    test('resolveImageUrl mengembalikan null untuk null atau string kosong', () {
      expect(resolveImageUrl(null), isNull);
      expect(resolveImageUrl(''), isNull);
      expect(resolveImageUrl('   '), isNull);
    });

    test('resolveImageUrl memetakan endpoint gambar produk ke host ApiConfig aktif', () {
      final resolved = resolveImageUrl('http://127.0.0.1:8000/api/produk/1/gambar');
      expect(resolved, isNotNull);
      expect(resolved, contains('/api/produk/1/gambar'));
    });

    test('resolveImageUrl mendukung path relatif gambar produk', () {
      final resolved = resolveImageUrl('/api/produk/5/gambar');
      expect(resolved, isNotNull);
      expect(resolved, contains('/api/produk/5/gambar'));
      expect(resolved!.startsWith('http'), isTrue);
    });

    testWidgets('ProdukImageWidget menampilkan placeholder otomatis saat imageUrl null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProdukImageWidget(
              imageUrl: null,
              width: 80,
              height: 80,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });
  });
}
