<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, useForm } from '@inertiajs/vue3';
import { Bell, CheckCircle2, Cloud, Send, Smartphone } from 'lucide-vue-next';

interface Props {
    settings?: {
        notifications_push_enabled: boolean;
        notifications_customer_order_updates: boolean;
        notifications_admin_new_orders: boolean;
        notifications_admin_new_reviews: boolean;
        notifications_admin_new_messages: boolean;
    };
    fcm?: {
        project_id: string;
        credentials_path: string;
        credentials_present: boolean;
        notification_channel: string;
        source: 'dashboard' | 'server' | 'none';
        client_email: string;
    };
}

const props = withDefaults(defineProps<Props>(), {
    settings: () => ({
        notifications_push_enabled: true,
        notifications_customer_order_updates: true,
        notifications_admin_new_orders: true,
        notifications_admin_new_reviews: true,
        notifications_admin_new_messages: true,
    }),
    fcm: () => ({
        project_id: '',
        credentials_path: '',
        credentials_present: false,
        notification_channel: '',
        source: 'none' as const,
        client_email: '',
    }),
});

const form = useForm({
    notifications_push_enabled:
        props.settings.notifications_push_enabled ?? true,
    notifications_customer_order_updates:
        props.settings.notifications_customer_order_updates ?? true,
    notifications_admin_new_orders:
        props.settings.notifications_admin_new_orders ?? true,
    notifications_admin_new_reviews:
        props.settings.notifications_admin_new_reviews ?? true,
    notifications_admin_new_messages:
        props.settings.notifications_admin_new_messages ?? true,
});

const save = () => {
    form.post('/admin/settings/notifications', {
        preserveScroll: true,
    });
};

const sendTestPush = () => {
    useForm({}).post('/admin/settings/notifications/test', {
        preserveScroll: true,
    });
};

// Uploading the Firebase key. Its own form, so saving the switches above does
// not require picking the file again.
const keyForm = useForm<{ key: File | null }>({ key: null });

const chooseKey = (event: Event) => {
    const input = event.target as HTMLInputElement;
    keyForm.key = input.files?.[0] ?? null;
};

const uploadKey = () => {
    if (!keyForm.key) return;
    keyForm.post('/admin/settings/notifications/firebase-key', {
        preserveScroll: true,
        forceFormData: true,
        onSuccess: () => keyForm.reset('key'),
    });
};

const removeKey = () => {
    useForm({}).delete('/admin/settings/notifications/firebase-key', {
        preserveScroll: true,
    });
};

const switches = [
    {
        key: 'notifications_push_enabled' as const,
        label: 'Send push notifications to phones',
        help: 'When off, customers still see notifications in the app, but their phones do not buzz.',
        master: true,
    },
    {
        key: 'notifications_customer_order_updates' as const,
        label: 'Order updates to customers',
        help: 'Tell the customer when their order is received, processed, completed or cancelled.',
    },
    {
        key: 'notifications_admin_new_orders' as const,
        label: 'New orders to admins',
        help: 'Show a bell notification for every new order.',
    },
    {
        key: 'notifications_admin_new_reviews' as const,
        label: 'New reviews to admins',
        help: 'Show a bell notification when a customer submits a product review.',
    },
    {
        key: 'notifications_admin_new_messages' as const,
        label: 'New contact messages to admins',
        help: 'Show a bell notification when someone sends a message from the contact form.',
    },
];
</script>

<template>
    <AdminLayout :title="$t('Notifications')">
        <Head :title="$t('Notifications')" />

        <div class="space-y-6">
            <div>
                <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
                    {{ $t('Notifications') }}
                </h1>
                <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                    {{
                        $t(
                            'Choose what reaches customers and admins, and test that push reaches a phone.',
                        )
                    }}
                </p>
            </div>

            <form @submit.prevent="save">
                <div
                    class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <!-- Switches -->
                    <div class="space-y-6 p-6 sm:p-8">
                        <div class="flex items-center gap-2">
                            <Bell class="h-5 w-5 text-gray-400" />
                            <h3
                                class="text-lg font-semibold text-gray-900 dark:text-white"
                            >
                                {{ $t('What to send') }}
                            </h3>
                        </div>

                        <div
                            v-for="item in switches"
                            :key="item.key"
                            class="flex items-start"
                        >
                            <div class="flex h-5 items-center">
                                <input
                                    :id="item.key"
                                    v-model="form[item.key]"
                                    type="checkbox"
                                    class="h-4 w-4 rounded border-gray-300 text-blue-600 transition duration-150 ease-in-out focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                />
                            </div>
                            <div class="ml-3 text-sm">
                                <label
                                    :for="item.key"
                                    class="font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t(item.label) }}
                                </label>
                                <p
                                    class="mt-1 text-gray-500 dark:text-gray-400"
                                >
                                    {{ $t(item.help) }}
                                </p>
                            </div>
                        </div>
                    </div>

                    <!-- Firebase status (read-only) -->
                    <div
                        class="space-y-4 border-t border-gray-100 bg-gray-50 p-6 sm:p-8 dark:border-gray-700 dark:bg-gray-900/50"
                    >
                        <div class="flex items-center gap-2">
                            <Cloud class="h-5 w-5 text-gray-400" />
                            <h3
                                class="text-lg font-semibold text-gray-900 dark:text-white"
                            >
                                {{ $t('Firebase push key') }}
                            </h3>
                        </div>

                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            {{
                                $t(
                                    'Phones can only be reached once this key is in place. Download it from the Firebase console under Project settings, Service accounts, "Generate new private key", then upload the file here. It is stored privately on the server and never shown again.',
                                )
                            }}
                        </p>

                        <div
                            class="flex flex-col gap-3 rounded-lg border border-gray-200 bg-gray-50 p-4 sm:flex-row sm:items-center dark:border-gray-700 dark:bg-gray-800/60"
                        >
                            <input
                                type="file"
                                accept=".json,application/json"
                                class="block w-full text-sm text-gray-700 file:mr-3 file:rounded-md file:border-0 file:bg-blue-600 file:px-3 file:py-2 file:text-sm file:font-semibold file:text-white hover:file:bg-blue-700 dark:text-gray-200"
                                @change="chooseKey"
                            />
                            <button
                                type="button"
                                class="inline-flex shrink-0 items-center justify-center rounded-lg bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                                :disabled="!keyForm.key || keyForm.processing"
                                @click="uploadKey"
                            >
                                {{
                                    keyForm.processing
                                        ? $t('Uploading...')
                                        : $t('Upload key')
                                }}
                            </button>
                            <button
                                v-if="fcm.source === 'dashboard'"
                                type="button"
                                class="inline-flex shrink-0 items-center justify-center rounded-lg border border-gray-300 bg-white px-4 py-2 text-xs font-semibold tracking-widest text-gray-700 uppercase transition hover:bg-gray-100 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-200"
                                @click="removeKey"
                            >
                                {{ $t('Remove') }}
                            </button>
                        </div>

                        <p
                            v-if="keyForm.errors.key"
                            class="text-sm font-medium text-red-600 dark:text-red-400"
                        >
                            {{ keyForm.errors.key }}
                        </p>

                        <dl
                            class="grid grid-cols-1 gap-3 text-sm sm:grid-cols-2"
                        >
                            <div>
                                <dt
                                    class="font-medium text-gray-500 dark:text-gray-400"
                                >
                                    {{ $t('Project ID') }}
                                </dt>
                                <dd class="text-gray-900 dark:text-white">
                                    {{ fcm.project_id || $t('Not set') }}
                                </dd>
                            </div>
                            <div>
                                <dt
                                    class="font-medium text-gray-500 dark:text-gray-400"
                                >
                                    {{ $t('Credentials file') }}
                                </dt>
                                <dd class="text-gray-900 dark:text-white">
                                    {{
                                        fcm.credentials_path || $t('Not set')
                                    }}
                                </dd>
                            </div>
                            <div>
                                <dt
                                    class="font-medium text-gray-500 dark:text-gray-400"
                                >
                                    {{ $t('File present') }}
                                </dt>
                                <dd>
                                    <span
                                        v-if="fcm.credentials_present"
                                        class="inline-flex items-center gap-1 font-medium text-green-600 dark:text-green-400"
                                    >
                                        <CheckCircle2 class="h-4 w-4" />
                                        {{ $t('Yes') }}
                                    </span>
                                    <span
                                        v-else
                                        class="font-medium text-red-600 dark:text-red-400"
                                    >
                                        {{ $t('No') }}
                                    </span>
                                </dd>
                            </div>
                            <div>
                                <dt
                                    class="font-medium text-gray-500 dark:text-gray-400"
                                >
                                    {{ $t('Key source') }}
                                </dt>
                                <dd class="text-gray-900 dark:text-white">
                                    <span v-if="fcm.source === 'dashboard'">
                                        {{ $t('Uploaded here') }}
                                    </span>
                                    <span v-else-if="fcm.source === 'server'">
                                        {{ $t('Set on the server (.env)') }}
                                    </span>
                                    <span v-else>{{ $t('Not set') }}</span>
                                </dd>
                            </div>
                            <div v-if="fcm.client_email">
                                <dt
                                    class="font-medium text-gray-500 dark:text-gray-400"
                                >
                                    {{ $t('Signs in as') }}
                                </dt>
                                <dd class="truncate text-gray-900 dark:text-white">
                                    {{ fcm.client_email }}
                                </dd>
                            </div>
                            <div>
                                <dt
                                    class="font-medium text-gray-500 dark:text-gray-400"
                                >
                                    {{ $t('Android channel') }}
                                </dt>
                                <dd class="text-gray-900 dark:text-white">
                                    {{
                                        fcm.notification_channel ||
                                        $t('Firebase default')
                                    }}
                                </dd>
                            </div>
                        </dl>
                    </div>

                    <!-- Save -->
                    <div
                        class="flex flex-col gap-3 border-t border-gray-200 bg-gray-50 px-6 py-4 sm:flex-row sm:items-center sm:justify-between dark:border-gray-700 dark:bg-gray-800"
                    >
                        <button
                            type="button"
                            class="inline-flex items-center justify-center rounded-lg border border-gray-300 bg-white px-4 py-2 text-xs font-semibold tracking-widest text-gray-700 uppercase transition duration-150 hover:bg-gray-100 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-gray-200 dark:hover:bg-gray-600"
                            @click="sendTestPush"
                        >
                            <Send class="mr-2 h-4 w-4" />
                            {{ $t('Send test push to my phone') }}
                        </button>

                        <button
                            type="submit"
                            :disabled="form.processing"
                            class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            <Smartphone
                                v-if="!form.processing"
                                class="mr-2 h-4 w-4"
                            />
                            <svg
                                v-else
                                class="mr-2 h-4 w-4 animate-spin"
                                fill="none"
                                viewBox="0 0 24 24"
                            >
                                <circle
                                    class="opacity-25"
                                    cx="12"
                                    cy="12"
                                    r="10"
                                    stroke="currentColor"
                                    stroke-width="4"
                                ></circle>
                                <path
                                    class="opacity-75"
                                    fill="currentColor"
                                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                                ></path>
                            </svg>
                            {{
                                form.processing
                                    ? $t('Saving...')
                                    : $t('Save settings')
                            }}
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </AdminLayout>
</template>
