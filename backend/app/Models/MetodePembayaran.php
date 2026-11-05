<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MetodePembayaran extends Model
{
    use HasFactory;

    protected $table = 'metode_pembayaran';

    protected $fillable = [
        'kode',
        'nama',
    ];

    public function pesanan(): HasMany
    {
        return $this->hasMany(Pesanan::class, 'metode_pembayaran_id', 'id');
    }
}
