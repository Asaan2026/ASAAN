<script setup lang="ts">
import { computed, ref } from 'vue';

const props = defineProps<{
    settings: Record<string, unknown>;
    editorMode?: boolean;
}>();

const submitted = ref(false);
const sending = ref(false);
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
// The shipped wording used to promise 10% off a first order. Nothing sent a
// code, so nobody ever got it. Any offer here has to be set in the dashboard
// by someone who is actually going to honour it.
const subtitle = computed(
    () =>
        (props.settings.subtitle as string) ||
        'New arrivals and offers, straight to your inbox.',
);
const ctaText = computed(
    () => (props.settings.cta_text as string) || 'Subscribe',
);
const successMsg = computed(
    () =>
        (props.settings.success_msg as string) || "Thanks — we'll be in touch.",
);

/**
 * This form used to do nothing at all: it checked the address for an "@",
 * then showed "check your inbox", and stored the address nowhere. The shop
 * has had a working subscribe endpoint all along; it was simply never called.
 */
async function submit() {
    error.value = '';

    if (!email.value || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.value)) {
        error.value = 'Please enter a valid email address.';
        return;
    }

    // The editor must not post real subscriptions while someone is just
    // arranging blocks on the page.
    if (props.editorMode) {
        submitted.value = true;
        return;
    }

    sending.value = true;

    try {
        const token =
            document
                .querySelector('meta[name="csrf-token"]')
                ?.getAttribute('content') ?? '';

        const response = await fetch('/newsletter/subscribe', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Accept: 'application/json',
                'X-CSRF-TOKEN': token,
            },
            body: JSON.stringify({ email: email.value }),
        });

        const body = await response.json().catch(() => ({}));

        if (response.ok && body?.success) {
            submitted.value = true;
            return;
        }

        // The server already words these ("already subscribed", and so on), so
        // show what it said rather than a generic failure.
        error.value =
            body?.message ?? 'Could not subscribe just now. Please try again.';
    } catch {
        error.value = 'Could not reach the server. Please try again.';
    } finally {
        sending.value = false;
    }
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
                    class="rich-text rich-text-tight text-base text-white/70 md:text-lg"
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
                        Just store news
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
                        Join the mailing list
                    </h3>
                    <p class="mb-5 text-sm text-white/50">
                        Enter your email address to subscribe.
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
                            :disabled="sending"
                            class="w-full rounded-xl py-3 text-sm font-bold text-white transition-all disabled:cursor-not-allowed disabled:opacity-70"
                            style="background: #2563eb"
                        >
                            {{ sending ? 'Subscribing…' : ctaText }}
                        </button>
                    </form>

                    <p class="mt-4 text-center text-xs text-white/30">
                        Unsubscribe at any time.
                    </p>
                </div>
            </div>
        </div>
    </div>
</template>
