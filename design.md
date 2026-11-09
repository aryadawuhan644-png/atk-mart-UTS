# Panduan Desain — ATK Mart Aoen (Buku & Alat Tulis)

Acuan visual ini dipakai supaya semua halaman Flutter (Katalog, Rincian Produk,
Keranjang, Checkout, dst) konsisten satu sama lain. Gaya bersih, modern, dan
rounded dengan biru navy `#011C6B`, aksen teal dan amber bercahaya, serta
latar biru pucat yang tetap nyaman dibaca.

---

## 1. Palet Warna

| Token | Hex | Dipakai untuk |
|---|---|---|
| `primary` | `#011C6B` | Identitas merek, tombol utama, pilihan aktif, dan navigasi |
| `primaryDark` | `#00134D` | Elemen utama yang memerlukan penekanan |
| `accent` | `#007F87` | Aksen teal, info, dan variasi visual |
| `accentWarm` | `#A85D00` | Pre-order, highlight hangat, dan status menunggu |
| `accentEarth` | `#955A0B` | Aksen cokelat karamel bercahaya untuk akun sekunder dan status dikirim |
| `surfaceLight` | `#F5F8FF` | Latar layar terang kebiruan |
| `surfaceCard` | `#FFFFFF` | Latar kartu produk dan kategori |
| `surfaceMuted` | `#EAF1FF` | Latar ikon kategori dan chip filter tidak aktif |
| `textPrimary` | `#182B4D` | Judul, nama produk, dan harga |
| `textSecondary` | `#536887` | Deskripsi singkat, label kecil, dan placeholder |
| `success` | `#16754B` | Badge diskon/hemat dan status "selesai" |
| `warning` | `#A85D00` | Status "menunggu_stok" / "menunggu_pembayaran" |
| `danger` | `#B42318` | Pesan galat dan badge stok habis |
| `border` | `#D8E3F5` | Garis tipis antar elemen dan outline input |

**Catatan khusus domain:** karena produk kalian ada yang **pre-order**, pakai
`warning` untuk badge "Pre-Order" (bukan `danger`), supaya beda kesan dari
"Stok Habis" yang pakai `danger`. Badge "Harga Grosir" pakai `primary`
dengan latar `#E8F1FB`.

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
butuh slot). Item aktif pakai background `primary` bentuk pill di sekitar
ikon+label, item lain abu-abu (`textSecondary`). Badge jumlah di ikon
Keranjang: lingkaran kecil `primary`, teks putih, posisi pojok kanan atas.

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
  full-width `primary`.

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
| `menunggu_stok` | `warning`, latar `#F5EDDD` |
| `menunggu_pembayaran` | `warning`, latar `#F5EDDD` |
| `menunggu_konfirmasi` | `primary`, latar `#E8F1FB` |
| `dibayar` / `diproses` | `primary`, latar `#E8F1FB` |
| `dikirim` | `#955A0B`, latar `#FFF2D6` (cokelat karamel, biar beda dari diproses) |
| `selesai` | `success`, latar `#EAF3ED` |
| `dibatalkan` | `danger`, latar `#F8EAEA` |

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

1. **Gunakan tampilan terang yang konsisten** dengan `#011C6B` sebagai warna
   utama; tambahkan teal, amber, dan warna status seperlunya agar hierarki
   informasi jelas tanpa membuat layar monoton atau terlalu jenuh.
2. **Rounded besar di mana-mana** (16px ke atas untuk elemen utama), hindari
   sudut tajam.
3. **Jarak putih (whitespace) lega** — jangan padatkan kartu, beri padding 16px
   di dalam setiap kartu.
4. **Gunakan `primary` sebagai aksi utama**; teal dan amber hanya jadi aksen
   pendamping untuk membantu hierarki tanpa mengalahkan identitas merek.
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
