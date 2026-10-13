<script setup lang="ts">
import {
    BarChart3,
    BookOpen,
    Check,
    Clock,
    CreditCard,
    FileText,
    Flag,
    FolderOpen,
    FolderTree,
    Globe,
    Image,
    Laptop,
    LayoutDashboard,
    ListChecks,
    Mail,
    Megaphone,
    Menu,
    Newspaper,
    Package,
    Percent,
    Receipt,
    Search,
    Server,
    Settings,
    Shield,
    ShoppingBag,
    ShoppingCart,
    Star,
    Store,
    Tag,
    Ticket,
    TrendingUp,
    Truck,
    Users,
    Wrench,
    X,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Props {
    modelValue: string | null;
}

interface Emits {
    (e: 'update:modelValue', value: string): void;
}

const props = defineProps<Props>();
const emit = defineEmits<Emits>();

const showPicker = ref(false);
const searchQuery = ref('');

// Common Lucide icons for admin menu
const availableIcons = [
    {
        name: 'layout-dashboard',
        label: 'Dashboard',
        component: LayoutDashboard,
    },
    { name: 'package', label: 'Package', component: Package },
    { name: 'shopping-bag', label: 'Shopping Bag', component: ShoppingBag },
    { name: 'shopping-cart', label: 'Shopping Cart', component: ShoppingCart },
    { name: 'users', label: 'Users', component: Users },
    { name: 'trending-up', label: 'Trending Up', component: TrendingUp },
    { name: 'file-text', label: 'File Text', component: FileText },
    { name: 'bar-chart-3', label: 'Bar Chart', component: BarChart3 },
    { name: 'settings', label: 'Settings', component: Settings },
    { name: 'server', label: 'Server', component: Server },
    { name: 'folder-open', label: 'Folder', component: FolderOpen },
    { name: 'folder-tree', label: 'Folder Tree', component: FolderTree },
    { name: 'list-checks', label: 'List Checks', component: ListChecks },
    { name: 'tag', label: 'Tag', component: Tag },
    { name: 'star', label: 'Star', component: Star },
    { name: 'truck', label: 'Truck', component: Truck },
    { name: 'receipt', label: 'Receipt', component: Receipt },
    { name: 'credit-card', label: 'Credit Card', component: CreditCard },
    { name: 'megaphone', label: 'Megaphone', component: Megaphone },
    { name: 'ticket', label: 'Ticket', component: Ticket },
    { name: 'mail', label: 'Mail', component: Mail },
    { name: 'globe', label: 'Globe', component: Globe },
    { name: 'book-open', label: 'Book Open', component: BookOpen },
    { name: 'newspaper', label: 'Newspaper', component: Newspaper },
    { name: 'image', label: 'Image', component: Image },
    { name: 'wrench', label: 'Wrench', component: Wrench },
    { name: 'shop', label: 'Shop', component: Store },
    { name: 'flag', label: 'Flag', component: Flag },
    { name: 'devices', label: 'Devices', component: Laptop },
    { name: 'percent', label: 'Percent', component: Percent },
    { name: 'clock', label: 'Clock', component: Clock },
    { name: 'shield', label: 'Shield', component: Shield },
    { name: 'menu', label: 'Menu', component: Menu },
];

const filteredIcons = computed(() => {
    if (!searchQuery.value) return availableIcons;

    return availableIcons.filter(
        (icon) =>
            icon.label
                .toLowerCase()
                .includes(searchQuery.value.toLowerCase()) ||
            icon.name.toLowerCase().includes(searchQuery.value.toLowerCase()),
    );
});

const selectedIcon = computed(() => {
    return availableIcons.find((icon) => icon.name === props.modelValue);
});

const selectIcon = (iconName: string) => {
    emit('update:modelValue', iconName);
    showPicker.value = false;
    searchQuery.value = '';
};

const clearIcon = () => {
    emit('update:modelValue', '');
    showPicker.value = false;
};
</script>

<template>
    <div class="relative">
        <!-- Selected Icon Display -->
        <div class="flex items-center gap-2">
            <button
                type="button"
                @click="showPicker = !showPicker"
                class="flex items-center gap-2 rounded-lg border border-gray-300 px-4 py-2 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:hover:bg-gray-700"
            >
                <component
                    v-if="selectedIcon"
                    :is="selectedIcon.component"
                    :size="20"
                    class="text-gray-600 dark:text-gray-400"
                />
                <Menu v-else :size="20" class="text-gray-400" />
                <span class="text-sm text-gray-700 dark:text-gray-300">
                    {{ $t(selectedIcon?.label || 'Select Icon') }}
                </span>
            </button>

            <button
                v-if="modelValue"
                type="button"
                @click="clearIcon"
                class="p-2 text-gray-400 transition-colors hover:text-gray-600 dark:hover:text-gray-300"
            >
                <X :size="16" />
            </button>
        </div>

        <!-- Icon Picker Modal -->
        <div
            v-if="showPicker"
            class="absolute top-full left-0 z-50 mt-2 w-96 rounded-lg border border-gray-200 bg-white shadow-lg dark:border-gray-700 dark:bg-gray-800"
        >
            <!-- Search -->
            <div class="border-b border-gray-200 p-3 dark:border-gray-700">
                <div class="relative">
                    <Search
                        :size="16"
                        class="absolute top-1/2 left-3 -translate-y-1/2 text-gray-400"
                    />
                    <input
                        v-model="searchQuery"
                        type="text"
                        :placeholder="$t('Search icons...')"
                        class="w-full rounded-lg border border-gray-300 bg-white py-2 pr-4 pl-10 text-sm text-gray-900 focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                    />
                </div>
            </div>

            <!-- Icon Grid -->
            <div class="max-h-80 overflow-y-auto p-3">
                <div class="grid grid-cols-4 gap-2">
                    <button
                        v-for="icon in filteredIcons"
                        :key="icon.name"
                        type="button"
                        @click="selectIcon(icon.name)"
                        :class="[
                            'relative flex flex-col items-center gap-1 rounded-lg p-3 transition-colors',
                            modelValue === icon.name
                                ? 'bg-blue-50 text-blue-600 dark:bg-blue-900/20 dark:text-blue-400'
                                : 'text-gray-600 hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-700',
                        ]"
                    >
                        <component :is="icon.component" :size="24" />
                        <span class="text-center text-xs leading-tight">{{
                            $t(icon.label)
                        }}</span>
                        <Check
                            v-if="modelValue === icon.name"
                            :size="14"
                            class="absolute top-1 right-1 text-blue-600 dark:text-blue-400"
                        />
                    </button>
                </div>

                <!-- No Results -->
                <div
                    v-if="filteredIcons.length === 0"
                    class="py-8 text-center text-gray-500 dark:text-gray-400"
                >
                    {{ $t('No icons found') }}
                </div>
            </div>
        </div>

        <!-- Backdrop -->
        <div
            v-if="showPicker"
            class="fixed inset-0 z-40"
            @click="showPicker = false"
        ></div>
    </div>
</template>
