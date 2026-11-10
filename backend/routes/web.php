<?php

use App\Http\Controllers\AccountController;
use Illuminate\Support\Facades\Route;

Route::get('/', [AccountController::class, 'onboarding'])->name('onboarding');

Route::middleware('guest')->group(function () {
    Route::get('/auth', [AccountController::class, 'showAuth'])->name('auth');
    Route::post('/login', [AccountController::class, 'login'])->name('login');
    Route::post('/register', [AccountController::class, 'register'])->middleware('throttle:5,1')->name('register');
});

Route::middleware('auth')->group(function () {
    Route::middleware('account.type:admin')->group(function () {
        Route::get('/admin', [AccountController::class, 'adminDashboard'])->name('admin.dashboard');
        Route::post('/admin/products', [AccountController::class, 'storeProduct'])->name('admin.products.store');
        Route::put('/admin/products/{product}', [AccountController::class, 'updateProduct'])->name('admin.products.update');
        Route::delete('/admin/products/{product}', [AccountController::class, 'deleteProduct'])->name('admin.products.destroy');
    });

    Route::middleware('account.type:buyer_1,buyer_2')->group(function () {
        Route::get('/profile/setup', [AccountController::class, 'profileSetup'])->name('profile.setup');
        Route::post('/profile', [AccountController::class, 'updateProfile'])->name('profile.update');
        Route::get('/home', [AccountController::class, 'home'])->name('home');
        Route::post('/cart/{product}', [AccountController::class, 'addCartItem'])->name('cart.store');
        Route::put('/cart/{item}', [AccountController::class, 'updateCartItem'])->name('cart.update');
        Route::delete('/cart/{item}', [AccountController::class, 'removeCartItem'])->name('cart.destroy');
    });

    Route::post('/logout', [AccountController::class, 'logout'])->name('logout');
});
