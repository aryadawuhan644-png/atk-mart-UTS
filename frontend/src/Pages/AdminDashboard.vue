<script setup>
import { ref } from 'vue';
import { useForm } from '@inertiajs/vue3';
import brandLogo from '../../Foto/Logo ATK.png';

const props = defineProps({
    stats: { type: Object, required: true },
    products: { type: Array, default: () => [] },
    status: { type: String, default: '' },
});

const logoutForm = useForm({});
const productForm = useForm({ nama: '', harga: '', kategori: '', stok: 0, deskripsi: '' });
const editingProductId = ref(null);
const editForm = useForm({ nama: '', harga: '', kategori: '', stok: 0, tersedia: true });

function logout() {
    logoutForm.post('/logout');
}

function createProduct() {
    productForm.post('/admin/products', { onSuccess: () => productForm.reset() });
}

function startEditing(product) {
    editingProductId.value = product.id;
    editForm.defaults({
        nama: product.nama,
        harga: product.harga,
        kategori: product.kategori,
        stok: product.stok,
        tersedia: product.tersedia,
    });
    editForm.reset();
}

function saveProduct(product) {
    editForm.put(`/admin/products/${product.id}`, {
        onSuccess: () => { editingProductId.value = null; },
    });
}

function disableProduct(product) {
    useForm({}).delete(`/admin/products/${product.id}`);
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
    <main class="admin-page">
        <header class="admin-header">
            <div class="admin-brand"><img :src="brandLogo" alt=""><span>ATK MART AOEN <small>PENJUAL</small></span></div>
            <div class="admin-actions">
                <button type="button" :disabled="logoutForm.processing" @click="logout">
                    {{ logoutForm.processing ? 'Keluar...' : 'Keluar' }}
                </button>
            </div>
        </header>

        <section class="admin-content">
            <p class="admin-kicker">DASHBOARD PENJUAL</p>
            <h1>Kelola Toko</h1>
            <p class="admin-description">Atur katalog produk dan pantau aktivitas ATK Mart Aoen.</p>

            <p v-if="props.status" class="admin-status" role="status">{{ props.status }}</p>

            <div class="admin-stats">
                <article><span>Total Produk</span><strong>{{ props.stats.products }}</strong></article>
                <article><span>Produk Tersedia</span><strong>{{ props.stats.availableProducts }}</strong></article>
                <article><span>Akun Pembeli</span><strong>{{ props.stats.customers }}</strong></article>
                <article><span>Total Pesanan</span><strong>{{ props.stats.orders }}</strong></article>
            </div>

            <section class="admin-products admin-create">
                <header><h2>Tambah Produk</h2></header>
                <form class="product-form" @submit.prevent="createProduct">
                    <label>Nama<input v-model="productForm.nama" required maxlength="255"></label>
                    <label>Kategori<input v-model="productForm.kategori" required maxlength="100"></label>
                    <label>Harga (Rp)<input v-model="productForm.harga" type="number" min="1" required></label>
                    <label>Stok<input v-model="productForm.stok" type="number" min="0" required></label>
                    <label class="product-description-field">Deskripsi<input v-model="productForm.deskripsi" maxlength="2000"></label>
                    <button type="submit" :disabled="productForm.processing">{{ productForm.processing ? 'Menyimpan...' : 'Tambah ke Katalog' }}</button>
                </form>
                <p v-if="productForm.errors.nama || productForm.errors.harga || productForm.errors.kategori || productForm.errors.stok" class="admin-error">
                    {{ productForm.errors.nama || productForm.errors.harga || productForm.errors.kategori || productForm.errors.stok }}
                </p>
            </section>

            <section class="admin-products">
                <header><h2>Kelola Produk</h2><span>{{ props.products.length }} produk</span></header>
                <div v-if="props.products.length" class="admin-table-wrap">
                    <table>
                        <thead><tr><th>Nama</th><th>Kategori</th><th>Harga</th><th>Stok</th><th>Status</th><th>Aksi</th></tr></thead>
                        <tbody>
                            <tr v-for="product in props.products" :key="product.id">
                                <template v-if="editingProductId === product.id">
                                    <td><input v-model="editForm.nama" aria-label="Nama produk"></td>
                                    <td><input v-model="editForm.kategori" aria-label="Kategori produk"></td>
                                    <td><input v-model="editForm.harga" type="number" min="1" aria-label="Harga produk"></td>
                                    <td><input v-model="editForm.stok" type="number" min="0" aria-label="Stok produk"></td>
                                    <td><label class="availability-check"><input v-model="editForm.tersedia" type="checkbox"> Tersedia</label></td>
                                    <td class="admin-row-actions">
                                        <button type="button" :disabled="editForm.processing" @click="saveProduct(product)">Simpan</button>
                                        <button type="button" @click="editingProductId = null">Batal</button>
                                    </td>
                                </template>
                                <template v-else>
                                    <td>{{ product.nama }}</td>
                                    <td>{{ product.kategori }}</td>
                                    <td>{{ formatPrice(product.harga) }}</td>
                                    <td>{{ product.stok }}</td>
                                    <td><span class="availability" :class="{ unavailable: !product.tersedia }">{{ product.tersedia ? 'Tersedia' : 'Tidak tersedia' }}</span></td>
                                    <td class="admin-row-actions">
                                        <button type="button" @click="startEditing(product)">Ubah</button>
                                        <button v-if="product.tersedia" type="button" @click="disableProduct(product)">Nonaktifkan</button>
                                    </td>
                                </template>
                            </tr>
                            <tr v-if="editingProductId === product.id && Object.keys(editForm.errors).length">
                                <td colspan="6" class="admin-error">{{ Object.values(editForm.errors)[0] }}</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <p v-else class="admin-empty">Belum ada produk di database.</p>
            </section>
        </section>
    </main>
</template>

<style>
.admin-page { min-height: 100vh; background: #f3f6fc; }
.admin-header { display: flex; min-height: 66px; align-items: center; justify-content: space-between; gap: 12px; padding: 10px max(18px, calc((100vw - 1060px) / 2)); color: #fff; background: #09256f; }
.admin-brand { display: flex; align-items: center; gap: 10px; font-size: 12px; font-weight: 800; letter-spacing: 1px; }
.admin-brand img { width: 40px; height: 40px; border-radius: 11px; background: #e2ebff; object-fit: contain; }
.admin-brand small { margin-left: 6px; border-radius: 99px; padding: 3px 6px; color: #09256f; background: #e2ebff; font-size: 8px; letter-spacing: .5px; }
.admin-actions { display: flex; align-items: center; gap: 13px; }
.admin-actions a { color: #e2eaff; font-size: 11px; text-decoration: none; }
.admin-actions button { min-height: 35px; border: 1px solid rgb(255 255 255 / 28%); border-radius: 9px; padding: 0 12px; color: #fff; background: rgb(255 255 255 / 10%); font-size: 11px; }
.admin-content { width: min(100% - 32px, 1020px); margin: 32px auto; }
.admin-kicker { margin: 0 0 6px; color: #4967a3; font-size: 10px; font-weight: 800; letter-spacing: 1.4px; }
.admin-content h1 { margin: 0; color: #132c64; font-size: 27px; }
.admin-description { margin: 8px 0 22px; color: #6a7892; font-size: 13px; }
.admin-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }
.admin-stats article { display: grid; gap: 10px; border: 1px solid #e6ecf6; border-radius: 15px; padding: 18px; background: #fff; box-shadow: 0 5px 15px rgb(22 47 103 / 4%); }
.admin-stats span { color: #697790; font-size: 11px; }
.admin-stats strong { color: #09256f; font-size: 26px; }
.admin-products { overflow: hidden; margin-top: 21px; border: 1px solid #e6ecf6; border-radius: 16px; background: #fff; box-shadow: 0 5px 15px rgb(22 47 103 / 4%); }
.admin-status { border-radius: 10px; padding: 11px 13px; color: #164b32; background: #e8f7ed; font-size: 12px; }
.admin-create { padding-bottom: 16px; }
.product-form { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px; padding: 15px 18px 0; }
.product-form label { display: grid; gap: 5px; color: #596780; font-size: 10px; font-weight: 700; }
.product-form input, .admin-products td input:not([type="checkbox"]) { min-width: 0; min-height: 34px; border: 1px solid #dfe7f7; border-radius: 8px; padding: 0 8px; color: #26334b; background: #fff; font: inherit; }
.product-form button, .admin-row-actions button { min-height: 34px; border: 0; border-radius: 8px; padding: 0 11px; color: #fff; background: #09256f; font-size: 10px; font-weight: 700; }
.product-form button { align-self: end; }
.product-form button:disabled, .admin-row-actions button:disabled { opacity: .65; }
.product-description-field { grid-column: span 3; }
.admin-error { margin: 8px 18px 0; color: #b42318; font-size: 11px; }
.admin-products > header { display: flex; align-items: center; justify-content: space-between; gap: 10px; border-bottom: 1px solid #edf0f6; padding: 15px 18px; }
.admin-products h2 { margin: 0; color: #243451; font-size: 15px; }
.admin-products > header span { color: #71809b; font-size: 10px; }
.admin-table-wrap { overflow-x: auto; }
.admin-products table { width: 100%; border-collapse: collapse; text-align: left; }
.admin-products th, .admin-products td { border-bottom: 1px solid #eef1f6; padding: 12px 16px; color: #4a5871; font-size: 11px; white-space: nowrap; }
.admin-products th { color: #66748c; background: #f8faff; font-size: 10px; }
.admin-row-actions { display: flex; gap: 6px; }
.admin-row-actions button + button { color: #34425d; background: #e9eef8; }
.availability-check { display: flex; align-items: center; gap: 4px; font-size: 10px; }
.availability { border-radius: 99px; padding: 5px 8px; color: #15633b; background: #e8f7ed; font-size: 9px; }
.availability.unavailable { color: #94510d; background: #fff2df; }
.admin-empty { padding: 20px; color: #71809b; font-size: 12px; }
.admin-page button:focus-visible, .admin-page a:focus-visible { outline: 3px solid #9db8f5; outline-offset: 3px; }
@media (max-width: 560px) {
    .admin-header { padding-inline: 12px; }
    .admin-brand { font-size: 10px; }
    .admin-actions { gap: 8px; }
    .admin-actions a { font-size: 9px; }
    .admin-actions button { padding-inline: 9px; font-size: 10px; }
    .admin-content { margin-top: 23px; }
    .admin-stats { grid-template-columns: repeat(2, 1fr); gap: 7px; }
    .admin-stats article { gap: 8px; padding: 12px 9px; }
    .admin-stats span { font-size: 9px; }
    .admin-stats strong { font-size: 21px; }
    .admin-products th, .admin-products td { padding: 10px; }
    .product-form { grid-template-columns: repeat(2, minmax(0, 1fr)); padding-inline: 12px; }
    .product-description-field { grid-column: span 2; }
}
</style>
