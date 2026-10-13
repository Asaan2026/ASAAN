<script setup lang="ts">
const props = defineProps<{ settings: Record<string, unknown> }>();
const emit = defineEmits<{ 'update:settings': [v: Record<string, unknown>] }>();

function update(key: string, value: unknown) {
    emit('update:settings', { ...props.settings, [key]: value });
}
</script>

<template>
    <div class="space-y-4 p-4">
        <!-- Layout toggle -->
        <div>
            <label
                class="mb-2 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Layout</label
            >
            <div class="grid grid-cols-2 gap-2">
                <button
                    v-for="opt in [
                        { val: 'split', label: 'Split' },
                        { val: 'center', label: 'Centered' },
                    ]"
                    :key="opt.val"
                    type="button"
                    class="rounded-lg border py-1.5 text-xs font-medium transition-colors"
                    :class="
                        (settings.layout ?? 'split') === opt.val
                            ? 'border-blue-600 bg-blue-600 text-white'
                            : 'border-gray-300 bg-white text-gray-600 hover:border-blue-400 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-400'
                    "
                    @click="update('layout', opt.val)"
                >
                    {{ opt.label }}
                </button>
            </div>
        </div>

        <!-- Background Color -->
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Background Color</label
            >
            <div class="flex items-center gap-2">
                <input
                    type="color"
                    :value="(settings.bg_color as string) || '#0f172a'"
                    class="h-8 w-8 flex-shrink-0 cursor-pointer rounded border"
                    @input="
                        update(
                            'bg_color',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                />
                <input
                    type="text"
                    :value="(settings.bg_color as string) || '#0f172a'"
                    class="uie-input flex-1"
                    @change="
                        update(
                            'bg_color',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                />
            </div>
        </div>

        <!-- Title -->
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Headline</label
            >
            <input
                type="text"
                :value="settings.title as string"
                class="uie-input"
                placeholder="Join Thousands of Happy Shoppers"
                @input="
                    update('title', ($event.target as HTMLInputElement).value)
                "
            />
        </div>

        <!-- Subtitle -->
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Subtitle
                <span class="font-normal text-gray-400"
                    >(HTML allowed)</span
                ></label
            >
            <textarea
                :value="settings.subtitle as string"
                rows="3"
                class="uie-input resize-none"
                placeholder="Subscribe and get <strong>10% off</strong>…"
                @input="
                    update(
                        'subtitle',
                        ($event.target as HTMLTextAreaElement).value,
                    )
                "
            />
        </div>

        <!-- CTA Button Text -->
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Button Label</label
            >
            <input
                type="text"
                :value="settings.cta_text as string"
                class="uie-input"
                placeholder="Subscribe Free"
                @input="
                    update(
                        'cta_text',
                        ($event.target as HTMLInputElement).value,
                    )
                "
            />
        </div>

        <!-- Success Message -->
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Success Message</label
            >
            <input
                type="text"
                :value="settings.success_msg as string"
                class="uie-input"
                placeholder="You're in! Check your inbox…"
                @input="
                    update(
                        'success_msg',
                        ($event.target as HTMLInputElement).value,
                    )
                "
            />
        </div>
    </div>
</template>

<style scoped>
@reference "tailwindcss";
.uie-input {
    @apply w-full rounded-lg border border-gray-300 bg-white px-2 py-1.5 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white;
}
</style>
