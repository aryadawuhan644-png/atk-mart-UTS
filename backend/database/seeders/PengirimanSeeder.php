<?php

namespace Database\Seeders;

use App\Models\Kurir;
use App\Models\TarifKurir;
use App\Models\WilayahAntar;
use Illuminate\Database\Seeder;

class PengirimanSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. 5 Wilayah Kecamatan Kota Malang
        $wilayahList = [
            ['id' => 1, 'nama' => 'Lowokwaru', 'kota' => 'Kota Malang', 'aktif' => true],
            ['id' => 2, 'nama' => 'Klojen', 'kota' => 'Kota Malang', 'aktif' => true],
            ['id' => 3, 'nama' => 'Blimbing', 'kota' => 'Kota Malang', 'aktif' => true],
            ['id' => 4, 'nama' => 'Sukun', 'kota' => 'Kota Malang', 'aktif' => true],
            ['id' => 5, 'nama' => 'Kedungkandang', 'kota' => 'Kota Malang', 'aktif' => true],
        ];

        foreach ($wilayahList as $w) {
            WilayahAntar::updateOrCreate(
                ['id' => $w['id']],
                [
                    'nama' => $w['nama'],
                    'kota' => $w['kota'],
                    'aktif' => $w['aktif'],
                ]
            );
        }

        // 2. 3 Kurir Internal
        $kurirList = [
            [
                'id' => 1,
                'nama' => 'Kurir Instan Toko (Motor)',
                'deskripsi' => 'Pengantaran kilat hari yang sama (same day)',
                'aktif' => true,
            ],
            [
                'id' => 2,
                'nama' => 'Kurir Reguler Toko',
                'deskripsi' => 'Pengantaran 1-2 hari kerja',
                'aktif' => true,
            ],
            [
                'id' => 3,
                'nama' => 'Kurir Kargo ATK (Mobil Pick-up)',
                'deskripsi' => 'Khusus pesanan grosir dan muatan besar',
                'aktif' => true,
            ],
        ];

        foreach ($kurirList as $k) {
            Kurir::updateOrCreate(
                ['id' => $k['id']],
                [
                    'nama' => $k['nama'],
                    'deskripsi' => $k['deskripsi'],
                    'aktif' => $k['aktif'],
                ]
            );
        }

        // 3. 15 Kombinasi Tarif Kurir (3 Kurir x 5 Wilayah)
        // Toko berlokasi di Sukun (wilayah_id: 4). Tarif Sukun paling murah, wilayah lain menyesuaikan jarak.
        $tarifList = [
            // Kurir 1: Instan Motor
            ['kurir_id' => 1, 'wilayah_id' => 4, 'tarif' => 8000],  // Sukun (Asal)
            ['kurir_id' => 1, 'wilayah_id' => 2, 'tarif' => 10000], // Klojen
            ['kurir_id' => 1, 'wilayah_id' => 5, 'tarif' => 12000], // Kedungkandang
            ['kurir_id' => 1, 'wilayah_id' => 1, 'tarif' => 13000], // Lowokwaru
            ['kurir_id' => 1, 'wilayah_id' => 3, 'tarif' => 15000], // Blimbing

            // Kurir 2: Reguler
            ['kurir_id' => 2, 'wilayah_id' => 4, 'tarif' => 5000],  // Sukun (Asal)
            ['kurir_id' => 2, 'wilayah_id' => 2, 'tarif' => 6000],  // Klojen
            ['kurir_id' => 2, 'wilayah_id' => 5, 'tarif' => 7000],  // Kedungkandang
            ['kurir_id' => 2, 'wilayah_id' => 1, 'tarif' => 8000],  // Lowokwaru
            ['kurir_id' => 2, 'wilayah_id' => 3, 'tarif' => 9000],  // Blimbing

            // Kurir 3: Kargo Pick-up
            ['kurir_id' => 3, 'wilayah_id' => 4, 'tarif' => 25000], // Sukun (Asal)
            ['kurir_id' => 3, 'wilayah_id' => 2, 'tarif' => 30000], // Klojen
            ['kurir_id' => 3, 'wilayah_id' => 5, 'tarif' => 35000], // Kedungkandang
            ['kurir_id' => 3, 'wilayah_id' => 1, 'tarif' => 38000], // Lowokwaru
            ['kurir_id' => 3, 'wilayah_id' => 3, 'tarif' => 40000], // Blimbing
        ];

        foreach ($tarifList as $t) {
            TarifKurir::updateOrCreate(
                [
                    'kurir_id' => $t['kurir_id'],
                    'wilayah_id' => $t['wilayah_id'],
                ],
                [
                    'tarif' => $t['tarif'],
                ]
            );
        }
    }
}
