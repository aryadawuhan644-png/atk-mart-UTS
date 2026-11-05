<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            PelangganSeeder::class,
            ProdukSeeder::class,
            HargaGrosirSeeder::class,
            PengirimanSeeder::class,
            MetodePembayaranSeeder::class,
            PesananSeeder::class,
        ]);
    }
}
