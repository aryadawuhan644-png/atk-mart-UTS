<?php

namespace Tests\Feature;

use App\Models\Produk;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProdukGambarTest extends TestCase
{
    use DatabaseTransactions;

    public function test_format_produk_includes_api_gambar_url(): void
    {
        Storage::fake('public');
        $file = UploadedFile::fake()->image('buku_tulis.jpg', 200, 200);
        $path = $file->store('produk', 'public');

        $produk = Produk::create([
            'nama' => 'Buku Uji Gambar',
            'harga' => 10000,
            'kategori' => 'Buku',
            'stok' => 15,
            'tersedia' => true,
            'pre_order' => false,
            'gambar' => $path,
        ]);

        $response = $this->getJson('/api/produk/' . $produk->id);

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'sukses',
                'data' => [
                    'id' => $produk->id,
                    'gambar' => url('/api/produk/' . $produk->id . '/gambar'),
                ],
            ]);
    }

    public function test_get_gambar_returns_image_with_proper_headers_and_cors(): void
    {
        Storage::fake('public');
        $file = UploadedFile::fake()->image('gambar_produk.png', 100, 100);
        $path = $file->store('produk', 'public');

        $produk = Produk::create([
            'nama' => 'Penggaris Gambar Uji',
            'harga' => 5000,
            'kategori' => 'Alat Tulis',
            'stok' => 20,
            'tersedia' => true,
            'pre_order' => false,
            'gambar' => $path,
        ]);

        $origin = 'http://localhost:54321';
        $response = $this->withHeaders([
            'Origin' => $origin,
        ])->get('/api/produk/' . $produk->id . '/gambar');

        $response->assertStatus(200);
        $this->assertStringContainsString('image/png', (string) $response->headers->get('Content-Type'));
        $this->assertEquals($origin, $response->headers->get('Access-Control-Allow-Origin'));
    }

    public function test_get_gambar_supports_lan_origin_cors(): void
    {
        Storage::fake('public');
        $file = UploadedFile::fake()->image('sampul.jpg', 150, 150);
        $path = $file->store('produk', 'public');

        $produk = Produk::create([
            'nama' => 'Produk LAN Uji',
            'harga' => 8000,
            'kategori' => 'Alat Tulis',
            'stok' => 10,
            'tersedia' => true,
            'pre_order' => false,
            'gambar' => $path,
        ]);

        $origin = 'http://172.16.187.57:3000';
        $response = $this->withHeaders([
            'Origin' => $origin,
        ])->get('/api/produk/' . $produk->id . '/gambar');

        $response->assertStatus(200);
        $this->assertEquals($origin, $response->headers->get('Access-Control-Allow-Origin'));
    }

    public function test_get_gambar_returns_404_when_product_has_no_image(): void
    {
        $produk = Produk::create([
            'nama' => 'Produk Tanpa Gambar Uji',
            'harga' => 5000,
            'kategori' => 'Alat Tulis',
            'stok' => 10,
            'tersedia' => true,
            'pre_order' => false,
            'gambar' => null,
        ]);

        $response = $this->getJson('/api/produk/' . $produk->id . '/gambar');

        $response->assertStatus(404)
            ->assertJson([
                'status' => 'gagal',
                'code' => '404',
            ]);
    }

    public function test_get_gambar_returns_404_when_product_not_found(): void
    {
        $response = $this->getJson('/api/produk/999999/gambar');

        $response->assertStatus(404)
            ->assertJson([
                'status' => 'gagal',
                'code' => '404',
            ]);
    }
}
