<script setup lang="ts">
defineProps<{ settings: Record<string, unknown>; editorMode?: boolean }>();

function embedUrl(url: string): string | null {
    if (!url) return null;
    // YouTube
    const yt = url.match(
        /(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/))([^&?/]+)/,
    );
    if (yt) return `https://www.youtube.com/embed/${yt[1]}`;
    // Vimeo
    const vm = url.match(/vimeo\.com\/(\d+)/);
    if (vm) return `https://player.vimeo.com/video/${vm[1]}`;
    return url;
}

const ratioClass = (ratio: unknown) => {
    if (ratio === '4:3') return 'aspect-[4/3]';
    if (ratio === '1:1') return 'aspect-square';
    return 'aspect-video';
};
</script>

<template>
    <div class="w-full">
        <div v-if="settings.url" :class="ratioClass(settings.ratio)">
            <iframe
                class="h-full w-full rounded"
                :src="embedUrl(settings.url as string) ?? ''"
                frameborder="0"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen
            />
        </div>
        <div
            v-else-if="editorMode"
            class="flex aspect-video w-full items-center justify-center rounded-lg border-2 border-dashed border-gray-300 bg-gray-100 text-sm text-gray-400 dark:border-gray-600 dark:bg-gray-800"
        >
            <div class="text-center">
                <svg
                    class="mx-auto mb-1 h-8 w-8 opacity-50"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <polygon points="5 3 19 12 5 21 5 3" stroke-width="2" />
                </svg>
                Paste a YouTube or Vimeo URL
            </div>
        </div>
    </div>
</template>
