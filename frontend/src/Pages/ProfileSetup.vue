<script setup>
import { useForm } from '@inertiajs/vue3';
import brandLogo from '../../Foto/Logo ATK.png';

const props = defineProps({
    user: { type: Object, required: true },
});

const roles = [
    { label: 'Siswa / Kuliah', detail: 'Tugas & Catatan', icon: '🎒' },
    { label: 'Kantor / Bisnis', detail: 'Pengadaan ATK', icon: '💼' },
    { label: 'Guru / Dosen', detail: 'Alat Mengajar', icon: '📚' },
    { label: 'Pribadi / Umum', detail: 'Hobi & Rumah', icon: '🏠' },
];

const form = useForm({
    phone: props.user.phone ?? '',
    role: props.user.role ?? '',
    birth_date: props.user.birth_date?.slice(0, 10) ?? '',
    address: props.user.address ?? '',
    city: props.user.city ?? '',
});
const logoutForm = useForm({});

function saveProfile() {
    form.post('/profile');
}

function logout() {
    logoutForm.post('/logout');
}
</script>

<template>
    <main class="profile-page">
        <header class="profile-topbar">
            <div class="profile-brand"><img :src="brandLogo" alt=""><span>ATK MART AOEN</span></div>
            <button type="button" class="logout-small" @click="logout">Keluar</button>
        </header>

        <section class="profile-container">
            <header class="profile-intro">
                <p class="profile-step">LANGKAH 2 DARI 2 <span>90% Selesai</span></p>
                <h1>Informasi Akun & Pengiriman</h1>
                <div class="progress-track"><span /></div>
            </header>

            <div class="profile-reminder">
                <span class="reminder-icon">✦</span>
                <p><strong>Bonus Member Baru Menanti!</strong><br>Lengkapi profil untuk memudahkan pesanan dan pengiriman ATK Mart.</p>
            </div>

            <form class="profile-form" @submit.prevent="saveProfile">
                <div class="avatar-placeholder" aria-hidden="true">
                    <svg viewBox="0 0 24 24" fill="none">
                        <circle cx="12" cy="8" r="4" stroke="currentColor" stroke-width="1.7" />
                        <path d="M4.5 20a7.5 7.5 0 0 1 15 0" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" />
                    </svg>
                </div>
                <p class="profile-name">{{ props.user.name }}</p>
                <p class="profile-email">{{ props.user.email || 'Profil pelanggan ATK Mart Aoen' }}</p>

                <label for="profile-phone">Nomor WhatsApp Aktif <span>*</span></label>
                <input id="profile-phone" v-model="form.phone" type="tel" autocomplete="tel" placeholder="081234567890" required>
                <p v-if="form.errors.phone" class="profile-error">{{ form.errors.phone }}</p>
                <small>Gunakan nomor yang dapat dihubungi untuk konfirmasi pesanan.</small>

                <label>Peran / Kebutuhan Utama Belanja <span>*</span></label>
                <div class="role-grid">
                    <button
                        v-for="role in roles"
                        :key="role.label"
                        type="button"
                        class="role-option"
                        :class="{ active: form.role === role.label }"
                        :aria-pressed="form.role === role.label"
                        @click="form.role = role.label"
                    >
                        <span>{{ role.icon }}</span>
                        <span><strong>{{ role.label }}</strong><small>{{ role.detail }}</small></span>
                    </button>
                </div>
                <p v-if="form.errors.role" class="profile-error">{{ form.errors.role }}</p>

                <label for="profile-birth">Tanggal Lahir <span>*</span></label>
                <input id="profile-birth" v-model="form.birth_date" type="date" autocomplete="bday" required>
                <p v-if="form.errors.birth_date" class="profile-error">{{ form.errors.birth_date }}</p>
                <small>Kami siapkan kejutan khusus di bulan kelahiranmu.</small>

                <label for="profile-address">Alamat Utama Pengiriman <span>*</span></label>
                <textarea id="profile-address" v-model="form.address" rows="3" autocomplete="street-address" placeholder="Nama jalan, nomor rumah, kelurahan, kecamatan" required />
                <p v-if="form.errors.address" class="profile-error">{{ form.errors.address }}</p>

                <label for="profile-city">Kota / Kabupaten <span>*</span></label>
                <input id="profile-city" v-model="form.city" type="text" autocomplete="address-level2" placeholder="cth. Kota Malang" maxlength="100" required>
                <p v-if="form.errors.city" class="profile-error">{{ form.errors.city }}</p>

                <button class="profile-submit" type="submit" :disabled="form.processing">
                    {{ form.processing ? 'Menyimpan...' : 'Simpan & Lanjutkan Belanja' }} <span aria-hidden="true">→</span>
                </button>
            </form>

            <a class="skip-profile" href="/home">Lewati untuk sekarang</a>
        </section>
    </main>
</template>

<style>
.profile-page { min-height: 100vh; padding: 0 16px 30px; background: #f3f6fc; }
.profile-topbar { display: flex; width: min(100%, 560px); height: 54px; align-items: center; justify-content: space-between; margin: 0 auto; }
.profile-brand { display: flex; align-items: center; gap: 7px; color: #23375f; font-size: 10px; font-weight: 800; letter-spacing: .8px; }
.profile-brand img { width: 31px; height: 31px; object-fit: contain; }
.logout-small { border: 0; border-radius: 9px; padding: 8px 12px; color: #17336f; background: #e2ebff; font-size: 11px; font-weight: 700; }
.profile-container { width: min(100%, 500px); margin: 0 auto; }
.profile-intro { border-radius: 18px; padding: 17px 18px 15px; background: #fff; box-shadow: 0 5px 16px rgb(25 48 94 / 4%); }
.profile-step { display: flex; justify-content: space-between; margin: 0; color: #465777; font-size: 9px; font-weight: 800; letter-spacing: .6px; }
.profile-step span { color: #09256f; }
.profile-intro h1 { margin: 6px 0 11px; color: #09256f; font-size: 16px; }
.progress-track { height: 5px; overflow: hidden; border-radius: 10px; background: #dce5f8; }
.progress-track span { display: block; width: 90%; height: 100%; border-radius: inherit; background: #09256f; }
.profile-reminder { display: flex; align-items: center; gap: 10px; margin: 12px 0; border-radius: 14px; padding: 12px; color: #374c73; background: #e2ebff; }
.reminder-icon { display: grid; width: 32px; height: 32px; flex: 0 0 auto; place-items: center; border-radius: 9px; color: #09256f; background: #fff; }
.profile-reminder p { margin: 0; font-size: 10px; line-height: 1.45; }
.profile-reminder strong { color: #09256f; font-size: 11px; }
.profile-form { display: flex; flex-direction: column; border-radius: 19px; padding: 18px; background: #fff; box-shadow: 0 5px 16px rgb(25 48 94 / 4%); }
.avatar-placeholder { display: grid; width: 64px; height: 64px; place-items: center; align-self: center; border-radius: 50%; color: #526687; background: #e2ebff; }
.avatar-placeholder svg { width: 36px; height: 36px; }
.profile-name { margin: 8px 0 2px; color: #30394a; font-size: 12px; font-weight: 700; text-align: center; }
.profile-email { margin: 0 0 14px; color: #7a8598; font-size: 10px; text-align: center; }
.profile-form label { margin: 11px 0 5px; color: #34425e; font-size: 10px; font-weight: 750; }
.profile-form label span { color: #d92d20; }
.profile-form > input, .profile-form textarea { width: 100%; min-height: 42px; border: 1px solid #dfe7f7; border-radius: 10px; padding: 10px 12px; outline: 0; color: #34425e; background: #e2ebff; font-size: 12px; }
.profile-form textarea { resize: vertical; }
.profile-form > input:focus, .profile-form textarea:focus { border-color: #668bd7; box-shadow: 0 0 0 3px rgb(70 115 205 / 12%); }
.profile-form small { margin-top: 5px; color: #77839a; font-size: 9px; line-height: 1.4; }
.role-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 7px; }
.role-option { display: flex; min-height: 48px; align-items: center; gap: 7px; border: 1px solid #dfe7f7; border-radius: 10px; padding: 7px; color: #384967; background: #e2ebff; text-align: left; }
.role-option.active { border-color: #09256f; color: #fff; background: #09256f; }
.role-option > span:first-child { font-size: 15px; }
.role-option strong, .role-option small { display: block; }
.role-option strong { font-size: 9px; }
.role-option small { margin-top: 2px; font-size: 8px; opacity: .8; }
.profile-error { margin: 5px 0 0; color: #b42318; font-size: 10px; }
.profile-submit { display: flex; min-height: 46px; align-items: center; justify-content: center; gap: 8px; margin-top: 16px; border: 0; border-radius: 10px; color: #fff; background: #09256f; box-shadow: 0 6px 12px rgb(1 28 107 / 18%); font-size: 12px; font-weight: 700; }
.profile-submit:hover:not(:disabled) { background: #143b96; }
.profile-submit:disabled { cursor: wait; opacity: .7; }
.skip-profile { display: block; margin: 13px 0 0; color: #68748a; font-size: 10px; text-align: center; text-decoration: none; }
.skip-profile:hover { color: #09256f; text-decoration: underline; }
.profile-page button:focus-visible, .skip-profile:focus-visible { outline: 3px solid #9db8f5; outline-offset: 3px; }
</style>
