<script setup lang="ts">
import { computed, ref } from 'vue';

const props = defineProps<{
    settings: Record<string, unknown>;
    editorMode?: boolean;
}>();

const submitted = ref(false);
const email = ref('');
const error = ref('');

const bgColor = computed(
    () => (props.settings.bg_color as string) || '#0f172a',
);
const layout = computed(() => (props.settings.layout as string) || 'split');
const title = computed(
    () =>
        (props.settings.title as string) || 'Join Thousands of Happy Shoppers',
);
const subtitle = computed(
    () =>
        (props.settings.subtitle as string) ||
        'Subscribe and get <strong>10% off</strong> your first order, plus exclusive deals and new arrivals straight to your inbox.',
);
const ctaText = computed(
    () => (props.settings.cta_text as string) || 'Subscribe Free',
);
const successMsg = computed(
    () =>
        (props.settings.success_msg as string) ||
        "You're in! Check your inbox for your discount code.",
);

function submit() {
    error.value = '';
    if (!email.value || !email.value.includes('@')) {
        error.value = 'Please enter a valid email address.';
        return;
    }
    submitted.value = true;
}
</script>

<template>
    <div class="w-full" :style="{ background: bgColor }">
        <div
            class="mx-auto max-w-6xl px-6 py-16"
            :class="
                layout === 'split'
                    ? 'flex flex-col items-center gap-12 md:flex-row'
                    : 'flex flex-col items-center text-center'
            "
        >
            <!-- Text -->
            <div :class="layout === 'split' ? 'min-w-0 flex-1' : 'max-w-xl'">
                <span
                    class="mb-3 inline-block rounded-full px-3 py-1 text-xs font-bold tracking-widest text-white uppercase"
                    style="background: rgba(255, 255, 255, 0.12)"
                    >Newsletter</span
                >
                <h2
                    class="mb-4 text-2xl leading-tight font-extrabold text-white md:text-4xl"
                >
                    {{ title }}
                </h2>
                <!-- eslint-disable-next-line vue/no-v-html -->
                <p
                    class="text-base leading-relaxed text-white/70 md:text-lg"
                    v-html="subtitle"
                />

                <!-- Trust badges -->
                <div
                    class="mt-6 flex flex-wrap gap-4 text-xs text-white/50"
                    :class="layout === 'center' ? 'justify-center' : ''"
                >
                    <span class="flex items-center gap-1">
                        <svg
                            class="h-3.5 w-3.5 text-green-400"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2.5"
                                d="M5 13l4 4L19 7"
                            />
                        </svg>
                        No spam, ever
                    </span>
                    <span class="flex items-center gap-1">
                        <svg
                            class="h-3.5 w-3.5 text-green-400"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2.5"
                                d="M5 13l4 4L19 7"
                            />
                        </svg>
                        Unsubscribe any time
                    </span>
                    <span class="flex items-center gap-1">
                        <svg
                            class="h-3.5 w-3.5 text-green-400"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2.5"
                                d="M5 13l4 4L19 7"
                            />
                        </svg>
                        Exclusive deals
                    </span>
                </div>
            </div>

            <!-- Form -->
            <div
                :class="
                    layout === 'split'
                        ? 'w-full shrink-0 md:w-[440px]'
                        : 'mt-8 w-full max-w-md'
                "
            >
                <!-- Success -->
                <div
                    v-if="submitted"
                    class="rounded-2xl p-8 text-center"
                    style="
                        background: rgba(255, 255, 255, 0.08);
                        border: 1px solid rgba(255, 255, 255, 0.12);
                    "
                >
                    <div class="mb-4 text-5xl">🎉</div>
                    <p class="mb-2 text-xl font-bold text-white">
                        You're subscribed!
                    </p>
                    <p class="text-sm text-white/60">{{ successMsg }}</p>
                </div>

                <!-- Form card -->
                <div
                    v-else
                    class="rounded-2xl p-6"
                    style="
                        background: rgba(255, 255, 255, 0.06);
                        border: 1px solid rgba(255, 255, 255, 0.1);
                    "
                >
                    <h3 class="mb-1 text-lg font-bold text-white">
                        Get your 10% off code
                    </h3>
                    <p class="mb-5 text-sm text-white/50">
                        Enter your email and we'll send it instantly.
                    </p>

                    <form @submit.prevent="submit" class="space-y-3">
                        <div>
                            <input
                                v-model="email"
                                type="email"
                                placeholder="your@email.com"
                                autocomplete="email"
                                class="w-full rounded-xl border-0 bg-white px-4 py-3 text-sm text-gray-900 placeholder-gray-400 outline-none focus:ring-2 focus:ring-blue-400 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-100 dark:placeholder-slate-500"
                            />
                            <p v-if="error" class="mt-1.5 text-xs text-red-400">
                                {{ error }}
                            </p>
                        </div>
                        <button
                            type="submit"
                            class="w-full rounded-xl py-3 text-sm font-bold text-white transition-all"
                            style="background: #2563eb"
                            onmouseenter="this.style.background='#1d4ed8'"
                            onmouseleave="this.style.background='#2563eb'"
                        >
                            {{ ctaText }}
                        </button>
                    </form>

                    <p class="mt-4 text-center text-xs text-white/30">
                        🔒 Your data is safe with us. Privacy guaranteed.
                    </p>
                </div>
            </div>
        </div>
    </div>
</template>
