import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import laravel from 'laravel-vite-plugin';
import tailwindcss from '@tailwindcss/vite';
import { fileURLToPath } from 'node:url';

const repositoryRoot = fileURLToPath(new URL('../', import.meta.url));

export default defineConfig({
    resolve: {
        alias: {
            '@inertiajs/vue3': fileURLToPath(new URL('./node_modules/@inertiajs/vue3/dist/index.esm.js', import.meta.url)),
            vue: fileURLToPath(new URL('./node_modules/vue/dist/vue.runtime.esm-bundler.js', import.meta.url)),
        },
        dedupe: ['vue'],
    },
    plugins: [
        vue(),
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
        tailwindcss(),
    ],
    server: {
        fs: {
            allow: [repositoryRoot],
        },
    },
});
