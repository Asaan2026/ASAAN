import { usePage } from '@inertiajs/vue3';
import { computed } from 'vue';

type ThemeSettings = Record<
    string,
    string | number | boolean | null | undefined
>;

function settingBool(value: unknown, defaultValue = true): boolean {
    if (value === undefined || value === null) return defaultValue;
    if (typeof value === 'boolean') return value;
    if (value === '0' || value === 0 || value === 'false') return false;
    return Boolean(value);
}

/**
 * Picks a readable foreground (near-black or white) for text sitting on top of
 * a brand colour. The theme's Primary Color can be anything the owner picks --
 * a light green, a mid teal -- and a fixed white or dark label becomes unreadable
 * on the wrong one. This checks the colour's brightness and answers with the
 * side that will actually be legible.
 */
export function readableOn(hex: string): string {
    const clean = String(hex).replace('#', '').trim();
    const full =
        clean.length === 3
            ? clean
                  .split('')
                  .map((c) => c + c)
                  .join('')
            : clean;
    const value = parseInt(full, 16);
    if (Number.isNaN(value) || full.length !== 6) return '#ffffff';

    const r = (value >> 16) & 255;
    const g = (value >> 8) & 255;
    const b = value & 255;
    const brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255;

    return brightness > 0.6 ? '#111827' : '#ffffff';
}

export function useThemeSettings() {
    const page = usePage();

    const settings = computed<ThemeSettings>(() => {
        const theme = page.props.theme as
            | { settings?: ThemeSettings }
            | null
            | undefined;
        return theme?.settings ?? {};
    });

    const primary = computed(() =>
        String(settings.value['colors.primary'] ?? '#2563eb'),
    );
    // A label colour that stays readable on top of the Primary Color.
    const primaryText = computed(() => readableOn(primary.value));
    const secondary = computed(() =>
        String(settings.value['colors.secondary'] ?? '#1e40af'),
    );
    const accent = computed(() =>
        String(settings.value['colors.accent'] ?? '#0ea5e9'),
    );
    const fontFamily = computed(() =>
        String(settings.value['typography.font_family'] ?? 'Inter, sans-serif'),
    );
    const containerWidth = computed(() =>
        String(settings.value['layout.container_width'] ?? '1280px'),
    );
    const stickyHeader = computed(() =>
        settingBool(settings.value['features.sticky_header'], true),
    );
    const backToTop = computed(() =>
        settingBool(settings.value['features.back_to_top'], true),
    );
    const showPlatformBranding = computed(() =>
        settingBool(settings.value['features.show_platform_branding'], false),
    );
    const quickViewEnabled = computed(() =>
        settingBool(settings.value['features.quick_view'], true),
    );
    const wishlistEnabled = computed(() =>
        settingBool(settings.value['features.wishlist'], true),
    );

    const cssVars = computed(() => ({
        '--theme-primary': primary.value,
        '--theme-secondary': secondary.value,
        '--theme-accent': accent.value,
        '--theme-font': fontFamily.value,
        '--theme-container': containerWidth.value,
    }));

    return {
        settings,
        primary,
        primaryText,
        secondary,
        accent,
        fontFamily,
        containerWidth,
        stickyHeader,
        backToTop,
        showPlatformBranding,
        quickViewEnabled,
        wishlistEnabled,
        cssVars,
    };
}
