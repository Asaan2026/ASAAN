<script setup lang="ts">
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link } from '@inertiajs/vue3';
import { ArrowLeft, Crown, Lock, Users } from 'lucide-vue-next';
import { computed } from 'vue';

interface TopReferrer {
    user_id: number;
    name: string;
    email: string | null;
    total_earned: number;
    awards: number;
    last_award_at: string | null;
    available: number;
    locked: number;
}

interface Settings {
    enabled: boolean;
    reward_amount: number;
    threshold_amount: number;
    lock_days: number;
    level_shares: number[];
    reward_mode: string;
    allow_admin_credit: boolean;
    block_account_deletion: boolean;
    credit_max_percent_of_order: number;
}

const props = defineProps<{
    topReferrers: TopReferrer[];
    settings: Settings;
}>();

const { formatPrice } = useCurrency();

const totalPaidOut = computed(() =>
    props.topReferrers.reduce((sum, person) => sum + person.total_earned, 0),
);

const stillLocked = computed(() =>
    props.topReferrers.reduce((sum, person) => sum + person.locked, 0),
);

const lifetimeAwards = computed(() =>
    props.topReferrers.reduce((sum, person) => sum + person.awards, 0),
);
</script>

<template>
    <Head :title="$t('Top Earners')" />

    <AdminLayout :title="$t('Top Earners')">
        <div class="space-y-6 p-6">
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <Link
                        href="/admin/marketing/referrals"
                        class="inline-flex items-center text-xs font-semibold text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
                    >
                        <ArrowLeft class="mr-1 h-3.5 w-3.5" />
                        {{ $t('Back to overview') }}
                    </Link>
                    <h1
                        class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Top Earners') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{
                            $t(
                                'Everyone who has earned referral credit, best first.',
                            )
                        }}
                    </p>
                </div>
            </div>

            <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <p
                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                    >
                        {{ $t('Paid out in total') }}
                    </p>
                    <p
                        class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ formatPrice(totalPaidOut) }}
                    </p>
                </div>
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <p
                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                    >
                        {{ $t('Still locked') }}
                    </p>
                    <p
                        class="mt-2 text-2xl font-bold text-amber-600 dark:text-amber-400"
                    >
                        {{ formatPrice(stillLocked) }}
                    </p>
                </div>
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <p
                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                    >
                        {{ $t('Rewards awarded') }}
                    </p>
                    <p
                        class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ lifetimeAwards }}
                    </p>
                </div>
            </div>

            <div
                class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div
                    v-if="topReferrers.length === 0"
                    class="px-6 py-12 text-center"
                >
                    <Crown
                        class="mx-auto h-8 w-8 text-gray-300 dark:text-gray-600"
                    />
                    <p class="mt-3 text-sm text-gray-500 dark:text-gray-400">
                        {{ $t('Nobody has earned a reward yet.') }}
                    </p>
                </div>

                <div v-else class="overflow-x-auto">
                    <table
                        class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                    >
                        <thead class="bg-gray-50 dark:bg-gray-700/50">
                            <tr>
                                <th
                                    class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Rank') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Customer') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Earned') }}
                                </th>
                                <th
                                    class="hidden px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Awards') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Available') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Locked') }}
                                </th>
                                <th
                                    class="hidden px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Last reward') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody
                            class="divide-y divide-gray-200 dark:divide-gray-700"
                        >
                            <tr
                                v-for="(person, i) in topReferrers"
                                :key="person.user_id"
                                class="transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10"
                            >
                                <td class="px-6 py-4">
                                    <span
                                        class="inline-flex h-7 w-7 items-center justify-center rounded-full text-xs font-bold"
                                        :class="
                                            i === 0
                                                ? 'bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-300'
                                                : i === 1
                                                  ? 'bg-gray-200 text-gray-700 dark:bg-gray-600 dark:text-gray-200'
                                                  : i === 2
                                                    ? 'bg-orange-100 text-orange-700 dark:bg-orange-900/40 dark:text-orange-300'
                                                    : 'bg-gray-100 text-gray-500 dark:bg-gray-700 dark:text-gray-400'
                                        "
                                    >
                                        {{ i + 1 }}
                                    </span>
                                </td>
                                <td class="px-6 py-4">
                                    <div
                                        class="text-sm font-medium text-gray-900 dark:text-white"
                                    >
                                        {{ person.name }}
                                    </div>
                                    <div
                                        v-if="person.email"
                                        class="text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        {{ person.email }}
                                    </div>
                                </td>
                                <td
                                    class="px-6 py-4 text-right text-sm font-semibold text-gray-900 dark:text-white"
                                >
                                    {{ formatPrice(person.total_earned) }}
                                </td>
                                <td
                                    class="hidden px-6 py-4 text-right text-sm text-gray-500 md:table-cell dark:text-gray-400"
                                >
                                    {{ person.awards }}
                                </td>
                                <td
                                    class="px-6 py-4 text-right text-sm text-green-600 dark:text-green-400"
                                >
                                    {{ formatPrice(person.available) }}
                                </td>
                                <td
                                    class="px-6 py-4 text-right text-sm text-amber-600 dark:text-amber-400"
                                >
                                    <span class="inline-flex items-center">
                                        <Lock
                                            v-if="person.locked > 0"
                                            class="mr-1 h-3 w-3"
                                        />
                                        {{ formatPrice(person.locked) }}
                                    </span>
                                </td>
                                <td
                                    class="hidden px-6 py-4 text-sm text-gray-500 lg:table-cell dark:text-gray-400"
                                >
                                    {{
                                        person.last_award_at
                                            ? String(
                                                  person.last_award_at,
                                              ).slice(0, 10)
                                            : '—'
                                    }}
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <p
                class="flex items-center gap-1.5 text-xs text-gray-500 dark:text-gray-400"
            >
                <Users class="h-3.5 w-3.5" />
                {{
                    $t(
                        'Showing everyone with an active reward, capped at 100. A reward that was reversed does not count here.',
                    )
                }}
            </p>
        </div>
    </AdminLayout>
</template>
