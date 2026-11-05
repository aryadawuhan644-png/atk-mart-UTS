<?php

namespace Tests\Feature;

use App\Models\Keranjang;
use App\Models\Pesanan;
use App\Models\Produk;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class ApiEndpointsTest extends TestCase
{
    use DatabaseTransactions;

    protected string $tokenPembeli = 'token-pembeli-atk-mart-2026';
    protected string $tokenPengelola = 'token-pengelola-atk-mart-2026';

    /**
     * Uji 1: GET /api/produk (Publik)
     */
    public function test_get_produk_public(): void
    {
        $response = $this->getJson('/api/produk');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'code',
                'message',
                'data' => [
                    '*' => [
                        'id',
                        'nama',
                        'harga',
                        'kategori',
                        'stok',
                        'tersedia',
                        'deskripsi',
                        'pre_order',
                        'estimasi_tersedia',
                        'harga_grosir',
                    ],
                ],
            ])
            ->assertJson(['status' => 'sukses', 'code' => '200']);
    }

    /**
     * Uji 2: GET /api/produk/{id}
     */
    public function test_get_detail_produk(): void
    {
        $produk = Produk::first();
        $response = $this->getJson('/api/produk/' . $produk->id);

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'sukses',
                'code' => '200',
                'data' => [
                    'id' => $produk->id,
                    'nama' => $produk->nama,
                ],
            ]);
    }

    /**
     * Uji 3: GET /api/produk/{id} 404 jika ID tidak ditemukan
     */
    public function test_get_detail_produk_not_found(): void
    {
        $response = $this->getJson('/api/produk/999999');

        $response->assertStatus(404)
            ->assertJson([
                'status' => 'gagal',
                'code' => '404',
            ]);
    }

    /**
     * Uji 4: GET /api/kurir (Publik)
     */
    public function test_get_kurir_public(): void
    {
        $response = $this->getJson('/api/kurir');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'code',
                'message',
                'data' => [
                    'kurir',
                    'wilayah',
                    'tarif',
                ],
            ]);
    }

    /**
     * Uji 5: Proteksi 401 saat mengakses keranjang tanpa token
     */
    public function test_cart_requires_token(): void
    {
        $response = $this->getJson('/api/keranjang');

        $response->assertStatus(401)
            ->assertJson([
                'status' => 'gagal',
                'code' => '401',
            ]);
    }

    /**
     * Uji 6: Proteksi 403 saat pembeli mencoba menambah produk (POST /api/produk)
     */
    public function test_buyer_cannot_create_product(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->postJson('/api/produk', [
                'nama' => 'Buku Gambar A3',
                'harga' => 15000,
                'kategori' => 'Buku',
                'stok' => 50,
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'status' => 'gagal',
                'code' => '403',
            ]);
    }

    /**
     * Uji 7: Pengelola berhasil menambah produk (POST /api/produk)
     */
    public function test_manager_can_create_product(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPengelola)
            ->postJson('/api/produk', [
                'nama' => 'Buku Gambar A3 Uji',
                'harga' => 15000,
                'kategori' => 'Buku',
                'stok' => 50,
                'tersedia' => true,
                'pre_order' => false,
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'status' => 'sukses',
                'code' => '201',
                'data' => [
                    'nama' => 'Buku Gambar A3 Uji',
                    'harga' => 15000,
                ],
            ]);
    }

    /**
     * Uji 8: Alur Keranjang (Tambah, Lihat, Validasi 422 jika jumlah <= 0, Hapus)
     */
    public function test_cart_flow(): void
    {
        $produk = Produk::where('tersedia', true)->where('stok', '>=', 5)->first();

        // 8a. Tambah ke keranjang
        $addResponse = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->postJson('/api/keranjang', [
                'produk_id' => $produk->id,
                'jumlah' => 2,
            ]);

        $addResponse->assertStatus(201)
            ->assertJson([
                'status' => 'sukses',
            ]);

        // 8b. Lihat keranjang
        $getResponse = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->getJson('/api/keranjang');

        $getResponse->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'code',
                'data' => [
                    'items',
                    'subtotal',
                ],
            ]);

        $cartItemId = $getResponse->json('data.items.0.id');

        // 8c. Validasi PUT jumlah <= 0 harus 422
        $invalidPut = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->putJson('/api/keranjang/' . $cartItemId, [
                'jumlah' => 0,
            ]);

        $invalidPut->assertStatus(422)
            ->assertJson([
                'status' => 'gagal',
                'code' => '422',
            ]);

        // 8d. Hapus item keranjang
        $deleteResponse = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->deleteJson('/api/keranjang/' . $cartItemId);

        $deleteResponse->assertStatus(200)
            ->assertJson([
                'status' => 'sukses',
                'code' => '200',
            ]);
    }

    /**
     * Uji 9: Penolakan produk stok nol non-preorder (Aturan STK-02 / BR-02 -> 409)
     */
    public function test_cannot_add_out_of_stock_non_preorder(): void
    {
        $produk = Produk::where('tersedia', true)->where('pre_order', false)->where('stok', 0)->first();
        if ($produk) {
            $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
                ->postJson('/api/keranjang', [
                    'produk_id' => $produk->id,
                    'jumlah' => 1,
                ]);

            $response->assertStatus(409)
                ->assertJson([
                    'status' => 'gagal',
                    'code' => '409',
                ]);
        }
    }

    /**
     * Uji 10: Checkout lengkap, idempoten, dan hash checking
     */
    public function test_checkout_full_and_idempotency(): void
    {
        $produk = Produk::where('tersedia', true)->where('stok', '>=', 5)->first();

        // Tambah ke keranjang
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->postJson('/api/keranjang', [
                'produk_id' => $produk->id,
                'jumlah' => 1,
            ]);

        $key = 'test-uuid-' . uniqid();
        $payload = [
            'nama_penerima' => 'Pelanggan Demo Test',
            'alamat' => 'Jl. Soekarno Hatta No. 9',
            'kota' => 'Kota Malang',
            'wilayah_id' => 1,
            'kurir_id' => 1,
            'metode_pembayaran' => 'tunai_di_tempat',
        ];

        // Checkout pertama
        $checkoutResponse = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->withHeader('X-Kunci-Idempoten', $key)
            ->postJson('/api/checkout', $payload);

        $checkoutResponse->assertStatus(201)
            ->assertJson([
                'status' => 'sukses',
                'code' => '201',
            ]);

        $orderId = $checkoutResponse->json('data.pesanan_id');

        // Retry dengan kunci dan payload sama -> Mengembalikan pesanan yang sama (200)
        $retryResponse = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->withHeader('X-Kunci-Idempoten', $key)
            ->postJson('/api/checkout', $payload);

        $retryResponse->assertStatus(200)
            ->assertJson([
                'status' => 'sukses',
                'code' => '200',
                'data' => [
                    'pesanan_id' => $orderId,
                ],
            ]);

        // Kunci sama dengan payload berbeda -> Ditolak 409
        $conflictPayload = $payload;
        $conflictPayload['alamat'] = 'Jl. Berbeda No. 99';

        $conflictResponse = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->withHeader('X-Kunci-Idempoten', $key)
            ->postJson('/api/checkout', $conflictPayload);

        $conflictResponse->assertStatus(409)
            ->assertJson([
                'status' => 'gagal',
                'code' => '409',
            ]);
    }

    /**
     * Uji 11: Detail Pesanan dan Riwayat Pesanan
     */
    public function test_order_detail_and_history(): void
    {
        $pesanan = Pesanan::first();
        if ($pesanan) {
            $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPengelola)
                ->getJson('/api/pesanan/' . $pesanan->id);

            $response->assertStatus(200)
                ->assertJsonStructure([
                    'status',
                    'code',
                    'data' => [
                        'id',
                        'nomor_pesanan',
                        'status',
                        'items',
                        'riwayat_status',
                    ],
                ]);
        }
    }

    /**
     * Uji 12: Pembaruan Status Pesanan (PATCH /api/pesanan/{id}/status)
     */
    public function test_patch_status_pesanan(): void
    {
        $pesanan = Pesanan::where('status', 'menunggu_pembayaran')->first();
        if ($pesanan) {
            // Transisi ilegal: menunggu_pembayaran -> dibayar (harus menunggu_konfirmasi dulu) -> 409
            $invalidTransition = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPengelola)
                ->patchJson('/api/pesanan/' . $pesanan->id . '/status', [
                    'status' => 'dibayar',
                ]);

            $invalidTransition->assertStatus(409)
                ->assertJson([
                    'status' => 'gagal',
                    'code' => '409',
                ]);

            // Transisi sah oleh pembeli: menunggu_pembayaran -> menunggu_konfirmasi -> 200
            $validTransition = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
                ->patchJson('/api/pesanan/' . $pesanan->id . '/status', [
                    'status' => 'menunggu_konfirmasi',
                ]);

            $validTransition->assertStatus(200)
                ->assertJson([
                    'status' => 'sukses',
                    'code' => '200',
                    'data' => [
                        'status_baru' => 'menunggu_konfirmasi',
                    ],
                ]);
        }
    }

    /**
     * Uji 13: Penghapusan produk pada pesanan aktif ditolak dengan 409
     */
    public function test_delete_product_in_active_order_rejected(): void
    {
        // Cari produk yang ada di pesanan aktif
        $activePesanan = Pesanan::whereNotIn('status', ['selesai', 'dibatalkan'])->with('detail')->first();
        if ($activePesanan && $activePesanan->detail->isNotEmpty()) {
            $produkId = $activePesanan->detail->first()->produk_id;
            if ($produkId) {
                $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPengelola)
                    ->deleteJson('/api/produk/' . $produkId);

                $response->assertStatus(409)
                    ->assertJson([
                        'status' => 'gagal',
                        'code' => '409',
                    ]);
            }
        }
    }
}
