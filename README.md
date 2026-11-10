# ATK Mart

**Aplikasi toko online alat tulis kantor (ATK)**

ATK Mart menggunakan Laravel sebagai backend REST API dan Flutter sebagai aplikasi mobile. Aplikasi mendukung katalog, gambar produk, keranjang belanja, checkout, pesanan, serta akses pembeli dan pengelola.

## Teknologi

- Backend: Laravel, PHP, MySQL, REST API
- Mobile: Flutter, Dart, HTTP client, Image Picker
- Tools: Visual Studio Code, Laragon, Postman, Git

## Struktur proyek

```text
atk-mart/
├── backend/   # Laravel REST API
└── mobile/    # Flutter app
```

## Persyaratan

- PHP dan Composer
- MySQL
- Flutter SDK dan Dart SDK
- Android Studio atau Chrome untuk menjalankan aplikasi Flutter

## Menyiapkan backend

Jalankan perintah berikut di PowerShell:

```powershell
cd backend
composer install
Copy-Item .env.example .env
php artisan key:generate
```

Buat database MySQL `atk_mart`, lalu sesuaikan konfigurasi `DB_*` di `.env`.
Tambahkan token API demo berikut; token di aplikasi Flutter harus cocok dengan
nilai di backend:

```env
TOKEN_STATIS_PEMBELI=token-pembeli-atk-mart-2026
TOKEN_STATIS_PEMBELI_2=token-pembeli-2-atk-mart-2026
TOKEN_STATIS_PENGELOLA=token-pengelola-atk-mart-2026
```

Jalankan migrasi dan server:

```powershell
php artisan migrate
php artisan storage:link
php artisan serve --host=0.0.0.0 --port=8000
```

API lokal tersedia di `http://127.0.0.1:8000/api`. Untuk perangkat lain di
jaringan Wi-Fi yang sama, gunakan alamat IP laptop yang menjalankan Laravel.
Pastikan MySQL dan server Laravel tetap berjalan.

## Menyiapkan Flutter

Buka terminal baru:

```powershell
cd mobile
flutter pub get
Copy-Item assets/config/env.json.example assets/config/env.json
```

Contoh konfigurasi sudah memakai token demo yang sama dengan `.env.example`.
Alamat API otomatis dipilih untuk web, desktop, dan Android Emulator jika
`api_base_url` dibiarkan kosong. Untuk perangkat fisik, isi alamat IP laptop
yang menjalankan backend:

```json
{
  "active_role": "pembeli",
  "token_pembeli": "token-pembeli-atk-mart-2026",
  "token_pembeli_2": "token-pembeli-2-atk-mart-2026",
  "token_pengelola": "token-pengelola-atk-mart-2026",
  "api_base_url": "http://192.168.1.10:8000/api"
}
```

Pastikan perangkat fisik dan laptop berada di jaringan Wi-Fi yang sama.
Setelah konfigurasi:

```powershell
flutter run
```

Untuk menjalankan di Chrome:

```powershell
flutter run -d chrome
```

File lokal `mobile/assets/config/env.json` tidak boleh di-commit. Bearer token
statis hanya ditujukan untuk demonstrasi/pengembangan; jangan gunakan token
contoh atau membuka server demo ke jaringan publik.

## Pengujian API

Base URL lokal: `http://127.0.0.1:8000/api`

| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/produk` | Daftar produk |
| GET | `/produk/{id}` | Detail produk |
| GET | `/produk/{id}/gambar` | Gambar produk |
| POST | `/produk` | Tambah produk (pengelola) |
| PUT | `/produk/{id}` | Ubah produk (pengelola) |
| DELETE | `/produk/{id}` | Hapus produk (pengelola) |
| GET/POST/PUT/DELETE | `/keranjang` | Keranjang pembeli |
| POST | `/checkout` | Buat pesanan |
| GET | `/pesanan` | Riwayat pesanan |

Endpoint yang memerlukan autentikasi memakai header
`Authorization: Bearer <token>`. Katalog, detail produk, gambar, dan daftar
kurir dapat diakses tanpa token. Flutter menyediakan pilihan pengurutan produk
berdasarkan harga.

## Kolaborasi Git

Sebelum memperbarui branch, pastikan perubahan lokal sudah disimpan atau
di-commit:

```powershell
git status
git fetch origin
git switch Khatarina_24102033
git merge origin/main
```

Kirim perubahan melalui branch kerja dan Pull Request, bukan push langsung ke
`main`:

```powershell
git add <file-yang-diubah>
git commit -m "Deskripsi perubahan"
git push -u origin Khatarina_24102033
```

## Catatan keamanan

- Jangan commit file `.env` atau `mobile/assets/config/env.json`.
- Jangan gunakan token demo untuk deployment atau layanan yang terekspos publik.
- Hindari `php artisan migrate:fresh` pada database yang memiliki data penting.
- Backup database sebelum mengubah skema.
- Jangan membuka port MySQL ke jaringan publik.

## Pengembang

- Proyek: ATK Mart
- Backend: Laravel REST API
- Frontend: Flutter
- Database: MySQL
