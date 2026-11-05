<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WilayahAntar extends Model
{
    use HasFactory;

    protected $table = 'wilayah_antar';

    protected $fillable = [
        'nama',
        'kota',
        'aktif',
    ];

    protected $casts = [
        'aktif' => 'boolean',
    ];

    public function tarifKurir(): HasMany
    {
        return $this->hasMany(TarifKurir::class, 'wilayah_id', 'id');
    }

    public function pesanan(): HasMany
    {
        return $this->hasMany(Pesanan::class, 'wilayah_id', 'id');
    }
}
