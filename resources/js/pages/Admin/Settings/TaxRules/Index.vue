<template>
    <Head :title="$t('Tax Rules')" />

    <AdminLayout :title="$t('Tax Rules')">
        <div class="space-y-6">
            <!-- Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h2
                        class="bg-gradient-to-r from-gray-900 to-gray-600 bg-clip-text text-2xl font-bold text-transparent dark:from-white dark:to-gray-300"
                    >
                        {{ $t('Tax Configuration') }}
                    </h2>
                    <p
                        class="mt-1 flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400"
                    >
                        <Receipt class="h-4 w-4" />
                        {{ $t('Manage tax rules, classes, rates, and zones') }}
                    </p>
                </div>
            </div>

            <!-- Main Content -->
            <div
                class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <!-- Tabs -->
                <div class="border-b border-gray-200 dark:border-gray-700">
                    <nav class="flex overflow-x-auto" :aria-label="$t('Tabs')">
                        <button
                            v-for="tab in tabs"
                            :key="tab.id"
                            @click="activeTab = tab.id"
                            :class="[
                                'flex items-center gap-2 border-b-2 px-6 py-4 text-sm font-medium whitespace-nowrap transition-colors',
                                activeTab === tab.id
                                    ? 'border-blue-500 bg-blue-50/50 text-blue-600 dark:bg-blue-900/10 dark:text-blue-400'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                            ]"
                        >
                            <component :is="tab.icon" class="h-4 w-4" />
                            {{ tab.name }}
                        </button>
                    </nav>
                </div>

                <div class="p-6">
                    <!-- Tax Rules Tab -->
                    <div v-show="activeTab === 'rules'" class="space-y-4">
                        <div
                            class="flex flex-col justify-between gap-4 sm:flex-row"
                        >
                            <div class="relative w-full max-w-md">
                                <Search
                                    class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                />
                                <input
                                    v-model="searchQuery"
                                    type="text"
                                    :placeholder="$t('Search tax rules...')"
                                    class="w-full rounded-xl border border-gray-300 bg-white py-2 pr-4 pl-9 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                />
                            </div>
                            <Link
                                href="/admin/settings/tax-rules/create"
                                class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                            >
                                <Plus class="mr-2 h-4 w-4" />
                                {{ $t('Create Rule') }}
                            </Link>
                        </div>

                        <div
                            v-if="taxRules.data.length === 0"
                            class="py-12 text-center"
                        >
                            <div
                                class="mb-4 inline-flex h-12 w-12 items-center justify-center rounded-full bg-gray-100 dark:bg-gray-700"
                            >
                                <Gavel class="h-6 w-6 text-gray-400" />
                            </div>
                            <h3
                                class="text-lg font-medium text-gray-900 dark:text-white"
                            >
                                {{ $t('No rules found') }}
                            </h3>
                            <p class="mt-1 text-gray-500 dark:text-gray-400">
                                {{
                                    $t(
                                        'Get started by creating your first tax rule.',
                                    )
                                }}
                            </p>
                        </div>

                        <div
                            v-else
                            class="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-700"
                        >
                            <table class="w-full text-left text-sm">
                                <thead class="bg-gray-50 dark:bg-gray-700/50">
                                    <tr>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Name') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Tax Class') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Zone') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Rate') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Priority') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Status') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 text-right font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Actions') }}
                                        </th>
                                    </tr>
                                </thead>
                                <tbody
                                    class="divide-y divide-gray-200 dark:divide-gray-700"
                                >
                                    <tr
                                        v-for="rule in taxRules.data"
                                        :key="rule.id"
                                        class="transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
                                    >
                                        <td
                                            class="px-6 py-4 font-medium text-gray-900 dark:text-white"
                                        >
                                            {{ rule.name }}
                                        </td>
                                        <td
                                            class="px-6 py-4 text-gray-600 dark:text-gray-300"
                                        >
                                            <div
                                                class="flex items-center gap-2"
                                            >
                                                <Tag
                                                    class="h-3.5 w-3.5 text-gray-400"
                                                />
                                                {{ rule.tax_class.name }}
                                            </div>
                                        </td>
                                        <td
                                            class="px-6 py-4 text-gray-600 dark:text-gray-300"
                                        >
                                            <div
                                                class="flex items-center gap-2"
                                            >
                                                <Map
                                                    class="h-3.5 w-3.5 text-gray-400"
                                                />
                                                {{ rule.tax_zone.name }}
                                            </div>
                                        </td>
                                        <td
                                            class="px-6 py-4 text-gray-600 dark:text-gray-300"
                                        >
                                            {{ rule.tax_rate.percentage }}%
                                        </td>
                                        <td
                                            class="px-6 py-4 text-gray-600 dark:text-gray-300"
                                        >
                                            {{ rule.priority }}
                                        </td>
                                        <td class="px-6 py-4">
                                            <span
                                                class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium capitalize"
                                                :class="
                                                    rule.is_active
                                                        ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
                                                        : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                                                "
                                            >
                                                {{
                                                    rule.is_active
                                                        ? $t('Active')
                                                        : $t('Inactive')
                                                }}
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 text-right">
                                            <div
                                                class="flex items-center justify-end gap-2"
                                            >
                                                <Link
                                                    :href="`/admin/settings/tax-rules/${rule.id}/edit`"
                                                    class="rounded-lg p-2 text-blue-600 transition-colors hover:bg-blue-50 dark:text-blue-400 dark:hover:bg-blue-900/30"
                                                >
                                                    <Edit class="h-4 w-4" />
                                                </Link>
                                                <button
                                                    @click="
                                                        confirmDelete(rule.id)
                                                    "
                                                    class="rounded-lg p-2 text-red-600 transition-colors hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-900/30"
                                                >
                                                    <Trash2 class="h-4 w-4" />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>

                        <Pagination
                            :data="taxRules"
                            resource-name="tax rules"
                        />
                    </div>

                    <!-- Tax Classes Tab -->
                    <div v-show="activeTab === 'classes'" class="space-y-4">
                        <div
                            class="flex flex-col items-center justify-between gap-4 rounded-xl bg-gray-50 p-4 sm:flex-row dark:bg-gray-700/30"
                        >
                            <div>
                                <h3
                                    class="text-base font-semibold text-gray-900 dark:text-white"
                                >
                                    {{ $t('Tax Classes') }}
                                </h3>
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{
                                        $t(
                                            'Categorize products for tax calculation purposes.',
                                        )
                                    }}
                                </p>
                            </div>
                            <button
                                @click="openTaxClassModal()"
                                class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                            >
                                <Plus class="mr-2 h-4 w-4" />
                                {{ $t('Add Class') }}
                            </button>
                        </div>

                        <div
                            class="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-700"
                        >
                            <table class="w-full text-left text-sm">
                                <thead class="bg-gray-50 dark:bg-gray-700/50">
                                    <tr>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Name') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Code') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Description') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 text-center font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Default') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 text-right font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Actions') }}
                                        </th>
                                    </tr>
                                </thead>
                                <tbody
                                    class="divide-y divide-gray-200 dark:divide-gray-700"
                                >
                                    <tr
                                        v-for="taxClass in taxClasses"
                                        :key="taxClass.id"
                                        class="transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
                                    >
                                        <td
                                            class="px-6 py-4 font-medium text-gray-900 dark:text-white"
                                        >
                                            {{ taxClass.name }}
                                        </td>
                                        <td
                                            class="px-6 py-4 font-mono text-xs text-gray-600 dark:text-gray-300"
                                        >
                                            {{ taxClass.code }}
                                        </td>
                                        <td
                                            class="px-6 py-4 text-gray-500 dark:text-gray-400"
                                        >
                                            {{ taxClass.description || '—' }}
                                        </td>
                                        <td class="px-6 py-4 text-center">
                                            <span
                                                v-if="taxClass.is_default"
                                                class="inline-flex items-center rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800 dark:bg-blue-900/30 dark:text-blue-300"
                                            >
                                                {{ $t('Default') }}
                                            </span>
                                            <span
                                                v-else
                                                class="text-gray-400 dark:text-gray-600"
                                                >—</span
                                            >
                                        </td>
                                        <td class="px-6 py-4 text-right">
                                            <div
                                                class="flex items-center justify-end gap-2"
                                            >
                                                <button
                                                    @click="
                                                        openTaxClassModal(
                                                            taxClass,
                                                        )
                                                    "
                                                    class="rounded-lg p-2 text-blue-600 transition-colors hover:bg-blue-50 dark:text-blue-400 dark:hover:bg-blue-900/30"
                                                >
                                                    <Edit class="h-4 w-4" />
                                                </button>
                                                <button
                                                    @click="
                                                        confirmDeleteTaxClass(
                                                            taxClass.id,
                                                        )
                                                    "
                                                    class="rounded-lg p-2 text-red-600 transition-colors hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-900/30"
                                                >
                                                    <Trash2 class="h-4 w-4" />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Tax Rates Tab -->
                    <div v-show="activeTab === 'rates'" class="space-y-4">
                        <div
                            class="flex flex-col items-center justify-between gap-4 rounded-xl bg-gray-50 p-4 sm:flex-row dark:bg-gray-700/30"
                        >
                            <div>
                                <h3
                                    class="text-base font-semibold text-gray-900 dark:text-white"
                                >
                                    {{ $t('Tax Rates') }}
                                </h3>
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{
                                        $t(
                                            'Define percentages for tax calculations.',
                                        )
                                    }}
                                </p>
                            </div>
                            <button
                                @click="openTaxRateModal()"
                                class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                            >
                                <Plus class="mr-2 h-4 w-4" />
                                {{ $t('Add Rate') }}
                            </button>
                        </div>

                        <div
                            class="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-700"
                        >
                            <table class="w-full text-left text-sm">
                                <thead class="bg-gray-50 dark:bg-gray-700/50">
                                    <tr>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Name') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Code') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Rate') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Priority') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 text-center font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Compound') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Status') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 text-right font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Actions') }}
                                        </th>
                                    </tr>
                                </thead>
                                <tbody
                                    class="divide-y divide-gray-200 dark:divide-gray-700"
                                >
                                    <tr
                                        v-for="rate in taxRates"
                                        :key="rate.id"
                                        class="transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
                                    >
                                        <td
                                            class="px-6 py-4 font-medium text-gray-900 dark:text-white"
                                        >
                                            {{ rate.name }}
                                        </td>
                                        <td
                                            class="px-6 py-4 font-mono text-xs text-gray-600 dark:text-gray-300"
                                        >
                                            {{ rate.code }}
                                        </td>
                                        <td
                                            class="px-6 py-4 font-medium text-gray-900 dark:text-white"
                                        >
                                            {{ rate.percentage }}%
                                        </td>
                                        <td
                                            class="px-6 py-4 text-gray-600 dark:text-gray-300"
                                        >
                                            {{ rate.priority }}
                                        </td>
                                        <td class="px-6 py-4 text-center">
                                            <span
                                                v-if="rate.is_compound"
                                                class="inline-flex items-center rounded-full bg-purple-100 px-2.5 py-0.5 text-xs font-medium text-purple-800 dark:bg-purple-900/30 dark:text-purple-300"
                                            >
                                                {{ $t('Compound') }}
                                            </span>
                                            <span
                                                v-else
                                                class="text-gray-400 dark:text-gray-600"
                                                >—</span
                                            >
                                        </td>
                                        <td class="px-6 py-4">
                                            <span
                                                class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium capitalize"
                                                :class="
                                                    rate.is_active
                                                        ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
                                                        : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                                                "
                                            >
                                                {{
                                                    rate.is_active
                                                        ? $t('Active')
                                                        : $t('Inactive')
                                                }}
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 text-right">
                                            <div
                                                class="flex items-center justify-end gap-2"
                                            >
                                                <button
                                                    @click="
                                                        openTaxRateModal(rate)
                                                    "
                                                    class="rounded-lg p-2 text-blue-600 transition-colors hover:bg-blue-50 dark:text-blue-400 dark:hover:bg-blue-900/30"
                                                >
                                                    <Edit class="h-4 w-4" />
                                                </button>
                                                <button
                                                    @click="
                                                        confirmDeleteTaxRate(
                                                            rate.id,
                                                        )
                                                    "
                                                    class="rounded-lg p-2 text-red-600 transition-colors hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-900/30"
                                                >
                                                    <Trash2 class="h-4 w-4" />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Tax Zones Tab -->
                    <div v-show="activeTab === 'zones'" class="space-y-4">
                        <div
                            class="flex flex-col items-center justify-between gap-4 rounded-xl bg-gray-50 p-4 sm:flex-row dark:bg-gray-700/30"
                        >
                            <div>
                                <h3
                                    class="text-base font-semibold text-gray-900 dark:text-white"
                                >
                                    {{ $t('Tax Zones') }}
                                </h3>
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{
                                        $t(
                                            'Define geographic regions for tax application.',
                                        )
                                    }}
                                </p>
                            </div>
                            <button
                                @click="openTaxZoneModal()"
                                class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                            >
                                <Plus class="mr-2 h-4 w-4" />
                                {{ $t('Add Zone') }}
                            </button>
                        </div>

                        <div
                            class="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-700"
                        >
                            <table class="w-full text-left text-sm">
                                <thead class="bg-gray-50 dark:bg-gray-700/50">
                                    <tr>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Name') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Code') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Description') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Locations') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Status') }}
                                        </th>
                                        <th
                                            class="px-6 py-4 text-right font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('Actions') }}
                                        </th>
                                    </tr>
                                </thead>
                                <tbody
                                    class="divide-y divide-gray-200 dark:divide-gray-700"
                                >
                                    <tr
                                        v-for="zone in taxZones"
                                        :key="zone.id"
                                        class="transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
                                    >
                                        <td
                                            class="px-6 py-4 font-medium text-gray-900 dark:text-white"
                                        >
                                            {{ zone.name }}
                                        </td>
                                        <td
                                            class="px-6 py-4 font-mono text-xs text-gray-600 dark:text-gray-300"
                                        >
                                            {{ zone.code }}
                                        </td>
                                        <td
                                            class="px-6 py-4 text-gray-500 dark:text-gray-400"
                                        >
                                            {{ zone.description || '—' }}
                                        </td>
                                        <td
                                            class="px-6 py-4 text-gray-600 dark:text-gray-300"
                                        >
                                            <span
                                                class="inline-flex items-center rounded bg-blue-50 px-2 py-1 text-xs text-blue-700 ring-1 ring-blue-700/10 ring-inset dark:bg-blue-900/20 dark:text-blue-300 dark:ring-blue-400/20"
                                            >
                                                {{
                                                    $t('{count} location(s)', {
                                                        count: zone.locations
                                                            .length,
                                                    })
                                                }}
                                            </span>
                                        </td>
                                        <td class="px-6 py-4">
                                            <span
                                                class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium capitalize"
                                                :class="
                                                    zone.is_active
                                                        ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
                                                        : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                                                "
                                            >
                                                {{
                                                    zone.is_active
                                                        ? $t('Active')
                                                        : $t('Inactive')
                                                }}
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 text-right">
                                            <div
                                                class="flex items-center justify-end gap-2"
                                            >
                                                <button
                                                    @click="
                                                        openTaxZoneModal(zone)
                                                    "
                                                    class="rounded-lg p-2 text-blue-600 transition-colors hover:bg-blue-50 dark:text-blue-400 dark:hover:bg-blue-900/30"
                                                >
                                                    <Edit class="h-4 w-4" />
                                                </button>
                                                <button
                                                    @click="
                                                        confirmDeleteTaxZone(
                                                            zone.id,
                                                        )
                                                    "
                                                    class="rounded-lg p-2 text-red-600 transition-colors hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-900/30"
                                                >
                                                    <Trash2 class="h-4 w-4" />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>

    <!-- Delete Confirmation Modal -->
    <div
        v-if="showDeleteModal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 p-4 backdrop-blur-sm dark:bg-gray-900/80"
        @click.self="showDeleteModal = false"
    >
        <div
            class="w-full max-w-sm space-y-4 rounded-2xl bg-white p-6 shadow-xl dark:bg-gray-800"
        >
            <div class="flex items-center gap-3 text-red-600">
                <div class="rounded-xl bg-red-100 p-2 dark:bg-red-900/30">
                    <AlertTriangle class="h-6 w-6" />
                </div>
                <h3 class="text-lg font-bold text-gray-900 dark:text-white">
                    {{ $t('Confirm Delete') }}
                </h3>
            </div>
            <p class="text-gray-600 dark:text-gray-400">{{ deleteMessage }}</p>
            <div class="flex justify-end gap-3 pt-2">
                <button
                    @click="showDeleteModal = false"
                    class="rounded-xl px-4 py-2 font-medium text-gray-700 transition-colors hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-700"
                >
                    {{ $t('Cancel') }}
                </button>
                <button
                    @click="deleteItem"
                    class="rounded-xl bg-red-600 px-4 py-2 font-medium text-white shadow-sm transition-colors hover:bg-red-700"
                >
                    {{ $t('Delete') }}
                </button>
            </div>
        </div>
    </div>

    <!-- Tax Class Modal -->
    <div
        v-if="showTaxClassModal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 p-4 backdrop-blur-sm dark:bg-gray-900/80"
        @click.self="showTaxClassModal = false"
    >
        <div
            class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl bg-white shadow-xl dark:bg-gray-800"
        >
            <div
                class="flex items-center justify-between border-b border-gray-100 p-6 dark:border-gray-700"
            >
                <h3 class="text-lg font-bold text-gray-900 dark:text-white">
                    {{
                        taxClassForm.id
                            ? $t('Edit Tax Class')
                            : $t('Create Tax Class')
                    }}
                </h3>
                <button
                    @click="showTaxClassModal = false"
                    class="text-gray-400 hover:text-gray-500 dark:hover:text-gray-300"
                >
                    <X class="h-5 w-5" />
                </button>
            </div>
            <form @submit.prevent="saveTaxClass" class="space-y-4 p-6">
                <div>
                    <label
                        class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                        >{{ $t('Name') }}
                        <span class="text-red-500">*</span></label
                    >
                    <input
                        v-model="taxClassForm.name"
                        type="text"
                        required
                        class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                    />
                </div>
                <div>
                    <label
                        class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                        >{{ $t('Code') }}
                        <span class="text-red-500">*</span></label
                    >
                    <input
                        v-model="taxClassForm.code"
                        type="text"
                        required
                        class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                    />
                </div>
                <div>
                    <label
                        class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                        >{{ $t('Description') }}</label
                    >
                    <textarea
                        v-model="taxClassForm.description"
                        rows="3"
                        class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                    />
                </div>
                <div
                    class="flex items-center gap-3 rounded-xl bg-gray-50 p-3 dark:bg-gray-700/30"
                >
                    <input
                        v-model="taxClassForm.is_default"
                        type="checkbox"
                        class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                    />
                    <label
                        class="text-sm font-medium text-gray-700 dark:text-gray-300"
                        >{{ $t('Set as default tax class') }}</label
                    >
                </div>

                <div class="flex justify-end gap-3 pt-4">
                    <button
                        type="button"
                        @click="showTaxClassModal = false"
                        class="rounded-xl border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        {{ $t('Cancel') }}
                    </button>
                    <button
                        type="submit"
                        :disabled="processing"
                        class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        {{ processing ? $t('Saving...') : $t('Save Changes') }}
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Tax Rate Modal -->
    <div
        v-if="showTaxRateModal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 p-4 backdrop-blur-sm dark:bg-gray-900/80"
        @click.self="showTaxRateModal = false"
    >
        <div
            class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl bg-white shadow-xl dark:bg-gray-800"
        >
            <div
                class="flex items-center justify-between border-b border-gray-100 p-6 dark:border-gray-700"
            >
                <h3 class="text-lg font-bold text-gray-900 dark:text-white">
                    {{
                        taxRateForm.id
                            ? $t('Edit Tax Rate')
                            : $t('Create Tax Rate')
                    }}
                </h3>
                <button
                    @click="showTaxRateModal = false"
                    class="text-gray-400 hover:text-gray-500 dark:hover:text-gray-300"
                >
                    <X class="h-5 w-5" />
                </button>
            </div>
            <form @submit.prevent="saveTaxRate" class="space-y-4 p-6">
                <div class="grid grid-cols-2 gap-4">
                    <div class="col-span-2">
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Name') }}
                            <span class="text-red-500">*</span></label
                        >
                        <input
                            v-model="taxRateForm.name"
                            type="text"
                            required
                            class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                        />
                    </div>
                    <div>
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Code') }}
                            <span class="text-red-500">*</span></label
                        >
                        <input
                            v-model="taxRateForm.code"
                            type="text"
                            required
                            class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                        />
                    </div>
                    <div>
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Priority') }}
                            <span class="text-red-500">*</span></label
                        >
                        <input
                            v-model="taxRateForm.priority"
                            type="number"
                            min="1"
                            required
                            class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                        />
                    </div>
                    <div class="col-span-2">
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Percentage (%)') }}
                            <span class="text-red-500">*</span></label
                        >
                        <input
                            v-model="taxRateForm.percentage"
                            type="number"
                            step="0.01"
                            min="0"
                            max="100"
                            required
                            class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                        />
                    </div>
                </div>

                <div
                    class="flex flex-col gap-3 rounded-xl bg-gray-50 p-3 dark:bg-gray-700/30"
                >
                    <div class="flex items-center gap-3">
                        <input
                            v-model="taxRateForm.is_compound"
                            type="checkbox"
                            class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                        />
                        <label
                            class="text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{
                                $t(
                                    'Compound Tax (calculated on top of other taxes)',
                                )
                            }}</label
                        >
                    </div>
                    <div
                        class="flex items-center gap-3 border-t border-gray-200 pt-3 dark:border-gray-600"
                    >
                        <input
                            v-model="taxRateForm.is_active"
                            type="checkbox"
                            class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                        />
                        <label
                            class="text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Active') }}</label
                        >
                    </div>
                </div>

                <div class="flex justify-end gap-3 pt-4">
                    <button
                        type="button"
                        @click="showTaxRateModal = false"
                        class="rounded-xl border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        {{ $t('Cancel') }}
                    </button>
                    <button
                        type="submit"
                        :disabled="processing"
                        class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        {{ processing ? $t('Saving...') : $t('Save Changes') }}
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Tax Zone Modal -->
    <div
        v-if="showTaxZoneModal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 p-4 backdrop-blur-sm dark:bg-gray-900/80"
        @click.self="showTaxZoneModal = false"
    >
        <div
            class="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-2xl bg-white shadow-xl dark:bg-gray-800"
        >
            <div
                class="flex items-center justify-between border-b border-gray-100 p-6 dark:border-gray-700"
            >
                <h3 class="text-lg font-bold text-gray-900 dark:text-white">
                    {{
                        taxZoneForm.id
                            ? $t('Edit Tax Zone')
                            : $t('Create Tax Zone')
                    }}
                </h3>
                <button
                    @click="showTaxZoneModal = false"
                    class="text-gray-400 hover:text-gray-500 dark:hover:text-gray-300"
                >
                    <X class="h-5 w-5" />
                </button>
            </div>
            <form @submit.prevent="saveTaxZone" class="space-y-4 p-6">
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Name') }}
                            <span class="text-red-500">*</span></label
                        >
                        <input
                            v-model="taxZoneForm.name"
                            type="text"
                            required
                            class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                        />
                    </div>
                    <div>
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Code') }}
                            <span class="text-red-500">*</span></label
                        >
                        <input
                            v-model="taxZoneForm.code"
                            type="text"
                            required
                            class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                        />
                    </div>
                    <div class="col-span-2">
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Description') }}</label
                        >
                        <textarea
                            v-model="taxZoneForm.description"
                            rows="2"
                            class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                        />
                    </div>
                    <div class="col-span-2">
                        <div
                            class="flex items-center gap-3 rounded-xl bg-gray-50 p-3 dark:bg-gray-700/30"
                        >
                            <input
                                v-model="taxZoneForm.is_active"
                                type="checkbox"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                            />
                            <label
                                class="text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Active') }}</label
                            >
                        </div>
                    </div>
                </div>

                <!-- Locations -->
                <div class="border-t border-gray-100 pt-4 dark:border-gray-700">
                    <div class="mb-3 flex items-center justify-between">
                        <label
                            class="block text-sm font-medium text-gray-900 dark:text-white"
                            >{{ $t('Locations') }}</label
                        >
                        <button
                            type="button"
                            @click="addLocation"
                            class="rounded-lg border border-green-200 bg-green-50 px-3 py-1.5 text-sm font-medium text-green-700 transition-colors hover:bg-green-100 dark:border-green-800 dark:bg-green-900/20 dark:text-green-400 dark:hover:bg-green-900/30"
                        >
                            {{ $t('+ Add Location') }}
                        </button>
                    </div>

                    <div class="space-y-3">
                        <div
                            v-if="taxZoneForm.locations.length === 0"
                            class="rounded-xl border border-dashed border-gray-200 bg-gray-50 py-4 text-center text-sm text-gray-500 italic dark:border-gray-700 dark:bg-gray-800/50 dark:text-gray-400"
                        >
                            {{ $t('No locations added yet.') }}
                        </div>
                        <div
                            v-for="(location, index) in taxZoneForm.locations"
                            :key="index"
                            class="flex items-start gap-2"
                        >
                            <div
                                class="flex-1 rounded-xl border border-gray-300 bg-gray-100 px-3 py-2 text-sm text-gray-600 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-400"
                            >
                                {{ storeCountry }}
                            </div>
                            <input
                                v-model="location.state_code"
                                type="text"
                                :placeholder="$t('State (optional)')"
                                class="flex-1 rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                            />
                            <button
                                type="button"
                                @click="removeLocation(index)"
                                class="rounded-lg p-2 text-red-600 transition-colors hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-900/30"
                            >
                                <X class="h-4 w-4" />
                            </button>
                        </div>
                    </div>
                </div>

                <div
                    class="flex justify-end gap-3 border-t border-gray-100 pt-4 dark:border-gray-700"
                >
                    <button
                        type="button"
                        @click="showTaxZoneModal = false"
                        class="rounded-xl border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        {{ $t('Cancel') }}
                    </button>
                    <button
                        type="submit"
                        :disabled="processing"
                        class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        {{ processing ? $t('Saving...') : $t('Save Changes') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</template>

<script setup lang="ts">
import Pagination from '@/components/Admin/Pagination.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Head, Link, router } from '@inertiajs/vue3';
import {
    AlertTriangle,
    Edit,
    Gavel,
    Map,
    Percent,
    Plus,
    Receipt,
    Search,
    Tag,
    Trash2,
    X,
} from 'lucide-vue-next';
import { reactive, ref } from 'vue';

interface TaxClass {
    id: number;
    code: string;
    name: string;
    description: string | null;
    is_default: boolean;
}

interface TaxRate {
    id: number;
    code: string;
    name: string;
    percentage: string;
    priority: number;
    is_compound: boolean;
    is_active: boolean;
}

interface TaxZoneLocation {
    id?: number;
    country_code: string;
    state_code: string | null;
    postal_code_pattern?: string | null;
    city?: string | null;
}

interface TaxZone {
    id: number;
    code: string;
    name: string;
    description: string | null;
    is_active: boolean;
    locations: TaxZoneLocation[];
}

interface TaxRule {
    id: number;
    name: string;
    priority: number;
    calculate_shipping: boolean;
    is_active: boolean;
    tax_class: TaxClass;
    tax_zone: TaxZone;
    tax_rate: TaxRate;
}

interface PaginatedData<T> {
    data: T[];
    current_page: number;
    last_page: number;
    per_page: number;
    from: number;
    to: number;
    total: number;
    links: Array<{
        url: string | null;
        label: string;
        active: boolean;
    }>;
}

interface Props {
    taxRules: PaginatedData<TaxRule>;
    taxClasses: TaxClass[];
    taxRates: TaxRate[];
    taxZones: TaxZone[];
    filters?: {
        search?: string;
        tax_class_id?: number;
        tax_zone_id?: number;
        status?: string;
    };
}

const props = defineProps<Props>();

const { t } = useI18nStore();

const activeTab = ref('rules');
const searchQuery = ref(props.filters?.search || '');
const showDeleteModal = ref(false);
const deleteId = ref<number | null>(null);
const deleteType = ref<'rule' | 'class' | 'rate' | 'zone'>('rule');
const deleteMessage = ref('');
const processing = ref(false);

// Tax Class Modal State
const showTaxClassModal = ref(false);
const taxClassForm = reactive({
    id: null as number | null,
    name: '',
    code: '',
    description: '',
    is_default: false,
});

// Tax Rate Modal State
const showTaxRateModal = ref(false);
const taxRateForm = reactive({
    id: null as number | null,
    name: '',
    code: '',
    percentage: 0,
    priority: 1,
    is_compound: false,
    is_active: true,
});

// Tax Zone Modal State
const showTaxZoneModal = ref(false);
const taxZoneForm = reactive({
    id: null as number | null,
    name: '',
    code: '',
    description: '',
    is_active: true,
    locations: [] as TaxZoneLocation[],
});

const tabs = [
    { id: 'rules', name: t('Tax Rules'), icon: Gavel },
    { id: 'classes', name: t('Tax Classes'), icon: Tag },
    { id: 'rates', name: t('Tax Rates'), icon: Percent },
    { id: 'zones', name: t('Tax Zones'), icon: Map },
];

// Tax Rule Functions
const confirmDelete = (id: number) => {
    deleteId.value = id;
    deleteType.value = 'rule';
    deleteMessage.value = t(
        'Are you sure you want to delete this tax rule? This action cannot be undone.',
    );
    showDeleteModal.value = true;
};

const deleteTaxRule = () => {
    if (deleteId.value) {
        router.delete(`/admin/settings/tax-rules/${deleteId.value}`, {
            onSuccess: () => {
                showDeleteModal.value = false;
                deleteId.value = null;
            },
        });
    }
};

// Tax Class Functions
const openTaxClassModal = (taxClass?: TaxClass) => {
    if (taxClass) {
        taxClassForm.id = taxClass.id;
        taxClassForm.name = taxClass.name;
        taxClassForm.code = taxClass.code;
        taxClassForm.description = taxClass.description || '';
        taxClassForm.is_default = taxClass.is_default;
    } else {
        taxClassForm.id = null;
        taxClassForm.name = '';
        taxClassForm.code = '';
        taxClassForm.description = '';
        taxClassForm.is_default = false;
    }
    showTaxClassModal.value = true;
};

const saveTaxClass = () => {
    processing.value = true;
    const url = taxClassForm.id
        ? `/admin/settings/tax-classes/${taxClassForm.id}`
        : '/admin/settings/tax-classes';

    const method = taxClassForm.id ? 'put' : 'post';

    router[method](url, taxClassForm, {
        preserveScroll: true,
        onSuccess: () => {
            showTaxClassModal.value = false;
            processing.value = false;
        },
        onError: () => {
            processing.value = false;
        },
    });
};

const confirmDeleteTaxClass = (id: number) => {
    deleteId.value = id;
    deleteType.value = 'class';
    deleteMessage.value = t(
        'Are you sure you want to delete this tax class? This may affect existing tax rules.',
    );
    showDeleteModal.value = true;
};

const deleteTaxClass = () => {
    if (deleteId.value) {
        router.delete(`/admin/settings/tax-classes/${deleteId.value}`, {
            preserveScroll: true,
            onSuccess: () => {
                showDeleteModal.value = false;
                deleteId.value = null;
            },
        });
    }
};

// Tax Rate Functions
const openTaxRateModal = (taxRate?: TaxRate) => {
    if (taxRate) {
        taxRateForm.id = taxRate.id;
        taxRateForm.name = taxRate.name;
        taxRateForm.code = taxRate.code;
        taxRateForm.percentage = parseFloat(taxRate.percentage);
        taxRateForm.priority = taxRate.priority;
        taxRateForm.is_compound = taxRate.is_compound;
        taxRateForm.is_active = taxRate.is_active;
    } else {
        taxRateForm.id = null;
        taxRateForm.name = '';
        taxRateForm.code = '';
        taxRateForm.percentage = 0;
        taxRateForm.priority = 1;
        taxRateForm.is_compound = false;
        taxRateForm.is_active = true;
    }
    showTaxRateModal.value = true;
};

const saveTaxRate = () => {
    processing.value = true;
    const url = taxRateForm.id
        ? `/admin/settings/tax-rates/${taxRateForm.id}`
        : '/admin/settings/tax-rates';

    const method = taxRateForm.id ? 'put' : 'post';

    router[method](url, taxRateForm, {
        preserveScroll: true,
        onSuccess: () => {
            showTaxRateModal.value = false;
            processing.value = false;
        },
        onError: () => {
            processing.value = false;
        },
    });
};

const confirmDeleteTaxRate = (id: number) => {
    deleteId.value = id;
    deleteType.value = 'rate';
    deleteMessage.value = t(
        'Are you sure you want to delete this tax rate? This may affect existing tax rules.',
    );
    showDeleteModal.value = true;
};

const deleteTaxRate = () => {
    if (deleteId.value) {
        router.delete(`/admin/settings/tax-rates/${deleteId.value}`, {
            preserveScroll: true,
            onSuccess: () => {
                showDeleteModal.value = false;
                deleteId.value = null;
            },
        });
    }
};

// Tax Zone Functions
const openTaxZoneModal = (taxZone?: TaxZone) => {
    if (taxZone) {
        taxZoneForm.id = taxZone.id;
        taxZoneForm.name = taxZone.name;
        taxZoneForm.code = taxZone.code;
        taxZoneForm.description = taxZone.description || '';
        taxZoneForm.is_active = taxZone.is_active;
        taxZoneForm.locations = taxZone.locations.map((loc) => ({
            id: loc.id,
            country_code: loc.country_code,
            state_code: loc.state_code,
        }));
    } else {
        taxZoneForm.id = null;
        taxZoneForm.name = '';
        taxZoneForm.code = '';
        taxZoneForm.description = '';
        taxZoneForm.is_active = true;
        taxZoneForm.locations = [];
    }
    showTaxZoneModal.value = true;
};

// Shown read-only: the country is decided by the store, not the admin form.
const storeCountry = ref('Afghanistan');

const addLocation = () => {
    taxZoneForm.locations.push({
        country_code: '',
        state_code: null,
    });
};

const removeLocation = (index: number) => {
    taxZoneForm.locations.splice(index, 1);
};

const saveTaxZone = () => {
    processing.value = true;
    const url = taxZoneForm.id
        ? `/admin/settings/tax-zones/${taxZoneForm.id}`
        : '/admin/settings/tax-zones';

    const method = taxZoneForm.id ? 'put' : 'post';

    router[method](url, taxZoneForm, {
        preserveScroll: true,
        onSuccess: () => {
            showTaxZoneModal.value = false;
            processing.value = false;
        },
        onError: () => {
            processing.value = false;
        },
    });
};

const confirmDeleteTaxZone = (id: number) => {
    deleteId.value = id;
    deleteType.value = 'zone';
    deleteMessage.value = t(
        'Are you sure you want to delete this tax zone? This may affect existing tax rules.',
    );
    showDeleteModal.value = true;
};

const deleteTaxZone = () => {
    if (deleteId.value) {
        router.delete(`/admin/settings/tax-zones/${deleteId.value}`, {
            preserveScroll: true,
            onSuccess: () => {
                showDeleteModal.value = false;
                deleteId.value = null;
            },
        });
    }
};

// Generic Delete Function
const deleteItem = () => {
    switch (deleteType.value) {
        case 'rule':
            deleteTaxRule();
            break;
        case 'class':
            deleteTaxClass();
            break;
        case 'rate':
            deleteTaxRate();
            break;
        case 'zone':
            deleteTaxZone();
            break;
    }
};
</script>
