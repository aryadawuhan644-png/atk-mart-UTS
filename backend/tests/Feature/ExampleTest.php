<?php

namespace Tests\Feature;

// use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    /**
     * A basic test example.
     */
    public function test_the_application_returns_a_successful_response(): void
    {
        $response = $this->get('/');

        $response->assertStatus(200);
    }

    public function test_database_testing_is_strictly_isolated_from_atk_mart(): void
    {
        $defaultConn = config('database.default');
        $activeDb = config("database.connections.{$defaultConn}.database");

        $this->assertNotEquals('atk_mart', $activeDb, 'Database pengujian tidak boleh menggunakan atk_mart!');
        $this->assertEquals('atk_mart_testing', $activeDb, 'Database pengujian harus menggunakan atk_mart_testing!');
    }
}
