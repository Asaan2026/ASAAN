<script setup lang="ts">
import ConfirmModal from '@/components/Admin/ConfirmModal.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Head, Link, router } from '@inertiajs/vue3';
import {
    ArrowUpCircle,
    CheckCircle2,
    ChevronRight,
    Download,
    LayoutTemplate,
    Monitor,
    Power,
    RefreshCcw,
    Search,
    Settings2,
    Wand2,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Category {
    slug: string;
    label: string;
    sort?: number;
}

interface TemplateType {
    slug: string;
    label: string;
    enabled?: boolean;
}

interface TemplateItem {
    slug: string;
    type: string;
    category: string;
    category_label?: string;
    tags?: string[];
    name: string;
    description: string;
    version: string;
    author?: string;
    author_url?: string | null;
    screenshot_url?: string | null;
    source?: string;
    includes?: string[];
    demo_business_type?: string | null;
    has_demo_layout?: boolean;
    native_homepage?: boolean;
    installed?: boolean;
    is_active?: boolean;
    installed_version?: string | null;
    update_available?: boolean;
    remote_categories?: Array<{ slug: string; name: string }>;
    updated_at?: string | null;
}

interface Props {
    templates: TemplateItem[];
    categories: Category[];
    types: TemplateType[];
    filters: {
        type?: string | null;
        category?: string | null;
        search?: string | null;
    };
    remoteBrowseEnabled?: boolean;
    remoteInstallEnabled?: boolean;
    directoryUrl?: string;
    remoteThemeCount?: number;
    remoteProbe?: {
        ok: boolean;
        theme_count: number;
        category_count: number;
        status: number | null;
        error: string | null;
    };
}

const props = defineProps<Props>();

const { t } = useI18nStore();

const isSyncing = ref(false);
const installing = ref<Record<string, boolean>>({});
const activating = ref<Record<string, boolean>>({});
const searchQuery = ref(props.filters.search || '');
const selectedCategory = ref(props.filters.category || '');
const selectedType = ref(props.filters.type || 'storefront');

const confirmModal = ref({
    show: false,
    title: '',
    message: '',
    confirmText: t('Confirm'),
    variant: 'primary' as 'primary' | 'warning' | 'danger',
    onConfirm: () => {},
});

const openConfirm = (options: {
    title: string;
    message: string;
    confirmText?: string;
    variant?: 'primary' | 'warning' | 'danger';
    onConfirm: () => void;
}) => {
    confirmModal.value = {
        show: true,
        title: options.title,
        message: options.message,
        confirmText: options.confirmText ?? t('Confirm'),
        variant: options.variant ?? 'primary',
        onConfirm: options.onConfirm,
    };
};

const handleConfirm = () => {
    confirmModal.value.onConfirm();
    confirmModal.value.show = false;
};

const categoryLabel = (template: TemplateItem) =>
    template.category_label ||
    props.categories.find((item) => item.slug === template.category)?.label ||
    template.category;

const filteredTemplates = computed(() => props.templates);

const builderUrl = (template: TemplateItem) =>
    template.native_homepage
        ? '/admin/appearance?tab=features'
        : '/admin/content/pages';

const applyFilters = () => {
    router.get(
        '/admin/appearance/template-zone',
        {
            type: selectedType.value || undefined,
            category: selectedCategory.value || undefined,
            search: searchQuery.value || undefined,
        },
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
};

const syncCatalog = () => {
    isSyncing.value = true;
    router.post(
        '/admin/appearance/template-zone/sync',
        {},
        {
            preserveScroll: true,
            onFinish: () => {
                isSyncing.value = false;
            },
        },
    );
};

const isRemoteTheme = (template: TemplateItem) => template.source === 'remote';

const canInstallRemote = (template: TemplateItem) =>
    !isRemoteTheme(template) || props.remoteInstallEnabled !== false;

const runInstall = (template: TemplateItem) => {
    const remote = isRemoteTheme(template);

    installing.value[template.slug] = true;
    router.post(
        `/admin/appearance/template-zone/${encodeURIComponent(template.slug)}/install`,
        {
            import_demo_products: false,
            import_layout: !remote && !!template.has_demo_layout,
            activate: true,
        },
        {
            preserveScroll: true,
            onFinish: () => {
                installing.value[template.slug] = false;
            },
        },
    );
};

const runActivate = (template: TemplateItem) => {
    activating.value[template.slug] = true;
    router.post(
        `/admin/appearance/themes/${encodeURIComponent(template.slug)}/activate`,
        {},
        {
            preserveScroll: true,
            onFinish: () => {
                activating.value[template.slug] = false;
            },
        },
    );
};

const installTemplate = (template: TemplateItem) => {
    if (installing.value[template.slug]) return;

    if (!canInstallRemote(template)) {
        openConfirm({
            title: t('API key required'),
            message: t(
                'Set CARTXIS_THEME_API_KEY in your .env file to install themes from the Cartxis directory. It is auto-generated when you run php artisan cartxis:install.',
            ),
            confirmText: t('Got it'),
            variant: 'warning',
            onConfirm: () => {},
        });
        return;
    }

    const remote = isRemoteTheme(template);

    openConfirm({
        title: remote
            ? t('Install from Cartxis Directory')
            : t('Install theme'),
        message: remote
            ? t(
                  'Install "{name}" from the Cartxis theme directory? The package will be downloaded securely and activated on your store.',
                  { name: template.name },
              )
            : t(
                  'Install "{name}" into your store and activate it as the storefront theme?',
                  { name: template.name },
              ),
        confirmText: t('Install & Activate'),
        variant: 'primary',
        onConfirm: () => runInstall(template),
    });
};

const activateTemplate = (template: TemplateItem) => {
    if (activating.value[template.slug]) return;

    openConfirm({
        title: t('Activate theme'),
        message: t(
            'Activate "{name}" as your storefront theme? Your live store appearance will switch to this theme.',
            { name: template.name },
        ),
        confirmText: t('Activate'),
        variant: 'primary',
        onConfirm: () => runActivate(template),
    });
};

const downloadTemplate = (slug: string) => {
    window.location.href = `/admin/appearance/template-zone/${encodeURIComponent(slug)}/download?source=catalog`;
};
</script>

<template>
    <Head :title="$t('Browse Themes')" />

    <AdminLayout :title="$t('Browse Themes')">
        <div class="space-y-6">
            <div
                class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between"
            >
                <div>
                    <h1
                        class="flex items-center gap-2 text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        <LayoutTemplate class="h-7 w-7 text-blue-600" />
                        {{ $t('Browse Themes') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        {{
                            $t(
                                'Search the Cartxis theme directory, preview storefront themes, and install with one click.',
                            )
                        }}
                    </p>
                </div>

                <div class="flex flex-wrap gap-2">
                    <Link
                        href="/admin/appearance/themes"
                        class="inline-flex items-center rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
                    >
                        {{ $t('Installed Themes') }}
                    </Link>
                    <button
                        @click="syncCatalog"
                        :disabled="isSyncing"
                        class="inline-flex items-center gap-2 rounded-xl bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
                    >
                        <RefreshCcw
                            class="h-4 w-4"
                            :class="isSyncing ? 'animate-spin' : ''"
                        />
                        {{ $t('Sync Catalog') }}
                    </button>
                </div>
            </div>

            <div
                v-if="remoteBrowseEnabled === false"
                class="rounded-xl border border-amber-200 bg-amber-50 p-4 dark:border-amber-800 dark:bg-amber-900/20"
            >
                <p class="text-sm text-amber-900 dark:text-amber-100">
                    {{ $t('Theme directory URL is not configured. Set') }}
                    <code class="font-mono text-xs"
                        >CARTXIS_THEME_DIRECTORY_URL</code
                    >
                    {{ $t('in your') }}
                    <code class="font-mono text-xs">.env</code>
                    {{ $t('or run') }}
                    <code class="font-mono text-xs"
                        >php artisan cartxis:install</code
                    >
                    {{ $t('to browse themes from cartxis.com.') }}
                </p>
            </div>

            <div
                v-else-if="remoteProbe && !remoteProbe.ok"
                class="rounded-xl border border-red-200 bg-red-50 p-4 dark:border-red-800 dark:bg-red-900/20"
            >
                <p class="text-sm text-red-900 dark:text-red-100">
                    {{ $t('Could not reach the theme directory at') }}
                    <code class="font-mono text-xs">{{ directoryUrl }}</code
                    >.
                    {{
                        remoteProbe.error ||
                        $t(
                            'Check that cartxis-home is running and the URL includes /api.',
                        )
                    }}
                </p>
            </div>

            <div
                v-else-if="
                    remoteProbe?.ok &&
                    remoteProbe.theme_count > 0 &&
                    filteredTemplates.length === 0
                "
                class="rounded-xl border border-amber-200 bg-amber-50 p-4 dark:border-amber-800 dark:bg-amber-900/20"
            >
                <p class="text-sm text-amber-900 dark:text-amber-100">
                    {{
                        $t(
                            'The directory reports {count} theme(s) but none matched the current filters.',
                            { count: remoteProbe.theme_count },
                        )
                    }}
                    {{ $t('Try') }} <strong>{{ $t('All Templates') }}</strong>
                    {{ $t('or click') }}
                    <strong>{{ $t('Sync Catalog') }}</strong
                    >.
                </p>
            </div>

            <div
                v-else-if="remoteProbe?.ok && remoteProbe.theme_count === 0"
                class="rounded-xl border border-amber-200 bg-amber-50 p-4 dark:border-amber-800 dark:bg-amber-900/20"
            >
                <p class="text-sm text-amber-900 dark:text-amber-100">
                    {{ $t('Connected to') }}
                    <code class="font-mono text-xs">{{ directoryUrl }}</code>
                    {{ $t('but no themes are published there yet.') }}
                </p>
            </div>

            <div
                v-else-if="remoteInstallEnabled === false"
                class="rounded-xl border border-amber-200 bg-amber-50 p-4 dark:border-amber-800 dark:bg-amber-900/20"
            >
                <p class="text-sm text-amber-900 dark:text-amber-100">
                    {{
                        $t(
                            'You can browse the Cartxis theme directory, but one-click installs require',
                        )
                    }}
                    <code class="font-mono text-xs">CARTXIS_THEME_API_KEY</code>
                    {{ $t('in your') }}
                    <code class="font-mono text-xs">.env</code>
                    {{ $t('(auto-generated during') }}
                    <code class="font-mono text-xs">cartxis:install</code>).
                </p>
            </div>

            <div
                v-else
                class="rounded-xl border border-blue-200 bg-blue-50 p-4 dark:border-blue-800 dark:bg-blue-900/20"
            >
                <p class="text-sm text-blue-900 dark:text-blue-100">
                    {{
                        $t(
                            'Themes from the official Cartxis directory install securely — packages are downloaded server-side and activated in one step.',
                        )
                    }}
                </p>
            </div>

            <div class="flex flex-col gap-6 xl:flex-row">
                <aside class="shrink-0 space-y-4 xl:w-64">
                    <div
                        class="rounded-xl border border-gray-200 bg-white p-4 dark:border-gray-800 dark:bg-gray-900"
                    >
                        <h2
                            class="mb-3 text-xs font-semibold tracking-wider text-gray-500 uppercase"
                        >
                            {{ $t('Categories') }}
                        </h2>
                        <div class="space-y-1">
                            <button
                                @click="
                                    selectedCategory = '';
                                    applyFilters();
                                "
                                class="w-full rounded-lg px-3 py-2 text-left text-sm transition-colors"
                                :class="
                                    !selectedCategory
                                        ? 'bg-blue-50 font-medium text-blue-700'
                                        : 'text-gray-700 hover:bg-gray-50'
                                "
                            >
                                {{ $t('All Templates') }}
                            </button>
                            <button
                                v-for="category in categories"
                                :key="category.slug"
                                @click="
                                    selectedCategory = category.slug;
                                    applyFilters();
                                "
                                class="w-full rounded-lg px-3 py-2 text-left text-sm transition-colors"
                                :class="
                                    selectedCategory === category.slug
                                        ? 'bg-blue-50 font-medium text-blue-700'
                                        : 'text-gray-700 hover:bg-gray-50'
                                "
                            >
                                {{ category.label }}
                            </button>
                        </div>
                    </div>

                    <div
                        class="rounded-xl border border-gray-200 bg-white p-4 dark:border-gray-800 dark:bg-gray-900"
                    >
                        <h2
                            class="mb-3 text-xs font-semibold tracking-wider text-gray-500 uppercase"
                        >
                            {{ $t('Template Type') }}
                        </h2>
                        <div class="space-y-1">
                            <button
                                v-for="type in types"
                                :key="type.slug"
                                @click="
                                    selectedType = type.slug;
                                    applyFilters();
                                "
                                :disabled="!type.enabled"
                                class="w-full rounded-lg px-3 py-2 text-left text-sm transition-colors disabled:cursor-not-allowed disabled:opacity-50"
                                :class="
                                    selectedType === type.slug
                                        ? 'bg-blue-50 font-medium text-blue-700'
                                        : 'text-gray-700 hover:bg-gray-50'
                                "
                            >
                                {{ type.label }}
                                <span
                                    v-if="!type.enabled"
                                    class="text-xs text-gray-400"
                                >
                                    {{ $t('(soon)') }}</span
                                >
                            </button>
                        </div>
                    </div>
                </aside>

                <div class="flex-1 space-y-4">
                    <div class="relative">
                        <Search
                            class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                        />
                        <input
                            v-model="searchQuery"
                            @keyup.enter="applyFilters"
                            type="search"
                            :placeholder="$t('Search themes...')"
                            class="w-full rounded-xl border border-gray-200 bg-white py-2.5 pr-4 pl-10 text-sm dark:border-gray-700 dark:bg-gray-900"
                        />
                    </div>

                    <div
                        v-if="filteredTemplates.length === 0"
                        class="rounded-xl border border-dashed border-gray-300 bg-white py-16 text-center dark:bg-gray-900"
                    >
                        <Monitor class="mx-auto mb-3 h-12 w-12 text-gray-300" />
                        <h3
                            class="text-lg font-medium text-gray-900 dark:text-white"
                        >
                            {{ $t('No themes found') }}
                        </h3>
                        <p class="mt-1 text-sm text-gray-500">
                            {{
                                $t(
                                    'Try another category or clear your search filters.',
                                )
                            }}
                        </p>
                    </div>

                    <div v-else class="grid grid-cols-1 gap-6 md:grid-cols-2">
                        <article
                            v-for="template in filteredTemplates"
                            :key="template.slug"
                            class="flex flex-col overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm transition-shadow hover:shadow-md dark:border-gray-800 dark:bg-gray-900"
                        >
                            <div class="relative aspect-video bg-gray-100">
                                <img
                                    v-if="template.screenshot_url"
                                    :src="template.screenshot_url"
                                    :alt="template.name"
                                    class="h-full w-full object-cover object-top"
                                />
                                <div
                                    v-else
                                    class="flex h-full w-full items-center justify-center"
                                >
                                    <Monitor class="h-12 w-12 text-gray-300" />
                                </div>

                                <div
                                    class="absolute inset-x-0 top-0 flex items-start justify-between gap-2 p-3"
                                >
                                    <span
                                        class="inline-flex max-w-[55%] truncate rounded-full bg-white/95 px-2.5 py-1 text-xs font-semibold text-gray-700 shadow-sm ring-1 ring-black/5"
                                    >
                                        {{ categoryLabel(template) }}
                                    </span>

                                    <div
                                        class="flex shrink-0 flex-col items-end gap-1.5"
                                    >
                                        <span
                                            v-if="isRemoteTheme(template)"
                                            class="inline-flex items-center gap-1 rounded-full bg-purple-100 px-2.5 py-1 text-xs font-semibold text-purple-800 ring-1 ring-purple-600/10"
                                        >
                                            {{ $t('Cartxis Directory') }}
                                        </span>
                                        <span
                                            v-if="template.is_active"
                                            class="inline-flex items-center gap-1 rounded-full bg-blue-600 px-2.5 py-1 text-xs font-semibold text-white shadow-sm"
                                        >
                                            {{ $t('Active') }}
                                        </span>
                                        <span
                                            v-else-if="template.installed"
                                            class="inline-flex items-center gap-1 rounded-full bg-green-100 px-2.5 py-1 text-xs font-semibold text-green-800 ring-1 ring-green-600/10"
                                        >
                                            <CheckCircle2 class="h-3 w-3" />
                                            {{ $t('Installed') }}
                                        </span>
                                        <span
                                            v-if="template.update_available"
                                            class="inline-flex items-center gap-1 rounded-full bg-amber-100 px-2.5 py-1 text-xs font-semibold text-amber-800 ring-1 ring-amber-600/10"
                                        >
                                            <ArrowUpCircle class="h-3 w-3" />
                                            {{ $t('Update') }}
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <div class="flex flex-1 flex-col space-y-3 p-5">
                                <div>
                                    <h3
                                        class="text-lg font-bold text-gray-900 dark:text-white"
                                    >
                                        {{ template.name }}
                                    </h3>
                                    <p class="mt-1 text-xs text-gray-500">
                                        v{{ template.version }} ·
                                        {{ template.author }}
                                        <span
                                            v-if="
                                                template.installed &&
                                                template.installed_version
                                            "
                                            class="text-green-600"
                                        >
                                            · {{ $t('installed v')
                                            }}{{ template.installed_version }}
                                        </span>
                                    </p>
                                </div>
                                <p
                                    class="line-clamp-3 flex-1 text-sm text-gray-600 dark:text-gray-300"
                                >
                                    {{ template.description }}
                                </p>

                                <div
                                    class="flex flex-wrap gap-2 border-t border-gray-100 pt-2 dark:border-gray-800"
                                >
                                    <template
                                        v-if="
                                            template.installed &&
                                            !template.update_available
                                        "
                                    >
                                        <button
                                            v-if="!template.is_active"
                                            @click="activateTemplate(template)"
                                            :disabled="
                                                activating[template.slug]
                                            "
                                            class="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
                                        >
                                            <Power class="h-4 w-4" />
                                            {{
                                                activating[template.slug]
                                                    ? $t('Activating…')
                                                    : $t('Activate')
                                            }}
                                        </button>
                                        <Link
                                            v-if="template.is_active"
                                            href="/admin/appearance"
                                            class="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
                                        >
                                            <Settings2 class="h-4 w-4" />
                                            {{ $t('Customize') }}
                                        </Link>
                                        <Link
                                            v-if="template.is_active"
                                            :href="builderUrl(template)"
                                            class="inline-flex items-center gap-2 rounded-lg border border-green-200 bg-green-50 px-4 py-2 text-sm font-medium text-green-700 hover:bg-green-100"
                                        >
                                            <Wand2 class="h-4 w-4" />
                                            {{ $t('Open Page Builder') }}
                                            <ChevronRight
                                                class="h-3.5 w-3.5 opacity-60"
                                            />
                                        </Link>
                                    </template>

                                    <button
                                        v-else
                                        @click="installTemplate(template)"
                                        :disabled="
                                            installing[template.slug] ||
                                            (isRemoteTheme(template) &&
                                                !canInstallRemote(template))
                                        "
                                        class="inline-flex items-center rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
                                    >
                                        {{
                                            template.installed &&
                                            template.update_available
                                                ? $t('Update')
                                                : $t('Install Now')
                                        }}
                                    </button>

                                    <button
                                        v-if="!isRemoteTheme(template)"
                                        @click="downloadTemplate(template.slug)"
                                        class="inline-flex items-center gap-2 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
                                    >
                                        <Download class="h-4 w-4" />
                                        {{ $t('Download') }}
                                    </button>
                                    <Link
                                        :href="`/admin/appearance/template-zone/${encodeURIComponent(template.slug)}`"
                                        class="inline-flex items-center rounded-lg px-4 py-2 text-sm font-medium text-blue-700 hover:bg-blue-50"
                                    >
                                        {{ $t('Details') }}
                                    </Link>
                                </div>
                            </div>
                        </article>
                    </div>
                </div>
            </div>
        </div>

        <ConfirmModal
            v-model:show="confirmModal.show"
            :title="confirmModal.title"
            :message="confirmModal.message"
            :confirm-text="confirmModal.confirmText"
            :variant="confirmModal.variant"
            @confirm="handleConfirm"
        />
    </AdminLayout>
</template>
