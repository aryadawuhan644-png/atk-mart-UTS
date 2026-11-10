<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Pelanggan extends Model
{
    use HasFactory;

    protected $table = 'pelanggan';

    protected $fillable = [
        'id',
        'nama',
        'user_id',
    ];

    public function keranjang(): HasMany
    {
        return $this->hasMany(Keranjang::class, 'pelanggan_id', 'id');
    }

    public function pesanan(): HasMany
    {
        return $this->hasMany(Pesanan::class, 'pelanggan_id', 'id');
    }

    public function kunciIdempoten(): HasMany
    {
        return $this->hasMany(KunciIdempoten::class, 'pelanggan_id', 'id');
    }
}
