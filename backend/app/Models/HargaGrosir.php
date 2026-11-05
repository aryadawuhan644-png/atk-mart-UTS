<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HargaGrosir extends Model
{
    use HasFactory;

    protected $table = 'harga_grosir';

    protected $fillable = [
        'produk_id',
        'min_kuantitas',
        'harga_satuan',
    ];

    protected $casts = [
        'min_kuantitas' => 'integer',
        'harga_satuan' => 'integer',
    ];

    public function produk(): BelongsTo
    {
        return $this->belongsTo(Produk::class, 'produk_id', 'id');
    }
}
