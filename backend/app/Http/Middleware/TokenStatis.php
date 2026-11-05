<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class TokenStatis
{
    /**
     * Autentikasi token statis pembeli dan pengelola sesuai PRD.
     * Identitas ditentukan murni oleh server berdasarkan token yang sah,
     * menolak header manipulatif dari klien seperti X-Pelanggan-Id.
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Berikan izin preflight OPTIONS melewati middleware tanpa perlu token
        if ($request->isMethod('OPTIONS')) {
            return $next($request);
        }

        $authHeader = $request->header('Authorization');

        if (!$authHeader || !preg_match('/Bearer\s+(\S+)/', $authHeader, $matches)) {
            return response()->json([
                'status' => 'gagal',
                'code' => '401',
                'message' => 'Token tidak valid atau tidak disertakan',
                'data' => null,
            ], 401);
        }

        $token = $matches[1];
        $tokenPembeli = env('TOKEN_STATIS_PEMBELI', null);
        $tokenPembeli2 = env('TOKEN_STATIS_PEMBELI_2', null);
        $tokenPengelola = env('TOKEN_STATIS_PENGELOLA', null);

        if ($token === $tokenPembeli) {
            $role = 'pembeli';
            $pelangganId = 1;
        } elseif ($token === $tokenPembeli2) {
            $role = 'pembeli';
            $pelangganId = 2;
        } elseif ($token === $tokenPengelola) {
            $role = 'pengelola';
            $pelangganId = 1;
        } else {
            return response()->json([
                'status' => 'gagal',
                'code' => '401',
                'message' => 'Token tidak valid atau tidak disertakan',
                'data' => null,
            ], 401);
        }

        // Terapkan identitas ke request attributes (tidak dapat dimanipulasi oleh input query/body klien)
        $request->attributes->set('auth_role', $role);
        $request->attributes->set('pelanggan_id', $pelangganId);

        // Timpa input jika klien mencoba mengirim pelanggan_id atau auth_role
        $request->merge([
            'auth_role' => $role,
            'pelanggan_id' => $pelangganId,
        ]);

        return $next($request);
    }
}
