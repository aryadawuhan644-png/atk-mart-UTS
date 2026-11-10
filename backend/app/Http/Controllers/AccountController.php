<?php

namespace App\Http\Controllers;

use App\Models\Keranjang;
use App\Models\Pelanggan;
use App\Models\Pesanan;
use App\Models\Produk;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;
use Inertia\Response;

class AccountController extends Controller
{
    public function onboarding(): Response|RedirectResponse
    {
        if (Auth::check()) {
            return redirect()->route($this->dashboardRoute(Auth::user()));
        }

        return Inertia::render('Onboarding');
    }

    public function showAuth(Request $request): Response|RedirectResponse
    {
        if (Auth::check()) {
            return redirect()->route($this->dashboardRoute(Auth::user()));
        }

        return Inertia::render('Auth', [
            'mode' => 'login',
            'accountType' => $this->validAccountType($request->query('account_type', old('account_type', 'buyer_1'))),
        ]);
    }

    public function login(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'username' => ['required', 'string', 'max:50'],
            'password' => ['required', 'string'],
            'remember' => ['boolean'],
            'account_type' => ['required', Rule::in(['buyer_1', 'buyer_2', 'admin'])],
        ]);

        $username = Str::lower(trim($data['username']));
        $key = Str::transliterate($username.'|'.$request->ip());

        if (RateLimiter::tooManyAttempts($key, 5)) {
            throw ValidationException::withMessages([
                'username' => 'Terlalu banyak percobaan masuk. Coba lagi dalam '.RateLimiter::availableIn($key).' detik.',
            ]);
        }

        if (! Auth::attempt([
            'username' => $username,
            'password' => $data['password'],
        ], $request->boolean('remember'))) {
            RateLimiter::hit($key);

            throw ValidationException::withMessages([
                'username' => 'Username atau kata sandi tidak sesuai.',
            ]);
        }

        if (Auth::user()->account_type !== $data['account_type']) {
            Auth::logout();
            RateLimiter::hit($key);

            throw ValidationException::withMessages([
                'username' => 'Akun tidak memiliki akses untuk pilihan tersebut.',
            ]);
        }

        RateLimiter::clear($key);
        $request->session()->regenerate();

        return $this->redirectForAccount($request->user());
    }

    public function register(Request $request): RedirectResponse
    {
        $request->merge([
            'username' => Str::lower(trim((string) $request->input('username'))),
        ]);
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'username' => ['required', 'alpha_dash', 'min:3', 'max:50', Rule::unique('users', 'username')],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'terms' => ['accepted'],
            'account_type' => ['required', Rule::in(['buyer_1', 'buyer_2'])],
        ]);

        $user = User::create([
            'name' => $data['name'],
            'username' => Str::lower($data['username']),
            'password' => $data['password'],
            'terms_accepted' => true,
            'account_type' => $data['account_type'],
        ]);
        $user->pelanggan()->create(['nama' => $user->name]);

        Auth::login($user);
        $request->session()->regenerate();

        return redirect()->route('profile.setup');
    }

    public function profileSetup(Request $request): Response
    {
        return Inertia::render('ProfileSetup', [
            'user' => $request->user()->only([
                'name',
                'email',
                'phone',
                'role',
                'birth_date',
                'address',
                'city',
            ]),
        ]);
    }

    public function updateProfile(Request $request): RedirectResponse
    {
        $request->merge([
            'phone' => preg_replace('/[^\d+]/', '', (string) $request->input('phone')),
        ]);

        $data = $request->validate([
            'phone' => [
                'required',
                'regex:/^\+?[0-9]{9,15}$/',
                Rule::unique('users', 'phone')->ignore($request->user()->id),
            ],
            'role' => ['required', Rule::in([
                'Siswa / Kuliah',
                'Kantor / Bisnis',
                'Guru / Dosen',
                'Pribadi / Umum',
            ])],
            'birth_date' => ['required', 'date', 'before_or_equal:today'],
            'address' => ['required', 'string', 'max:2000'],
            'city' => ['required', 'string', 'max:100'],
        ]);

        $request->user()->update($data);

        return redirect()->route('home')->with('status', 'Profil berhasil disimpan.');
    }

    public function home(Request $request): Response
    {
        $search = trim((string) $request->query('q', ''));
        $category = trim((string) $request->query('category', ''));
        $query = Produk::query()->where('tersedia', true);

        if ($category !== '') {
            $query->where('kategori', $category);
        }

        if ($search !== '') {
            $query->where(function ($products) use ($search): void {
                $products->where('nama', 'like', "%{$search}%")
                    ->orWhere('kategori', 'like', "%{$search}%");
            });
        }

        $products = $query->orderByDesc('id')
            ->limit(24)
            ->get()
            ->map(fn (Produk $product): array => [
                'id' => $product->id,
                'name' => $product->nama,
                'price' => $product->harga,
                'category' => $product->kategori,
                'description' => $product->deskripsi,
                'image' => $product->gambar ? url("/api/produk/{$product->id}/gambar") : null,
                'available' => $product->tersedia && ($product->pre_order || $product->stok > 0),
            ]);

        return Inertia::render('Home', [
            'user' => $request->user()->only([
                'name',
                'username',
                'email',
                'phone',
                'role',
                'birth_date',
                'address',
                'city',
            ]),
            'profileComplete' => $this->profileIsComplete($request->user()),
            'status' => $request->session()->get('status'),
            'products' => $products,
            'cartItems' => $this->cartItemsFor($request->user()),
            'search' => $search,
            'category' => $category,
            'categories' => Produk::query()
                ->where('tersedia', true)
                ->distinct()
                ->orderBy('kategori')
                ->pluck('kategori'),
        ]);
    }

    public function adminDashboard(): Response
    {
        return Inertia::render('AdminDashboard', [
            'stats' => [
                'products' => Produk::query()->count(),
                'availableProducts' => Produk::query()->where('tersedia', true)->count(),
                'customers' => User::query()->whereIn('account_type', ['buyer_1', 'buyer_2'])->count(),
                'orders' => Pesanan::query()->count(),
            ],
            'products' => Produk::query()
                ->orderByDesc('id')
                ->limit(100)
                ->get(['id', 'nama', 'kategori', 'harga', 'stok', 'tersedia']),
            'status' => session('status'),
        ]);
    }

    public function addCartItem(Request $request, Produk $product): RedirectResponse
    {
        $data = $request->validate(['jumlah' => ['nullable', 'integer', 'min:1', 'max:99']]);
        if (! $product->tersedia) {
            throw ValidationException::withMessages(['jumlah' => 'Produk sedang tidak tersedia.']);
        }

        $customer = $this->customerFor($request->user());
        $item = Keranjang::query()
            ->where('pelanggan_id', $customer->id)
            ->where('produk_id', $product->id)
            ->first();
        $quantity = ($item?->jumlah ?? 0) + ($data['jumlah'] ?? 1);

        if (! $product->pre_order && $quantity > $product->stok) {
            throw ValidationException::withMessages(['jumlah' => 'Jumlah melebihi stok yang tersedia.']);
        }

        if ($item) {
            $item->update(['jumlah' => $quantity]);
        } else {
            $customer->keranjang()->create([
                'produk_id' => $product->id,
                'jumlah' => $quantity,
            ]);
        }

        return back()->with('status', $product->nama.' ditambahkan ke keranjang.');
    }

    public function updateCartItem(Request $request, int $item): RedirectResponse
    {
        $data = $request->validate(['jumlah' => ['required', 'integer', 'min:1', 'max:99']]);
        $customer = $this->customerFor($request->user());
        $cartItem = Keranjang::query()
            ->where('pelanggan_id', $customer->id)
            ->with('produk')
            ->findOrFail($item);

        if (! $cartItem->produk->pre_order && $data['jumlah'] > $cartItem->produk->stok) {
            throw ValidationException::withMessages(['jumlah' => 'Jumlah melebihi stok yang tersedia.']);
        }

        $cartItem->update(['jumlah' => $data['jumlah']]);

        return back()->with('status', 'Jumlah produk di keranjang diperbarui.');
    }

    public function removeCartItem(Request $request, int $item): RedirectResponse
    {
        $customer = $this->customerFor($request->user());
        Keranjang::query()
            ->where('pelanggan_id', $customer->id)
            ->whereKey($item)
            ->firstOrFail()
            ->delete();

        return back()->with('status', 'Produk dihapus dari keranjang.');
    }

    public function storeProduct(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:255'],
            'harga' => ['required', 'integer', 'min:1'],
            'kategori' => ['required', 'string', 'max:100'],
            'stok' => ['required', 'integer', 'min:0'],
            'deskripsi' => ['nullable', 'string', 'max:2000'],
        ]);
        $data['tersedia'] = true;
        Produk::query()->create($data);

        return back()->with('status', 'Produk berhasil ditambahkan ke katalog.');
    }

    public function updateProduct(Request $request, Produk $product): RedirectResponse
    {
        $data = $request->validate([
            'nama' => ['sometimes', 'required', 'string', 'max:255'],
            'harga' => ['sometimes', 'required', 'integer', 'min:1'],
            'kategori' => ['sometimes', 'required', 'string', 'max:100'],
            'stok' => ['sometimes', 'required', 'integer', 'min:0'],
            'tersedia' => ['sometimes', 'required', 'boolean'],
            'deskripsi' => ['nullable', 'string', 'max:2000'],
        ]);
        $product->update($data);

        return back()->with('status', 'Produk berhasil diperbarui.');
    }

    public function deleteProduct(Produk $product): RedirectResponse
    {
        $product->update(['tersedia' => false]);

        return back()->with('status', 'Produk dinonaktifkan dari katalog.');
    }

    public function logout(Request $request): RedirectResponse
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('onboarding');
    }

    private function profileIsComplete(User $user): bool
    {
        return filled($user->phone)
            && filled($user->role)
            && filled($user->birth_date)
            && filled($user->address)
            && filled($user->city);
    }

    private function customerFor(User $user): Pelanggan
    {
        return $user->pelanggan()->firstOrCreate([], ['nama' => $user->name]);
    }

    private function cartItemsFor(User $user): array
    {
        $customer = $this->customerFor($user);

        return $customer->keranjang()
            ->with('produk')
            ->orderBy('id')
            ->get()
            ->map(fn (Keranjang $item): array => [
                'id' => $item->id,
                'productId' => $item->produk_id,
                'name' => $item->produk->nama,
                'price' => $item->produk->harga,
                'quantity' => $item->jumlah,
                'available' => $item->produk->tersedia,
                'maxQuantity' => $item->produk->pre_order ? 99 : $item->produk->stok,
            ])
            ->all();
    }

    private function redirectForAccount(User $user): RedirectResponse
    {
        if ($user->account_type === 'admin') {
            return redirect()->route('admin.dashboard');
        }

        return $this->profileIsComplete($user)
            ? redirect()->route('home')
            : redirect()->route('profile.setup');
    }

    private function dashboardRoute(?User $user): string
    {
        return $user?->account_type === 'admin' ? 'admin.dashboard' : 'home';
    }

    private function validAccountType(mixed $accountType): string
    {
        return in_array($accountType, ['buyer_1', 'buyer_2', 'admin'], true)
            ? $accountType
            : 'buyer_1';
    }

}
