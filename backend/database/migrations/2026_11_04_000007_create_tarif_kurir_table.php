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
        Schema::create('tarif_kurir', function (Blueprint $table) {
            $table->engine = 'InnoDB';
            $table->id();
            $table->foreignId('kurir_id')->constrained('kurir')->cascadeOnDelete();
            $table->foreignId('wilayah_id')->constrained('wilayah_antar')->cascadeOnDelete();
            $table->unsignedInteger('tarif');
            $table->timestamps();

            $table->unique(['kurir_id', 'wilayah_id'], 'unique_kurir_wilayah');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tarif_kurir');
    }
};
