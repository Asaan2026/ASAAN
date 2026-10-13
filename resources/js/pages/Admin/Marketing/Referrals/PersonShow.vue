<script setup lang="ts">
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import { useCalendar } from '@/composables/useCalendar';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link, useForm } from '@inertiajs/vue3';
import {
    ArrowLeft,
    Ban,
    Check,
    Copy,
    Gift,
    Link2,
    Lock,
    ScrollText,
    SlidersHorizontal,
    UserPlus,
    Users,
    Wallet,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Person {
    id: number;
    name: string;
    email: string;
    phone: string | null;
    created_at: string | null;
    code: string;
    share_link: string;
    clicks: number;
    code_status: string;
}

interface Balances {
    available: number;
    locked: number;
    earned: number;
    spent: number;
}

interface ReferralRow {
    id: number;
    referred_name: string;
    referred_email: string | null;
    level: number;
    status: string;
    lifetime_spend: number;
    rewarded_at: string | null;
    created_at: string | null;
}

interface Commission {
    id: number;
    order_number: string | null;
    level: number;
    amount: number;
    status: string;
    unlocks_at: string | null;
    created_at: string | null;
}

interface LedgerEntry {
    id: number;
    type: string;
    amount: number;
    balance_after: number;
    reason: string | null;
    created_at: string | null;
}

const props = defineProps<{
    allowManualCredit: boolean;
    person: Person;
    balances: Balances;
    referredBy: { id: number; name: string; email: string } | null;
    referralsMade: ReferralRow[];
    commissions: Commission[];
    ledger: LedgerEntry[];
}>();

const { formatPrice } = useCurrency();
const { formatDate: formatCalendarDate } = useCalendar();

const copied = ref(false);

const copyLink = async () => {
    try {
        await navigator.clipboard.writeText(props.person.share_link);
        copied.value = true;
        setTimeout(() => (copied.value = false), 1500);
    } catch {
        // The browser refused clipboard access. The link is on screen.
    }
};

const ledgerLabel: Record<string, string> = {
    earned: 'Reward earned',
    spent: 'Spent at checkout',
    reversed: 'Reward reversed',
    admin_credit: 'Added by staff',
    admin_debit: 'Taken by staff',
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

const creditForm = useForm({
    user_id: String(props.person.id),
    type: 'admin_credit' as 'admin_credit' | 'admin_debit',
    amount: '',
    reason: '',
});

const submitCredit = () => {
    creditForm
        .transform((data) => ({
            ...data,
            user_id: Number(data.user_id),
            amount: Number(data.amount),
        }))
        .post('/admin/marketing/referrals/credit', {
            preserveScroll: true,
            onSuccess: () => creditForm.reset('amount', 'reason'),
        });
};

// Taking more than the customer has is refused by the server, but the page
// should not offer a button that is guaranteed to fail.
const takingTooMuch = computed(
    () =>
        creditForm.type === 'admin_debit' &&
        Number(creditForm.amount || 0) > props.balances.available,
);
</script>

<template>
    <Head :title="person.name" />

    <AdminLayout :title="person.name">
        <div class="space-y-6 p-6">
            <div>
                <Link
                    href="/admin/marketing/referrals/people"
                    class="inline-flex items-center text-xs font-semibold text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
                >
                    <ArrowLeft class="mr-1 h-3.5 w-3.5" />
                    {{ $t('Back to people') }}
                </Link>
                <h1
                    class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                >
                    {{ person.name }}
                </h1>
                <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                    {{ person.email
                    }}<span v-if="person.phone"> · {{ person.phone }}</span>
                </p>
                <p
                    v-if="person.created_at"
                    class="mt-0.5 text-xs text-gray-500 dark:text-gray-400"
                >
                    {{
                        $t('Joined {date}', {
                            date: formatCalendarDate(person.created_at),
                        })
                    }}
                </p>
            </div>

            <div
                v-if="referredBy"
                class="rounded-xl border border-purple-200 bg-purple-50 p-4 dark:border-purple-800 dark:bg-purple-900/20"
            >
                <p
                    class="flex items-center gap-1.5 text-xs font-semibold tracking-wider text-purple-700 uppercase dark:text-purple-300"
                >
                    <UserPlus class="h-3.5 w-3.5" />
                    {{ $t('Invited by') }}
                </p>
                <p class="mt-1 text-sm text-purple-900 dark:text-purple-100">
                    {{ referredBy.name }}
                    <span class="text-purple-600 dark:text-purple-400"
                        >· {{ referredBy.email }}</span
                    >
                </p>
            </div>

            <!-- Balances -->
            <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <p
                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                    >
                        {{ $t('Available now') }}
                    </p>
                    <p
                        class="mt-2 text-2xl font-bold text-green-600 dark:text-green-400"
                    >
                        {{ formatPrice(balances.available) }}
                    </p>
                </div>
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <p
                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                    >
                        {{ $t('Locked') }}
                    </p>
                    <p
                        class="mt-2 text-2xl font-bold text-amber-600 dark:text-amber-400"
                    >
                        <span class="inline-flex items-center">
                            <Lock
                                v-if="balances.locked > 0"
                                class="mr-1.5 h-5 w-5"
                            />
                            {{ formatPrice(balances.locked) }}
                        </span>
                    </p>
                </div>
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <p
                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                    >
                        {{ $t('Lifetime earned') }}
                    </p>
                    <p
                        class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ formatPrice(balances.earned) }}
                    </p>
                </div>
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <p
                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                    >
                        {{ $t('Lifetime spent') }}
                    </p>
                    <p
                        class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ formatPrice(balances.spent) }}
                    </p>
                </div>
            </div>

            <!-- Hand-issued credit -->
            <div
                v-if="allowManualCredit"
                class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <h2
                    class="flex items-center gap-2 text-sm font-semibold text-gray-900 dark:text-white"
                >
                    <SlidersHorizontal class="h-4 w-4 text-gray-400" />
                    {{ $t('Adjust credit by hand') }}
                </h2>
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                    {{
                        $t(
                            'For fixing mistakes and goodwill gestures. The customer sees the amount and your reason in their history.',
                        )
                    }}
                </p>

                <form
                    @submit.prevent="submitCredit"
                    class="mt-4 grid grid-cols-1 items-end gap-4 md:grid-cols-12"
                >
                    <div class="md:col-span-3">
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                        >
                            {{ $t('Action') }}
                        </label>
                        <select
                            v-model="creditForm.type"
                            class="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2.5 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                        >
                            <option value="admin_credit">
                                {{ $t('Give credit') }}
                            </option>
                            <option value="admin_debit">
                                {{ $t('Take credit back') }}
                            </option>
                        </select>
                    </div>

                    <div class="md:col-span-2">
                        <label
                            for="credit_amount"
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                        >
                            {{ $t('Amount') }}
                        </label>
                        <input
                            id="credit_amount"
                            v-model="creditForm.amount"
                            type="number"
                            min="0.01"
                            step="0.01"
                            :class="[
                                'w-full rounded-lg border bg-gray-50 px-3 py-2.5 text-sm text-gray-900 transition-all focus:ring-2 dark:bg-gray-700/50 dark:text-gray-100',
                                creditForm.errors.amount || takingTooMuch
                                    ? 'border-red-400 focus:border-red-500 focus:ring-red-500/20 dark:border-red-600'
                                    : 'border-gray-200 focus:border-blue-500 focus:ring-blue-500/20 dark:border-gray-600',
                            ]"
                        />
                        <p
                            v-if="creditForm.errors.amount"
                            class="mt-1 text-xs text-red-600 dark:text-red-400"
                        >
                            {{ creditForm.errors.amount }}
                        </p>
                        <p
                            v-else-if="takingTooMuch"
                            class="mt-1 text-xs text-red-600 dark:text-red-400"
                        >
                            {{
                                $t('They only have {amount} available.', {
                                    amount: formatPrice(balances.available),
                                })
                            }}
                        </p>
                    </div>

                    <div class="md:col-span-5">
                        <label
                            for="credit_reason"
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                        >
                            {{ $t('Reason') }}
                        </label>
                        <input
                            id="credit_reason"
                            v-model="creditForm.reason"
                            type="text"
                            :placeholder="$t('Why is this being done?')"
                            :class="[
                                'w-full rounded-lg border bg-gray-50 px-3 py-2.5 text-sm text-gray-900 transition-all placeholder:text-gray-400 focus:ring-2 dark:bg-gray-700/50 dark:text-gray-100',
                                creditForm.errors.reason
                                    ? 'border-red-400 focus:border-red-500 focus:ring-red-500/20 dark:border-red-600'
                                    : 'border-gray-200 focus:border-blue-500 focus:ring-blue-500/20 dark:border-gray-600',
                            ]"
                        />
                        <p
                            v-if="creditForm.errors.reason"
                            class="mt-1 text-xs text-red-600 dark:text-red-400"
                        >
                            {{ creditForm.errors.reason }}
                        </p>
                    </div>

                    <div class="md:col-span-2">
                        <button
                            type="submit"
                            :disabled="creditForm.processing || takingTooMuch"
                            class="w-full rounded-lg bg-blue-600 px-4 py-2.5 text-xs font-semibold tracking-widest text-white uppercase transition hover:bg-blue-700 disabled:opacity-50"
                        >
                            {{
                                creditForm.processing
                                    ? $t('Saving...')
                                    : $t('Apply')
                            }}
                        </button>
                    </div>
                </form>
            </div>

            <!-- Code -->
            <div
                class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div
                    class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
                >
                    <div>
                        <p
                            class="flex items-center gap-1.5 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                        >
                            <Link2 class="h-3.5 w-3.5" />
                            {{ $t('Share link') }}
                        </p>
                        <p
                            class="mt-2 font-mono text-sm break-all text-gray-900 dark:text-white"
                        >
                            {{ person.share_link }}
                        </p>
                        <p
                            class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                        >
                            {{ $t('Code') }}
                            <span class="font-mono">{{ person.code }}</span> ·
                            {{
                                $t('{clicks} link opens', {
                                    clicks: person.clicks,
                                })
                            }}
                            ·
                            <span
                                :class="
                                    person.code_status === 'active'
                                        ? 'text-green-600 dark:text-green-400'
                                        : 'text-red-500'
                                "
                            >
                                {{
                                    person.code_status === 'active'
                                        ? $t('active')
                                        : $t('disabled')
                                }}
                            </span>
                        </p>
                    </div>

                    <button
                        @click="copyLink"
                        class="inline-flex items-center justify-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none"
                    >
                        <Check v-if="copied" class="mr-2 h-4 w-4" />
                        <Copy v-else class="mr-2 h-4 w-4" />
                        {{ copied ? $t('Copied') : $t('Copy link') }}
                    </button>
                </div>

                <p
                    v-if="person.code_status === 'disabled'"
                    class="mt-3 text-xs text-amber-600 dark:text-amber-400"
                >
                    {{
                        $t(
                            'This code is disabled, so new visits with it are not credited to this customer.',
                        )
                    }}
                </p>
            </div>

            <!-- Invites -->
            <div
                class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div
                    class="flex items-center gap-2 border-b border-gray-100 px-5 py-4 dark:border-gray-700"
                >
                    <Users class="h-4 w-4 text-gray-400" />
                    <h2
                        class="text-sm font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('People they invited') }}
                        <span
                            class="ml-1 text-xs font-normal text-gray-500 dark:text-gray-400"
                            >({{ referralsMade.length }})</span
                        >
                    </h2>
                </div>

                <div
                    v-if="referralsMade.length === 0"
                    class="px-5 py-10 text-center text-sm text-gray-500 dark:text-gray-400"
                >
                    {{ $t('Nobody yet.') }}
                </div>

                <div v-else class="overflow-x-auto">
                    <table
                        class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                    >
                        <thead class="bg-gray-50 dark:bg-gray-700/50">
                            <tr>
                                <th
                                    class="px-5 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Person') }}
                                </th>
                                <th
                                    class="px-5 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Lifetime spend') }}
                                </th>
                                <th
                                    class="px-5 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
                                </th>
                                <th
                                    class="px-5 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Joined') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody
                            class="divide-y divide-gray-200 dark:divide-gray-700"
                        >
                            <tr
                                v-for="row in referralsMade"
                                :key="row.id"
                                class="hover:bg-gray-50 dark:hover:bg-gray-700/20"
                            >
                                <td class="px-5 py-4">
                                    <div
                                        class="text-sm font-medium text-gray-900 dark:text-white"
                                    >
                                        {{ row.referred_name }}
                                    </div>
                                    <div
                                        class="text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        {{ row.referred_email }}
                                    </div>
                                </td>
                                <td
                                    class="px-5 py-4 text-right text-sm text-gray-900 dark:text-white"
                                >
                                    {{ formatPrice(row.lifetime_spend) }}
                                </td>
                                <td class="px-5 py-4">
                                    <span
                                        v-if="row.rewarded_at"
                                        class="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-1 text-xs font-medium text-green-800 dark:bg-green-900/30 dark:text-green-300"
                                    >
                                        <Gift class="h-3 w-3" />
                                        {{ $t('Rewarded') }}
                                    </span>
                                    <span
                                        v-else-if="row.status === 'voided'"
                                        class="inline-flex items-center gap-1 rounded-full bg-red-100 px-2 py-1 text-xs font-medium text-red-800 dark:bg-red-900/30 dark:text-red-300"
                                    >
                                        <Ban class="h-3 w-3" />
                                        {{ $t('Voided') }}
                                    </span>
                                    <span
                                        v-else
                                        class="inline-flex items-center gap-1 rounded-full bg-amber-100 px-2 py-1 text-xs font-medium text-amber-800 dark:bg-amber-900/30 dark:text-amber-300"
                                    >
                                        {{ $t('Still spending') }}
                                    </span>
                                </td>
                                <td
                                    class="px-5 py-4 text-sm text-gray-500 dark:text-gray-400"
                                >
                                    <DateDisplay :value="row.created_at" />
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Commissions -->
            <div
                class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div
                    class="flex items-center gap-2 border-b border-gray-100 px-5 py-4 dark:border-gray-700"
                >
                    <Wallet class="h-4 w-4 text-gray-400" />
                    <h2
                        class="text-sm font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Rewards granted') }}
                        <span
                            class="ml-1 text-xs font-normal text-gray-500 dark:text-gray-400"
                            >({{ $t('last 50') }})</span
                        >
                    </h2>
                </div>

                <div
                    v-if="commissions.length === 0"
                    class="px-5 py-10 text-center text-sm text-gray-500 dark:text-gray-400"
                >
                    {{ $t('No rewards granted yet.') }}
                </div>

                <div v-else class="overflow-x-auto">
                    <table
                        class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                    >
                        <thead class="bg-gray-50 dark:bg-gray-700/50">
                            <tr>
                                <th
                                    class="px-5 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Order') }}
                                </th>
                                <th
                                    class="px-5 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Level') }}
                                </th>
                                <th
                                    class="px-5 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Amount') }}
                                </th>
                                <th
                                    class="px-5 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
                                </th>
                                <th
                                    class="px-5 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Actions') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody
                            class="divide-y divide-gray-200 dark:divide-gray-700"
                        >
                            <template v-for="c in commissions" :key="c.id">
                                <tr
                                    class="hover:bg-gray-50 dark:hover:bg-gray-700/20"
                                >
                                    <td
                                        class="px-5 py-4 text-sm text-gray-900 dark:text-white"
                                    >
                                        {{ c.order_number ?? '—' }}
                                        <div
                                            class="text-xs text-gray-500 dark:text-gray-400"
                                        >
                                            <DateDisplay
                                                :value="c.created_at"
                                            />
                                        </div>
                                    </td>
                                    <td
                                        class="px-5 py-4 text-sm text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t('Level {level}', {
                                                level: c.level,
                                            })
                                        }}
                                    </td>
                                    <td
                                        class="px-5 py-4 text-right text-sm font-semibold text-gray-900 dark:text-white"
                                    >
                                        {{ formatPrice(c.amount) }}
                                    </td>
                                    <td class="px-5 py-4">
                                        <span
                                            v-if="c.status === 'active'"
                                            class="inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-medium"
                                            :class="
                                                c.unlocks_at &&
                                                new Date(c.unlocks_at) >
                                                    new Date()
                                                    ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300'
                                                    : 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                            "
                                        >
                                            <Lock
                                                v-if="
                                                    c.unlocks_at &&
                                                    new Date(c.unlocks_at) >
                                                        new Date()
                                                "
                                                class="h-3 w-3"
                                            />
                                            {{
                                                c.unlocks_at &&
                                                new Date(c.unlocks_at) >
                                                    new Date()
                                                    ? $t(
                                                          'Locked until {date}',
                                                          {
                                                              date: formatCalendarDate(
                                                                  c.unlocks_at,
                                                              ),
                                                          },
                                                      )
                                                    : $t('Available')
                                            }}
                                        </span>
                                        <span
                                            v-else
                                            class="inline-flex items-center gap-1 rounded-full bg-red-100 px-2 py-1 text-xs font-medium text-red-800 dark:bg-red-900/30 dark:text-red-300"
                                        >
                                            <Ban class="h-3 w-3" />
                                            {{ $t('Reversed') }}
                                        </span>
                                    </td>
                                    <td class="px-5 py-4 text-right">
                                        <button
                                            v-if="c.status === 'active'"
                                            @click="openReverse(c)"
                                            class="text-xs font-semibold text-red-600 hover:underline dark:text-red-400"
                                        >
                                            {{ $t('Reverse') }}
                                        </button>
                                        <span
                                            v-else
                                            class="text-xs text-gray-400"
                                            >—</span
                                        >
                                    </td>
                                </tr>

                                <!-- Reverse reason form, under the row it belongs to -->
                                <tr
                                    v-if="reversing === c.id"
                                    class="bg-red-50 dark:bg-red-900/10"
                                >
                                    <td colspan="5" class="px-5 py-4">
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
            </div>

            <!-- Ledger -->
            <div
                class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div
                    class="flex items-center gap-2 border-b border-gray-100 px-5 py-4 dark:border-gray-700"
                >
                    <ScrollText class="h-4 w-4 text-gray-400" />
                    <h2
                        class="text-sm font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Credit history') }}
                        <span
                            class="ml-1 text-xs font-normal text-gray-500 dark:text-gray-400"
                            >({{ $t('last 50') }})</span
                        >
                    </h2>
                </div>

                <div
                    v-if="ledger.length === 0"
                    class="px-5 py-10 text-center text-sm text-gray-500 dark:text-gray-400"
                >
                    {{ $t('No movements yet.') }}
                </div>

                <div v-else class="overflow-x-auto">
                    <table
                        class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                    >
                        <thead class="bg-gray-50 dark:bg-gray-700/50">
                            <tr>
                                <th
                                    class="px-5 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('When') }}
                                </th>
                                <th
                                    class="px-5 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('What') }}
                                </th>
                                <th
                                    class="px-5 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Change') }}
                                </th>
                                <th
                                    class="px-5 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Balance after') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody
                            class="divide-y divide-gray-200 dark:divide-gray-700"
                        >
                            <tr
                                v-for="entry in ledger"
                                :key="entry.id"
                                class="hover:bg-gray-50 dark:hover:bg-gray-700/20"
                            >
                                <td
                                    class="px-5 py-4 text-sm text-gray-500 dark:text-gray-400"
                                >
                                    <DateDisplay :value="entry.created_at" />
                                </td>
                                <td class="px-5 py-4">
                                    <div
                                        class="text-sm text-gray-900 dark:text-white"
                                    >
                                        {{
                                            $t(
                                                ledgerLabel[entry.type] ??
                                                    entry.type,
                                            )
                                        }}
                                    </div>
                                    <div
                                        v-if="entry.reason"
                                        class="text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        {{ entry.reason }}
                                    </div>
                                </td>
                                <td
                                    class="px-5 py-4 text-right text-sm font-medium"
                                    :class="
                                        entry.amount >= 0
                                            ? 'text-green-600 dark:text-green-400'
                                            : 'text-red-600 dark:text-red-400'
                                    "
                                >
                                    {{ entry.amount >= 0 ? '+' : ''
                                    }}{{ formatPrice(entry.amount) }}
                                </td>
                                <td
                                    class="px-5 py-4 text-right text-sm text-gray-900 dark:text-white"
                                >
                                    {{ formatPrice(entry.balance_after) }}
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>
