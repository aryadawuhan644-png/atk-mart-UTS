<?php

use App\Http\Controllers\Api\CheckoutController;
use App\Http\Controllers\Api\KeranjangController;
use App\Http\Controllers\Api\KurirController;
use App\Http\Controllers\Api\PesananController;
use App\Http\Controllers\Api\ProdukController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes - ATK Mart (14 Endpoint Wajib PRD)
|--------------------------------------------------------------------------
*/

// Endpoint Publik: Katalog dan Kurir
Route::get('/produk', [ProdukController::class, 'index']);
Route::get('/produk/{id}', [ProdukController::class, 'show']);
Route::get('/kurir', [KurirController::class, 'index']);

// Endpoint dengan Autentikasi Token Statis
Route::middleware(['auth.statis'])->group(function () {
    // Pengelola: Kelola Produk CRUD
    Route::middleware(['role:pengelola'])->group(function () {
        Route::post('/produk', [ProdukController::class, 'store']);
        Route::put('/produk/{id}', [ProdukController::class, 'update']);
        Route::delete('/produk/{id}', [ProdukController::class, 'destroy']);
    });

    // Pembeli: Keranjang & Checkout
    Route::middleware(['role:pembeli'])->group(function () {
        Route::get('/keranjang', [KeranjangController::class, 'index']);
        Route::post('/keranjang', [KeranjangController::class, 'store']);
        Route::put('/keranjang/{id}', [KeranjangController::class, 'update']);
        Route::delete('/keranjang/{id}', [KeranjangController::class, 'destroy']);
        Route::post('/checkout', [CheckoutController::class, 'store']);
    });

    // Pesanan: Riwayat, Rincian, dan Pembaruan Status (Pembeli & Pengelola)
    Route::get('/pesanan', [PesananController::class, 'index']);
    Route::get('/pesanan/{id}', [PesananController::class, 'show']);
    Route::patch('/pesanan/{id}/status', [PesananController::class, 'updateStatus']);
});
