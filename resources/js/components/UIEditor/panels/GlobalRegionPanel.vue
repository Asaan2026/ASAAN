<script setup lang="ts">
import {
    CheckCircle,
    Clock,
    ExternalLink,
    LayoutTemplate,
} from 'lucide-vue-next';
import { computed } from 'vue';

const props = defineProps<{
    settings: Record<string, unknown>;
}>();

// read-only panel — no settings emission needed
const regionId = computed(() => props.settings.region_id as number | null);
const regionName = computed(
    () => (props.settings.region_name as string) || 'Unknown Region',
);
const regionType = computed(
    () => (props.settings.region_type as string) || 'section',
);
const status = computed(
    () => (props.settings.region_status as string) || 'draft',
);

const typeColors: Record<string, string> = {
    header: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300',
    footer: 'bg-gray-100 text-gray-600 dark:bg-gray-700',
    section: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300',
    banner: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-300',
    sidebar: 'bg-teal-100 text-teal-700 dark:bg-teal-900/30 dark:text-teal-300',
};
</script>

<template>
    <div class="space-y-4 p-4">
        <!-- Info card -->
        <div
            class="rounded-lg border border-indigo-200 bg-indigo-50 p-3 dark:border-indigo-800 dark:bg-indigo-900/20"
        >
            <div class="flex items-start gap-2">
                <LayoutTemplate
                    class="mt-0.5 h-4 w-4 flex-shrink-0 text-indigo-500"
                />
                <div class="min-w-0">
                    <p
                        class="mb-1 text-xs font-semibold tracking-wide text-indigo-700 uppercase dark:text-indigo-300"
                    >
                        Linked Reusable Section
                    </p>
                    <p
                        class="truncate text-sm font-medium text-gray-900 dark:text-white"
                    >
                        {{ regionName }}
                    </p>
                    <div class="mt-1.5 flex items-center gap-2">
                        <span
                            :class="[
                                'rounded-full px-2 py-0.5 text-xs font-semibold capitalize',
                                typeColors[regionType] ?? typeColors.section,
                            ]"
                        >
                            {{ regionType }}
                        </span>
                        <span
                            :class="[
                                'inline-flex items-center gap-1 text-xs',
                                status === 'published'
                                    ? 'text-green-600 dark:text-green-400'
                                    : 'text-amber-600 dark:text-amber-400',
                            ]"
                        >
                            <CheckCircle
                                v-if="status === 'published'"
                                class="h-3 w-3"
                            />
                            <Clock v-else class="h-3 w-3" />
                            {{ status === 'published' ? 'Live' : 'Draft' }}
                        </span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Link to edit the region -->
        <a
            v-if="regionId"
            :href="`/admin/uieditor/regions/${regionId}/editor`"
            target="_blank"
            class="flex w-full items-center justify-center gap-2 rounded-lg border border-indigo-300 px-4 py-2 text-sm font-medium text-indigo-600 transition-colors hover:bg-indigo-50 dark:border-indigo-700 dark:hover:bg-indigo-900/20"
        >
            <ExternalLink class="h-3.5 w-3.5" />
            Open Region Editor
        </a>

        <p
            class="text-center text-xs leading-relaxed text-gray-400 dark:text-gray-500"
        >
            Editing this region will update <strong>all pages</strong> that use
            it — changes are live-linked.
        </p>
    </div>
</template>
