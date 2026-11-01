<script setup lang="ts">
import { usePage } from '@inertiajs/vue3';
import {
    computed,
    defineAsyncComponent,
    markRaw,
    onErrorCaptured,
    type Component,
} from 'vue';

interface Block {
    id: string;
    type: string;
    settings: Record<string, unknown>;
}
interface Column {
    id: string;
    width: number;
    settings: Record<string, unknown>;
    blocks: Block[];
}
interface Section {
    id: string;
    type: string;
    settings: Record<string, unknown>;
    columns: Column[];
}
interface Layout {
    sections?: Section[];
}

const props = defineProps<{
    layout: Layout | null | Record<string, unknown>;
    editorMode?: boolean;
}>();

const page = usePage();

const themeSlug = computed(
    () => ((page.props as any).theme?.slug as string | null) ?? null,
);

const templateBlockModules = import.meta.glob<Component>(
    '../../../../templates/storefront/**/blocks/*Block.vue',
);

function toPascal(str: string): string {
    if (!str) return 'Text';
    return str
        .split(/[-_]/)
        .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
        .join('');
}

function loadTemplateBlock(slug: string, pascal: string) {
    const suffix = `/${slug}/blocks/${pascal}Block.vue`;
    const entry = Object.entries(templateBlockModules).find(([key]) =>
        key.includes(suffix),
    );

    return entry
        ? entry[1]()
        : Promise.reject(new Error(`Template block not found: ${suffix}`));
}

const blockComponentCache = new Map<string, Component>();

function blockComponent(type: string) {
    if (!type) return null;
    const cacheKey = `${themeSlug.value ?? ''}:${type}`;
    if (!blockComponentCache.has(cacheKey)) {
        const slug = themeSlug.value;
        const pascal = toPascal(type);
        const silent = { template: '<div />' };
        blockComponentCache.set(
            cacheKey,
            markRaw(
                defineAsyncComponent({
                    loader: () => {
                        const shared = () =>
                            import(`./blocks/${pascal}Block.vue`).catch(
                                () => import('./blocks/TextBlock.vue'),
                            );
                        return slug
                            ? loadTemplateBlock(slug, pascal).catch(shared)
                            : shared();
                    },
                    errorComponent: silent,
                }),
            ),
        );
    }
    return blockComponentCache.get(cacheKey)!;
}

onErrorCaptured((err) => {
    if (import.meta.env.DEV)
        console.warn('[UIBlockRenderer] block render error:', err);
    return false;
});

/**
 * How light a colour is, 0 (black) to 1 (white), using the sRGB relative
 * luminance formula. Used only to answer one question: did the dashboard pick
 * this colour as a *page surface* (white, off-white) or as a deliberate brand
 * colour (the blue promo strip, the near-black newsletter band)?
 */
function luminance(hex: string): number | null {
    const m = /^#?([0-9a-f]{3}|[0-9a-f]{6})$/i.exec(hex.trim());
    if (!m) return null;

    let h = m[1];
    if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];

    const channel = (v: number) => {
        const c = v / 255;
        return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
    };

    const r = channel(parseInt(h.slice(0, 2), 16));
    const g = channel(parseInt(h.slice(2, 4), 16));
    const b = channel(parseInt(h.slice(4, 6), 16));

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

// The theme's own dark surfaces, so a converted section sits in the same
// palette as the header, footer and product cards rather than inventing a
// third shade of grey.
const DARK_PAGE = '#0f172a'; // slate-900 — stands in for white
const DARK_RAISED = '#1e293b'; // slate-800 — stands in for off-white

/**
 * A background colour the dashboard chose is written as a CSS variable, not
 * straight onto the element. An inline colour beats every dark-mode rule the
 * theme has, which is why the shop used to keep a white middle while its
 * header and footer went dark. As a variable, the stylesheet below gets to
 * swap it for a dark equivalent -- but only for the near-white surfaces.
 * Deliberate brand colours are left exactly as the dashboard set them.
 */
function sectionStyle(section: Section): Record<string, string> {
    const s = section.settings ?? {};
    const out: Record<string, string> = {};

    if (s.background_color) {
        const bg = s.background_color as string;
        out['--uie-bg'] = bg;

        const lum = luminance(bg);
        if (lum !== null && lum >= 0.75) {
            // Only plain white stands in for the page itself. Off-white
            // (#f8fafc is 0.954) and pale tints are the *raised* shade, so a
            // layout that alternates white and off-white sections keeps that
            // separation in dark mode instead of flattening into one slab.
            out['--uie-bg-dark'] = lum >= 0.99 ? DARK_PAGE : DARK_RAISED;
        }
    }

    if (s.background_image) {
        out.backgroundImage = `url('${s.background_image}')`;
        out.backgroundSize = 'cover';
        out.backgroundPosition = 'center';
    }

    if (s.padding_top !== undefined) out['--uie-pt'] = `${s.padding_top}px`;
    if (s.padding_bottom !== undefined)
        out['--uie-pb'] = `${s.padding_bottom}px`;

    return out;
}

/** True when this section's background is a near-white page surface. */
function isLightSurface(section: Section): boolean {
    const bg = section.settings?.background_color as string | undefined;
    if (!bg) return false;
    const lum = luminance(bg);
    return lum !== null && lum >= 0.75;
}

/**
 * The column widths the dashboard chose apply to a desktop only. They go out
 * as variables so the stylesheet can stack them on a phone: writing
 * "3fr 3fr 3fr 3fr" straight onto the element left a phone drawing four
 * columns about seventy pixels wide, which is what squashed the feature boxes.
 *
 * Phone: one column. Tablet: two, unless the dashboard asked for fewer.
 * Desktop: exactly what the dashboard asked for.
 */
function gridStyle(columns: Column[]): Record<string, string> {
    const count = columns.length;
    const desktop = columns.map((c) => `${c.width ?? 6}fr`).join(' ');

    return {
        '--uie-cols': desktop,
        '--uie-cols-md': count > 2 ? 'repeat(2, minmax(0, 1fr))' : desktop,
    };
}

const sections = () => (props.layout as Layout)?.sections ?? [];
</script>

<template>
    <div class="uie-renderer">
        <section
            v-for="section in sections()"
            :key="section.id"
            class="uie-section"
            :data-uie-surface="isLightSurface(section) ? 'light' : null"
            :style="sectionStyle(section)"
        >
            <div
                :class="[
                    'uie-section-inner',
                    section.settings?.full_width
                        ? 'w-full'
                        : 'mx-auto max-w-7xl px-4 sm:px-6 lg:px-8',
                ]"
                :style="gridStyle(section.columns)"
            >
                <div
                    v-for="col in section.columns"
                    :key="col.id"
                    class="uie-col"
                >
                    <div
                        v-for="block in col.blocks"
                        :key="block.id"
                        class="uie-block"
                    >
                        <component
                            :is="blockComponent(block.type)"
                            :settings="block.settings"
                            :editor-mode="editorMode ?? false"
                        />
                    </div>
                </div>
            </div>
        </section>
    </div>
</template>

<style scoped>
.uie-renderer {
    width: 100%;
}

.uie-section {
    width: 100%;
    background-color: var(--uie-bg, transparent);

    /* A phone gets about two thirds of the breathing room a desktop does.
       Sixty-four pixels above and below every section is generous on a wide
       screen and turns a phone into an endless scroll. */
    padding-top: calc(var(--uie-pt, 0px) * 0.6);
    padding-bottom: calc(var(--uie-pb, 0px) * 0.6);
}

/* The dark-mode counterpart of the line above lives in resources/css/app.css,
   NOT here. Written here as `:global(html.dark) .uie-section`, Vue's scoped
   compiler threw the `.uie-section` away and emitted a bare `html.dark`, which
   painted the whole page transparent in dark mode instead of recolouring the
   sections -- and overrode the page's own dark background while doing it. */

.uie-section-inner {
    width: 100%;
    display: grid;
    gap: 16px;

    /* One column on a phone, whatever the dashboard asked for. Content written
       for a quarter of a desktop does not fit a quarter of a phone. */
    grid-template-columns: minmax(0, 1fr);
}

@media (min-width: 640px) {
    .uie-section-inner {
        gap: 24px;
        grid-template-columns: var(--uie-cols-md, minmax(0, 1fr));
    }
}

@media (min-width: 1024px) {
    .uie-section {
        padding-top: var(--uie-pt, 0px);
        padding-bottom: var(--uie-pb, 0px);
    }

    .uie-section-inner {
        grid-template-columns: var(--uie-cols, minmax(0, 1fr));
    }
}

.uie-col {
    min-width: 0;
}
.uie-block {
    margin-bottom: 0;
}
</style>
