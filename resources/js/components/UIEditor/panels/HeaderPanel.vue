<script setup lang="ts">
const props = defineProps<{ settings: Record<string, unknown> }>();
const emit = defineEmits<{ 'update:settings': [v: Record<string, unknown>] }>();

function update(key: string, value: unknown) {
    emit('update:settings', { ...props.settings, [key]: value });
}

function get(key: string, fallback: unknown): unknown {
    return key in props.settings ? props.settings[key] : fallback;
}
function str(key: string, fallback: string): string {
    return String(key in props.settings ? props.settings[key] : fallback);
}
function bool(key: string, fallback: boolean): boolean {
    const v = props.settings[key];
    return v === undefined ? fallback : Boolean(v);
}
</script>

<template>
    <div class="space-y-5 p-4 text-sm">
        <!-- ── Navigation Menu ─────────────────────────────────────── -->
        <div>
            <label
                class="mb-2 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
            >
                Navigation Menu
            </label>
            <select
                :value="str('menu_source', 'header')"
                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                @change="
                    update(
                        'menu_source',
                        ($event.target as HTMLSelectElement).value,
                    )
                "
            >
                <option value="header">
                    Header Menu (Storefront Navigation)
                </option>
                <option value="footer">Footer Menu</option>
                <option value="none">No menu</option>
            </select>
            <p
                class="mt-1.5 text-[11px] leading-relaxed text-gray-400 dark:text-gray-500"
            >
                Edit items in
                <strong class="font-medium text-gray-500 dark:text-gray-400"
                    >Content → Navigation Menus → Header Menu</strong
                >
            </p>
        </div>

        <!-- ── Logo ───────────────────────────────────────────────── -->
        <div class="border-t border-gray-100 pt-3 dark:border-gray-700">
            <p
                class="mb-3 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
            >
                Logo
            </p>

            <!-- Type toggle -->
            <div class="mb-3 flex gap-2">
                <button
                    :class="[
                        'flex-1 rounded-lg border py-1.5 text-xs transition-colors',
                        str('logo_type', 'text') === 'text'
                            ? 'border-blue-500 bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400'
                            : 'border-gray-300 text-gray-600 hover:border-gray-400 dark:border-gray-600 dark:text-gray-400',
                    ]"
                    @click="update('logo_type', 'text')"
                >
                    Text
                </button>
                <button
                    :class="[
                        'flex-1 rounded-lg border py-1.5 text-xs transition-colors',
                        str('logo_type', 'text') === 'image'
                            ? 'border-blue-500 bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400'
                            : 'border-gray-300 text-gray-600 hover:border-gray-400 dark:border-gray-600 dark:text-gray-400',
                    ]"
                    @click="update('logo_type', 'image')"
                >
                    Image URL
                </button>
            </div>

            <!-- Logo text -->
            <div v-if="str('logo_type', 'text') === 'text'" class="mb-3">
                <label
                    class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                    >Store Name</label
                >
                <input
                    :value="str('logo_text', 'My Store')"
                    type="text"
                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                    @input="
                        update(
                            'logo_text',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                />
            </div>

            <!-- Logo image -->
            <div v-else class="mb-3">
                <label
                    class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                    >Image URL</label
                >
                <input
                    :value="str('logo_image', '')"
                    type="text"
                    placeholder="/images/logo.png"
                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 font-mono text-sm text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                    @input="
                        update(
                            'logo_image',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                />
            </div>

            <!-- Logo link -->
            <div>
                <label
                    class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                    >Link URL</label
                >
                <input
                    :value="str('logo_url', '/')"
                    type="text"
                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 font-mono text-sm text-gray-900 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                    @input="
                        update(
                            'logo_url',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                />
            </div>
        </div>

        <!-- ── Features ────────────────────────────────────────────── -->
        <div class="border-t border-gray-100 pt-3 dark:border-gray-700">
            <p
                class="mb-3 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
            >
                Features
            </p>
            <div class="space-y-2.5">
                <label class="group flex cursor-pointer items-center gap-2.5">
                    <input
                        type="checkbox"
                        :checked="bool('show_search', true)"
                        class="h-3.5 w-3.5 rounded border-gray-300 text-blue-600 dark:border-gray-600"
                        @change="
                            update(
                                'show_search',
                                ($event.target as HTMLInputElement).checked,
                            )
                        "
                    />
                    <span class="text-xs text-gray-700 dark:text-gray-300"
                        >Search bar</span
                    >
                </label>

                <label class="flex cursor-pointer items-center gap-2.5">
                    <input
                        type="checkbox"
                        :checked="bool('show_cart', true)"
                        class="h-3.5 w-3.5 rounded border-gray-300 text-blue-600 dark:border-gray-600"
                        @change="
                            update(
                                'show_cart',
                                ($event.target as HTMLInputElement).checked,
                            )
                        "
                    />
                    <span class="text-xs text-gray-700 dark:text-gray-300"
                        >Cart icon</span
                    >
                </label>

                <label class="flex cursor-pointer items-center gap-2.5">
                    <input
                        type="checkbox"
                        :checked="bool('show_auth_buttons', true)"
                        class="h-3.5 w-3.5 rounded border-gray-300 text-blue-600 dark:border-gray-600"
                        @change="
                            update(
                                'show_auth_buttons',
                                ($event.target as HTMLInputElement).checked,
                            )
                        "
                    />
                    <span class="text-xs text-gray-700 dark:text-gray-300"
                        >Login / Register buttons</span
                    >
                </label>

                <label class="flex cursor-pointer items-center gap-2.5">
                    <input
                        type="checkbox"
                        :checked="bool('sticky', true)"
                        class="h-3.5 w-3.5 rounded border-gray-300 text-blue-600 dark:border-gray-600"
                        @change="
                            update(
                                'sticky',
                                ($event.target as HTMLInputElement).checked,
                            )
                        "
                    />
                    <span class="text-xs text-gray-700 dark:text-gray-300"
                        >Sticky header (fixed to top)</span
                    >
                </label>
            </div>
        </div>

        <!-- ── Colors ──────────────────────────────────────────────── -->
        <div class="border-t border-gray-100 pt-3 dark:border-gray-700">
            <p
                class="mb-3 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
            >
                Colors
            </p>
            <div class="space-y-2.5">
                <div class="flex items-center gap-3">
                    <input
                        type="color"
                        :value="str('background_color', '#ffffff')"
                        class="h-7 w-7 cursor-pointer rounded-md border border-gray-300 p-0.5 dark:border-gray-600"
                        @input="
                            update(
                                'background_color',
                                ($event.target as HTMLInputElement).value,
                            )
                        "
                    />
                    <span
                        class="flex-1 text-xs text-gray-700 dark:text-gray-300"
                        >Background</span
                    >
                    <code
                        class="font-mono text-[11px] text-gray-400 dark:text-gray-500"
                        >{{ str('background_color', '#ffffff') }}</code
                    >
                </div>

                <div class="flex items-center gap-3">
                    <input
                        type="color"
                        :value="str('text_color', '#111827')"
                        class="h-7 w-7 cursor-pointer rounded-md border border-gray-300 p-0.5 dark:border-gray-600"
                        @input="
                            update(
                                'text_color',
                                ($event.target as HTMLInputElement).value,
                            )
                        "
                    />
                    <span
                        class="flex-1 text-xs text-gray-700 dark:text-gray-300"
                        >Text &amp; icons</span
                    >
                    <code
                        class="font-mono text-[11px] text-gray-400 dark:text-gray-500"
                        >{{ str('text_color', '#111827') }}</code
                    >
                </div>

                <div class="flex items-center gap-3">
                    <input
                        type="color"
                        :value="str('accent_color', '#2563eb')"
                        class="h-7 w-7 cursor-pointer rounded-md border border-gray-300 p-0.5 dark:border-gray-600"
                        @input="
                            update(
                                'accent_color',
                                ($event.target as HTMLInputElement).value,
                            )
                        "
                    />
                    <span
                        class="flex-1 text-xs text-gray-700 dark:text-gray-300"
                        >Accent (logo text, buttons)</span
                    >
                    <code
                        class="font-mono text-[11px] text-gray-400 dark:text-gray-500"
                        >{{ str('accent_color', '#2563eb') }}</code
                    >
                </div>
            </div>
        </div>
    </div>
</template>
