<script setup lang="ts">
import Icon from '@/components/Icon.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Head, router } from '@inertiajs/vue3';
import { onMounted, onUnmounted, ref } from 'vue';

interface CacheStatistics {
    driver: string;
    total_size: string;
    total_keys: number;
    hit_rate?: string;
    miss_rate?: string;
    uptime?: string;
    memory_usage?: string;
    cache_types: {
        [key: string]: {
            size: string;
            keys: number;
        };
    };
}

interface Props {
    statistics: CacheStatistics;
}

const props = defineProps<Props>();

const { t } = useI18nStore();

const statistics = ref<CacheStatistics>(props.statistics);
const selectedTypes = ref<string[]>([]);
const isLoading = ref(false);
const autoRefresh = ref(true);
let refreshInterval: number | null = null;

const cacheTypes = [
    {
        value: 'application',
        label: t('Application Cache'),
        description: t('General application cache store'),
        icon: 'database',
    },
    {
        value: 'config',
        label: t('Configuration'),
        description: t('Bootstrap configuration cache'),
        icon: 'settings',
    },
    {
        value: 'route',
        label: t('Routes'),
        description: t('Compiled route definitions'),
        icon: 'signpost',
    },
    {
        value: 'view',
        label: t('Views'),
        description: t('Compiled Blade templates'),
        icon: 'eye',
    },
    {
        value: 'event',
        label: t('Events'),
        description: t('Event listener mappings'),
        icon: 'zap',
    },
];

const rebuildableTypes = ['config', 'route', 'event'];

function toggleSelectAll() {
    if (selectedTypes.value.length === cacheTypes.length) {
        selectedTypes.value = [];
    } else {
        selectedTypes.value = cacheTypes.map((t) => t.value);
    }
}

async function fetchStatistics() {
    try {
        const response = await fetch('/admin/system/cache/statistics');
        const result = await response.json();
        if (result.success && result.data) {
            statistics.value = result.data;
        }
    } catch (error) {
        console.error('Failed to fetch statistics:', error);
    }
}

function clearCache(types: string[]) {
    if (types.length === 0) {
        return;
    }

    isLoading.value = true;
    router.post(
        '/admin/system/cache/clear',
        {
            types,
        },
        {
            preserveScroll: true,
            onFinish: () => {
                isLoading.value = false;
                selectedTypes.value = [];
                fetchStatistics();
            },
        },
    );
}

function rebuildCache(types: string[]) {
    const validTypes = types.filter((t) => rebuildableTypes.includes(t));

    if (validTypes.length === 0) {
        // Show message when trying to rebuild non-rebuildable cache types
        const invalidTypes = types.filter((t) => !rebuildableTypes.includes(t));
        if (invalidTypes.length > 0) {
            window.dispatchEvent(
                new CustomEvent('show-toast', {
                    detail: {
                        message: t(
                            'Cannot rebuild {types} cache. Only Config, Route, and Event caches can be rebuilt.',
                            { types: invalidTypes.join(', ') },
                        ),
                        type: 'error',
                    },
                }),
            );
        }
        return;
    }

    isLoading.value = true;
    router.post(
        '/admin/system/cache/rebuild',
        {
            types: validTypes,
        },
        {
            preserveScroll: true,
            onFinish: () => {
                isLoading.value = false;
                fetchStatistics();
            },
        },
    );
}

function clearSingle(type: string) {
    clearCache([type]);
}

function rebuildSingle(type: string) {
    if (rebuildableTypes.includes(type)) {
        rebuildCache([type]);
    }
}

onMounted(() => {
    if (autoRefresh.value) {
        refreshInterval = setInterval(fetchStatistics, 30000); // Refresh every 30s
    }
});

onUnmounted(() => {
    if (refreshInterval) {
        clearInterval(refreshInterval);
    }
});
</script>

<template>
    <Head :title="$t('Cache Management')" />
    <AdminLayout :title="$t('Cache Management')">
        <div class="space-y-6">
            <!-- Page Header -->
            <div
                class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
            >
                <div>
                    <h1
                        class="flex items-center gap-2 text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Cache Management') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        {{
                            $t(
                                'Manage and monitor application cache performance and storage.',
                            )
                        }}
                    </p>
                </div>
                <div class="flex items-center gap-3">
                    <label
                        class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400"
                    >
                        <input
                            v-model="autoRefresh"
                            type="checkbox"
                            class="rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                        />
                        {{ $t('Auto-refresh') }}
                    </label>
                    <button
                        @click="fetchStatistics"
                        :disabled="isLoading"
                        class="inline-flex items-center rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm transition-all duration-200 hover:bg-gray-50 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        <svg
                            class="mr-2 h-4 w-4"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                            />
                        </svg>
                        {{ $t('Refresh') }}
                    </button>
                </div>
            </div>

            <!-- Content -->
            <div class="overflow-auto rounded-xl">
                <!-- Statistics Cards -->
                <div
                    class="mb-8 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4"
                >
                    <div
                        class="rounded-lg border border-gray-100 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <div
                            class="text-sm font-medium text-gray-500 dark:text-gray-400"
                        >
                            {{ $t('Cache Driver') }}
                        </div>
                        <div
                            class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                        >
                            {{ statistics.driver }}
                        </div>
                    </div>
                    <div
                        class="rounded-lg border border-gray-100 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <div
                            class="text-sm font-medium text-gray-500 dark:text-gray-400"
                        >
                            {{ $t('Total Size') }}
                        </div>
                        <div
                            class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                        >
                            {{ statistics.total_size }}
                        </div>
                    </div>
                    <div
                        class="rounded-lg border border-gray-100 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <div
                            class="text-sm font-medium text-gray-500 dark:text-gray-400"
                        >
                            {{ $t('Total Keys') }}
                        </div>
                        <div
                            class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                        >
                            {{ statistics.total_keys?.toLocaleString() ?? '0' }}
                        </div>
                    </div>
                    <div
                        v-if="statistics.hit_rate"
                        class="rounded-lg border border-gray-100 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <div
                            class="text-sm font-medium text-gray-500 dark:text-gray-400"
                        >
                            {{ $t('Hit Rate') }}
                        </div>
                        <div
                            class="mt-2 text-2xl font-bold text-green-600 dark:text-green-400"
                        >
                            {{ statistics.hit_rate }}
                        </div>
                    </div>
                </div>

                <!-- Additional Stats (Redis only) -->
                <div
                    v-if="statistics.memory_usage || statistics.uptime"
                    class="mb-8 grid grid-cols-1 gap-6 md:grid-cols-2"
                >
                    <div
                        v-if="statistics.memory_usage"
                        class="rounded-lg border border-gray-100 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <div
                            class="text-sm font-medium text-gray-500 dark:text-gray-400"
                        >
                            {{ $t('Memory Usage') }}
                        </div>
                        <div
                            class="mt-2 text-lg font-semibold text-gray-900 dark:text-white"
                        >
                            {{ statistics.memory_usage }}
                        </div>
                    </div>
                    <div
                        v-if="statistics.uptime"
                        class="rounded-lg border border-gray-100 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <div
                            class="text-sm font-medium text-gray-500 dark:text-gray-400"
                        >
                            {{ $t('Cache Uptime') }}
                        </div>
                        <div
                            class="mt-2 text-lg font-semibold text-gray-900 dark:text-white"
                        >
                            {{ statistics.uptime }}
                        </div>
                    </div>
                </div>

                <!-- Cache Types -->
                <div>
                    <div
                        class="mb-6 flex flex-col items-start justify-between gap-4 sm:flex-row sm:items-center"
                    >
                        <h2
                            class="flex items-center gap-2 text-lg font-bold text-gray-900 dark:text-white"
                        >
                            {{ $t('Cache Types') }}
                            <span
                                class="rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-600 dark:bg-gray-700 dark:text-gray-400"
                            >
                                {{ cacheTypes.length }}
                            </span>
                        </h2>
                        <div class="flex w-full flex-wrap gap-2 sm:w-auto">
                            <button
                                @click="toggleSelectAll"
                                class="inline-flex flex-1 items-center justify-center rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none sm:flex-none dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                            >
                                {{
                                    selectedTypes.length === cacheTypes.length
                                        ? $t('Deselect All')
                                        : $t('Select All')
                                }}
                            </button>
                            <button
                                @click="clearCache(selectedTypes)"
                                :disabled="
                                    isLoading || selectedTypes.length === 0
                                "
                                class="inline-flex flex-1 items-center justify-center rounded-lg border border-transparent bg-red-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:bg-red-700 focus:ring-2 focus:ring-red-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 sm:flex-none"
                            >
                                <svg
                                    class="mr-2 h-4 w-4"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                                    />
                                </svg>
                                {{ $t('Clear Selected') }}
                            </button>
                            <button
                                @click="rebuildCache(selectedTypes)"
                                :disabled="
                                    isLoading || selectedTypes.length === 0
                                "
                                class="inline-flex flex-1 items-center justify-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 sm:flex-none"
                            >
                                <svg
                                    class="mr-2 h-4 w-4"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                                    />
                                </svg>
                                {{ $t('Rebuild Selected') }}
                            </button>
                        </div>
                    </div>

                    <div
                        class="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-3"
                    >
                        <div
                            v-for="type in cacheTypes"
                            :key="type.value"
                            class="group flex flex-col rounded-xl border border-gray-100 bg-white p-6 shadow-sm transition-shadow hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
                            :class="{
                                'border-transparent ring-2 ring-blue-500':
                                    selectedTypes.includes(type.value),
                            }"
                        >
                            <div class="mb-4 flex items-start justify-between">
                                <div
                                    class="rounded-lg bg-blue-50 p-3 text-blue-600 transition-transform duration-200 group-hover:scale-110 dark:bg-blue-900/20 dark:text-blue-400"
                                >
                                    <Icon :name="type.icon" class="h-6 w-6" />
                                </div>
                                <input
                                    v-model="selectedTypes"
                                    :value="type.value"
                                    type="checkbox"
                                    class="h-5 w-5 cursor-pointer rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                />
                            </div>

                            <div class="mb-6 flex-1">
                                <h3
                                    class="mb-1 text-lg font-bold text-gray-900 dark:text-white"
                                >
                                    {{ type.label }}
                                </h3>
                                <p
                                    class="line-clamp-2 text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{ type.description }}
                                </p>
                            </div>

                            <div
                                class="-mx-6 mb-4 grid grid-cols-2 gap-4 border-t border-gray-100 bg-gray-50/50 px-6 py-4 dark:border-gray-700 dark:bg-gray-900/20"
                            >
                                <div>
                                    <div
                                        class="mb-1 text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Size') }}
                                    </div>
                                    <div
                                        class="font-semibold text-gray-900 dark:text-white"
                                    >
                                        {{
                                            statistics.cache_types?.[type.value]
                                                ?.size || '0 B'
                                        }}
                                    </div>
                                </div>
                                <div class="text-right">
                                    <div
                                        class="mb-1 text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Keys') }}
                                    </div>
                                    <div
                                        class="font-semibold text-gray-900 dark:text-white"
                                    >
                                        {{
                                            statistics.cache_types?.[type.value]
                                                ?.keys || 0
                                        }}
                                    </div>
                                </div>
                            </div>

                            <div class="mt-auto flex gap-2">
                                <button
                                    @click="clearSingle(type.value)"
                                    :disabled="isLoading"
                                    class="inline-flex flex-1 items-center justify-center rounded-lg border border-transparent bg-red-50 px-3 py-2 text-sm font-medium text-red-700 transition-colors hover:bg-red-100 focus:ring-2 focus:ring-red-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 dark:bg-red-900/20 dark:text-red-400 dark:hover:bg-red-900/40"
                                >
                                    {{ $t('Clear') }}
                                </button>
                                <button
                                    v-if="rebuildableTypes.includes(type.value)"
                                    @click="rebuildSingle(type.value)"
                                    :disabled="isLoading"
                                    class="inline-flex flex-1 items-center justify-center rounded-lg border border-transparent bg-blue-50 px-3 py-2 text-sm font-medium text-blue-700 transition-colors hover:bg-blue-100 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 dark:bg-blue-900/20 dark:text-blue-400 dark:hover:bg-blue-900/40"
                                >
                                    {{ $t('Rebuild') }}
                                </button>
                                <div v-else class="flex-1"></div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- End Cache Types -->
            </div>
        </div>
    </AdminLayout>
</template>
