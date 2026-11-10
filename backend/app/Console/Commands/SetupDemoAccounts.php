<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class SetupDemoAccounts extends Command
{
    protected $signature = 'account:setup-demo {--password= : Password to hash for the three demo accounts}';

    protected $description = 'Create the two buyer accounts and seller/admin demo account';

    public function handle(): int
    {
        $password = $this->option('password');
        if (! is_string($password) || strlen($password) < 8) {
            $this->error('Provide a password of at least 8 characters with --password.');

            return self::FAILURE;
        }

        $accounts = [
            ['username' => 'pembeli1', 'name' => 'Pembeli 1', 'account_type' => 'buyer_1'],
            ['username' => 'pembeli2', 'name' => 'Pembeli 2', 'account_type' => 'buyer_2'],
            ['username' => 'admin', 'name' => 'Admin / Penjual', 'account_type' => 'admin'],
        ];

        DB::transaction(function () use ($accounts, $password): void {
            foreach ($accounts as $account) {
                $user = User::query()->firstOrNew(['username' => $account['username']]);
                $user->fill([
                    'name' => $account['name'],
                    'account_type' => $account['account_type'],
                    'password' => $password,
                ]);

                if ($account['account_type'] !== 'admin') {
                    $user->fill([
                        'phone' => $account['username'] === 'pembeli1' ? '+620000000001' : '+620000000002',
                        'role' => 'Pribadi / Umum',
                        'birth_date' => '2000-01-01',
                        'address' => 'Alamat belum diatur',
                        'city' => 'Malang',
                    ]);
                }

                $user->save();
                if ($account['account_type'] !== 'admin') {
                    $user->pelanggan()->firstOrCreate([], ['nama' => $user->name]);
                }
            }
        });

        $this->info('Akun Pembeli 1, Pembeli 2, dan Admin/Penjual sudah siap.');

        return self::SUCCESS;
    }
}
