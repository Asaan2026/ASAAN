<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
    settings: Record<string, unknown>;
    editorMode?: boolean;
}>();

const lines = computed(() => {
    const raw = (props.settings.code as string) ?? '';
    return raw.split('\n');
});

const langLabel: Record<string, string> = {
    html: 'HTML',
    css: 'CSS',
    js: 'JavaScript',
    ts: 'TypeScript',
    php: 'PHP',
    python: 'Python',
    json: 'JSON',
    bash: 'Shell',
    sql: 'SQL',
    vue: 'Vue',
    jsx: 'JSX',
    tsx: 'TSX',
    xml: 'XML',
    yaml: 'YAML',
};
</script>

<template>
    <div
        class="overflow-hidden rounded-lg border border-gray-800 font-mono text-sm dark:border-gray-700"
    >
        <!-- Header bar -->
        <div
            class="flex items-center justify-between bg-gray-800 px-4 py-2 dark:bg-gray-900"
        >
            <div class="flex items-center gap-2">
                <!-- Traffic-light dots -->
                <span class="h-2.5 w-2.5 rounded-full bg-red-500 opacity-70" />
                <span
                    class="h-2.5 w-2.5 rounded-full bg-yellow-400 opacity-70"
                />
                <span
                    class="h-2.5 w-2.5 rounded-full bg-green-500 opacity-70"
                />
                <span
                    v-if="settings.filename"
                    class="ml-2 text-xs text-gray-400"
                >
                    {{ settings.filename }}
                </span>
            </div>
            <span
                class="text-[11px] font-semibold tracking-wider text-gray-500 uppercase"
            >
                {{
                    langLabel[settings.language as string] ?? settings.language
                }}
            </span>
        </div>

        <!-- Code content -->
        <div class="overflow-x-auto bg-gray-950 p-4 dark:bg-gray-950">
            <table class="w-full border-collapse text-xs leading-relaxed">
                <tbody>
                    <tr
                        v-for="(line, i) in lines"
                        :key="i"
                        class="transition-colors hover:bg-white/5"
                    >
                        <!-- Line number -->
                        <td
                            v-if="settings.show_line_numbers"
                            class="w-px pr-4 text-right whitespace-nowrap text-gray-600 select-none dark:text-gray-600"
                            style="min-width: 2rem"
                        >
                            {{ i + 1 }}
                        </td>
                        <!-- Code -->
                        <td class="pl-2 whitespace-pre text-gray-100">
                            {{ line || ' ' }}
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>
