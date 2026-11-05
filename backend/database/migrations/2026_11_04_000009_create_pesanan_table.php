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
        Schema::create('pesanan', function (Blueprint $table) {
            $table->engine = 'InnoDB';
            $table->id();
            $table->string('nomor_pesanan', 30)->unique();
            $table->foreignId('pelanggan_id')->constrained('pelanggan')->cascadeOnDelete();
            $table->string('nama_penerima', 100);
            $table->text('alamat');
            $table->string('kota', 100);
            $table->foreignId('wilayah_id')->constrained('wilayah_antar');
            $table->foreignId('kurir_id')->constrained('kurir');
            $table->foreignId('metode_pembayaran_id')->constrained('metode_pembayaran');
            $table->unsignedInteger('subtotal');
            $table->unsignedInteger('ongkos_kirim');
            $table->unsignedInteger('total');
            $table->string('status', 30)->index();
            $table->timestamps();

            $table->index(['pelanggan_id', 'created_at'], 'idx_pesanan_pelanggan_created');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pesanan');
    }
};
