<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Head } from '@inertiajs/vue3';
import {
    CheckCircle,
    Play,
    ShoppingCart,
    Store,
    Terminal,
    XCircle,
} from 'lucide-vue-next';
import { ref } from 'vue';

const props = defineProps({
    sources: Array,
});

const { t } = useI18nStore();

const selectedSource = ref(null);
const selectedEntity = ref('all');
const dryRun = ref(true);
const isProcessing = ref(false);
const migrationOutput = ref('');

const entities = [
    {
        value: 'all',
        label: t('All Data'),
        description: t(
            'Migrate all categories, customers, products, and orders',
        ),
    },
    {
        value: 'categories',
        label: t('Categories'),
        description: t('Product categories and hierarchies'),
    },
    {
        value: 'customers',
        label: t('Customers'),
        description: t('Customer accounts and addresses'),
    },
    {
        value: 'products',
        label: t('Products'),
        description: t('Products with inventory and pricing'),
    },
    {
        value: 'orders',
        label: t('Orders'),
        description: t('Order history and line items'),
    },
];

const getIcon = (iconName) => {
    const icons = {
        'shopping-cart': ShoppingCart,
        store: Store,
    };
    return icons[iconName] || ShoppingCart;
};

const selectSource = (source) => {
    selectedSource.value = source;
    migrationOutput.value = '';
};

const showToast = (message, type = 'success') => {
    window.dispatchEvent(
        new CustomEvent('show-toast', {
            detail: { message, type },
        }),
    );
};

const testConnection = async () => {
    if (!selectedSource.value) return;

    isProcessing.value = true;

    try {
        const response = await fetch(
            '/admin/system/migration/test-connection',
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector(
                        'meta[name="csrf-token"]',
                    ).content,
                    'X-Requested-With': 'XMLHttpRequest',
                },
                body: JSON.stringify({
                    source: selectedSource.value.id,
                }),
            },
        );

        const data = await response.json();

        if (data.success) {
            showToast(t('Connection successful!'), 'success');
        } else {
            showToast(
                t('Connection failed: {message}', { message: data.message }),
                'error',
            );
        }
    } catch (error) {
        showToast(
            t('Connection test failed: {message}', { message: error.message }),
            'error',
        );
    } finally {
        isProcessing.value = false;
    }
};

const startMigration = async () => {
    if (!selectedSource.value) return;

    isProcessing.value = true;
    migrationOutput.value = t('Starting migration...') + '\n';

    try {
        const response = await fetch('/admin/system/migration/migrate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector(
                    'meta[name="csrf-token"]',
                ).content,
                'X-Requested-With': 'XMLHttpRequest',
            },
            body: JSON.stringify({
                source: selectedSource.value.id,
                entity: selectedEntity.value,
                dry_run: dryRun.value,
            }),
        });

        const data = await response.json();

        if (data.success) {
            migrationOutput.value +=
                '\n' + data.output + '\n\n✓ ' + data.message;
        } else {
            migrationOutput.value += '\n\n✗ ' + data.message;
        }
    } catch (error) {
        migrationOutput.value +=
            '\n\n✗ ' +
            t('Migration failed: {message}', { message: error.message });
    } finally {
        isProcessing.value = false;
    }
};
</script>

<template>
    <Head :title="$t('Data Migration')" />

    <AdminLayout :title="$t('Data Migration')">
        <div class="space-y-6">
            <!-- Header -->
            <div
                class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
            >
                <div>
                    <h1
                        class="flex items-center gap-2 text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Data Migration') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        {{ $t('Migrate data from other ecommerce platforms') }}
                    </p>
                </div>
            </div>

            <!-- Content -->
            <div class="overflow-auto rounded-xl">
                <div class="space-y-6">
                    <!-- Source Selection -->
                    <div
                        class="overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <div
                            class="border-b border-gray-200 bg-gray-50 px-6 py-4 dark:border-gray-700 dark:bg-gray-700/50"
                        >
                            <h2
                                class="text-sm font-semibold text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Select Migration Source') }}
                            </h2>
                        </div>
                        <div class="p-6">
                            <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                                <div
                                    v-for="source in sources"
                                    :key="source.id"
                                    @click="selectSource(source)"
                                    class="group relative flex cursor-pointer items-start rounded-lg border-2 p-4 transition-all"
                                    :class="
                                        selectedSource?.id === source.id
                                            ? 'border-blue-600 bg-blue-50 dark:bg-blue-900/20'
                                            : 'border-gray-200 hover:border-blue-300 hover:shadow-sm dark:border-gray-700 dark:hover:border-blue-700'
                                    "
                                >
                                    <div
                                        class="rounded-lg border border-gray-100 bg-white p-2 shadow-sm dark:border-gray-600 dark:bg-gray-800"
                                    >
                                        <component
                                            :is="getIcon(source.icon)"
                                            class="h-6 w-6 text-gray-600 dark:text-gray-400"
                                        />
                                    </div>
                                    <div class="ml-4 flex-1">
                                        <h3
                                            class="text-base font-medium text-gray-900 dark:text-gray-100"
                                        >
                                            {{ source.name }}
                                        </h3>
                                        <p
                                            class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{ source.description }}
                                        </p>
                                        <div class="mt-3 flex items-center">
                                            <component
                                                :is="
                                                    source.configured
                                                        ? CheckCircle
                                                        : XCircle
                                                "
                                                class="h-4 w-4"
                                                :class="
                                                    source.configured
                                                        ? 'text-green-600 dark:text-green-400'
                                                        : 'text-red-600 dark:text-red-400'
                                                "
                                            />
                                            <span
                                                class="ml-1.5 text-xs font-medium"
                                                :class="
                                                    source.configured
                                                        ? 'text-green-700 dark:text-green-300'
                                                        : 'text-red-700 dark:text-red-300'
                                                "
                                            >
                                                {{
                                                    source.configured
                                                        ? $t('Configured')
                                                        : $t('Not Configured')
                                                }}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Migration Options -->
                    <div
                        v-if="selectedSource"
                        class="overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <div
                            class="border-b border-gray-200 bg-gray-50 px-6 py-4 dark:border-gray-700 dark:bg-gray-700/50"
                        >
                            <h2
                                class="text-sm font-semibold text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Migration Options') }}
                            </h2>
                        </div>

                        <div class="p-6">
                            <!-- Entity Selection -->
                            <div class="mb-6 max-w-xl">
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('What to migrate') }}
                                </label>
                                <select
                                    v-model="selectedEntity"
                                    class="block w-full rounded-lg border-gray-300 bg-white text-gray-900 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm dark:border-gray-600 dark:bg-gray-900 dark:text-gray-100"
                                >
                                    <option
                                        v-for="entity in entities"
                                        :key="entity.value"
                                        :value="entity.value"
                                    >
                                        {{ entity.label }} -
                                        {{ entity.description }}
                                    </option>
                                </select>
                            </div>

                            <!-- Dry Run Toggle -->
                            <div class="mb-6 flex items-center">
                                <input
                                    id="dry-run"
                                    v-model="dryRun"
                                    type="checkbox"
                                    class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                />
                                <label
                                    for="dry-run"
                                    class="ml-2 cursor-pointer text-sm text-gray-700 select-none dark:text-gray-300"
                                >
                                    {{
                                        $t(
                                            'Dry run (preview without making changes)',
                                        )
                                    }}
                                </label>
                            </div>

                            <!-- Actions -->
                            <div class="flex gap-3">
                                <button
                                    @click="testConnection"
                                    :disabled="
                                        isProcessing ||
                                        !selectedSource.configured
                                    "
                                    class="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm transition-colors hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-200 dark:hover:bg-gray-700"
                                >
                                    {{ $t('Test Connection') }}
                                </button>
                                <button
                                    @click="startMigration"
                                    :disabled="
                                        isProcessing ||
                                        !selectedSource.configured
                                    "
                                    class="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                                >
                                    <component
                                        :is="dryRun ? Terminal : Play"
                                        class="h-4 w-4"
                                    />
                                    {{
                                        dryRun
                                            ? $t('Preview Migration')
                                            : $t('Start Migration')
                                    }}
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Output Console -->
                    <div
                        v-if="migrationOutput"
                        class="overflow-hidden rounded-lg border border-gray-700 bg-gray-900 shadow-sm"
                    >
                        <div
                            class="flex items-center justify-between border-b border-gray-700 bg-gray-800 px-4 py-2"
                        >
                            <h2
                                class="font-mono text-xs tracking-wider text-gray-400 uppercase"
                            >
                                {{ $t('Migration Output') }}
                            </h2>
                        </div>
                        <div
                            class="max-h-96 overflow-y-auto p-4 font-mono text-xs leading-relaxed whitespace-pre-wrap text-gray-300"
                        >
                            {{ migrationOutput }}
                        </div>
                    </div>

                    <!-- Configuration Help -->
                    <div
                        v-if="selectedSource && !selectedSource.configured"
                        class="rounded-lg border border-amber-200 bg-amber-50 p-4 dark:border-amber-800 dark:bg-amber-900/20"
                    >
                        <h3
                            class="mb-2 text-sm font-medium text-amber-800 dark:text-amber-200"
                        >
                            {{ $t('Configuration Required') }}
                        </h3>
                        <p
                            class="mb-3 text-sm text-amber-700 dark:text-amber-300"
                        >
                            {{ $t('Add the following to your .env file:') }}
                        </p>
                        <pre
                            class="overflow-x-auto rounded-lg border border-amber-100 bg-white p-4 font-mono text-xs text-amber-900 shadow-sm dark:border-amber-800/50 dark:bg-gray-900 dark:text-amber-100"
                            >{{
                                selectedSource.id === 'woocommerce'
                                    ? `WOOCOMMERCE_DB_HOST=127.0.0.1
WOOCOMMERCE_DB_PORT=3306
WOOCOMMERCE_DB_DATABASE=wordpress
WOOCOMMERCE_DB_USERNAME=root
WOOCOMMERCE_DB_PASSWORD=
WOOCOMMERCE_DB_PREFIX=wp_
WOOCOMMERCE_HPOS_ENABLED=false`
                                    : `BAGISTO_DB_HOST=127.0.0.1
BAGISTO_DB_PORT=3306
BAGISTO_DB_DATABASE=bagisto
BAGISTO_DB_USERNAME=root
BAGISTO_DB_PASSWORD=`
                            }}</pre
                        >
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>
