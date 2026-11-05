<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class PastikanRole
{
    /**
     * Membatasi akses rute berdasarkan role (pembeli/pengelola).
     *
     * @param  string  ...$roles
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $currentRole = $request->attributes->get('auth_role');

        if (!$currentRole) {
            return response()->json([
                'status' => 'gagal',
                'code' => '401',
                'message' => 'Token tidak valid atau tidak disertakan',
                'data' => null,
            ], 401);
        }

        if (!in_array($currentRole, $roles, true)) {
            // Pengelola diizinkan mengakses alur belanja pembeli bila diperlukan
            if ($currentRole === 'pengelola' && in_array('pembeli', $roles, true)) {
                return $next($request);
            }

            return response()->json([
                'status' => 'gagal',
                'code' => '403',
                'message' => 'Akses ditolak: Hanya pengelola yang dapat melakukan aksi ini',
                'data' => null,
            ], 403);
        }

        return $next($request);
    }
}
