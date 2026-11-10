<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;

class GrantAdminAccess extends Command
{
    protected $signature = 'account:grant-admin {email : Email akun yang akan diberi akses admin}';

    protected $description = 'Memberikan akses admin ke akun yang sudah terdaftar';

    public function handle(): int
    {
        $user = User::query()
            ->where('email', strtolower($this->argument('email')))
            ->first();

        if ($user === null) {
            $this->error('Akun tidak ditemukan. Buat akun pembeli terlebih dahulu, lalu jalankan perintah ini lagi.');

            return self::FAILURE;
        }

        $user->forceFill(['account_type' => 'admin'])->save();

        $this->info("Akses admin diberikan ke {$user->email}.");

        return self::SUCCESS;
    }
}
