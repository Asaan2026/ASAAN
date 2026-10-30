<script setup lang="ts">
/**
 * "Download our app" block.
 *
 * The store links come from the dashboard (storeContact). The Play Store link
 * falls back to the direct APK when the dashboard has not set one yet, so the
 * Android button always works.
 *
 * iPhone has no app yet, because publishing one needs a paid Apple membership.
 * Until that exists the button offers the web app instead: Safari can save this
 * site to the home screen, where it opens full screen with the Asaan icon and
 * behaves like an app. That is a real thing a customer can use today, so the
 * button says what it is -- a web app, not the App Store -- rather than
 * promising an app that is not there. Apple gives no way to trigger that save
 * from a page, so the button can only show the three steps.
 *
 * The moment an App Store link is set in the dashboard, that wins and this
 * whole fallback disappears on its own.
 */
import { useI18nStore } from '@/Stores/i18n';
import { useThemeSettings } from '@/composables/useThemeSettings';
import { usePage } from '@inertiajs/vue3';
import { computed, ref } from 'vue';

interface Props {
    compact?: boolean;
    tone?: 'light' | 'dark';
}

const props = withDefaults(defineProps<Props>(), {
    compact: false,
    tone: 'light',
});

const i18n = useI18nStore();
const page = usePage();
const { primary } = useThemeSettings();

// Downloads the APK in one click, and never goes stale. GitHub's
// /releases/latest/download/<name> address always serves that file from
// whichever release was published last, so no version appears here -- a link
// naming one (asaan-2.6.0.apk, then asaan-2.8.1.apk) died on the next release
// both times.
//
// The catch: every release must attach the APK under exactly this file name,
// alongside the versioned copy. Miss it and this 404s. mobile/BUILD_AND_RELEASE.md
// says so in the publishing steps.
const FALLBACK_APK =
    'https://github.com/Asaan2026/ASAAN/releases/latest/download/asaan-latest.apk';

const contact = computed(
    () => (page.props as Record<string, any> | undefined)?.storeContact,
);

const androidUrl = computed(
    () => String(contact.value?.playStoreUrl || '').trim() || FALLBACK_APK,
);

const iosUrl = computed(() => String(contact.value?.appStoreUrl || '').trim());

const iosAvailable = computed(() => iosUrl.value.length > 0);

// The "add to home screen" steps, shown only when asked for, so the footer
// stays small for everyone who is not on an iPhone.
const showWebAppSteps = ref(false);

const isDark = computed(() => props.tone === 'dark');

const containerClass = computed(() =>
    props.compact
        ? isDark.value
            ? 'rounded-xl border border-slate-700 bg-slate-800/50 p-3'
            : 'rounded-xl border border-gray-200 bg-gray-50 p-3 dark:border-slate-700 dark:bg-slate-800/50'
        : isDark.value
          ? 'rounded-xl border border-slate-700 bg-slate-800/50 p-5'
          : 'rounded-xl border border-gray-200 bg-gray-50 p-5 dark:border-slate-700 dark:bg-slate-800/50',
);

const titleClass = computed(() =>
    isDark.value
        ? 'text-sm font-semibold text-white'
        : 'text-sm font-semibold text-gray-900 dark:text-slate-100',
);

const subtitleClass = computed(() =>
    isDark.value
        ? 'text-xs text-slate-400'
        : 'text-xs text-gray-500 dark:text-slate-400',
);
</script>

<template>
    <div :class="containerClass">
        <div class="flex items-center gap-3">
            <img
                src="/logos/asaan-logo.png"
                alt="Asaan"
                :class="compact ? 'h-10 w-10' : 'h-12 w-12'"
                class="shrink-0 rounded-xl object-contain"
            />
            <div class="min-w-0">
                <p :class="titleClass">{{ $t('Asaan') }}</p>
                <p :class="subtitleClass">{{ $t('Download our app') }}</p>
            </div>
        </div>

        <div
            :class="
                compact
                    ? 'mt-3 flex flex-col gap-2'
                    : 'mt-4 flex flex-col gap-2 sm:flex-row'
            "
        >
            <!-- Android: Play Store link, or the direct APK if none is set. -->
            <a
                :href="androidUrl"
                target="_blank"
                rel="noopener"
                :class="[
                    'inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2 text-sm font-medium text-white transition-opacity hover:opacity-90',
                    compact ? 'text-xs' : '',
                ]"
                :style="{ backgroundColor: primary }"
            >
                <svg
                    class="h-5 w-5"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    aria-hidden="true"
                >
                    <path
                        d="M17.523 15.3414c-.5511 0-.9993-.4486-.9993-.9997s.4483-.9993.9993-.9993c.5511 0 .9993.4483.9993.9993.0001.5511-.4482.9997-.9993.9997m-11.046 0c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.5511 0 .9993.4483.9993.9993 0 .5511-.4483.9997-.9993.9997m11.4045-6.02l1.9973-3.4592a.416.416 0 00-.1521-.5676.416.416 0 00-.5676.1521l-2.0223 3.503C15.5902 8.2439 13.8533 7.8508 12 7.8508s-3.5902.3931-5.1367 1.0989L4.841 5.4467a.4161.4161 0 00-.5677-.1521.4157.4157 0 00-.1521.5676l1.9973 3.4592C2.6889 11.1867.3432 14.6589 0 18.761h24c-.3435-4.1021-2.6892-7.5743-6.1185-9.4396"
                    />
                </svg>
                <span>{{ $t('Download for Android') }}</span>
            </a>

            <!-- iOS: the App Store when a link exists, otherwise the web app. -->
            <a
                v-if="iosAvailable"
                :href="iosUrl"
                target="_blank"
                rel="noopener"
                :class="[
                    'inline-flex items-center justify-center gap-2 rounded-lg border px-4 py-2 text-sm font-medium transition-colors',
                    compact ? 'text-xs' : '',
                    isDark
                        ? 'border-slate-600 text-white hover:bg-slate-700'
                        : 'border-gray-300 text-gray-900 hover:bg-gray-100 dark:border-slate-600 dark:text-slate-100 dark:hover:bg-slate-700',
                ]"
            >
                <svg
                    class="h-5 w-5"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    aria-hidden="true"
                >
                    <path
                        d="M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701"
                    />
                </svg>
                <span>{{ $t('Download for iPhone') }}</span>
            </a>
            <button
                v-else
                type="button"
                :aria-expanded="showWebAppSteps"
                aria-controls="asaan-web-app-steps"
                @click="showWebAppSteps = !showWebAppSteps"
                :class="[
                    'inline-flex items-center justify-center gap-2 rounded-lg border px-4 py-2 text-sm font-medium transition-colors',
                    compact ? 'text-xs' : '',
                    isDark
                        ? 'border-slate-600 text-white hover:bg-slate-700'
                        : 'border-gray-300 text-gray-900 hover:bg-gray-100 dark:border-slate-600 dark:text-slate-100 dark:hover:bg-slate-700',
                ]"
                :title="i18n.t('Add the website to your home screen')"
            >
                <svg
                    class="h-5 w-5"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    aria-hidden="true"
                >
                    <path
                        d="M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701"
                    />
                </svg>
                <span
                    >{{ $t('Install on iPhone') }} ·
                    {{ $t('web app') }}</span
                >
            </button>
        </div>

        <!-- Apple allows no "install" button on a page, so the three steps are
             the only way to offer this. Hidden until asked for. -->
        <div
            v-if="!iosAvailable"
            v-show="showWebAppSteps"
            id="asaan-web-app-steps"
            :class="[
                'mt-3 rounded-lg border p-3 text-xs leading-relaxed',
                isDark
                    ? 'border-slate-700 bg-slate-900/60 text-slate-300'
                    : 'border-gray-200 bg-white text-gray-600 dark:border-slate-700 dark:bg-slate-900/60 dark:text-slate-300',
            ]"
        >
            <p class="mb-2">
                {{
                    $t(
                        'Saves this shop to your home screen, with the Asaan icon, opening full screen like an app. It is the website itself, not an App Store app.',
                    )
                }}
            </p>
            <ol class="mb-2 list-inside list-decimal space-y-1">
                <li>{{ $t('Open this shop in Safari.') }}</li>
                <li>{{ $t('Tap the Share button.') }}</li>
                <li>{{ $t('Choose Add to Home Screen.') }}</li>
            </ol>
            <p :class="isDark ? 'text-slate-400' : 'text-gray-500 dark:text-slate-400'">
                {{ $t('A full iPhone app is on the way. This works in the meantime.') }}
            </p>
        </div>
    </div>
</template>
