<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use App\Models\Produk;
use App\Models\RiwayatStatusPesanan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PesananController extends Controller
{
    /**
     * Format ringkasan pesanan untuk daftar riwayat.
     */
    public static function formatPesananSummary(Pesanan $pesanan): array
    {
        return [
            'id' => (int) $pesanan->id,
            'nomor_pesanan' => (string) $pesanan->nomor_pesanan,
            'status' => (string) $pesanan->status,
            'subtotal' => (int) $pesanan->subtotal,
            'ongkos_kirim' => (int) $pesanan->ongkos_kirim,
            'total' => (int) $pesanan->total,
            'nama_penerima' => (string) $pesanan->nama_penerima,
            'kurir' => $pesanan->kurir ? (string) $pesanan->kurir->nama : null,
            'wilayah' => $pesanan->wilayah ? (string) $pesanan->wilayah->nama : null,
            'metode_pembayaran' => $pesanan->metodePembayaran ? (string) $pesanan->metodePembayaran->nama : null,
            'jumlah_item' => (int) $pesanan->detail->sum('jumlah'),
            'created_at' => $pesanan->created_at ? $pesanan->created_at->format('Y-m-d H:i:s') : null,
        ];
    }

    /**
     * Format detail lengkap pesanan beserta snapshot dan riwayat status.
     */
    public static function formatPesananDetail(Pesanan $pesanan): array
    {
        return [
            'id' => (int) $pesanan->id,
            'nomor_pesanan' => (string) $pesanan->nomor_pesanan,
            'status' => (string) $pesanan->status,
            'nama_penerima' => (string) $pesanan->nama_penerima,
            'alamat' => (string) $pesanan->alamat,
            'kota' => (string) $pesanan->kota,
            'wilayah' => $pesanan->wilayah ? [
                'id' => (int) $pesanan->wilayah->id,
                'nama' => (string) $pesanan->wilayah->nama,
                'kota' => (string) $pesanan->wilayah->kota,
            ] : null,
            'kurir' => $pesanan->kurir ? [
                'id' => (int) $pesanan->kurir->id,
                'nama' => (string) $pesanan->kurir->nama,
            ] : null,
            'metode_pembayaran' => $pesanan->metodePembayaran ? [
                'id' => (int) $pesanan->metodePembayaran->id,
                'kode' => (string) $pesanan->metodePembayaran->kode,
                'nama' => (string) $pesanan->metodePembayaran->nama,
            ] : null,
            'subtotal' => (int) $pesanan->subtotal,
            'ongkos_kirim' => (int) $pesanan->ongkos_kirim,
            'total' => (int) $pesanan->total,
            'created_at' => $pesanan->created_at ? $pesanan->created_at->format('Y-m-d H:i:s') : null,
            'items' => $pesanan->detail->map(function ($d) {
                return [
                    'id' => (int) $d->id,
                    'produk_id' => $d->produk_id ? (int) $d->produk_id : null,
                    'nama_produk' => (string) $d->nama_produk,
                    'harga_normal' => (int) $d->harga_normal,
                    'harga_satuan' => (int) $d->harga_satuan,
                    'jumlah' => (int) $d->jumlah,
                    'subtotal' => (int) $d->subtotal,
                    'menunggu_stok' => (bool) $d->menunggu_stok,
                ];
            })->values()->all(),
            'riwayat_status' => $pesanan->riwayatStatus->map(function ($r) {
                return [
                    'id' => (int) $r->id,
                    'status_lama' => $r->status_lama,
                    'status_baru' => (string) $r->status_baru,
                    'aktor' => (string) $r->aktor,
                    'catatan' => $r->catatan,
                    'created_at' => $r->created_at ? $r->created_at->format('Y-m-d H:i:s') : null,
                ];
            })->values()->all(),
        ];
    }

    /**
     * Endpoint 12: GET /api/pesanan
     * Menampilkan riwayat pesanan (terbaru lebih dahulu).
     */
    public function index(Request $request): JsonResponse
    {
        $pelangganId = (int) $request->attributes->get('pelanggan_id', 1);
        $role = (string) $request->attributes->get('auth_role', 'pembeli');

        $query = Pesanan::with(['kurir', 'wilayah', 'metodePembayaran', 'detail'])->orderBy('created_at', 'desc');

        if ($role === 'pembeli') {
            $query->where('pelanggan_id', $pelangganId);
        }

        $orders = $query->get();

        return response()->json([
            'status' => 'sukses',
            'code' => '200',
            'message' => 'Riwayat pesanan berhasil diambil',
            'data' => $orders->map(fn($p) => self::formatPesananSummary($p))->values()->all(),
        ], 200);
    }

    /**
     * Endpoint 13: GET /api/pesanan/{id}
     * Menampilkan detail pesanan lengkap beserta snapshot harga dan riwayat status.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $pelangganId = (int) $request->attributes->get('pelanggan_id', 1);
        $role = (string) $request->attributes->get('auth_role', 'pembeli');

        $query = Pesanan::with(['kurir', 'wilayah', 'metodePembayaran', 'detail', 'riwayatStatus'])->where('id', $id);

        if ($role === 'pembeli') {
            $query->where('pelanggan_id', $pelangganId);
        }

        $pesanan = $query->first();

        if (!$pesanan) {
            $otherOrder = Pesanan::find($id);
            if ($otherOrder && $role === 'pembeli' && $otherOrder->pelanggan_id !== $pelangganId) {
                return response()->json([
                    'status' => 'gagal',
                    'code' => '403',
                    'message' => 'Akses ditolak: Anda tidak memiliki akses ke pesanan pelanggan lain',
                    'data' => null,
                ], 403);
            }

            return response()->json([
                'status' => 'gagal',
                'code' => '404',
                'message' => 'Pesanan tidak ditemukan',
                'data' => null,
            ], 404);
        }

        return response()->json([
            'status' => 'sukses',
            'code' => '200',
            'message' => 'Detail pesanan berhasil diambil',
            'data' => self::formatPesananDetail($pesanan),
        ], 200);
    }

    /**
     * Endpoint 14: PATCH /api/pesanan/{id}/status
     * Memperbarui status pesanan sesuai matriks transisi sah dan hak akses role (Bagian 15.2).
     */
    public function updateStatus(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'status' => 'required|string|in:menunggu_stok,menunggu_pembayaran,menunggu_konfirmasi,dibayar,diproses,dikirim,selesai,dibatalkan',
            'catatan' => 'nullable|string|max:255',
        ]);

        $pelangganId = (int) $request->attributes->get('pelanggan_id', 1);
        $role = (string) $request->attributes->get('auth_role', 'pembeli');

        $query = Pesanan::with('detail')->where('id', $id);
        if ($role === 'pembeli') {
            $query->where('pelanggan_id', $pelangganId);
        }

        $pesanan = $query->first();

        if (!$pesanan) {
            $otherOrder = Pesanan::find($id);
            if ($otherOrder && $role === 'pembeli' && $otherOrder->pelanggan_id !== $pelangganId) {
                return response()->json([
                    'status' => 'gagal',
                    'code' => '403',
                    'message' => 'Akses ditolak: Anda tidak memiliki akses ke pesanan pelanggan lain',
                    'data' => null,
                ], 403);
            }

            return response()->json([
                'status' => 'gagal',
                'code' => '404',
                'message' => 'Pesanan tidak ditemukan',
                'data' => null,
            ], 404);
        }

        $statusLama = $pesanan->status;
        $statusBaru = $validated['status'];

        if ($statusLama === $statusBaru) {
            return response()->json([
                'status' => 'sukses',
                'code' => '200',
                'message' => 'Status pesanan tidak berubah',
                'data' => [
                    'pesanan_id' => (int) $pesanan->id,
                    'nomor_pesanan' => (string) $pesanan->nomor_pesanan,
                    'status_lama' => (string) $statusLama,
                    'status_baru' => (string) $statusBaru,
                ],
            ], 200);
        }

        // Matriks transisi sah sesuai PRD Bagian 15.2
        $allowedTransitions = [
            'menunggu_stok' => [
                'menunggu_pembayaran' => ['pengelola'],
                'dibatalkan' => ['pembeli', 'pengelola'],
            ],
            'menunggu_pembayaran' => [
                'menunggu_konfirmasi' => ['pembeli'],
                'dibatalkan' => ['pembeli', 'pengelola'],
            ],
            'menunggu_konfirmasi' => [
                'dibayar' => ['pengelola'],
                'dibatalkan' => ['pengelola'],
            ],
            'dibayar' => [
                'diproses' => ['pengelola'],
            ],
            'diproses' => [
                'dikirim' => ['pengelola'],
            ],
            'dikirim' => [
                'selesai' => ['pengelola', 'pembeli'],
            ],
        ];

        // 1. Validasi legalitas perpindahan status
        if (!isset($allowedTransitions[$statusLama][$statusBaru])) {
            return response()->json([
                'status' => 'gagal',
                'code' => '409',
                'message' => "Transisi status dari '{$statusLama}' ke '{$statusBaru}' tidak diizinkan",
                'data' => null,
            ], 409);
        }

        // 2. Validasi wewenang role untuk transisi tersebut
        $allowedRoles = $allowedTransitions[$statusLama][$statusBaru];
        if (!in_array($role, $allowedRoles, true)) {
            return response()->json([
                'status' => 'gagal',
                'code' => '403',
                'message' => "Role '{$role}' tidak memiliki wewenang untuk mengubah status ke '{$statusBaru}'",
                'data' => null,
            ], 403);
        }

        DB::transaction(function () use ($pesanan, $statusLama, $statusBaru, $role, $request) {
            // Jika pesanan dibatalkan, pulihkan stok yang sempat direservasi
            if ($statusBaru === 'dibatalkan') {
                foreach ($pesanan->detail as $detail) {
                    if ($detail->stok_dikurangi > 0 && $detail->produk_id) {
                        $prod = Produk::find($detail->produk_id);
                        if ($prod) {
                            $prod->increment('stok', $detail->stok_dikurangi);
                        }
                    }
                }
            }

            // Jika menunggu_stok berpindah ke menunggu_pembayaran, tandai item tidak menunggu stok lagi
            if ($statusLama === 'menunggu_stok' && $statusBaru === 'menunggu_pembayaran') {
                $pesanan->detail()->update(['menunggu_stok' => false]);
            }

            $pesanan->status = $statusBaru;
            $pesanan->save();

            RiwayatStatusPesanan::create([
                'pesanan_id' => $pesanan->id,
                'status_lama' => $statusLama,
                'status_baru' => $statusBaru,
                'aktor' => $role,
                'catatan' => $request->catatan ?: "Status diperbarui menjadi {$statusBaru} oleh {$role}",
            ]);
        });

        return response()->json([
            'status' => 'sukses',
            'code' => '200',
            'message' => 'Status pesanan berhasil diperbarui',
            'data' => [
                'pesanan_id' => (int) $pesanan->id,
                'nomor_pesanan' => (string) $pesanan->nomor_pesanan,
                'status_lama' => (string) $statusLama,
                'status_baru' => (string) $statusBaru,
            ],
        ], 200);
    }
}
