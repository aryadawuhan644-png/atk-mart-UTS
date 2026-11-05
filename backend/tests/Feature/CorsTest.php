<?php

namespace Tests\Feature;

use Tests\TestCase;

class CorsTest extends TestCase
{
    public function test_options_preflight_to_keranjang_returns_cors_headers(): void
    {
        $response = $this->withHeaders([
            'Origin' => 'http://localhost:54732',
            'Access-Control-Request-Method' => 'POST',
            'Access-Control-Request-Headers' => 'authorization,content-type',
        ])->options('/api/keranjang');

        $response->assertStatus(204);
        $this->assertEquals('http://localhost:54732', $response->headers->get('Access-Control-Allow-Origin'));
        $this->assertStringContainsString('POST', (string) $response->headers->get('Access-Control-Allow-Methods'));
    }

    public function test_options_preflight_from_127_0_0_1_works(): void
    {
        $response = $this->withHeaders([
            'Origin' => 'http://127.0.0.1:54732',
            'Access-Control-Request-Method' => 'POST',
            'Access-Control-Request-Headers' => 'authorization,content-type',
        ])->options('/api/keranjang');

        $response->assertStatus(204);
        $this->assertEquals('http://127.0.0.1:54732', $response->headers->get('Access-Control-Allow-Origin'));
    }

    public function test_post_keranjang_with_cors_returns_allow_origin(): void
    {
        $token = env('TOKEN_STATIS_PEMBELI', 'token-pembeli-atk-mart-2026');

        $response = $this->withHeaders([
            'Origin' => 'http://localhost:54732',
            'Authorization' => "Bearer $token",
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
        ])->postJson('/api/keranjang', [
            'produk_id' => 1,
            'jumlah' => 2,
        ]);

        $this->assertEquals('http://localhost:54732', $response->headers->get('Access-Control-Allow-Origin'));
        $this->assertTrue(in_array($response->status(), [200, 201]));
    }
}
