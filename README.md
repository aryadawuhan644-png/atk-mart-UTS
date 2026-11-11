# ATK Mart

**Aplikasi Toko Online Buku dan Alat Tulis (ATK)**

ATK Mart merupakan aplikasi toko online yang dikembangkan menggunakan Laravel sebagai REST API Backend dan Flutter sebagai aplikasi Frontend. Aplikasi ini menyediakan katalog produk, keranjang, checkout, dan pengelolaan pesanan untuk buku dan alat tulis kantor.

Proyek ini disusun sebagai Tugas Pengganti UTS mata kuliah Pemrograman Aplikasi Perangkat Bergerak (PAPB) dan Sistem Terdistribusi, S1 Informatika, ITSK RS dr. Soepraoen Kesdam V/BRW.

## Daftar Isi

1. [Identitas Kelompok](#1-identitas-kelompok)
2. [Domain Bisnis dan Aturan Bisnis Khas](#2-domain-bisnis-dan-aturan-bisnis-khas)
3. [Cara Menjalankan Backend](#3-cara-menjalankan-backend)
4. [Cara Menjalankan Aplikasi Flutter](#4-cara-menjalankan-aplikasi-flutter)
5. [Alamat Server untuk Emulator](#5-alamat-server-untuk-emulator)
6. [Akun Uji (Token Statis)](#6-akun-uji-token-statis)
7. [Daftar Endpoint Ringkas](#7-daftar-endpoint-ringkas)
8. [Informasi Tambahan](#9-informasi-tambahan)

---

## 1. Identitas Kelompok

**Nama Kelompok:** Kelompok 6

| No | Nama Lengkap | NIM |
|---|---|---|---|
| 1 | Khatarina Lusia Ose | 24102033 |
| 2 | Arya Anugrah Saputra | 24102027 | 
| 3 | Veronica Ananda Eka Cristya | 24102021 | 
| 4 | Anggun Tri Pratiwi | 24102026 | 
| 5 | Dewi Nafiatul Khusnaini | 24102031 | 
| 6 | Salma Nurul Aliyah | 24102036 |

## 2. Domain Bisnis dan Aturan Bisnis Khas

**Domain bisnis:** Toko online Buku dan Alat Tulis (ATK Mart). Ciri khas domain: **produk pre-order** dan **harga grosir bertingkat**.

Dua peran pengguna:

- **Pembeli**: melihat katalog, mengelola keranjang, checkout, melihat riwayat pesanan, serta mengonfirmasi pembayaran dan penerimaan pesanan.
- **Pengelola**: mengelola produk, serta memproses status pesanan (dibayar, diproses, dikirim).

### Aturan bisnis khas

1. **Harga grosir bertingkat.** Harga satuan tiap baris keranjang mengikuti tingkat `harga_grosir` dengan `min_kuantitas` terbesar yang terpenuhi oleh jumlah pembelian. Jika tidak ada tingkat yang terpenuhi, dipakai harga normal. Contoh: produk id 1 berharga normal Rp7.500, tetapi pembelian 13 unit dihitung Rp4.500 per unit (tingkat grosir minimal 10 unit).
2. **Pre-order.** Produk dengan `pre_order=true` dan `tersedia=true` boleh dipesan walau stok 0. Pesanannya berstatus `menunggu_stok` dan stok tidak dikurangi menjadi negatif.

Aturan pendukung lain yang ditegakkan server:

- Produk `tersedia=false` ditolak (409), termasuk yang bertanda pre-order.
- Produk non-pre-order dengan stok kurang dari jumlah diminta ditolak (409).
- Produk yang masih ada pada pesanan aktif tidak dapat dihapus (409).
- Nama dan harga pada rincian pesanan adalah salinan saat pembelian (snapshot), sehingga perubahan produk tidak mengubah pesanan lama.
- Pengiriman hanya ke wilayah aktif di Kota Malang (Lowokwaru, Klojen, Blimbing, Sukun, Kedungkandang); ongkos kirim dihitung dari pasangan kurir dan wilayah.
- Checkout bersifat idempoten melalui header `X-Kunci-Idempoten` sehingga percobaan ulang tidak membuat pesanan ganda.
- Subtotal, ongkos kirim, dan total dihitung di server; Flutter hanya menampilkan nilai respons.

### Alur status pesanan

`menunggu_pembayaran` → `menunggu_konfirmasi` → `dibayar` → `diproses` → `dikirim` → `selesai`

Status `dibatalkan` hanya dapat dicapai dari `menunggu_pembayaran` dan `menunggu_konfirmasi`. Perpindahan di luar alur ditolak dengan 409.

| Dari | Ke | Pelaku |
|---|---|---|
| menunggu_pembayaran | menunggu_konfirmasi | Pembeli |
| menunggu_konfirmasi | dibayar | Pengelola |
| dibayar | diproses | Pengelola |
| diproses | dikirim | Pengelola |
| dikirim | selesai | Pembeli |

### Teknologi yang Digunakan

**Backend:** Laravel, PHP, MySQL, REST API, Bearer Token Authentication

**Frontend:** Flutter, Dart, paket `http`, Image Picker

**Tools:** Visual Studio Code, Laragon, Postman, Git & GitHub, phpMyAdmin

### Struktur Folder

```text
atk-mart/
│
├── backend/          # Laravel REST API
│   ├── app/
│   ├── database/
│   ├── routes/
│   ├── storage/
│   └── .env
│
├── mobile/           # Flutter Application
│   ├── lib/
│   ├── assets/
│   ├── android/
│   └── pubspec.yaml
│
└── README.md
```

## 3. Cara Menjalankan Backend

### Persyaratan

- PHP dan Composer
- MySQL
- Git

### Langkah-langkah

1. Masuk ke folder backend:

```powershell
cd backend
```

2. Install dependencies:

```powershell
composer install
```

3. Salin konfigurasi environment jika `.env` belum tersedia:

```powershell
Copy-Item .env.example .env
```

4. Generate application key:

```powershell
php artisan key:generate
```

5. Buat database MySQL dengan nama:

```text
atk_mart
```

6. Sesuaikan konfigurasi database pada file `.env`:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=atk_mart
DB_USERNAME=root
DB_PASSWORD=
```

Sesuaikan username dan password dengan konfigurasi MySQL masing-masing.

7. Jalankan migrasi database beserta data awal (seeder: produk, kurir, wilayah, tarif, metode pembayaran, dan pesanan contoh):

```powershell
php artisan migrate --seed
```

8. Buat symbolic link untuk penyimpanan gambar:

```powershell
php artisan storage:link
```

9. Jalankan server:

```powershell
php artisan serve --host=0.0.0.0 --port=8000
```

Alamat API:

```text
http://127.0.0.1:8000/api
```

Untuk perangkat lain dalam jaringan Wi-Fi yang sama, gunakan IP laptop server, misalnya `http://172.16.187.57:8000/api`. Pastikan laptop server tetap menyala serta Laravel dan MySQL berjalan.

## 4. Cara Menjalankan Aplikasi Flutter

### Persyaratan

- Flutter SDK dan Dart SDK
- Android Studio (emulator) atau browser Chrome

### Langkah-langkah

1. Buka terminal baru, lalu masuk ke folder Flutter:

```powershell
cd mobile
```

2. Install dependencies:

```powershell
flutter pub get
```

3. Atur alamat server API pada file berikut (**di sinilah alamat server diubah**):

```text
mobile/assets/config/env.json
```

Contoh isi file:

```json
{
  "active_role": "pembeli",
  "token_pembeli": "token-pembeli-atk-mart-2026",
  "token_pengelola": "token-pengelola-atk-mart-2026",
  "api_base_url": "http://127.0.0.1:8000/api"
}
```

Nilai `api_base_url` disesuaikan dengan tempat aplikasi dijalankan (lihat bagian 5).

4. Jalankan aplikasi:

```powershell
flutter run
```

Untuk menjalankan melalui Chrome:

```powershell
flutter run -d chrome
```

## 5. Alamat Server untuk Emulator

Saat aplikasi dijalankan di **emulator Android**, alamat `127.0.0.1` (localhost) merujuk ke emulator itu sendiri, bukan ke laptop yang menjalankan Laravel. Karena itu, gunakan alamat khusus berikut yang diteruskan emulator ke localhost laptop:

```text
http://10.0.2.2:8000/api
```

Contoh `assets/config/env.json` untuk emulator:

```json
{
  "active_role": "pembeli",
  "token_pembeli": "token-pembeli-atk-mart-2026",
  "token_pengelola": "token-pengelola-atk-mart-2026",
  "api_base_url": "http://10.0.2.2:8000/api"
}
```

| Lingkungan | Nilai `api_base_url` |
|---|---|
| Emulator Android | `http://10.0.2.2:8000/api` |
| Chrome / Desktop | `http://127.0.0.1:8000/api` |
| HP fisik (Wi-Fi sama dengan laptop) | `http://<IP-laptop>:8000/api` |

Untuk HP fisik, pastikan backend dijalankan dengan `--host=0.0.0.0` dan perangkat berada pada jaringan Wi-Fi yang sama dengan laptop server.

## 6. Akun Uji (Token Statis)

Aplikasi belum memakai alur login penuh. Identitas diwakili token statis, sehingga penguji dapat langsung mencoba tanpa registrasi:

| Peran | Token | Akses |
|---|---|---|
| Publik | (tanpa token) | `GET /produk`, `GET /produk/{id}`, `GET /kurir` |
| Pembeli | `token-pembeli-atk-mart-2026` | `/keranjang`, `POST /checkout`, `GET /pesanan`, status ke `menunggu_konfirmasi` dan `selesai` |
| Pengelola | `token-pengelola-atk-mart-2026` | `POST/PUT/DELETE /produk`, status ke `dibayar`, `diproses`, `dikirim` |

Cara penggunaan:

- **Postman / API:** kirim token sebagai header `Authorization: Bearer <token>`.
- **Aplikasi Flutter:** ubah nilai `active_role` pada `assets/config/env.json` menjadi `pembeli` atau `pengelola`.

```json
"token_pembeli": "token-pembeli-atk-mart-2026",
"token_pengelola": "token-pengelola-atk-mart-2026",
```

> Token di atas hanya untuk keperluan pengujian dan bukan kredensial produksi.

## 7. Daftar Endpoint Ringkas

Base URL: `http://127.0.0.1:8000/api`. Seluruh respons berformat JSON dengan pembungkus seragam: `status`, `code`, `message`, `data` (galat validasi 422 memuat `errors` per kolom). Semua nilai uang berupa bilangan bulat Rupiah.

| No | Method | Endpoint | Akses | Keterangan |
|---|---|---|---|---|
| 1 | GET | `/produk` | Publik | Daftar produk (query opsional `kategori`, `cari`) |
| 2 | GET | `/produk/{id}` | Publik | Detail produk beserta tingkat harga grosir |
| 3 | POST | `/produk` | Pengelola | Menambah produk |
| 4 | PUT | `/produk/{id}` | Pengelola | Mengubah produk |
| 5 | DELETE | `/produk/{id}` | Pengelola | Menghapus produk (409 jika dipakai pesanan aktif) |
| 6 | GET | `/keranjang` | Pembeli | Isi keranjang dan subtotal dari server |
| 7 | POST | `/keranjang` | Pembeli | Menambah produk (`produk_id`, `jumlah`) |
| 8 | PUT | `/keranjang/{id}` | Pembeli | Mengubah jumlah (`id` = id baris keranjang) |
| 9 | DELETE | `/keranjang/{id}` | Pembeli | Menghapus baris keranjang |
| 10 | GET | `/kurir` | Publik | Kurir, wilayah, dan tarif pengiriman |
| 11 | POST | `/checkout` | Pembeli | Membuat pesanan; wajib header `X-Kunci-Idempoten` |
| 12 | GET | `/pesanan` | Pembeli | Riwayat pesanan, terbaru dahulu |
| 13 | GET | `/pesanan/{id}` | Pembeli | Detail pesanan dan riwayat status |
| 14 | PATCH | `/pesanan/{id}/status` | Pembeli / Pengelola | Mengubah status sesuai alur yang sah |

Kode status: `200` berhasil, `201` data baru dibuat, `404` tidak ditemukan, `409` bertentangan dengan keadaan server (stok, status tidak sah, produk terpakai), `422` validasi gagal, `500` galat server.

**Dokumentasi lengkap:** dokumen *Dokumentasi API ATK Mart* (diagram relasi tabel, contoh request/response nyata, perhitungan ongkos kirim, aturan bisnis, dan panduan Postman) pada [isi tautan, mis. `docs/Laporan_PAPB-UTS_Kelompok06_BukuAlatTulis.pdf` di repository]. Koleksi Postman: [isi tautan koleksi "ATK Mart - Laravel REST API"].


## 8. Informasi Tambahan

### Pengujian API dengan Postman

Koleksi "ATK Mart - Laravel REST API" memuat 29 request dalam 7 folder. Impor ke Postman, isi variabel koleksi (`base_url`, `buyer_token`, `manager_token`, dll.), lalu jalankan berurutan per folder. Untuk membuat pesanan baru, ganti nilai header `X-Kunci-Idempoten` dengan kunci yang belum pernah dipakai.

### Kolaborasi Tim

Repository GitHub: https://github.com/aryadawuhan644-png/atk-mart-UTS

```powershell
git pull origin main        # mengambil perubahan terbaru
git status                  # melihat status perubahan
git add .
git commit -m "Deskripsi perubahan"
git push origin main        # mengirim perubahan ke GitHub
```

Pastikan perubahan anggota tim sudah diperiksa sebelum melakukan commit dan push.

### Catatan Penting

- Jangan mengunggah file `.env` ke GitHub.
- Jangan mengunggah password database atau token rahasia (token pada README ini hanya token uji).
- Jangan menjalankan `php artisan migrate:fresh` pada database yang berisi data penting. Untuk data demo yang bersih, `php artisan migrate:fresh --seed` boleh dijalankan pada database lokal.
- Backup database sebelum melakukan perubahan struktur database.
- Perangkat lain tidak perlu menjalankan MySQL. Cukup mengakses API melalui jaringan yang sama.
- Jangan membuka port MySQL ke jaringan publik.
