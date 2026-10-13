<script setup lang="ts">
const props = defineProps<{ settings: Record<string, unknown> }>();
const emit = defineEmits<{ 'update:settings': [v: Record<string, unknown>] }>();
function update(key: string, value: unknown) {
    emit('update:settings', { ...props.settings, [key]: value });
}

const languages = [
    { value: 'html', label: 'HTML' },
    { value: 'css', label: 'CSS' },
    { value: 'js', label: 'JavaScript' },
    { value: 'ts', label: 'TypeScript' },
    { value: 'php', label: 'PHP' },
    { value: 'python', label: 'Python' },
    { value: 'json', label: 'JSON' },
    { value: 'bash', label: 'Shell / Bash' },
    { value: 'sql', label: 'SQL' },
    { value: 'vue', label: 'Vue' },
    { value: 'jsx', label: 'JSX' },
    { value: 'tsx', label: 'TSX' },
    { value: 'xml', label: 'XML' },
    { value: 'yaml', label: 'YAML' },
];
</script>

<template>
    <div class="space-y-4 p-4">
        <div class="grid grid-cols-2 gap-3">
            <div>
                <label
                    class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                    >Language</label
                >
                <select
                    :value="settings.language as string"
                    class="uie-input"
                    @change="
                        update(
                            'language',
                            ($event.target as HTMLSelectElement).value,
                        )
                    "
                >
                    <option
                        v-for="lang in languages"
                        :key="lang.value"
                        :value="lang.value"
                    >
                        {{ lang.label }}
                    </option>
                </select>
            </div>
            <div>
                <label
                    class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                    >Filename (optional)</label
                >
                <input
                    type="text"
                    :value="settings.filename as string"
                    class="uie-input"
                    placeholder="index.html"
                    @input="
                        update(
                            'filename',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                />
            </div>
        </div>

        <div class="flex items-center gap-2">
            <input
                id="show-line-numbers"
                type="checkbox"
                :checked="settings.show_line_numbers !== false"
                class="rounded border-gray-300 text-blue-600 dark:border-gray-600"
                @change="
                    update(
                        'show_line_numbers',
                        ($event.target as HTMLInputElement).checked,
                    )
                "
            />
            <label
                for="show-line-numbers"
                class="text-xs font-medium text-gray-700 dark:text-gray-300"
                >Show line numbers</label
            >
        </div>

        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Code</label
            >
            <textarea
                :value="settings.code as string"
                rows="18"
                spellcheck="false"
                class="uie-code-textarea"
                placeholder="// Paste your code here"
                @input="
                    update('code', ($event.target as HTMLTextAreaElement).value)
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
.uie-code-textarea {
    @apply w-full resize-y rounded-lg border border-gray-300 bg-gray-900 px-3 py-2.5 font-mono text-xs text-green-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-950 dark:text-green-300;
    tab-size: 2;
    white-space: pre;
    overflow-x: auto;
}
</style>
