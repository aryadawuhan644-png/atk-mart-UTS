<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        $currentDb = config('database.connections.' . config('database.default') . '.database');
        if ($currentDb === 'atk_mart') {
            $this->fail('Pengujian dibatalkan: koneksi database terdeteksi menggunakan database utama atk_mart.');
        }
    }
}
