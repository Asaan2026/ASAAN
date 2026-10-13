<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Head, router, usePage } from '@inertiajs/vue3';
import {
    AlertTriangle,
    Camera,
    CheckCircle,
    ChevronRight,
    Download,
    ExternalLink,
    Eye,
    Info,
    Layers,
    Layout,
    LayoutTemplate,
    Monitor,
    Paintbrush,
    Palette,
    Phone,
    Save,
    Settings2,
    ShoppingCart,
    ToggleLeft,
    Wand2,
    X,
} from 'lucide-vue-next';
import { computed, onMounted, reactive, ref } from 'vue';

interface Theme {
    id: number;
    name: string;
    slug: string;
    description: string;
    version: string;
    author: string;
    screenshot: string | null;
    is_active: boolean;
}

interface Field {
    id: string;
    type: 'color' | 'select' | 'number' | 'boolean' | 'text';
    label: string;
    description?: string;
    default: any;
    options?: Record<string, string>;
    min?: number;
    max?: number;
    step?: number;
}

interface Section {
    id: string;
    title: string;
    description: string;
    fields: Field[];
}

interface Schema {
    sections: Section[];
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
    theme: Theme;
    schema: Schema;
    settings: Record<string, any>;
    hasThemeData: boolean;
    hasProductData: boolean;
    homepageEditor: HomepageEditorMeta;
}

const props = defineProps<Props>();
const page = usePage();
const { t } = useI18nStore();
const processing = ref(false);
const importing = ref(false);
const importingLayout = ref(false);
const showImportDialog = ref(false);
const importFresh = ref(false);
const importProducts = ref(false);
const uploadingScreenshot = ref(false);
const screenshotInput = ref<HTMLInputElement | null>(null);

const flash = computed(() => (page.props.flash as any) ?? {});

const screenshotUrl = computed(() => {
    if (props.theme.screenshot) {
        const url = props.theme.screenshot;
        const sep = url.includes('?') ? '&' : '?';
        return `${url}${sep}t=${Date.now()}`;
    }
    return null;
});

const triggerScreenshotUpload = () => screenshotInput.value?.click();

const uploadScreenshot = (event: Event) => {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    uploadingScreenshot.value = true;
    const formData = new FormData();
    formData.append('screenshot', file);
    router.post(
        `/admin/appearance/themes/${props.theme.slug}/screenshot`,
        formData,
        {
            preserveScroll: true,
            forceFormData: true,
            onFinish: () => {
                uploadingScreenshot.value = false;
                input.value = '';
            },
        },
    );
};

const importLayout = () => {
    if (importingLayout.value) return;
    importingLayout.value = true;
    router.post(
        `/admin/appearance/themes/${props.theme.slug}/import-layout`,
        {},
        {
            preserveScroll: true,
            onFinish: () => {
                importingLayout.value = false;
            },
        },
    );
};

const importThemeData = () => {
    importing.value = true;
    router.post(
        `/admin/appearance/themes/${props.theme.slug}/import-data`,
        { fresh: importFresh.value, include_products: importProducts.value },
        {
            preserveScroll: true,
            onFinish: () => {
                importing.value = false;
                showImportDialog.value = false;
                importFresh.value = false;
                importProducts.value = false;
            },
        },
    );
};

const tabDefs: Record<
    string,
    { icon: any; label: string; sections: string[] }
> = {
    contact: {
        icon: Phone,
        label: t('Contact & Social'),
        sections: ['contact', 'social'],
    },
    colors: {
        icon: Paintbrush,
        label: t('Colors & Typography'),
        sections: ['colors', 'typography'],
    },
    layout: { icon: Layout, label: t('Layout'), sections: ['layout'] },
    features: {
        icon: ToggleLeft,
        label: t('Features'),
        sections: ['features', 'homepage'],
    },
};

const tabs = computed(() =>
    Object.entries(tabDefs)
        .filter(([_, def]) =>
            def.sections.some((sid) =>
                props.schema.sections.find((s) => s.id === sid),
            ),
        )
        .map(([id, def]) => ({ id, ...def })),
);

const activeTab = ref(tabs.value[0]?.id ?? 'contact');

onMounted(() => {
    const params = new URLSearchParams(window.location.search);
    const requestedTab = params.get('tab');

    if (requestedTab && tabs.value.some((tab) => tab.id === requestedTab)) {
        activeTab.value = requestedTab;
    }
});

const sectionsForTab = computed(() => {
    const def = tabDefs[activeTab.value];
    if (!def) return [];
    return def.sections
        .map((sid) => props.schema.sections.find((s) => s.id === sid))
        .filter(Boolean) as Section[];
});

const form = reactive<Record<string, any>>({});
props.schema.sections.forEach((section) => {
    section.fields.forEach((field) => {
        const key = `${section.id}.${field.id}`;
        form[key] = props.settings[key] ?? field.default;
    });
});

const saveSettings = () => {
    processing.value = true;
    router.put(
        `/admin/appearance/themes/${props.theme.slug}/settings`,
        { settings: form },
        {
            preserveScroll: true,
            onFinish: () => {
                processing.value = false;
            },
        },
    );
};
</script>

<template>
    <AdminLayout :title="$t('Appearance')">
        <Head :title="$t('Appearance')" />

        <div class="space-y-5">
            <!-- Page Header -->
            <div
                class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Appearance') }}
                    </h1>
                    <p class="mt-0.5 text-sm text-gray-500 dark:text-gray-400">
                        {{
                            $t(
                                "Customize your store's look, feel and homepage layout",
                            )
                        }}
                    </p>
                </div>
                <div class="flex items-center gap-2.5">
                    <a
                        href="/"
                        target="_blank"
                        class="inline-flex items-center gap-1.5 rounded-xl border border-gray-300 bg-white px-3.5 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        <Eye class="h-4 w-4" />
                        {{ $t('Preview') }}
                    </a>
                    <button
                        @click="saveSettings"
                        :disabled="processing"
                        class="inline-flex items-center gap-2 rounded-xl bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition-all hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        <Save v-if="!processing" class="h-4 w-4" />
                        <svg
                            v-else
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
                        {{ processing ? $t('Saving…') : $t('Save Changes') }}
                    </button>
                </div>
            </div>

            <!-- Flash Messages -->
            <transition name="slide-down">
                <div
                    v-if="flash.success"
                    class="flex items-center gap-3 rounded-xl border border-green-200 bg-green-50 px-4 py-3 dark:border-green-800 dark:bg-green-900/30"
                >
                    <CheckCircle class="h-4 w-4 flex-shrink-0 text-green-500" />
                    <p
                        class="text-sm font-medium text-green-800 dark:text-green-300"
                    >
                        {{ flash.success }}
                    </p>
                </div>
            </transition>
            <transition name="slide-down">
                <div
                    v-if="flash.error"
                    class="flex items-center gap-3 rounded-xl border border-red-200 bg-red-50 px-4 py-3 dark:border-red-800 dark:bg-red-900/30"
                >
                    <Info class="h-4 w-4 flex-shrink-0 text-red-500" />
                    <p
                        class="text-sm font-medium text-red-800 dark:text-red-300"
                    >
                        {{ flash.error }}
                    </p>
                </div>
            </transition>

            <!-- Active Theme Card -->
            <div
                class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="flex flex-col sm:flex-row">
                    <!-- Screenshot -->
                    <div
                        class="group relative flex-shrink-0 cursor-pointer overflow-hidden bg-gradient-to-br from-gray-50 to-gray-100 sm:w-52 lg:w-60 dark:from-gray-900/60 dark:to-gray-800/60"
                        style="min-height: 168px"
                        @click="triggerScreenshotUpload"
                        :title="$t('Click to upload a screenshot')"
                    >
                        <img
                            v-if="screenshotUrl"
                            :src="screenshotUrl"
                            :alt="theme.name"
                            class="absolute inset-0 h-full w-full object-cover object-top transition-transform duration-700 group-hover:scale-105"
                        />
                        <div
                            v-else
                            class="absolute inset-0 flex flex-col items-center justify-center gap-2 bg-gradient-to-br from-blue-600 to-indigo-700 text-center"
                        >
                            <div
                                class="flex h-10 w-10 items-center justify-center rounded-xl bg-white/20"
                            >
                                <Monitor class="h-6 w-6 text-white/80" />
                            </div>
                            <p class="text-xs font-medium text-white/80">
                                {{ theme.name }}
                            </p>
                        </div>
                        <div
                            class="absolute inset-0 flex flex-col items-center justify-center gap-1.5 bg-black/50 opacity-0 transition-opacity group-hover:opacity-100"
                        >
                            <Camera
                                v-if="!uploadingScreenshot"
                                class="h-5 w-5 text-white"
                            />
                            <svg
                                v-else
                                class="h-5 w-5 animate-spin text-white"
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
                            <span class="text-[11px] font-medium text-white">{{
                                $t('Upload screenshot')
                            }}</span>
                        </div>
                    </div>
                    <input
                        ref="screenshotInput"
                        type="file"
                        accept="image/jpeg,image/png,image/webp"
                        class="hidden"
                        @change="uploadScreenshot"
                    />

                    <!-- Details -->
                    <div class="flex flex-1 flex-col gap-4 p-5 sm:p-6">
                        <div>
                            <div
                                class="mb-1.5 flex flex-wrap items-center gap-2"
                            >
                                <h3
                                    class="text-lg leading-snug font-bold text-gray-900 dark:text-white"
                                >
                                    {{ theme.name }}
                                </h3>
                                <span
                                    class="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-0.5 text-[11px] font-semibold text-green-700 ring-1 ring-green-600/20 ring-inset dark:bg-green-900/40 dark:text-green-400"
                                >
                                    <span
                                        class="h-1.5 w-1.5 animate-pulse rounded-full bg-green-500"
                                    ></span>
                                    {{ $t('Active') }}
                                </span>
                            </div>
                            <p
                                class="text-sm leading-relaxed text-gray-500 dark:text-gray-400"
                            >
                                {{ theme.description }}
                            </p>
                            <div
                                class="mt-2 flex items-center gap-3 text-xs text-gray-400 dark:text-gray-500"
                            >
                                <span>v{{ theme.version }}</span>
                                <span
                                    class="h-1 w-1 rounded-full bg-gray-300 dark:bg-gray-600"
                                ></span>
                                <span>{{
                                    $t('by {author}', { author: theme.author })
                                }}</span>
                            </div>
                        </div>

                        <div
                            class="flex flex-wrap gap-2 border-t border-gray-100 pt-3 dark:border-gray-700"
                        >
                            <a
                                href="/admin/appearance/themes"
                                class="inline-flex items-center gap-1.5 rounded-lg border border-gray-200 bg-gray-50 px-3 py-1.5 text-xs font-medium text-gray-700 transition-colors hover:bg-gray-100 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-300 dark:hover:bg-gray-700"
                            >
                                <Settings2 class="h-3.5 w-3.5" />
                                {{ $t('Manage Themes') }}
                            </a>
                            <a
                                href="/"
                                target="_blank"
                                class="inline-flex items-center gap-1.5 rounded-lg border border-gray-200 bg-gray-50 px-3 py-1.5 text-xs font-medium text-gray-700 transition-colors hover:bg-gray-100 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-300 dark:hover:bg-gray-700"
                            >
                                <ExternalLink class="h-3.5 w-3.5" />
                                {{ $t('Preview Storefront') }}
                            </a>
                            <button
                                v-if="hasThemeData"
                                @click="showImportDialog = true"
                                type="button"
                                class="inline-flex items-center gap-1.5 rounded-lg border border-gray-200 bg-gray-50 px-3 py-1.5 text-xs font-medium text-gray-700 transition-colors hover:bg-gray-100 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-300 dark:hover:bg-gray-700"
                            >
                                <Download class="h-3.5 w-3.5" />
                                {{ $t('Import Demo Data') }}
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Homepage Layout Status -->
            <div
                v-if="
                    homepageEditor.showPublishedBanner ||
                    homepageEditor.showImportLayout
                "
            >
                <!-- Published / native homepage -->
                <div
                    v-if="homepageEditor.showPublishedBanner"
                    class="flex flex-col justify-between gap-4 rounded-2xl border border-green-200 bg-green-50 px-5 py-4 sm:flex-row sm:items-center dark:border-green-800/60 dark:bg-green-900/20"
                >
                    <div class="flex items-center gap-3">
                        <div
                            class="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-xl bg-green-100 dark:bg-green-900/50"
                        >
                            <CheckCircle
                                class="h-5 w-5 text-green-600 dark:text-green-400"
                            />
                        </div>
                        <div>
                            <p
                                class="text-sm font-semibold text-green-900 dark:text-green-200"
                            >
                                {{ homepageEditor.bannerTitle }}
                            </p>
                            <p
                                class="mt-0.5 text-xs text-green-700 dark:text-green-400"
                            >
                                {{ homepageEditor.bannerDescription }}
                            </p>
                        </div>
                    </div>
                    <button
                        v-if="homepageEditor.mode === 'native'"
                        type="button"
                        @click="activeTab = 'features'"
                        class="inline-flex flex-shrink-0 items-center gap-2 rounded-xl border border-green-300 bg-white px-4 py-2 text-sm font-medium text-green-700 transition-colors hover:bg-green-50 dark:border-green-700 dark:bg-green-950/40 dark:text-green-300 dark:hover:bg-green-900/40"
                    >
                        <Wand2 class="h-4 w-4" />
                        {{ homepageEditor.editorLabel }}
                        <ChevronRight class="h-3.5 w-3.5 opacity-60" />
                    </button>
                    <a
                        v-else
                        :href="homepageEditor.editorUrl"
                        class="inline-flex flex-shrink-0 items-center gap-2 rounded-xl border border-green-300 bg-white px-4 py-2 text-sm font-medium text-green-700 transition-colors hover:bg-green-50 dark:border-green-700 dark:bg-green-950/40 dark:text-green-300 dark:hover:bg-green-900/40"
                    >
                        <Wand2 class="h-4 w-4" />
                        {{ homepageEditor.editorLabel }}
                        <ChevronRight class="h-3.5 w-3.5 opacity-60" />
                    </a>
                </div>

                <!-- Not published -->
                <div
                    v-else-if="homepageEditor.showImportLayout"
                    class="flex flex-col justify-between gap-4 rounded-2xl border border-amber-200 bg-amber-50 px-5 py-4 sm:flex-row sm:items-center dark:border-amber-800/60 dark:bg-amber-900/20"
                >
                    <div class="flex items-center gap-3">
                        <div
                            class="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-xl bg-amber-100 dark:bg-amber-900/50"
                        >
                            <LayoutTemplate
                                class="h-5 w-5 text-amber-600 dark:text-amber-400"
                            />
                        </div>
                        <div>
                            <p
                                class="text-sm font-semibold text-amber-900 dark:text-amber-200"
                            >
                                {{ $t('No Homepage Layout') }}
                            </p>
                            <p
                                class="mt-0.5 text-xs text-amber-700 dark:text-amber-400"
                            >
                                {{
                                    $t(
                                        'Your homepage has no published layout. Import the demo layout to get started instantly.',
                                    )
                                }}
                            </p>
                        </div>
                    </div>
                    <button
                        @click="importLayout"
                        :disabled="importingLayout"
                        class="inline-flex flex-shrink-0 items-center gap-2 rounded-xl bg-amber-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:bg-amber-700 focus:ring-2 focus:ring-amber-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 dark:focus:ring-offset-gray-900"
                    >
                        <svg
                            v-if="importingLayout"
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
                        <Layers v-else class="h-4 w-4" />
                        {{
                            importingLayout
                                ? $t('Importing…')
                                : $t('Import Demo Layout')
                        }}
                    </button>
                </div>
            </div>

            <!-- Settings Tabs -->
            <form @submit.prevent="saveSettings" novalidate>
                <div
                    class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <!-- Tab nav -->
                    <div class="border-b border-gray-200 dark:border-gray-700">
                        <nav
                            class="scrollbar-none flex overflow-x-auto px-4 sm:px-6"
                            :aria-label="$t('Settings tabs')"
                        >
                            <button
                                v-for="tab in tabs"
                                :key="tab.id"
                                type="button"
                                @click="activeTab = tab.id"
                                :class="[
                                    activeTab === tab.id
                                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                                    'group mr-7 inline-flex items-center border-b-2 px-1 py-4 text-sm font-medium whitespace-nowrap transition-colors last:mr-0',
                                ]"
                            >
                                <component
                                    :is="tab.icon"
                                    class="mr-2 h-4 w-4 flex-shrink-0 transition-colors"
                                    :class="
                                        activeTab === tab.id
                                            ? 'text-blue-500 dark:text-blue-400'
                                            : 'text-gray-400 group-hover:text-gray-500'
                                    "
                                />
                                {{ tab.label }}
                            </button>
                        </nav>
                    </div>

                    <!-- Tab panels -->
                    <div class="p-6 sm:p-8">
                        <div
                            v-if="
                                tabs.length === 0 || sectionsForTab.length === 0
                            "
                            class="py-16 text-center"
                        >
                            <Palette
                                class="mx-auto mb-3 h-10 w-10 text-gray-300 dark:text-gray-600"
                            />
                            <p class="text-sm text-gray-400 dark:text-gray-500">
                                {{ $t('No settings available for this tab.') }}
                            </p>
                        </div>
                        <div v-else class="space-y-10">
                            <template
                                v-for="(section, si) in sectionsForTab"
                                :key="section.id"
                            >
                                <div>
                                    <div class="mb-5">
                                        <h3
                                            class="text-sm font-semibold tracking-wide text-gray-900 uppercase dark:text-white"
                                        >
                                            {{ section.title }}
                                        </h3>
                                        <p
                                            class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                        >
                                            {{ section.description }}
                                        </p>
                                    </div>
                                    <div class="space-y-5">
                                        <div
                                            v-for="field in section.fields"
                                            :key="field.id"
                                            class="grid grid-cols-1 items-start gap-x-8 gap-y-1.5 sm:grid-cols-12"
                                        >
                                            <div
                                                class="sm:col-span-4 sm:pt-2.5"
                                            >
                                                <label
                                                    :for="`${section.id}-${field.id}`"
                                                    class="text-sm font-medium text-gray-700 dark:text-gray-200"
                                                >
                                                    {{ field.label }}
                                                </label>
                                                <p
                                                    v-if="field.description"
                                                    class="mt-0.5 text-xs leading-relaxed text-gray-400 dark:text-gray-500"
                                                >
                                                    {{ field.description }}
                                                </p>
                                            </div>
                                            <div class="sm:col-span-8">
                                                <!-- Color -->
                                                <div
                                                    v-if="
                                                        field.type === 'color'
                                                    "
                                                    class="flex items-center gap-2.5"
                                                >
                                                    <input
                                                        :id="`${section.id}-${field.id}`"
                                                        v-model="
                                                            form[
                                                                `${section.id}.${field.id}`
                                                            ]
                                                        "
                                                        type="color"
                                                        class="h-10 w-11 cursor-pointer rounded-lg border border-gray-300 bg-white p-0.5 shadow-sm dark:border-gray-600 dark:bg-gray-700"
                                                    />
                                                    <input
                                                        v-model="
                                                            form[
                                                                `${section.id}.${field.id}`
                                                            ]
                                                        "
                                                        type="text"
                                                        class="flex-1 rounded-lg border border-gray-300 bg-white px-3 py-2 font-mono text-sm text-gray-900 uppercase focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                                        placeholder="#000000"
                                                    />
                                                </div>
                                                <!-- Select -->
                                                <select
                                                    v-else-if="
                                                        field.type === 'select'
                                                    "
                                                    :id="`${section.id}-${field.id}`"
                                                    v-model="
                                                        form[
                                                            `${section.id}.${field.id}`
                                                        ]
                                                    "
                                                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                                >
                                                    <option
                                                        v-for="(
                                                            label, value
                                                        ) in field.options"
                                                        :key="value"
                                                        :value="value"
                                                    >
                                                        {{ label }}
                                                    </option>
                                                </select>
                                                <!-- Number -->
                                                <div
                                                    v-else-if="
                                                        field.type === 'number'
                                                    "
                                                    class="flex items-center gap-2.5"
                                                >
                                                    <input
                                                        :id="`${section.id}-${field.id}`"
                                                        v-model.number="
                                                            form[
                                                                `${section.id}.${field.id}`
                                                            ]
                                                        "
                                                        type="number"
                                                        :min="field.min"
                                                        :max="field.max"
                                                        :step="field.step ?? 1"
                                                        class="w-28 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                                    />
                                                    <span
                                                        v-if="
                                                            field.min !==
                                                                undefined ||
                                                            field.max !==
                                                                undefined
                                                        "
                                                        class="text-xs text-gray-400"
                                                    >
                                                        {{
                                                            field.min ??
                                                            '\u2013'
                                                        }}
                                                        \u2013
                                                        {{
                                                            field.max ??
                                                            '\u221e'
                                                        }}
                                                    </span>
                                                </div>
                                                <!-- Boolean toggle -->
                                                <div
                                                    v-else-if="
                                                        field.type === 'boolean'
                                                    "
                                                    class="flex items-center gap-3 pt-1.5"
                                                >
                                                    <button
                                                        type="button"
                                                        @click="
                                                            form[
                                                                `${section.id}.${field.id}`
                                                            ] =
                                                                !form[
                                                                    `${section.id}.${field.id}`
                                                                ]
                                                        "
                                                        :class="[
                                                            form[
                                                                `${section.id}.${field.id}`
                                                            ]
                                                                ? 'bg-blue-600'
                                                                : 'bg-gray-200 dark:bg-gray-600',
                                                            'relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none dark:focus:ring-offset-gray-800',
                                                        ]"
                                                        role="switch"
                                                        :aria-checked="
                                                            form[
                                                                `${section.id}.${field.id}`
                                                            ]
                                                        "
                                                    >
                                                        <span
                                                            :class="[
                                                                form[
                                                                    `${section.id}.${field.id}`
                                                                ]
                                                                    ? 'translate-x-5'
                                                                    : 'translate-x-0',
                                                                'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200',
                                                            ]"
                                                        />
                                                    </button>
                                                    <span
                                                        class="text-sm text-gray-500 select-none dark:text-gray-400"
                                                    >
                                                        {{
                                                            form[
                                                                `${section.id}.${field.id}`
                                                            ]
                                                                ? $t('Enabled')
                                                                : $t('Disabled')
                                                        }}
                                                    </span>
                                                </div>
                                                <!-- Text -->
                                                <input
                                                    v-else
                                                    :id="`${section.id}-${field.id}`"
                                                    v-model="
                                                        form[
                                                            `${section.id}.${field.id}`
                                                        ]
                                                    "
                                                    type="text"
                                                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                                />
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div
                                    v-if="si < sectionsForTab.length - 1"
                                    class="border-t border-gray-100 dark:border-gray-700/60"
                                />
                            </template>
                        </div>
                    </div>

                    <!-- Save bar -->
                    <div
                        class="flex items-center justify-between gap-4 border-t border-gray-200 bg-gray-50/80 px-6 py-4 dark:border-gray-700 dark:bg-gray-800/50"
                    >
                        <p
                            class="hidden text-xs text-gray-400 sm:block dark:text-gray-500"
                        >
                            {{
                                $t(
                                    "Settings are saved per-theme and won't affect other themes.",
                                )
                            }}
                        </p>
                        <button
                            type="submit"
                            :disabled="processing"
                            class="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-5 py-2 text-sm font-medium text-white shadow-sm transition-all hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            <Save v-if="!processing" class="h-4 w-4" />
                            <svg
                                v-else
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
                            {{
                                processing ? $t('Saving…') : $t('Save Changes')
                            }}
                        </button>
                    </div>
                </div>
            </form>
        </div>

        <!-- Import Demo Data Modal -->
        <Teleport to="body">
            <Transition name="modal">
                <div
                    v-if="showImportDialog"
                    class="fixed inset-0 z-50 flex items-center justify-center p-4"
                >
                    <div
                        class="fixed inset-0 bg-black/50 backdrop-blur-sm"
                        @click="showImportDialog = false"
                    />
                    <div
                        class="relative w-full max-w-md overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-2xl dark:border-gray-700 dark:bg-gray-800"
                    >
                        <div
                            class="flex items-center justify-between border-b border-gray-200 px-6 py-5 dark:border-gray-700"
                        >
                            <div class="flex items-center gap-3">
                                <div
                                    class="flex h-9 w-9 items-center justify-center rounded-xl bg-blue-100 dark:bg-blue-900/30"
                                >
                                    <Download
                                        class="h-4 w-4 text-blue-600 dark:text-blue-400"
                                    />
                                </div>
                                <h3
                                    class="text-base font-semibold text-gray-900 dark:text-white"
                                >
                                    {{ $t('Import Theme Data') }}
                                </h3>
                            </div>
                            <button
                                @click="showImportDialog = false"
                                class="rounded-lg p-1 text-gray-400 transition-colors hover:text-gray-600 dark:hover:text-gray-300"
                            >
                                <X class="h-5 w-5" />
                            </button>
                        </div>
                        <div class="space-y-3.5 px-6 py-5">
                            <p class="text-sm text-gray-600 dark:text-gray-400">
                                {{
                                    $t(
                                        "Import demo content from this theme's data file:",
                                    )
                                }}
                            </p>
                            <ul
                                class="space-y-1.5 text-sm text-gray-500 dark:text-gray-400"
                            >
                                <li
                                    v-for="item in [
                                        $t(
                                            'CMS Blocks (banners, sliders, hero sections)',
                                        ),
                                        $t(
                                            'Navigation Menus (header & footer)',
                                        ),
                                        $t(
                                            'Theme Settings (colors, layout, features)',
                                        ),
                                    ]"
                                    :key="item"
                                    class="flex items-center gap-2"
                                >
                                    <span
                                        class="h-1.5 w-1.5 flex-shrink-0 rounded-full bg-blue-400"
                                    />
                                    {{ item }}
                                </li>
                            </ul>
                            <label
                                class="flex cursor-pointer items-start gap-3 rounded-xl border border-amber-200 bg-amber-50 p-3.5 transition-colors hover:bg-amber-100/70 dark:border-amber-800 dark:bg-amber-900/20 dark:hover:bg-amber-900/30"
                            >
                                <input
                                    v-model="importFresh"
                                    type="checkbox"
                                    class="mt-0.5 h-4 w-4 rounded border-gray-300 text-amber-600 focus:ring-amber-500"
                                />
                                <div>
                                    <p
                                        class="text-sm font-medium text-amber-800 dark:text-amber-300"
                                    >
                                        {{ $t('Fresh Import') }}
                                    </p>
                                    <p
                                        class="mt-0.5 text-xs text-amber-600 dark:text-amber-400"
                                    >
                                        {{
                                            $t(
                                                'Remove existing blocks, menus & settings before importing.',
                                            )
                                        }}
                                    </p>
                                </div>
                            </label>
                            <label
                                v-if="hasProductData"
                                class="flex cursor-pointer items-start gap-3 rounded-xl border p-3.5 transition-colors"
                                :class="
                                    importProducts
                                        ? 'border-red-300 bg-red-50 dark:border-red-800 dark:bg-red-900/20'
                                        : 'border-gray-200 bg-gray-50 hover:bg-gray-100/60 dark:border-gray-700 dark:bg-gray-900/20 dark:hover:bg-gray-900/40'
                                "
                            >
                                <input
                                    v-model="importProducts"
                                    type="checkbox"
                                    class="mt-0.5 h-4 w-4 rounded border-gray-300 text-red-600 focus:ring-red-500"
                                />
                                <div class="min-w-0 flex-1">
                                    <p
                                        class="text-sm font-medium"
                                        :class="
                                            importProducts
                                                ? 'text-red-800 dark:text-red-300'
                                                : 'text-gray-700 dark:text-gray-300'
                                        "
                                    >
                                        <ShoppingCart
                                            class="-mt-0.5 mr-1 inline h-3.5 w-3.5"
                                        />
                                        {{
                                            $t('Include Products & Categories')
                                        }}
                                    </p>
                                    <p
                                        class="mt-0.5 text-xs"
                                        :class="
                                            importProducts
                                                ? 'text-red-600 dark:text-red-400'
                                                : 'text-gray-500 dark:text-gray-400'
                                        "
                                    >
                                        {{
                                            $t(
                                                'Import demo products from the theme data.',
                                            )
                                        }}
                                    </p>
                                    <div
                                        v-if="importProducts"
                                        class="mt-2.5 flex items-start gap-2 rounded-lg border border-red-200 bg-red-100 p-2.5 dark:border-red-700/50 dark:bg-red-900/40"
                                    >
                                        <AlertTriangle
                                            class="mt-0.5 h-3.5 w-3.5 flex-shrink-0 text-red-600 dark:text-red-400"
                                        />
                                        <p
                                            class="text-xs font-medium text-red-700 dark:text-red-300"
                                        >
                                            {{ $t('This will') }}
                                            <strong>{{
                                                $t(
                                                    'delete all existing products and categories',
                                                )
                                            }}</strong
                                            >. {{ $t('Cannot be undone.') }}
                                        </p>
                                    </div>
                                </div>
                            </label>
                        </div>
                        <div
                            class="flex items-center justify-end gap-2.5 border-t border-gray-200 bg-gray-50 px-6 py-4 dark:border-gray-700 dark:bg-gray-800/50"
                        >
                            <button
                                @click="showImportDialog = false"
                                :disabled="importing"
                                class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 disabled:opacity-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                            >
                                {{ $t('Cancel') }}
                            </button>
                            <button
                                @click="importThemeData"
                                :disabled="importing"
                                class="inline-flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium text-white transition-colors disabled:opacity-50"
                                :class="
                                    importProducts
                                        ? 'bg-red-600 hover:bg-red-700'
                                        : importFresh
                                          ? 'bg-amber-600 hover:bg-amber-700'
                                          : 'bg-blue-600 hover:bg-blue-700'
                                "
                            >
                                <svg
                                    v-if="importing"
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
                                <Download v-else class="h-4 w-4" />
                                {{
                                    importing
                                        ? $t('Importing…')
                                        : importProducts
                                          ? $t('Import with Products')
                                          : importFresh
                                            ? $t('Fresh Import')
                                            : $t('Import Data')
                                }}
                            </button>
                        </div>
                    </div>
                </div>
            </Transition>
        </Teleport>
    </AdminLayout>
</template>

<style scoped>
.scrollbar-none {
    scrollbar-width: none;
}
.scrollbar-none::-webkit-scrollbar {
    display: none;
}
.slide-down-enter-active,
.slide-down-leave-active {
    transition: all 0.2s ease;
}
.slide-down-enter-from {
    opacity: 0;
    transform: translateY(-6px);
}
.slide-down-leave-to {
    opacity: 0;
    transform: translateY(-4px);
}
.modal-enter-active {
    transition: opacity 0.2s ease;
}
.modal-enter-active > div:last-child {
    transition:
        transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1),
        opacity 0.2s ease;
}
.modal-leave-active {
    transition: opacity 0.15s ease;
}
.modal-leave-active > div:last-child {
    transition:
        transform 0.15s ease,
        opacity 0.15s ease;
}
.modal-enter-from,
.modal-leave-to {
    opacity: 0;
}
.modal-enter-from > div:last-child,
.modal-leave-to > div:last-child {
    transform: scale(0.95);
    opacity: 0;
}
</style>
