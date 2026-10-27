<script setup lang="ts">
import UIBlockRenderer from '@/components/UIEditor/UIBlockRenderer.vue';
import { Head } from '@inertiajs/vue3';
import { computed } from 'vue';
import ContactForm from '../../components/ContactForm.vue';
import ThemeLayout from '../../layouts/ThemeLayout.vue';

interface Props {
    page: {
        title: string;
        content: string;
        meta_title?: string;
        meta_description?: string;
        meta_keywords?: string;
        url_key: string;
        created_at?: string;
        updated_at?: string;
    };
    theme: {
        name: string;
        slug: string;
        settings: {
            primary_color: string;
            secondary_color: string;
            features: Record<string, boolean>;
        };
    };
    siteConfig: {
        name: string;
        url: string;
        description: string;
    };
    layoutData?: Record<string, unknown> | null;
}

const props = defineProps<Props>();
const hasLayout = computed(
    () =>
        !!(
            props.layoutData?.sections &&
            (props.layoutData.sections as unknown[]).length
        ),
);
// Only the contact page gets the message form. "Contact" is matched in the url
// key so a store that names it "contact" or "contact-us" both work.
const isContactPage = computed(() =>
    (props.page.url_key || '').toLowerCase().includes('contact'),
);
</script>

<template>
    <ThemeLayout>
        <Head>
            <title>{{ page.meta_title || page.title }}</title>
            <meta
                v-if="page.meta_description"
                name="description"
                :content="page.meta_description"
            />
            <meta
                v-if="page.meta_keywords"
                name="keywords"
                :content="page.meta_keywords"
            />
        </Head>

        <div class="min-h-screen bg-gray-50 dark:bg-slate-900">
            <!-- Page Content -->
            <div class="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
                <!-- Visual Editor layout takes priority when published -->
                <template v-if="hasLayout">
                    <UIBlockRenderer
                        :layout="layoutData"
                        :editor-mode="false"
                    />
                </template>
                <template v-else>
                    <div
                        class="rounded-lg bg-white p-8 shadow-sm dark:bg-slate-900"
                    >
                        <div
                            v-html="page.content"
                            class="rich-text max-w-none text-gray-700 dark:text-slate-300"
                        ></div>
                    </div>
                </template>

                <!-- Contact messages go to the dashboard inbox (free). -->
                <ContactForm v-if="isContactPage" />
            </div>
        </div>
    </ThemeLayout>
</template>

<style scoped>
/* Additional custom styles for CMS content if needed */
</style>
