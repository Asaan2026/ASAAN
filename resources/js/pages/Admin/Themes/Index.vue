<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, router, usePage } from '@inertiajs/vue3';
import {
    AlertTriangle,
    CheckCircle,
    ChevronRight,
    Download,
    Eye,
    LayoutTemplate,
    Monitor,
    Package,
    Plus,
    Power,
    Settings,
    Trash2,
    Wand2,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Theme {
    id: number;
    name: string;
    slug: string;
    description: string;
    version: string;
    author: string;
    screenshot: string | null;
    is_active: boolean;
    is_default: boolean;
    exists: boolean;
    supports: string[];
    homepageEditor: HomepageEditorMeta;
}

interface HomepageEditorMeta {
    mode: 'native' | 'layout';
    showPublishedBanner: boolean;
    showImportLayout: boolean;
    editorUrl: string;
    editorLabel: string;
    bannerTitle: string;
    bannerDescription: string;
}

interface Props {
    themes: Theme[];
}

const props = defineProps<Props>();
const page = usePage();
const flash = computed(() => (page.props as any).flash || {});
const processing = ref<Record<string, boolean>>({});
const uploadingTheme = ref(false);
const themeFileInput = ref<HTMLInputElement | null>(null);

const activeTheme = computed(() => props.themes.find((t) => t.is_active));
const otherThemes = computed(() => props.themes.filter((t) => !t.is_active));

const importingLayout = ref<Record<string, boolean>>({});

const importDemoLayout = (slug: string) => {
    if (importingLayout.value[slug]) return;
    if (
        !confirm(
            'This will import the demo homepage layout and replace any existing draft. Continue?',
        )
    )
        return;
    importingLayout.value[slug] = true;
    router.post(
        `/admin/appearance/themes/${slug}/import-layout`,
        {},
        {
            preserveScroll: true,
            onFinish: () => {
                importingLayout.value[slug] = false;
            },
        },
    );
};

const activateTheme = (slug: string) => {
    if (processing.value[slug]) return;

    processing.value[slug] = true;

    router.post(
        `/admin/appearance/themes/${slug}/activate`,
        {},
        {
            preserveScroll: true,
            onFinish: () => {
                processing.value[slug] = false;
            },
        },
    );
};

const deleteTheme = (slug: string, name: string) => {
    if (processing.value[slug]) return;

    if (!confirm(`Are you sure you want to delete the theme "${name}"?`)) {
        return;
    }

    processing.value[slug] = true;

    router.delete(`/admin/appearance/themes/${slug}`, {
        preserveScroll: true,
        onFinish: () => {
            processing.value[slug] = false;
        },
    });
};

const goToSettings = (slug: string) => {
    router.get('/admin/appearance');
};

const downloadTheme = (slug: string) => {
    window.location.href = `/admin/appearance/themes/${encodeURIComponent(slug)}/download?source=installed`;
};

const triggerThemeUpload = () => {
    if (uploadingTheme.value) return;
    themeFileInput.value?.click();
};

const uploadTheme = (event: Event) => {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];

    if (!file) return;

    uploadingTheme.value = true;

    const formData = new FormData();
    formData.append('theme', file);

    router.post('/admin/appearance/themes/upload', formData, {
        preserveScroll: true,
        forceFormData: true,
        onFinish: () => {
            uploadingTheme.value = false;
            input.value = '';
        },
    });
};
</script>

<template>
    <AdminLayout :title="$t('Themes')">
        <Head :title="$t('Themes')" />

        <div class="py-8">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <!-- Header -->
                <div
                    class="mb-8 flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
                >
                    <div>
                        <h1
                            class="text-2xl font-bold tracking-tight text-gray-900 dark:text-gray-100"
                        >
                            {{ $t('Themes') }}
                        </h1>
                        <p
                            class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                        >
                            {{
                                $t(
                                    'Manage installed themes — browse the catalog to add new storefront templates',
                                )
                            }}
                        </p>
                    </div>
                    <div class="flex flex-wrap gap-2">
                        <a
                            href="/admin/appearance/template-zone"
                            class="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
                        >
                            <LayoutTemplate class="h-4 w-4" />
                            {{ $t('Browse Template Zone') }}
                        </a>
                        <button
                            @click="triggerThemeUpload"
                            class="inline-flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                        >
                            <Plus class="h-4 w-4" />
                            {{ $t('Upload Zip') }}
                        </button>
                    </div>
                    <input
                        ref="themeFileInput"
                        type="file"
                        accept=".zip,application/zip"
                        class="hidden dark:bg-gray-700/50 dark:text-gray-100"
                        @change="uploadTheme"
                    />
                </div>

                <!-- Alerts -->
                <div
                    v-if="flash.success"
                    class="mb-6 rounded-lg border border-green-200 bg-green-50 p-4"
                >
                    <div class="flex">
                        <CheckCircle class="h-5 w-5 text-green-500" />
                        <p class="ml-3 text-sm font-medium text-green-800">
                            {{ flash.success }}
                        </p>
                    </div>
                </div>

                <div
                    v-if="flash.error"
                    class="mb-6 rounded-lg border border-red-200 bg-red-50 p-4"
                >
                    <div class="flex">
                        <AlertTriangle class="h-5 w-5 text-red-500" />
                        <p class="ml-3 text-sm font-medium text-red-800">
                            {{ flash.error }}
                        </p>
                    </div>
                </div>

                <!-- Active Theme -->
                <div v-if="activeTheme" class="mb-12">
                    <h2
                        class="mb-4 text-sm font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                    >
                        {{ $t('Current Theme') }}
                    </h2>
                    <div
                        class="flex flex-col overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm md:flex-row dark:border-gray-700 dark:bg-gray-800"
                    >
                        <!-- Screenshot -->
                        <div
                            class="group relative aspect-video overflow-hidden bg-gray-100 md:w-1/2 lg:w-2/5 dark:bg-gray-800/60"
                        >
                            <img
                                v-if="activeTheme.screenshot"
                                :src="activeTheme.screenshot"
                                :alt="activeTheme.name"
                                class="h-full w-full object-cover object-top transition-transform duration-700 group-hover:scale-105"
                            />
                            <div
                                v-else
                                class="flex h-full w-full flex-col items-center justify-center gap-3 bg-gradient-to-br from-blue-600 to-indigo-700"
                            >
                                <div
                                    class="flex h-16 w-16 items-center justify-center rounded-2xl bg-white/20"
                                >
                                    <Monitor class="h-9 w-9 text-white/80" />
                                </div>
                                <span
                                    class="text-lg font-bold tracking-wide text-white"
                                    >{{ activeTheme.name }}</span
                                >
                            </div>
                            <div class="absolute top-4 left-4">
                                <span
                                    class="inline-flex items-center rounded-full bg-green-500 px-3 py-1 text-xs font-semibold text-white shadow-sm ring-2 ring-white"
                                >
                                    <CheckCircle class="mr-1 h-3.5 w-3.5" />
                                    {{ $t('Active') }}
                                </span>
                            </div>
                        </div>

                        <!-- Details -->
                        <div
                            class="flex flex-col justify-center p-6 md:w-1/2 md:p-8 lg:w-3/5"
                        >
                            <div class="flex items-start justify-between">
                                <div>
                                    <h3
                                        class="mb-2 text-2xl font-bold text-gray-900 dark:text-gray-100"
                                    >
                                        {{ activeTheme.name }}
                                    </h3>
                                    <p
                                        class="mb-4 text-base leading-relaxed text-gray-500 dark:text-gray-400"
                                    >
                                        {{ activeTheme.description }}
                                    </p>
                                    <div
                                        class="flex items-center gap-4 text-sm text-gray-500 dark:text-gray-400"
                                    >
                                        <div class="flex items-center">
                                            <span
                                                class="mr-1 font-medium text-gray-900 dark:text-gray-100"
                                                >{{ $t('Version:') }}</span
                                            >
                                            {{ activeTheme.version }}
                                        </div>
                                        <div
                                            class="h-1 w-1 rounded-full bg-gray-300"
                                        ></div>
                                        <div class="flex items-center">
                                            <span
                                                class="mr-1 font-medium text-gray-900 dark:text-gray-100"
                                                >{{ $t('Author:') }}</span
                                            >
                                            {{ activeTheme.author }}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="mt-8 flex flex-wrap gap-3">
                                <a
                                    href="/"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    class="inline-flex items-center rounded-lg border border-gray-300 bg-white px-5 py-2.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 focus:ring-2 focus:ring-gray-300 focus:ring-offset-2 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                                    :title="$t('Preview active theme')"
                                >
                                    <Eye class="mr-2 h-4 w-4" />
                                    {{ $t('Preview') }}
                                </a>
                                <button
                                    @click="goToSettings(activeTheme.slug)"
                                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-5 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none"
                                >
                                    <Settings class="mr-2 h-4 w-4" />
                                    {{ $t('Customize') }}
                                </button>
                                <!-- Layout is live → link to page builder -->
                                <a
                                    v-if="
                                        activeTheme.homepageEditor
                                            ?.showPublishedBanner
                                    "
                                    :href="activeTheme.homepageEditor.editorUrl"
                                    class="inline-flex items-center gap-2 rounded-lg border border-green-300 bg-green-50 px-5 py-2.5 text-sm font-medium text-green-700 transition-colors hover:bg-green-100 focus:ring-2 focus:ring-green-400 focus:ring-offset-2 focus:outline-none"
                                >
                                    <Wand2 class="h-4 w-4" />
                                    {{ activeTheme.homepageEditor.editorLabel }}
                                    <ChevronRight
                                        class="h-3.5 w-3.5 opacity-60"
                                    />
                                </a>
                                <!-- No layout yet → import button -->
                                <button
                                    v-else-if="
                                        activeTheme.homepageEditor
                                            ?.showImportLayout
                                    "
                                    @click="importDemoLayout(activeTheme.slug)"
                                    :disabled="
                                        importingLayout[activeTheme.slug]
                                    "
                                    class="inline-flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-5 py-2.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 focus:ring-2 focus:ring-gray-300 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                                    :title="
                                        $t('Import pre-built homepage layout')
                                    "
                                >
                                    <svg
                                        v-if="importingLayout[activeTheme.slug]"
                                        class="h-4 w-4 animate-spin"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                    >
                                        <circle
                                            class="opacity-25"
                                            cx="12"
                                            cy="12"
                                            r="10"
                                            stroke="currentColor"
                                            stroke-width="4"
                                        />
                                        <path
                                            class="opacity-75"
                                            fill="currentColor"
                                            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                                        />
                                    </svg>
                                    <LayoutTemplate v-else class="h-4 w-4" />
                                    {{
                                        importingLayout[activeTheme.slug]
                                            ? $t('Importing…')
                                            : $t('Import Demo Layout')
                                    }}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Installed Themes -->
                <div v-if="otherThemes.length > 0">
                    <h2
                        class="mb-4 text-sm font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                    >
                        {{ $t('Installed Themes') }}
                    </h2>
                    <div
                        class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3"
                    >
                        <div
                            v-for="theme in otherThemes"
                            :key="theme.id"
                            class="group relative flex h-full flex-col overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm transition-shadow duration-300 hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
                        >
                            <!-- Screenshot -->
                            <div
                                class="relative aspect-video overflow-hidden bg-gray-100 dark:bg-gray-800/60"
                            >
                                <img
                                    v-if="theme.screenshot"
                                    :src="theme.screenshot"
                                    :alt="theme.name"
                                    class="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
                                />
                                <div
                                    v-else
                                    class="flex h-full w-full items-center justify-center bg-gray-50 dark:bg-gray-900"
                                >
                                    <Monitor class="h-12 w-12 text-gray-300" />
                                </div>

                                <!-- Overlay Actions -->
                                <div
                                    class="absolute inset-0 flex items-center justify-center gap-3 bg-black/40 opacity-0 transition-opacity duration-200 group-hover:opacity-100"
                                >
                                    <button
                                        v-if="theme.exists"
                                        @click="activateTheme(theme.slug)"
                                        :disabled="processing[theme.slug]"
                                        class="inline-flex translate-y-2 transform items-center rounded-lg bg-white px-4 py-2 text-sm font-semibold text-gray-900 shadow-lg transition-all duration-300 group-hover:translate-y-0 hover:bg-gray-50 focus:outline-none dark:bg-gray-800 dark:text-gray-100 dark:hover:bg-gray-700"
                                    >
                                        <svg
                                            v-if="processing[theme.slug]"
                                            class="mr-2 -ml-1 h-4 w-4 animate-spin text-gray-900 dark:text-gray-100"
                                            fill="none"
                                            viewBox="0 0 24 24"
                                        >
                                            <circle
                                                class="opacity-25"
                                                cx="12"
                                                cy="12"
                                                r="10"
                                                stroke="currentColor"
                                                stroke-width="4"
                                            ></circle>
                                            <path
                                                class="opacity-75"
                                                fill="currentColor"
                                                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                                            ></path>
                                        </svg>
                                        <Power v-else class="mr-2 h-4 w-4" />
                                        {{ $t('Activate') }}
                                    </button>
                                </div>
                            </div>

                            <!-- Content -->
                            <div class="flex flex-1 flex-col p-5">
                                <div
                                    class="mb-2 flex items-start justify-between"
                                >
                                    <div>
                                        <h3
                                            class="text-lg leading-tight font-bold text-gray-900 dark:text-gray-100"
                                        >
                                            {{ theme.name }}
                                        </h3>
                                        <div
                                            class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                        >
                                            v{{ theme.version }}
                                            {{
                                                $t('by {author}', {
                                                    author: theme.author,
                                                })
                                            }}
                                        </div>
                                    </div>
                                    <span
                                        v-if="theme.is_default"
                                        class="inline-flex items-center rounded bg-blue-50 px-2 py-0.5 text-xs font-medium text-blue-700 ring-1 ring-blue-700/10 ring-inset"
                                        >{{ $t('Default') }}</span
                                    >
                                </div>

                                <p
                                    class="mb-4 line-clamp-2 text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{ theme.description }}
                                </p>

                                <div
                                    class="mt-auto flex items-center justify-between border-t border-gray-100 pt-4"
                                >
                                    <div
                                        v-if="!theme.exists"
                                        class="flex items-center text-xs font-medium text-amber-600"
                                    >
                                        <AlertTriangle
                                            class="mr-1 h-3.5 w-3.5"
                                        />
                                        {{ $t('Files missing') }}
                                    </div>
                                    <div
                                        v-else
                                        class="text-xs font-medium text-gray-400"
                                    >
                                        {{
                                            theme.exists
                                                ? $t('Ready to use')
                                                : $t('Not installed')
                                        }}
                                    </div>

                                    <div class="flex items-center gap-1">
                                        <button
                                            v-if="theme.exists"
                                            @click="downloadTheme(theme.slug)"
                                            class="p-1 text-gray-400 transition-colors hover:text-blue-600"
                                            :title="$t('Download Theme')"
                                        >
                                            <Download class="h-4 w-4" />
                                        </button>
                                        <button
                                            v-if="
                                                !theme.is_active &&
                                                !theme.is_default
                                            "
                                            @click="
                                                deleteTheme(
                                                    theme.slug,
                                                    theme.name,
                                                )
                                            "
                                            class="p-1 text-gray-400 transition-colors hover:text-red-600"
                                            :title="$t('Delete Theme')"
                                        >
                                            <Trash2 class="h-4 w-4" />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Upload Placeholder Card -->
                        <div
                            @click="triggerThemeUpload"
                            class="group relative flex min-h-[300px] cursor-pointer flex-col items-center justify-center rounded-xl border-2 border-dashed border-gray-300 bg-gray-50 p-6 text-center transition-all hover:border-gray-400 hover:bg-gray-100 dark:border-gray-600 dark:bg-gray-900 dark:hover:bg-gray-700"
                        >
                            <div
                                class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-white shadow-sm transition-transform group-hover:scale-110 dark:bg-gray-800"
                            >
                                <Plus
                                    class="h-8 w-8 text-gray-400 group-hover:text-gray-600 dark:group-hover:text-gray-400"
                                />
                            </div>
                            <h3
                                class="text-base font-semibold text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Add New Theme') }}
                            </h3>
                            <p
                                class="mt-1 max-w-[200px] text-sm text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        'Upload a .zip file containing your theme files',
                                    )
                                }}
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Empty State (Only if no active theme AND no other themes) -->
                <div
                    v-if="props.themes.length === 0"
                    class="cursor-pointer rounded-xl border border-dashed border-gray-300 bg-white py-20 text-center transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:hover:bg-gray-700"
                    @click="triggerThemeUpload"
                >
                    <Package class="mx-auto h-12 w-12 text-gray-400" />
                    <h3
                        class="mt-4 text-lg font-medium text-gray-900 dark:text-gray-100"
                    >
                        {{ $t('No themes installed') }}
                    </h3>
                    <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
                        {{ $t('Click here to upload your first theme.') }}
                    </p>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>
