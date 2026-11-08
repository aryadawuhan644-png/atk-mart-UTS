<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Keranjang;
use App\Models\KunciIdempoten;
use App\Models\MetodePembayaran;
use App\Models\Pesanan;
use App\Models\PesananDetail;
use App\Models\Produk;
use App\Models\RiwayatStatusPesanan;
use App\Models\TarifKurir;
use App\Models\WilayahAntar;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CheckoutController extends Controller
{
    /**
     * Endpoint 11: POST /api/checkout
     * Melakukan transaksi checkout yang atomik dengan idempotency key,
     * perhitungan harga grosir, verifikasi stok, dan pencatatan snapshot pesanan.
     */
    public function store(Request $request): JsonResponse
    {
        $kunci = $request->header('X-Kunci-Idempoten');

        if (!$kunci || trim($kunci) === '') {
            return response()->json([
                'status' => 'gagal',
                'code' => '422',
                'message' => 'Header X-Kunci-Idempoten wajib disertakan',
                'errors' => [
                    'X-Kunci-Idempoten' => ['Header X-Kunci-Idempoten wajib disertakan.'],
                ],
            ], 422);
        }

        $validated = $request->validate([
            'nama_penerima' => 'required|string|max:255',
            'alamat' => 'required|string|max:500',
            'kota' => 'required|string|max:100',
            'wilayah_id' => 'required|integer|exists:wilayah_antar,id',
            'kurir_id' => 'required|integer|exists:kurir,id',
            'metode_pembayaran' => 'required|string|max:50',
            'item_ids' => 'nullable|array',
            'item_ids.*' => 'integer|exists:keranjang,id',
        ]);

        $pelangganId = (int) $request->attributes->get('pelanggan_id', 1);

        // 1. Normalisasi payload untuk verifikasi hash idempoten
        $payloadToHash = [
            'nama_penerima' => $validated['nama_penerima'],
            'alamat' => $validated['alamat'],
            'kota' => $validated['kota'],
            'wilayah_id' => (int) $validated['wilayah_id'],
            'kurir_id' => (int) $validated['kurir_id'],
            'metode_pembayaran' => (string) $validated['metode_pembayaran'],
        ];
        if (isset($validated['item_ids'])) {
            $payloadToHash['item_ids'] = array_values($validated['item_ids']);
        }
        $hashPermintaan = hash('sha256', json_encode($payloadToHash));

        // 2. Cek apakah kunci idempoten sudah pernah digunakan
        $kunciRecord = KunciIdempoten::where('pelanggan_id', $pelangganId)
            ->where('kunci', $kunci)
            ->first();

        if ($kunciRecord) {
            if ($kunciRecord->hash_permintaan !== $hashPermintaan) {
                return response()->json([
                    'status' => 'gagal',
                    'code' => '409',
                    'message' => 'Kunci idempoten sudah digunakan dengan data permintaan berbeda',
                    'data' => null,
                ], 409);
            }

            $pesananLama = Pesanan::find($kunciRecord->pesanan_id);
            if ($pesananLama) {
                return response()->json([
                    'status' => 'sukses',
                    'code' => '200',
                    'message' => 'Pesanan lama dikembalikan (idempoten)',
                    'data' => [
                        'pesanan_id' => (int) $pesananLama->id,
                        'nomor_pesanan' => (string) $pesananLama->nomor_pesanan,
                        'status' => (string) $pesananLama->status,
                        'subtotal' => (int) $pesananLama->subtotal,
                        'ongkos_kirim' => (int) $pesananLama->ongkos_kirim,
                        'total' => (int) $pesananLama->total,
                    ],
                ], 200);
            }
        }

        // 3. Validasi wilayah Malang (Aturan domain TIM T3 / Section 14)
        $wilayah = WilayahAntar::where('id', $validated['wilayah_id'])->where('aktif', true)->first();
        if (!$wilayah || $wilayah->kota !== 'Kota Malang' || stripos($validated['kota'], 'Malang') === false) {
            return response()->json([
                'status' => 'gagal',
                'code' => '422',
                'message' => 'Pengiriman di luar wilayah Kota Malang tidak didukung',
                'errors' => [
                    'wilayah_id' => ['Wilayah pengiriman di luar cakupan Kota Malang.'],
                ],
            ], 422);
        }

        // 4. Validasi ketersediaan kurir & tarif
        $tarifRecord = TarifKurir::where('kurir_id', $validated['kurir_id'])
            ->where('wilayah_id', $validated['wilayah_id'])
            ->first();

        if (!$tarifRecord) {
            return response()->json([
                'status' => 'gagal',
                'code' => '422',
                'message' => 'Tarif kurir untuk wilayah yang dipilih tidak tersedia',
                'errors' => [
                    'kurir_id' => ['Kombinasi kurir dan wilayah pengiriman tidak memiliki tarif aktif.'],
                ],
            ], 422);
        }

        $ongkosKirim = (int) $tarifRecord->tarif;

        // 5. Validasi metode pembayaran
        $metode = MetodePembayaran::where('kode', $validated['metode_pembayaran'])->first();
        if (!$metode) {
            return response()->json([
                'status' => 'gagal',
                'code' => '422',
                'message' => 'Metode pembayaran tidak valid',
                'errors' => [
                    'metode_pembayaran' => ['Metode pembayaran tidak ditemukan.'],
                ],
            ], 422);
        }

        // 6. Transaksi Checkout Atomik
        try {
            $pesanan = DB::transaction(function () use ($pelangganId, $validated, $wilayah, $metode, $ongkosKirim, $kunci, $hashPermintaan) {
                // Kunci baris keranjang (hanya item_ids jika dipilih, atau semua jika tidak ditentukan)
                $cartQuery = Keranjang::where('pelanggan_id', $pelangganId);
                if (!empty($validated['item_ids'])) {
                    $cartQuery->whereIn('id', $validated['item_ids']);
                }
                $cartItems = $cartQuery->lockForUpdate()->get();

                if ($cartItems->isEmpty()) {
                    throw new \DomainException('Keranjang belanja kosong', 422);
                }

                // Urutkan ID produk untuk mencegah potensi deadlock database
                $productIds = $cartItems->pluck('produk_id')->sort()->values();
                $products = Produk::with('hargaGrosir')->whereIn('id', $productIds)->lockForUpdate()->get()->keyBy('id');

                $subtotal = 0;
                $hasPreorderWaiting = false;
                $detailsData = [];

                foreach ($cartItems as $item) {
                    $prod = $products->get($item->produk_id);
                    if (!$prod) {
                        throw new \DomainException('Produk tidak ditemukan', 404);
                    }

                    // BR-01: Produk tersedia=false ditolak
                    if (!$prod->tersedia) {
                        throw new \DomainException("Produk '{$prod->nama}' saat ini tidak tersedia", 409);
                    }

                    // BR-02: Non-preorder melebihi stok ditolak
                    if (!$prod->pre_order && $item->jumlah > $prod->stok) {
                        throw new \DomainException("Stok produk '{$prod->nama}' tidak mencukupi (tersedia: {$prod->stok})", 409);
                    }

                    // Hitung harga satuan berdasarkan aturan grosir
                    $hargaSatuan = KeranjangController::hitungHargaSatuan($prod, $item->jumlah);
                    $itemSubtotal = $hargaSatuan * $item->jumlah;
                    $subtotal += $itemSubtotal;

                    $menungguStok = false;
                    $stokDikurangi = 0;

                    if (!$prod->pre_order) {
                        $prod->stok -= $item->jumlah;
                        $prod->save();
                        $stokDikurangi = $item->jumlah;
                    } else {
                        // Pre-order: kurangi stok tersedia tanpa membuat stok negatif
                        if ($item->jumlah <= $prod->stok) {
                            $prod->stok -= $item->jumlah;
                            $prod->save();
                            $stokDikurangi = $item->jumlah;
                        } else {
                            $stokDikurangi = max(0, (int) $prod->stok);
                            $prod->stok = 0;
                            $prod->save();
                            $menungguStok = true;
                            $hasPreorderWaiting = true;
                        }
                    }

                    $detailsData[] = [
                        'produk_id' => $prod->id,
                        'nama_produk' => $prod->nama,
                        'harga_normal' => (int) $prod->harga,
                        'harga_satuan' => (int) $hargaSatuan,
                        'jumlah' => (int) $item->jumlah,
                        'subtotal' => (int) $itemSubtotal,
                        'menunggu_stok' => $menungguStok,
                        'stok_dikurangi' => $stokDikurangi,
                    ];
                }

                // Pisahkan status awal COD vs Transfer Manual:
                // Pre-order butuh stok -> menunggu_stok
                // COD normal -> langsung menunggu_konfirmasi (konfirmasi pesanan oleh toko tanpa bayar di muka)
                // Transfer normal -> menunggu_pembayaran
                $isCod = ($metode->kode === 'tunai_di_tempat');
                if ($hasPreorderWaiting) {
                    $initialStatus = 'menunggu_stok';
                    $catatanAwal = 'Pesanan memuat produk pre-order, menunggu pasokan fisik dari pemasok';
                } else {
                    $initialStatus = $isCod ? 'menunggu_konfirmasi' : 'menunggu_pembayaran';
                    $catatanAwal = $isCod
                        ? 'Pesanan COD berhasil dibuat, menunggu konfirmasi pesanan oleh toko'
                        : 'Pesanan berhasil dibuat melalui checkout, menunggu pembayaran';
                }

                $total = $subtotal + $ongkosKirim;

                // Buat nomor pesanan format: ATK-YYYYMMDD-XXXXX
                $nextId = (int) (Pesanan::max('id') ?? 0) + 1;
                $nomorPesanan = 'ATK-' . date('Ymd') . '-' . str_pad((string) $nextId, 5, '0', STR_PAD_LEFT);

                $pesanan = Pesanan::create([
                    'nomor_pesanan' => $nomorPesanan,
                    'pelanggan_id' => $pelangganId,
                    'nama_penerima' => $validated['nama_penerima'],
                    'alamat' => $validated['alamat'],
                    'kota' => $validated['kota'],
                    'wilayah_id' => $wilayah->id,
                    'kurir_id' => $validated['kurir_id'],
                    'metode_pembayaran_id' => $metode->id,
                    'subtotal' => $subtotal,
                    'ongkos_kirim' => $ongkosKirim,
                    'total' => $total,
                    'status' => $initialStatus,
                ]);

                foreach ($detailsData as $detail) {
                    $detail['pesanan_id'] = $pesanan->id;
                    PesananDetail::create($detail);
                }

                RiwayatStatusPesanan::create([
                    'pesanan_id' => $pesanan->id,
                    'status_lama' => null,
                    'status_baru' => $initialStatus,
                    'aktor' => 'sistem',
                    'catatan' => $catatanAwal,
                ]);

                KunciIdempoten::create([
                    'pelanggan_id' => $pelangganId,
                    'kunci' => $kunci,
                    'hash_permintaan' => $hashPermintaan,
                    'pesanan_id' => $pesanan->id,
                ]);

                // Hapus hanya item yang di-checkout dari keranjang, pertahankan item lainnya
                Keranjang::where('pelanggan_id', $pelangganId)
                    ->whereIn('id', $cartItems->pluck('id'))
                    ->delete();

                return $pesanan;

                return $pesanan;
            });

            return response()->json([
                'status' => 'sukses',
                'code' => '201',
                'message' => 'Pesanan berhasil dibuat',
                'data' => [
                    'pesanan_id' => (int) $pesanan->id,
                    'nomor_pesanan' => (string) $pesanan->nomor_pesanan,
                    'status' => (string) $pesanan->status,
                    'subtotal' => (int) $pesanan->subtotal,
                    'ongkos_kirim' => (int) $pesanan->ongkos_kirim,
                    'total' => (int) $pesanan->total,
                ],
            ], 201);
        } catch (\DomainException $e) {
            $code = $e->getCode() ?: 409;
            return response()->json([
                'status' => 'gagal',
                'code' => (string) $code,
                'message' => $e->getMessage(),
                'data' => null,
            ], $code);
        } catch (\Illuminate\Database\QueryException $e) {
            // Tangani race condition / duplicate entry pada kunci_idempoten (PRD Bagian 12.4)
            if (isset($e->errorInfo[1]) && $e->errorInfo[1] == 1062 || str_contains($e->getMessage(), 'Duplicate entry') || str_contains($e->getMessage(), 'Integrity constraint violation')) {
                $retryRecord = null;
                for ($attempt = 0; $attempt < 5; $attempt++) {
                    $retryRecord = KunciIdempoten::where('pelanggan_id', $pelangganId)
                        ->where('kunci', $kunci)
                        ->first();

                    if ($retryRecord && $retryRecord->pesanan_id) {
                        break;
                    }
                    usleep(30000); // 30ms
                }

                if ($retryRecord) {
                    if ($retryRecord->hash_permintaan !== $hashPermintaan) {
                        return response()->json([
                            'status' => 'gagal',
                            'code' => '409',
                            'message' => 'Kunci idempoten sudah digunakan dengan data permintaan berbeda',
                            'data' => null,
                        ], 409);
                    }

                    $pesananLama = Pesanan::find($retryRecord->pesanan_id);
                    if ($pesananLama) {
                        return response()->json([
                            'status' => 'sukses',
                            'code' => '200',
                            'message' => 'Pesanan berhasil ditemukan (idempoten)',
                            'data' => [
                                'pesanan_id' => (int) $pesananLama->id,
                                'nomor_pesanan' => (string) $pesananLama->nomor_pesanan,
                                'status' => (string) $pesananLama->status,
                                'subtotal' => (int) $pesananLama->subtotal,
                                'ongkos_kirim' => (int) $pesananLama->ongkos_kirim,
                                'total' => (int) $pesananLama->total,
                            ],
                        ], 200);
                    }
                }
            }

            throw $e;
        }
    }
}
