<?php

namespace Database\Seeders;

use App\Models\MetodePembayaran;
use Illuminate\Database\Seeder;

class MetodePembayaranSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $metodeList = [
            [
                'id' => 1,
                'kode' => 'tunai_di_tempat',
                'nama' => 'Tunai di Tempat (COD)',
            ],
            [
                'id' => 2,
                'kode' => 'transfer_manual',
                'nama' => 'Transfer Bank Manual',
            ],
        ];

        foreach ($metodeList as $item) {
            MetodePembayaran::updateOrCreate(
                ['kode' => $item['kode']],
                [
                    'id' => $item['id'],
                    'nama' => $item['nama'],
                ]
            );
        }
    }
}
