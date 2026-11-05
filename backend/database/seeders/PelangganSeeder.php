<?php

namespace Database\Seeders;

use App\Models\Pelanggan;
use Illuminate\Database\Seeder;

class PelangganSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        Pelanggan::updateOrCreate(
            ['id' => 1],
            ['nama' => 'Pelanggan Demo ATK Mart']
        );
    }
}
