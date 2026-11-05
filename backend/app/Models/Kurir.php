<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Kurir extends Model
{
    use HasFactory;

    protected $table = 'kurir';

    protected $fillable = [
        'nama',
        'deskripsi',
        'aktif',
    ];

    protected $casts = [
        'aktif' => 'boolean',
    ];

    public function tarifKurir(): HasMany
    {
        return $this->hasMany(TarifKurir::class, 'kurir_id', 'id');
    }

    public function pesanan(): HasMany
    {
        return $this->hasMany(Pesanan::class, 'kurir_id', 'id');
    }
}
