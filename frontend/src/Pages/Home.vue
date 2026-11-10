<script setup>
import { router, useForm, Link } from '@inertiajs/vue3';
import { computed, ref } from 'vue';
import brandLogo from '../../Foto/Logo ATK.png';

const props = defineProps({
    user: { type: Object, required: true },
    profileComplete: { type: Boolean, default: false },
    status: { type: String, default: '' },
    products: { type: Array, default: () => [] },
    cartItems: { type: Array, default: () => [] },
    categories: { type: Array, default: () => [] },
    search: { type: String, default: '' },
    category: { type: String, default: '' },
});

const searchForm = useForm({ q: props.search });
const logoutForm = useForm({});
const categoriesSection = ref(null);
const cartTotal = computed(() => props.cartItems.reduce((total, item) => total + item.price * item.quantity, 0));
const cartError = ref('');

function searchProducts() {
    router.get('/home', {
        q: searchForm.q || undefined,
        category: props.category || undefined,
    }, { preserveState: true, replace: true });
}

function selectCategory(category) {
    router.get('/home', {
        q: props.search || undefined,
        category: category || undefined,
    }, { preserveState: true, replace: true });
}

function logout() {
    logoutForm.post('/logout');
}

function scrollToCategories() {
    categoriesSection.value?.scrollIntoView({ behavior: 'smooth' });
}

function showAllProducts() {
    searchForm.q = '';
    router.get('/home');
}

function addToCart(product) {
    cartError.value = '';
    useForm({ jumlah: 1 }).post(`/cart/${product.id}`, {
        onError: (errors) => { cartError.value = Object.values(errors)[0] || 'Produk tidak dapat ditambahkan.'; },
    });
}

function updateCartItem(item, amount) {
    cartError.value = '';
    useForm({ jumlah: item.quantity + amount }).put(`/cart/${item.id}`, {
        onError: (errors) => { cartError.value = Object.values(errors)[0] || 'Keranjang tidak dapat diperbarui.'; },
    });
}

function removeCartItem(item) {
    useForm({}).delete(`/cart/${item.id}`);
}

function scrollToCart() {
    document.getElementById('store-cart')?.scrollIntoView({ behavior: 'smooth' });
}

function formatPrice(price) {
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        maximumFractionDigits: 0,
    }).format(price);
}
</script>

<template>
    <main class="store-page">
        <header class="store-top">
            <div class="top-brand">
                <img :src="brandLogo" alt="">
                <div><strong>ATK Mart Aoen</strong><span>Belanja Cerdas, Berkualitas!</span></div>
            </div>
            <div class="top-actions">
                <span class="account-name">{{ props.user.name }}</span>
                <button type="button" class="logout-button" :disabled="logoutForm.processing" @click="logout">
                    {{ logoutForm.processing ? 'Keluar...' : 'Keluar' }}
                </button>
            </div>
        </header>

        <div class="store-content">
            <form class="store-search" @submit.prevent="searchProducts">
                <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
                    <circle cx="10.8" cy="10.8" r="6.8" stroke="currentColor" stroke-width="2" />
                    <path d="m16 16 4.5 4.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
                </svg>
                <input v-model="searchForm.q" type="search" placeholder="Cari ATK di sini..." aria-label="Cari produk">
                <button type="submit">Cari</button>
            </form>

            <p v-if="props.status" class="store-status" role="status">{{ props.status }}</p>
            <p v-if="cartError" class="store-status" role="alert">{{ cartError }}</p>
            <section v-if="!props.profileComplete" class="profile-reminder">
                <div><strong>Lengkapi profil pengiriman</strong><p>Tambahkan nomor WhatsApp dan alamat untuk memudahkan pengiriman.</p></div>
                <Link href="/profile/setup">Lengkapi profil →</Link>
            </section>

            <section class="promo-banner">
                <div><span class="promo-label">ATK MART AOEN</span><h1>Semua kebutuhan ATK<br>ada di satu tempat!</h1><p>Temukan alat tulis untuk sekolah, kerja, dan aktivitas sehari-hari.</p></div>
                <img :src="brandLogo" alt="">
            </section>

            <section id="store-categories" ref="categoriesSection" class="category-section">
                <div class="section-heading"><h2>Kategori</h2><button type="button" :class="{ active: !props.category }" @click="selectCategory('')">Lihat Semua</button></div>
                <div class="category-list">
                    <button
                        v-for="category in props.categories"
                        :key="category"
                        type="button"
                        :class="{ active: props.category === category }"
                        @click="selectCategory(category)"
                    >{{ category }}</button>
                    <p v-if="props.categories.length === 0" class="empty-note">Kategori akan muncul setelah produk ditambahkan.</p>
                </div>
            </section>

            <section class="products-section">
                <div class="section-heading"><h2>{{ props.category || 'Produk Populer' }}</h2><span>{{ props.products.length }} produk</span></div>
                <div v-if="props.products.length" class="product-grid">
                    <article v-for="product in props.products" :key="product.id" class="product-card">
                        <div class="product-image">
                            <img v-if="product.image" :src="product.image" :alt="product.name" loading="lazy">
                            <img v-else :src="brandLogo" alt="" class="image-fallback">
                        </div>
                        <span class="product-category">{{ product.category }}</span>
                        <h3>{{ product.name }}</h3>
                        <p v-if="product.description" class="product-description">{{ product.description }}</p>
                        <strong class="product-price">{{ formatPrice(product.price) }}</strong>
                        <button class="add-cart-button" type="button" :disabled="!product.available" @click="addToCart(product)">
                            {{ product.available ? 'Tambah ke Keranjang' : 'Tidak tersedia' }}
                        </button>
                    </article>
                </div>
                <div v-else class="empty-products">
                    <span aria-hidden="true">▤</span>
                    <strong>{{ props.search || props.category ? 'Produk tidak ditemukan' : 'Katalog sedang disiapkan' }}</strong>
                    <p>{{ props.search || props.category ? 'Coba kata kunci atau kategori lain.' : 'Produk yang tersedia di backend akan muncul di sini.' }}</p>
                    <button v-if="props.search || props.category" type="button" @click="showAllProducts">Tampilkan semua produk</button>
                </div>
            </section>

            <section id="store-cart" class="cart-section">
                <div class="section-heading"><h2>Keranjang {{ props.user.name }}</h2><span>{{ props.cartItems.length }} produk</span></div>
                <article v-for="item in props.cartItems" :key="item.id" class="cart-item">
                    <div class="cart-item-info">
                        <strong>{{ item.name }}</strong>
                        <span>{{ formatPrice(item.price) }} / produk</span>
                    </div>
                    <div class="cart-item-actions">
                        <button type="button" :disabled="item.quantity <= 1" :aria-label="`Kurangi ${item.name}`" @click="updateCartItem(item, -1)">−</button>
                        <span>{{ item.quantity }}</span>
                        <button type="button" :disabled="item.quantity >= item.maxQuantity" :aria-label="`Tambah ${item.name}`" @click="updateCartItem(item, 1)">+</button>
                        <button class="remove-cart-button" type="button" @click="removeCartItem(item)">Hapus</button>
                    </div>
                </article>
                <p v-if="!props.cartItems.length" class="empty-note">Keranjang kamu masih kosong. Tambahkan produk yang kamu inginkan.</p>
                <div v-else class="cart-total"><span>Subtotal</span><strong>{{ formatPrice(cartTotal) }}</strong></div>
            </section>
        </div>

        <nav class="store-bottom" aria-label="Navigasi katalog">
            <Link href="/home" class="selected"><span aria-hidden="true">⌂</span>Beranda</Link>
            <button type="button" @click="scrollToCategories"><span aria-hidden="true">▦</span>Kategori</button>
            <button type="button" @click="scrollToCart"><span aria-hidden="true">🛒</span>Keranjang ({{ props.cartItems.length }})</button>
            <Link href="/profile/setup"><span aria-hidden="true">♙</span>Profil</Link>
        </nav>
    </main>
</template>

<style>
.store-page { min-height: 100vh; padding-bottom: 82px; background: #f4f7fd; }
.store-top { position: sticky; z-index: 3; top: 0; display: flex; min-height: 72px; align-items: center; justify-content: space-between; gap: 12px; padding: 10px max(20px, calc((100vw - 1100px) / 2)); color: #fff; background: #09256f; box-shadow: 0 4px 16px rgb(3 23 71 / 12%); }
.top-brand { display: flex; align-items: center; gap: 11px; }
.top-brand img { width: 43px; height: 43px; border-radius: 12px; padding: 3px; background: #dce8ff; object-fit: contain; }
.top-brand div { display: grid; gap: 3px; }
.top-brand strong { font-size: 15px; }
.top-brand span { color: #c8d6f5; font-size: 11px; }
.top-actions { display: flex; align-items: center; gap: 12px; }
.account-name { max-width: 180px; overflow: hidden; color: #e2eaff; font-size: 12px; text-overflow: ellipsis; white-space: nowrap; }
.logout-button { border: 1px solid rgb(255 255 255 / 28%); border-radius: 9px; padding: 8px 12px; color: #fff; background: rgb(255 255 255 / 10%); font-size: 11px; font-weight: 650; }
.logout-button:disabled { opacity: .7; }
.store-content { width: min(100% - 32px, 1080px); margin: 0 auto; }
.store-search { display: flex; min-height: 52px; align-items: center; gap: 11px; margin: 18px 0; border: 1px solid #e3eaf7; border-radius: 14px; padding: 5px 7px 5px 15px; background: #fff; box-shadow: 0 6px 20px rgb(24 47 94 / 5%); }
.store-search svg { width: 21px; height: 21px; flex: 0 0 auto; color: #5b6d8d; }
.store-search input { width: 100%; min-width: 0; border: 0; outline: 0; color: #263752; background: transparent; font-size: 13px; }
.store-search input::placeholder { color: #8490a6; }
.store-search button { min-width: 58px; min-height: 38px; border: 0; border-radius: 10px; color: #fff; background: #09256f; font-size: 11px; font-weight: 700; }
.store-status { border-radius: 10px; padding: 11px 13px; color: #164b32; background: #e8f7ed; font-size: 12px; }
.profile-reminder { display: flex; align-items: center; justify-content: space-between; gap: 14px; margin-bottom: 16px; border-radius: 13px; padding: 13px 15px; background: #e3ecff; }
.profile-reminder strong { color: #17336f; font-size: 12px; }
.profile-reminder p { margin: 4px 0 0; color: #68748a; font-size: 10px; }
.profile-reminder a { flex: 0 0 auto; color: #09256f; font-size: 11px; font-weight: 700; text-decoration: none; }
.promo-banner { display: flex; min-height: 190px; align-items: center; justify-content: space-between; gap: 20px; overflow: hidden; border-radius: 22px; padding: 25px 28px; background: linear-gradient(110deg, #dce8ff, #edf3ff); }
.promo-label { display: inline-block; border-radius: 99px; padding: 5px 9px; color: #fff; background: #ec7755; font-size: 9px; font-weight: 800; letter-spacing: .7px; }
.promo-banner h1 { margin: 10px 0 6px; color: #09256f; font-size: clamp(20px, 4vw, 27px); letter-spacing: -.5px; line-height: 1.2; }
.promo-banner p { max-width: 420px; margin: 0; color: #67748c; font-size: 12px; line-height: 1.55; }
.promo-banner > img { width: 125px; height: 125px; flex: 0 0 auto; object-fit: contain; }
.category-section, .products-section { margin-top: 25px; }
.section-heading { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 12px; }
.section-heading h2 { margin: 0; color: #202b3d; font-size: 17px; }
.section-heading > button, .section-heading > span { border: 0; padding: 6px 0 6px 8px; color: #6d7890; background: transparent; font-size: 11px; font-weight: 650; }
.section-heading > button.active { color: #09256f; }
.category-list { display: flex; flex-wrap: wrap; gap: 8px; }
.category-list button { min-height: 37px; border: 1px solid #e2e9f5; border-radius: 11px; padding: 0 14px; color: #53617b; background: #fff; font-size: 11px; font-weight: 650; }
.category-list button.active { border-color: #09256f; color: #fff; background: #09256f; }
.empty-note { margin: 5px 0; color: #77839a; font-size: 11px; }
.product-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 13px; }
.product-card { min-width: 0; overflow: hidden; border: 1px solid #e8edf7; border-radius: 15px; padding: 10px; background: #fff; box-shadow: 0 5px 16px rgb(22 47 103 / 4%); }
.product-image { display: grid; height: 150px; place-items: center; overflow: hidden; border-radius: 11px; background: #e4ecfc; }
.product-image img { width: 100%; height: 100%; object-fit: cover; }
.product-image img.image-fallback { width: 80px; height: 80px; object-fit: contain; }
.product-category { display: block; overflow: hidden; margin-top: 10px; color: #63779f; font-size: 9px; text-overflow: ellipsis; white-space: nowrap; }
.product-card h3 { display: -webkit-box; min-height: 36px; overflow: hidden; margin: 5px 0 0; color: #26334b; font-size: 12px; line-height: 1.45; -webkit-box-orient: vertical; -webkit-line-clamp: 2; }
.product-description { display: -webkit-box; min-height: 28px; overflow: hidden; margin: 5px 0 9px; color: #7b879b; font-size: 10px; line-height: 1.4; -webkit-box-orient: vertical; -webkit-line-clamp: 2; }
.product-price { display: block; margin-top: 11px; color: #09256f; font-size: 14px; }
.add-cart-button { width: 100%; min-height: 37px; margin-top: 11px; border: 0; border-radius: 9px; color: #fff; background: #09256f; font-size: 10px; font-weight: 700; }
.add-cart-button:disabled { background: #9aa5b8; }
.empty-products { display: grid; min-height: 210px; justify-items: center; align-content: center; border: 1px dashed #cbd6e9; border-radius: 17px; padding: 22px; color: #61708a; background: rgb(255 255 255 / 70%); text-align: center; }
.empty-products > span { color: #4265a7; font-size: 30px; }
.empty-products strong { margin-top: 8px; color: #2e3b52; font-size: 13px; }
.empty-products p { margin: 6px 0 0; font-size: 11px; }
.empty-products button { margin-top: 12px; border: 0; border-radius: 9px; padding: 9px 13px; color: #fff; background: #09256f; font-size: 11px; }
.cart-section { margin: 25px 0 32px; border: 1px solid #e8edf7; border-radius: 16px; padding: 16px; background: #fff; }
.cart-item { display: flex; align-items: center; justify-content: space-between; gap: 12px; border-top: 1px solid #edf0f6; padding: 13px 0; }
.cart-item-info { display: grid; gap: 5px; }
.cart-item-info strong { color: #26334b; font-size: 12px; }
.cart-item-info span { color: #748099; font-size: 10px; }
.cart-item-actions { display: flex; align-items: center; gap: 8px; color: #26334b; font-size: 11px; }
.cart-item-actions button { min-width: 29px; min-height: 29px; border: 1px solid #dfe7f7; border-radius: 8px; color: #09256f; background: #f5f8ff; }
.cart-item-actions button:disabled { color: #9aa5b8; }
.cart-item-actions .remove-cart-button { width: auto; padding: 0 9px; color: #a43838; background: #fff5f5; }
.cart-total { display: flex; justify-content: space-between; border-top: 1px solid #edf0f6; padding-top: 14px; color: #293650; font-size: 12px; }
.cart-total strong { color: #09256f; font-size: 14px; }
.store-bottom { position: fixed; z-index: 4; right: 0; bottom: 0; left: 0; display: grid; min-height: 64px; grid-template-columns: repeat(4, 1fr); border-top: 1px solid #e3e9f3; padding: 6px max(10px, calc((100vw - 750px) / 2)); background: #fff; box-shadow: 0 -7px 22px rgb(24 47 94 / 6%); }
.store-bottom a, .store-bottom button { display: grid; justify-items: center; gap: 2px; border: 0; color: #6a7892; background: transparent; font-size: 9px; text-decoration: none; }
.store-bottom a span, .store-bottom button span { font-size: 19px; line-height: 1; }
.store-bottom .selected { color: #09256f; font-weight: 750; }
.store-page button:focus-visible, .store-page a:focus-visible { outline: 3px solid #9db8f5; outline-offset: 2px; }
@media (max-width: 780px) {
    .product-grid { grid-template-columns: repeat(3, minmax(0, 1fr)); }
    .product-image { height: 130px; }
}
@media (max-width: 560px) {
    .store-top { min-height: 62px; padding-inline: 14px; }
    .top-brand img { width: 38px; height: 38px; }
    .top-brand strong { font-size: 13px; }
    .top-brand span { font-size: 9px; }
    .account-name { display: none; }
    .store-content { width: calc(100% - 24px); }
    .store-search { min-height: 48px; margin: 13px 0; }
    .promo-banner { min-height: 165px; border-radius: 18px; padding: 18px; }
    .promo-banner > img { width: 82px; height: 82px; }
    .promo-banner p { font-size: 10px; }
    .section-heading h2 { font-size: 15px; }
    .product-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 9px; }
    .product-card { padding: 8px; }
    .product-image { height: 145px; }
    .profile-reminder { align-items: flex-start; flex-direction: column; }
}
</style>
