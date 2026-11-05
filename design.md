# Panduan Desain — ATK Mart (Buku & Alat Tulis)

Acuan visual ini dipakai supaya semua halaman Flutter (Katalog, Rincian Produk,
Keranjang, Checkout, dst) konsisten satu sama lain. Gaya: bersih, modern,
rounded, dengan satu layar beraksen gelap (beranda) dan sisanya terang.

---

## 1. Palet Warna

| Token | Hex | Dipakai untuk |
|---|---|---|
| `primaryDark` | `#0D0D12` | Latar beranda/hero, teks utama di atas latar terang |
| `primaryBlue` | `#2F6BFF` | Aksen interaktif: tombol aktif, tab terpilih, link, badge jumlah |
| `surfaceLight` | `#F5F5F7` | Latar belakang layar (light mode) |
| `surfaceCard` | `#FFFFFF` | Latar kartu produk, kartu kategori |
| `surfaceMuted` | `#EDEDF2` | Latar ikon kategori, chip filter tidak aktif |
| `textPrimary` | `#15151A` | Judul, nama produk, harga |
| `textSecondary` | `#8A8A93` | Deskripsi singkat, label kecil, placeholder |
| `success` | `#2E9E5B` | Badge diskon/hemat, status "selesai" |
| `warning` | `#E0A32E` | Status "menunggu_stok" / "menunggu_pembayaran" |
| `danger` | `#E14B4B` | Pesan galat, badge stok habis |
| `border` | `#E6E6EC` | Garis tipis antar elemen, outline input |

**Catatan khusus domain:** karena produk kalian ada yang **pre-order**, pakai
`warning` untuk badge "Pre-Order" (bukan `danger`), supaya beda kesan dari
"Stok Habis" yang pakai `danger`. Badge "Harga Grosir" pakai `primaryBlue`
dengan latar `#EAF0FF`.

---

## 2. Tipografi

Font: **Inter** atau **Plus Jakarta Sans** (keduanya tersedia via Google Fonts
package `google_fonts` di pub.dev, gratis dan dekat dengan gaya mockup).

| Gaya | Ukuran | Weight | Dipakai untuk |
|---|---|---|---|
| Display | 26sp | Bold (700) | Judul hero beranda ("Katalog Buku & Alat Tulis") |
| Heading | 20sp | SemiBold (600) | Judul halaman, nama produk di rincian |
| Subheading | 16sp | SemiBold (600) | Nama produk di kartu list, judul section ("Terlaris") |
| Body | 14sp | Regular (400) | Deskripsi produk, teks form |
| Caption | 12sp | Regular (400) | Label kecil, teks di bawah ikon fitur |
| Harga | 18sp | Bold (700) | Harga produk (warna `textPrimary`) |
| Harga Coret | 14sp | Regular, strikethrough | Harga sebelum diskon (warna `textSecondary`) |

---

## 3. Spacing & Radius

- **Grid dasar:** kelipatan 4px (4, 8, 12, 16, 20, 24, 32).
- **Padding layar:** 20px kiri-kanan di semua halaman.
- **Jarak antar kartu dalam grid/list:** 12px.
- **Radius kartu & tombol besar:** 16px.
- **Radius kartu kecil (ikon kategori, chip):** 12px.
- **Radius tombol pill (filter kategori, badge):** 999px (full rounded).
- **Radius input form:** 12px.

---

## 4. Komponen

### 4.1 Bottom Navigation
5 item: **Katalog, Kategori, Keranjang, Riwayat, Profil/Kelola** (sesuaikan
dengan 7 halaman wajib — boleh gabung "Kelola Produk" ke menu profil kalau
butuh slot). Item aktif pakai background `primaryBlue` bentuk pill di sekitar
ikon+label, item lain abu-abu (`textSecondary`). Badge jumlah di ikon
Keranjang: lingkaran kecil `primaryBlue`, teks putih, posisi pojok kanan atas.

### 4.2 Kartu Produk (Katalog — grid/list)
- Gambar produk 1:1, radius atas 16px.
- Nama produk (Subheading), maks 2 baris, ellipsis.
- Baris harga: harga aktif (Harga) + harga grosir kalau ada, format
  `"Mulai 12 pcs: Rp10.000/pcs"` kecil di bawah harga utama.
- Badge pojok kiri atas gambar: **"Pre-Order"** (warning) atau
  **"Stok Habis"** (danger, hanya untuk produk non pre-order).
- Tombol tambah keranjang: ikon bulat kecil pojok kanan bawah gambar,
  latar `primaryDark`, ikon putih. **Dimatikan (abu-abu, disabled)** kalau
  produk stok 0 dan bukan pre-order.

### 4.3 Halaman Rincian Produk
- Gambar besar di atas (bisa carousel kalau ada >1 gambar, pakai dot indicator
  seperti mockup).
- Judul + rating (opsional, skip kalau tidak ada fitur rating) di bawah gambar.
- Baris "fitur singkat" ala 4 ikon di mockup → ganti jadi atribut khas domain:
  **Kategori**, **Stok**, **Pre-Order (ya/tidak)**, **Satuan Grosir**.
- Pemilih jumlah: tombol `-` / angka / `+` dalam kapsul rounded abu-abu muda.
- Harga besar di kiri bawah, tombol **"Tambah ke Keranjang"** full-width warna
  `primaryDark`, teks putih, radius 16px, disabled abu-abu kalau tidak bisa
  dipesan.

### 4.4 Keranjang
- List item dengan thumbnail kecil (radius 12px), nama, harga satuan efektif,
  qty stepper kecil, ikon hapus (ikon tempat sampah, warna `danger`).
- Subtotal di card terpisah bagian bawah, latar `surfaceCard`, border atas
  tipis (`border`), total dalam Heading, tombol **"Lanjut ke Checkout"**
  full-width `primaryBlue`.

### 4.5 Checkout
- Form alamat: input rounded 12px, border `border`, label di atas input
  (bukan placeholder-only, supaya jelas saat sudah terisi).
- Pemilih kurir: list radio card, nama kurir + tarif di kanan.
- Ringkasan biaya: subtotal, ongkos kirim, total — rata kanan-kiri, total pakai
  Heading bold.
- Tombol checkout: sama seperti tombol tambah keranjang, tapi tampilkan
  **loading spinner di dalam tombol** (bukan dialog terpisah) saat permintaan
  sedang berjalan, dan nonaktif selama itu.

### 4.6 Status Pesanan (badge warna)
| Status | Warna badge |
|---|---|
| `menunggu_stok` | `warning`, latar `#FBF2DD` |
| `menunggu_pembayaran` | `warning`, latar `#FBF2DD` |
| `menunggu_konfirmasi` | `primaryBlue`, latar `#EAF0FF` |
| `dibayar` / `diproses` | `primaryBlue`, latar `#EAF0FF` |
| `dikirim` | `#6B4EE8`, latar `#F0ECFD` (ungu, biar beda dari diproses) |
| `selesai` | `success`, latar `#E7F7ED` |
| `dibatalkan` | `danger`, latar `#FCEAEA` |

### 4.7 Keadaan Layar (4 state wajib)
- **memuat**: skeleton shimmer abu-abu di bentuk kartu/list (bukan spinner
  polos di tengah layar, supaya terasa lebih modern dan sesuai mockup).
- **berhasil**: tampilkan data seperti biasa.
- **kosong**: ilustrasi sederhana (ikon outline besar, warna `textSecondary`)
  + teks ajakan, misalnya "Keranjang masih kosong" + tombol "Mulai Belanja".
- **galat**: ikon outline warning/wifi-off + pesan singkat + tombol
  **"Coba Lagi"** outline (border `danger`, teks `danger`, latar transparan).

---

## 5. Prinsip Umum

1. **Satu layar gelap saja** (beranda/katalog utama), sisanya terang — jangan
   dark mode penuh di semua halaman, ikuti pola mockup.
2. **Rounded besar di mana-mana** (16px ke atas untuk elemen utama), hindari
   sudut tajam.
3. **Jarak putih (whitespace) lega** — jangan padatkan kartu, beri padding 16px
   di dalam setiap kartu.
4. **Satu warna aksen dominan** (`primaryBlue`) untuk semua elemen interaktif
   utama, jangan tambah warna aksen lain supaya tetap terasa satu brand.
5. **Badge status & label jangan pakai warna sama dengan tombol aksi utama**,
   supaya mata langsung bisa bedakan mana yang bisa diklik dan mana yang cuma
   info.

---

## 6. Referensi implementasi Flutter

- Taruh semua warna & style di satu file `lib/theme/app_theme.dart` sebagai
  `ThemeData` dan konstanta warna — jangan tulis hex code berulang-ulang di
  banyak widget.
- Font lewat package `google_fonts`, dipanggil sekali di `MaterialApp(theme: ...)`.
- Badge status & badge pre-order/grosir dibuat sebagai satu widget reusable
  `StatusBadge({required String label, required Color color, required Color background})`
  supaya konsisten dipakai di Katalog, Rincian Produk, dan Riwayat Pesanan.
