import './bootstrap';
import '@fontsource-variable/inter';

import { createInertiaApp } from '@inertiajs/vue3';
import { createApp, h } from 'vue';

const pages = import.meta.glob('../../../frontend/src/Pages/**/*.vue', {
    eager: true,
});

createInertiaApp({
    resolve: (name) => {
        const page = pages[`../../../frontend/src/Pages/${name}.vue`];

        if (!page) {
            throw new Error(`Unknown Inertia page: ${name}`);
        }

        return page.default;
    },
    setup({ el, App, props, plugin }) {
        createApp({ render: () => h(App, props) }).use(plugin).mount(el);
    },
});
