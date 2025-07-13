<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { Search, Filter, X } from 'lucide-svelte';
	import { Button } from '$lib/components/ui';
	import ListingGrid from '$lib/components/listings/ListingGrid.svelte';
	import { cn } from '$lib/utils';

	// Get URL parameters
	const category = $derived($page.url.searchParams.get('category') || '');
	const searchQuery = $derived($page.url.searchParams.get('q') || '');

	// Filter states
	let mobileFiltersOpen = $state(false);
	let activeCategory = $state(category);
	let searchInput = $state(searchQuery);
	let sortBy = $state('recent');
	let priceRange = $state({ min: 0, max: 1000 });
	let selectedSizes = $state(new Set<string>());
	let selectedBrands = $state(new Set<string>());
	let selectedConditions = $state(new Set<string>());

	// Categories with subcategories
	const categories = [
		{
			name: 'All',
			value: '',
			subcategories: []
		},
		{
			name: 'Women',
			value: 'women',
			subcategories: [
				'Dresses', 'Tops', 'Bottoms', 'Outerwear', 'Shoes', 'Accessories', 'Bags', 'Jewellery'
			]
		},
		{
			name: 'Men',
			value: 'men',
			subcategories: [
				'T-shirts', 'Shirts', 'Trousers', 'Jeans', 'Outerwear', 'Shoes', 'Accessories', 'Watches'
			]
		},
		{
			name: 'Kids',
			value: 'kids',
			subcategories: [
				'Girls', 'Boys', 'Baby Girl', 'Baby Boy', 'Shoes', 'Accessories'
			]
		},
		{
			name: 'Designer',
			value: 'designer',
			subcategories: [
				'Gucci', 'Louis Vuitton', 'Chanel', 'Prada', 'Burberry', 'Hermès', 'Balenciaga'
			]
		},
		{
			name: 'Shoes',
			value: 'shoes',
			subcategories: [
				'Trainers', 'Heels', 'Boots', 'Flats', 'Sandals', 'Formal'
			]
		},
		{
			name: 'Bags',
			value: 'bags',
			subcategories: [
				'Handbags', 'Backpacks', 'Crossbody', 'Clutches', 'Tote Bags', 'Travel Bags'
			]
		}
	];

	const sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '6', '8', '10', '12', '14', '16'];
	const brands = ['Nike', 'Adidas', 'Zara', 'H&M', 'Uniqlo', 'ASOS', 'Gucci', 'Prada', 'Burberry'];
	// const conditions = ['New with tags', 'Very good', 'Good', 'Fair'];
	const sortOptions = [
		{ value: 'recent', label: 'Most recent' },
		{ value: 'price-low', label: 'Price: Low to High' },
		{ value: 'price-high', label: 'Price: High to Low' },
		{ value: 'popular', label: 'Most popular' }
	];

	function updateCategory(newCategory: string) {
		activeCategory = newCategory;
		// Update URL without page reload
		const url = new URL($page.url);
		if (newCategory) {
			url.searchParams.set('category', newCategory);
		} else {
			url.searchParams.delete('category');
		}
		window.history.replaceState({}, '', url.toString());
	}

	function handleSearch() {
		const url = new URL($page.url);
		if (searchInput.trim()) {
			url.searchParams.set('q', searchInput.trim());
		} else {
			url.searchParams.delete('q');
		}
		window.history.replaceState({}, '', url.toString());
	}

	function clearFilters() {
		selectedSizes.clear();
		selectedBrands.clear();
		selectedConditions.clear();
		priceRange = { min: 0, max: 1000 };
		selectedSizes = new Set();
		selectedBrands = new Set();
		selectedConditions = new Set();
	}

	onMount(() => {
		activeCategory = category;
		searchInput = searchQuery;
	});
</script>

<svelte:head>
	<title>Browse Fashion - Threadly</title>
</svelte:head>

<div class="min-h-screen bg-background">
	<!-- Mobile Header with Search -->
	<div class="sticky top-[64px] z-40 bg-background border-b block md:hidden">
		<div class="p-4 space-y-3">
			<!-- Search Bar -->
			<div class="relative">
				<Search class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
				<input
					type="search"
					placeholder="Search for items..."
					bind:value={searchInput}
					onkeydown={(e) => e.key === 'Enter' && handleSearch()}
					class="w-full rounded-lg border border-input bg-background pl-10 pr-3 py-3 text-base"
				/>
			</div>

			<!-- Mobile Category Tabs -->
			<div class="overflow-x-auto">
				<div class="flex space-x-2 pb-2">
					{#each categories as category}
						<button
							onclick={() => updateCategory(category.value)}
							class={cn(
								"whitespace-nowrap rounded-full px-4 py-2 text-sm font-medium transition-colors",
								activeCategory === category.value
									? "bg-primary text-primary-foreground"
									: "bg-muted hover:bg-muted/80"
							)}
						>
							{category.name}
						</button>
					{/each}
				</div>
			</div>

			<!-- Mobile Filter Button -->
			<div class="flex items-center justify-between">
				<span class="text-sm text-muted-foreground">2,847 items</span>
				<Button
					variant="outline"
					size="sm"
					onclick={() => mobileFiltersOpen = true}
				>
					<Filter class="h-4 w-4 mr-2" />
					Filters
				</Button>
			</div>
		</div>
	</div>

	<div class="container px-4 py-6">
		<div class="flex gap-6">
			<!-- Desktop Sidebar -->
			<aside class="hidden md:block w-64 flex-shrink-0">
				<div class="sticky top-24 space-y-6">
					<!-- Desktop Search -->
					<div>
						<h3 class="font-semibold mb-3">Search</h3>
						<div class="relative">
							<Search class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
							<input
								type="search"
								placeholder="Search for items..."
								bind:value={searchInput}
								onkeydown={(e) => e.key === 'Enter' && handleSearch()}
								class="w-full rounded-lg border border-input bg-background pl-10 pr-3 py-2 text-sm"
							/>
						</div>
					</div>

					<!-- Categories -->
					<div>
						<h3 class="font-semibold mb-3">Categories</h3>
						<div class="space-y-1">
							{#each categories as category}
								<div>
									<button
										onclick={() => updateCategory(category.value)}
										class={cn(
											"w-full text-left px-3 py-2 rounded-lg text-sm transition-colors",
											activeCategory === category.value
												? "bg-primary/10 text-primary font-medium"
												: "hover:bg-muted"
										)}
									>
										{category.name}
									</button>
									{#if category.subcategories.length > 0 && activeCategory === category.value}
										<div class="ml-4 mt-1 space-y-1">
											{#each category.subcategories as sub}
												<button class="block w-full text-left px-2 py-1 text-xs text-muted-foreground hover:text-foreground">
													{sub}
												</button>
											{/each}
										</div>
									{/if}
								</div>
							{/each}
						</div>
					</div>

					<!-- Price Range -->
					<div>
						<h3 class="font-semibold mb-3">Price Range</h3>
						<div class="space-y-2">
							<div class="flex gap-2">
								<input
									type="number"
									placeholder="Min"
									bind:value={priceRange.min}
									class="w-full rounded border border-input px-2 py-1 text-sm"
								/>
								<input
									type="number"
									placeholder="Max"
									bind:value={priceRange.max}
									class="w-full rounded border border-input px-2 py-1 text-sm"
								/>
							</div>
						</div>
					</div>

					<!-- Sizes -->
					<div>
						<h3 class="font-semibold mb-3">Size</h3>
						<div class="grid grid-cols-3 gap-2">
							{#each sizes as size}
								<button
									onclick={() => {
										if (selectedSizes.has(size)) {
											selectedSizes.delete(size);
										} else {
											selectedSizes.add(size);
										}
										selectedSizes = new Set(selectedSizes);
									}}
									class={cn(
										"px-2 py-1 rounded text-xs border transition-colors",
										selectedSizes.has(size)
											? "bg-primary text-primary-foreground border-primary"
											: "border-input hover:bg-muted"
									)}
								>
									{size}
								</button>
							{/each}
						</div>
					</div>

					<!-- Brands -->
					<div>
						<h3 class="font-semibold mb-3">Brand</h3>
						<div class="space-y-2 max-h-40 overflow-y-auto">
							{#each brands as brand}
								<label class="flex items-center space-x-2 text-sm">
									<input
										type="checkbox"
										checked={selectedBrands.has(brand)}
										onchange={(e) => {
											if (e.currentTarget.checked) {
												selectedBrands.add(brand);
											} else {
												selectedBrands.delete(brand);
											}
											selectedBrands = new Set(selectedBrands);
										}}
										class="rounded"
									/>
									<span>{brand}</span>
								</label>
							{/each}
						</div>
					</div>

					<!-- Clear Filters -->
					<Button variant="outline" onclick={clearFilters} class="w-full">
						Clear all filters
					</Button>
				</div>
			</aside>

			<!-- Main Content -->
			<main class="flex-1">
				<!-- Desktop Sort Options -->
				<div class="hidden md:flex items-center justify-between mb-6">
					<h1 class="text-2xl font-bold">
						{activeCategory ? categories.find(c => c.value === activeCategory)?.name : 'All Items'}
					</h1>
					<div class="flex items-center gap-4">
						<span class="text-sm text-muted-foreground">2,847 items</span>
						<select
							bind:value={sortBy}
							class="rounded border border-input px-3 py-1 text-sm"
						>
							{#each sortOptions as option}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</div>
				</div>

				<!-- Product Grid -->
				<ListingGrid title="" />
			</main>
		</div>
	</div>

	<!-- Mobile Filters Modal -->
	{#if mobileFiltersOpen}
		<div class="fixed inset-0 z-50 md:hidden">
			<div class="fixed inset-0 bg-black/50" onclick={() => mobileFiltersOpen = false}></div>
			<div class="fixed inset-x-0 bottom-0 bg-background rounded-t-xl max-h-[80vh] overflow-y-auto">
				<div class="p-4 border-b">
					<div class="flex items-center justify-between">
						<h2 class="text-lg font-semibold">Filters</h2>
						<button onclick={() => mobileFiltersOpen = false}>
							<X class="h-6 w-6" />
						</button>
					</div>
				</div>
				
				<div class="p-4 space-y-6">
					<!-- Mobile Price Range -->
					<div>
						<h3 class="font-semibold mb-3">Price Range</h3>
						<div class="flex gap-2">
							<input
								type="number"
								placeholder="Min"
								bind:value={priceRange.min}
								class="w-full rounded border border-input px-3 py-2"
							/>
							<input
								type="number"
								placeholder="Max"
								bind:value={priceRange.max}
								class="w-full rounded border border-input px-3 py-2"
							/>
						</div>
					</div>

					<!-- Mobile Sizes -->
					<div>
						<h3 class="font-semibold mb-3">Size</h3>
						<div class="grid grid-cols-4 gap-2">
							{#each sizes as size}
								<button
									onclick={() => {
										if (selectedSizes.has(size)) {
											selectedSizes.delete(size);
										} else {
											selectedSizes.add(size);
										}
										selectedSizes = new Set(selectedSizes);
									}}
									class={cn(
										"px-3 py-2 rounded text-sm border transition-colors",
										selectedSizes.has(size)
											? "bg-primary text-primary-foreground border-primary"
											: "border-input hover:bg-muted"
									)}
								>
									{size}
								</button>
							{/each}
						</div>
					</div>

					<!-- Mobile Sort -->
					<div>
						<h3 class="font-semibold mb-3">Sort by</h3>
						<select
							bind:value={sortBy}
							class="w-full rounded border border-input px-3 py-2"
						>
							{#each sortOptions as option}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</div>
				</div>

				<div class="p-4 border-t">
					<div class="flex gap-3">
						<Button variant="outline" onclick={clearFilters} class="flex-1">
							Clear all
						</Button>
						<Button onclick={() => mobileFiltersOpen = false} class="flex-1">
							Show results
						</Button>
					</div>
				</div>
			</div>
		</div>
	{/if}
</div>