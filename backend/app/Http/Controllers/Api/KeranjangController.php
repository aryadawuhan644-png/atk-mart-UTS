<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Keranjang;
use App\Models\Produk;
use App\Models\TarifKurir;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class KeranjangController extends Controller
{
    /**
     * Hitung harga satuan efektif berdasarkan aturan harga grosir.
     */
    public static function hitungHargaSatuan(Produk $produk, int $jumlah): int
    {
        $tiers = $produk->hargaGrosir ?? collect();
        $grosir = $tiers
            ->filter(fn($tier) => (int) $tier->min_kuantitas <= $jumlah)
            ->sortByDesc(fn($tier) => (int) $tier->min_kuantitas)
            ->first();

        return $grosir ? (int) $grosir->harga_satuan : (int) $produk->harga;
    }

    /**
     * Format payload data keranjang beserta subtotal dari server.
     */
    public static function formatKeranjang(int $pelangganId, ?int $kurirId = null, ?int $wilayahId = null): array
    {
        $items = Keranjang::with(['produk.hargaGrosir'])
            ->where('pelanggan_id', $pelangganId)
            ->orderBy('id', 'asc')
            ->get();

        $subtotal = 0;
        $formattedItems = [];

        foreach ($items as $item) {
            $hargaSatuan = self::hitungHargaSatuan($item->produk, $item->jumlah);
            $itemSubtotal = $hargaSatuan * $item->jumlah;
            $subtotal += $itemSubtotal;

            $formattedItems[] = [
                'id' => (int) $item->id,
                'produk_id' => (int) $item->produk_id,
                'nama' => (string) $item->produk->nama,
                'jumlah' => (int) $item->jumlah,
                'harga_satuan' => (int) $hargaSatuan,
                'subtotal' => (int) $itemSubtotal,
            ];
        }

        $result = [
            'items' => $formattedItems,
            'subtotal' => (int) $subtotal,
        ];

        if ($kurirId && $wilayahId) {
            $tarif = TarifKurir::where('kurir_id', $kurirId)
                ->where('wilayah_id', $wilayahId)
                ->value('tarif');

            if ($tarif !== null) {
                $result['ongkos_kirim'] = (int) $tarif;
                $result['total'] = (int) ($subtotal + $tarif);
            }
        }

        return $result;
    }

    /**
     * Endpoint 6: GET /api/keranjang
     * Mengembalikan item keranjang dan subtotal hitungan server.
     */
    public function index(Request $request): JsonResponse
    {
        $pelangganId = (int) $request->attributes->get('pelanggan_id', 1);
        $kurirId = $request->query('kurir_id') ? (int) $request->query('kurir_id') : null;
        $wilayahId = $request->query('wilayah_id') ? (int) $request->query('wilayah_id') : null;

        $data = self::formatKeranjang($pelangganId, $kurirId, $wilayahId);

        return response()->json([
            'status' => 'sukses',
            'code' => '200',
            'message' => 'Data keranjang berhasil diambil',
            'data' => $data,
        ], 200);
    }

    /**
     * Endpoint 7: POST /api/keranjang
     * Menambahkan produk ke keranjang (atau menambah jumlah jika produk sudah ada).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'produk_id' => 'required|integer|exists:produk,id',
            'jumlah' => 'required|integer|min:1',
        ]);

        $pelangganId = (int) $request->attributes->get('pelanggan_id', 1);
        $produk = Produk::find($validated['produk_id']);

        if (!$produk) {
            return response()->json([
                'status' => 'gagal',
                'code' => '404',
                'message' => 'Produk tidak ditemukan',
                'data' => null,
            ], 404);
        }

        // Aturan BR-01: Produk tersedia=false tidak dapat dimasukkan ke keranjang
        if (!$produk->tersedia) {
            return response()->json([
                'status' => 'gagal',
                'code' => '409',
                'message' => "Produk '{$produk->nama}' saat ini tidak tersedia",
                'data' => null,
            ], 409);
        }

        $existing = Keranjang::where('pelanggan_id', $pelangganId)
            ->where('produk_id', $produk->id)
            ->first();

        $totalJumlah = ($existing ? $existing->jumlah : 0) + $validated['jumlah'];

        // Aturan BR-02: Non-pre-order dengan stok kurang dari total diminta ditolak (409)
        if (!$produk->pre_order && $totalJumlah > $produk->stok) {
            return response()->json([
                'status' => 'gagal',
                'code' => '409',
                'message' => "Stok produk '{$produk->nama}' tidak mencukupi (tersedia: {$produk->stok})",
                'data' => null,
            ], 409);
        }

        if ($existing) {
            $existing->jumlah = $totalJumlah;
            $existing->save();
            $statusCode = 200;
            $message = 'Jumlah produk di keranjang berhasil ditambahkan';
        } else {
            Keranjang::create([
                'pelanggan_id' => $pelangganId,
                'produk_id' => $produk->id,
                'jumlah' => $validated['jumlah'],
            ]);
            $statusCode = 201;
            $message = 'Produk berhasil ditambahkan ke keranjang';
        }

        return response()->json([
            'status' => 'sukses',
            'code' => (string) $statusCode,
            'message' => $message,
            'data' => self::formatKeranjang($pelangganId),
        ], $statusCode);
    }

    /**
     * Endpoint 8: PUT /api/keranjang/{id}
     * Mengubah jumlah item di keranjang.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'jumlah' => 'required|integer|min:1',
        ], [
            'jumlah.min' => 'Jumlah harus lebih besar dari nol.',
        ]);

        $pelangganId = (int) $request->attributes->get('pelanggan_id', 1);
        $item = Keranjang::with('produk')->where('pelanggan_id', $pelangganId)->where('id', $id)->first();

        if (!$item) {
            return response()->json([
                'status' => 'gagal',
                'code' => '404',
                'message' => 'Item keranjang tidak ditemukan',
                'data' => null,
            ], 404);
        }

        $produk = $item->produk;

        if (!$produk || !$produk->tersedia) {
            return response()->json([
                'status' => 'gagal',
                'code' => '409',
                'message' => 'Produk tidak tersedia',
                'data' => null,
            ], 409);
        }

        if (!$produk->pre_order && $validated['jumlah'] > $produk->stok) {
            return response()->json([
                'status' => 'gagal',
                'code' => '409',
                'message' => "Stok produk '{$produk->nama}' tidak mencukupi (tersedia: {$produk->stok})",
                'data' => null,
            ], 409);
        }

        $item->jumlah = $validated['jumlah'];
        $item->save();

        return response()->json([
            'status' => 'sukses',
            'code' => '200',
            'message' => 'Jumlah item keranjang berhasil diperbarui',
            'data' => self::formatKeranjang($pelangganId),
        ], 200);
    }

    /**
     * Endpoint 9: DELETE /api/keranjang/{id}
     * Menghapus item dari keranjang.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $pelangganId = (int) $request->attributes->get('pelanggan_id', 1);
        $item = Keranjang::where('pelanggan_id', $pelangganId)->where('id', $id)->first();

        if (!$item) {
            return response()->json([
                'status' => 'gagal',
                'code' => '404',
                'message' => 'Item keranjang tidak ditemukan',
                'data' => null,
            ], 404);
        }

        $item->delete();

        return response()->json([
            'status' => 'sukses',
            'code' => '200',
            'message' => 'Item keranjang berhasil dihapus',
            'data' => null,
        ], 200);
    }
}
