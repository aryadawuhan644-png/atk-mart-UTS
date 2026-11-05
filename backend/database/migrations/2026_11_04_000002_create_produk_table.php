<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('produk', function (Blueprint $table) {
            $table->engine = 'InnoDB';
            $table->id();
            $table->string('nama', 150);
            $table->unsignedInteger('harga');
            $table->string('kategori', 60)->index();
            $table->unsignedInteger('stok');
            $table->boolean('tersedia')->default(true);
            $table->text('deskripsi')->nullable();
            $table->boolean('pre_order')->default(false);
            $table->date('estimasi_tersedia')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('produk');
    }
};
