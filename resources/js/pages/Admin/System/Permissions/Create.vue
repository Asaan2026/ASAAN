<script setup lang="ts">
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Head, Link, useForm } from '@inertiajs/vue3';
import { ArrowLeft, List, PenLine } from 'lucide-vue-next';
import { ref } from 'vue';

interface Props {
    existingGroups: string[];
}

const props = defineProps<Props>();

const { t } = useI18nStore();

const form = useForm({
    name: '',
    display_name: '',
    group: '',
    description: '',
});

const customGroup = ref('');
const showCustomGroup = ref(false);

const toggleCustomGroup = () => {
    showCustomGroup.value = !showCustomGroup.value;
    if (showCustomGroup.value) {
        form.group = customGroup.value;
    } else {
        customGroup.value = form.group;
        form.group = '';
    }
};

const updateGroup = (value: string) => {
    if (showCustomGroup.value) {
        customGroup.value = value;
        form.group = value;
    } else {
        form.group = value;
    }
};

const submit = () => {
    form.post('/admin/system/permissions', {
        preserveScroll: true,
    });
};
</script>

<template>
    <Head :title="$t('Create Permission')" />

    <AdminLayout :title="$t('Create Permission')">
        <div class="max-w-9xl mx-auto w-full px-4 py-8 sm:px-6 lg:px-8">
            <!-- Header -->
            <div class="mb-8">
                <div class="flex items-center justify-between">
                    <div>
                        <h1
                            class="text-2xl font-bold text-gray-800 md:text-3xl dark:text-gray-100"
                        >
                            {{ $t('Create Permission') }}
                        </h1>
                        <p
                            class="mt-1 text-sm text-gray-600 dark:text-gray-300"
                        >
                            {{ $t('Add a new permission to the system') }}
                        </p>
                    </div>
                    <Link
                        href="/admin/system/permissions"
                        class="inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none dark:border-gray-700 dark:bg-gray-900 dark:text-gray-200 dark:hover:bg-gray-800"
                    >
                        <ArrowLeft class="mr-2 h-4 w-4" />
                        {{ $t('Back to Permissions') }}
                    </Link>
                </div>
            </div>

            <!-- Form -->
            <div
                class="rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-800 dark:bg-gray-900"
            >
                <form @submit.prevent="submit" class="space-y-6">
                    <!-- Name -->
                    <div class="space-y-2">
                        <Label for="name" class="required">{{
                            $t('Permission Name')
                        }}</Label>
                        <Input
                            id="name"
                            v-model="form.name"
                            type="text"
                            placeholder="e.g., catalog.products.view"
                            class="font-mono"
                            required
                        />
                        <p class="text-sm text-gray-500 dark:text-gray-300">
                            {{
                                $t(
                                    'Use dot notation for permission keys (e.g., module.resource.action)',
                                )
                            }}
                        </p>
                        <p v-if="form.errors.name" class="text-sm text-red-600">
                            {{ form.errors.name }}
                        </p>
                    </div>

                    <!-- Display Name -->
                    <div class="space-y-2">
                        <Label for="display_name" class="required">{{
                            $t('Display Name')
                        }}</Label>
                        <Input
                            id="display_name"
                            v-model="form.display_name"
                            type="text"
                            placeholder="e.g., View Products"
                            required
                        />
                        <p class="text-sm text-gray-500 dark:text-gray-300">
                            {{
                                $t('A human-readable name for this permission')
                            }}
                        </p>
                        <p
                            v-if="form.errors.display_name"
                            class="text-sm text-red-600"
                        >
                            {{ form.errors.display_name }}
                        </p>
                    </div>

                    <!-- Group Selection -->
                    <div class="space-y-2">
                        <Label for="group" class="required">{{
                            $t('Permission Group')
                        }}</Label>
                        <select
                            v-if="!showCustomGroup"
                            id="group"
                            v-model="form.group"
                            class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:outline-none dark:border-gray-700 dark:bg-gray-900 dark:text-gray-100"
                            required
                        >
                            <option value="" disabled>
                                {{ $t('Select a group') }}
                            </option>
                            <option value="catalog">{{ $t('Catalog') }}</option>
                            <option value="sales">{{ $t('Sales') }}</option>
                            <option value="customer">
                                {{ $t('Customer') }}
                            </option>
                            <option value="marketing">
                                {{ $t('Marketing') }}
                            </option>
                            <option value="content">{{ $t('Content') }}</option>
                            <option value="settings">
                                {{ $t('Settings') }}
                            </option>
                            <option value="system">{{ $t('System') }}</option>
                            <option value="reports">{{ $t('Reports') }}</option>
                            <option
                                v-for="group in props.existingGroups"
                                :key="group"
                                :value="group"
                            >
                                {{ group }}
                            </option>
                        </select>
                        <Input
                            v-else
                            id="custom_group"
                            v-model="customGroup"
                            type="text"
                            :placeholder="$t('Enter custom group name')"
                            @input="updateGroup(customGroup)"
                            required
                        />
                        <button
                            type="button"
                            @click="toggleCustomGroup"
                            class="inline-flex items-center gap-1.5 text-xs text-blue-600 underline-offset-2 transition-colors hover:text-blue-800 hover:underline dark:text-blue-400 dark:hover:text-blue-300"
                        >
                            <List v-if="showCustomGroup" class="h-3.5 w-3.5" />
                            <PenLine v-else class="h-3.5 w-3.5" />
                            {{
                                showCustomGroup
                                    ? $t('Choose from existing groups')
                                    : $t('Use a custom group name')
                            }}
                        </button>
                        <p class="text-sm text-gray-500 dark:text-gray-300">
                            {{ $t('Group related permissions together') }}
                        </p>
                        <p
                            v-if="form.errors.group"
                            class="text-sm text-red-600"
                        >
                            {{ form.errors.group }}
                        </p>
                    </div>

                    <!-- Description -->
                    <div class="space-y-2">
                        <Label for="description">{{ $t('Description') }}</Label>
                        <Textarea
                            id="description"
                            v-model="form.description"
                            :placeholder="
                                $t('Describe what this permission allows...')
                            "
                            rows="3"
                        />
                        <p class="text-sm text-gray-500 dark:text-gray-300">
                            {{
                                $t(
                                    'Optional description to explain what this permission controls',
                                )
                            }}
                        </p>
                        <p
                            v-if="form.errors.description"
                            class="text-sm text-red-600"
                        >
                            {{ form.errors.description }}
                        </p>
                    </div>

                    <!-- Actions -->
                    <div
                        class="flex items-center justify-end gap-3 border-t pt-4 dark:border-gray-800"
                    >
                        <Link
                            href="/admin/system/permissions"
                            class="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none dark:border-gray-700 dark:bg-gray-900 dark:text-gray-200 dark:hover:bg-gray-800"
                        >
                            {{ $t('Cancel') }}
                        </Link>
                        <button
                            type="submit"
                            :disabled="form.processing"
                            class="inline-flex items-center rounded-md border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            {{
                                form.processing
                                    ? $t('Creating...')
                                    : $t('Create Permission')
                            }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </AdminLayout>
</template>

<style scoped>
.required::after {
    content: ' *';
    color: #ef4444;
}
</style>
