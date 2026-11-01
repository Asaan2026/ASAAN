<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { Link } from '@inertiajs/vue3';
import { useCart } from '@/composables/useCart';
import { useCurrency } from '@/composables/useCurrency';
import { useWishlist } from '@/composables/useWishlist';
import { useThemeSettings } from '@/composables/useThemeSettings';
import { useI18nStore } from '@/Stores/i18n';
import { Check, Heart, Plus } from 'lucide-vue-next';
import ThemePlaceholderIcon from './ThemePlaceholderIcon.vue';

const i18n = useI18nStore();
const { formatPrice } = useCurrency();
const { toggleWishlist, isInWishlist, loading: wishlistLoading } = useWishlist();
const { primary, wishlistEnabled, quickViewEnabled } = useThemeSettings();

interface ProductBadge {
    text: string;
    class?: string;
}

interface Product {
    id: number;
    name: string;
    slug: string;
    sku: string;
    type?: string;
    price: number;
    special_price: number | null;
    image: string | null;
    rating: number;
    reviews_count: number;
    stock_quantity: number;
    in_stock: boolean;
    has_configurable_attributes: boolean;
    badges?: ProductBadge[];
    brand?: {
        id: number;
        name: string;
        slug: string;
    };
}

const props = withDefaults(defineProps<{
    product: Product;
    compact?: boolean;
}>(), {
    compact: false,
});

const emit = defineEmits<{
    quickView: [slug: string];
}>();

const { addToCart, loading } = useCart();

const addingToCart = ref(false);
const showSuccess = ref(false);

const imageBroken = ref(false);

watch(() => props.product.image, () => {
    imageBroken.value = false;
});

// A special price of 0 (or anything not strictly positive and below the
// regular price) is not a real discount. Seed data stores 0 instead of NULL,
// so guard against it here as well as in the backend accessor.
const effectiveSpecialPrice = computed(() => {
    const sp = props.product.special_price;
    if (sp === null || sp === undefined) return null;
    const n = typeof sp === 'string' ? parseFloat(sp) : sp;
    if (!n || n <= 0) return null;
    const price = typeof props.product.price === 'string' ? parseFloat(props.product.price) : props.product.price;
    if (price && n >= price) return null;
    return n;
});

const displayPrice = computed(() => {
    const price = effectiveSpecialPrice.value ?? props.product.price;
    return typeof price === 'string' ? parseFloat(price) : price;
});

const hasDiscount = computed(() => effectiveSpecialPrice.value !== null);

const discountPercentage = computed(() => {
    if (!hasDiscount.value) return 0;
    const price = typeof props.product.price === 'string' ? parseFloat(props.product.price) : props.product.price;
    const specialPrice = effectiveSpecialPrice.value!;
    if (!price) return 0;
    return Math.round(((price - specialPrice) / price) * 100);
});

const showRatings = computed(() => !props.compact || props.product.reviews_count > 0);

const handleAddToCart = async () => {
    if (props.product.has_configurable_attributes) {
        emit('quickView', props.product.slug);
        return;
    }

    addingToCart.value = true;
    const result = await addToCart(props.product.id, 1);

    if (result.success) {
        showSuccess.value = true;
        setTimeout(() => {
            showSuccess.value = false;
        }, 2000);
    }

    addingToCart.value = false;
};

const renderStars = (rating: number) => {
    const stars = [];
    const fullStars = Math.floor(rating);
    const hasHalfStar = rating % 1 >= 0.5;

    for (let i = 0; i < fullStars; i++) stars.push('★');
    if (hasHalfStar) stars.push('☆');
    while (stars.length < 5) stars.push('☆');

    return stars.join('');
};

const handleWishlistToggle = async () => {
    await toggleWishlist(props.product.id);
};

// On a phone the button is an icon, so the only thing a screen reader has to
// go on is this label. It also becomes the hover tooltip on a desktop.
const addButtonLabel = computed(() => {
    if (!props.product.in_stock) return i18n.t('Out of Stock');
    if (props.product.has_configurable_attributes)
        return i18n.t('Choose options');
    return i18n.t('Add to Cart');
});
</script>

<template>
    <div class="group relative bg-white dark:bg-slate-900 rounded-2xl overflow-hidden shadow-md hover:shadow-2xl transition-all duration-300">
        <Link :href="`/product/${product.slug}`" class="block">
            <div class="relative aspect-square bg-gradient-to-br from-blue-50 to-slate-100 dark:from-slate-800 dark:to-slate-900 overflow-hidden">
                <!-- Barely any padding on a phone: in a card about 170px wide,
                     12px of padding on each side is a tenth of the picture. -->
                <img
                    v-if="product.image && !imageBroken"
                    :src="product.image"
                    :alt="product.name"
                    class="w-full h-full object-contain p-1 sm:p-3 group-hover:scale-105 transition-transform duration-300"
                    loading="lazy"
                    @error="imageBroken = true"
                />
                <div v-else class="absolute inset-0 flex items-center justify-center opacity-50">
                    <ThemePlaceholderIcon />
                </div>

                <div class="absolute top-2 left-2 sm:top-4 sm:left-4 flex flex-col gap-1 sm:gap-2">
                    <span
                        v-for="(badge, index) in product.badges ?? []"
                        :key="index"
                        class="px-1.5 py-0.5 text-[10px] sm:px-3 sm:py-1 sm:text-xs font-bold rounded-full"
                        :class="badge.class ?? 'bg-blue-600 text-white'"
                    >
                        {{ badge.text }}
                    </span>

                    <span v-if="hasDiscount" class="px-1.5 py-0.5 text-[10px] sm:px-3 sm:py-1 sm:text-sm bg-red-500 text-white font-bold rounded-full">
                        -{{ discountPercentage }}%
                    </span>

                    <span
                        v-if="product.type && (product.type === 'virtual' || product.type === 'downloadable')"
                        class="px-1.5 py-0.5 text-[10px] sm:px-3 sm:py-1 sm:text-xs font-medium rounded-full inline-flex items-center"
                        :class="{
                            'bg-blue-500 text-white': product.type === 'virtual',
                            'bg-cyan-500 text-white': product.type === 'downloadable',
                        }"
                    >
                        {{ $t(product.type === 'downloadable' ? 'Digital' : 'Virtual') }}
                    </span>
                </div>

                <button
                    v-if="product.in_stock && wishlistEnabled"
                    @click.prevent="handleWishlistToggle"
                    :disabled="wishlistLoading"
                    class="absolute top-2 right-2 p-1.5 sm:top-4 sm:right-4 sm:p-2 bg-white/90 dark:bg-slate-900/90 hover:bg-white dark:hover:bg-slate-800 rounded-full shadow-md transition-all hover:scale-110 disabled:opacity-50 z-10"
                    :title="$t('Add to wishlist')"
                    :aria-label="$t('Add to wishlist')"
                >
                    <Heart
                        :class="{ 'fill-red-500 text-red-500': isInWishlist(product.id), 'text-gray-600 dark:text-slate-300': !isInWishlist(product.id) }"
                        class="w-4 h-4 sm:w-5 sm:h-5 transition-colors"
                    />
                </button>

                <div v-if="!product.in_stock" class="absolute top-2 right-2 sm:top-4 sm:right-4">
                    <span class="px-2 py-0.5 text-[10px] sm:px-3 sm:py-1 sm:text-sm bg-gray-900 text-white font-semibold rounded-full">
                        {{ $t('Out of Stock') }}
                    </span>
                </div>

                <div
                    v-if="quickViewEnabled"
                    class="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center"
                >
                    <button
                        @click.prevent="emit('quickView', product.slug)"
                        class="px-6 py-3 bg-white dark:bg-slate-900 text-gray-900 dark:text-slate-100 rounded-lg font-semibold hover:bg-gray-100 dark:hover:bg-slate-800 transition-all transform hover:scale-105 cursor-pointer"
                    >
                        {{ $t('Quick View') }}
                    </button>
                </div>
            </div>
        </Link>

        <div class="p-2.5 sm:p-4">
            <div v-if="product.brand" class="mb-1 sm:mb-2">
                <Link
                    :href="`/brands/${product.brand.slug}`"
                    class="text-xs text-gray-500 dark:text-slate-400 hover:text-gray-700 transition-colors"
                >
                    {{ product.brand.name }}
                </Link>
            </div>

            <Link :href="`/product/${product.slug}`">
                <!-- The reserved two-line height is a desktop nicety that keeps
                     a row of cards aligned. On a phone it is wasted space. -->
                <h3
                    class="font-semibold text-gray-900 dark:text-slate-100 text-[13px] leading-snug sm:text-base mb-1 sm:mb-2 transition-colors line-clamp-2 sm:min-h-[3rem] group-hover:text-[var(--theme-primary)]"
                >
                    {{ product.name }}
                </h3>
            </Link>

            <div v-if="showRatings" class="flex items-center gap-1.5 sm:gap-2 mb-1.5 sm:mb-3">
                <div class="flex text-yellow-400 text-[11px] sm:text-sm">
                    {{ renderStars(product.rating) }}
                </div>
                <span class="text-[10px] sm:text-xs text-gray-500 dark:text-slate-400">({{ product.reviews_count }})</span>
            </div>

            <!-- Phone: price on the left, a round + on the right, one line.
                 Tablet and up: price above, the labelled button beneath, which
                 is clearer where there is room for the words. -->
            <div class="flex items-center justify-between gap-2 sm:block">
                <div class="min-w-0 sm:mb-3">
                    <div class="flex items-baseline gap-1 sm:gap-2 flex-wrap">
                        <span class="text-base sm:text-2xl font-bold text-gray-900 dark:text-slate-100">
                            {{ formatPrice(displayPrice) }}
                        </span>
                        <span v-if="hasDiscount" class="text-[11px] sm:text-sm text-gray-500 dark:text-slate-400 line-through">
                            {{ formatPrice(typeof product.price === 'string' ? parseFloat(product.price) : product.price) }}
                        </span>
                    </div>
                </div>

                <button
                    @click="handleAddToCart"
                    :disabled="!product.in_stock || addingToCart"
                    :title="addButtonLabel"
                    :aria-label="addButtonLabel"
                    class="shrink-0 flex items-center justify-center gap-2 font-semibold transition-all cursor-pointer text-white hover:shadow-lg disabled:cursor-not-allowed h-9 w-9 rounded-full sm:h-auto sm:w-full sm:rounded-lg sm:px-4 sm:py-3"
                    :style="product.in_stock ? { backgroundColor: primary } : undefined"
                    :class="{ 'bg-gray-300 text-gray-500 dark:bg-slate-700 dark:text-slate-400': !product.in_stock, 'animate-pulse': addingToCart }"
                >
                    <template v-if="addingToCart">
                        <svg class="animate-spin h-4 w-4 sm:h-5 sm:w-5" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                        </svg>
                        <span class="hidden sm:inline">{{ $t('Adding...') }}</span>
                    </template>
                    <template v-else-if="showSuccess">
                        <Check class="h-5 w-5 sm:hidden" />
                        <span class="hidden sm:inline">{{ $t('Added!') }}</span>
                    </template>
                    <template v-else-if="product.in_stock">
                        <Plus class="h-5 w-5 sm:hidden" />
                        <span class="hidden sm:inline">{{ $t('Add to Cart') }}</span>
                    </template>
                    <template v-else>
                        <Plus class="h-5 w-5 sm:hidden" />
                        <span class="hidden sm:inline">{{ $t('Out of Stock') }}</span>
                    </template>
                </button>
            </div>
        </div>
    </div>
</template>
