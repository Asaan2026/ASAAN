<script setup lang="ts">
/**
 * The customer's notification bell for the storefront header.
 *
 * It reads the first render from the `customerNotifications` shared prop (so the
 * badge is correct the moment the page paints, with no flash of "0"), then keeps
 * itself current by polling a lightweight count endpoint. Opening the bell loads
 * the newest few notifications. There is no real-time layer on the website yet;
 * polling is deliberately chosen because it needs no extra server infrastructure.
 */
import { useI18nStore } from '@/Stores/i18n';
import { usePage } from '@inertiajs/vue3';
import axios from 'axios';
import { Bell, CheckCheck } from 'lucide-vue-next';
import { computed, onMounted, onUnmounted, ref, watch } from 'vue';

interface CustomerNotification {
    id: number;
    type: string;
    title: string;
    body: string;
    data: Record<string, unknown>;
    read: boolean;
    read_at: string | null;
    created_at: string | null;
    created_at_human?: string;
}

const i18n = useI18nStore();
const page = usePage();

const POLL_INTERVAL = 45000;

const props = withDefaults(
    defineProps<{
        variant?: 'header' | 'drawer';
    }>(),
    {
        variant: 'header',
    },
);

const open = ref(false);
const loading = ref(false);
const notifications = ref<CustomerNotification[]>([]);
const unreadCount = ref(0);
const pulse = ref(false);

let pollTimer: ReturnType<typeof setInterval> | null = null;
let pulseTimer: ReturnType<typeof setTimeout> | null = null;

const shared = computed(
    () =>
        ((page.props as Record<string, any>).customerNotifications ?? {}) as {
            unread_count?: number;
            recent?: CustomerNotification[];
        },
);

watch(
    () => shared.value.unread_count,
    (count) => {
        if (typeof count === 'number') {
            unreadCount.value = count;
        }
    },
);

function applyShared() {
    if (typeof shared.value.unread_count === 'number') {
        unreadCount.value = shared.value.unread_count;
    }
    if (Array.isArray(shared.value.recent) && notifications.value.length === 0) {
        notifications.value = shared.value.recent;
    }
}

async function fetchFeed() {
    loading.value = true;
    try {
        const { data } = await axios.get('/account/notifications/feed', {
            params: { limit: 10 },
            headers: { Accept: 'application/json' },
        });
        notifications.value = data.notifications ?? [];
        const count = Number(data.unread_count ?? 0);
        if (count > unreadCount.value) {
            pulse.value = true;
            if (pulseTimer) clearTimeout(pulseTimer);
            pulseTimer = setTimeout(() => (pulse.value = false), 4000);
        }
        unreadCount.value = count;
    } catch {
        // The bell is an extra; a failed poll must never disturb the page.
    } finally {
        loading.value = false;
    }
}

async function pollCount() {
    try {
        const { data } = await axios.get('/account/notifications/unread-count', {
            headers: { Accept: 'application/json' },
        });
        const count = Number(data.unread_count ?? 0);
        if (count > unreadCount.value) {
            pulse.value = true;
            if (pulseTimer) clearTimeout(pulseTimer);
            pulseTimer = setTimeout(() => (pulse.value = false), 4000);
        }
        unreadCount.value = count;
    } catch {
        // Ignore a failed poll.
    }
}

async function toggle() {
    open.value = !open.value;
    if (open.value) {
        await fetchFeed();
    }
}

function close() {
    open.value = false;
}

/**
 * Where a tapped notification should take the visitor. Order notifications carry
 * the order id; everything else lands on the full notifications page.
 */
function targetFor(notification: CustomerNotification): string {
    const orderId = notification.data?.order_id;
    if (notification.type === 'order' && orderId) {
        return `/account/orders/${orderId}`;
    }

    return '/account/notifications';
}

async function openNotification(notification: CustomerNotification) {
    const target = targetFor(notification);

    if (!notification.read) {
        try {
            await axios.post(
                `/account/notifications/${notification.id}/read`,
                {},
                { headers: { Accept: 'application/json' } },
            );
            notification.read = true;
            unreadCount.value = Math.max(0, unreadCount.value - 1);
        } catch {
            // If marking read failed, still let the visitor through.
        }
    }

    open.value = false;
    window.location.href = target;
}

async function markAllRead() {
    try {
        await axios.post(
            '/account/notifications/read-all',
            {},
            { headers: { Accept: 'application/json' } },
        );
        notifications.value = notifications.value.map((n) => ({
            ...n,
            read: true,
        }));
        unreadCount.value = 0;
    } catch {
        // Ignore.
    }
}

onMounted(() => {
    applyShared();
    pollTimer = setInterval(pollCount, POLL_INTERVAL);
});

onUnmounted(() => {
    if (pollTimer) clearInterval(pollTimer);
    if (pulseTimer) clearTimeout(pulseTimer);
});

const badgeClass = computed(() =>
    props.variant === 'drawer'
        ? 'absolute top-1 right-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white'
        : 'absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-xs font-bold text-white',
);
</script>

<template>
    <!-- Drawer: a plain row that matches the other account links, opening the
         same panel inline. -->
    <div v-if="variant === 'drawer'" class="relative">
        <button
            type="button"
            class="flex w-full items-center gap-3 px-3 py-2.5 text-sm text-slate-700 transition-colors hover:bg-slate-50 dark:text-slate-300 dark:hover:bg-slate-700/50"
            @click="toggle"
        >
            <Bell class="h-4 w-4 shrink-0 text-slate-400 dark:text-slate-500" />
            <span class="flex-1 text-left">{{ i18n.t('Notifications') }}</span>
            <span
                v-if="unreadCount > 0"
                class="flex h-5 min-w-5 items-center justify-center rounded-full bg-red-500 px-1.5 text-xs font-bold text-white"
            >
                {{ unreadCount > 99 ? '99+' : unreadCount }}
            </span>
        </button>
    </div>

    <!-- Header bell -->
    <div v-else class="relative">
        <button
            type="button"
            class="relative p-2 text-gray-700 transition-colors hover:text-gray-900 dark:text-slate-300 dark:hover:text-slate-100"
            :aria-label="i18n.t('Notifications')"
            :title="i18n.t('Notifications')"
            @click="toggle"
        >
            <Bell class="h-6 w-6" :class="{ 'animate-wiggle': pulse }" />
            <span
                v-if="unreadCount > 0"
                class="absolute -top-1 -right-1 flex h-5 min-w-5 items-center justify-center rounded-full bg-red-500 px-1 text-xs font-bold text-white"
            >
                {{ unreadCount > 99 ? '99+' : unreadCount }}
            </span>
        </button>
    </div>

    <!-- Panel -->
    <Teleport to="body">
        <Transition name="fade">
            <div
                v-if="open"
                class="fixed inset-0 z-[110]"
                @click="close"
            />
        </Transition>
        <Transition name="fade">
            <div
                v-if="open"
                class="fixed z-[120] w-[min(360px,92vw)] overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900"
                :class="
                    variant === 'drawer'
                        ? 'top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2'
                        : 'top-16 end-4'
                "
                @click.stop
            >
                <div
                    class="flex items-center justify-between border-b border-slate-200 px-4 py-3 dark:border-slate-700"
                >
                    <span
                        class="text-sm font-semibold text-slate-900 dark:text-slate-100"
                    >
                        {{ i18n.t('Notifications') }}
                    </span>
                    <button
                        v-if="unreadCount > 0"
                        type="button"
                        class="inline-flex items-center gap-1 text-xs font-medium text-blue-600 hover:underline dark:text-blue-400"
                        @click="markAllRead"
                    >
                        <CheckCheck class="h-3.5 w-3.5" />
                        {{ i18n.t('Mark all read') }}
                    </button>
                </div>

                <div class="max-h-96 overflow-y-auto">
                    <p
                        v-if="loading && notifications.length === 0"
                        class="px-4 py-8 text-center text-sm text-slate-500 dark:text-slate-400"
                    >
                        {{ i18n.t('Loading...') }}
                    </p>

                    <p
                        v-else-if="notifications.length === 0"
                        class="px-4 py-8 text-center text-sm text-slate-500 dark:text-slate-400"
                    >
                        {{ i18n.t('No notifications yet') }}
                    </p>

                    <button
                        v-for="notification in notifications"
                        :key="notification.id"
                        type="button"
                        class="flex w-full items-start gap-3 border-b border-slate-100 px-4 py-3 text-left transition-colors last:border-b-0 hover:bg-slate-50 dark:border-slate-800 dark:hover:bg-slate-800/60"
                        :class="
                            notification.read
                                ? ''
                                : 'bg-blue-50/60 dark:bg-blue-950/20'
                        "
                        @click="openNotification(notification)"
                    >
                        <span
                            class="mt-1.5 h-2 w-2 shrink-0 rounded-full"
                            :class="
                                notification.read
                                    ? 'bg-transparent'
                                    : 'bg-blue-500'
                            "
                        />
                        <span class="min-w-0 flex-1">
                            <span
                                class="block truncate text-sm font-medium text-slate-900 dark:text-slate-100"
                            >
                                {{ notification.title }}
                            </span>
                            <span
                                class="mt-0.5 block text-xs text-slate-600 dark:text-slate-400"
                            >
                                {{ notification.body }}
                            </span>
                            <span
                                v-if="notification.created_at"
                                class="mt-1 block text-[11px] text-slate-400 dark:text-slate-500"
                            >
                                {{
                                    new Date(
                                        notification.created_at,
                                    ).toLocaleString()
                                }}
                            </span>
                        </span>
                    </button>
                </div>

                <a
                    href="/account/notifications"
                    class="block border-t border-slate-200 px-4 py-3 text-center text-sm font-medium text-blue-600 hover:bg-slate-50 dark:border-slate-700 dark:text-blue-400 dark:hover:bg-slate-800/60"
                >
                    {{ i18n.t('View all notifications') }}
                </a>
            </div>
        </Transition>
    </Teleport>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.15s ease;
}
.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}

@keyframes wiggle {
    0%,
    100% {
        transform: rotate(0deg);
    }
    25% {
        transform: rotate(-12deg);
    }
    75% {
        transform: rotate(12deg);
    }
}
.animate-wiggle {
    animation: wiggle 0.5s ease-in-out 2;
}
</style>
