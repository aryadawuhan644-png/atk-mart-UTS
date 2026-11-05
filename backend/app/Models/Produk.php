<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Produk extends Model
{
    use HasFactory;

    protected $table = 'produk';

    protected $fillable = [
        'nama',
        'harga',
        'kategori',
        'stok',
        'tersedia',
        'deskripsi',
        'pre_order',
        'estimasi_tersedia',
    ];

    protected $casts = [
        'harga' => 'integer',
        'stok' => 'integer',
        'tersedia' => 'boolean',
        'pre_order' => 'boolean',
        'estimasi_tersedia' => 'date',
    ];

    public function hargaGrosir(): HasMany
    {
        return $this->hasMany(HargaGrosir::class, 'produk_id', 'id')->orderBy('min_kuantitas', 'asc');
    }

    public function keranjang(): HasMany
    {
        return $this->hasMany(Keranjang::class, 'produk_id', 'id');
    }

    public function pesananDetail(): HasMany
    {
        return $this->hasMany(PesananDetail::class, 'produk_id', 'id');
    }
}
