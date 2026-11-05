<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Kurir;
use App\Models\TarifKurir;
use App\Models\WilayahAntar;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class KurirController extends Controller
{
    /**
     * Endpoint 10: GET /api/kurir
     * Mengembalikan pilihan kurir, wilayah, dan tarif internal.
     */
    public function index(Request $request): JsonResponse
    {
        $wilayahId = $request->query('wilayah_id');

        if ($wilayahId !== null) {
            $wilayah = WilayahAntar::where('id', $wilayahId)->where('aktif', true)->first();

            if (!$wilayah) {
                return response()->json([
                    'status' => 'gagal',
                    'code' => '404',
                    'message' => 'Wilayah tidak ditemukan atau tidak aktif',
                    'data' => null,
                ], 404);
            }

            $tarifList = TarifKurir::with('kurir')
                ->where('wilayah_id', $wilayahId)
                ->whereHas('kurir', fn($q) => $q->where('aktif', true))
                ->get();

            $data = [
                'wilayah' => [
                    'id' => (int) $wilayah->id,
                    'nama' => (string) $wilayah->nama,
                    'kota' => (string) $wilayah->kota,
                ],
                'kurir' => $tarifList->map(fn($t) => [
                    'kurir_id' => (int) $t->kurir->id,
                    'nama' => (string) $t->kurir->nama,
                    'deskripsi' => $t->kurir->deskripsi !== null ? (string) $t->kurir->deskripsi : null,
                    'tarif' => (int) $t->tarif,
                ])->values()->all(),
            ];

            return response()->json([
                'status' => 'sukses',
                'code' => '200',
                'message' => 'Pilihan kurir dan tarif berhasil diambil',
                'data' => $data,
            ], 200);
        }

        $kurirList = Kurir::where('aktif', true)->get();
        $wilayahList = WilayahAntar::where('aktif', true)->get();
        $tarifList = TarifKurir::with(['kurir', 'wilayah'])->get();

        $data = [
            'kurir' => $kurirList->map(fn($k) => [
                'id' => (int) $k->id,
                'nama' => (string) $k->nama,
                'deskripsi' => $k->deskripsi !== null ? (string) $k->deskripsi : null,
            ])->values()->all(),
            'wilayah' => $wilayahList->map(fn($w) => [
                'id' => (int) $w->id,
                'nama' => (string) $w->nama,
                'kota' => (string) $w->kota,
            ])->values()->all(),
            'tarif' => $tarifList->map(fn($t) => [
                'id' => (int) $t->id,
                'kurir_id' => (int) $t->kurir_id,
                'wilayah_id' => (int) $t->wilayah_id,
                'tarif' => (int) $t->tarif,
            ])->values()->all(),
        ];

        return response()->json([
            'status' => 'sukses',
            'code' => '200',
            'message' => 'Data kurir dan tarif pengiriman berhasil diambil',
            'data' => $data,
        ], 200);
    }
}
