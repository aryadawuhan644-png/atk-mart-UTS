<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Pesanan extends Model
{
    use HasFactory;

    protected $table = 'pesanan';

    protected $fillable = [
        'nomor_pesanan',
        'pelanggan_id',
        'nama_penerima',
        'alamat',
        'kota',
        'wilayah_id',
        'kurir_id',
        'metode_pembayaran_id',
        'subtotal',
        'ongkos_kirim',
        'total',
        'status',
    ];

    protected $casts = [
        'subtotal' => 'integer',
        'ongkos_kirim' => 'integer',
        'total' => 'integer',
    ];

    public function pelanggan(): BelongsTo
    {
        return $this->belongsTo(Pelanggan::class, 'pelanggan_id', 'id');
    }

    public function wilayah(): BelongsTo
    {
        return $this->belongsTo(WilayahAntar::class, 'wilayah_id', 'id');
    }

    public function wilayahAntar(): BelongsTo
    {
        return $this->wilayah();
    }

    public function kurir(): BelongsTo
    {
        return $this->belongsTo(Kurir::class, 'kurir_id', 'id');
    }

    public function metodePembayaran(): BelongsTo
    {
        return $this->belongsTo(MetodePembayaran::class, 'metode_pembayaran_id', 'id');
    }

    public function detail(): HasMany
    {
        return $this->hasMany(PesananDetail::class, 'pesanan_id', 'id');
    }

    public function riwayatStatus(): HasMany
    {
        return $this->hasMany(RiwayatStatusPesanan::class, 'pesanan_id', 'id')->orderBy('created_at', 'asc');
    }

    public function kunciIdempoten(): HasOne
    {
        return $this->hasOne(KunciIdempoten::class, 'pesanan_id', 'id');
    }
}
