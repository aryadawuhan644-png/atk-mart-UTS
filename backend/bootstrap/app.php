<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->web(append: [
            \App\Http\Middleware\HandleInertiaRequests::class,
        ]);

        $middleware->alias([
            'auth.statis' => \App\Http\Middleware\TokenStatis::class,
            'account.type' => \App\Http\Middleware\EnsureAccountType::class,
            'role' => \App\Http\Middleware\PastikanRole::class,
        ]);

        $middleware->api(prepend: [
            \App\Http\Middleware\PastikanJson::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        $exceptions->render(function (\Illuminate\Validation\ValidationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'status' => 'gagal',
                    'code' => '422',
                    'message' => 'Data yang dikirim belum valid',
                    'errors' => $e->errors(),
                ], 422);
            }
        });

        $exceptions->render(function (\Illuminate\Database\Eloquent\ModelNotFoundException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'status' => 'gagal',
                    'code' => '404',
                    'message' => 'Data tidak ditemukan',
                    'data' => null,
                ], 404);
            }
        });

        $exceptions->render(function (\Symfony\Component\HttpKernel\Exception\NotFoundHttpException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'status' => 'gagal',
                    'code' => '404',
                    'message' => 'Resource tidak ditemukan',
                    'data' => null,
                ], 404);
            }
        });

        $exceptions->render(function (\Symfony\Component\HttpKernel\Exception\HttpException $e, Request $request) {
            if ($request->is('api/*')) {
                $status = $e->getStatusCode();
                return response()->json([
                    'status' => 'gagal',
                    'code' => (string) $status,
                    'message' => $e->getMessage() ?: 'Terjadi kesalahan pada request',
                    'data' => null,
                ], $status);
            }
        });

        $exceptions->render(function (\Throwable $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'status' => 'gagal',
                    'code' => '500',
                    'message' => 'Terjadi kesalahan pada server',
                    'data' => null,
                ], 500);
            }
        });
    })->create();
