<script setup lang="ts">
/**
 * Light / dark / system switch, shared by the storefront header, the mobile
 * drawer and the account pages.
 *
 * The choice is stored twice on purpose: in localStorage so the very first
 * paint after a reload is already correct without waiting for the server, and
 * in a cookie so the server renders the same palette in the initial HTML. One
 * without the other means either a flash of the wrong colours on every page
 * load, or a page that is dark on screen but light in the markup.
 */
import { useAppearance, type Appearance } from '@/composables/useAppearance';
import { useI18nStore } from '@/Stores/i18n';
import { Monitor, Moon, Sun } from 'lucide-vue-next';
import { computed } from 'vue';

const { appearance, updateAppearance } = useAppearance();
const i18n = useI18nStore();

interface Props {
    /** 'icon' is a single button that flips light/dark. 'segmented' shows all three. */
    variant?: 'icon' | 'segmented';
    /** Hide the text label in the segmented variant, leaving the icon alone. */
    compact?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
    variant: 'icon',
    compact: false,
});

/** What the page is actually showing right now, once 'system' is resolved. */
const resolvedIsDark = computed(() => {
    if (appearance.value === 'dark') return true;
    if (appearance.value === 'light') return false;
    if (typeof window === 'undefined') return false;
    return window.matchMedia('(prefers-color-scheme: dark)').matches;
});

/** Computed, not a plain array, so the labels follow a language change. */
const options = computed(() => [
    { value: 'light' as Appearance, label: i18n.t('Light'), icon: Sun },
    { value: 'dark' as Appearance, label: i18n.t('Dark'), icon: Moon },
    { value: 'system' as Appearance, label: i18n.t('System'), icon: Monitor },
]);

const quickLabel = computed(() =>
    resolvedIsDark.value
        ? i18n.t('Switch to light mode')
        : i18n.t('Switch to dark mode'),
);

/** The single-button variant: one tap moves between light and dark. */
function toggleQuick() {
    updateAppearance(resolvedIsDark.value ? 'light' : 'dark');
}
</script>

<template>
    <div class="theme-toggle">
        <!-- Single button: light <-> dark, labelled with the state it switches to. -->
        <button
            v-if="props.variant === 'icon'"
            type="button"
            class="flex h-9 w-9 items-center justify-center rounded-lg text-gray-600 transition-colors hover:bg-gray-100 dark:text-slate-300 dark:hover:bg-slate-800"
            :aria-label="quickLabel"
            :title="quickLabel"
            @click="toggleQuick"
        >
            <Moon v-if="resolvedIsDark" class="h-[18px] w-[18px]" />
            <Sun v-else class="h-[18px] w-[18px]" />
        </button>

        <!-- Segmented control: all three options, always visible. -->
        <div
            v-else
            class="inline-flex items-center gap-1 rounded-lg bg-gray-100 p-1 dark:bg-slate-800"
            role="group"
            :aria-label="i18n.t('Colour theme')"
        >
            <button
                v-for="option in options"
                :key="option.value"
                type="button"
                class="flex items-center gap-1.5 rounded-md px-2.5 py-1.5 text-sm font-medium transition-colors"
                :class="
                    appearance === option.value
                        ? 'bg-white text-gray-900 shadow-sm dark:bg-slate-700 dark:text-white'
                        : 'text-gray-600 hover:text-gray-900 dark:text-slate-400 dark:hover:text-slate-200'
                "
                :aria-pressed="appearance === option.value"
                @click="updateAppearance(option.value)"
            >
                <component :is="option.icon" class="h-4 w-4" />
                <span v-if="!props.compact">{{ option.label }}</span>
                <span v-else class="sr-only">{{ option.label }}</span>
            </button>
        </div>
    </div>
</template>
