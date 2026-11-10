<script setup>
import { ref } from 'vue';
import { useForm } from '@inertiajs/vue3';
import brandLogo from '../../Foto/Logo ATK.png';

const props = defineProps({
    accountType: { type: String, default: 'buyer_1' },
});

const selectedAccountType = ref(props.accountType);
const activeMode = ref('login');
const showPassword = ref(false);
const showPasswordConfirmation = ref(false);
const showTerms = ref(false);

const accountUsernames = { buyer_1: 'pembeli1', buyer_2: 'pembeli2', admin: 'admin' };
const loginForm = useForm({
    username: accountUsernames[props.accountType] || accountUsernames.buyer_1,
    password: '',
    remember: false,
    account_type: props.accountType,
});
const registerForm = useForm({
    name: '',
    username: '',
    password: '',
    password_confirmation: '',
    terms: false,
    account_type: props.accountType === 'admin' ? 'buyer_1' : props.accountType,
});

function chooseMode(mode) {
    activeMode.value = mode;
    loginForm.clearErrors();
    registerForm.clearErrors();
}

function chooseAccountType(accountType) {
    selectedAccountType.value = accountType;
    loginForm.account_type = accountType;
    loginForm.username = accountUsernames[accountType];

    if (accountType !== 'admin') {
        registerForm.account_type = accountType;
    } else {
        activeMode.value = 'login';
    }
}

function login() {
    loginForm.post('/login', {
        onFinish: () => loginForm.reset('password'),
    });
}

function register() {
    registerForm.post('/register', {
        onFinish: () => registerForm.reset('password', 'password_confirmation'),
    });
}
</script>

<template>
    <main class="auth-page">
        <section class="auth-shell">
            <div class="auth-card">
                <header class="auth-heading">
                    <div class="auth-heading-copy">
                        <p class="auth-title">{{ activeMode === 'register' ? 'Buat Akun Pembeli' : selectedAccountType === 'admin' ? 'Masuk sebagai Penjual' : 'Selamat Datang' }}</p>
                        <p class="auth-subtitle">
                            {{ activeMode === 'register'
                                ? 'Buat username dan kata sandi untuk mulai berbelanja.'
                                : selectedAccountType === 'admin'
                                    ? 'Kelola produk dan katalog ATK Mart Aoen.'
                                    : 'Masuk menggunakan username dan kata sandi.' }}
                        </p>
                    </div>
                    <span class="lock-badge" aria-hidden="true">
                        <svg viewBox="0 0 24 24" fill="none">
                            <rect x="4" y="10" width="16" height="11" rx="2" stroke="currentColor" stroke-width="1.8" />
                            <path d="M8 10V7a4 4 0 0 1 8 0v3" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" />
                            <circle cx="12" cy="15" r="1" fill="currentColor" />
                            <path d="M12 16v2" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" />
                        </svg>
                    </span>
                </header>

                <div class="account-type-options" role="group" aria-label="Pilih jenis akun">
                    <button
                        type="button"
                        :aria-pressed="selectedAccountType === 'buyer_1'"
                        :class="{ selected: selectedAccountType === 'buyer_1' }"
                        @click="chooseAccountType('buyer_1')"
                    >Pembeli 1</button>
                    <button
                        type="button"
                        :aria-pressed="selectedAccountType === 'buyer_2'"
                        :class="{ selected: selectedAccountType === 'buyer_2' }"
                        @click="chooseAccountType('buyer_2')"
                    >Pembeli 2</button>
                    <button
                        type="button"
                        :aria-pressed="selectedAccountType === 'admin'"
                        :class="{ selected: selectedAccountType === 'admin' }"
                        @click="chooseAccountType('admin')"
                    >Admin / Penjual</button>
                </div>

                <div v-if="selectedAccountType !== 'admin'" class="auth-tabs" role="tablist" aria-label="Pilih masuk atau daftar">
                    <button type="button" role="tab" :aria-selected="activeMode === 'login'" :class="{ selected: activeMode === 'login' }" @click="chooseMode('login')">Masuk</button>
                    <button type="button" role="tab" :aria-selected="activeMode === 'register'" :class="{ selected: activeMode === 'register' }" @click="chooseMode('register')">Daftar Akun</button>
                </div>
                <p v-else class="admin-signin-note">Akun penjual hanya dapat masuk dengan username dan kata sandi yang diberikan.</p>

                <form v-if="activeMode === 'login'" class="account-form" @submit.prevent="login">
                    <label class="field-label" for="login-username">Username</label>
                    <div class="input-wrap">
                        <span aria-hidden="true">♙</span>
                        <input
                            id="login-username"
                            v-model="loginForm.username"
                            type="text"
                            autocomplete="username"
                            placeholder="Masukkan username"
                            maxlength="50"
                            required
                        >
                    </div>
                    <p v-if="loginForm.errors.username" class="field-error">{{ loginForm.errors.username }}</p>

                    <label class="field-label" for="login-password">Kata Sandi</label>
                    <div class="input-wrap">
                        <span aria-hidden="true">⚿</span>
                        <input
                            id="login-password"
                            v-model="loginForm.password"
                            :type="showPassword ? 'text' : 'password'"
                            autocomplete="current-password"
                            placeholder="Masukkan kata sandi"
                            required
                        >
                        <button class="input-action" type="button" @click="showPassword = !showPassword">
                            {{ showPassword ? 'Sembunyikan' : 'Lihat' }}
                        </button>
                    </div>
                    <p v-if="loginForm.errors.password" class="field-error">{{ loginForm.errors.password }}</p>
                    <label class="check-label"><input v-model="loginForm.remember" type="checkbox"> Ingat saya</label>
                    <button class="submit-button" type="submit" :disabled="loginForm.processing">
                        {{ loginForm.processing ? 'Memeriksa...' : 'Masuk' }} <span aria-hidden="true">↪</span>
                    </button>
                    <button v-if="selectedAccountType !== 'admin'" class="switch-account" type="button" @click="chooseMode('register')">
                        Belum punya akun? <strong>Daftar Akun</strong>
                    </button>
                </form>

                <form v-else class="account-form register-form" @submit.prevent="register">
                    <label class="field-label" for="register-name">Nama Lengkap</label>
                    <div class="input-wrap">
                        <span aria-hidden="true">♙</span>
                        <input id="register-name" v-model="registerForm.name" type="text" autocomplete="name" maxlength="100" required>
                    </div>
                    <p v-if="registerForm.errors.name" class="field-error">{{ registerForm.errors.name }}</p>

                    <label class="field-label" for="register-username">Username</label>
                    <div class="input-wrap">
                        <span aria-hidden="true">@</span>
                        <input id="register-username" v-model="registerForm.username" type="text" autocomplete="username" minlength="3" maxlength="50" required>
                    </div>
                    <p v-if="registerForm.errors.username" class="field-error">{{ registerForm.errors.username }}</p>

                    <label class="field-label" for="register-password">Kata Sandi</label>
                    <div class="input-wrap">
                        <span aria-hidden="true">⚿</span>
                        <input
                            id="register-password"
                            v-model="registerForm.password"
                            :type="showPassword ? 'text' : 'password'"
                            autocomplete="new-password"
                            minlength="8"
                            required
                        >
                        <button class="input-action" type="button" @click="showPassword = !showPassword">
                            {{ showPassword ? 'Sembunyikan' : 'Lihat' }}
                        </button>
                    </div>
                    <p v-if="registerForm.errors.password" class="field-error">{{ registerForm.errors.password }}</p>

                    <label class="field-label" for="register-confirm">Konfirmasi Kata Sandi</label>
                    <div class="input-wrap">
                        <span aria-hidden="true">⟳</span>
                        <input
                            id="register-confirm"
                            v-model="registerForm.password_confirmation"
                            :type="showPasswordConfirmation ? 'text' : 'password'"
                            autocomplete="new-password"
                            required
                        >
                        <button class="input-action" type="button" @click="showPasswordConfirmation = !showPasswordConfirmation">
                            {{ showPasswordConfirmation ? 'Sembunyikan' : 'Lihat' }}
                        </button>
                    </div>

                    <label class="terms-check">
                        <input v-model="registerForm.terms" type="checkbox" required>
                        <span>Saya menyetujui
                            <button class="inline-link" type="button" @click.prevent="showTerms = true">Syarat & Ketentuan</button>
                            serta
                            <button class="inline-link" type="button" @click.prevent="showTerms = true">Kebijakan Privasi</button>
                            ATK Mart Aoen.
                        </span>
                    </label>
                    <p v-if="registerForm.errors.terms" class="field-error">{{ registerForm.errors.terms }}</p>

                    <button class="submit-button" type="submit" :disabled="registerForm.processing">
                        {{ registerForm.processing ? 'Membuat akun...' : 'Daftar Sekarang' }} <span aria-hidden="true">→</span>
                    </button>
                    <button class="switch-account" type="button" @click="chooseMode('login')">
                        Sudah punya akun? <strong>Masuk di sini</strong>
                    </button>
                </form>
            </div>

            <footer class="auth-branding">
                <img :src="brandLogo" alt="Logo ATK Mart Aoen">
                <h1>ATK Mart Aoen</h1>
                <p>Belanja Cerdas, Berkualitas!</p>
                <span class="trust-pill">✦ &nbsp;Katalog Alat Tulis & Perlengkapan Kantor</span>
            </footer>
        </section>

        <div v-if="showTerms" class="terms-overlay" role="dialog" aria-modal="true" aria-labelledby="terms-title">
            <section class="terms-dialog">
                <button class="terms-close" type="button" aria-label="Tutup" @click="showTerms = false">×</button>
                <h2 id="terms-title">Syarat & Privasi</h2>
                <p>Gunakan akun ATK Mart Aoen dengan bertanggung jawab. Informasi akun dan keranjang belanja hanya digunakan untuk kebutuhan layanan toko.</p>
                <button class="submit-button" type="button" @click="showTerms = false">Saya Mengerti</button>
            </section>
        </div>
    </main>
</template>

<style>
.auth-page { min-height: 100vh; display: grid; place-items: center; padding: 24px 16px; background: #f3f6fc; font-family: inherit; }
.auth-shell { display: grid; width: min(100%, 430px); gap: 20px; margin: 0 auto; }
.auth-card { padding: 22px; border: 1px solid #e8edf7; border-radius: 21px; background: #fff; box-shadow: 0 12px 35px rgb(22 47 103 / 5%); }
.auth-heading { display: flex; align-items: flex-start; justify-content: space-between; gap: 15px; margin-bottom: 17px; }
.auth-title { margin: 0; color: #202734; font-size: 17px; font-weight: 750; }
.auth-subtitle { margin: 4px 0 0; color: #6d7890; font-size: 12px; line-height: 1.45; }
.lock-badge { display: grid; width: 40px; height: 40px; flex: 0 0 auto; place-items: center; border-radius: 13px; color: #011c6b; background: #e2ebff; }
.lock-badge svg { width: 19px; height: 19px; }
.account-type-options { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 5px; margin-bottom: 12px; padding: 4px; border-radius: 12px; background: #dce7ff; }
.account-type-options button { min-height: 36px; border: 0; border-radius: 9px; color: #53617b; background: transparent; font-size: 11px; font-weight: 650; }
.account-type-options button.selected { color: #011c6b; background: #fff; box-shadow: 0 2px 6px rgb(18 40 87 / 7%); }
.admin-signin-note { margin: 0 0 4px; color: #65728b; font-size: 11px; line-height: 1.5; }
.auth-tabs { display: grid; grid-template-columns: 1fr 1fr; gap: 4px; padding: 4px; border-radius: 12px; background: #dce7ff; }
.auth-tabs button { min-height: 37px; border: 0; border-radius: 9px; color: #53617b; background: transparent; font-size: 13px; font-weight: 600; }
.auth-tabs button.selected { color: #011c6b; background: #fff; box-shadow: 0 2px 6px rgb(18 40 87 / 7%); }
.account-form { display: flex; flex-direction: column; padding-top: 17px; }
.field-label { margin: 0 0 6px; color: #323b4d; font-size: 11px; font-weight: 700; }
.input-wrap { display: flex; min-height: 46px; align-items: center; gap: 10px; margin-bottom: 14px; padding: 0 12px; border: 1px solid #dfe7f7; border-radius: 11px; color: #596b8d; background: #e1eaff; }
.input-wrap:focus-within { border-color: #668bd7; box-shadow: 0 0 0 3px rgb(70 115 205 / 12%); }
.input-wrap > span { flex: 0 0 auto; font-size: 16px; }
.input-wrap input { width: 100%; min-width: 0; border: 0; outline: 0; color: #25334e; background: transparent; font-size: 13px; }
.input-action { flex: 0 0 auto; border: 0; padding: 5px 0 5px 3px; color: #526687; background: transparent; font-size: 10px; }
.check-label, .terms-check { display: flex; align-items: flex-start; gap: 7px; color: #64708a; font-size: 11px; line-height: 1.5; }
.check-label { margin: 0 0 14px; }
.check-label input, .terms-check input { accent-color: #011c6b; }
.inline-link { border: 0; padding: 0; color: #082b7f; background: transparent; font-size: inherit; font-weight: 700; text-decoration: underline; text-underline-offset: 2px; }
.submit-button { display: flex; width: 100%; min-height: 48px; align-items: center; justify-content: center; gap: 9px; border: 0; border-radius: 10px; color: #fff; background: #09256f; box-shadow: 0 5px 11px rgb(1 28 107 / 14%); font-size: 13px; font-weight: 700; }
.submit-button:hover:not(:disabled) { background: #143b96; }
.submit-button:disabled { cursor: wait; opacity: .7; }
.switch-account { min-height: 39px; margin-top: 14px; border: 0; border-radius: 11px; color: #69758b; background: #e2ebff; font-size: 11px; }
.switch-account strong { margin-left: 4px; color: #09256f; }
.register-form { padding-top: 15px; }
.register-form .input-wrap { min-height: 43px; margin-bottom: 10px; }
.terms-check { margin: 2px 0 12px; }
.terms-check input { margin: 2px 0 0; }
.field-error { margin: -10px 0 12px; color: #b42318; font-size: 11px; line-height: 1.4; }
.auth-branding { display: flex; flex-direction: column; align-items: center; text-align: center; }
.auth-branding img { width: 87px; height: 78px; object-fit: contain; }
.auth-branding h1 { margin: 2px 0 0; color: #09256f; font-size: 21px; letter-spacing: -.5px; }
.auth-branding p { margin: 4px 0 10px; color: #6b7891; font-size: 13px; }
.trust-pill { border-radius: 99px; padding: 7px 12px; color: #153775; background: #e2ebff; font-size: 10px; font-weight: 700; }
.terms-overlay { position: fixed; z-index: 10; inset: 0; display: grid; place-items: center; padding: 18px; background: rgb(10 24 53 / 48%); }
.terms-dialog { position: relative; width: min(100%, 390px); border-radius: 18px; padding: 26px; background: #fff; box-shadow: 0 20px 70px rgb(0 0 0 / 19%); }
.terms-dialog h2 { margin: 0 28px 12px 0; color: #09256f; font-size: 20px; }
.terms-dialog p { color: #606d84; font-size: 13px; line-height: 1.6; }
.terms-dialog .submit-button { margin-top: 18px; }
.terms-close { position: absolute; top: 12px; right: 14px; border: 0; color: #53617b; background: transparent; font-size: 24px; }
.auth-page button:focus-visible { outline: 3px solid #9db8f5; outline-offset: 2px; }
@media (max-width: 380px) { .auth-page { padding: 16px 12px; } .auth-card { padding: 18px 16px; } .auth-title { font-size: 16px; } }
</style>
