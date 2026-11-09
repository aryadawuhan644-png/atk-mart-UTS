<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class PastikanJson
{
    /**
     * Pastikan header Accept dan Content-Type selalu application/json untuk API JSON.
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (!$request->is('api/produk/*/gambar')) {
            $request->headers->set('Accept', 'application/json');
        }

        $response = $next($request);

        // Jangan timpa Content-Type jika respons merupakan berkas biner/gambar
        $contentType = $response->headers->get('Content-Type', '');
        if (
            !$response instanceof \Symfony\Component\HttpFoundation\BinaryFileResponse &&
            !$response instanceof \Symfony\Component\HttpFoundation\StreamedResponse &&
            !str_starts_with($contentType, 'image/')
        ) {
            $response->headers->set('Content-Type', 'application/json');
        }

        return $response;
    }
}
