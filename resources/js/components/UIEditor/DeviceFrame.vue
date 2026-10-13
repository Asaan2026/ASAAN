<script setup lang="ts">
import type { PreviewMode } from '@/Stores/uiEditorStore';
import { computed } from 'vue';

const props = defineProps<{
    mode: PreviewMode;
}>();

const config = {
    desktop: { width: null, label: 'Desktop' },
    tablet: { width: 768, label: 'Tablet (768px)' },
    mobile: { width: 390, label: 'Mobile (390px)' },
};

const current = computed(() => config[props.mode]);
</script>

<template>
    <!-- Desktop: no frame wrapper needed, slot renders at full width -->
    <div v-if="mode === 'desktop'" class="w-full">
        <slot />
    </div>

    <!-- Tablet / Mobile: centered device frame -->
    <div v-else class="flex w-full flex-col items-center py-4">
        <!-- Device label -->
        <span
            class="mb-2 text-xs font-medium tracking-wide text-gray-400 uppercase dark:text-gray-500"
        >
            {{ current.label }}
        </span>

        <!-- Device frame shell -->
        <div
            class="relative bg-gray-900 shadow-2xl transition-all duration-300 ease-in-out dark:bg-gray-800"
            :class="
                mode === 'mobile' ? 'rounded-[2.5rem] p-3' : 'rounded-2xl p-2.5'
            "
            :style="
                current.width
                    ? { width: `${current.width + 24}px`, maxWidth: '100%' }
                    : {}
            "
        >
            <!-- Top notch (mobile only) -->
            <div
                v-if="mode === 'mobile'"
                class="absolute top-0 left-1/2 z-10 h-5 w-24 -translate-x-1/2 rounded-b-xl bg-gray-900 dark:bg-gray-800"
            />

            <!-- Screen area -->
            <div
                class="relative overflow-hidden bg-white dark:bg-gray-950"
                :class="
                    mode === 'mobile' ? 'mt-2 rounded-[2rem]' : 'rounded-xl'
                "
                :style="
                    current.width
                        ? { width: `${current.width}px`, maxWidth: '100%' }
                        : {}
                "
            >
                <slot />
            </div>

            <!-- Home indicator (mobile only) -->
            <div v-if="mode === 'mobile'" class="mt-2.5 flex justify-center">
                <div class="h-1 w-28 rounded-full bg-gray-600" />
            </div>
        </div>
    </div>
</template>
