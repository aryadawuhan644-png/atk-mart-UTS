<?php

namespace Database\Seeders;

use App\Models\Produk;
use Illuminate\Database\Seeder;

class ProdukSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $produkList = [
            [
                'id' => 1,
                'nama' => 'Pulpen Gel Hitam 0.5mm',
                'harga' => 5000,
                'kategori' => 'Alat Tulis',
                'stok' => 50,
                'tersedia' => true,
                'deskripsi' => 'Pulpen gel tinta hitam pekat, ketebalan 0.5mm, anti macet.',
                'pre_order' => false,
                'estimasi_tersedia' => null,
            ],
            [
                'id' => 2,
                'nama' => 'Pensil 2B Ujian',
                'harga' => 3000,
                'kategori' => 'Alat Tulis',
                'stok' => 100,
                'tersedia' => true,
                'deskripsi' => 'Pensil grafit 2B standar komputer OMR untuk ujian.',
                'pre_order' => false,
                'estimasi_tersedia' => null,
            ],
            [
                'id' => 3,
                'nama' => 'Penghapus Putih Karet',
                'harga' => 2500,
                'kategori' => 'Alat Tulis',
                'stok' => 40,
                'tersedia' => true,
                'deskripsi' => 'Penghapus karet bebas debu tidak merusak kertas.',
                'pre_order' => false,
                'estimasi_tersedia' => null,
            ],
            [
                'id' => 4,
                'nama' => 'Penggaris Besi 30 cm',
                'harga' => 6000,
                'kategori' => 'Alat Tulis',
                'stok' => 30,
                'tersedia' => true,
                'deskripsi' => 'Penggaris logam stainless steel 30 cm presisi.',
                'pre_order' => false,
                'estimasi_tersedia' => null,
            ],
            [
                'id' => 5,
                'nama' => 'Stabilo Highlighter Kuning',
                'harga' => 8500,
                'kategori' => 'Alat Tulis',
                'stok' => 25,
                'tersedia' => true,
                'deskripsi' => 'Penanda teks fluorescent warna kuning cerah tahan lama.',
                'pre_order' => false,
                'estimasi_tersedia' => null,
            ],
            [
                'id' => 6,
                'nama' => 'Spidol Whiteboard Hitam',
                'harga' => 9000,
                'kategori' => 'Alat Tulis',
                'stok' => 35,
                'tersedia' => true,
                'deskripsi' => 'Spidol papan tulis mudah dihapus dan tidak berbau tajam.',
                'pre_order' => false,
                'estimasi_tersedia' => null,
            ],
            [
                'id' => 7,
                'nama' => 'Buku Tulis Garis 38 Lembar',
                'harga' => 4500,
                'kategori' => 'Buku & Perlengkapan Belajar',
                'stok' => 80,
                'tersedia' => true,
                'deskripsi' => 'Buku tulis bergaris ukuran standar sekolah 38 lembar.',
                'pre_order' => false,
                'estimasi_tersedia' => null,
            ],
            [
                'id' => 8,
                'nama' => 'Buku Gambar A4 Tebal',
                'harga' => 12000,
                'kategori' => 'Buku & Perlengkapan Belajar',
                'stok' => 30,
                'tersedia' => true,
                'deskripsi' => 'Buku gambar kertas tebal 120 gsm ukuran A4 isi 20 lembar.',
                'pre_order' => false,
                'estimasi_tersedia' => null,
            ],
            [
                'id' => 9,
                'nama' => 'Buku Catatan Hardcover A5',
                'harga' => 22000,
                'kategori' => 'Buku & Perlengkapan Belajar',
                'stok' => 20,
                'tersedia' => true,
                'deskripsi' => 'Notebook agenda jilid tebal hardcover pita pembatas.',
                'pre_order' => false,
                'estimasi_tersedia' => null,
            ],
            [
                'id' => 10,
                'nama' => 'Pena Gel Kaligrafi Eksklusif',
                'harga' => 15000,
                'kategori' => 'Alat Tulis',
                'stok' => 0,
                'tersedia' => true,
                'deskripsi' => 'Pena tinta kaligrafi (stok sengaja 0 untuk uji penolakan).',
                'pre_order' => false,
                'estimasi_tersedia' => null,
            ],
            [
                'id' => 11,
                'nama' => 'Buku Ensiklopedia Lawas',
                'harga' => 45000,
                'kategori' => 'Buku & Perlengkapan Belajar',
                'stok' => 10,
                'tersedia' => false,
                'deskripsi' => 'Buku referensi discontinued (tersedia=false untuk uji penolakan).',
                'pre_order' => false,
                'estimasi_tersedia' => null,
            ],
            [
                'id' => 12,
                'nama' => 'Paket Persiapan Ujian Nasional 2027',
                'harga' => 65000,
                'kategori' => 'Buku & Perlengkapan Belajar',
                'stok' => 0,
                'tersedia' => true,
                'deskripsi' => 'Paket buku bank soal intensif pre-order cetakan baru.',
                'pre_order' => true,
                'estimasi_tersedia' => '2026-11-20',
            ],
        ];

        foreach ($produkList as $item) {
            Produk::updateOrCreate(
                ['id' => $item['id']],
                $item
            );
        }
    }
}
