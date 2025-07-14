<script lang="ts">
	import { X, ChevronRight, Check } from 'lucide-svelte';
	import { goto } from '$app/navigation';
	import { cn } from '$lib/utils';
	
	interface Props {
		isOpen?: boolean;
		onClose?: () => void;
	}
	
	let { isOpen = false, onClose = () => {} }: Props = $props();
	
	let selectedFilters = $state({
		category: '',
		subcategory: '',
		price: '',
		size: '',
		brand: '',
		condition: '',
		sort: 'recent'
	});
	
	// Main categories
	const categories = [
		{ slug: 'women', name: 'Women', icon: '👩', count: '2.1k items' },
		{ slug: 'men', name: 'Men', icon: '👨', count: '1.8k items' },
		{ slug: 'kids', name: 'Kids', icon: '👶', count: '890 items' },
		{ slug: 'designer', name: 'Designer', icon: '💎', count: '450 items' },
		{ slug: 'home', name: 'Home & Living', icon: '🏠', count: '320 items' }
	];
	
	// Subcategories
	const subcategories = [
		{ slug: 'dresses', name: 'Dresses', icon: '👗' },
		{ slug: 'shoes', name: 'Shoes', icon: '👠' },
		{ slug: 'bags', name: 'Bags', icon: '👜' },
		{ slug: 'jackets', name: 'Jackets', icon: '🧥' },
		{ slug: 'jeans', name: 'Jeans', icon: '👖' },
		{ slug: 'tops', name: 'Tops', icon: '👚' },
		{ slug: 'accessories', name: 'Accessories', icon: '⌚' },
		{ slug: 'jewelry', name: 'Jewelry', icon: '💍' }
	];
	
	// Filter options
	const priceRanges = [
		{ label: 'Under £20', value: '0-20' },
		{ label: '£20-50', value: '20-50' },
		{ label: '£50-100', value: '50-100' },
		{ label: '£100-200', value: '100-200' },
		{ label: '£200+', value: '200-999' }
	];
	
	const sizes = [
		{ label: 'XS', value: 'xs' },
		{ label: 'S', value: 's' },
		{ label: 'M', value: 'm' },
		{ label: 'L', value: 'l' },
		{ label: 'XL', value: 'xl' },
		{ label: 'XXL', value: 'xxl' }
	];
	
	const brands = [
		{ label: 'Nike', value: 'nike' },
		{ label: 'Adidas', value: 'adidas' },
		{ label: 'Zara', value: 'zara' },
		{ label: 'H&M', value: 'hm' },
		{ label: 'Gucci', value: 'gucci' },
		{ label: 'Louis Vuitton', value: 'lv' },
		{ label: 'Chanel', value: 'chanel' },
		{ label: 'Prada', value: 'prada' }
	];
	
	const conditions = [
		{ label: 'New with tags', value: 'new' },
		{ label: 'Like new', value: 'likenew' },
		{ label: 'Very good', value: 'verygood' },
		{ label: 'Good', value: 'good' },
		{ label: 'Fair', value: 'fair' }
	];
	
	const sortOptions = [
		{ label: 'Most Recent', value: 'recent', icon: '🆕' },
		{ label: 'Price: Low to High', value: 'price-low', icon: '📈' },
		{ label: 'Price: High to Low', value: 'price-high', icon: '📉' },
		{ label: 'Most Popular', value: 'popular', icon: '🔥' },
		{ label: 'Ending Soon', value: 'ending', icon: '⏰' }
	];
	
	function selectFilter(type: string, value: string) {
		selectedFilters[type] = selectedFilters[type] === value ? '' : value;
	}
	
	function clearAllFilters() {
		selectedFilters = {
			category: '',
			subcategory: '',
			price: '',
			size: '',
			brand: '',
			condition: '',
			sort: 'recent'
		};
	}
	
	function applyFilters() {
		const params = new URLSearchParams();
		
		Object.entries(selectedFilters).forEach(([key, value]) => {
			if (value && value !== 'recent') {
				params.set(key, value);
			}
		});
		
		const url = selectedFilters.category 
			? `/${selectedFilters.category}${params.toString() ? '?' + params.toString() : ''}`
			: `/browse${params.toString() ? '?' + params.toString() : ''}`;
		
		onClose();
		goto(url);
	}
	
	const activeFilterCount = $derived(
		Object.values(selectedFilters).filter(v => v && v !== 'recent').length
	);
</script>

<!-- Backdrop -->
{#if isOpen}
	<div 
		class="fixed inset-0 bg-black/50 z-[60] transition-opacity duration-300"
		onclick={onClose}
	></div>
{/if}

<!-- Drawer -->
<div class={cn(
	"fixed bottom-0 left-0 right-0 bg-white rounded-t-3xl shadow-2xl z-[70] transition-transform duration-300 ease-out",
	isOpen ? "translate-y-0" : "translate-y-full"
)}>
	<div class="max-h-[85vh] flex flex-col">
		<!-- Header -->
		<div class="flex items-center justify-between p-4 border-b border-gray-200">
			<div class="flex items-center gap-3">
				<h2 class="text-lg font-bold text-gray-900">Filters</h2>
				{#if activeFilterCount > 0}
					<span class="bg-orange-500 text-white text-xs font-bold px-2 py-1 rounded-full">
						{activeFilterCount}
					</span>
				{/if}
			</div>
			<div class="flex items-center gap-2">
				{#if activeFilterCount > 0}
					<button
						onclick={clearAllFilters}
						class="text-sm text-orange-600 hover:text-orange-700 font-medium px-3 py-1.5 rounded-lg hover:bg-orange-50"
					>
						Clear all
					</button>
				{/if}
				<button
					onclick={onClose}
					class="p-2 hover:bg-gray-100 rounded-lg transition-colors"
				>
					<X class="h-5 w-5 text-gray-500" />
				</button>
			</div>
		</div>
		
		<!-- Content -->
		<div class="flex-1 overflow-y-auto p-4 space-y-6">
			<!-- Categories -->
			<div>
				<h3 class="text-base font-semibold text-gray-900 mb-3">Categories</h3>
				<div class="grid grid-cols-2 gap-2">
					{#each categories as category}
						<button
							onclick={() => selectFilter('category', category.slug)}
							class={cn(
								"flex items-center gap-3 p-3 rounded-xl border transition-all duration-200 text-left",
								selectedFilters.category === category.slug
									? "bg-orange-50 border-orange-300 text-orange-700"
									: "bg-white border-gray-200 hover:border-orange-300 hover:bg-orange-50"
							)}
						>
							<span class="text-lg">{category.icon}</span>
							<div class="flex-1 min-w-0">
								<div class="font-medium text-sm">{category.name}</div>
								<div class="text-xs text-gray-500">{category.count}</div>
							</div>
							{#if selectedFilters.category === category.slug}
								<Check class="h-4 w-4 text-orange-600 flex-shrink-0" />
							{/if}
						</button>
					{/each}
				</div>
			</div>
			
			<!-- Subcategories -->
			<div>
				<h3 class="text-base font-semibold text-gray-900 mb-3">What are you looking for?</h3>
				<div class="grid grid-cols-2 gap-2">
					{#each subcategories as subcategory}
						<button
							onclick={() => selectFilter('subcategory', subcategory.slug)}
							class={cn(
								"flex items-center gap-2 p-3 rounded-xl border transition-all duration-200 text-left",
								selectedFilters.subcategory === subcategory.slug
									? "bg-orange-50 border-orange-300 text-orange-700"
									: "bg-white border-gray-200 hover:border-orange-300 hover:bg-orange-50"
							)}
						>
							<span class="text-base">{subcategory.icon}</span>
							<span class="font-medium text-sm flex-1">{subcategory.name}</span>
							{#if selectedFilters.subcategory === subcategory.slug}
								<Check class="h-4 w-4 text-orange-600 flex-shrink-0" />
							{/if}
						</button>
					{/each}
				</div>
			</div>
			
			<!-- Price Range -->
			<div>
				<h3 class="text-base font-semibold text-gray-900 mb-3">Price Range</h3>
				<div class="grid grid-cols-2 gap-2">
					{#each priceRanges as price}
						<button
							onclick={() => selectFilter('price', price.value)}
							class={cn(
								"p-3 rounded-xl border text-center font-medium text-sm transition-all duration-200",
								selectedFilters.price === price.value
									? "bg-orange-500 border-orange-500 text-white"
									: "bg-white border-gray-200 text-gray-700 hover:border-orange-300 hover:bg-orange-50"
							)}
						>
							{price.label}
						</button>
					{/each}
				</div>
			</div>
			
			<!-- Size -->
			<div>
				<h3 class="text-base font-semibold text-gray-900 mb-3">Size</h3>
				<div class="flex flex-wrap gap-2">
					{#each sizes as size}
						<button
							onclick={() => selectFilter('size', size.value)}
							class={cn(
								"px-4 py-2 rounded-xl border font-medium text-sm transition-all duration-200 min-w-[50px]",
								selectedFilters.size === size.value
									? "bg-orange-500 border-orange-500 text-white"
									: "bg-white border-gray-200 text-gray-700 hover:border-orange-300 hover:bg-orange-50"
							)}
						>
							{size.label}
						</button>
					{/each}
				</div>
			</div>
			
			<!-- Brand -->
			<div>
				<h3 class="text-base font-semibold text-gray-900 mb-3">Brand</h3>
				<div class="grid grid-cols-2 gap-2">
					{#each brands as brand}
						<button
							onclick={() => selectFilter('brand', brand.value)}
							class={cn(
								"p-3 rounded-xl border text-center font-medium text-sm transition-all duration-200",
								selectedFilters.brand === brand.value
									? "bg-orange-500 border-orange-500 text-white"
									: "bg-white border-gray-200 text-gray-700 hover:border-orange-300 hover:bg-orange-50"
							)}
						>
							{brand.label}
						</button>
					{/each}
				</div>
			</div>
			
			<!-- Condition -->
			<div>
				<h3 class="text-base font-semibold text-gray-900 mb-3">Condition</h3>
				<div class="space-y-2">
					{#each conditions as condition}
						<button
							onclick={() => selectFilter('condition', condition.value)}
							class={cn(
								"w-full p-3 rounded-xl border text-left font-medium text-sm transition-all duration-200 flex items-center justify-between",
								selectedFilters.condition === condition.value
									? "bg-orange-50 border-orange-300 text-orange-700"
									: "bg-white border-gray-200 text-gray-700 hover:border-orange-300 hover:bg-orange-50"
							)}
						>
							<span>{condition.label}</span>
							{#if selectedFilters.condition === condition.value}
								<Check class="h-4 w-4 text-orange-600" />
							{/if}
						</button>
					{/each}
				</div>
			</div>
			
			<!-- Sort -->
			<div>
				<h3 class="text-base font-semibold text-gray-900 mb-3">Sort by</h3>
				<div class="space-y-2">
					{#each sortOptions as sort}
						<button
							onclick={() => selectFilter('sort', sort.value)}
							class={cn(
								"w-full p-3 rounded-xl border text-left font-medium text-sm transition-all duration-200 flex items-center gap-3",
								selectedFilters.sort === sort.value
									? "bg-orange-50 border-orange-300 text-orange-700"
									: "bg-white border-gray-200 text-gray-700 hover:border-orange-300 hover:bg-orange-50"
							)}
						>
							<span class="text-base">{sort.icon}</span>
							<span class="flex-1">{sort.label}</span>
							{#if selectedFilters.sort === sort.value}
								<Check class="h-4 w-4 text-orange-600" />
							{/if}
						</button>
					{/each}
				</div>
			</div>
		</div>
		
		<!-- Footer -->
		<div class="border-t border-gray-200 p-4 bg-gray-50">
			<button
				onclick={applyFilters}
				class="w-full bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700 text-white font-semibold py-4 px-6 rounded-xl transition-all duration-200 shadow-lg hover:shadow-xl active:scale-95"
			>
				{#if activeFilterCount > 0}
					Apply Filters ({activeFilterCount})
				{:else}
					Browse All Items
				{/if}
			</button>
		</div>
	</div>
</div>