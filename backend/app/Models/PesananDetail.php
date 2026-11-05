<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PesananDetail extends Model
{
    use HasFactory;

    protected $table = 'pesanan_detail';

    protected $fillable = [
        'pesanan_id',
        'produk_id',
        'nama_produk',
        'harga_normal',
        'harga_satuan',
        'jumlah',
        'subtotal',
        'menunggu_stok',
        'stok_dikurangi',
    ];

    protected $casts = [
        'harga_normal' => 'integer',
        'harga_satuan' => 'integer',
        'jumlah' => 'integer',
        'subtotal' => 'integer',
        'menunggu_stok' => 'boolean',
        'stok_dikurangi' => 'integer',
    ];

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class, 'pesanan_id', 'id');
    }

    public function produk(): BelongsTo
    {
        return $this->belongsTo(Produk::class, 'produk_id', 'id');
    }
}
