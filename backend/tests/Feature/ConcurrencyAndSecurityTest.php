<?php

namespace Tests\Feature;

use App\Models\Keranjang;
use App\Models\KunciIdempoten;
use App\Models\Pelanggan;
use App\Models\Pesanan;
use App\Models\PesananDetail;
use App\Models\Produk;
use Tests\TestCase;

class ConcurrencyAndSecurityTest extends TestCase
{
    protected string $tokenPembeli = 'token-pembeli-atk-mart-2026';
    protected string $tokenPembeli2 = 'token-pembeli-2-atk-mart-2026';
    protected string $tokenPengelola = 'token-pengelola-atk-mart-2026';

    protected static $serverProcess = null;
    protected static string $serverUrl = 'http://localhost:8080';

    protected function setUp(): void
    {
        parent::setUp();

        // Pastikan Pelanggan 1 dan 2 tersedia di database
        Pelanggan::firstOrCreate(['id' => 1], ['nama' => 'Pelanggan Demo ATK Mart']);
        Pelanggan::firstOrCreate(['id' => 2], ['nama' => 'Pelanggan Dua Demo']);

        if (self::$serverProcess === null) {
            $baseDir = dirname(__DIR__, 2);
            $publicDir = $baseDir . DIRECTORY_SEPARATOR . 'public';
            $cmd = escapeshellarg(PHP_BINARY) . ' -S localhost:8080 -t ' . escapeshellarg($publicDir);

            $descriptors = [
                0 => ['pipe', 'r'],
                1 => ['pipe', 'w'],
                2 => ['pipe', 'w'],
            ];

            self::$serverProcess = proc_open($cmd, $descriptors, $pipes, $baseDir);

            // Tunggu server lokal siap melayani HTTP request
            $start = microtime(true);
            while (microtime(true) - $start < 5.0) {
                $ch = curl_init('http://localhost:8080/up');
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_TIMEOUT, 1);
                curl_exec($ch);
                $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                curl_close($ch);
                if ($code === 200) {
                    break;
                }
                usleep(100000); // 100ms
            }
        }
    }

    protected function tearDown(): void
    {
        // Bersihkan data pelanggan uji tambahan selagi aplikasi masih aktif
        Pelanggan::where('id', '>', 1)->delete();

        parent::tearDown();
    }

    public static function tearDownAfterClass(): void
    {
        if (is_resource(self::$serverProcess)) {
            proc_terminate(self::$serverProcess);
            proc_close(self::$serverProcess);
            self::$serverProcess = null;
        }

        parent::tearDownAfterClass();
    }

    /**
     * 1. IDENTITAS PELANGGAN: Klien TIDAK DAPAT memalsukan pelanggan_id
     * via header X-Pelanggan-Id, parameter query, atau payload body.
     */
    public function test_client_cannot_spoof_pelanggan_id(): void
    {
        $produk = Produk::where('tersedia', true)->where('stok', '>=', 5)->first();

        // Klien mencoba menyusupkan X-Pelanggan-Id: 999 dan body pelanggan_id: 999
        $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
            ->withHeader('X-Pelanggan-Id', '999')
            ->postJson('/api/keranjang', [
                'produk_id' => $produk->id,
                'jumlah' => 1,
                'pelanggan_id' => 999,
                'auth_role' => 'pengelola',
            ]);

        $response->assertStatus(201);

        // Verifikasi di database: item tersimpan untuk pelanggan_id = 1 (bukan 999)
        $cartItem = Keranjang::where('produk_id', $produk->id)
            ->where('pelanggan_id', 1)
            ->latest('id')
            ->first();
        $this->assertNotNull($cartItem);
        $this->assertEquals(1, $cartItem->pelanggan_id);

        $cartItem->delete();
    }

    /**
     * 2. OTORISASI: Pembeli tidak dapat mengakses atau memodifikasi pesanan pelanggan lain.
     */
    public function test_buyer_strictly_forbidden_from_other_buyer_orders(): void
    {
        $pesanan1 = Pesanan::create([
            'nomor_pesanan' => 'ATK-SEC-' . uniqid(),
            'pelanggan_id' => 1,
            'nama_penerima' => 'Pelanggan 1 Asli',
            'alamat' => 'Jl. Asli No. 1',
            'kota' => 'Kota Malang',
            'wilayah_id' => 1,
            'kurir_id' => 1,
            'metode_pembayaran_id' => 1,
            'subtotal' => 15000,
            'ongkos_kirim' => 5000,
            'total' => 20000,
            'status' => 'menunggu_pembayaran',
        ]);

        try {
            // Pembeli 2 (tokenPembeli2) mencoba GET pesanan milik Pembeli 1 -> 403 Forbidden
            $getRes = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli2)
                ->getJson('/api/pesanan/' . $pesanan1->id);

            $getRes->assertStatus(403)
                ->assertJson([
                    'status' => 'gagal',
                    'code' => '403',
                ]);

            // Pembeli 2 mencoba PATCH status pesanan milik Pembeli 1 -> 403 Forbidden
            $patchRes = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli2)
                ->patchJson('/api/pesanan/' . $pesanan1->id . '/status', [
                    'status' => 'dibatalkan',
                ]);

            $patchRes->assertStatus(403)
                ->assertJson([
                    'status' => 'gagal',
                    'code' => '403',
                ]);

            // Pembeli 2 memanggil daftar pesanan: pesanan milik Pembeli 1 TIDAK boleh muncul
            $listRes = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli2)
                ->getJson('/api/pesanan');

            $listRes->assertStatus(200);
            $orderIds = collect($listRes->json('data'))->pluck('id')->all();
            $this->assertNotContains($pesanan1->id, $orderIds);

            // Pengelola (tokenPengelola) tetap memiliki akses
            $this->withHeader('Authorization', 'Bearer ' . $this->tokenPengelola)
                ->getJson('/api/pesanan/' . $pesanan1->id)
                ->assertStatus(200);
        } finally {
            $pesanan1->delete();
        }
    }

    /**
     * 3. RACE CONDITION (SIMULASI EXCEPTION & ROLLBACK):
     * Menguji penanganan QueryException duplicate-key (error 1062) pada tabel kunci_idempoten,
     * memastikan transaksi kedua rollback (tanpa double-deduct stok), dan mengembalikan pesanan pertama.
     */
    public function test_simulated_unique_constraint_collision_and_rollback(): void
    {
        $produk = Produk::create([
            'nama' => 'Buku Sim Race ' . uniqid(),
            'harga' => 25000,
            'kategori' => 'Buku',
            'stok' => 10,
            'tersedia' => true,
            'pre_order' => false,
        ]);

        $pelangganId = 1;
        $kunci = 'sim-race-key-' . uniqid();
        $payload = [
            'nama_penerima' => 'Pembeli Sim',
            'alamat' => 'Jl. Sim No. 1',
            'kota' => 'Kota Malang',
            'wilayah_id' => 1,
            'kurir_id' => 1,
            'metode_pembayaran' => 'tunai_di_tempat',
        ];
        $hashPermintaan = hash('sha256', json_encode($payload));

        // Buat pesanan Request 1 yang sudah tersimpan di database
        $pesanan1 = Pesanan::create([
            'nomor_pesanan' => 'ATK-COMMITTED-' . uniqid(),
            'pelanggan_id' => $pelangganId,
            'nama_penerima' => $payload['nama_penerima'],
            'alamat' => $payload['alamat'],
            'kota' => $payload['kota'],
            'wilayah_id' => $payload['wilayah_id'],
            'kurir_id' => $payload['kurir_id'],
            'metode_pembayaran_id' => 1,
            'subtotal' => 25000,
            'ongkos_kirim' => 5000,
            'total' => 30000,
            'status' => 'menunggu_pembayaran',
        ]);

        KunciIdempoten::create([
            'pelanggan_id' => $pelangganId,
            'kunci' => $kunci,
            'hash_permintaan' => $hashPermintaan,
            'pesanan_id' => $pesanan1->id,
        ]);

        // Simulasikan Request 2: sudah memiliki isi keranjang dan mengirim key yang sama
        Keranjang::create([
            'pelanggan_id' => $pelangganId,
            'produk_id' => $produk->id,
            'jumlah' => 2,
        ]);

        $stokAwal = $produk->fresh()->stok;

        try {
            // Jalankan checkout kedua dengan key sama
            $response = $this->withHeader('Authorization', 'Bearer ' . $this->tokenPembeli)
                ->withHeader('X-Kunci-Idempoten', $kunci)
                ->postJson('/api/checkout', $payload);

            // Harus mengembalikan pesanan 1 dengan status 200 (idempoten)
            $response->assertStatus(200)
                ->assertJson([
                'status' => 'sukses',
                'code' => '200',
                'data' => [
                    'pesanan_id' => $pesanan1->id,
                    'nomor_pesanan' => $pesanan1->nomor_pesanan,
                ],
            ]);

            // Pastikan stok TIDAK dikurangi untuk kedua kalinya (tetap utuh)
            $this->assertEquals($stokAwal, $produk->fresh()->stok);
        } finally {
            Keranjang::where('pelanggan_id', $pelangganId)->delete();
            KunciIdempoten::where('kunci', $kunci)->delete();
            $pesanan1->delete();
            $produk->delete();
        }
    }

    /**
     * 4. RACE CONDITION (CONCURRENCY NYATA DENGAN KEY SAMA):
     * Menjalankan 2 request HTTP secara paralel menggunakan curl_multi ke server live.
     * Membuktikan tepat 1 pesanan dibuat, stok hanya berkurang sekali, dan kedua request menerima pesanan yang sama.
     */
    public function test_real_concurrency_same_idempotency_key_via_curl_multi(): void
    {
        $produk = Produk::create([
            'nama' => 'Produk Parallel ' . uniqid(),
            'harga' => 10000,
            'kategori' => 'Alat Tulis',
            'stok' => 20,
            'tersedia' => true,
            'pre_order' => false,
        ]);

        // Isi keranjang pelanggan 1
        Keranjang::create([
            'pelanggan_id' => 1,
            'produk_id' => $produk->id,
            'jumlah' => 2,
        ]);

        $kunci = 'real-parallel-' . uniqid();
        $payload = json_encode([
            'nama_penerima' => 'Pembeli Paralel',
            'alamat' => 'Jl. Simpang No. 8',
            'kota' => 'Kota Malang',
            'wilayah_id' => 1,
            'kurir_id' => 1,
            'metode_pembayaran' => 'tunai_di_tempat',
        ]);

        $headers = [
            'Content-Type: application/json',
            'Accept: application/json',
            'Authorization: Bearer ' . $this->tokenPembeli,
            'X-Kunci-Idempoten: ' . $kunci,
        ];

        $mh = curl_multi_init();

        $ch1 = curl_init(self::$serverUrl . '/api/checkout');
        curl_setopt($ch1, CURLOPT_POST, true);
        curl_setopt($ch1, CURLOPT_POSTFIELDS, $payload);
        curl_setopt($ch1, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch1, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch1, CURLOPT_TIMEOUT, 10);

        $ch2 = curl_init(self::$serverUrl . '/api/checkout');
        curl_setopt($ch2, CURLOPT_POST, true);
        curl_setopt($ch2, CURLOPT_POSTFIELDS, $payload);
        curl_setopt($ch2, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch2, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch2, CURLOPT_TIMEOUT, 10);

        curl_multi_add_handle($mh, $ch1);
        curl_multi_add_handle($mh, $ch2);

        // Eksekusi paralel simultan
        $active = null;
        do {
            $mrc = curl_multi_exec($mh, $active);
        } while ($mrc == CURLM_CALL_MULTI_PERFORM);

        while ($active && $mrc == CURLM_OK) {
            if (curl_multi_select($mh) != -1) {
                do {
                    $mrc = curl_multi_exec($mh, $active);
                } while ($mrc == CURLM_CALL_MULTI_PERFORM);
            }
        }

        $res1 = json_decode(curl_multi_getcontent($ch1), true);
        $res2 = json_decode(curl_multi_getcontent($ch2), true);
        $code1 = curl_getinfo($ch1, CURLINFO_HTTP_CODE);
        $code2 = curl_getinfo($ch2, CURLINFO_HTTP_CODE);

        curl_multi_remove_handle($mh, $ch1);
        curl_multi_remove_handle($mh, $ch2);
        curl_multi_close($mh);

        try {
            // Kedua request harus sukses (satu 201 Created, satu 200 OK idempoten)
            $this->assertTrue(in_array($code1, [200, 201]), "Code 1 was {$code1}: " . json_encode($res1));
            $this->assertTrue(in_array($code2, [200, 201]), "Code 2 was {$code2}: " . json_encode($res2));

            // Keduanya harus mengembalikan nomor pesanan yang SAMA PERSIS
            $nomorPesanan1 = $res1['data']['nomor_pesanan'] ?? null;
            $nomorPesanan2 = $res2['data']['nomor_pesanan'] ?? null;
            $this->assertNotNull($nomorPesanan1);
            $this->assertEquals($nomorPesanan1, $nomorPesanan2);

            // Pastikan hanya 1 pesanan yang terbentuk untuk kunci ini
            $pesananCount = KunciIdempoten::where('kunci', $kunci)->count();
            $this->assertEquals(1, $pesananCount);

            // Pastikan stok HANYA berkurang 2 (menjadi 18, BUKAN 16)
            $this->assertEquals(18, $produk->fresh()->stok);
        } finally {
            $pesananId = $res1['data']['pesanan_id'] ?? $res2['data']['pesanan_id'] ?? null;
            if ($pesananId) {
                PesananDetail::where('pesanan_id', $pesananId)->delete();
                KunciIdempoten::where('pesanan_id', $pesananId)->delete();
                Pesanan::where('id', $pesananId)->delete();
            }
            Keranjang::where('produk_id', $produk->id)->delete();
            $produk->delete();
        }
    }

    /**
     * 5. RACE CONDITION (CONCURRENCY NYATA MEMPEREBUTKAN STOK TERAKHIR):
     * Dua request checkout bersamaan dengan KEY BERBEDA memperebutkan stok = 1.
     * Tepat satu request berhasil (201 Created), request lainnya ditolak (409 Conflict).
     * Stok akhir menjadi 0 (tidak pernah negatif).
     */
    public function test_real_concurrency_last_stock_competition_via_curl_multi(): void
    {
        $produk = Produk::create([
            'nama' => 'Barang Langka Terakhir ' . uniqid(),
            'harga' => 50000,
            'kategori' => 'Buku',
            'stok' => 1, // Hanya ada 1 stok!
            'tersedia' => true,
            'pre_order' => false,
        ]);

        // Isi keranjang pelanggan 1 (pesan 1 unit)
        Keranjang::create([
            'pelanggan_id' => 1,
            'produk_id' => $produk->id,
            'jumlah' => 1,
        ]);

        // Isi keranjang pelanggan 2 (pesan 1 unit)
        Keranjang::create([
            'pelanggan_id' => 2,
            'produk_id' => $produk->id,
            'jumlah' => 1,
        ]);

        $payloadBase = [
            'alamat' => 'Jl. Berebut No. 1',
            'kota' => 'Kota Malang',
            'wilayah_id' => 1,
            'kurir_id' => 1,
            'metode_pembayaran' => 'tunai_di_tempat',
        ];

        $payload1 = json_encode(array_merge($payloadBase, ['nama_penerima' => 'Pembeli 1']));
        $payload2 = json_encode(array_merge($payloadBase, ['nama_penerima' => 'Pembeli 2']));

        $mh = curl_multi_init();

        $ch1 = curl_init(self::$serverUrl . '/api/checkout');
        curl_setopt($ch1, CURLOPT_POST, true);
        curl_setopt($ch1, CURLOPT_POSTFIELDS, $payload1);
        curl_setopt($ch1, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Accept: application/json',
            'Authorization: Bearer ' . $this->tokenPembeli,
            'X-Kunci-Idempoten: key-comp-1-' . uniqid(),
        ]);
        curl_setopt($ch1, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch1, CURLOPT_TIMEOUT, 10);

        $ch2 = curl_init(self::$serverUrl . '/api/checkout');
        curl_setopt($ch2, CURLOPT_POST, true);
        curl_setopt($ch2, CURLOPT_POSTFIELDS, $payload2);
        curl_setopt($ch2, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Accept: application/json',
            'Authorization: Bearer ' . $this->tokenPembeli2,
            'X-Kunci-Idempoten: key-comp-2-' . uniqid(),
        ]);
        curl_setopt($ch2, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch2, CURLOPT_TIMEOUT, 10);

        curl_multi_add_handle($mh, $ch1);
        curl_multi_add_handle($mh, $ch2);

        $active = null;
        do {
            $mrc = curl_multi_exec($mh, $active);
        } while ($mrc == CURLM_CALL_MULTI_PERFORM);

        while ($active && $mrc == CURLM_OK) {
            if (curl_multi_select($mh) != -1) {
                do {
                    $mrc = curl_multi_exec($mh, $active);
                } while ($mrc == CURLM_CALL_MULTI_PERFORM);
            }
        }

        $res1 = json_decode(curl_multi_getcontent($ch1), true);
        $res2 = json_decode(curl_multi_getcontent($ch2), true);
        $code1 = curl_getinfo($ch1, CURLINFO_HTTP_CODE);
        $code2 = curl_getinfo($ch2, CURLINFO_HTTP_CODE);

        curl_multi_remove_handle($mh, $ch1);
        curl_multi_remove_handle($mh, $ch2);
        curl_multi_close($mh);

        try {
            $statusCodes = [$code1, $code2];
            sort($statusCodes);

            // Tepat 1 request harus 201 Created dan 1 request harus 409 Conflict
            $this->assertEquals([201, 409], $statusCodes, 'Satu request harus 201 dan yang kalah harus 409. Hasil: ' . json_encode([$code1 => $res1, $code2 => $res2]));

            // Stok akhir harus tepat 0 (tidak boleh -1)
            $this->assertEquals(0, $produk->fresh()->stok);
        } finally {
            $winnerRes = ($code1 === 201) ? $res1 : $res2;
            $winnerOrderId = $winnerRes['data']['pesanan_id'] ?? null;
            if ($winnerOrderId) {
                PesananDetail::where('pesanan_id', $winnerOrderId)->delete();
                KunciIdempoten::where('pesanan_id', $winnerOrderId)->delete();
                Pesanan::where('id', $winnerOrderId)->delete();
            }
            Keranjang::where('produk_id', $produk->id)->delete();
            $produk->delete();
        }
    }
}
