<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import axios from '@/lib/axios';
import { useI18nStore } from '@/Stores/i18n';
import { Head, Link, useForm, usePage } from '@inertiajs/vue3';
import { computed, onMounted, ref } from 'vue';

interface OptionItem {
    value: string;
    label: string;
}

interface Props {
    settings: {
        enabled: boolean;
        email: string;
        password: string;
        pickup_location: string;
        channel_id: string;
    };
}

const props = defineProps<Props>();
const page = usePage();
const errors = computed(() => page.props.errors as Record<string, string>);
const { t } = useI18nStore();
const pickupOptions = ref<OptionItem[]>(
    props.settings.pickup_location
        ? [
              {
                  value: props.settings.pickup_location,
                  label: props.settings.pickup_location,
              },
          ]
        : [],
);
const channelOptions = ref<OptionItem[]>(
    props.settings.channel_id
        ? [
              {
                  value: props.settings.channel_id,
                  label: props.settings.channel_id,
              },
          ]
        : [],
);

const form = useForm({
    enabled: props.settings.enabled ?? false,
    email: props.settings.email ?? '',
    password: props.settings.password ?? '',
    pickup_location: props.settings.pickup_location ?? 'Primary',
    channel_id: props.settings.channel_id ?? '',
});

const testState = useForm({
    email: props.settings.email ?? '',
    password: props.settings.password ?? '',
});

const save = () => {
    form.post('/admin/settings/shiprocket', {
        preserveScroll: true,
    });
};

const applyFetchedOptions = (responseData: any) => {
    const fetchedPickupOptions = Array.isArray(responseData?.pickup_locations)
        ? (responseData.pickup_locations as OptionItem[])
        : [];
    const fetchedChannelOptions = Array.isArray(responseData?.channels)
        ? (responseData.channels as OptionItem[])
        : [];

    pickupOptions.value = fetchedPickupOptions;
    channelOptions.value = fetchedChannelOptions;

    const hasSelectedPickup = fetchedPickupOptions.some(
        (option) => option.value === form.pickup_location,
    );
    if (!hasSelectedPickup && fetchedPickupOptions.length > 0) {
        form.pickup_location = fetchedPickupOptions[0].value;
    }

    const hasSelectedChannel = fetchedChannelOptions.some(
        (option) => option.value === form.channel_id,
    );
    if (!hasSelectedChannel) {
        form.channel_id = fetchedChannelOptions[0]?.value || '';
    }
};

const testConnection = async () => {
    testState.processing = true;

    try {
        const response = await axios.post(
            '/admin/settings/shiprocket/test-connection',
            {
                email: testState.email || form.email,
                password: testState.password || form.password,
            },
        );

        applyFetchedOptions(response.data);

        window.dispatchEvent(
            new CustomEvent('show-toast', {
                detail: {
                    message:
                        response.data?.message ||
                        t('Shiprocket connection successful.'),
                    type: 'success',
                },
            }),
        );
    } catch (error: any) {
        const message =
            error?.response?.data?.message ||
            error.message ||
            t('Shiprocket connection failed.');
        window.dispatchEvent(
            new CustomEvent('show-toast', {
                detail: { message, type: 'error' },
            }),
        );
    } finally {
        testState.processing = false;
    }
};

onMounted(async () => {
    if (!form.enabled || !form.email || !form.password) {
        return;
    }

    try {
        const response = await axios.get('/admin/settings/shiprocket/metadata');
        applyFetchedOptions(response.data);
    } catch {
        // keep existing saved fallback values when metadata fetch fails
    }
});
</script>

<template>
    <Head :title="$t('Shiprocket Settings')" />

    <AdminLayout :title="$t('Shiprocket Settings')">
        <div class="space-y-6">
            <div class="flex items-center justify-between">
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Shiprocket Shipment Settings') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{
                            $t(
                                'Configure Shiprocket API credentials and defaults.',
                            )
                        }}
                    </p>
                </div>
                <Link
                    href="/admin/settings/shipping-methods"
                    class="inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                >
                    {{ $t('Back to Shipping Methods') }}
                </Link>
            </div>

            <form
                @submit.prevent="save"
                class="rounded-lg border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Connection') }}
                    </h2>

                    <label class="mb-4 inline-flex items-center gap-2">
                        <input
                            v-model="form.enabled"
                            type="checkbox"
                            class="rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600"
                        />
                        <span
                            class="text-sm font-medium text-gray-800 dark:text-gray-200"
                            >{{ $t('Enable Shiprocket integration') }}</span
                        >
                    </label>

                    <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Email') }}
                                <span class="text-red-500">*</span></label
                            >
                            <input
                                v-model="form.email"
                                type="email"
                                :class="[
                                    'w-full rounded-lg border bg-white px-3 py-2 text-gray-900 dark:bg-gray-700 dark:text-white',
                                    errors.email
                                        ? 'border-red-500'
                                        : 'border-gray-300 dark:border-gray-600',
                                ]"
                                placeholder="your-email@example.com"
                            />
                            <p
                                v-if="errors.email"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.email }}
                            </p>
                        </div>

                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Password') }}
                                <span class="text-red-500">*</span></label
                            >
                            <input
                                v-model="form.password"
                                type="password"
                                :class="[
                                    'w-full rounded-lg border bg-white px-3 py-2 text-gray-900 dark:bg-gray-700 dark:text-white',
                                    errors.password
                                        ? 'border-red-500'
                                        : 'border-gray-300 dark:border-gray-600',
                                ]"
                                :placeholder="$t('Shiprocket account password')"
                            />
                            <p
                                v-if="errors.password"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.password }}
                            </p>
                        </div>

                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Pickup Location') }}</label
                            >
                            <select
                                v-model="form.pickup_location"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            >
                                <option value="">
                                    {{ $t('Select pickup location') }}
                                </option>
                                <option
                                    v-for="location in pickupOptions"
                                    :key="location.value"
                                    :value="location.value"
                                >
                                    {{ location.label }}
                                </option>
                            </select>
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        'Locations are auto-fetched from Shiprocket when this page loads.',
                                    )
                                }}
                            </p>
                        </div>

                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Channel ID (Optional)') }}</label
                            >
                            <select
                                v-model="form.channel_id"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            >
                                <option value="">{{ $t('No channel') }}</option>
                                <option
                                    v-for="channel in channelOptions"
                                    :key="channel.value"
                                    :value="channel.value"
                                >
                                    {{ channel.label }}
                                </option>
                            </select>
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        'Channels are auto-fetched from Shiprocket when this page loads.',
                                    )
                                }}
                            </p>
                        </div>
                    </div>
                </div>

                <div class="flex items-center justify-between gap-3 p-6">
                    <button
                        type="button"
                        @click="testConnection"
                        :disabled="testState.processing"
                        class="inline-flex items-center rounded-lg border border-indigo-300 px-4 py-2 text-sm font-medium text-indigo-700 hover:bg-indigo-50 disabled:opacity-50 dark:border-indigo-700 dark:text-indigo-300 dark:hover:bg-indigo-900/20"
                    >
                        {{
                            testState.processing
                                ? $t('Testing...')
                                : $t('Test Connection')
                        }}
                    </button>

                    <button
                        type="submit"
                        :disabled="form.processing"
                        class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        {{
                            form.processing
                                ? $t('Saving...')
                                : $t('Save Shiprocket Settings')
                        }}
                    </button>
                </div>
            </form>
        </div>
    </AdminLayout>
</template>
