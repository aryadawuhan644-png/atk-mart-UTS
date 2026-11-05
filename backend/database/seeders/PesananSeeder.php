<?php

namespace Database\Seeders;

use App\Models\Pesanan;
use App\Models\PesananDetail;
use App\Models\RiwayatStatusPesanan;
use Illuminate\Database\Seeder;

class PesananSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $pesananData = [
            // Pesanan 1: Status menunggu_pembayaran
            [
                'pesanan' => [
                    'nomor_pesanan' => 'ATK-20261101-00001',
                    'pelanggan_id' => 1,
                    'nama_penerima' => 'Budi Santoso',
                    'alamat' => 'Jl. Soekarno Hatta No. 45',
                    'kota' => 'Kota Malang',
                    'wilayah_id' => 1, // Lowokwaru
                    'kurir_id' => 2,   // Kurir Reguler
                    'metode_pembayaran_id' => 2, // Transfer Manual
                    'subtotal' => 34000,
                    'ongkos_kirim' => 5000,
                    'total' => 39000,
                    'status' => 'menunggu_pembayaran',
                ],
                'details' => [
                    [
                        'produk_id' => 1,
                        'nama_produk' => 'Pulpen Gel Hitam 0.5mm',
                        'harga_normal' => 5000,
                        'harga_satuan' => 5000,
                        'jumlah' => 5,
                        'subtotal' => 25000,
                        'menunggu_stok' => false,
                        'stok_dikurangi' => 5,
                    ],
                    [
                        'produk_id' => 7,
                        'nama_produk' => 'Buku Tulis Garis 38 Lembar',
                        'harga_normal' => 4500,
                        'harga_satuan' => 4500,
                        'jumlah' => 2,
                        'subtotal' => 9000,
                        'menunggu_stok' => false,
                        'stok_dikurangi' => 2,
                    ],
                ],
                'riwayat' => [
                    [
                        'status_lama' => null,
                        'status_baru' => 'menunggu_pembayaran',
                        'aktor' => 'pembeli',
                        'catatan' => 'Pesanan dibuat oleh pembeli',
                    ],
                ],
            ],

            // Pesanan 2: Status dibayar (harga grosir)
            [
                'pesanan' => [
                    'nomor_pesanan' => 'ATK-20261102-00002',
                    'pelanggan_id' => 1,
                    'nama_penerima' => 'Siti Rahmawati',
                    'alamat' => 'Jl. Ijen No. 12',
                    'kota' => 'Kota Malang',
                    'wilayah_id' => 2, // Klojen
                    'kurir_id' => 1,   // Kurir Instan Motor
                    'metode_pembayaran_id' => 2, // Transfer Manual
                    'subtotal' => 67500,
                    'ongkos_kirim' => 10000,
                    'total' => 77500,
                    'status' => 'dibayar',
                ],
                'details' => [
                    [
                        'produk_id' => 1,
                        'nama_produk' => 'Pulpen Gel Hitam 0.5mm',
                        'harga_normal' => 5000,
                        'harga_satuan' => 4500, // Harga grosir tier 1
                        'jumlah' => 15,
                        'subtotal' => 67500,
                        'menunggu_stok' => false,
                        'stok_dikurangi' => 15,
                    ],
                ],
                'riwayat' => [
                    [
                        'status_lama' => null,
                        'status_baru' => 'menunggu_pembayaran',
                        'aktor' => 'pembeli',
                        'catatan' => 'Pesanan dibuat',
                    ],
                    [
                        'status_lama' => 'menunggu_pembayaran',
                        'status_baru' => 'menunggu_konfirmasi',
                        'aktor' => 'pembeli',
                        'catatan' => 'Bukti transfer diunggah',
                    ],
                    [
                        'status_lama' => 'menunggu_konfirmasi',
                        'status_baru' => 'dibayar',
                        'aktor' => 'pengelola',
                        'catatan' => 'Pembayaran diverifikasi pengelola',
                    ],
                ],
            ],

            // Pesanan 3: Status menunggu_stok (Pre-order)
            [
                'pesanan' => [
                    'nomor_pesanan' => 'ATK-20261103-00003',
                    'pelanggan_id' => 1,
                    'nama_penerima' => 'Ahmad Dahlan',
                    'alamat' => 'Jl. Borobudur No. 8',
                    'kota' => 'Kota Malang',
                    'wilayah_id' => 3, // Blimbing
                    'kurir_id' => 2,   // Kurir Reguler
                    'metode_pembayaran_id' => 1, // Tunai di Tempat (COD)
                    'subtotal' => 65000,
                    'ongkos_kirim' => 5000,
                    'total' => 70000,
                    'status' => 'menunggu_stok',
                ],
                'details' => [
                    [
                        'produk_id' => 12,
                        'nama_produk' => 'Paket Persiapan Ujian Nasional 2027',
                        'harga_normal' => 65000,
                        'harga_satuan' => 65000,
                        'jumlah' => 1,
                        'subtotal' => 65000,
                        'menunggu_stok' => true,
                        'stok_dikurangi' => 0,
                    ],
                ],
                'riwayat' => [
                    [
                        'status_lama' => null,
                        'status_baru' => 'menunggu_stok',
                        'aktor' => 'sistem',
                        'catatan' => 'Pesanan memuat produk pre-order, menunggu pasokan fisik',
                    ],
                ],
            ],
        ];

        foreach ($pesananData as $data) {
            $pesanan = Pesanan::updateOrCreate(
                ['nomor_pesanan' => $data['pesanan']['nomor_pesanan']],
                $data['pesanan']
            );

            foreach ($data['details'] as $detail) {
                PesananDetail::updateOrCreate(
                    [
                        'pesanan_id' => $pesanan->id,
                        'nama_produk' => $detail['nama_produk'],
                    ],
                    array_merge($detail, ['pesanan_id' => $pesanan->id])
                );
            }

            foreach ($data['riwayat'] as $r) {
                RiwayatStatusPesanan::updateOrCreate(
                    [
                        'pesanan_id' => $pesanan->id,
                        'status_baru' => $r['status_baru'],
                    ],
                    array_merge($r, ['pesanan_id' => $pesanan->id])
                );
            }
        }
    }
}
