<script setup lang="ts">
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Head, Link, router } from '@inertiajs/vue3';
import { Edit, Plus, Shield, Trash2 } from 'lucide-vue-next';

interface Permission {
    id: number;
    name: string;
    display_name: string;
    group: string;
    description: string;
    created_at: string;
}

interface Props {
    permissions: Record<string, Permission[]>;
}

const props = defineProps<Props>();

const { t } = useI18nStore();

const deletePermission = (permission: Permission) => {
    if (
        confirm(
            `Are you sure you want to delete permission "${permission.display_name}"?`,
        )
    ) {
        router.delete(`/admin/system/permissions/${permission.id}`, {
            preserveScroll: true,
        });
    }
};

const getGroupColor = (group: string) => {
    const colors: Record<string, string> = {
        catalog:
            'bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-200',
        sales: 'bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-200',
        customer:
            'bg-purple-100 text-purple-800 dark:bg-purple-900/40 dark:text-purple-200',
        marketing:
            'bg-pink-100 text-pink-800 dark:bg-pink-900/40 dark:text-pink-200',
        content:
            'bg-orange-100 text-orange-800 dark:bg-orange-900/40 dark:text-orange-200',
        settings:
            'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200',
        system: 'bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-200',
        reports:
            'bg-indigo-100 text-indigo-800 dark:bg-indigo-900/40 dark:text-indigo-200',
    };
    return (
        colors[group.toLowerCase()] ||
        'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200'
    );
};
</script>

<template>
    <Head :title="$t('Permissions Management')" />

    <AdminLayout :title="$t('Permissions Management')">
        <div class="space-y-6">
            <!-- Header -->
            <div
                class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
            >
                <div>
                    <h1
                        class="flex items-center gap-2 text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Permissions Management') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        {{
                            $t('Manage system permissions and access controls')
                        }}
                    </p>
                </div>
                <Link
                    href="/admin/system/permissions/create"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <Plus class="mr-2 h-4 w-4" />
                    {{ $t('Add Permission') }}
                </Link>
            </div>

            <!-- Content -->
            <div class="overflow-auto rounded-xl">
                <!-- Permissions by Group -->
                <div class="space-y-6">
                    <div
                        v-for="(groupPermissions, group) in props.permissions"
                        :key="group"
                        class="overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900"
                    >
                        <!-- Group Header -->
                        <div
                            class="border-b border-gray-200 bg-gray-50 px-6 py-3 dark:border-gray-700 dark:bg-gray-800/60"
                        >
                            <div class="flex items-center gap-2">
                                <span
                                    class="rounded-full px-2.5 py-0.5 text-xs font-semibold tracking-wide uppercase"
                                    :class="getGroupColor(group)"
                                >
                                    {{ group }}
                                </span>
                                <span
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{
                                        $t(
                                            groupPermissions.length === 1
                                                ? '{count} permission'
                                                : '{count} permissions',
                                            { count: groupPermissions.length },
                                        )
                                    }}
                                </span>
                            </div>
                        </div>

                        <!-- Permissions Table -->
                        <table
                            class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                        >
                            <thead class="bg-gray-50 dark:bg-gray-700/50">
                                <tr>
                                    <th
                                        class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Name') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Display Name') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Description') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Created') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-right text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Actions') }}
                                    </th>
                                </tr>
                            </thead>
                            <tbody
                                class="divide-y divide-gray-200 dark:divide-gray-700"
                            >
                                <tr
                                    v-for="permission in groupPermissions"
                                    :key="permission.id"
                                    class="group transition-colors hover:bg-gray-50 dark:hover:bg-gray-800/60"
                                >
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <code
                                            class="rounded border border-gray-200 bg-gray-100 px-2 py-1 font-mono text-xs text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
                                        >
                                            {{ permission.name }}
                                        </code>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div
                                            class="text-sm font-medium text-gray-900 dark:text-white"
                                        >
                                            {{ permission.display_name }}
                                        </div>
                                    </td>
                                    <td class="px-6 py-4">
                                        <div
                                            class="text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                permission.description ||
                                                $t('No description')
                                            }}
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-sm whitespace-nowrap text-gray-500 dark:text-gray-400"
                                    >
                                        <DateDisplay
                                            :value="permission.created_at"
                                        />
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-0 transition-opacity group-hover:opacity-100"
                                        >
                                            <Link
                                                :href="`/admin/system/permissions/${permission.id}/edit`"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                :title="$t('Edit')"
                                            >
                                                <Edit class="h-4 w-4" />
                                            </Link>
                                            <button
                                                @click="
                                                    deletePermission(permission)
                                                "
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20"
                                                :title="$t('Delete')"
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

                <!-- Empty State -->
                <div
                    v-if="Object.keys(props.permissions).length === 0"
                    class="flex flex-col items-center justify-center rounded-lg border border-gray-200 bg-white p-12 text-center shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <Shield
                        class="mb-4 h-16 w-16 text-gray-300 dark:text-gray-600"
                    />
                    <h3
                        class="mb-2 text-lg font-medium text-gray-900 dark:text-white"
                    >
                        {{ $t('No permissions found') }}
                    </h3>
                    <p class="mb-6 text-gray-500 dark:text-gray-400">
                        {{
                            $t('Get started by creating your first permission.')
                        }}
                    </p>
                    <Link
                        href="/admin/system/permissions/create"
                        class="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700"
                    >
                        <Plus class="h-4 w-4" />
                        {{ $t('Add Permission') }}
                    </Link>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>
