<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TarifKurir extends Model
{
    use HasFactory;

    protected $table = 'tarif_kurir';

    protected $fillable = [
        'kurir_id',
        'wilayah_id',
        'tarif',
    ];

    protected $casts = [
        'tarif' => 'integer',
    ];

    public function kurir(): BelongsTo
    {
        return $this->belongsTo(Kurir::class, 'kurir_id', 'id');
    }

    public function wilayah(): BelongsTo
    {
        return $this->belongsTo(WilayahAntar::class, 'wilayah_id', 'id');
    }

    public function wilayahAntar(): BelongsTo
    {
        return $this->wilayah();
    }
}
