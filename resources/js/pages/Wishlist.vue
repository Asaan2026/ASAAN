<script setup lang="ts">
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import { useWishlist } from '@/composables/useWishlist';
import { Head, Link } from '@inertiajs/vue3';
import { Heart, Loader2, ShoppingCart, Trash2 } from 'lucide-vue-next';
import { onMounted } from 'vue';
import ThemeLayout from '../../../templates/storefront/general/cartxis-default/resources/views/layouts/ThemeLayout.vue';

const {
    wishlistItems,
    wishlistCount,
    loading,
    removeFromWishlist,
    moveToCart,
    fetchWishlist,
} = useWishlist();

const showToast = (message: string, type: 'success' | 'error' = 'success') => {
    window.dispatchEvent(
        new CustomEvent('show-toast', {
            detail: { message, type },
        }),
    );
};

onMounted(async () => {
    await fetchWishlist();
});

const formatPrice = (price: number) => {
    return new Intl.NumberFormat('en-IN', {
        style: 'currency',
        currency: 'INR',
        minimumFractionDigits: 0,
    }).format(price);
};

const handleRemove = async (itemId: number) => {
    const result = await removeFromWishlist(itemId);
    if (result.success) {
        showToast('Removed from wishlist', 'success');
    } else {
        showToast(result.message || 'Failed to remove item', 'error');
    }
};

const handleMoveToCart = async (itemId: number) => {
    const result = await moveToCart(itemId);
    if (result.success) {
        showToast('Product moved to cart successfully!', 'success');
    } else {
        showToast(result.message || 'Failed to move to cart', 'error');
    }
};
</script>

<template>
    <Head title="My Wishlist" />

    <ThemeLayout>
        <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
            <!-- Header -->
            <div class="mb-8">
                <h1
                    class="mb-2 flex items-center gap-3 text-3xl font-bold text-gray-900"
                >
                    <Heart class="h-8 w-8 text-red-500" />
                    My Wishlist
                </h1>
                <p class="text-gray-600">
                    {{ wishlistCount }}
                    {{ wishlistCount === 1 ? 'item' : 'items' }} saved
                </p>
            </div>

            <!-- Loading State -->
            <div
                v-if="loading && wishlistItems.length === 0"
                class="py-12 text-center"
            >
                <Loader2
                    class="text-primary-500 mx-auto h-12 w-12 animate-spin"
                />
                <p class="mt-4 text-gray-600">Loading your wishlist...</p>
            </div>

            <!-- Empty State -->
            <div
                v-else-if="wishlistItems.length === 0"
                class="py-12 text-center"
            >
                <Heart class="mx-auto mb-6 h-24 w-24 text-gray-300" />
                <h2 class="mb-2 text-2xl font-semibold text-gray-900">
                    Your wishlist is empty
                </h2>
                <p class="mb-8 text-gray-600">
                    Save items you love by clicking the heart icon
                </p>
                <Link
                    href="/products"
                    class="inline-flex items-center rounded-lg bg-blue-600 px-6 py-3 font-semibold text-white transition-colors hover:bg-blue-700"
                >
                    Start Shopping
                </Link>
            </div>

            <!-- Wishlist Grid -->
            <div
                v-else
                class="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
            >
                <div
                    v-for="item in wishlistItems"
                    :key="item.id"
                    class="overflow-hidden rounded-lg bg-white shadow-md transition-shadow hover:shadow-lg"
                >
                    <!-- Product Image -->
                    <Link
                        :href="`/products/${item.product.slug}`"
                        class="relative block aspect-square overflow-hidden bg-gray-100"
                    >
                        <img
                            v-if="item.product.image"
                            :src="item.product.image"
                            :alt="item.product.name"
                            class="h-full w-full object-cover transition-transform duration-300 hover:scale-105"
                        />
                        <div
                            v-else
                            class="flex h-full w-full items-center justify-center text-gray-400"
                        >
                            No Image
                        </div>

                        <!-- Stock Badge -->
                        <div
                            v-if="!item.product.is_in_stock"
                            class="absolute top-2 right-2 rounded-full bg-red-500 px-3 py-1 text-xs font-semibold text-white"
                        >
                            Out of Stock
                        </div>
                    </Link>

                    <!-- Product Details -->
                    <div class="p-4">
                        <Link
                            :href="`/products/${item.product.slug}`"
                            class="mb-2 line-clamp-2 text-lg font-semibold text-gray-900 hover:text-blue-600"
                        >
                            {{ item.product.name }}
                        </Link>

                        <!-- Price -->
                        <div class="mb-4">
                            <div
                                v-if="item.product.special_price"
                                class="flex items-center gap-2"
                            >
                                <span class="text-xl font-bold text-red-600">
                                    {{
                                        formatPrice(item.product.special_price)
                                    }}
                                </span>
                                <span
                                    class="text-sm text-gray-500 line-through"
                                >
                                    {{ formatPrice(item.product.price) }}
                                </span>
                            </div>
                            <div v-else class="text-xl font-bold text-gray-900">
                                {{ formatPrice(item.product.price) }}
                            </div>
                        </div>

                        <!-- Actions -->
                        <div class="flex gap-2">
                            <button
                                @click="handleMoveToCart(item.id)"
                                :disabled="!item.product.is_in_stock || loading"
                                class="flex flex-1 items-center justify-center gap-2 rounded-lg bg-blue-600 px-4 py-2 font-semibold text-white transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:bg-gray-300"
                            >
                                <ShoppingCart class="h-4 w-4" />
                                Add to Cart
                            </button>
                            <button
                                @click="handleRemove(item.id)"
                                :disabled="loading"
                                class="rounded-lg bg-red-50 p-2 text-red-600 transition-colors hover:bg-red-100 disabled:opacity-50"
                                title="Remove from wishlist"
                            >
                                <Trash2 class="h-5 w-5" />
                            </button>
                        </div>

                        <!-- Added Date -->
                        <p class="mt-3 text-xs text-gray-500">
                            Added <DateDisplay :value="item.added_at" />
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </ThemeLayout>
</template>
