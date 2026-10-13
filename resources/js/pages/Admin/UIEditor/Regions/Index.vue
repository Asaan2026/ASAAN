<script setup lang="ts">
import { useI18nStore } from '@/Stores/i18n';
import { useCalendar } from '@/composables/useCalendar';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, router } from '@inertiajs/vue3';
import axios from 'axios';
import {
    CheckCircle,
    Clock,
    LayoutTemplate,
    Pencil,
    Plus,
    Trash2,
    X,
} from 'lucide-vue-next';
import { ref } from 'vue';

type RegionType = 'header' | 'footer' | 'section' | 'banner' | 'sidebar';

interface GlobalRegion {
    id: number;
    name: string;
    slug: string;
    description: string | null;
    region_type: RegionType;
    status: 'draft' | 'published';
    published_at: string | null;
    updated_at: string | null;
}

const props = defineProps<{ regions: GlobalRegion[] }>();

const { t } = useI18nStore();
const { formatDate: formatCalendarDate } = useCalendar();

// ── Create modal ─────────────────────────────────────────────────────────────
const showCreate = ref(false);
const form = ref({
    name: '',
    description: '',
    region_type: 'section' as RegionType,
});
const creating = ref(false);
const createError = ref('');

function openCreate() {
    form.value = { name: '', description: '', region_type: 'section' };
    createError.value = '';
    showCreate.value = true;
}

async function submitCreate() {
    if (!form.value.name.trim()) {
        createError.value = t('Name is required.');
        return;
    }
    creating.value = true;
    createError.value = '';
    try {
        // Use Inertia post so we follow the redirect to the editor
        router.post('/admin/uieditor/regions', form.value);
    } catch {
        createError.value = t('Failed to create region.');
        creating.value = false;
    }
}

// ── Delete ───────────────────────────────────────────────────────────────────
const confirmDelete = ref<GlobalRegion | null>(null);
const deleting = ref(false);

async function doDelete() {
    if (!confirmDelete.value) return;
    deleting.value = true;
    try {
        await axios.delete(`/admin/uieditor/regions/${confirmDelete.value.id}`);
        router.reload({ only: ['regions'] });
    } finally {
        deleting.value = false;
        confirmDelete.value = null;
    }
}

// ── Helpers ──────────────────────────────────────────────────────────────────
const typeColors: Record<RegionType, string> = {
    header: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300',
    footer: 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300',
    section: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300',
    banner: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-300',
    sidebar: 'bg-teal-100 text-teal-700 dark:bg-teal-900/30 dark:text-teal-300',
};

const typeLabels: Record<RegionType, string> = {
    header: t('Header'),
    footer: t('Footer'),
    section: t('Section'),
    banner: t('Banner'),
    sidebar: t('Sidebar'),
};

function formatDate(iso: string | null): string {
    if (!iso) return '—';
    return formatCalendarDate(iso);
}

const regionTypes: { value: RegionType; label: string }[] = [
    { value: 'header', label: t('Header') },
    { value: 'footer', label: t('Footer') },
    { value: 'section', label: t('Section') },
    { value: 'banner', label: t('Banner') },
    { value: 'sidebar', label: t('Sidebar') },
];
</script>

<template>
    <Head :title="$t('Reusable Sections')" />

    <AdminLayout :title="$t('Reusable Sections')">
        <div class="space-y-6 p-6">
            <!-- Header -->
            <div class="flex items-center justify-between">
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Reusable Sections') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        {{
                            $t(
                                'Build once, reuse anywhere — edit a section once and all pages update automatically.',
                            )
                        }}
                    </p>
                </div>
                <button
                    @click="openCreate"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <Plus class="mr-2 h-4 w-4" />
                    {{ $t('New Section') }}
                </button>
            </div>

            <!-- Empty state -->
            <div
                v-if="!regions.length"
                class="flex flex-col items-center justify-center py-20 text-center"
            >
                <LayoutTemplate
                    class="mb-4 h-12 w-12 text-gray-300 dark:text-gray-600"
                />
                <h3
                    class="mb-1 text-base font-semibold text-gray-700 dark:text-gray-300"
                >
                    {{ $t('No sections yet') }}
                </h3>
                <p
                    class="mb-4 max-w-xs text-sm text-gray-500 dark:text-gray-400"
                >
                    {{
                        $t(
                            'Create your first Reusable Section — like a promo header or CTA strip — then insert it into any landing page.',
                        )
                    }}
                </p>
                <button
                    @click="openCreate"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <Plus class="mr-2 h-4 w-4" />
                    {{ $t('Create First Section') }}
                </button>
            </div>

            <!-- Regions grid -->
            <div
                v-else
                class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3"
            >
                <div
                    v-for="region in regions"
                    :key="region.id"
                    class="flex flex-col rounded-xl border border-gray-200 bg-white shadow-sm transition-shadow hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
                >
                    <!-- Card header -->
                    <div class="flex items-start justify-between p-4 pb-3">
                        <div class="flex min-w-0 items-center gap-2">
                            <span
                                :class="[
                                    'flex-shrink-0 rounded-full px-2 py-0.5 text-xs font-semibold capitalize',
                                    typeColors[region.region_type],
                                ]"
                            >
                                {{ typeLabels[region.region_type] }}
                            </span>
                            <span
                                v-if="region.status === 'published'"
                                class="inline-flex items-center gap-1 text-xs text-green-600 dark:text-green-400"
                            >
                                <CheckCircle class="h-3 w-3" />
                                {{ $t('Live') }}
                            </span>
                            <span
                                v-else
                                class="inline-flex items-center gap-1 text-xs text-amber-600 dark:text-amber-400"
                            >
                                <Clock class="h-3 w-3" />
                                {{ $t('Draft') }}
                            </span>
                        </div>
                        <button
                            @click="confirmDelete = region"
                            class="flex-shrink-0 p-1 text-gray-300 transition-colors hover:text-red-500"
                            :title="$t('Delete region')"
                        >
                            <Trash2 class="h-4 w-4" />
                        </button>
                    </div>

                    <!-- Card body -->
                    <div class="flex-1 px-4 pb-2">
                        <h3
                            class="truncate text-sm font-semibold text-gray-900 dark:text-white"
                        >
                            {{ region.name }}
                        </h3>
                        <p
                            v-if="region.description"
                            class="mt-0.5 line-clamp-2 text-xs text-gray-500 dark:text-gray-400"
                        >
                            {{ region.description }}
                        </p>
                        <p
                            v-else
                            class="mt-0.5 text-xs text-gray-400 italic dark:text-gray-500"
                        >
                            {{ $t('No description') }}
                        </p>
                    </div>

                    <!-- Card footer -->
                    <div
                        class="flex items-center justify-between border-t border-gray-100 px-4 py-3 dark:border-gray-700"
                    >
                        <span class="text-xs text-gray-400">{{
                            $t('Updated {date}', {
                                date: formatDate(region.updated_at),
                            })
                        }}</span>
                        <a
                            :href="`/admin/uieditor/regions/${region.id}/editor`"
                            class="inline-flex items-center gap-1.5 rounded-xl bg-blue-50 px-3 py-1.5 text-xs font-medium text-blue-600 transition-colors hover:bg-blue-600 hover:text-white dark:bg-blue-900/30 dark:text-blue-300 dark:hover:bg-blue-600 dark:hover:text-white"
                        >
                            <Pencil class="h-3.5 w-3.5" />
                            {{ $t('Edit Layout') }}
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <!-- ── Create modal ──────────────────────────────────────────────────── -->
        <Teleport to="body">
            <Transition
                enter-active-class="transition-opacity duration-200"
                enter-from-class="opacity-0"
                enter-to-class="opacity-100"
                leave-active-class="transition-opacity duration-150"
                leave-from-class="opacity-100"
                leave-to-class="opacity-0"
            >
                <div
                    v-if="showCreate"
                    class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
                    @click.self="showCreate = false"
                >
                    <div
                        class="w-full max-w-md rounded-2xl border border-gray-200 bg-white shadow-2xl dark:border-gray-700 dark:bg-gray-900"
                    >
                        <!-- Modal header -->
                        <div
                            class="flex items-center justify-between border-b border-gray-100 px-6 py-4 dark:border-gray-800"
                        >
                            <h2
                                class="text-base font-semibold text-gray-900 dark:text-white"
                            >
                                {{ $t('New Reusable Section') }}
                            </h2>
                            <button
                                @click="showCreate = false"
                                class="text-gray-400 transition hover:text-gray-600"
                            >
                                <X class="h-5 w-5" />
                            </button>
                        </div>

                        <!-- Modal body -->
                        <div class="space-y-4 px-6 py-5">
                            <!-- Name -->
                            <div>
                                <label
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Section Name') }}
                                    <span class="text-red-500">*</span>
                                </label>
                                <input
                                    v-model="form.name"
                                    type="text"
                                    :placeholder="
                                        $t('e.g. Summer Promo Header')
                                    "
                                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                    @keydown.enter="submitCreate"
                                />
                            </div>

                            <!-- Type -->
                            <div>
                                <label
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Type') }}</label
                                >
                                <select
                                    v-model="form.region_type"
                                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                >
                                    <option
                                        v-for="t in regionTypes"
                                        :key="t.value"
                                        :value="t.value"
                                    >
                                        {{ t.label }}
                                    </option>
                                </select>
                            </div>

                            <!-- Description -->
                            <div>
                                <label
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Description') }}
                                    <span class="text-gray-400">{{
                                        $t('(optional)')
                                    }}</span></label
                                >
                                <textarea
                                    v-model="form.description"
                                    rows="2"
                                    :placeholder="
                                        $t('What is this region used for?')
                                    "
                                    class="w-full resize-none rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                />
                            </div>

                            <p v-if="createError" class="text-sm text-red-600">
                                {{ createError }}
                            </p>
                        </div>

                        <!-- Modal footer -->
                        <div
                            class="flex items-center justify-end gap-3 border-t border-gray-100 px-6 py-4 dark:border-gray-800"
                        >
                            <button
                                @click="showCreate = false"
                                class="rounded-lg px-4 py-2 text-sm font-medium text-gray-700 transition hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
                            >
                                {{ $t('Cancel') }}
                            </button>
                            <button
                                @click="submitCreate"
                                :disabled="creating || !form.name.trim()"
                                class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                            >
                                <span v-if="creating">{{
                                    $t('Creating…')
                                }}</span>
                                <span v-else>{{
                                    $t('Create &amp; Edit Layout')
                                }}</span>
                            </button>
                        </div>
                    </div>
                </div>
            </Transition>

            <!-- Delete confirm modal -->
            <Transition
                enter-active-class="transition-opacity duration-200"
                enter-from-class="opacity-0"
                enter-to-class="opacity-100"
                leave-active-class="transition-opacity duration-150"
                leave-from-class="opacity-100"
                leave-to-class="opacity-0"
            >
                <div
                    v-if="confirmDelete"
                    class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
                    @click.self="confirmDelete = null"
                >
                    <div
                        class="w-full max-w-sm rounded-2xl border border-gray-200 bg-white p-6 shadow-2xl dark:border-gray-700 dark:bg-gray-900"
                    >
                        <h3
                            class="mb-2 text-base font-semibold text-gray-900 dark:text-white"
                        >
                            {{ $t('Delete Section?') }}
                        </h3>
                        <p
                            class="mb-5 text-sm text-gray-500 dark:text-gray-400"
                        >
                            {{ $t('"')
                            }}<strong
                                class="text-gray-700 dark:text-gray-200"
                                >{{ confirmDelete?.name }}</strong
                            >{{
                                $t(
                                    '" will be permanently deleted. Any pages that reference this section will show a placeholder.',
                                )
                            }}
                        </p>
                        <div class="flex justify-end gap-3">
                            <button
                                @click="confirmDelete = null"
                                class="rounded-lg px-4 py-2 text-sm font-medium text-gray-600 transition hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
                            >
                                {{ $t('Cancel') }}
                            </button>
                            <button
                                @click="doDelete"
                                :disabled="deleting"
                                class="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-red-700 disabled:opacity-50"
                            >
                                <span v-if="deleting">{{
                                    $t('Deleting…')
                                }}</span>
                                <span v-else>{{ $t('Yes, Delete') }}</span>
                            </button>
                        </div>
                    </div>
                </div>
            </Transition>
        </Teleport>
    </AdminLayout>
</template>
