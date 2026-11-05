<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\HargaGrosir;
use App\Models\PesananDetail;
use App\Models\Produk;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProdukController extends Controller
{
    /**
     * Format data produk sesuai kontrak PRD (Bagian 10.3).
     */
    public static function formatProduk(Produk $produk): array
    {
        return [
            'id' => (int) $produk->id,
            'nama' => (string) $produk->nama,
            'harga' => (int) $produk->harga,
            'kategori' => (string) $produk->kategori,
            'stok' => (int) $produk->stok,
            'tersedia' => (bool) $produk->tersedia,
            'deskripsi' => $produk->deskripsi !== null ? (string) $produk->deskripsi : null,
            'pre_order' => (bool) $produk->pre_order,
            'estimasi_tersedia' => $produk->estimasi_tersedia ? (is_string($produk->estimasi_tersedia) ? substr($produk->estimasi_tersedia, 0, 10) : $produk->estimasi_tersedia->format('Y-m-d')) : null,
            'harga_grosir' => $produk->hargaGrosir->map(function ($g) {
                return [
                    'min_kuantitas' => (int) $g->min_kuantitas,
                    'harga_satuan' => (int) $g->harga_satuan,
                ];
            })->values()->all(),
        ];
    }

    /**
     * Endpoint 1: GET /api/produk
     * Menampilkan daftar produk dengan filter kategori dan pencarian nama/deskripsi.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Produk::with('hargaGrosir');

        if ($request->filled('kategori')) {
            $query->where('kategori', $request->query('kategori'));
        }

        if ($request->filled('cari')) {
            $cari = $request->query('cari');
            $query->where(function ($q) use ($cari) {
                $q->where('nama', 'like', "%{$cari}%")
                  ->orWhere('deskripsi', 'like', "%{$cari}%");
            });
        }

        $produkList = $query->orderBy('id', 'asc')->get();

        return response()->json([
            'status' => 'sukses',
            'code' => '200',
            'message' => 'Daftar produk berhasil diambil',
            'data' => $produkList->map(fn($p) => self::formatProduk($p))->values()->all(),
        ], 200);
    }

    /**
     * Endpoint 2: GET /api/produk/{id}
     * Menampilkan detail satu produk.
     */
    public function show(int $id): JsonResponse
    {
        $produk = Produk::with('hargaGrosir')->find($id);

        if (!$produk) {
            return response()->json([
                'status' => 'gagal',
                'code' => '404',
                'message' => 'Produk tidak ditemukan',
                'data' => null,
            ], 404);
        }

        return response()->json([
            'status' => 'sukses',
            'code' => '200',
            'message' => 'Detail produk berhasil diambil',
            'data' => self::formatProduk($produk),
        ], 200);
    }

    /**
     * Endpoint 3: POST /api/produk
     * Menambahkan produk baru (khusus pengelola).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'nama' => 'required|string|max:255',
            'harga' => 'required|integer|min:1',
            'kategori' => 'required|string|max:100',
            'stok' => 'required|integer|min:0',
            'tersedia' => 'nullable|boolean',
            'deskripsi' => 'nullable|string',
            'pre_order' => 'nullable|boolean',
            'estimasi_tersedia' => 'nullable|date',
            'harga_grosir' => 'nullable|array',
            'harga_grosir.*.min_kuantitas' => 'required_with:harga_grosir|integer|min:2',
            'harga_grosir.*.harga_satuan' => 'required_with:harga_grosir|integer|min:1',
        ]);

        $produk = DB::transaction(function () use ($validated) {
            $dataProduk = [
                'nama' => $validated['nama'],
                'harga' => $validated['harga'],
                'kategori' => $validated['kategori'],
                'stok' => $validated['stok'],
                'tersedia' => $validated['tersedia'] ?? true,
                'deskripsi' => $validated['deskripsi'] ?? null,
                'pre_order' => $validated['pre_order'] ?? false,
                'estimasi_tersedia' => $validated['estimasi_tersedia'] ?? null,
            ];

            $created = Produk::create($dataProduk);

            if (!empty($validated['harga_grosir'])) {
                foreach ($validated['harga_grosir'] as $tier) {
                    HargaGrosir::create([
                        'produk_id' => $created->id,
                        'min_kuantitas' => $tier['min_kuantitas'],
                        'harga_satuan' => $tier['harga_satuan'],
                    ]);
                }
            }

            return $created->fresh('hargaGrosir');
        });

        return response()->json([
            'status' => 'sukses',
            'code' => '201',
            'message' => 'Produk berhasil dibuat',
            'data' => self::formatProduk($produk),
        ], 201);
    }

    /**
     * Endpoint 4: PUT /api/produk/{id}
     * Memperbarui produk (khusus pengelola).
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $produk = Produk::with('hargaGrosir')->find($id);

        if (!$produk) {
            return response()->json([
                'status' => 'gagal',
                'code' => '404',
                'message' => 'Produk tidak ditemukan',
                'data' => null,
            ], 404);
        }

        $validated = $request->validate([
            'nama' => 'sometimes|required|string|max:255',
            'harga' => 'sometimes|required|integer|min:1',
            'kategori' => 'sometimes|required|string|max:100',
            'stok' => 'sometimes|required|integer|min:0',
            'tersedia' => 'sometimes|boolean',
            'deskripsi' => 'nullable|string',
            'pre_order' => 'sometimes|boolean',
            'estimasi_tersedia' => 'nullable|date',
            'harga_grosir' => 'nullable|array',
            'harga_grosir.*.min_kuantitas' => 'required_with:harga_grosir|integer|min:2',
            'harga_grosir.*.harga_satuan' => 'required_with:harga_grosir|integer|min:1',
        ]);

        $updatedProduk = DB::transaction(function () use ($produk, $validated) {
            $produk->update($validated);

            if (array_key_exists('harga_grosir', $validated)) {
                $produk->hargaGrosir()->delete();
                if (!empty($validated['harga_grosir'])) {
                    foreach ($validated['harga_grosir'] as $tier) {
                        HargaGrosir::create([
                            'produk_id' => $produk->id,
                            'min_kuantitas' => $tier['min_kuantitas'],
                            'harga_satuan' => $tier['harga_satuan'],
                        ]);
                    }
                }
            }

            return $produk->fresh('hargaGrosir');
        });

        return response()->json([
            'status' => 'sukses',
            'code' => '200',
            'message' => 'Produk berhasil diperbarui',
            'data' => self::formatProduk($updatedProduk),
        ], 200);
    }

    /**
     * Endpoint 5: DELETE /api/produk/{id}
     * Menghapus produk (khusus pengelola; ditolak 409 bila pada pesanan aktif).
     */
    public function destroy(int $id): JsonResponse
    {
        $produk = Produk::find($id);

        if (!$produk) {
            return response()->json([
                'status' => 'gagal',
                'code' => '404',
                'message' => 'Produk tidak ditemukan',
                'data' => null,
            ], 404);
        }

        // Cek apakah terkait pesanan aktif (status bukan selesai atau dibatalkan)
        $activeOrderCount = PesananDetail::where('produk_id', $produk->id)
            ->whereHas('pesanan', function ($q) {
                $q->whereNotIn('status', ['selesai', 'dibatalkan']);
            })
            ->count();

        if ($activeOrderCount > 0) {
            return response()->json([
                'status' => 'gagal',
                'code' => '409',
                'message' => 'Produk tidak dapat dihapus karena masih terkait dengan pesanan yang sedang aktif',
                'data' => null,
            ], 409);
        }

        $produk->delete();

        return response()->json([
            'status' => 'sukses',
            'code' => '200',
            'message' => 'Produk berhasil dihapus',
            'data' => null,
        ], 200);
    }
}
