<script setup lang="ts">
import LanguageSwitcher from '@/components/LanguageSwitcher.vue';
import admin from '@/routes/admin';
import { useI18nStore } from '@/Stores/i18n';
import { Head, useForm } from '@inertiajs/vue3';
import { computed, ref } from 'vue';

const { t } = useI18nStore();

const props = defineProps<{
    adminLogo: string;
    tab?: string;
}>();

const activeTab = ref<string>(props.tab === 'delivery' ? 'delivery' : 'admin');

const adminForm = useForm({
    email: '',
    password: '',
    remember: false,
});

const deliveryForm = useForm({
    email: '',
    password: '',
});

const form = computed(() =>
    activeTab.value === 'delivery' ? deliveryForm : adminForm,
);

const showPassword = ref(false);
const currentYear = computed(() => new Date().getFullYear());

const submit = () => {
    if (activeTab.value === 'delivery') {
        deliveryForm.post('/delivery/login', {
            onFinish: () => deliveryForm.reset('password'),
        });
        return;
    }
    adminForm.post(admin.login.store.url(), {
        onFinish: () => adminForm.reset('password'),
    });
};
</script>

<template>
    <Head :title="`${t('Admin Login')} - Akbari Development Group`" />

    <div
        class="relative flex min-h-screen items-center justify-center overflow-hidden bg-gray-50 dark:bg-transparent"
    >
        <div class="absolute top-4 right-4 z-20">
            <LanguageSwitcher />
        </div>

        <!-- ============================================ -->
        <!-- BACKGROUND: LIGHT MODE                       -->
        <!-- ============================================ -->
        <div class="absolute inset-0 dark:hidden">
            <!-- Soft gradient base -->
            <div
                class="absolute inset-0 bg-gradient-to-br from-slate-50 via-blue-50/50 to-indigo-50/60"
            ></div>
            <!-- Decorative blobs -->
            <div
                class="absolute top-[-15%] right-[-10%] h-[600px] w-[600px] rounded-full bg-blue-200/30 blur-3xl"
            ></div>
            <div
                class="absolute bottom-[-20%] left-[-8%] h-[500px] w-[500px] rounded-full bg-indigo-200/25 blur-3xl"
            ></div>
            <div
                class="absolute top-[50%] left-[50%] h-[350px] w-[350px] rounded-full bg-violet-200/15 blur-3xl"
            ></div>
            <!-- Dot grid pattern -->
            <div
                class="absolute inset-0 opacity-[0.35]"
                style="
                    background-image: radial-gradient(
                        circle,
                        #c7d2fe 1px,
                        transparent 1px
                    );
                    background-size: 32px 32px;
                "
            ></div>
        </div>

        <!-- ============================================ -->
        <!-- BACKGROUND: DARK MODE                        -->
        <!-- ============================================ -->
        <div
            class="absolute inset-0 hidden bg-gradient-to-br from-slate-950 via-blue-950 to-indigo-950 dark:block"
        >
            <!-- Glowing orbs -->
            <div
                class="absolute top-[-10%] left-[-5%] h-[500px] w-[500px] animate-pulse rounded-full bg-blue-500/10 blur-3xl"
            ></div>
            <div
                class="absolute right-[-10%] bottom-[-15%] h-[600px] w-[600px] animate-pulse rounded-full bg-indigo-500/10 blur-3xl"
                style="animation-delay: 1s"
            ></div>
            <div
                class="absolute top-[40%] left-[30%] h-[300px] w-[300px] animate-pulse rounded-full bg-violet-500/5 blur-3xl"
                style="animation-delay: 2s"
            ></div>
            <!-- Cross grid pattern -->
            <div
                class="absolute inset-0 opacity-[0.03]"
                style="
                    background-image: url('data:image/svg+xml,%3Csvg width=&quot;60&quot; height=&quot;60&quot; viewBox=&quot;0 0 60 60&quot; xmlns=&quot;http://www.w3.org/2000/svg&quot;%3E%3Cg fill=&quot;none&quot; fill-rule=&quot;evenodd&quot;%3E%3Cg fill=&quot;%23ffffff&quot; fill-opacity=&quot;1&quot;%3E%3Cpath d=&quot;M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z&quot;/%3E%3C/g%3E%3C/g%3E%3C/svg%3E');
                "
            ></div>
        </div>

        <!-- Centered container -->
        <div class="relative z-10 mx-auto flex min-h-screen w-full max-w-7xl">
            <!-- ============================================ -->
            <!-- LEFT PANEL - BRANDING                        -->
            <!-- ============================================ -->
            <div
                class="relative hidden flex-col justify-between p-12 lg:flex lg:w-[55%] xl:p-16"
            >
                <!-- Top: Logo -->
                <div>
                    <div class="flex items-center">
                        <img
                            :src="props.adminLogo"
                            alt="Akbari Development Group"
                            class="h-12 w-auto object-contain dark:brightness-0 dark:invert"
                        />
                    </div>
                </div>

                <!-- Center: Headline + Stats -->
                <div>
                    <div class="max-w-lg space-y-6">
                        <h1
                            class="text-5xl leading-[1.1] font-bold tracking-tight text-gray-900 xl:text-6xl dark:text-white"
                        >
                            {{ $t('Your store,') }}<br />
                            <span
                                class="bg-gradient-to-r from-blue-600 via-indigo-600 to-violet-600 bg-clip-text text-transparent dark:from-blue-400 dark:via-indigo-400 dark:to-violet-400"
                                >{{ $t('simplified.') }}</span
                            >
                        </h1>
                        <p
                            class="max-w-md text-lg leading-relaxed text-gray-500 dark:text-slate-400"
                        >
                            {{
                                $t(
                                    'The all-in-one commerce platform that puts you in control. Manage products, orders, and customers from a single, elegant dashboard with unlimited custom agent creation for agentic commerce.',
                                )
                            }}
                        </p>
                    </div>

                    <!-- Stats Row -->
                    <div class="mt-12 flex items-center gap-8">
                        <div class="flex items-center gap-3">
                            <div
                                class="flex h-10 w-10 items-center justify-center rounded-lg border border-blue-200/60 bg-blue-100 dark:border-blue-500/20 dark:bg-blue-500/10"
                            >
                                <svg
                                    class="h-5 w-5 text-blue-600 dark:text-blue-400"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="1.5"
                                        d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
                                    />
                                </svg>
                            </div>
                            <div>
                                <div
                                    class="text-xl font-bold text-gray-900 dark:text-white"
                                >
                                    10K+
                                </div>
                                <div
                                    class="text-xs text-gray-400 dark:text-slate-500"
                                >
                                    {{ $t('Products') }}
                                </div>
                            </div>
                        </div>
                        <div
                            class="h-10 w-px bg-gray-200 dark:bg-slate-800"
                        ></div>
                        <div class="flex items-center gap-3">
                            <div
                                class="flex h-10 w-10 items-center justify-center rounded-lg border border-indigo-200/60 bg-indigo-100 dark:border-indigo-500/20 dark:bg-indigo-500/10"
                            >
                                <svg
                                    class="h-5 w-5 text-indigo-600 dark:text-indigo-400"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="1.5"
                                        d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"
                                    />
                                </svg>
                            </div>
                            <div>
                                <div
                                    class="text-xl font-bold text-gray-900 dark:text-white"
                                >
                                    99.9%
                                </div>
                                <div
                                    class="text-xs text-gray-400 dark:text-slate-500"
                                >
                                    {{ $t('Uptime') }}
                                </div>
                            </div>
                        </div>
                        <div
                            class="h-10 w-px bg-gray-200 dark:bg-slate-800"
                        ></div>
                        <div class="flex items-center gap-3">
                            <div
                                class="flex h-10 w-10 items-center justify-center rounded-lg border border-violet-200/60 bg-violet-100 dark:border-violet-500/20 dark:bg-violet-500/10"
                            >
                                <svg
                                    class="h-5 w-5 text-violet-600 dark:text-violet-400"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="1.5"
                                        d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                                    />
                                </svg>
                            </div>
                            <div>
                                <div
                                    class="text-xl font-bold text-gray-900 dark:text-white"
                                >
                                    24/7
                                </div>
                                <div
                                    class="text-xs text-gray-400 dark:text-slate-500"
                                >
                                    {{ $t('Support') }}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Bottom: Copyright -->
                <div>
                    <p class="text-sm text-gray-400 dark:text-slate-600">
                        &copy; {{ currentYear }} Akbari Development Group.
                        {{ $t('All rights reserved.') }}
                    </p>
                </div>
            </div>

            <!-- ============================================ -->
            <!-- RIGHT PANEL - LOGIN FORM                     -->
            <!-- ============================================ -->
            <div
                class="flex w-full items-center justify-center p-6 sm:p-8 lg:w-[45%]"
            >
                <div class="w-full max-w-[420px]">
                    <!-- LIGHT: elevated white card / DARK: glass card -->
                    <div
                        class="rounded-3xl border border-gray-200/80 bg-white p-8 shadow-xl shadow-gray-200/40 sm:p-10 dark:border-white/[0.08] dark:bg-white/[0.07] dark:shadow-2xl dark:shadow-black/20 dark:backdrop-blur-2xl"
                    >
                        <!-- Mobile Logo -->
                        <div
                            class="mb-10 flex items-center justify-center lg:hidden"
                        >
                            <img
                                :src="props.adminLogo"
                                alt="Akbari Development Group"
                                class="h-10 w-auto object-contain dark:brightness-0 dark:invert"
                            />
                        </div>

                        <!-- Tab Switcher -->
                        <div class="mb-8">
                            <div
                                class="grid grid-cols-2 gap-1 rounded-xl border border-gray-200/80 bg-gray-100 p-1 dark:border-white/[0.08] dark:bg-white/[0.06]"
                            >
                                <button
                                    type="button"
                                    @click="activeTab = 'admin'"
                                    class="flex items-center justify-center gap-2 rounded-lg py-2.5 text-sm font-medium transition-all"
                                    :class="
                                        activeTab === 'admin'
                                            ? 'bg-white text-gray-900 shadow-sm dark:bg-white/10 dark:text-white'
                                            : 'text-gray-500 hover:text-gray-700 dark:text-slate-400 dark:hover:text-slate-200'
                                    "
                                >
                                    <svg
                                        class="h-4 w-4"
                                        fill="none"
                                        stroke="currentColor"
                                        viewBox="0 0 24 24"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="1.5"
                                            d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                                        />
                                    </svg>
                                    {{ $t('Admin') }}
                                </button>
                                <button
                                    type="button"
                                    @click="activeTab = 'delivery'"
                                    class="flex items-center justify-center gap-2 rounded-lg py-2.5 text-sm font-medium transition-all"
                                    :class="
                                        activeTab === 'delivery'
                                            ? 'bg-white text-gray-900 shadow-sm dark:bg-white/10 dark:text-white'
                                            : 'text-gray-500 hover:text-gray-700 dark:text-slate-400 dark:hover:text-slate-200'
                                    "
                                >
                                    <svg
                                        class="h-4 w-4"
                                        fill="none"
                                        stroke="currentColor"
                                        viewBox="0 0 24 24"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="1.5"
                                            d="M3 7h11v13H3zM14 13h6l-2 5h-4zM6.5 17a1.5 1.5 0 100 3 1.5 1.5 0 000-3zm7 0a1.5 1.5 0 100 3 1.5 1.5 0 000-3z"
                                        />
                                    </svg>
                                    {{ $t('Delivery Person') }}
                                </button>
                            </div>
                        </div>

                        <!-- Header -->
                        <div class="mb-8">
                            <h2
                                class="mb-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{
                                    activeTab === 'delivery'
                                        ? $t('Delivery portal')
                                        : $t('Welcome back')
                                }}
                            </h2>
                            <p
                                v-if="activeTab === 'delivery'"
                                class="text-sm text-gray-500 dark:text-slate-400"
                            >
                                {{
                                    $t(
                                        'Sign in to view your assigned packages and start delivering',
                                    )
                                }}
                            </p>
                            <p
                                v-else
                                class="text-sm text-gray-500 dark:text-slate-400"
                            >
                                {{
                                    $t(
                                        'Sign in to your admin account to continue',
                                    )
                                }}
                            </p>
                        </div>

                        <form @submit.prevent="submit" class="space-y-5">
                            <!-- Email Field -->
                            <div class="space-y-2">
                                <label
                                    class="block text-sm font-medium text-gray-700 dark:text-slate-300"
                                    >{{ $t('Email') }}</label
                                >
                                <div class="group relative">
                                    <div
                                        class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5"
                                    >
                                        <svg
                                            class="h-[18px] w-[18px] text-gray-400 transition-colors group-focus-within:text-blue-500 dark:text-slate-500 dark:group-focus-within:text-blue-400"
                                            fill="none"
                                            stroke="currentColor"
                                            viewBox="0 0 24 24"
                                        >
                                            <path
                                                stroke-linecap="round"
                                                stroke-linejoin="round"
                                                stroke-width="1.5"
                                                d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                                            />
                                        </svg>
                                    </div>
                                    <input
                                        v-model="form.email"
                                        type="email"
                                        class="w-full rounded-xl border border-gray-200 bg-gray-50 py-3 pr-4 pl-11 text-sm text-gray-900 placeholder-gray-400 transition-all focus:border-blue-500 focus:bg-white focus:ring-2 focus:ring-blue-500/20 focus:outline-none dark:border-white/[0.08] dark:bg-white/[0.05] dark:text-white dark:placeholder-slate-500 dark:focus:border-blue-500/50 dark:focus:bg-white/[0.08] dark:focus:ring-1 dark:focus:ring-blue-500/30"
                                        :class="{
                                            'border-red-400 focus:border-red-500 focus:ring-red-500/20 dark:border-red-500/50 dark:focus:border-red-500/50 dark:focus:ring-red-500/30':
                                                form.errors.email,
                                        }"
                                        placeholder="admin@example.com"
                                        autofocus
                                        required
                                    />
                                </div>
                                <p
                                    v-if="form.errors.email"
                                    class="mt-1 flex items-center gap-1 text-xs text-red-500 dark:text-red-400"
                                >
                                    <svg
                                        class="h-3.5 w-3.5 flex-shrink-0"
                                        fill="currentColor"
                                        viewBox="0 0 20 20"
                                    >
                                        <path
                                            fill-rule="evenodd"
                                            d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z"
                                            clip-rule="evenodd"
                                        />
                                    </svg>
                                    {{ form.errors.email }}
                                </p>
                            </div>

                            <!-- Password Field -->
                            <div class="space-y-2">
                                <label
                                    class="block text-sm font-medium text-gray-700 dark:text-slate-300"
                                    >{{ $t('Password') }}</label
                                >
                                <div class="group relative">
                                    <div
                                        class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5"
                                    >
                                        <svg
                                            class="h-[18px] w-[18px] text-gray-400 transition-colors group-focus-within:text-blue-500 dark:text-slate-500 dark:group-focus-within:text-blue-400"
                                            fill="none"
                                            stroke="currentColor"
                                            viewBox="0 0 24 24"
                                        >
                                            <path
                                                stroke-linecap="round"
                                                stroke-linejoin="round"
                                                stroke-width="1.5"
                                                d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                                            />
                                        </svg>
                                    </div>
                                    <input
                                        v-model="form.password"
                                        :type="
                                            showPassword ? 'text' : 'password'
                                        "
                                        class="w-full rounded-xl border border-gray-200 bg-gray-50 py-3 pr-12 pl-11 text-sm text-gray-900 placeholder-gray-400 transition-all focus:border-blue-500 focus:bg-white focus:ring-2 focus:ring-blue-500/20 focus:outline-none dark:border-white/[0.08] dark:bg-white/[0.05] dark:text-white dark:placeholder-slate-500 dark:focus:border-blue-500/50 dark:focus:bg-white/[0.08] dark:focus:ring-1 dark:focus:ring-blue-500/30"
                                        :class="{
                                            'border-red-400 focus:border-red-500 focus:ring-red-500/20 dark:border-red-500/50 dark:focus:border-red-500/50 dark:focus:ring-red-500/30':
                                                form.errors.password,
                                        }"
                                        :placeholder="$t('Enter your password')"
                                        required
                                    />
                                    <button
                                        @click="showPassword = !showPassword"
                                        type="button"
                                        class="absolute top-1/2 right-3 -translate-y-1/2 p-1 text-gray-400 transition-colors hover:text-gray-600 dark:text-slate-500 dark:hover:text-slate-300"
                                    >
                                        <svg
                                            v-if="!showPassword"
                                            class="h-[18px] w-[18px]"
                                            fill="none"
                                            stroke="currentColor"
                                            viewBox="0 0 24 24"
                                        >
                                            <path
                                                stroke-linecap="round"
                                                stroke-linejoin="round"
                                                stroke-width="1.5"
                                                d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                                            />
                                            <path
                                                stroke-linecap="round"
                                                stroke-linejoin="round"
                                                stroke-width="1.5"
                                                d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                                            />
                                        </svg>
                                        <svg
                                            v-else
                                            class="h-[18px] w-[18px]"
                                            fill="none"
                                            stroke="currentColor"
                                            viewBox="0 0 24 24"
                                        >
                                            <path
                                                stroke-linecap="round"
                                                stroke-linejoin="round"
                                                stroke-width="1.5"
                                                d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"
                                            />
                                        </svg>
                                    </button>
                                </div>
                                <p
                                    v-if="form.errors.password"
                                    class="mt-1 flex items-center gap-1 text-xs text-red-500 dark:text-red-400"
                                >
                                    <svg
                                        class="h-3.5 w-3.5 flex-shrink-0"
                                        fill="currentColor"
                                        viewBox="0 0 20 20"
                                    >
                                        <path
                                            fill-rule="evenodd"
                                            d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z"
                                            clip-rule="evenodd"
                                        />
                                    </svg>
                                    {{ form.errors.password }}
                                </p>
                            </div>

                            <!-- Remember Me -->
                            <div
                                v-if="activeTab === 'admin'"
                                class="flex items-center justify-between"
                            >
                                <label
                                    class="group flex cursor-pointer items-center gap-2.5"
                                >
                                    <div class="relative">
                                        <input
                                            v-model="form.remember"
                                            type="checkbox"
                                            id="remember"
                                            class="peer sr-only"
                                        />
                                        <div
                                            class="flex h-[18px] w-[18px] items-center justify-center rounded-md border border-gray-300 bg-gray-50 transition-all peer-checked:border-blue-600 peer-checked:bg-blue-600 dark:border-white/15 dark:bg-white/5 dark:peer-checked:border-blue-500 dark:peer-checked:bg-blue-500"
                                        >
                                            <svg
                                                v-show="form.remember"
                                                class="h-3 w-3 text-white"
                                                fill="none"
                                                stroke="currentColor"
                                                viewBox="0 0 24 24"
                                                stroke-width="3"
                                            >
                                                <path
                                                    stroke-linecap="round"
                                                    stroke-linejoin="round"
                                                    d="M5 13l4 4L19 7"
                                                />
                                            </svg>
                                        </div>
                                    </div>
                                    <span
                                        class="text-sm text-gray-500 transition-colors select-none group-hover:text-gray-700 dark:text-slate-400 dark:group-hover:text-slate-300"
                                        >{{ $t('Remember me') }}</span
                                    >
                                </label>
                            </div>

                            <!-- Submit Button -->
                            <button
                                type="submit"
                                class="group relative w-full overflow-hidden rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 px-4 py-3.5 text-sm font-semibold tracking-wide text-white shadow-lg shadow-blue-600/25 transition-all duration-300 hover:from-blue-500 hover:to-indigo-500 hover:shadow-blue-500/35 disabled:cursor-not-allowed disabled:opacity-40 disabled:shadow-none dark:shadow-blue-500/25 dark:hover:shadow-blue-500/40"
                                :disabled="form.processing"
                            >
                                <!-- Button Shine Effect -->
                                <div
                                    class="absolute inset-0 -translate-x-full bg-gradient-to-r from-transparent via-white/15 to-transparent transition-transform duration-700 group-hover:translate-x-full dark:via-white/10"
                                ></div>

                                <span
                                    v-if="!form.processing"
                                    class="relative flex items-center justify-center gap-2"
                                >
                                    <span>{{
                                        activeTab === 'delivery'
                                            ? $t('Start Delivering')
                                            : $t('Sign In')
                                    }}</span>
                                    <svg
                                        class="h-4 w-4 transition-transform group-hover:translate-x-0.5"
                                        fill="none"
                                        stroke="currentColor"
                                        viewBox="0 0 24 24"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="2"
                                            d="M14 5l7 7m0 0l-7 7m7-7H3"
                                        />
                                    </svg>
                                </span>
                                <span
                                    v-else
                                    class="relative flex items-center justify-center gap-2"
                                >
                                    <svg
                                        class="h-[18px] w-[18px] animate-spin text-white"
                                        xmlns="http://www.w3.org/2000/svg"
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
                                    <span>{{ $t('Signing in...') }}</span>
                                </span>
                            </button>
                        </form>

                        <!-- Divider + Open Source Badge -->
                        <div
                            class="mt-8 border-t border-gray-100 pt-6 dark:border-white/[0.06]"
                        >
                            <div
                                class="flex items-center justify-center gap-2 text-xs text-gray-400 dark:text-slate-600"
                            >
                                <svg
                                    class="h-4 w-4"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="1.5"
                                        d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                                    />
                                </svg>
                                <span>{{
                                    $t('Secured by Akbari Development Group')
                                }}</span>
                            </div>
                        </div>

                        <!-- Footer (mobile only) -->
                        <div class="mt-4 text-center lg:hidden">
                            <p
                                class="text-xs text-gray-400 dark:text-slate-600"
                            >
                                &copy; {{ currentYear }} Akbari Development
                                Group. {{ $t('All rights reserved.') }}
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <!-- /centered container -->
    </div>
</template>
