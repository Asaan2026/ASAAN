<script setup lang="ts">
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Head, useForm } from '@inertiajs/vue3';
import { User } from 'lucide-vue-next';
import { ref } from 'vue';

interface Props {
    user: {
        id: number;
        name: string;
        email: string;
        profile_photo_path?: string | null;
    };
}

const props = defineProps<Props>();

const { t } = useI18nStore();

const form = useForm({
    name: props.user.name,
    email: props.user.email,
    profile_photo: null as File | null,
});

const photoPreview = ref<string | null>(null);

const handleFileChange = (event: Event) => {
    const target = event.target as HTMLInputElement;
    const file = target.files?.[0];

    if (file) {
        form.profile_photo = file;

        // Create preview
        const reader = new FileReader();
        reader.onload = (e) => {
            photoPreview.value = e.target?.result as string;
        };
        reader.readAsDataURL(file);
    }
};

const submit = () => {
    form.post('/admin/profile', {
        preserveScroll: true,
        onSuccess: () => {
            photoPreview.value = null;
        },
    });
};
</script>

<template>
    <AdminLayout :title="$t('Profile Settings')">
        <Head :title="$t('Profile Settings')" />

        <div class="max-w-4xl">
            <div class="mb-6">
                <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
                    {{ $t('Profile Settings') }}
                </h1>
                <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                    {{ $t('Update your profile information and photo') }}
                </p>
            </div>

            <div
                class="rounded-lg border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <form @submit.prevent="submit" class="space-y-6 p-6">
                    <!-- Profile Photo -->
                    <div class="space-y-2">
                        <Label for="profile_photo">{{
                            $t('Profile Photo')
                        }}</Label>
                        <div class="flex items-center gap-6">
                            <!-- Current/Preview Photo -->
                            <div class="flex-shrink-0">
                                <div
                                    v-if="photoPreview"
                                    class="h-24 w-24 overflow-hidden rounded-full border-2 border-gray-200 dark:border-gray-600"
                                >
                                    <img
                                        :src="photoPreview"
                                        :alt="$t('Preview')"
                                        class="h-full w-full object-cover"
                                    />
                                </div>
                                <div
                                    v-else-if="user.profile_photo_path"
                                    class="h-24 w-24 overflow-hidden rounded-full border-2 border-gray-200 dark:border-gray-600"
                                >
                                    <img
                                        :src="`/storage/${user.profile_photo_path}`"
                                        :alt="$t('Current photo')"
                                        class="h-full w-full object-cover"
                                    />
                                </div>
                                <div
                                    v-else
                                    class="flex h-24 w-24 items-center justify-center rounded-full border-2 border-gray-200 bg-gray-200 dark:border-gray-600 dark:bg-gray-700"
                                >
                                    <User class="h-12 w-12 text-gray-400" />
                                </div>
                            </div>

                            <!-- File Input -->
                            <div class="flex-1">
                                <Input
                                    id="profile_photo"
                                    type="file"
                                    accept="image/*"
                                    @change="handleFileChange"
                                    class="cursor-pointer"
                                />
                                <p
                                    class="mt-2 text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{ $t('JPG, PNG or GIF (max. 2MB)') }}
                                </p>
                            </div>
                        </div>
                        <p
                            v-if="form.errors.profile_photo"
                            class="text-sm text-red-600 dark:text-red-400"
                        >
                            {{ form.errors.profile_photo }}
                        </p>
                    </div>

                    <!-- Name -->
                    <div class="space-y-2">
                        <Label for="name">{{ $t('Name') }}</Label>
                        <Input
                            id="name"
                            v-model="form.name"
                            type="text"
                            required
                            class="w-full"
                            :placeholder="$t('Your name')"
                        />
                        <p
                            v-if="form.errors.name"
                            class="text-sm text-red-600 dark:text-red-400"
                        >
                            {{ form.errors.name }}
                        </p>
                    </div>

                    <!-- Email -->
                    <div class="space-y-2">
                        <Label for="email">{{ $t('Email') }}</Label>
                        <Input
                            id="email"
                            v-model="form.email"
                            type="email"
                            required
                            class="w-full"
                            placeholder="your.email@example.com"
                        />
                        <p
                            v-if="form.errors.email"
                            class="text-sm text-red-600 dark:text-red-400"
                        >
                            {{ form.errors.email }}
                        </p>
                    </div>

                    <!-- Submit Button -->
                    <div
                        class="flex items-center gap-4 border-t border-gray-200 pt-4 dark:border-gray-700"
                    >
                        <button
                            type="submit"
                            :disabled="form.processing"
                            class="inline-flex items-center justify-center rounded-md border border-transparent bg-blue-600 px-6 py-2 text-sm font-medium text-white shadow-sm hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            {{
                                form.processing
                                    ? $t('Saving...')
                                    : $t('Save Changes')
                            }}
                        </button>

                        <Transition
                            enter-active-class="transition ease-in-out"
                            enter-from-class="opacity-0"
                            leave-active-class="transition ease-in-out"
                            leave-to-class="opacity-0"
                        >
                            <p
                                v-show="form.recentlySuccessful"
                                class="text-sm text-green-600 dark:text-green-400"
                            >
                                {{ $t('Saved successfully!') }}
                            </p>
                        </Transition>
                    </div>
                </form>
            </div>
        </div>
    </AdminLayout>
</template>
