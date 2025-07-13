<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { Search, Filter, X } from 'lucide-svelte';
	import { Button } from '$lib/components/ui';
	import ListingGrid from '$lib/components/listings/ListingGrid.svelte';
	import SearchInput from '$lib/components/search/SearchInput.svelte';
	import { cn } from '$lib/utils';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	// Reactive filter states from server data
	let searchInput = $state(data.filters.search);
	let sortBy = $state(data.filters.sortBy);
	let priceRange = $state({ 
		min: data.filters.minPrice || 0, 
		max: data.filters.maxPrice || 1000 
	});
	let selectedSizes = $state(new Set(data.filters.sizes));
	let selectedBrands = $state(new Set(data.filters.brands));
	let selectedConditions = $state(new Set(data.filters.conditions));
	let mobileFiltersOpen = $state(false);

	// Infinite scroll state
	let allListings = $state([...data.listings]);
	let currentPage = $state(data.pagination.currentPage);
	let hasMoreItems = $state(data.pagination.hasNextPage);
	let loadingMore = $state(false);

	// Derive categories with "All" option
	const categoriesWithAll = $derived([
		{ id: '', name: 'All', slug: '', icon_url: null, parent_id: null },
		...data.categories
	]);

	// Available condition options
	const conditionOptions = [
		{ value: 'new_with_tags', label: 'New with tags' },
		{ value: 'like_new', label: 'Like new' },
		{ value: 'good', label: 'Good' },
		{ value: 'fair', label: 'Fair' },
		{ value: 'poor', label: 'Poor' }
	];

	const sortOptions = [
		{ value: 'recent', label: 'Most recent' },
		{ value: 'price-low', label: 'Price: Low to High' },
		{ value: 'price-high', label: 'Price: High to Low' },
		{ value: 'popular', label: 'Most popular' },
		{ value: 'liked', label: 'Most liked' }
	];

	function buildFilterUrl(updates: Record<string, any> = {}) {
		const url = new URL($page.url);
		
		// Apply updates to current filters
		const newFilters = {
			category: updates.category ?? data.filters.category,
			subcategory: updates.subcategory ?? data.filters.subcategory,
			q: updates.search ?? searchInput?.trim(),
			min_price: updates.minPrice ?? (priceRange.min > 0 ? priceRange.min : null),
			max_price: updates.maxPrice ?? (priceRange.max < 10000 ? priceRange.max : null),
			sizes: updates.sizes ?? (selectedSizes.size > 0 ? Array.from(selectedSizes).join(',') : null),
			brands: updates.brands ?? (selectedBrands.size > 0 ? Array.from(selectedBrands).join(',') : null),
			conditions: updates.conditions ?? (selectedConditions.size > 0 ? Array.from(selectedConditions).join(',') : null),
			sort: updates.sort ?? sortBy,
			page: updates.page ?? 1 // Reset to page 1 on filter changes
		};

		// Clear existing params and set new ones
		url.search = '';
		Object.entries(newFilters).forEach(([key, value]) => {
			if (value && value !== '' && value !== 'recent') {
				url.searchParams.set(key, String(value));
			}
		});

		return url.toString();
	}

	function updateCategory(categorySlug: string) {
		goto(buildFilterUrl({ category: categorySlug || null }));
	}

	function handleSearch(query: string) {
		goto(buildFilterUrl({ search: query?.trim() || null }));
	}

	function handleSearchInput(query: string) {
		searchInput = query;
	}

	function updateSort(newSort: string) {
		sortBy = newSort;
		goto(buildFilterUrl({ sort: newSort }));
	}

	function updatePriceRange() {
		goto(buildFilterUrl({ 
			minPrice: priceRange.min > 0 ? priceRange.min : null,
			maxPrice: priceRange.max < 10000 ? priceRange.max : null
		}));
	}

	function toggleSize(size: string) {
		if (selectedSizes.has(size)) {
			selectedSizes.delete(size);
		} else {
			selectedSizes.add(size);
		}
		selectedSizes = new Set(selectedSizes);
		goto(buildFilterUrl({ sizes: selectedSizes.size > 0 ? Array.from(selectedSizes).join(',') : null }));
	}

	function toggleBrand(brand: string) {
		if (selectedBrands.has(brand)) {
			selectedBrands.delete(brand);
		} else {
			selectedBrands.add(brand);
		}
		selectedBrands = new Set(selectedBrands);
		goto(buildFilterUrl({ brands: selectedBrands.size > 0 ? Array.from(selectedBrands).join(',') : null }));
	}

	function toggleCondition(condition: string) {
		if (selectedConditions.has(condition)) {
			selectedConditions.delete(condition);
		} else {
			selectedConditions.add(condition);
		}
		selectedConditions = new Set(selectedConditions);
		goto(buildFilterUrl({ conditions: selectedConditions.size > 0 ? Array.from(selectedConditions).join(',') : null }));
	}

	function clearAllFilters() {
		goto('/browse');
	}


	// Size options
	const sizeOptions = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '6', '8', '10', '12', '14', '16'];

	// Reset infinite scroll state when data changes (filter applied)
	$effect(() => {
		allListings = [...data.listings];
		currentPage = data.pagination.currentPage;
		hasMoreItems = data.pagination.hasNextPage;
		loadingMore = false;
	});

	async function loadMoreItems() {
		if (loadingMore || !hasMoreItems) return;
		
		loadingMore = true;
		const nextPage = currentPage + 1;

		try {
			const params = new URLSearchParams();
			
			// Add all current filters to the API call
			if (data.filters.category) params.set('category', data.filters.category);
			if (data.filters.subcategory) params.set('subcategory', data.filters.subcategory);
			if (data.filters.search) params.set('q', data.filters.search);
			if (data.filters.minPrice) params.set('min_price', data.filters.minPrice.toString());
			if (data.filters.maxPrice) params.set('max_price', data.filters.maxPrice.toString());
			if (data.filters.sizes.length > 0) params.set('sizes', data.filters.sizes.join(','));
			if (data.filters.brands.length > 0) params.set('brands', data.filters.brands.join(','));
			if (data.filters.conditions.length > 0) params.set('conditions', data.filters.conditions.join(','));
			if (data.filters.sortBy !== 'recent') params.set('sort', data.filters.sortBy);
			params.set('page', nextPage.toString());
			params.set('limit', data.pagination.limit.toString());

			const response = await fetch(`/api/browse/load-more?${params.toString()}`);
			
			if (response.ok) {
				const result = await response.json();
				
				if (result.listings && result.listings.length > 0) {
					allListings = [...allListings, ...result.listings];
					currentPage = nextPage;
					hasMoreItems = result.hasMore;
				} else {
					hasMoreItems = false;
				}
			} else {
				console.error('Failed to load more items');
				hasMoreItems = false;
			}
		} catch (error) {
			console.error('Error loading more items:', error);
			hasMoreItems = false;
		} finally {
			loadingMore = false;
		}
	}
</script>

<svelte:head>
	<title>Browse Fashion - Threadly</title>
</svelte:head>

<div class="min-h-screen bg-background">
	<!-- Mobile Header with Search -->
	<div class="sticky top-[64px] z-40 bg-background border-b block md:hidden">
		<div class="p-4 space-y-3">
			<!-- Search Bar -->
			<SearchInput
				value={searchInput}
				onSearch={handleSearch}
				onInput={handleSearchInput}
				class="py-3 text-base"
			/>

			<!-- Mobile Category Tabs -->
			<div class="overflow-x-auto">
				<div class="flex space-x-2 pb-2">
					{#each categoriesWithAll as category}
						<button
							onclick={() => updateCategory(category.slug)}
							class={cn(
								"whitespace-nowrap rounded-full px-4 py-2 text-sm font-medium transition-colors",
								data.filters.category === category.slug
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
				<span class="text-sm text-muted-foreground">{data.totalCount.toLocaleString()} items</span>
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
						<SearchInput
							value={searchInput}
							onSearch={handleSearch}
							onInput={handleSearchInput}
						/>
					</div>

					<!-- Categories -->
					<div>
						<h3 class="font-semibold mb-3">Categories</h3>
						<div class="space-y-1">
							{#each categoriesWithAll as category}
								<button
									onclick={() => updateCategory(category.slug)}
									class={cn(
										"w-full text-left px-3 py-2 rounded-lg text-sm transition-colors",
										data.filters.category === category.slug
											? "bg-primary/10 text-primary font-medium"
											: "hover:bg-muted"
									)}
								>
									{category.icon_url || '📦'} {category.name}
								</button>
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
									onblur={updatePriceRange}
									class="w-full rounded border border-input px-2 py-1 text-sm"
								/>
								<input
									type="number"
									placeholder="Max"
									bind:value={priceRange.max}
									onblur={updatePriceRange}
									class="w-full rounded border border-input px-2 py-1 text-sm"
								/>
							</div>
							<Button variant="outline" size="sm" onclick={updatePriceRange} class="w-full">
								Apply
							</Button>
						</div>
					</div>

					<!-- Sizes -->
					<div>
						<h3 class="font-semibold mb-3">Size</h3>
						<div class="grid grid-cols-3 gap-2">
							{#each sizeOptions as size}
								<button
									onclick={() => toggleSize(size)}
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

					<!-- Conditions -->
					<div>
						<h3 class="font-semibold mb-3">Condition</h3>
						<div class="space-y-2">
							{#each conditionOptions as condition}
								<label class="flex items-center space-x-2 text-sm">
									<input
										type="checkbox"
										checked={selectedConditions.has(condition.value)}
										onchange={() => toggleCondition(condition.value)}
										class="rounded"
									/>
									<span>{condition.label}</span>
								</label>
							{/each}
						</div>
					</div>

					<!-- Brands -->
					<div>
						<h3 class="font-semibold mb-3">Brand</h3>
						<div class="space-y-2 max-h-40 overflow-y-auto">
							{#each data.popularBrands as brand}
								<label class="flex items-center space-x-2 text-sm">
									<input
										type="checkbox"
										checked={selectedBrands.has(brand)}
										onchange={() => toggleBrand(brand)}
										class="rounded"
									/>
									<span>{brand}</span>
								</label>
							{/each}
						</div>
					</div>

					<!-- Clear Filters -->
					<Button variant="outline" onclick={clearAllFilters} class="w-full">
						Clear all filters
					</Button>
				</div>
			</aside>

			<!-- Main Content -->
			<main class="flex-1">
				<!-- Desktop Sort Options -->
				<div class="hidden md:flex items-center justify-between mb-6">
					<h1 class="text-2xl font-bold">
						{data.filters.category ? categoriesWithAll.find(c => c.slug === data.filters.category)?.name : 'All Items'}
						{#if data.filters.search}
							<span class="text-base font-normal text-muted-foreground">for "{data.filters.search}"</span>
						{/if}
					</h1>
					<div class="flex items-center gap-4">
						<span class="text-sm text-muted-foreground">{data.totalCount.toLocaleString()} items</span>
						<select
							bind:value={sortBy}
							onchange={(e) => updateSort(e.currentTarget.value)}
							class="rounded border border-input px-3 py-1 text-sm"
						>
							{#each sortOptions as option}
								<option value={option.value}>{option.label}</option>
							{/each}
						</select>
					</div>
				</div>

				<!-- Active Filters Display -->
				{#if data.filters.search || data.filters.category || selectedSizes.size > 0 || selectedBrands.size > 0 || selectedConditions.size > 0 || data.filters.minPrice || data.filters.maxPrice}
					<div class="mb-6 flex flex-wrap gap-2">
						{#if data.filters.search}
							<span class="inline-flex items-center rounded-full bg-primary/10 px-3 py-1 text-sm">
								Search: "{data.filters.search}"
								<button onclick={() => goto(buildFilterUrl({ search: null }))} class="ml-2 hover:text-primary">
									<X class="h-3 w-3" />
								</button>
							</span>
						{/if}
						{#if data.filters.category}
							<span class="inline-flex items-center rounded-full bg-primary/10 px-3 py-1 text-sm">
								{categoriesWithAll.find(c => c.slug === data.filters.category)?.name}
								<button onclick={() => updateCategory('')} class="ml-2 hover:text-primary">
									<X class="h-3 w-3" />
								</button>
							</span>
						{/if}
						{#each Array.from(selectedSizes) as size}
							<span class="inline-flex items-center rounded-full bg-primary/10 px-3 py-1 text-sm">
								Size {size}
								<button onclick={() => toggleSize(size)} class="ml-2 hover:text-primary">
									<X class="h-3 w-3" />
								</button>
							</span>
						{/each}
						{#each Array.from(selectedBrands) as brand}
							<span class="inline-flex items-center rounded-full bg-primary/10 px-3 py-1 text-sm">
								{brand}
								<button onclick={() => toggleBrand(brand)} class="ml-2 hover:text-primary">
									<X class="h-3 w-3" />
								</button>
							</span>
						{/each}
						{#each Array.from(selectedConditions) as condition}
							<span class="inline-flex items-center rounded-full bg-primary/10 px-3 py-1 text-sm">
								{conditionOptions.find(c => c.value === condition)?.label}
								<button onclick={() => toggleCondition(condition)} class="ml-2 hover:text-primary">
									<X class="h-3 w-3" />
								</button>
							</span>
						{/each}
						{#if data.filters.minPrice || data.filters.maxPrice}
							<span class="inline-flex items-center rounded-full bg-primary/10 px-3 py-1 text-sm">
								${data.filters.minPrice || 0} - ${data.filters.maxPrice || '∞'}
								<button onclick={() => goto(buildFilterUrl({ minPrice: null, maxPrice: null }))} class="ml-2 hover:text-primary">
									<X class="h-3 w-3" />
								</button>
							</span>
						{/if}
						<Button variant="ghost" size="sm" onclick={clearAllFilters}>
							Clear all
						</Button>
					</div>
				{/if}

				<!-- Product Grid -->
				<ListingGrid 
					listings={allListings} 
					title="" 
					infiniteScroll={true}
					hasMore={hasMoreItems}
					onLoadMore={loadMoreItems}
				/>

				<!-- Items Counter -->
				{#if allListings.length > 0}
					<div class="mt-4 text-center text-sm text-muted-foreground">
						Showing {allListings.length.toLocaleString()} of {data.totalCount.toLocaleString()} results
						{#if hasMoreItems}
							• Scroll down to load more
						{/if}
					</div>
				{/if}
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
						<div class="space-y-2">
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
							<Button variant="outline" size="sm" onclick={updatePriceRange} class="w-full">
								Apply Price Range
							</Button>
						</div>
					</div>

					<!-- Mobile Sizes -->
					<div>
						<h3 class="font-semibold mb-3">Size</h3>
						<div class="grid grid-cols-4 gap-2">
							{#each sizeOptions as size}
								<button
									onclick={() => toggleSize(size)}
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

					<!-- Mobile Conditions -->
					<div>
						<h3 class="font-semibold mb-3">Condition</h3>
						<div class="space-y-2">
							{#each conditionOptions as condition}
								<label class="flex items-center space-x-2 text-sm">
									<input
										type="checkbox"
										checked={selectedConditions.has(condition.value)}
										onchange={() => toggleCondition(condition.value)}
										class="rounded"
									/>
									<span>{condition.label}</span>
								</label>
							{/each}
						</div>
					</div>

					<!-- Mobile Brands -->
					<div>
						<h3 class="font-semibold mb-3">Brand</h3>
						<div class="space-y-2 max-h-32 overflow-y-auto">
							{#each data.popularBrands.slice(0, 10) as brand}
								<label class="flex items-center space-x-2 text-sm">
									<input
										type="checkbox"
										checked={selectedBrands.has(brand)}
										onchange={() => toggleBrand(brand)}
										class="rounded"
									/>
									<span>{brand}</span>
								</label>
							{/each}
						</div>
					</div>

					<!-- Mobile Sort -->
					<div>
						<h3 class="font-semibold mb-3">Sort by</h3>
						<select
							bind:value={sortBy}
							onchange={(e) => updateSort(e.currentTarget.value)}
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
						<Button variant="outline" onclick={clearAllFilters} class="flex-1">
							Clear all
						</Button>
						<Button onclick={() => mobileFiltersOpen = false} class="flex-1">
							Show {data.totalCount.toLocaleString()} results
						</Button>
					</div>
				</div>
			</div>
		</div>
	{/if}
</div>