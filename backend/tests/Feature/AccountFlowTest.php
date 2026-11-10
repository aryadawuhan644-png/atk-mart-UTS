<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Produk;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Artisan;
use Inertia\Testing\AssertableInertia as Assert;
use Tests\TestCase;

class AccountFlowTest extends TestCase
{
    use RefreshDatabase;

    public function test_onboarding_leads_to_separate_authentication_page(): void
    {
        $this->get('/')
            ->assertOk()
            ->assertInertia(fn (Assert $page) => $page->component('Onboarding', false));

        $this->get('/auth')
            ->assertOk()
            ->assertInertia(fn (Assert $page) => $page
                ->component('Auth', false)
                ->where('accountType', 'buyer_1'));
    }

    public function test_registration_stores_account_and_profile_in_database(): void
    {
        $this->post('/register', [
            'name' => 'Khatarina Lusia',
            'username' => 'khatarina',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'terms' => true,
            'account_type' => 'buyer_1',
        ])->assertRedirect('/profile/setup');

        $user = User::query()->where('username', 'khatarina')->firstOrFail();

        $this->assertAuthenticatedAs($user);
        $this->assertTrue(Hash::check('password123', $user->password));
        $this->assertTrue($user->terms_accepted);

        $this->actingAs($user)->post('/profile', [
            'phone' => '+62 812 3456 7890',
            'role' => 'Siswa / Kuliah',
            'birth_date' => '2006-11-20',
            'address' => 'Jalan Merdeka No. 1',
            'city' => 'Malang',
        ])->assertRedirect('/home');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'phone' => '+6281234567890',
            'role' => 'Siswa / Kuliah',
            'city' => 'Malang',
        ]);
    }

    public function test_customer_can_login_with_username_and_logout(): void
    {
        $user = User::factory()->create([
            'username' => 'buyer2',
            'email' => null,
            'phone' => '+6281234567890',
            'account_type' => 'buyer_2',
            'role' => 'Pribadi / Umum',
            'birth_date' => '2000-01-01',
            'address' => 'Jalan Melati No. 1',
            'city' => 'Malang',
        ]);

        $this->post('/login', [
            'username' => 'buyer2',
            'password' => 'password',
            'account_type' => 'buyer_2',
        ])->assertRedirect('/home');

        $this->assertAuthenticatedAs($user);

        $this->post('/logout')->assertRedirect('/');
        $this->assertGuest();
    }

    public function test_buyer_cannot_sign_in_through_the_admin_choice(): void
    {
        User::factory()->create([
            'username' => 'buyer',
            'account_type' => 'buyer_1',
        ]);

        $this->from('/auth')
            ->post('/login', [
                'username' => 'buyer',
                'password' => 'password',
                'account_type' => 'admin',
            ])
            ->assertRedirect('/auth')
            ->assertSessionHasErrors('username');

        $this->assertGuest();
    }

    public function test_both_buyer_types_open_the_backend_product_dashboard(): void
    {
        $user = User::factory()->create([
            'account_type' => 'buyer_2',
            'role' => 'Siswa / Kuliah',
            'phone' => '+6281234567890',
            'birth_date' => '2006-11-20',
            'address' => 'Jalan Merdeka No. 1',
            'city' => 'Malang',
        ]);
        $product = Produk::query()->create([
            'nama' => 'Buku Tulis',
            'harga' => 12000,
            'kategori' => 'Buku',
            'stok' => 10,
            'tersedia' => true,
            'gambar' => 'produk/buku-tulis.jpg',
        ]);

        $this->actingAs($user)
            ->get('/home')
            ->assertOk()
            ->assertInertia(fn (Assert $page) => $page
                ->component('Home', false)
                ->where('products.0.id', $product->id)
                ->where('products.0.name', 'Buku Tulis')
                ->where('products.0.image', url("/api/produk/{$product->id}/gambar")));
    }

    public function test_public_registration_cannot_create_an_admin(): void
    {
        $this->from('/auth')
            ->post('/register', [
                'name' => 'Public Admin',
                'username' => 'public-admin',
                'password' => 'password123',
                'password_confirmation' => 'password123',
                'terms' => true,
                'account_type' => 'admin',
            ])
            ->assertRedirect('/auth')
            ->assertSessionHasErrors('account_type');

        $this->assertDatabaseMissing('users', ['username' => 'public-admin']);
    }

    public function test_admin_command_grants_admin_dashboard_access(): void
    {
        $admin = User::factory()->create([
            'email' => 'admin@example.test',
            'account_type' => 'buyer_1',
        ]);

        Artisan::call('account:grant-admin', ['email' => $admin->email]);
        $this->assertSame('admin', $admin->fresh()->account_type);

        $this->actingAs($admin->fresh())
            ->get('/admin')
            ->assertOk()
            ->assertInertia(fn (Assert $page) => $page->component('AdminDashboard', false));

        $this->actingAs(User::factory()->create(['account_type' => 'buyer_1']))
            ->get('/admin')
            ->assertForbidden();
    }

    public function test_registration_uses_a_unique_username_and_password(): void
    {
        $this->post('/register', [
            'name' => 'Username Customer',
            'username' => 'username-customer',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'terms' => true,
            'account_type' => 'buyer_2',
        ])->assertRedirect('/profile/setup');

        $this->assertDatabaseHas('users', [
            'name' => 'Username Customer',
            'username' => 'username-customer',
        ]);
    }

    public function test_buyer_carts_are_private_to_each_logged_in_account(): void
    {
        $buyer1 = User::factory()->create(['username' => 'pembeli1', 'account_type' => 'buyer_1']);
        $buyer2 = User::factory()->create(['username' => 'pembeli2', 'account_type' => 'buyer_2']);
        $product = Produk::query()->create([
            'nama' => 'Pensil',
            'harga' => 3000,
            'kategori' => 'Alat Tulis',
            'stok' => 20,
            'tersedia' => true,
        ]);
        $buyer1Customer = $buyer1->pelanggan()->create(['nama' => 'Pembeli 1']);
        $buyer2Customer = $buyer2->pelanggan()->create(['nama' => 'Pembeli 2']);
        $buyer1Cart = $buyer1Customer->keranjang()->create(['produk_id' => $product->id, 'jumlah' => 2]);
        $buyer2Customer->keranjang()->create(['produk_id' => $product->id, 'jumlah' => 1]);

        $this->actingAs($buyer1)->get('/home')
            ->assertInertia(fn (Assert $page) => $page
                ->where('cartItems.0.quantity', 2)
                ->where('cartItems.0.id', $buyer1Cart->id));

        $this->actingAs($buyer1)->put('/cart/'.$buyer2Customer->keranjang()->first()->id, ['jumlah' => 9])
            ->assertNotFound();

        $this->actingAs($buyer2)->get('/home')
            ->assertInertia(fn (Assert $page) => $page
                ->where('cartItems.0.quantity', 1)
                ->where('cartItems.0.id', $buyer2Customer->keranjang()->first()->id));
    }

    public function test_admin_seller_can_create_update_and_deactivate_products(): void
    {
        $admin = User::factory()->create(['account_type' => 'admin']);
        $this->actingAs($admin)->post('/admin/products', [
            'nama' => 'Penghapus',
            'harga' => 2500,
            'kategori' => 'Alat Tulis',
            'stok' => 15,
        ])->assertRedirect();

        $product = Produk::query()->where('nama', 'Penghapus')->firstOrFail();
        $this->actingAs($admin)->put('/admin/products/'.$product->id, [
            'nama' => 'Penghapus Putih',
            'stok' => 12,
        ])->assertRedirect();
        $this->assertDatabaseHas('produk', ['id' => $product->id, 'nama' => 'Penghapus Putih', 'stok' => 12]);

        $this->actingAs($admin)->delete('/admin/products/'.$product->id)->assertRedirect();
        $this->assertDatabaseHas('produk', ['id' => $product->id, 'tersedia' => false]);
    }

    public function test_google_authentication_routes_are_not_available(): void
    {
        $this->get('/auth/google')->assertNotFound();
        $this->get('/auth/google/callback')->assertNotFound();
    }

    public function test_demo_accounts_are_created_with_hashed_shared_passwords_and_separate_customers(): void
    {
        $demoPassword = 'Fixture-Pass-123!';
        $this->artisan('account:setup-demo', ['--password' => $demoPassword])
            ->assertExitCode(0);

        foreach ([
            'pembeli1' => 'buyer_1',
            'pembeli2' => 'buyer_2',
            'admin' => 'admin',
        ] as $username => $accountType) {
            $user = User::query()->where('username', $username)->firstOrFail();
            $this->assertSame($accountType, $user->account_type);
            $this->assertTrue(Hash::check($demoPassword, $user->password));
            if ($accountType !== 'admin') {
                $this->assertNotNull($user->pelanggan);
            }
        }

        $this->assertNotSame(
            User::query()->where('username', 'pembeli1')->firstOrFail()->pelanggan->id,
            User::query()->where('username', 'pembeli2')->firstOrFail()->pelanggan->id
        );

        $this->post('/login', [
            'username' => 'pembeli1',
            'password' => $demoPassword,
            'account_type' => 'buyer_1',
        ])->assertRedirect('/home');

        $this->post('/logout')->assertRedirect('/');

        $this->post('/login', [
            'username' => 'pembeli2',
            'password' => $demoPassword,
            'account_type' => 'buyer_2',
        ])->assertRedirect('/home');

        $this->post('/logout')->assertRedirect('/');

        $this->post('/login', [
            'username' => 'admin',
            'password' => $demoPassword,
            'account_type' => 'admin',
        ])->assertRedirect('/admin');
    }
}
