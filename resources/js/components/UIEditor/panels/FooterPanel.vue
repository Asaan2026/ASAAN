<script setup lang="ts">
const props = defineProps<{
    settings: Record<string, unknown>;
}>();

const emit = defineEmits<{
    'update:settings': [v: Record<string, unknown>];
}>();

function update(key: string, value: unknown) {
    emit('update:settings', { ...props.settings, [key]: value });
}
function str(key: string, fallback = ''): string {
    const v = props.settings[key];
    return typeof v === 'string' ? v : fallback;
}
function bool(key: string, fallback = false): boolean {
    const v = props.settings[key];
    return typeof v === 'boolean' ? v : fallback;
}
function strSocial(platform: string): string {
    const links = props.settings.social_links as
        | Record<string, string>
        | undefined;
    return typeof links?.[platform] === 'string' ? links[platform] : '';
}
function updateSocial(platform: string, value: string) {
    const links = {
        ...((props.settings.social_links as Record<string, string>) || {}),
    };
    links[platform] = value;
    update('social_links', links);
}
</script>

<template>
    <div class="space-y-5 p-4 text-sm">
        <!-- ── Navigation Menu ──────────────────────────────────────── -->
        <div>
            <label
                class="mb-2 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
            >
                Navigation
            </label>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Footer Menu</label
            >
            <select
                :value="str('menu_source', 'footer')"
                @change="
                    update(
                        'menu_source',
                        ($event.target as HTMLSelectElement).value,
                    )
                "
                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
            >
                <option value="footer">Footer Menu</option>
                <option value="header">Header Menu</option>
                <option value="none">None</option>
            </select>
            <p
                class="mt-1.5 text-[11px] leading-relaxed text-gray-400 dark:text-gray-500"
            >
                Edit links in
                <a
                    href="/admin/content/navigation"
                    target="_blank"
                    class="text-blue-500 hover:underline"
                >
                    Content → Navigation Menus
                </a>
            </p>
        </div>

        <!-- ── Brand ────────────────────────────────────────────────── -->
        <div class="border-t border-gray-100 pt-3 dark:border-gray-700">
            <p
                class="mb-3 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
            >
                Brand
            </p>

            <!-- Logo type toggle -->
            <div class="mb-3 flex gap-2">
                <button
                    v-for="t in ['text', 'image']"
                    :key="t"
                    @click="update('logo_type', t)"
                    :class="[
                        'flex-1 rounded-lg border py-1.5 text-xs transition-colors',
                        str('logo_type', 'text') === t
                            ? 'border-blue-500 bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400'
                            : 'border-gray-300 text-gray-600 hover:border-gray-400 dark:border-gray-600 dark:text-gray-400',
                    ]"
                >
                    {{ t === 'text' ? 'Text' : 'Image' }}
                </button>
            </div>

            <!-- Logo text -->
            <div v-if="str('logo_type', 'text') === 'text'" class="mb-3">
                <label
                    class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                    >Store Name</label
                >
                <input
                    type="text"
                    :value="str('logo_text', 'My Store')"
                    @input="
                        update(
                            'logo_text',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                    placeholder="My Store"
                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                />
            </div>

            <!-- Logo image -->
            <div v-else class="mb-3">
                <label
                    class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                    >Logo Image URL</label
                >
                <input
                    type="text"
                    :value="str('logo_image', '')"
                    @input="
                        update(
                            'logo_image',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                    placeholder="/images/logo.png"
                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 font-mono text-sm text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                />
            </div>

            <!-- Logo link -->
            <div class="mb-3">
                <label
                    class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                    >Logo Link URL</label
                >
                <input
                    type="text"
                    :value="str('logo_url', '/')"
                    @input="
                        update(
                            'logo_url',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                    placeholder="/"
                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 font-mono text-sm text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                />
            </div>

            <!-- Tagline -->
            <div>
                <label
                    class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                    >Tagline / Description</label
                >
                <textarea
                    :value="str('tagline', '')"
                    @input="
                        update(
                            'tagline',
                            ($event.target as HTMLTextAreaElement).value,
                        )
                    "
                    rows="2"
                    placeholder="Short description shown below logo…"
                    class="w-full resize-none rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                />
            </div>
        </div>

        <!-- ── Copyright ─────────────────────────────────────────────── -->
        <div class="border-t border-gray-100 pt-3 dark:border-gray-700">
            <p
                class="mb-3 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
            >
                Copyright
            </p>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Copyright Text</label
            >
            <input
                type="text"
                :value="str('copyright', '')"
                @input="
                    update(
                        'copyright',
                        ($event.target as HTMLInputElement).value,
                    )
                "
                placeholder="© {year} {store}. All rights reserved."
                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
            />
            <p class="mt-1.5 text-[11px] text-gray-400 dark:text-gray-500">
                Use
                <code class="rounded bg-gray-100 px-1 dark:bg-gray-700"
                    >{year}</code
                >
                and
                <code class="rounded bg-gray-100 px-1 dark:bg-gray-700"
                    >{store}</code
                >
                as placeholders.
            </p>
        </div>

        <!-- ── Features ──────────────────────────────────────────────── -->
        <div class="border-t border-gray-100 pt-3 dark:border-gray-700">
            <p
                class="mb-3 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
            >
                Features
            </p>

            <label
                class="mb-2 flex cursor-pointer items-center gap-2 select-none"
            >
                <input
                    type="checkbox"
                    :checked="bool('show_social', true)"
                    @change="
                        update(
                            'show_social',
                            ($event.target as HTMLInputElement).checked,
                        )
                    "
                    class="rounded border-gray-300 text-blue-500 focus:ring-blue-500 dark:border-gray-600"
                />
                <span class="text-sm text-gray-700 dark:text-gray-300"
                    >Show social icons</span
                >
            </label>

            <label class="flex cursor-pointer items-center gap-2 select-none">
                <input
                    type="checkbox"
                    :checked="bool('show_payment_icons', true)"
                    @change="
                        update(
                            'show_payment_icons',
                            ($event.target as HTMLInputElement).checked,
                        )
                    "
                    class="rounded border-gray-300 text-blue-500 focus:ring-blue-500 dark:border-gray-600"
                />
                <span class="text-sm text-gray-700 dark:text-gray-300"
                    >Show payment icons</span
                >
            </label>
        </div>

        <!-- ── Social Links ───────────────────────────────────────────── -->
        <div
            v-if="bool('show_social', true)"
            class="border-t border-gray-100 pt-3 dark:border-gray-700"
        >
            <p
                class="mb-3 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
            >
                Social Links
            </p>

            <div
                v-for="platform in [
                    'facebook',
                    'twitter',
                    'instagram',
                    'youtube',
                    'linkedin',
                ]"
                :key="platform"
                class="mb-3"
            >
                <label
                    class="mb-1 block text-xs font-medium text-gray-600 capitalize dark:text-gray-400"
                    >{{ platform }}</label
                >
                <input
                    type="url"
                    :value="strSocial(platform)"
                    @input="
                        updateSocial(
                            platform,
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                    :placeholder="`https://${platform}.com/yourpage`"
                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 font-mono text-sm text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                />
            </div>
        </div>

        <!-- ── Colors ────────────────────────────────────────────────── -->
        <div class="border-t border-gray-100 pt-3 dark:border-gray-700">
            <p
                class="mb-3 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
            >
                Colors
            </p>

            <div
                v-for="[key, label, def] in [
                    ['background_color', 'Background', '#111827'],
                    ['text_color', 'Body Text', '#9ca3af'],
                    ['heading_color', 'Headings', '#ffffff'],
                    ['accent_color', 'Accent / Links', '#3b82f6'],
                    ['border_color', 'Border', '#1f2937'],
                ]"
                :key="key"
                class="mb-2 flex items-center gap-2"
            >
                <input
                    type="color"
                    :value="str(key as string, def as string)"
                    @input="
                        update(
                            key as string,
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                    class="h-7 w-7 flex-shrink-0 cursor-pointer rounded border border-gray-300 bg-transparent p-0.5 dark:border-gray-600"
                />
                <span class="flex-1 text-xs text-gray-700 dark:text-gray-300">{{
                    label
                }}</span>
                <code
                    class="font-mono text-[11px] text-gray-400 dark:text-gray-500"
                >
                    {{ str(key as string, def as string) }}
                </code>
            </div>
        </div>
    </div>
</template>
