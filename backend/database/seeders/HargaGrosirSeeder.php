<?php

namespace Database\Seeders;

use App\Models\HargaGrosir;
use Illuminate\Database\Seeder;

class HargaGrosirSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $grosirList = [
            // Produk 1: Pulpen Gel Hitam 0.5mm (Harga normal: 5.000)
            [
                'produk_id' => 1,
                'min_kuantitas' => 10,
                'harga_satuan' => 4500,
            ],
            [
                'produk_id' => 1,
                'min_kuantitas' => 50,
                'harga_satuan' => 4000,
            ],

            // Produk 2: Pensil 2B Ujian (Harga normal: 3.000)
            [
                'produk_id' => 2,
                'min_kuantitas' => 12,
                'harga_satuan' => 2700,
            ],
            [
                'produk_id' => 2,
                'min_kuantitas' => 36,
                'harga_satuan' => 2400,
            ],

            // Produk 7: Buku Tulis Garis 38 Lembar (Harga normal: 4.500)
            [
                'produk_id' => 7,
                'min_kuantitas' => 10,
                'harga_satuan' => 4000,
            ],
            [
                'produk_id' => 7,
                'min_kuantitas' => 25,
                'harga_satuan' => 3600,
            ],
        ];

        foreach ($grosirList as $item) {
            HargaGrosir::updateOrCreate(
                [
                    'produk_id' => $item['produk_id'],
                    'min_kuantitas' => $item['min_kuantitas'],
                ],
                [
                    'harga_satuan' => $item['harga_satuan'],
                ]
            );
        }
    }
}
