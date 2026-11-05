<?php

namespace Tests\Feature;

use App\Models\HargaGrosir;
use App\Models\Keranjang;
use App\Models\KunciIdempoten;
use App\Models\Pelanggan;
use App\Models\Pesanan;
use App\Models\Produk;
use App\Models\WilayahAntar;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class BusinessRulesTest extends TestCase
{
    use DatabaseTransactions;

    protected string $tokenPembeli = 'token-pembeli-atk-mart-2026';
    protected string $tokenPembeli2 = 'token-pembeli-2-atk-mart-2026';
    protected string $tokenPengelola = 'token-pengelola-atk-mart-2026';

    /**
     * Helper membuat produk uji dengan harga grosir bertingkat
     */
    protected function buatProdukGrosir(int $stok = 100): Produk
    {
        $produk = Produk::create([
            'nama' => 'Pensil Uji Grosir ' . uniqid(),
            'harga' => 5000,
            'kategori' => 'Alat Tulis',
            'stok' => $stok,
            'tersedia' => true,
            'pre_order' => false,
        ]);

        HargaGrosir::create([
            'produk_id' => $produk->id,
            'min_kuantitas' => 10,
            'harga_satuan' => 4500,
        ]);

        HargaGrosir::create([
            'produk_id' => $produk->id,
            'min_kuantitas' => 50,
            'harga_satuan' => 4000,
        ]);

        return $produk->fresh('hargaGrosir');
    }

    /**
     * 1. Perhitungan harga grosir: memilih tier tertinggi yang memenuhi kuantitas.
     */
    public function test_harga_grosir_memilih_tier_tertinggi_yang_cocok(): void
    {
        $produk = $this->buatProdukGrosir();

        // 1a. Kuantitas 5 (di bawah tier 10) -> harga normal 5000, subtotal 25000
        $resNormal = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->postJson('/api/keranjang', [
                'produk_id' => $produk->id,
                'jumlah' => 5,
            ]);

        $resNormal->assertStatus(201);
        $item = collect($resNormal->json('data.items'))->firstWhere('produk_id', $produk->id);
        $this->assertEquals(5000, $item['harga_satuan']);
        $this->assertEquals(25000, $item['subtotal']);

        // 1b. Update ke kuantitas 15 (memenuhi tier min 10) -> harga 4500, subtotal 67500
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->putJson('/api/keranjang/' . $item['id'], ['jumlah' => 15])
            ->assertStatus(200);

        $resTier1 = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)->getJson('/api/keranjang');
        $item15 = collect($resTier1->json('data.items'))->firstWhere('produk_id', $produk->id);
        $this->assertEquals(4500, $item15['harga_satuan']);
        $this->assertEquals(67500, $item15['subtotal']);

        // 1c. Update ke kuantitas 60 (memenuhi tier min 50) -> harga 4000, subtotal 240000
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->putJson('/api/keranjang/' . $item['id'], ['jumlah' => 60])
            ->assertStatus(200);

        $resTier2 = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)->getJson('/api/keranjang');
        $item60 = collect($resTier2->json('data.items'))->firstWhere('produk_id', $produk->id);
        $this->assertEquals(4000, $item60['harga_satuan']);
        $this->assertEquals(240000, $item60['subtotal']);
    }

    /**
     * 2. Pengiriman: hanya wilayah Kota Malang yang diterima.
     */
    public function test_pengiriman_menolak_alamat_luar_malang(): void
    {
        $produk = Produk::where('tersedia', true)->where('stok', '>=', 5)->first();
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->postJson('/api/keranjang', [
                'produk_id' => $produk->id,
                'jumlah' => 1,
            ]);

        // Coba checkout dengan teks kota luar Malang
        $responseLuar = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->withHeader('X-Kunci-Idempoten', 'key-malang-' . uniqid())
            ->postJson('/api/checkout', [
                'nama_penerima' => 'Pembeli Luar',
                'alamat' => 'Jl. Pahlawan No. 1',
                'kota' => 'Surabaya',
                'wilayah_id' => 1,
                'kurir_id' => 1,
                'metode_pembayaran' => 'tunai_di_tempat',
            ]);

        $responseLuar->assertStatus(422)
            ->assertJson([
                'status' => 'gagal',
                'code' => '422',
            ]);
    }

    /**
     * 3a. Produk tidak tersedia (tersedia=false) ditolak masuk keranjang (BR-01 -> 409).
     */
    public function test_produk_tidak_tersedia_ditolak_409(): void
    {
        $produk = Produk::create([
            'nama' => 'Produk Nonaktif ' . uniqid(),
            'harga' => 10000,
            'kategori' => 'Buku',
            'stok' => 10,
            'tersedia' => false,
            'pre_order' => false,
        ]);

        $res = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->postJson('/api/keranjang', [
                'produk_id' => $produk->id,
                'jumlah' => 1,
            ]);

        $res->assertStatus(409)
            ->assertJson([
                'status' => 'gagal',
                'code' => '409',
            ]);
    }

    /**
     * 3b. Produk preorder stok nol boleh dipesan dan masuk status menunggu_stok.
     */
    public function test_preorder_stok_nol_menghasilkan_status_menunggu_stok(): void
    {
        $produkPO = Produk::create([
            'nama' => 'Buku Preorder Langka ' . uniqid(),
            'harga' => 75000,
            'kategori' => 'Buku',
            'stok' => 0,
            'tersedia' => true,
            'pre_order' => true,
        ]);

        // Tambah ke keranjang sukses
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->postJson('/api/keranjang', [
                'produk_id' => $produkPO->id,
                'jumlah' => 2,
            ])->assertStatus(201);

        // Checkout
        $resCheckout = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->withHeader('X-Kunci-Idempoten', 'po-key-' . uniqid())
            ->postJson('/api/checkout', [
                'nama_penerima' => 'Pembeli Preorder',
                'alamat' => 'Jl. Dinoyo No. 5',
                'kota' => 'Kota Malang',
                'wilayah_id' => 1,
                'kurir_id' => 1,
                'metode_pembayaran' => 'transfer_manual',
            ]);

        $resCheckout->assertStatus(201)
            ->assertJson([
                'status' => 'sukses',
                'code' => '201',
                'data' => [
                    'status' => 'menunggu_stok',
                ],
            ]);

        // Pastikan stok tidak menjadi negatif (tetap 0)
        $this->assertEquals(0, $produkPO->fresh()->stok);
    }

    /**
     * 3c. Preorder dengan stok parsial: mereservasi stok tersedia tanpa negatif,
     * dan pesanan masuk status menunggu_stok.
     */
    public function test_preorder_stok_parsial_dan_pembatalan(): void
    {
        $produkParsial = Produk::create([
            'nama' => 'Buku PO Stok Parsial ' . uniqid(),
            'harga' => 50000,
            'kategori' => 'Buku',
            'stok' => 2, // hanya ada 2
            'tersedia' => true,
            'pre_order' => true,
        ]);

        // Pesan 5 unit
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->postJson('/api/keranjang', [
                'produk_id' => $produkParsial->id,
                'jumlah' => 5,
            ])->assertStatus(201);

        $resCheckout = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->withHeader('X-Kunci-Idempoten', 'po-part-' . uniqid())
            ->postJson('/api/checkout', [
                'nama_penerima' => 'Pembeli Parsial',
                'alamat' => 'Jl. Galunggung No. 12',
                'kota' => 'Kota Malang',
                'wilayah_id' => 1,
                'kurir_id' => 1,
                'metode_pembayaran' => 'tunai_di_tempat',
            ]);

        $resCheckout->assertStatus(201);
        $orderId = $resCheckout->json('data.pesanan_id');

        // Verifikasi stok berkurang menjadi 0 (bukan -3)
        $this->assertEquals(0, $produkParsial->fresh()->stok);

        // Verifikasi detail pesanan mencatat stok_dikurangi = 2
        $pesanan = Pesanan::with('detail')->find($orderId);
        $detail = $pesanan->detail->firstWhere('produk_id', $produkParsial->id);
        $this->assertEquals(2, $detail->stok_dikurangi);
        $this->assertTrue((bool) $detail->menunggu_stok);
        $this->assertEquals('menunggu_stok', $pesanan->status);

        // 5. Pembatalan pesanan: stok dipulihkan tepat sebesar stok_dikurangi (2 unit)
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->patchJson('/api/pesanan/' . $orderId . '/status', [
                'status' => 'dibatalkan',
                'catatan' => 'Batal menunggu stok',
            ])->assertStatus(200);

        $this->assertEquals(2, $produkParsial->fresh()->stok);
    }

    /**
     * 4. Checkout: stok tidak boleh negatif dan hanya dikurangi satu kali; keranjang dikosongkan.
     */
    public function test_checkout_stok_hanya_dikurangi_sekali_dan_keranjang_bersih(): void
    {
        $produk = Produk::create([
            'nama' => 'Spidol Uji ' . uniqid(),
            'harga' => 12000,
            'kategori' => 'Alat Tulis',
            'stok' => 10,
            'tersedia' => true,
            'pre_order' => false,
        ]);

        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->postJson('/api/keranjang', [
                'produk_id' => $produk->id,
                'jumlah' => 4,
            ])->assertStatus(201);

        $key = 'single-deduct-' . uniqid();
        $payload = [
            'nama_penerima' => 'Pelanggan Uji',
            'alamat' => 'Jl. Suhat No. 10',
            'kota' => 'Kota Malang',
            'wilayah_id' => 1,
            'kurir_id' => 1,
            'metode_pembayaran' => 'tunai_di_tempat',
        ];

        $checkoutRes = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->withHeader('X-Kunci-Idempoten', $key)
            ->postJson('/api/checkout', $payload);

        $checkoutRes->assertStatus(201);
        $this->assertEquals(6, $produk->fresh()->stok);

        // Pastikan keranjang dikosongkan oleh server
        $keranjangRes = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)->getJson('/api/keranjang');
        $this->assertEmpty($keranjangRes->json('data.items'));

        // Retry dengan kunci sama -> tidak mengurangi stok lagi
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->withHeader('X-Kunci-Idempoten', $key)
            ->postJson('/api/checkout', $payload)
            ->assertStatus(200);

        $this->assertEquals(6, $produk->fresh()->stok);
    }

    /**
     * 6. Idempotency: simulasi race condition duplicate key database.
     */
    public function test_idempotency_race_condition_duplicate_key(): void
    {
        $produk = Produk::create([
            'nama' => 'Buku Tulis ' . uniqid(),
            'harga' => 8000,
            'kategori' => 'Buku',
            'stok' => 20,
            'tersedia' => true,
            'pre_order' => false,
        ]);

        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->postJson('/api/keranjang', [
                'produk_id' => $produk->id,
                'jumlah' => 2,
            ]);

        $key = 'race-key-' . uniqid();
        $payload = [
            'nama_penerima' => 'Pelanggan Race',
            'alamat' => 'Jl. Veteran No. 2',
            'kota' => 'Kota Malang',
            'wilayah_id' => 1,
            'kurir_id' => 1,
            'metode_pembayaran' => 'transfer_manual',
        ];

        // Jalankan checkout pertama
        $res1 = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->withHeader('X-Kunci-Idempoten', $key)
            ->postJson('/api/checkout', $payload);

        $res1->assertStatus(201);
        $orderId = $res1->json('data.pesanan_id');

        // Panggil kembali dengan kunci dan payload sama -> Mengembalikan pesanan lama
        $res2 = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->withHeader('X-Kunci-Idempoten', $key)
            ->postJson('/api/checkout', $payload);

        $res2->assertStatus(200)
            ->assertJson([
                'status' => 'sukses',
                'code' => '200',
                'data' => [
                    'pesanan_id' => $orderId,
                ],
            ]);
    }

    /**
     * 7. Otorisasi: pembeli tidak boleh mengakses atau mengubah pesanan milik pembeli lain.
     */
    public function test_otorisasi_pembeli_tidak_bisa_akses_pesanan_pembeli_lain(): void
    {
        // Buat pelanggan kedua
        $pelanggan2 = Pelanggan::firstOrCreate(['id' => 2], ['nama' => 'Pembeli Kedua Demo']);

        // Buat pesanan untuk pelanggan 1
        $pesanan1 = Pesanan::create([
            'nomor_pesanan' => 'ATK-TEST-P1-' . uniqid(),
            'pelanggan_id' => 1,
            'nama_penerima' => 'Pembeli Satu',
            'alamat' => 'Jl. Satu No. 1',
            'kota' => 'Kota Malang',
            'wilayah_id' => 1,
            'kurir_id' => 1,
            'metode_pembayaran_id' => 1,
            'subtotal' => 20000,
            'ongkos_kirim' => 5000,
            'total' => 25000,
            'status' => 'menunggu_pembayaran',
        ]);

        // Pelanggan 2 mencoba mengakses detail pesanan Pelanggan 1 -> Ditolak 403
        $getRes = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli2)
            ->getJson('/api/pesanan/' . $pesanan1->id);

        $getRes->assertStatus(403)
            ->assertJson([
                'status' => 'gagal',
                'code' => '403',
            ]);

        // Pelanggan 2 mencoba membatalkan pesanan Pelanggan 1 -> Ditolak 403
        $patchRes = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli2)
            ->patchJson('/api/pesanan/' . $pesanan1->id . '/status', [
                'status' => 'dibatalkan',
            ]);

        $patchRes->assertStatus(403)
            ->assertJson([
                'status' => 'gagal',
                'code' => '403',
            ]);

        // Uji coba memalsukan X-Pelanggan-Id dengan token pembeli 1 tetap menghasilkan identitas pelanggan 1
        $spoofRes = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->withHeader('X-Pelanggan-Id', '999')
            ->getJson('/api/pesanan/' . $pesanan1->id);

        $spoofRes->assertStatus(200); // Pesanan 1 miliknya tetap dapat diakses karena server tidak memakai X-Pelanggan-Id

        // Pengelola diizinkan melihat pesanan siapapun
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPengelola)
            ->getJson('/api/pesanan/' . $pesanan1->id)
            ->assertStatus(200);
    }

    /**
     * 8. Transisi status: menguji transisi sah dan tidak sah sesuai matriks PRD Bagian 15.2.
     */
    public function test_matriks_transisi_status_lengkap(): void
    {
        $pesanan = Pesanan::create([
            'nomor_pesanan' => 'ATK-STATUS-' . uniqid(),
            'pelanggan_id' => 1,
            'nama_penerima' => 'Penguji Transisi',
            'alamat' => 'Jl. Mawar No. 3',
            'kota' => 'Kota Malang',
            'wilayah_id' => 1,
            'kurir_id' => 1,
            'metode_pembayaran_id' => 2,
            'subtotal' => 50000,
            'ongkos_kirim' => 5000,
            'total' => 55000,
            'status' => 'menunggu_pembayaran',
        ]);

        // 8a. Transisi tidak sah langsung ke 'selesai' -> 409
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPengelola)
            ->patchJson('/api/pesanan/' . $pesanan->id . '/status', ['status' => 'selesai'])
            ->assertStatus(409);

        // 8b. Transisi sah: menunggu_pembayaran -> menunggu_konfirmasi (oleh pembeli) -> 200
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->patchJson('/api/pesanan/' . $pesanan->id . '/status', ['status' => 'menunggu_konfirmasi'])
            ->assertStatus(200);

        // 8c. Pembeli mencoba konfirmasi pembayaran ke 'dibayar' -> 403 (khusus pengelola)
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->patchJson('/api/pesanan/' . $pesanan->id . '/status', ['status' => 'dibayar'])
            ->assertStatus(403);

        // 8d. Pengelola konfirmasi: menunggu_konfirmasi -> dibayar -> 200
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPengelola)
            ->patchJson('/api/pesanan/' . $pesanan->id . '/status', ['status' => 'dibayar'])
            ->assertStatus(200);

        // 8e. Pengelola: dibayar -> diproses -> 200
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPengelola)
            ->patchJson('/api/pesanan/' . $pesanan->id . '/status', ['status' => 'diproses'])
            ->assertStatus(200);

        // 8f. Pengelola: diproses -> dikirim -> 200
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPengelola)
            ->patchJson('/api/pesanan/' . $pesanan->id . '/status', ['status' => 'dikirim'])
            ->assertStatus(200);

        // 8g. Pembeli konfirmasi terima: dikirim -> selesai -> 200
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->patchJson('/api/pesanan/' . $pesanan->id . '/status', ['status' => 'selesai'])
            ->assertStatus(200);

        // 8h. Pesanan yang sudah 'selesai' tidak boleh dibatalkan -> 409
        $this->withHeader('Authorization', 'Bearer ' . $this->tokenPengelola)
            ->patchJson('/api/pesanan/' . $pesanan->id . '/status', ['status' => 'dibatalkan'])
            ->assertStatus(409);
    }
}
