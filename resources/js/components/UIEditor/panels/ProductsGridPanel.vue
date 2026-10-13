<script setup lang="ts">
import axios from 'axios';
import { computed, ref } from 'vue';

const props = defineProps<{ settings: Record<string, unknown> }>();
const emit = defineEmits<{ 'update:settings': [v: Record<string, unknown>] }>();
function update(key: string, value: unknown) {
    emit('update:settings', { ...props.settings, [key]: value });
}

interface ProductOption {
    id: number;
    name: string;
}
const search = ref('');
const options = ref<ProductOption[]>([]);
const searching = ref(false);

async function doSearch() {
    if (!search.value.trim()) {
        options.value = [];
        return;
    }
    searching.value = true;
    try {
        const res = await axios.get(route('admin.uieditor.products.search'), {
            params: { search: search.value, per_page: 10 },
        });
        options.value = res.data.data ?? [];
    } finally {
        searching.value = false;
    }
}

const selectedIds = computed(
    () => (props.settings.product_ids as number[]) ?? [],
);

function toggleProduct(id: number) {
    const ids = [...selectedIds.value];
    const i = ids.indexOf(id);
    if (i !== -1) ids.splice(i, 1);
    else ids.push(id);
    update('product_ids', ids);
}
</script>

<template>
    <div class="space-y-4 p-4">
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Search & Select Products</label
            >
            <div class="mb-2 flex gap-2">
                <input
                    v-model="search"
                    type="text"
                    placeholder="Search products…"
                    class="uie-input flex-1"
                    @keydown.enter.prevent="doSearch"
                />
                <button
                    type="button"
                    :disabled="searching"
                    class="rounded-lg bg-blue-600 px-2 py-1.5 text-xs text-white hover:bg-blue-700 disabled:opacity-50"
                    @click="doSearch"
                >
                    Search
                </button>
            </div>
            <div
                v-if="options.length"
                class="max-h-40 divide-y divide-gray-100 overflow-y-auto rounded-lg border border-gray-200 dark:divide-gray-700 dark:border-gray-700"
            >
                <label
                    v-for="opt in options"
                    :key="opt.id"
                    class="flex cursor-pointer items-center gap-2 px-3 py-2 text-sm hover:bg-gray-50 dark:hover:bg-gray-800"
                >
                    <input
                        type="checkbox"
                        :checked="selectedIds.includes(opt.id)"
                        class="rounded text-blue-600"
                        @change="toggleProduct(opt.id)"
                    />
                    <span class="text-gray-700 dark:text-gray-300">{{
                        opt.name
                    }}</span>
                </label>
            </div>
            <p
                v-if="selectedIds.length"
                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
            >
                {{ selectedIds.length }} product(s) selected
            </p>
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Columns</label
            >
            <input
                type="number"
                :value="settings.columns as number"
                min="2"
                max="6"
                class="uie-input"
                @change="
                    update(
                        'columns',
                        Number(($event.target as HTMLInputElement).value),
                    )
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Max Products</label
            >
            <input
                type="number"
                :value="settings.limit as number"
                min="1"
                max="50"
                class="uie-input"
                @change="
                    update(
                        'limit',
                        Number(($event.target as HTMLInputElement).value),
                    )
                "
            />
        </div>
        <div class="flex items-center gap-2">
            <input
                id="pg_price"
                type="checkbox"
                :checked="settings.show_price as boolean"
                class="rounded text-blue-600"
                @change="
                    update(
                        'show_price',
                        ($event.target as HTMLInputElement).checked,
                    )
                "
            />
            <label
                for="pg_price"
                class="text-sm text-gray-700 dark:text-gray-300"
                >Show Price</label
            >
        </div>
        <div class="flex items-center gap-2">
            <input
                id="pg_cart"
                type="checkbox"
                :checked="settings.show_cart as boolean"
                class="rounded text-blue-600"
                @change="
                    update(
                        'show_cart',
                        ($event.target as HTMLInputElement).checked,
                    )
                "
            />
            <label
                for="pg_cart"
                class="text-sm text-gray-700 dark:text-gray-300"
                >Show Add to Cart</label
            >
        </div>
    </div>
</template>

<style scoped>
@reference "tailwindcss";
.uie-input {
    @apply w-full rounded-lg border border-gray-300 bg-white px-2 py-1.5 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white;
}
</style>
