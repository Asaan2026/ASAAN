<script setup lang="ts">
import TiptapEditor from '@/components/Admin/TiptapEditor.vue';
import { ref, watch } from 'vue';

const props = defineProps<{ settings: Record<string, unknown> }>();
const emit = defineEmits<{ 'update:settings': [v: Record<string, unknown>] }>();

const content = ref((props.settings.content as string) ?? '');
watch(content, (val) =>
    emit('update:settings', { ...props.settings, content: val }),
);
</script>

<template>
    <div class="p-4">
        <label
            class="mb-2 block text-xs font-medium text-gray-600 dark:text-gray-400"
            >Content</label
        >
        <TiptapEditor v-model="content" />
    </div>
</template>
