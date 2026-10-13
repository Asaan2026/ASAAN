<script setup lang="ts">
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import { useCalendar } from '@/composables/useCalendar';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link, router, useForm } from '@inertiajs/vue3';
import {
    Ban,
    CheckCircle2,
    Filter,
    Lock,
    Search,
    Undo2,
    X,
} from 'lucide-vue-next';
import { ref, watch } from 'vue';

interface Commission {
    id: number;
    referrer_name: string;
    referrer_email: string | null;
    referred_name: string;
    order_number: string | null;
    level: number;
    amount: number;
    reward_snapshot: number;
    share_snapshot: number;
    status: string;
    unlocks_at: string | null;
    is_locked: boolean;
    reversal_reason: string | null;
    created_at: string | null;
}

interface Props {
    commissions: {
        data: Commission[];
        current_page: number;
        last_page: number;
        total: number;
        from: number | null;
        to: number | null;
        prev_page_url: string | null;
        next_page_url: string | null;
    };
    filters: {
        search?: string;
        status?: string;
        level?: string;
    };
}

const props = defineProps<Props>();

const { formatPrice } = useCurrency();
const { formatDate: formatCalendarDate } = useCalendar();

const searchQuery = ref(props.filters.search ?? '');
const statusFilter = ref(props.filters.status ?? '');
const levelFilter = ref(props.filters.level ?? '');

watch(
    () => props.filters,
    (value) => {
        searchQuery.value = value.search ?? '';
        statusFilter.value = value.status ?? '';
        levelFilter.value = value.level ?? '';
    },
);

const applyFilters = () => {
    router.get(
        '/admin/marketing/referrals/commissions',
        {
            search: searchQuery.value || undefined,
            status: statusFilter.value || undefined,
            level: levelFilter.value || undefined,
        },
        { preserveState: true, replace: true },
    );
};

const clearFilters = () => {
    searchQuery.value = '';
    statusFilter.value = '';
    levelFilter.value = '';
    router.get(
        '/admin/marketing/referrals/commissions',
        {},
        { preserveState: true, replace: true },
    );
};

const reverseForm = useForm({ reason: '' });
const reversing = ref<number | null>(null);

const openReverse = (commission: Commission) => {
    reversing.value = reversing.value === commission.id ? null : commission.id;
    reverseForm.reason = '';
    reverseForm.clearErrors();
};

const submitReverse = (commission: Commission) => {
    reverseForm.post(
        `/admin/marketing/referrals/commissions/${commission.id}/reverse`,
        {
            preserveScroll: true,
            onSuccess: () => {
                reversing.value = null;
                reverseForm.reset();
            },
        },
    );
};

const pageTotal = (data: Commission[]) =>
    data.reduce((sum, c) => sum + (c.status === 'active' ? c.amount : 0), 0);
</script>

<template>
    <Head :title="$t('Referral Rewards')" />

    <AdminLayout :title="$t('Referral Rewards')">
        <div class="space-y-6 p-6">
            <div>
                <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
                    {{ $t('Rewards') }}
                </h1>
                <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                    {{
                        $t(
                            'Every referral reward that has been granted, with the order that triggered it.',
                        )
                    }}
                </p>
            </div>

            <!-- Filters -->
            <div
                class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="grid grid-cols-1 gap-4 md:grid-cols-12">
                    <div class="md:col-span-6">
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Search') }}</label
                        >
                        <div class="relative">
                            <Search
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <input
                                v-model="searchQuery"
                                type="text"
                                :placeholder="$t('Customer or order number...')"
                                class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm text-gray-900 transition-all placeholder:text-gray-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                @keyup.enter="applyFilters"
                            />
                        </div>
                    </div>

                    <div class="md:col-span-3">
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Status') }}</label
                        >
                        <div class="relative">
                            <Filter
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="statusFilter"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">{{ $t('Any status') }}</option>
                                <option value="active">
                                    {{ $t('Active') }}
                                </option>
                                <option value="reversed">
                                    {{ $t('Reversed') }}
                                </option>
                                <option value="locked">
                                    {{ $t('Locked right now') }}
                                </option>
                                <option value="available">
                                    {{ $t('Available to spend') }}
                                </option>
                            </select>
                        </div>
                    </div>

                    <div class="md:col-span-3">
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Level') }}</label
                        >
                        <select
                            v-model="levelFilter"
                            @change="applyFilters"
                            class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 px-4 py-2.5 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                        >
                            <option value="">{{ $t('Any level') }}</option>
                            <option value="1">{{ $t('Level 1') }}</option>
                            <option value="2">{{ $t('Level 2') }}</option>
                        </select>
                    </div>
                </div>

                <div
                    v-if="searchQuery || statusFilter || levelFilter"
                    class="mt-4 flex justify-end border-t border-gray-200 pt-4 dark:border-gray-700"
                >
                    <button
                        @click="clearFilters"
                        class="flex items-center gap-2 rounded-lg bg-gray-100 px-4 py-2 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-200 hover:text-gray-900 dark:bg-gray-700 dark:text-gray-400 dark:hover:bg-gray-600 dark:hover:text-gray-200"
                    >
                        <X class="h-4 w-4" />
                        {{ $t('Clear Filters') }}
                    </button>
                </div>
            </div>

            <!-- Table -->
            <div
                class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div
                    v-if="commissions.data.length === 0"
                    class="px-6 py-12 text-center"
                >
                    <p class="text-sm text-gray-500 dark:text-gray-400">
                        {{
                            searchQuery || statusFilter || levelFilter
                                ? $t('No rewards match those filters.')
                                : $t('No rewards have been granted yet.')
                        }}
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
                                    {{ $t('Earned by') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('From') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Order') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Amount') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Actions') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody
                            class="divide-y divide-gray-200 dark:divide-gray-700"
                        >
                            <template v-for="c in commissions.data" :key="c.id">
                                <tr
                                    class="hover:bg-gray-50 dark:hover:bg-gray-700/20"
                                >
                                    <td class="px-6 py-4">
                                        <div
                                            class="text-sm font-medium text-gray-900 dark:text-white"
                                        >
                                            {{ c.referrer_name }}
                                        </div>
                                        <div
                                            class="text-xs text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t('Level {level}', {
                                                    level: c.level,
                                                })
                                            }}
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-sm text-gray-500 dark:text-gray-400"
                                    >
                                        {{ c.referred_name }}
                                    </td>
                                    <td class="px-6 py-4">
                                        <div
                                            class="font-mono text-sm text-gray-900 dark:text-white"
                                        >
                                            {{ c.order_number ?? '—' }}
                                        </div>
                                        <div
                                            class="text-xs text-gray-500 dark:text-gray-400"
                                        >
                                            <DateDisplay
                                                :value="c.created_at"
                                            />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 text-right">
                                        <div
                                            class="text-sm font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ formatPrice(c.amount) }}
                                        </div>
                                        <div
                                            class="text-[10px] text-gray-400 dark:text-gray-500"
                                        >
                                            {{
                                                $t('{share}% of {amount}', {
                                                    share: c.share_snapshot,
                                                    amount: formatPrice(
                                                        c.reward_snapshot,
                                                    ),
                                                })
                                            }}
                                        </div>
                                    </td>
                                    <td class="px-6 py-4">
                                        <span
                                            v-if="c.status === 'reversed'"
                                            class="inline-flex items-center gap-1 rounded-full bg-red-100 px-2 py-1 text-xs font-medium text-red-800 dark:bg-red-900/30 dark:text-red-300"
                                            :title="
                                                c.reversal_reason ?? undefined
                                            "
                                        >
                                            <Ban class="h-3 w-3" />
                                            {{ $t('Reversed') }}
                                        </span>
                                        <span
                                            v-else-if="c.is_locked"
                                            class="inline-flex items-center gap-1 rounded-full bg-amber-100 px-2 py-1 text-xs font-medium text-amber-800 dark:bg-amber-900/30 dark:text-amber-300"
                                        >
                                            <Lock class="h-3 w-3" />
                                            {{
                                                $t('Until {date}', {
                                                    date: formatCalendarDate(
                                                        c.unlocks_at ?? '',
                                                    ),
                                                })
                                            }}
                                        </span>
                                        <span
                                            v-else
                                            class="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-1 text-xs font-medium text-green-800 dark:bg-green-900/30 dark:text-green-300"
                                        >
                                            <CheckCircle2 class="h-3 w-3" />
                                            {{ $t('Available') }}
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 text-right">
                                        <button
                                            v-if="c.status === 'active'"
                                            @click="openReverse(c)"
                                            class="inline-flex items-center text-xs font-semibold text-red-600 hover:underline dark:text-red-400"
                                        >
                                            <Undo2 class="mr-1 h-3.5 w-3.5" />
                                            {{ $t('Reverse') }}
                                        </button>
                                        <span
                                            v-else
                                            class="text-xs text-gray-400"
                                            >—</span
                                        >
                                    </td>
                                </tr>

                                <tr
                                    v-if="reversing === c.id"
                                    class="bg-red-50 dark:bg-red-900/10"
                                >
                                    <td colspan="6" class="px-6 py-4">
                                        <label
                                            class="mb-1.5 block text-xs font-semibold text-red-800 dark:text-red-300"
                                        >
                                            {{
                                                $t(
                                                    'Why is this being taken back? The customer sees this in their history.',
                                                )
                                            }}
                                        </label>
                                        <input
                                            v-model="reverseForm.reason"
                                            type="text"
                                            :placeholder="
                                                $t(
                                                    'e.g. The referred order was refunded',
                                                )
                                            "
                                            class="w-full rounded-lg border border-red-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-red-500 focus:ring-2 focus:ring-red-500/20 dark:border-red-700 dark:bg-gray-800 dark:text-gray-100"
                                            @keyup.enter="submitReverse(c)"
                                        />
                                        <p
                                            v-if="reverseForm.errors.reason"
                                            class="mt-1 text-xs text-red-600 dark:text-red-400"
                                        >
                                            {{ reverseForm.errors.reason }}
                                        </p>
                                        <div class="mt-3 flex gap-2">
                                            <button
                                                @click="submitReverse(c)"
                                                :disabled="
                                                    reverseForm.processing
                                                "
                                                class="rounded-lg bg-red-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-red-700 disabled:opacity-50"
                                            >
                                                {{
                                                    reverseForm.processing
                                                        ? $t('Reversing...')
                                                        : $t('Take back')
                                                }}
                                            </button>
                                            <button
                                                @click="reversing = null"
                                                class="rounded-lg bg-gray-200 px-3 py-1.5 text-xs font-semibold text-gray-700 hover:bg-gray-300 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                                            >
                                                {{ $t('Cancel') }}
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            </template>
                        </tbody>
                    </table>
                </div>

                <div
                    v-if="commissions.data.length > 0"
                    class="flex items-center justify-between border-t border-gray-100 px-6 py-4 dark:border-gray-700"
                >
                    <div class="text-sm text-gray-500 dark:text-gray-400">
                        {{
                            $t('Showing {from} to {to} of {total} rewards', {
                                from: commissions.from,
                                to: commissions.to,
                                total: commissions.total,
                            })
                        }}
                        ({{
                            $t('{amount} active on this page', {
                                amount: formatPrice(
                                    pageTotal(commissions.data),
                                ),
                            })
                        }})
                    </div>
                    <div class="flex gap-2">
                        <Link
                            v-if="commissions.prev_page_url"
                            :href="commissions.prev_page_url"
                            class="rounded-md border border-gray-300 px-3 py-1 text-sm text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                        >
                            {{ $t('Previous') }}
                        </Link>
                        <Link
                            v-if="commissions.next_page_url"
                            :href="commissions.next_page_url"
                            class="rounded-md border border-gray-300 px-3 py-1 text-sm text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                        >
                            {{ $t('Next') }}
                        </Link>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>
