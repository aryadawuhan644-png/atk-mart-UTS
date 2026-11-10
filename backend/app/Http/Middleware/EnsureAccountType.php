<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAccountType
{
    public function handle(Request $request, Closure $next, string ...$accountTypes): Response
    {
        abort_unless(in_array($request->user()?->account_type, $accountTypes, true), 403);

        return $next($request);
    }
}
