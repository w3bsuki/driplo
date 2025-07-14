<script lang="ts">
	import { Search, Sparkles, TrendingUp, ChevronDown } from 'lucide-svelte';
	import { goto } from '$app/navigation';
	import { cn } from '$lib/utils';
	import CategoryDropdown from '$lib/components/shared/CategoryDropdown.svelte';
	import type { Category } from '$lib/types';
	
	interface Props {
		categories?: Category[];
	}
	
	let { categories = [] }: Props = $props();
	
	let searchQuery = $state('');
	let isFocused = $state(false);
	let isCategoryDropdownOpen = $state(false);
	
	const trendingSearches = [
		'vintage levis',
		'designer bags',
		'nike trainers',
		'zara dress',
		'north face jacket'
	];
	
	// Top trending categories - these would be dynamic based on analytics
	const trendingCategories = [
		{ icon: '👗', name: 'Dresses', value: 'dresses', trending: true },
		{ icon: '👟', name: 'Trainers', value: 'trainers', trending: true },
		{ icon: '👜', name: 'Bags', value: 'bags', trending: true },
		{ icon: '🧥', name: 'Jackets', value: 'jackets', trending: true },
		{ icon: '👠', name: 'Shoes', value: 'shoes', trending: true },
		{ icon: '👕', name: 'T-Shirts', value: 'tshirts', trending: true },
		{ icon: '👖', name: 'Jeans', value: 'jeans', trending: true },
		{ icon: '⌚', name: 'Watches', value: 'watches', trending: true },
		{ icon: '💍', name: 'Jewelry', value: 'jewelry', trending: true },
		{ icon: '🕶️', name: 'Sunglasses', value: 'sunglasses', trending: true }
	];
	
	function handleSearch() {
		if (searchQuery.trim()) {
			const params = new URLSearchParams();
			params.set('q', searchQuery.trim());
			goto(`/browse?${params.toString()}`);
		} else {
			goto('/browse');
		}
	}
	
	function searchTrending(term: string) {
		searchQuery = term;
		handleSearch();
	}
	
	function goToCategory(category: string) {
		goto(`/browse?category=${category}`);
	}
	
	function toggleCategoryDropdown() {
		isCategoryDropdownOpen = !isCategoryDropdownOpen;
	}
	
	function closeCategoryDropdown() {
		isCategoryDropdownOpen = false;
	}
</script>

<section class="relative bg-gradient-to-b from-orange-50 to-white py-3 md:py-4 pb-0">
	<div class="container px-4">
		<div class="max-w-3xl mx-auto">
			
			<!-- Search Bar -->
			<div class="relative group">
				<div class={cn(
					"absolute inset-0 bg-gradient-to-r from-orange-400 to-orange-600 rounded-2xl blur-xl opacity-20 transition-all duration-300",
					isFocused && "opacity-30 blur-2xl"
				)}></div>
				
				<div class="relative bg-white rounded-2xl shadow-lg border border-orange-200 transition-all duration-300 hover:shadow-xl hover:border-orange-300">
					<div class="flex items-center">
						<!-- Category Dropdown Button -->
						<div class="relative pl-4 pr-3">
							<button
								data-categories-button
								onclick={toggleCategoryDropdown}
								class={cn(
									"flex items-center gap-1.5 px-3 py-2 rounded-lg transition-all duration-200 font-medium text-sm",
									isCategoryDropdownOpen 
										? "bg-gradient-to-r from-orange-500 to-orange-600 text-white shadow-sm hover:from-orange-600 hover:to-orange-700" 
										: "bg-gradient-to-r from-orange-100 to-orange-200 hover:from-orange-200 hover:to-orange-300 border border-orange-300"
								)}
							>
								<span class={cn(
									isCategoryDropdownOpen ? "text-white" : "text-gray-900"
								)}>Categories</span>
								<ChevronDown class={cn(
									"h-4 w-4 transition-transform duration-200",
									isCategoryDropdownOpen && "rotate-180",
									isCategoryDropdownOpen ? "text-white" : "text-gray-900"
								)} />
							</button>
							
							<CategoryDropdown
								{categories}
								isOpen={isCategoryDropdownOpen}
								onToggle={toggleCategoryDropdown}
								onClose={closeCategoryDropdown}
							/>
						</div>
						
						<!-- Divider -->
						<div class="w-px h-6 bg-orange-200"></div>
						
						
						<input
							type="search"
							placeholder="Search for items, brands, or users..."
							bind:value={searchQuery}
							onfocus={() => isFocused = true}
							onblur={() => isFocused = false}
							onkeydown={(e) => e.key === 'Enter' && handleSearch()}
							class="flex-1 py-4 md:py-4.5 pl-4 pr-4 text-sm md:text-base placeholder:text-gray-400 focus:outline-none bg-transparent focus:placeholder:text-orange-400"
						/>
						
						<button
							onclick={handleSearch}
							class="mr-3 p-2.5 bg-orange-500 text-white rounded-lg hover:bg-orange-600 transition-all duration-200 active:scale-95 flex items-center justify-center"
							aria-label="Search"
						>
							<Search class="h-4 w-4" />
						</button>
					</div>
					
					<!-- Trending Category Links -->
					<div class="border-t border-orange-100 py-2 flex items-center gap-3 overflow-x-auto">
						<div class="flex items-center gap-3 px-4">
							<span class="text-xs text-gray-500 flex-shrink-0 hidden md:block">Trending:</span>
							{#each trendingCategories as category}
								<button
									onclick={() => goToCategory(category.value)}
									class="flex items-center gap-1 px-2.5 py-1 rounded-full bg-white/80 backdrop-blur-sm shadow-sm text-gray-800 hover:bg-white hover:shadow-md transition-all duration-200 text-xs font-medium whitespace-nowrap group"
								>
									<span class="text-sm">{category.icon}</span>
									<span>{category.name}</span>
								</button>
							{/each}
						</div>
					</div>
				</div>
			</div>
			
			<!-- Trending Searches - Compact -->
			<div class="mt-3 flex items-center justify-center gap-2 flex-wrap text-xs md:text-sm">
				<span class="text-gray-500">Trending:</span>
				{#each trendingSearches.slice(0, 3) as term}
					<button
						onclick={() => searchTrending(term)}
						class="text-gray-600 hover:text-orange-600 transition-colors duration-200"
					>
						{term}
					</button>
				{/each}
			</div>
		</div>
	</div>
</section>

<style>
	/* Hide scrollbar for quick categories */
	.overflow-x-auto {
		-ms-overflow-style: none;
		scrollbar-width: none;
	}
	.overflow-x-auto::-webkit-scrollbar {
		display: none;
	}
</style>