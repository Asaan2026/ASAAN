<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Head, useForm, usePage } from '@inertiajs/vue3';
import {
    Bot,
    Brain,
    ChevronDown,
    ChevronRight,
    Cpu,
    Database,
    Eye,
    EyeOff,
    Key,
    Plus,
    Save,
    Server,
    Terminal,
    Trash2,
} from 'lucide-vue-next';
import { computed, ref, watch } from 'vue';

interface ProviderConfig {
    name: string;
    type: string;
    base_url?: string;
    api_key?: string;
    org_id?: string;
    project_id?: string;
    headers?: Record<string, string>;
    is_default?: boolean;
}

interface ModelConfig {
    name: string;
    provider: string;
    mode?: string;
    max_tokens?: number | null;
    is_default?: boolean;
}

interface AgentConfig {
    name: string;
    provider: string;
    model: string;
    temperature?: number | null;
    max_tokens?: number | null;
    system_prompt?: string;
    is_default?: boolean;
    is_system?: boolean;
}

interface Props {
    settings?: {
        ai_enabled?: boolean;
        default_provider?: string;
        default_agent?: string;
        product_description_agent?: string;
        price_comparison_agent?: string;
        providers?: ProviderConfig[];
        models?: ModelConfig[];
        agents?: AgentConfig[];
    };
}

const props = withDefaults(defineProps<Props>(), {
    settings: () => ({}),
});

const page = usePage();
const { t } = useI18nStore();
const errors = computed(() => page.props.errors as Record<string, string>);

const form = useForm({
    ai_enabled: props.settings.ai_enabled ?? false,
    default_provider: props.settings.default_provider ?? '',
    default_agent: props.settings.default_agent ?? '',
    product_description_agent: props.settings.product_description_agent ?? '',
    price_comparison_agent: props.settings.price_comparison_agent ?? '',
    providers: (props.settings.providers ?? []) as ProviderConfig[],
    models: (props.settings.models ?? []) as ModelConfig[],
    agents: (props.settings.agents ?? []) as AgentConfig[],
});

const showApiKeys = ref<Record<number, boolean>>({});
const activeTab = ref<'access' | 'providers' | 'models' | 'agents'>('access');
const expandedAgentIndex = ref<number | null>(0);

const providerOptions = computed(() =>
    form.providers.map((p) => p.name).filter(Boolean),
);
const agentOptions = computed(() =>
    form.agents.map((a) => a.name).filter(Boolean),
);

const tabs = [
    { id: 'providers', name: t('Providers'), icon: Server },
    { id: 'models', name: t('Models'), icon: Cpu },
    { id: 'agents', name: t('AI Agents'), icon: Bot },
    { id: 'access', name: t('Access & Defaults'), icon: Key },
];

const toggleApiKeyVisibility = (index: number) => {
    showApiKeys.value[index] = !showApiKeys.value[index];
};

const getModelsForProvider = (provider: string) => {
    return form.models
        .filter((model) => !provider || model.provider === provider)
        .map((model) => model.name)
        .filter(Boolean);
};

const addProvider = () => {
    form.providers.push({
        name: '',
        type: 'openai',
        base_url: '',
        api_key: '',
        org_id: '',
        project_id: '',
        headers: {},
        is_default: false,
    });
};

const removeProvider = (index: number) => {
    form.providers.splice(index, 1);
};

const addModel = () => {
    form.models.push({
        name: '',
        provider: form.default_provider || (providerOptions.value[0] ?? ''),
        mode: 'text',
        max_tokens: null,
        is_default: false,
    });
};

const removeModel = (index: number) => {
    form.models.splice(index, 1);
};

const addAgent = () => {
    const provider = form.default_provider || (providerOptions.value[0] ?? '');
    const model = provider ? getModelsForProvider(provider)[0] || '' : '';

    form.agents.push({
        name: '',
        provider,
        model,
        temperature: 0.7,
        max_tokens: 1024,
        system_prompt: '',
    });

    expandedAgentIndex.value = form.agents.length - 1;
};

const removeAgent = (index: number) => {
    if (form.agents[index]?.is_system) {
        showToast(t('System agents cannot be deleted.'), 'warning');
        return;
    }

    form.agents.splice(index, 1);

    if (expandedAgentIndex.value === index) {
        expandedAgentIndex.value = null;
    } else if (
        expandedAgentIndex.value !== null &&
        expandedAgentIndex.value > index
    ) {
        expandedAgentIndex.value -= 1;
    }
};

const toggleAgentAccordion = (index: number) => {
    expandedAgentIndex.value =
        expandedAgentIndex.value === index ? null : index;
};

watch(
    () =>
        form.agents.map((agent) => ({
            provider: agent.provider,
            model: agent.model,
        })),
    (agents) => {
        agents.forEach((agentState, index) => {
            const availableModels = getModelsForProvider(agentState.provider);

            if (availableModels.length === 0) {
                if (form.agents[index].model) {
                    form.agents[index].model = '';
                }
                return;
            }

            if (!availableModels.includes(agentState.model)) {
                form.agents[index].model = availableModels[0];
            }
        });
    },
    { deep: true },
);

const showToast = (
    message: string,
    type: 'success' | 'error' | 'warning' | 'info' = 'success',
) => {
    window.dispatchEvent(
        new CustomEvent('show-toast', {
            detail: { message, type },
        }),
    );
};

const save = () => {
    const section = activeTab.value;
    if (section === 'agents') {
        form.agents = form.agents.map((agent) => {
            const fallbackProvider =
                form.default_provider || providerOptions.value[0] || '';
            const provider = agent.provider || fallbackProvider;
            const model =
                agent.model ||
                (provider ? getModelsForProvider(provider)[0] || '' : '');
            return {
                ...agent,
                provider,
                model,
            };
        });
    }

    const payload = (() => {
        switch (section) {
            case 'providers':
                return { providers: form.providers };
            case 'models':
                return { models: form.models };
            case 'agents':
                return { agents: form.agents };
            case 'access':
                return {
                    ai_enabled: form.ai_enabled,
                    default_provider: form.default_provider,
                    default_agent: form.default_agent,
                    product_description_agent: form.product_description_agent,
                    price_comparison_agent: form.price_comparison_agent,
                };
            default:
                return {};
        }
    })();

    form.transform(() => payload).post('/admin/settings/ai', {
        preserveScroll: true,
        onSuccess: () => {
            showToast(t('AI settings saved successfully.'), 'success');
        },
        onError: () => {
            const firstError = Object.values(form.errors || {})[0];
            showToast(
                firstError ||
                    t('Failed to save AI settings. Please try again.'),
                'error',
            );
        },
    });
};
</script>

<template>
    <Head :title="$t('AI Settings')" />

    <AdminLayout :title="$t('AI Settings')">
        <div class="space-y-6">
            <!-- Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h2
                        class="bg-gradient-to-r from-gray-900 to-gray-600 bg-clip-text text-2xl font-bold text-transparent dark:from-white dark:to-gray-300"
                    >
                        {{ $t('AI Configuration') }}
                    </h2>
                    <p
                        class="mt-1 flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400"
                    >
                        <Brain class="h-4 w-4" />
                        {{ $t('Manage AI providers, models, and agents') }}
                    </p>
                </div>
            </div>

            <div
                class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <form @submit.prevent="save">
                    <!-- Tabs -->
                    <div class="border-b border-gray-200 dark:border-gray-700">
                        <nav
                            class="flex overflow-x-auto"
                            :aria-label="$t('Tabs')"
                        >
                            <button
                                v-for="tab in tabs"
                                :key="tab.id"
                                type="button"
                                @click="activeTab = tab.id as any"
                                :class="[
                                    'flex items-center gap-2 border-b-2 px-6 py-4 text-sm font-medium whitespace-nowrap transition-colors',
                                    activeTab === tab.id
                                        ? 'border-blue-500 bg-blue-50/50 text-blue-600 dark:bg-blue-900/10 dark:text-blue-400'
                                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                                ]"
                            >
                                <component :is="tab.icon" class="h-4 w-4" />
                                {{ tab.name }}
                            </button>
                        </nav>
                    </div>

                    <!-- Content -->
                    <div class="p-6">
                        <!-- Access & Defaults Tab -->
                        <div v-show="activeTab === 'access'" class="space-y-8">
                            <div
                                class="flex items-center justify-between rounded-xl border border-gray-100 bg-gray-50 p-4 dark:border-gray-700 dark:bg-gray-700/30"
                            >
                                <div>
                                    <h3
                                        class="text-base font-semibold text-gray-900 dark:text-white"
                                    >
                                        {{ $t('AI Features') }}
                                    </h3>
                                    <p
                                        class="text-sm text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t(
                                                'Enable or disable AI capabilities globally across the platform.',
                                            )
                                        }}
                                    </p>
                                </div>
                                <div class="flex items-center">
                                    <label
                                        class="relative inline-flex cursor-pointer items-center"
                                    >
                                        <input
                                            type="checkbox"
                                            v-model="form.ai_enabled"
                                            class="peer sr-only"
                                        />
                                        <div
                                            class="peer h-6 w-11 rounded-full bg-gray-200 peer-checked:bg-blue-600 peer-focus:ring-4 peer-focus:ring-blue-300 peer-focus:outline-none after:absolute after:top-[2px] after:left-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-gray-300 after:bg-white after:transition-all after:content-[''] peer-checked:after:translate-x-full peer-checked:after:border-white dark:border-gray-600 dark:bg-gray-700 dark:peer-focus:ring-blue-800"
                                        ></div>
                                        <span
                                            class="ml-3 text-sm font-medium text-gray-900 dark:text-gray-300"
                                            >{{
                                                form.ai_enabled
                                                    ? $t('Enabled')
                                                    : $t('Disabled')
                                            }}</span
                                        >
                                    </label>
                                </div>
                            </div>

                            <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                                <div>
                                    <label
                                        class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Default Provider') }}</label
                                    >
                                    <div class="relative">
                                        <select
                                            v-model="form.default_provider"
                                            class="w-full appearance-none rounded-xl border border-gray-300 bg-white py-2.5 pr-4 pl-10 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                        >
                                            <option value="">
                                                {{ $t('Select provider') }}
                                            </option>
                                            <option
                                                v-for="provider in providerOptions"
                                                :key="provider"
                                                :value="provider"
                                            >
                                                {{ provider }}
                                            </option>
                                        </select>
                                        <Server
                                            class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                        />
                                    </div>
                                </div>

                                <div>
                                    <label
                                        class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{
                                            $t('Default Generic Agent')
                                        }}</label
                                    >
                                    <div class="relative">
                                        <select
                                            v-model="form.default_agent"
                                            class="w-full appearance-none rounded-xl border border-gray-300 bg-white py-2.5 pr-4 pl-10 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                        >
                                            <option value="">
                                                {{ $t('Select agent') }}
                                            </option>
                                            <option
                                                v-for="agent in agentOptions"
                                                :key="agent"
                                                :value="agent"
                                            >
                                                {{ agent }}
                                            </option>
                                        </select>
                                        <Bot
                                            class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                        />
                                    </div>
                                </div>

                                <div>
                                    <label
                                        class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{
                                            $t('Product Description Agent')
                                        }}</label
                                    >
                                    <div class="relative">
                                        <select
                                            v-model="
                                                form.product_description_agent
                                            "
                                            class="w-full appearance-none rounded-xl border border-gray-300 bg-white py-2.5 pr-4 pl-10 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                        >
                                            <option value="">
                                                {{ $t('Select agent') }}
                                            </option>
                                            <option
                                                v-for="agent in agentOptions"
                                                :key="agent"
                                                :value="agent"
                                            >
                                                {{ agent }}
                                            </option>
                                        </select>
                                        <Terminal
                                            class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                        />
                                    </div>
                                    <p
                                        class="mt-1.5 text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t(
                                                'Helper agent for generating product descriptions.',
                                            )
                                        }}
                                    </p>
                                </div>

                                <div>
                                    <label
                                        class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{
                                            $t('Price Comparison Agent')
                                        }}</label
                                    >
                                    <div class="relative">
                                        <select
                                            v-model="
                                                form.price_comparison_agent
                                            "
                                            class="w-full appearance-none rounded-xl border border-gray-300 bg-white py-2.5 pr-4 pl-10 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                        >
                                            <option value="">
                                                {{ $t('Select agent') }}
                                            </option>
                                            <option
                                                v-for="agent in agentOptions"
                                                :key="agent"
                                                :value="agent"
                                            >
                                                {{ agent }}
                                            </option>
                                        </select>
                                        <Database
                                            class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                        />
                                    </div>
                                    <p
                                        class="mt-1.5 text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t(
                                                'Agent used by product pricing comparison modal.',
                                            )
                                        }}
                                    </p>
                                </div>
                            </div>
                        </div>

                        <!-- Providers Tab -->
                        <div
                            v-show="activeTab === 'providers'"
                            class="space-y-6"
                        >
                            <div class="flex items-center justify-between">
                                <div>
                                    <h3
                                        class="text-lg font-semibold text-gray-900 dark:text-white"
                                    >
                                        {{ $t('AI Providers') }}
                                    </h3>
                                    <p
                                        class="text-sm text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t(
                                                'Configure connections to LLM services.',
                                            )
                                        }}
                                    </p>
                                </div>
                                <button
                                    type="button"
                                    @click="addProvider"
                                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                                >
                                    <Plus class="mr-2 h-4 w-4" />
                                    {{ $t('Add Provider') }}
                                </button>
                            </div>

                            <div
                                v-if="form.providers.length === 0"
                                class="rounded-xl border border-dashed border-gray-300 bg-gray-50 py-12 text-center dark:border-gray-600 dark:bg-gray-700/30"
                            >
                                <Server
                                    class="mx-auto mb-3 h-8 w-8 text-gray-400"
                                />
                                <h3
                                    class="text-sm font-medium text-gray-900 dark:text-white"
                                >
                                    {{ $t('No providers configured') }}
                                </h3>
                                <p
                                    class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{
                                        $t(
                                            'Add a provider to get started with AI features.',
                                        )
                                    }}
                                </p>
                            </div>

                            <div v-else class="space-y-4">
                                <div
                                    v-for="(provider, index) in form.providers"
                                    :key="index"
                                    class="overflow-hidden rounded-xl border border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-700/20"
                                >
                                    <div
                                        class="flex items-center justify-between border-b border-gray-200 bg-gray-100/50 p-4 dark:border-gray-700 dark:bg-gray-700/40"
                                    >
                                        <div class="flex items-center gap-2">
                                            <span
                                                class="rounded-md bg-blue-100 px-2 py-1 text-xs font-bold text-blue-700 uppercase dark:bg-blue-900/30 dark:text-blue-300"
                                                >{{
                                                    provider.type ||
                                                    $t('Custom')
                                                }}</span
                                            >
                                            <h4
                                                class="font-medium text-gray-900 dark:text-white"
                                            >
                                                {{
                                                    provider.name ||
                                                    $t('New Provider')
                                                }}
                                            </h4>
                                        </div>
                                        <button
                                            type="button"
                                            @click="removeProvider(index)"
                                            class="rounded-lg p-1 text-red-500 transition-colors hover:bg-red-50 hover:text-red-700 dark:hover:bg-red-900/20 dark:hover:text-red-400"
                                        >
                                            <Trash2 class="h-4 w-4" />
                                        </button>
                                    </div>

                                    <div
                                        class="grid grid-cols-1 gap-6 p-6 md:grid-cols-2"
                                    >
                                        <div>
                                            <label
                                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('Provider Name') }}
                                                <span class="text-red-500"
                                                    >*</span
                                                ></label
                                            >
                                            <input
                                                v-model="provider.name"
                                                type="text"
                                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                                :placeholder="
                                                    $t('e.g. OpenAI Main')
                                                "
                                            />
                                        </div>
                                        <div>
                                            <label
                                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('Type') }}
                                                <span class="text-red-500"
                                                    >*</span
                                                ></label
                                            >
                                            <select
                                                v-model="provider.type"
                                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                            >
                                                <option value="openai">
                                                    OpenAI
                                                </option>
                                                <option value="gemini">
                                                    Gemini
                                                </option>
                                                <option value="anthropic">
                                                    Anthropic
                                                </option>
                                                <option value="custom">
                                                    {{
                                                        $t(
                                                            'Custom (OpenAI Compatible)',
                                                        )
                                                    }}
                                                </option>
                                            </select>
                                        </div>
                                        <div class="md:col-span-2">
                                            <label
                                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('Base URL') }}</label
                                            >
                                            <input
                                                v-model="provider.base_url"
                                                type="text"
                                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                                placeholder="https://api.openai.com/v1"
                                            />
                                        </div>
                                        <div class="md:col-span-2">
                                            <label
                                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('API Key') }}
                                                <span class="text-red-500"
                                                    >*</span
                                                ></label
                                            >
                                            <div class="relative">
                                                <input
                                                    v-model="provider.api_key"
                                                    :type="
                                                        showApiKeys[index]
                                                            ? 'text'
                                                            : 'password'
                                                    "
                                                    class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 pr-12 font-mono text-sm focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                                    placeholder="sk-..."
                                                />
                                                <button
                                                    type="button"
                                                    class="absolute inset-y-0 right-0 flex items-center px-4 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                                                    @click="
                                                        toggleApiKeyVisibility(
                                                            index,
                                                        )
                                                    "
                                                >
                                                    <component
                                                        :is="
                                                            showApiKeys[index]
                                                                ? EyeOff
                                                                : Eye
                                                        "
                                                        class="h-4 w-4"
                                                    />
                                                </button>
                                            </div>
                                        </div>
                                        <div>
                                            <label
                                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{
                                                    $t('Organization ID')
                                                }}</label
                                            >
                                            <input
                                                v-model="provider.org_id"
                                                type="text"
                                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                                :placeholder="$t('Optional')"
                                            />
                                        </div>
                                        <div>
                                            <label
                                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('Project ID') }}</label
                                            >
                                            <input
                                                v-model="provider.project_id"
                                                type="text"
                                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                                :placeholder="$t('Optional')"
                                            />
                                        </div>
                                        <div
                                            class="flex items-center pt-2 md:col-span-2"
                                        >
                                            <label
                                                class="flex cursor-pointer items-center gap-3"
                                            >
                                                <input
                                                    v-model="
                                                        provider.is_default
                                                    "
                                                    type="checkbox"
                                                    class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                                />
                                                <span
                                                    class="text-sm font-medium text-gray-900 dark:text-gray-200"
                                                    >{{
                                                        $t(
                                                            'Use as primary provider for this type',
                                                        )
                                                    }}</span
                                                >
                                            </label>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Models Tab -->
                        <div v-show="activeTab === 'models'" class="space-y-6">
                            <div class="flex items-center justify-between">
                                <div>
                                    <h3
                                        class="text-lg font-semibold text-gray-900 dark:text-white"
                                    >
                                        {{ $t('AI Models') }}
                                    </h3>
                                    <p
                                        class="text-sm text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t(
                                                'Map available models to providers.',
                                            )
                                        }}
                                    </p>
                                </div>
                                <button
                                    type="button"
                                    @click="addModel"
                                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                                >
                                    <Plus class="mr-2 h-4 w-4" />
                                    {{ $t('Add Model') }}
                                </button>
                            </div>

                            <div
                                v-if="form.models.length === 0"
                                class="rounded-xl border border-dashed border-gray-300 bg-gray-50 py-12 text-center dark:border-gray-600 dark:bg-gray-700/30"
                            >
                                <Cpu
                                    class="mx-auto mb-3 h-8 w-8 text-gray-400"
                                />
                                <h3
                                    class="text-sm font-medium text-gray-900 dark:text-white"
                                >
                                    {{ $t('No models configured') }}
                                </h3>
                                <p
                                    class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{
                                        $t(
                                            'Define which models are available for use.',
                                        )
                                    }}
                                </p>
                            </div>

                            <div v-else class="space-y-4">
                                <div
                                    v-for="(model, index) in form.models"
                                    :key="index"
                                    class="overflow-hidden rounded-xl border border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-700/20"
                                >
                                    <div
                                        class="flex items-center justify-between border-b border-gray-200 bg-gray-100/50 p-4 dark:border-gray-700 dark:bg-gray-700/40"
                                    >
                                        <div class="flex items-center gap-2">
                                            <span
                                                class="rounded-md bg-purple-100 px-2 py-1 text-xs font-bold text-purple-700 uppercase dark:bg-purple-900/30 dark:text-purple-300"
                                                >{{
                                                    model.mode || $t('Text')
                                                }}</span
                                            >
                                            <h4
                                                class="font-medium text-gray-900 dark:text-white"
                                            >
                                                {{
                                                    model.name ||
                                                    $t('New Model')
                                                }}
                                            </h4>
                                            <span
                                                v-if="model.provider"
                                                class="ml-2 text-xs text-gray-500 dark:text-gray-400"
                                                >{{ $t('via') }}
                                                {{ model.provider }}</span
                                            >
                                        </div>
                                        <button
                                            type="button"
                                            @click="removeModel(index)"
                                            class="rounded-lg p-1 text-red-500 transition-colors hover:bg-red-50 hover:text-red-700 dark:hover:bg-red-900/20 dark:hover:text-red-400"
                                        >
                                            <Trash2 class="h-4 w-4" />
                                        </button>
                                    </div>

                                    <div
                                        class="grid grid-cols-1 gap-6 p-6 md:grid-cols-2"
                                    >
                                        <div>
                                            <label
                                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('Model ID') }}
                                                <span class="text-red-500"
                                                    >*</span
                                                ></label
                                            >
                                            <input
                                                v-model="model.name"
                                                type="text"
                                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                                placeholder="gpt-4-turbo"
                                            />
                                        </div>
                                        <div>
                                            <label
                                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('Provider') }}
                                                <span class="text-red-500"
                                                    >*</span
                                                ></label
                                            >
                                            <select
                                                v-model="model.provider"
                                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                            >
                                                <option value="">
                                                    {{ $t('Select provider') }}
                                                </option>
                                                <option
                                                    v-for="provider in providerOptions"
                                                    :key="provider"
                                                    :value="provider"
                                                >
                                                    {{ provider }}
                                                </option>
                                            </select>
                                        </div>
                                        <div>
                                            <label
                                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('Mode') }}</label
                                            >
                                            <select
                                                v-model="model.mode"
                                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                            >
                                                <option value="text">
                                                    {{ $t('Text / Chat') }}
                                                </option>
                                                <option value="vision">
                                                    {{
                                                        $t(
                                                            'Vision (Image Analysis)',
                                                        )
                                                    }}
                                                </option>
                                                <option value="embedding">
                                                    {{ $t('Embedding') }}
                                                </option>
                                                <option
                                                    value="image_generation"
                                                >
                                                    {{ $t('Image Generation') }}
                                                </option>
                                            </select>
                                        </div>
                                        <div>
                                            <label
                                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{
                                                    $t('Max Context Tokens')
                                                }}</label
                                            >
                                            <input
                                                v-model.number="
                                                    model.max_tokens
                                                "
                                                type="number"
                                                min="1"
                                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                                placeholder="128000"
                                            />
                                        </div>
                                        <div
                                            class="flex items-center pt-2 md:col-span-2"
                                        >
                                            <label
                                                class="flex cursor-pointer items-center gap-3"
                                            >
                                                <input
                                                    v-model="model.is_default"
                                                    type="checkbox"
                                                    class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                                />
                                                <span
                                                    class="text-sm font-medium text-gray-900 dark:text-gray-200"
                                                    >{{
                                                        $t(
                                                            'Set as default model for this provider',
                                                        )
                                                    }}</span
                                                >
                                            </label>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Agents Tab -->
                        <div v-show="activeTab === 'agents'" class="space-y-6">
                            <div class="flex items-center justify-between">
                                <div>
                                    <h3
                                        class="text-lg font-semibold text-gray-900 dark:text-white"
                                    >
                                        {{ $t('AI Agents') }}
                                    </h3>
                                    <p
                                        class="text-sm text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t(
                                                'Configure specialize agents for specific tasks.',
                                            )
                                        }}
                                    </p>
                                </div>
                                <button
                                    type="button"
                                    @click="addAgent"
                                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                                >
                                    <Plus class="mr-2 h-4 w-4" />
                                    {{ $t('Add Agent') }}
                                </button>
                            </div>

                            <div
                                v-if="form.agents.length === 0"
                                class="rounded-xl border border-dashed border-gray-300 bg-gray-50 py-12 text-center dark:border-gray-600 dark:bg-gray-700/30"
                            >
                                <Bot
                                    class="mx-auto mb-3 h-8 w-8 text-gray-400"
                                />
                                <h3
                                    class="text-sm font-medium text-gray-900 dark:text-white"
                                >
                                    {{ $t('No agents configured') }}
                                </h3>
                                <p
                                    class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{
                                        $t(
                                            'Create agents to handle specific tasks.',
                                        )
                                    }}
                                </p>
                            </div>

                            <div v-else class="space-y-4">
                                <div
                                    v-for="(agent, index) in form.agents"
                                    :key="index"
                                    class="overflow-hidden rounded-xl border border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-700/20"
                                >
                                    <div
                                        class="flex items-center justify-between border-b border-gray-200 bg-gray-100/50 p-4 dark:border-gray-700 dark:bg-gray-700/40"
                                    >
                                        <button
                                            type="button"
                                            class="flex items-center gap-2 text-left"
                                            @click="toggleAgentAccordion(index)"
                                        >
                                            <component
                                                :is="
                                                    expandedAgentIndex === index
                                                        ? ChevronDown
                                                        : ChevronRight
                                                "
                                                class="h-4 w-4 text-gray-500 dark:text-gray-400"
                                            />
                                            <Bot
                                                class="h-4 w-4 text-blue-600 dark:text-blue-400"
                                            />
                                            <h4
                                                class="font-medium text-gray-900 dark:text-white"
                                            >
                                                {{
                                                    agent.name ||
                                                    $t('New Agent')
                                                }}
                                            </h4>
                                        </button>
                                        <div class="flex items-center gap-2">
                                            <span
                                                v-if="agent.is_system"
                                                class="inline-flex items-center rounded-full bg-blue-100 px-2 py-0.5 text-xs font-medium text-blue-700 dark:bg-blue-900/30 dark:text-blue-300"
                                            >
                                                {{ $t('System') }}
                                            </span>
                                            <button
                                                type="button"
                                                @click="
                                                    toggleAgentAccordion(index)
                                                "
                                                class="rounded-lg p-1 text-gray-500 transition-colors hover:bg-gray-200/60 hover:text-gray-700 dark:text-gray-400 dark:hover:bg-gray-600/40 dark:hover:text-gray-200"
                                            >
                                                <component
                                                    :is="
                                                        expandedAgentIndex ===
                                                        index
                                                            ? ChevronDown
                                                            : ChevronRight
                                                    "
                                                    class="h-4 w-4"
                                                />
                                            </button>
                                            <button
                                                v-if="!agent.is_system"
                                                type="button"
                                                @click="removeAgent(index)"
                                                class="rounded-lg p-1 text-red-500 transition-colors hover:bg-red-50 hover:text-red-700 dark:hover:bg-red-900/20 dark:hover:text-red-400"
                                            >
                                                <Trash2 class="h-4 w-4" />
                                            </button>
                                        </div>
                                    </div>

                                    <div
                                        v-show="expandedAgentIndex === index"
                                        class="grid grid-cols-1 gap-6 p-6 md:grid-cols-2"
                                    >
                                        <div>
                                            <label
                                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('Agent Name') }}
                                                <span class="text-red-500"
                                                    >*</span
                                                ></label
                                            >
                                            <input
                                                v-model="agent.name"
                                                type="text"
                                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                                :placeholder="
                                                    $t('Product Describer')
                                                "
                                            />
                                        </div>
                                        <div>
                                            <label
                                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('Provider') }}</label
                                            >
                                            <select
                                                v-model="agent.provider"
                                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                            >
                                                <option value="">
                                                    {{ $t('Select provider') }}
                                                </option>
                                                <option
                                                    v-for="provider in providerOptions"
                                                    :key="provider"
                                                    :value="provider"
                                                >
                                                    {{ provider }}
                                                </option>
                                            </select>
                                        </div>
                                        <div>
                                            <label
                                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('Model') }}</label
                                            >
                                            <select
                                                v-model="agent.model"
                                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                            >
                                                <option value="">
                                                    {{ $t('Select model') }}
                                                </option>
                                                <option
                                                    v-for="modelName in getModelsForProvider(
                                                        agent.provider,
                                                    )"
                                                    :key="modelName"
                                                    :value="modelName"
                                                >
                                                    {{ modelName }}
                                                </option>
                                            </select>
                                        </div>
                                        <div class="grid grid-cols-2 gap-4">
                                            <div>
                                                <label
                                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                    >{{
                                                        $t('Temperature')
                                                    }}</label
                                                >
                                                <input
                                                    v-model.number="
                                                        agent.temperature
                                                    "
                                                    type="number"
                                                    step="0.1"
                                                    min="0"
                                                    max="2"
                                                    class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                                />
                                            </div>
                                            <div>
                                                <label
                                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                    >{{
                                                        $t('Max Output')
                                                    }}</label
                                                >
                                                <input
                                                    v-model.number="
                                                        agent.max_tokens
                                                    "
                                                    type="number"
                                                    min="1"
                                                    class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                                />
                                            </div>
                                        </div>
                                        <div class="md:col-span-2">
                                            <label
                                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{
                                                    $t('System Prompt')
                                                }}</label
                                            >
                                            <textarea
                                                v-model="agent.system_prompt"
                                                rows="4"
                                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 font-mono text-sm focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                                :placeholder="
                                                    $t(
                                                        'You are a helpful assistant...',
                                                    )
                                                "
                                            ></textarea>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Actions -->
                    <div
                        class="flex items-center justify-between border-t border-gray-200 bg-gray-50 p-6 dark:border-gray-700 dark:bg-gray-800/50"
                    >
                        <div
                            class="text-sm text-red-600 dark:text-red-400"
                            v-if="errors.general"
                        >
                            {{ errors.general }}
                        </div>
                        <div v-else></div>
                        <button
                            type="submit"
                            :disabled="form.processing"
                            class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            <Save
                                v-if="!form.processing"
                                class="mr-2 h-4 w-4"
                            />
                            <div
                                v-else
                                class="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent"
                            ></div>
                            <span>{{
                                form.processing
                                    ? $t('Saving Changes...')
                                    : $t('Save Settings')
                            }}</span>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </AdminLayout>
</template>
