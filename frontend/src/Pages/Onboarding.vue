<script setup>
import { onMounted, onUnmounted, ref } from 'vue';
import { router } from '@inertiajs/vue3';
import mascotHelper from '../../Foto/cute_3d_cartoon.png';
import mascotConvenient from '../../Foto/cute_happy.png';
import mascotShopping from '../../Foto/cute_friendly.png';
import brandLogo from '../../Foto/Logo ATK.png';

const steps = [
    {
        image: mascotHelper,
        imageAlt: 'Maskot lucu membawa pensil dan jurnal',
        eyebrow: 'KENALAN DULU',
        title: 'Kami Ada untuk Membantu Anda',
        description:
            'Temukan semua kebutuhan alat tulis untuk sekolah, kuliah, kantor, dan keseharianmu.',
    },
    {
        image: mascotConvenient,
        imageAlt: 'Maskot ceria memegang alat tulis',
        eyebrow: 'LEBIH PRAKTIS',
        title: 'Belanja Tanpa Harus ke Mana-mana',
        description:
            'Cari perlengkapan favoritmu dari rumah dan pesan dengan mudah, kapan pun dibutuhkan.',
    },
    {
        image: mascotShopping,
        imageAlt: 'Maskot ramah membawa hadiah dan perlengkapan sekolah',
        eyebrow: 'SIAP MULAI?',
        title: 'Kebutuhan ATK Jadi Lebih Mudah',
        description:
            'Belanja cepat, nyaman, dan temukan berbagai perlengkapan dalam satu tempat.',
    },
];

const stage = ref('splash');
const activeStep = ref(0);
let splashTimer;

function continueOnboarding() {
    if (activeStep.value < steps.length - 1) {
        activeStep.value += 1;
        return;
    }

    router.visit('/auth');
}

function skipOnboarding() {
    router.visit('/auth');
}

onMounted(() => {
    splashTimer = window.setTimeout(() => {
        stage.value = 'onboarding';
    }, 1400);
});

onUnmounted(() => {
    window.clearTimeout(splashTimer);
});
</script>

<template>
    <main class="welcome-page">
        <Transition name="fade" mode="out-in">
            <section v-if="stage === 'splash'" key="splash" class="splash-screen" aria-label="ATK Mart Aoen">
                <img class="brand-logo splash-logo" :src="brandLogo" alt="ATK Mart Aoen">
            </section>

            <section v-else key="onboarding" class="onboarding-screen">
                <header class="onboarding-header">
                    <div class="brand-mini">
                        <img :src="brandLogo" alt="">
                        <span>ATK MART AOEN</span>
                    </div>
                    <button class="text-button" type="button" @click="skipOnboarding">Lewati</button>
                </header>

                <article class="onboarding-card" :aria-label="`Halaman ${activeStep + 1} dari ${steps.length}`">
                    <div class="illustration">
                        <div class="illustration-orbit orbit-one" />
                        <div class="illustration-orbit orbit-two" />
                        <img :src="steps[activeStep].image" :alt="steps[activeStep].imageAlt">
                    </div>
                    <div class="onboarding-copy">
                        <p class="eyebrow">{{ steps[activeStep].eyebrow }}</p>
                        <h1>{{ steps[activeStep].title }}</h1>
                        <p class="description">{{ steps[activeStep].description }}</p>
                    </div>
                    <footer class="onboarding-footer">
                        <div class="step-dots" role="group" :aria-label="`Langkah ${activeStep + 1} dari ${steps.length}`">
                            <span
                                v-for="(_, index) in steps"
                                :key="index"
                                class="step-dot"
                                :class="{ current: activeStep === index }"
                            />
                        </div>
                        <button class="primary-button" type="button" @click="continueOnboarding">
                            {{ activeStep === steps.length - 1 ? 'Lanjut ke Akun' : 'Lanjut' }}
                            <span aria-hidden="true">→</span>
                        </button>
                    </footer>
                </article>
                <p class="onboarding-note">Belanja perlengkapan jadi lebih praktis bersama kami.</p>
            </section>
        </Transition>
    </main>
</template>

<style>
:root {
    color-scheme: light;
    font-family: 'Inter Variable', Inter, sans-serif;
    color: #17233c;
    background: #f3f6fc;
    font-synthesis: none;
    text-rendering: optimizeLegibility;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
}

* { box-sizing: border-box; }
body { min-width: 280px; min-height: 100vh; margin: 0; }
button, input, textarea { font: inherit; }
button { cursor: pointer; }

.welcome-page {
    display: grid;
    min-height: 100vh;
    place-items: center;
    padding: 0;
    background:
        radial-gradient(ellipse at 12% 14%, rgb(200 218 255 / 54%), transparent 34%),
        radial-gradient(ellipse at 88% 86%, rgb(218 229 250 / 75%), transparent 38%),
        #f4f7fd;
}

.splash-screen {
    position: fixed;
    inset: 0;
    display: grid;
    width: 100%;
    min-height: 100svh;
    place-items: center;
    background:
        radial-gradient(ellipse at 82% 10%, rgb(226 234 255 / 67%), transparent 36%),
        radial-gradient(ellipse at 84% 91%, rgb(222 230 246 / 76%), transparent 39%),
        #f8faff;
}

.brand-logo { display: block; object-fit: contain; }
.splash-logo { width: min(200px, 78vw); height: min(200px, 78vw); }

.onboarding-screen { display: flex; width: 100%; min-height: 100svh; flex-direction: column; align-items: center; }
.onboarding-header { display: flex; width: 100%; min-height: 60px; flex: 0 0 auto; align-items: center; justify-content: space-between; margin-bottom: 24px; padding: 0 16px; background: #edf2fb; }
.brand-mini { display: flex; align-items: center; gap: 14px; color: #011c6b; font-size: 17px; font-weight: 800; letter-spacing: 2px; }
.brand-mini img { width: 34px; height: 34px; object-fit: contain; }
.text-button { border: 0; padding: 9px 0 9px 12px; color: #71809b; background: transparent; font-size: 16px; }
.text-button:hover { color: #011c6b; }
.onboarding-screen > .onboarding-card { width: min(calc(100% - 30px), 570px); }
.onboarding-note { margin: 16px 0 24px; }
.onboarding-card { overflow: hidden; border: 1px solid #e8edf7; border-radius: 28px; background: #fff; box-shadow: 0 20px 60px rgb(22 47 103 / 9%); }
.illustration { position: relative; display: grid; height: clamp(270px, 42vh, 360px); place-items: center; overflow: hidden; background: linear-gradient(145deg, #e7efff, #f8faff 75%); }
.illustration img { position: relative; z-index: 1; width: min(75%, 300px); height: 96%; object-fit: contain; filter: drop-shadow(0 13px 15px rgb(24 53 110 / 12%)); }
.illustration-orbit { position: absolute; width: 270px; height: 270px; border: 1px solid rgb(1 28 107 / 10%); border-radius: 50%; }
.orbit-one { transform: scale(1.16); }
.orbit-two { transform: scale(.82); }
.onboarding-copy { padding: 25px 32px 12px; text-align: center; }
.eyebrow { margin: 0 0 9px; color: #3158a5; font-size: 10px; font-weight: 800; letter-spacing: 1.7px; }
.onboarding-copy h1 { max-width: 420px; margin: 0 auto; color: #112249; font-size: clamp(23px, 5vw, 29px); letter-spacing: -.8px; line-height: 1.2; }
.description { max-width: 430px; margin: 11px auto 0; color: #68748a; font-size: 14px; line-height: 1.6; }
.onboarding-footer { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 19px 28px 25px; }
.step-dots { display: flex; align-items: center; gap: 6px; }
.step-dot { width: 7px; height: 7px; border-radius: 99px; background: #cbd6eb; transition: width 180ms ease, background 180ms ease; }
.step-dot.current { width: 24px; background: #011c6b; }
.primary-button { display: inline-flex; min-height: 46px; align-items: center; justify-content: center; gap: 14px; border: 0; border-radius: 12px; padding: 0 22px; color: #fff; background: #011c6b; box-shadow: 0 7px 16px rgb(1 28 107 / 19%); font-size: 14px; font-weight: 700; transition: background 160ms ease, transform 160ms ease; }
.primary-button:hover { background: #123b9b; transform: translateY(-1px); }
.primary-button:focus-visible, .text-button:focus-visible { outline: 3px solid #9db8f5; outline-offset: 3px; }
.onboarding-note { color: #8490a6; font-size: 12px; text-align: center; }
.fade-enter-active, .fade-leave-active { transition: opacity 180ms ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
@media (max-width: 560px) {
    .welcome-page { min-height: 100svh; padding: 0; }
    .onboarding-screen { min-height: 100svh; }
    .onboarding-header { min-height: 60px; margin-bottom: 14px; }
    .brand-mini { gap: 10px; font-size: 13px; letter-spacing: 1.5px; }
    .brand-mini img { width: 29px; height: 29px; }
    .text-button { font-size: 14px; }
    .onboarding-card { display: flex; flex: 1; flex-direction: column; }
    .illustration { min-height: 245px; flex: 1 1 48%; }
    .illustration img { width: min(77%, 280px); }
    .onboarding-copy { padding: 22px 22px 8px; }
    .description { font-size: 13px; }
    .onboarding-footer { margin-top: auto; padding: 17px 20px 22px; }
}

@media (prefers-reduced-motion: reduce) {
    *, *::before, *::after { animation-duration: .01ms !important; transition-duration: .01ms !important; }
}
</style>
