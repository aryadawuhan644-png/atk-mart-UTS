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
        $tarifList = [
            // Kurir 1: Instan Motor
            ['kurir_id' => 1, 'wilayah_id' => 1, 'tarif' => 8000],
            ['kurir_id' => 1, 'wilayah_id' => 2, 'tarif' => 10000],
            ['kurir_id' => 1, 'wilayah_id' => 3, 'tarif' => 9000],
            ['kurir_id' => 1, 'wilayah_id' => 4, 'tarif' => 12000],
            ['kurir_id' => 1, 'wilayah_id' => 5, 'tarif' => 14000],

            // Kurir 2: Reguler
            ['kurir_id' => 2, 'wilayah_id' => 1, 'tarif' => 5000],
            ['kurir_id' => 2, 'wilayah_id' => 2, 'tarif' => 6000],
            ['kurir_id' => 2, 'wilayah_id' => 3, 'tarif' => 5000],
            ['kurir_id' => 2, 'wilayah_id' => 4, 'tarif' => 7000],
            ['kurir_id' => 2, 'wilayah_id' => 5, 'tarif' => 8000],

            // Kurir 3: Kargo Pick-up
            ['kurir_id' => 3, 'wilayah_id' => 1, 'tarif' => 25000],
            ['kurir_id' => 3, 'wilayah_id' => 2, 'tarif' => 30000],
            ['kurir_id' => 3, 'wilayah_id' => 3, 'tarif' => 25000],
            ['kurir_id' => 3, 'wilayah_id' => 4, 'tarif' => 35000],
            ['kurir_id' => 3, 'wilayah_id' => 5, 'tarif' => 40000],
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
