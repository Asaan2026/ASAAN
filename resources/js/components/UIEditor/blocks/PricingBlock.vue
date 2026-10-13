<script setup lang="ts">
defineProps<{ settings: Record<string, unknown>; editorMode?: boolean }>();
</script>

<template>
    <div
        class="relative flex flex-col overflow-hidden rounded-2xl border-2"
        :class="
            settings.highlight
                ? 'border-blue-500 shadow-xl ring-2 ring-blue-500/20'
                : 'border-gray-200 shadow dark:border-gray-700'
        "
    >
        <!-- Badge -->
        <div
            v-if="settings.badge"
            class="absolute top-4 right-4 rounded-full px-2.5 py-0.5 text-xs font-bold"
            :class="
                settings.highlight
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'
            "
        >
            {{ settings.badge }}
        </div>

        <!-- Header -->
        <div
            class="px-6 pt-8 pb-6"
            :class="
                settings.highlight
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-50 dark:bg-gray-800'
            "
        >
            <h3
                class="mb-4 text-lg font-bold"
                :class="
                    settings.highlight
                        ? 'text-white'
                        : 'text-gray-900 dark:text-white'
                "
            >
                {{ (settings.title as string) || 'Plan Name' }}
            </h3>
            <div class="flex items-baseline gap-1">
                <span
                    class="text-3xl font-bold"
                    :class="
                        settings.highlight
                            ? 'text-white'
                            : 'text-gray-900 dark:text-white'
                    "
                    >{{ settings.currency }}{{ settings.price }}</span
                >
                <span
                    class="text-sm"
                    :class="
                        settings.highlight
                            ? 'text-blue-100'
                            : 'text-gray-500 dark:text-gray-400'
                    "
                    >{{ settings.period }}</span
                >
            </div>
            <p
                v-if="settings.description"
                class="mt-2 text-sm"
                :class="
                    settings.highlight
                        ? 'text-blue-100'
                        : 'text-gray-600 dark:text-gray-400'
                "
            >
                {{ settings.description }}
            </p>
        </div>

        <!-- Features -->
        <div class="flex-1 bg-white px-6 py-5 dark:bg-gray-900">
            <ul class="space-y-3">
                <li
                    v-for="(feat, i) in settings.features as string[]"
                    :key="i"
                    class="flex items-start gap-2.5 text-sm text-gray-700 dark:text-gray-300"
                >
                    <svg
                        class="mt-0.5 h-4 w-4 flex-shrink-0 text-green-500"
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
                    {{ feat }}
                </li>
            </ul>
        </div>

        <!-- CTA -->
        <div class="bg-white px-6 pt-4 pb-7 dark:bg-gray-900">
            <a
                :href="(settings.cta_url as string) || '#'"
                class="block w-full rounded-xl px-4 py-2.5 text-center text-sm font-semibold transition-colors"
                :class="
                    settings.highlight
                        ? 'bg-blue-600 text-white hover:bg-blue-700'
                        : 'bg-gray-100 text-gray-900 hover:bg-gray-200 dark:bg-gray-700 dark:text-white dark:hover:bg-gray-600'
                "
            >
                {{ (settings.cta_text as string) || 'Get Started' }}
            </a>
        </div>
    </div>
</template>
