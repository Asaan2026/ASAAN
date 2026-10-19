<script setup lang="ts">
/**
 * The customer's full notification history on the website.
 *
 * Mirrors the phone app's notification centre: same wording, same fields. Tapping
 * an order notification opens that order and marks it read; everything else just
 * marks read.
 */
import { Head, Link, router } from '@inertiajs/vue3';
import axios from 'axios';
import { Bell, CheckCheck } from 'lucide-vue-next';
import { ref } from 'vue';
import ThemeLayout from '../../../layouts/ThemeLayout.vue';

interface CustomerNotification {
    id: number;
    type: string;
    title: string;
    body: string;
    data: Record<string, unknown>;
    read: boolean;
    read_at: string | null;
    created_at: string | null;
}

interface Paginated {
    data: CustomerNotification[];
    current_page: number;
    last_page: number;
    total: number;
    links: { url: string | null; label: string; active: boolean }[];
}

const props = defineProps<{ notifications: Paginated }>();

const items = ref<CustomerNotification[]>(props.notifications.data);
const markingAll = ref(false);

function targetFor(notification: CustomerNotification): string | null {
    const orderId = notification.data?.order_id;
    if (notification.type === 'order' && orderId) {
        return `/account/orders/${orderId}`;
    }

    return null;
}

async function openNotification(notification: CustomerNotification) {
    if (!notification.read) {
        try {
            await axios.post(
                `/account/notifications/${notification.id}/read`,
                {},
                { headers: { Accept: 'application/json' } },
            );
            notification.read = true;
        } catch {
            // Still navigate even if the mark-read call fails.
        }
    }

    const target = targetFor(notification);
    if (target) {
        window.location.href = target;
    }
}

async function markAllRead() {
    markingAll.value = true;
    try {
        await axios.post(
            '/account/notifications/read-all',
            {},
            { headers: { Accept: 'application/json' } },
        );
        items.value = items.value.map((item) => ({ ...item, read: true }));
    } catch {
        // Nothing to do; the list stays as-is.
    } finally {
        markingAll.value = false;
    }
}
</script>

<template>
    <ThemeLayout>
        <Head :title="$t('Notifications')" />

        <div class="container mx-auto px-4 py-8">
            <div class="mx-auto max-w-3xl">
                <div class="mb-6 flex items-center justify-between gap-4">
                    <div>
                        <h1 class="mb-1 text-3xl font-bold">
                            {{ $t('Notifications') }}
                        </h1>
                        <p class="text-gray-600 dark:text-slate-400">
                            {{ $t('Updates about your orders and account') }}
                        </p>
                    </div>
                    <button
                        v-if="items.some((item) => !item.read)"
                        type="button"
                        class="inline-flex items-center gap-2 rounded-lg border border-gray-300 px-3 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 disabled:opacity-50 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-800"
                        :disabled="markingAll"
                        @click="markAllRead"
                    >
                        <CheckCheck class="h-4 w-4" />
                        {{ $t('Mark all read') }}
                    </button>
                </div>

                <div
                    v-if="items.length > 0"
                    class="divide-y divide-gray-200 overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm dark:divide-slate-700 dark:border-slate-700 dark:bg-slate-900"
                >
                    <button
                        v-for="notification in items"
                        :key="notification.id"
                        type="button"
                        class="flex w-full items-start gap-3 px-5 py-4 text-left transition-colors hover:bg-gray-50 dark:hover:bg-slate-800/60"
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
                                class="block text-sm font-semibold text-gray-900 dark:text-slate-100"
                            >
                                {{ notification.title }}
                            </span>
                            <span
                                class="mt-0.5 block text-sm text-gray-600 dark:text-slate-400"
                            >
                                {{ notification.body }}
                            </span>
                            <span
                                v-if="notification.created_at"
                                class="mt-1 block text-xs text-gray-400 dark:text-slate-500"
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

                <div
                    v-else
                    class="rounded-lg border border-gray-200 bg-white p-12 text-center shadow-sm dark:border-slate-700 dark:bg-slate-900"
                >
                    <Bell
                        class="mx-auto mb-4 h-16 w-16 text-gray-400 dark:text-slate-500"
                    />
                    <h3 class="mb-2 text-xl font-semibold">
                        {{ $t('No notifications yet') }}
                    </h3>
                    <p class="mb-6 text-gray-600 dark:text-slate-400">
                        {{
                            $t(
                                'Order updates and account messages will appear here',
                            )
                        }}
                    </p>
                    <Link
                        href="/products"
                        class="inline-block rounded-lg bg-blue-600 px-6 py-3 text-white transition-colors hover:bg-blue-700"
                    >
                        {{ $t('Continue Shopping') }}
                    </Link>
                </div>

                <div
                    v-if="notifications.last_page > 1"
                    class="mt-8 flex justify-center gap-2"
                >
                    <Link
                        v-for="link in notifications.links"
                        :key="link.label"
                        :href="link.url || '#'"
                        class="rounded-lg border px-3 py-2 text-sm"
                        :class="[
                            link.active
                                ? 'border-blue-600 bg-blue-600 text-white'
                                : 'border-gray-300 bg-white text-gray-700 hover:bg-gray-50 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-200',
                            !link.url ? 'pointer-events-none opacity-50' : '',
                        ]"
                        preserve-scroll
                        v-html="link.label"
                    />
                </div>
            </div>
        </div>
    </ThemeLayout>
</template>
