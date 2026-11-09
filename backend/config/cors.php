<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Konfigurasi CORS untuk komunikasi Flutter Web dengan backend Laravel.
    | Dibatasi secara spesifik hanya untuk lingkungan pengembangan lokal
    | (localhost dan 127.0.0.1 pada sembarang port), tanpa membuka akses
    | produksi secara sembarangan.
    |
    */

    'paths' => ['api/*'],

    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],

    'allowed_origins' => [],

    'allowed_origins_patterns' => [
        '#^https?://(localhost|127\.0\.0\.1|172\.(1[6-9]|2\d|3[01])\.\d+\.\d+|192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+)(:\d+)?$#',
    ],

    'allowed_headers' => [
    'Authorization',
    'Content-Type',
    'Accept',
    'X-Requested-With',
    'X-Kunci-Idempoten',
    'X-HTTP-Method-Override',
],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,

];
