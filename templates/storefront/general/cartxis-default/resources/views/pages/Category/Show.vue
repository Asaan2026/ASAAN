<script setup lang="ts">
import { Head, Link } from '@inertiajs/vue3';
import ThemeLayout from '../../layouts/ThemeLayout.vue';
import ProductCard from '../../components/ProductCard.vue';
import { useCurrency } from '@/composables/useCurrency';
import { computed, ref } from 'vue';

interface Category {
    id: number;
    name: string;
    slug: string;
    description?: string;
    image?: string;
    image_url?: string;
    children?: Category[];
}

interface Product {
    id: number;
    name: string;
    slug: string;
    price: number;
    special_price?: number | null;
    image?: string | null;
    rating?: number;
    reviews_count?: number;
}

interface Props {
    category: Category;
    products: {
        data: Product[];
        total: number;
        per_page: number;
        current_page: number;
        last_page: number;
    };
    filters: {
        per_page: number;
        sort: string;
    };
    seo: {
        title: string;
        description: string;
        keywords: string;
    };
}

const props = defineProps<Props>();
const { formatPrice } = useCurrency();

const hasDiscount = (product: Product) => {
    const sp = product.special_price;
    if (sp === null || sp === undefined) return false;
    const n = typeof sp === 'string' ? parseFloat(sp) : sp;
    if (!n || n <= 0) return false;
    return n < product.price;
};

const discountPercentage = (product: Product) => {
    if (!hasDiscount(product)) return 0;
    const sp = product.special_price;
    const n = typeof sp === 'string' ? parseFloat(sp) : (sp as number);
    return Math.round(((product.price - n) / product.price) * 100);
};
</script>

<template>
    <Head>
        <title>{{ seo.title }}</title>
        <meta name="description" :content="seo.description" />
        <meta name="keywords" :content="seo.keywords" />
    </Head>

    <ThemeLayout>
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            <!-- Breadcrumb -->
            <nav class="flex mb-6 text-sm">
                <Link href="/" class="text-gray-600 dark:text-slate-400 hover:text-gray-900 dark:hover:text-slate-100">{{ $t('Home') }}</Link>
                <span class="mx-2 text-gray-400 dark:text-slate-500">/</span>
                <Link href="/products" class="text-gray-600 dark:text-slate-400 hover:text-gray-900 dark:hover:text-slate-100">{{ $t('Products') }}</Link>
                <span class="mx-2 text-gray-400 dark:text-slate-500">/</span>
                <span class="text-gray-900 dark:text-slate-100 font-medium">{{ category.name }}</span>
            </nav>

            <!-- Category Header -->
            <div class="mb-8">
                <div class="flex items-start justify-between">
                    <div class="flex-1">
                        <h1 class="text-3xl font-bold text-gray-900 dark:text-slate-100 mb-3">{{ category.name }}</h1>
                        <div v-if="category.description" class="rich-text rich-text-tight text-gray-600 dark:text-slate-400 max-w-3xl" v-html="category.description"></div>
                    </div>
                    <img 
                        v-if="category.image_url" 
                        :src="category.image_url" 
                        :alt="category.name"
                        class="w-32 h-32 object-contain rounded-lg ml-6 bg-gray-100 dark:bg-slate-800"
                    />
                </div>

                <!-- Subcategories -->
                <div v-if="category.children && category.children.length > 0" class="mt-6">
                    <h2 class="text-lg font-semibold text-gray-900 dark:text-slate-100 mb-3">{{ $t('Shop by Category') }}</h2>
                    <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
                        <Link
                            v-for="child in category.children"
                            :key="child.id"
                            :href="`/category/${child.slug}`"
                            class="flex flex-col items-center p-4 bg-white dark:bg-slate-900 rounded-lg border border-gray-200 dark:border-slate-700 hover:border-indigo-500 hover:shadow-md transition-all"
                        >
                            <div class="w-16 h-16 bg-gray-100 dark:bg-slate-800 rounded-full flex items-center justify-center mb-2 overflow-hidden">
                                <img
                                    v-if="child.image_url"
                                    :src="child.image_url"
                                    :alt="child.name"
                                    class="w-full h-full object-cover"
                                    loading="lazy"
                                />
                                <svg v-else class="w-8 h-8 text-gray-400 dark:text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
                                </svg>
                            </div>
                            <span class="text-sm font-medium text-gray-900 dark:text-slate-100 text-center">{{ child.name }}</span>
                        </Link>
                    </div>
                </div>
            </div>

            <!-- Products Header -->
            <div class="flex items-center justify-between mb-6 border-b pb-4">
                <div class="text-sm text-gray-600 dark:text-slate-400">
                    {{ $t('Showing {count} of {total} products', { count: products.data.length, total: products.total }) }}
                </div>
                <div class="flex items-center space-x-4">
                    <label class="text-sm text-gray-700 dark:text-slate-300">
                        {{ $t('Sort by:') }}
                        <select 
                            class="ml-2 border border-gray-300 dark:border-slate-600 rounded-md px-3 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                            @change="(e) => $inertia.get(`/category/${category.slug}`, { sort: (e.target as HTMLSelectElement).value })"
                        >
                            <option value="position">{{ $t('Featured') }}</option>
                            <option value="name">{{ $t('Name (A-Z)') }}</option>
                            <option value="-name">{{ $t('Name (Z-A)') }}</option>
                            <option value="price">{{ $t('Price: Low to High') }}</option>
                            <option value="-price">{{ $t('Price: High to Low') }}</option>
                            <option value="-created_at">{{ $t('Newest First') }}</option>
                        </select>
                    </label>
                </div>
            </div>

            <!-- Products Grid -->
            <div v-if="products.data.length > 0" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 mb-8">
                <ProductCard
                    v-for="product in products.data"
                    :key="product.id"
                    :product="product"
                />
            </div>

            <!-- Empty State -->
            <div v-else class="text-center py-16">
                <svg class="mx-auto h-24 w-24 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
                </svg>
                <h3 class="mt-4 text-lg font-medium text-gray-900 dark:text-slate-100">{{ $t('No products found') }}</h3>
                <p class="mt-2 text-gray-500 dark:text-slate-400">{{ $t("This category doesn't have any products yet.") }}</p>
                <Link href="/products" class="mt-6 inline-block px-6 py-3 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition-colors">
                    {{ $t('Browse All Products') }}
                </Link>
            </div>

            <!-- Pagination -->
            <div v-if="products.last_page > 1" class="flex items-center justify-center space-x-2 mt-8">
                <Link
                    v-for="page in products.last_page"
                    :key="page"
                    :href="`/category/${category.slug}?page=${page}`"
                    class="px-4 py-2 rounded-md text-sm font-medium transition-colors"
                    :class="page === products.current_page 
                        ? 'bg-indigo-600 text-white' 
                        : 'bg-white text-gray-700 hover:bg-gray-100 border border-gray-300'"
                >
                    {{ page }}
                </Link>
            </div>
        </div>
    </ThemeLayout>
</template>
