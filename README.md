# ATK Mart

**Aplikasi Toko Online Alat Tulis Kantor (ATK)**

ATK Mart merupakan aplikasi toko online yang dikembangkan menggunakan Laravel sebagai REST API Backend dan Flutter sebagai aplikasi Frontend. Aplikasi ini menyediakan fitur pengelolaan produk dan transaksi pembelian alat tulis kantor.

## Teknologi yang Digunakan

### Backend
- Laravel
- PHP
- MySQL
- REST API
- Bearer Token Authentication

### Frontend
- Flutter
- Dart
- HTTP Client
- Image Picker

### Tools
- Visual Studio Code
- Laragon
- Postman
- Git & GitHub
- phpMyAdmin

## Struktur Folder

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

## Fitur Aplikasi

### Backend
- REST API untuk pengelolaan data.
- Pengelolaan produk.
- Upload dan pengelolaan gambar produk.
- Pengelolaan keranjang belanja.
- Pengelolaan pesanan.
- Pengelolaan status pesanan.
- Pengelolaan kurir dan tarif pengiriman.
- Pemisahan akses pembeli dan pengelola.

### Flutter
- Tampilan katalog produk.
- Menampilkan gambar produk.
- Pengelolaan keranjang.
- Proses pemesanan.
- Riwayat pesanan.
- Navigasi aplikasi pembeli.
- Integrasi dengan Laravel REST API.

## Persyaratan Sistem

Pastikan perangkat sudah memiliki:
- PHP dan Composer.
- MySQL.
- Laravel dependencies.
- Flutter SDK.
- Dart SDK.
- Android Studio atau browser untuk menjalankan Flutter.

## Instalasi Backend

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

7. Jalankan migrasi database:

```powershell
php artisan migrate
```

8. Buat symbolic link untuk penyimpanan gambar:

```powershell
php artisan storage:link
```

## Menjalankan Backend

Dari folder `backend`, jalankan:

```powershell
php artisan serve --host=0.0.0.0 --port=8000
```

Alamat API:

```text
http://127.0.0.1:8000/api
```

Untuk perangkat lain dalam jaringan Wi-Fi yang sama, gunakan IP laptop server, misalnya:

```text
http://172.16.187.57:8000/api
```

Pastikan laptop server tetap menyala dan Laravel serta MySQL berjalan.

## Instalasi Flutter

1. Buka terminal baru.
2. Masuk ke folder Flutter:

```powershell
cd mobile
```

3. Install dependencies:

```powershell
flutter pub get
```

4. Periksa konfigurasi API pada:

```text
assets/config/env.json
```

Contoh konfigurasi untuk menjalankan Flutter di laptop server sendiri:

```json
{
  "active_role": "pembeli",
  "token_pembeli": "token-pembeli-atk-mart-2026",
  "token_pengelola": "token-pengelola-atk-mart-2026",
  "api_base_url": "http://127.0.0.1:8000/api"
}
```

Untuk perangkat lain yang mengakses server melalui Wi-Fi, gunakan alamat IP laptop server sebagai pengganti `127.0.0.1`.

5. Jalankan aplikasi:

```powershell
flutter run
```

Untuk menjalankan melalui Chrome:

```powershell
flutter run -d chrome
```

## Pengujian API

API dapat diuji menggunakan Postman.

Base URL:

```text
http://127.0.0.1:8000/api
```

Untuk pengujian dari perangkat lain, gunakan IP laptop server.

Contoh endpoint:

| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/produk` | Mengambil daftar produk |
| POST | `/produk` | Menambahkan produk |
| GET | `/produk/{id}` | Mengambil detail produk |
| PUT | `/produk/{id}` | Mengubah produk |
| DELETE | `/produk/{id}` | Menghapus produk |

Gunakan token sesuai peran pengguna apabila endpoint memerlukan autentikasi.

## Kolaborasi Tim

Repository GitHub:

https://github.com/aryadawuhan644-png/atk-mart-UTS

Untuk mengambil perubahan terbaru:

```powershell
git pull origin main
```

Untuk melihat status perubahan:

```powershell
git status
```

Untuk mengirim perubahan ke GitHub:

```powershell
git add .
git commit -m "Deskripsi perubahan"
git push origin main
```

Pastikan perubahan anggota tim sudah diperiksa sebelum melakukan commit dan push.

## Catatan Penting

- Jangan mengunggah file `.env` ke GitHub.
- Jangan mengunggah password database atau token rahasia.
- Jangan menjalankan `php artisan migrate:fresh` pada database yang berisi data penting.
- Backup database sebelum melakukan perubahan struktur database.
- Perangkat lain tidak perlu menjalankan MySQL. Cukup mengakses API melalui jaringan yang sama.
- Jangan membuka port MySQL ke jaringan publik.

## Pengembang

**Proyek:** ATK Mart  
**Jenis:** Aplikasi Toko Online Alat Tulis Kantor  
**Backend:** Laravel REST API  
**Frontend:** Flutter  
**Database:** MySQL
